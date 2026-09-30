# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30
extends Node
## Music + SFX (hud.md Audio). One looped track in Stream mode, started on the
## first gesture; paused with the game; low-passed on the results screen.
## SFX files do not exist yet: short tones are synthesised as stand-ins, one
## per event, so real files can replace them key by key.

const MIX_RATE := 22050

var _cfg: Resource
var _scope: RefCounted
var _music: AudioStreamPlayer
var _sfx: Array[AudioStreamPlayer] = []
var _sfx_streams := {}
var _lowpass: AudioEffectLowPassFilter
var _music_bus := -1
var _muted := false
var _gesture := false
var _loaded := false
var _paused := false
var _started := false
var _lp_t := -1.0
var _http: HTTPRequest
var _retried := false


func setup(audio_cfg: Resource, scope: RefCounted) -> void:
	_cfg = audio_cfg
	_scope = scope
	scope.declare_bool("muted", false)
	_muted = scope.read_bool("muted")
	# Browsers block audio until the first gesture; desktop/editor has no such rule.
	_gesture = not OS.has_feature("web")
	_ensure_buses()
	AudioServer.set_bus_mute(0, _muted)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	_music.volume_db = audio_cfg.music_volume_db
	_music.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	add_child(_music)
	for i in 6:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		p.volume_db = audio_cfg.sfx_volume_db
		add_child(p)
		_sfx.append(p)
	_build_sfx()


func is_muted() -> bool:
	return _muted


func set_muted(v: bool) -> void:
	_muted = v
	AudioServer.set_bus_mute(0, v)
	_scope.write_bool("muted", v)


## Web: fetch the track from next to index.html after boot. Elsewhere: load it.
func start_music_fetch(url: String) -> void:
	if url == "":
		# The track is not imported (it ships beside index.html on web), so read the raw file.
		var stream := AudioStreamOggVorbis.load_from_file(ProjectSettings.globalize_path(_cfg.music_path))
		if stream:
			_set_stream(stream)
		return
	_http = HTTPRequest.new()
	_http.use_threads = false
	add_child(_http)
	_http.request_completed.connect(_on_music_fetched.bind(url))
	_http.request(url)


func on_paused_changed(paused: bool) -> void:
	_paused = paused
	if _started:
		_music.stream_paused = paused
	_try_start()


func on_match_started() -> void:
	_lp_t = -1.0
	_set_lowpass(false)
	if _started:
		_music.play(0.0)
		_music.stream_paused = _paused


func on_match_ended(new_record: bool) -> void:
	_set_lowpass(true)
	_lp_t = 0.0
	play(&"record" if new_record else &"match_end")


func play(event: StringName) -> void:
	var stream: AudioStream = _sfx_streams.get(event)
	if stream == null:
		return
	for p in _sfx:
		if not p.playing:
			p.stream = stream
			p.play()
			return
	_sfx[0].stream = stream
	_sfx[0].play()


## The ui clock drives the filter ramp so it runs on the results screen.
func step_ui(ui_dt: float) -> void:
	if _lp_t < 0.0 or _lowpass == null:
		return
	_lp_t += ui_dt
	var k := clampf(_lp_t / maxf(_cfg.music_lowpass_ramp_s, 0.001), 0.0, 1.0)
	# Log-linear sweep 20 kHz -> cutoff.
	_lowpass.cutoff_hz = exp(lerpf(log(20000.0), log(_cfg.music_lowpass_cutoff_hz), k))


func _input(event: InputEvent) -> void:
	if _gesture:
		return
	if (event is InputEventMouseButton or event is InputEventScreenTouch or event is InputEventKey) and event.is_pressed():
		_gesture = true
		_try_start()


func _try_start() -> void:
	if _started or not _gesture or not _loaded or _paused:
		return
	_started = true
	_music.play(0.0)


func _set_stream(stream: AudioStream) -> void:
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	_music.stream = stream
	_loaded = true
	_try_start()


func _on_music_fetched(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray, url: String) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and code == 200:
		var stream := AudioStreamOggVorbis.load_from_buffer(body)
		if stream:
			_set_stream(stream)
			return
	if not _retried:
		_retried = true
		await get_tree().create_timer(5.0).timeout
		_http.request(url)


func _ensure_buses() -> void:
	for name: String in ["Music", "SFX"]:
		if AudioServer.get_bus_index(name) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, name)
			AudioServer.set_bus_send(idx, "Master")
	_music_bus = AudioServer.get_bus_index("Music")
	_lowpass = AudioEffectLowPassFilter.new()
	_lowpass.cutoff_hz = 20000.0
	AudioServer.add_bus_effect(_music_bus, _lowpass, 0)
	AudioServer.set_bus_effect_enabled(_music_bus, 0, false)


func _set_lowpass(on: bool) -> void:
	if _music_bus < 0:
		return
	_lowpass.cutoff_hz = 20000.0
	AudioServer.set_bus_effect_enabled(_music_bus, 0, on)


# --- Stand-in SFX -----------------------------------------------------------

func _build_sfx() -> void:
	_sfx_streams[&"coin"] = _tones([[1320.0, 0.06], [1760.0, 0.12]], 0.35, "sine")
	_sfx_streams[&"score"] = _tones([[880.0, 0.08]], 0.25, "triangle")
	_sfx_streams[&"served"] = _tones([[523.0, 0.07], [659.0, 0.07], [784.0, 0.12]], 0.3, "triangle")
	_sfx_streams[&"leaving"] = _tones([[330.0, 0.12], [247.0, 0.22]], 0.3, "triangle")
	_sfx_streams[&"kettle_ready"] = _tones([[1568.0, 0.25]], 0.25, "sine")
	_sfx_streams[&"till"] = _tones([[2093.0, 0.05]], 0.12, "sine")
	_sfx_streams[&"till_full"] = _tones([[523.0, 0.35], [659.0, 0.35], [784.0, 0.5]], 0.25, "sine", true)
	_sfx_streams[&"overflow"] = _tones([[180.0, 0.07]], 0.35, "square")
	_sfx_streams[&"ruined"] = _tones([[110.0, 0.15]], 0.45, "noise")
	_sfx_streams[&"refused"] = _tones([[200.0, 0.06]], 0.2, "square")
	_sfx_streams[&"record"] = _tones([[523.0, 0.1], [659.0, 0.1], [784.0, 0.1], [1047.0, 0.35]], 0.3, "triangle")
	_sfx_streams[&"match_end"] = _tones([[659.0, 0.15], [523.0, 0.35]], 0.25, "triangle")


## Notes in sequence (or together when chord) with a quick decay envelope.
func _tones(notes: Array, volume: float, wave: String, chord := false) -> AudioStreamWAV:
	var total := 0.0
	for n: Array in notes:
		total = maxf(total, n[1]) if chord else total + n[1]
	var frames := int(total * MIX_RATE) + 1
	var buf := PackedFloat32Array()
	buf.resize(frames)
	var start := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for n: Array in notes:
		var f: float = n[0]
		var len_s: float = n[1]
		var s0 := int(start * MIX_RATE)
		for i in int(len_s * MIX_RATE):
			var t := float(i) / MIX_RATE
			var ph := fmod(t * f, 1.0)
			var v := 0.0
			match wave:
				"sine": v = sin(TAU * ph)
				"triangle": v = 4.0 * absf(ph - 0.5) - 1.0
				"square": v = 1.0 if ph < 0.5 else -1.0
				"noise": v = rng.randf_range(-1.0, 1.0) * 0.6 + sin(TAU * ph) * 0.4
			var env := minf(1.0, t * 200.0) * exp(-4.0 * t / len_s)
			if s0 + i < frames:
				buf[s0 + i] += v * env * volume
		if not chord:
			start += len_s
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i in frames:
		data.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = data
	return wav
