# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30
extends Node3D
## Composition root and the one tick (ADR-0003): builds every module, wires
## signals, then per frame runs 0 start -> 1 clock -> 2 tap -> 3 barista ->
## 4 brewing -> 5 guests -> 6 save flush. Modules never see each other's nodes.

const CONFIG_PATH := "res://prototypes/tea-rush-vertical-slice/data/game_config.tres"
const ConfigLoader := preload("../foundation/config/config_loader.gd")
const PlatformBridge := preload("../foundation/platform_bridge.gd")
const GameClock := preload("../foundation/game_clock.gd")
const UtcClock := preload("../foundation/utc_clock.gd")
const Rng := preload("../foundation/rng.gd")
const SaveStore := preload("../foundation/save_store.gd")
const SaveBackends := preload("../foundation/save_backends.gd")
const ViewFit := preload("../foundation/view_fit.gd")
const KitchenLayout := preload("../foundation/kitchen_layout.gd")
const RecipeBook := preload("../core/recipe_book.gd")
const Pathing := preload("../core/pathing.gd")
const TapPicker := preload("../core/tap_picker.gd")
const BaristaController := preload("../core/barista_controller.gd")
const Brewing := preload("brewing.gd")
const GuestSim := preload("guest_sim.gd")
const Currency := preload("currency.gd")
const Till := preload("till.gd")
const MatchLifecycle := preload("match_lifecycle.gd")
const KitchenView := preload("../presentation/kitchen_view.gd")
const Hud := preload("../presentation/hud.gd")
const AudioDirector := preload("../presentation/audio_director.gd")
const PlaytestLog := preload("../debug/playtest_log.gd")

enum Boot { NAV_WAIT, PREWARM, DONE }

var _cfg: Resource
var _bridge: Node
var _save: RefCounted
var _clock: RefCounted
var _lifecycle: RefCounted
var _layout: RefCounted
var _pathing: RefCounted
var _book: RefCounted
var _brewing: RefCounted
var _guests: RefCounted
var _barista: RefCounted
var _currency: RefCounted
var _till: RefCounted
var _picker: RefCounted
var _camera: Camera3D
var _view_fit: Node
var _view: Node3D
var _hud: Node
var _audio: Node
var _boot := Boot.NAV_WAIT
var _prewarm_frames := 0
var _pending_tap: Variant = null
var _boot_rng := RandomNumberGenerator.new()
var _last_coins_added := 0
var _last_coins_earned := 0
var _last_score := 0
var _bot: RefCounted
var _playtest: RefCounted


func _ready() -> void:
	process_priority = -100
	var root := get_tree().root
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.content_scale_size = Vector2i(360, 640)
	if not OS.has_feature("web"):
		var size := Vector2i(405, 810)
		for arg: String in OS.get_cmdline_user_args():
			if arg.begins_with("--size="):
				var wh := arg.trim_prefix("--size=").split("x")
				size = Vector2i(int(wh[0]), int(wh[1]))
		get_window().size = size * maxi(1, roundi(DisplayServer.screen_get_scale()))
		get_window().move_to_center()
	# The bridge is a child here instead of an autoload so the slice never
	# touches project settings (prototype rule); same API as ADR-0001.
	_bridge = PlatformBridge.new()
	_bridge.name = "PlatformBridge"
	add_child(_bridge)
	var loaded := ConfigLoader.load_config(CONFIG_PATH)
	if not loaded.errors.is_empty():
		var lines: PackedStringArray = []
		for e: Dictionary in loaded.errors:
			lines.append("%s [%s] %s" % [e.path, e.rule, e.message])
			push_error("config: " + lines[-1])
		_bridge.fail_boot("\n".join(lines))
		set_process(false)
		return
	_cfg = loaded.config
	_compose()


func _compose() -> void:
	_save = SaveStore.new()
	_save.open(SaveBackends.WebStorageBackend.new() if OS.has_feature("web") else SaveBackends.FileBackend.new())
	_clock = GameClock.new(_cfg.guest.max_step_delta)
	_lifecycle = MatchLifecycle.new(_clock)
	_layout = KitchenLayout.new(_cfg.kitchen, _cfg.control)
	_pathing = Pathing.new(_layout, _cfg.control)
	_book = RecipeBook.new(_cfg.recipes)
	_brewing = Brewing.new(_layout, _book, _cfg.brewing)
	_guests = GuestSim.new(_clock, _book, _brewing, _cfg.guest, _cfg.difficulty, _cfg.kitchen)
	_barista = BaristaController.new(_layout, _pathing, _cfg.control, self)
	_currency = Currency.new(_book, _cfg.currency, _save.scope(&"currency"))
	_till = Till.new(_cfg.till, _save.scope(&"till"), UtcClock.new())
	_playtest = PlaytestLog.new(_save.scope(&"playtest"), _till)
	_picker = TapPicker.new(_layout, _cfg.view, _cfg.control)
	_boot_rng.randomize()

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = _cfg.view.background_color
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	_camera = Camera3D.new()
	add_child(_camera)
	_view_fit = ViewFit.new()
	add_child(_view_fit)
	_view_fit.setup(_camera, _cfg.view)
	_view = KitchenView.new()
	add_child(_view)
	_view.setup(_cfg, _layout, _book, _brewing, _guests, _barista, _till, _clock, _camera)
	_audio = AudioDirector.new()
	add_child(_audio)
	_audio.setup(_cfg.audio, _save.scope(&"settings"))
	_hud = Hud.new()
	add_child(_hud)
	_hud.setup(_cfg, _currency, _guests, _lifecycle, _audio, _view, _clock, _till)

	_bridge.safe_area_changed.connect(_view_fit.apply)
	_view_fit.playfield_changed.connect(_hud.on_playfield_changed)
	_bridge.visibility_changed.connect(_on_visibility_changed)
	_bridge.reduced_motion_changed.connect(_set_reduced_motion)
	_bridge.ready_reached.connect(_on_ready_reached)
	_lifecycle.match_started.connect(_on_match_started)
	_lifecycle.match_ended.connect(_on_match_ended)
	_lifecycle.paused_changed.connect(_on_paused_changed)
	_guests.served.connect(_currency.on_served)
	_guests.guest_served.connect(_on_guest_served)
	_guests.guest_left.connect(func(_s: int, _g: Dictionary) -> void: _audio.play(&"leaving"))
	_guests.target_vanished.connect(_barista.on_target_vanished)
	_guests.guests_lost_reached.connect(_lifecycle.on_guests_lost_reached)
	_currency.coins_earned.connect(_till.on_coins_earned)
	_currency.coins_earned.connect(func(n: int) -> void: _last_coins_earned = n)
	_currency.score_earned.connect(func(n: int) -> void: _last_score = n)
	_till.coins_added.connect(func(n: int, _e: int) -> void: _last_coins_added = n)
	_guests.guest_served.connect(func(_s: int, _g: Dictionary) -> void: _playtest.on_served())
	_guests.guest_left.connect(func(_s: int, _g: Dictionary) -> void: _playtest.on_left())
	_currency.coins_earned.connect(_playtest.on_coins_earned)
	_till.became_full.connect(func() -> void: _audio.play(&"till_full"))
	_brewing.kettle_ready.connect(func(_id: StringName) -> void: _audio.play(&"kettle_ready"))
	_brewing.cup_ruined.connect(func() -> void: _audio.play(&"ruined"))
	_brewing.refused.connect(func(_id: StringName) -> void: _audio.play(&"refused"))
	_hud.play_again_pressed.connect(_lifecycle.request_new_match)
	_hud.new_day_pressed.connect(_till.debug_new_day)
	_hud.start_pressed.connect(_lifecycle.on_ready_reached)

	_view_fit.apply(_bridge.get_safe_area())
	_lifecycle.on_visibility_changed(_bridge.is_visible())
	_set_reduced_motion(_bridge.prefers_reduced_motion())
	if "--bot" in OS.get_cmdline_user_args():
		_bot = preload("../debug/demo_bot.gd").new(self)
	_maybe_screenshot()


func _exit_tree() -> void:
	if _pathing:
		_pathing.dispose()


func _unhandled_input(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	if touch and touch.pressed:
		_pending_tap = touch.position
		return
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and mb.device != InputEvent.DEVICE_ID_EMULATION:
		_pending_tap = mb.position


func _process(delta: float) -> void:
	if _boot != Boot.DONE:
		_step_boot()
		return
	_lifecycle.apply_pending()                                   # 0
	var dt: float = _clock.advance(delta)                        # 1
	# Nothing simulates before the first match starts (start screen).
	var running: bool = dt > 0.0 and _lifecycle.state == MatchLifecycle.State.RUNNING
	_flush_tap(running)                                          # 2
	if running:
		if _bot:
			_bot.step()
		_barista.step(dt)                                        # 3
		_brewing.step(dt)                                        # 4
		_guests.step(dt)                                         # 5
	_audio.step_ui(_clock.ui_dt)
	_save.flush_if_dirty()                                       # 6


func _step_boot() -> void:
	match _boot:
		Boot.NAV_WAIT:
			if not _pathing.poll_ready():
				return
			var points: Array = []
			for id: StringName in _layout.station_ids:
				points.append_array(_layout.stations[id].spots)
			points.append_array(_layout.guest_serve_points)
			var msg: String = _pathing.verify(points)
			if msg != "":
				_bridge.fail_boot(msg)
				set_process(false)
				return
			_boot = Boot.PREWARM
		Boot.PREWARM:
			# Two drawn frames so every material is compiled before play.
			_prewarm_frames += 1
			if _prewarm_frames >= 2:
				_boot = Boot.DONE
				_bridge.mark_boot_complete()


func _flush_tap(accept: bool) -> void:
	if _pending_tap == null:
		return
	var pos: Vector2 = _pending_tap
	_pending_tap = null
	if not accept:
		return
	var occupied: Array = []
	for g: Variant in _guests.guests:
		occupied.append(g != null)
	var t: Dictionary = _picker.resolve(pos, _camera, _view_fit.kitchen_rect, occupied)
	if not t.is_empty():
		_barista.tap(t)


# --- Action router for the barista (Holding contract) -------------------------

func is_valid(t: Dictionary) -> bool:
	return _brewing.is_valid(t.id) if t.kind == &"station" else _guests.is_valid(t.id)


func offer(t: Dictionary) -> int:
	return _brewing.offer(t.id) if t.kind == &"station" else _guests.offer(t.id)


# --- Lifecycle ----------------------------------------------------------------

func _on_ready_reached() -> void:
	# The first match waits for the start button (owner decision 2026-09-30).
	if "--bot" in OS.get_cmdline_user_args() or "--autostart" in OS.get_cmdline_user_args():
		_lifecycle.on_ready_reached()
	else:
		_hud.show_start()
	_audio.start_music_fetch(_bridge.asset_url(_cfg.audio.music_file_name))


func _on_match_started() -> void:
	var match_seed := _boot_rng.randi()
	print_debug("match_seed %d" % match_seed)
	_brewing.reset()
	_currency.on_match_started()
	_till.on_match_started()
	_playtest.on_match_started()
	_barista.reset()
	_guests.reset(Rng.new(Rng.derive(match_seed, "guest_tier")), Rng.new(Rng.derive(match_seed, "guest_recipe")))
	_view.on_match_started()
	_hud.on_match_started()
	_audio.on_match_started()


func _on_match_ended() -> void:
	_currency.on_match_ended()
	_barista.stop()
	_view.on_match_ended()
	_hud.playtest_line = _playtest.on_match_ended(_clock.t)
	_hud.on_match_ended()
	_audio.on_match_ended(_currency.is_new_record)


func _on_paused_changed(paused: bool) -> void:
	_hud.on_paused_changed(paused)
	_audio.on_paused_changed(paused)


func _on_visibility_changed(visible: bool) -> void:
	_lifecycle.on_visibility_changed(visible)
	if not visible:
		_save.flush_if_dirty()


func _on_guest_served(slot: int, _g: Dictionary) -> void:
	_audio.play(&"served")
	_audio.play(&"coin" if _last_coins_added > 0 else &"overflow")
	_audio.play(&"score")
	_hud.on_served_popups(slot, _last_coins_added, _last_coins_earned, _last_score)


func _set_reduced_motion(v: bool) -> void:
	_view.reduced_motion = v
	_hud.reduced_motion = v


## Dev aid: `-- --shot=/path.png [--shot-at=seconds]` saves a frame and quits.
func _maybe_screenshot() -> void:
	var path := ""
	var at := 6.0
	var pause_at := -1.0
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			path = arg.trim_prefix("--shot=")
		elif arg.begins_with("--shot-at="):
			at = float(arg.trim_prefix("--shot-at="))
		elif arg.begins_with("--pause-at="):
			pause_at = float(arg.trim_prefix("--pause-at="))
	if path == "":
		return
	if pause_at >= 0.0:
		await get_tree().create_timer(pause_at).timeout
		_lifecycle.request_pause()
		at -= pause_at
	await get_tree().create_timer(at).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()
