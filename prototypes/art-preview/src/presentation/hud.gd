# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30
extends Node
## HUD (design/ux/hud.md): one top row (score, strikes | pause, mute), popups,
## pause overlay, results overlay. Stores nothing: reads upstream every frame.
## The only writes it performs: request_pause/resume/new_match and set_muted.

signal play_again_pressed()
signal new_day_pressed()
signal start_pressed()

const Art := preload("pixel_art.gd")
const Kit := preload("ui_kit.gd")
const TopBar := preload("top_bar.gd")
const OrderBoard := preload("order_board.gd")

const INK := Color(0.24, 0.16, 0.12)
const PAPER := Color(0.99, 0.96, 0.88)
const PAPER_DARK := Color(0.93, 0.86, 0.72)
const GOLD := Color(0.86, 0.58, 0.1)
const MINT := Color(0.12, 0.6, 0.55)
const RECORD := Color(0.85, 0.35, 0.25)

enum Mode { INACTIVE, ACTIVE, PAUSED, MATCH_END }

var mode := Mode.INACTIVE
var reduced_motion := false

var _cfg: Resource
var _currency: RefCounted
var _guests: RefCounted
var _lifecycle: RefCounted
var _audio: Node
var _view: Node3D
var _clock: RefCounted

var _row_layer: CanvasLayer
var _bar: Control             # UI s7 top bar (top_bar.gd)
var _board: Control           # UI s7 hanging order plaques (order_board.gd)
var _ui_key := Vector3.ZERO   # viewport + device scale the bar was laid out for
var _book: RefCounted
var _brewing: RefCounted
var _start: Control
var _start_button: Button
var _start_best: Label
var _heart_pulse: Array[float] = [0.0, 0.0, 0.0]
var _popup_layer: CanvasLayer
var _popups: Array = []
var _overlay_layer: CanvasLayer
var _pause_overlay: Control
var _continue_button: Button
var _results: Control
var _results_panel: Control
var _results_score: Label
var _results_best: Label
var _results_record: Label
var _results_coins: Label
var _results_playtest: Label
## Set by the director before on_match_ended (playtest measurement, not GDD).
var playtest_line := ""
var _till: RefCounted
var _again_button: Button
var _results_t := 0.0
var _playfield := Rect2()
var _kitchen := Rect2()
var _lost_seen := 0
var _pending_strikes := 0


func setup(cfg: Resource, currency: RefCounted, guests: RefCounted, lifecycle: RefCounted, audio: Node,
		view: Node3D, clock: RefCounted, till: RefCounted, book: RefCounted = null, brewing: RefCounted = null) -> void:
	_till = till
	_book = book
	_brewing = brewing
	_cfg = cfg
	_currency = currency
	_guests = guests
	_lifecycle = lifecycle
	_audio = audio
	_view = view
	_clock = clock
	var theme := _make_theme()
	_popup_layer = CanvasLayer.new()
	_popup_layer.layer = 5
	add_child(_popup_layer)
	_overlay_layer = CanvasLayer.new()
	_overlay_layer.layer = 6
	add_child(_overlay_layer)
	_row_layer = CanvasLayer.new()
	_row_layer.layer = 7
	add_child(_row_layer)
	_build_row()
	_build_pause(theme)
	_build_results(theme)
	_build_start(theme)
	_row_layer.visible = false


func on_playfield_changed(playfield: Rect2, kitchen_rect: Rect2) -> void:
	_playfield = playfield
	_kitchen = kitchen_rect
	_ui_key = Vector3.ZERO   # re-layout the bar next frame
	for panel: Control in [_pause_overlay.get_child(1), _results_panel, _start.get_child(1)]:
		panel.custom_minimum_size.x = minf(kitchen_rect.size.x * 0.8, 300)


func on_match_started() -> void:
	mode = Mode.ACTIVE
	_start.visible = false
	_row_layer.visible = true
	_results.visible = false
	_pause_overlay.visible = false
	_lost_seen = 0
	_heart_pulse = [0.0, 0.0, 0.0]
	_board.clear()
	for p: Dictionary in _popups:
		p.node.queue_free()
	_popups.clear()


func on_match_ended() -> void:
	mode = Mode.MATCH_END
	_pause_overlay.visible = false
	_results.visible = true
	_results.modulate.a = 0.0
	_results_t = 0.0
	_again_button.disabled = true
	_results_score.text = str(mini(_currency.match_score, _cfg.hud.score_display_cap))
	_results_best.text = "Best: %d" % _currency.best_score
	_results_record.visible = _currency.is_new_record
	_results_coins.text = "Coins this shift: +%d\nTill: %d / %d%s" % [_till.match_added, _till.till_amount,
		_till.till_capacity, " — full until tomorrow" if _till.is_full else ""]
	_results_playtest.text = playtest_line
	_again_button.grab_focus()


func on_paused_changed(_paused: bool) -> void:
	var user: bool = _lifecycle.is_user_paused()
	if mode == Mode.ACTIVE and user:
		mode = Mode.PAUSED
		_pause_overlay.visible = true
		_continue_button.grab_focus()
	elif mode == Mode.PAUSED and not user:
		mode = Mode.ACTIVE
		_pause_overlay.visible = false


## A served cup: coins fly to the till line of the plaque, score to the score line (hud.md E12).
func on_served_popups(from: Vector2, coins_added: int, coins_earned: int, score: int) -> void:
	var till: Vector2 = _bar.till_pos_dp()
	var score_pos: Vector2 = _bar.score_pos_dp()
	if coins_added > 0:
		_spawn_popup("+%d" % coins_added, "coin", Kit.GOLD_INK, from, till)
	if coins_added < coins_earned:
		_spawn_popup("", "coin", Color(0.6, 0.55, 0.5), till, till + Vector2(18, 26), 0.3)
	_spawn_popup("+%d" % score, "star", Kit.MINT, from + Vector2(0, -20), score_pos)


func _process(_delta: float) -> void:
	if _clock == null or mode == Mode.INACTIVE:
		return
	var sim_dt: float = _clock.sim_dt
	var ui_dt: float = _clock.ui_dt
	var fx_dt := ui_dt if mode == Mode.MATCH_END else sim_dt
	_relayout_if_needed()
	var lost: int = clampi(_guests.guests_lost, 0, 3)
	for i in range(_lost_seen, lost):
		# Strikes go out right to left, staggered like the leaving pulses.
		_heart_pulse[2 - i] = _cfg.hud.strike_pulse_s + (i - _lost_seen) * _cfg.hud.leaving_pulse_stagger_s
	_lost_seen = lost
	var pulse := []
	for i in 3:
		_heart_pulse[i] = maxf(_heart_pulse[i] - fx_dt, 0.0)
		var k: float = clampf(_heart_pulse[i] / _cfg.hud.strike_pulse_s, 0.0, 1.0)
		pulse.append(1.0 + (0.35 * sin(k * PI) if not reduced_motion else 0.0))
	_bar.set_state(mini(_currency.match_score, _cfg.hud.score_display_cap),
			"%d/%d" % [_till.till_amount, _till.till_capacity], lost, pulse, _audio.is_muted(), mode != Mode.MATCH_END)
	_board.reduced_motion = reduced_motion
	_board.step(fx_dt, mode == Mode.ACTIVE or mode == Mode.PAUSED)
	_update_popups(fx_dt)
	if mode == Mode.MATCH_END:
		_results_t += ui_dt
		var fade: float = _cfg.hud.results_fade_s
		_results.modulate.a = clampf(_results_t / fade, 0.0, 1.0)
		var ready: bool = _results_t >= fade + _cfg.hud.restart_input_grace_s
		if ready and _again_button.disabled:
			_again_button.disabled = false
			if not reduced_motion:
				_again_button.pivot_offset = _again_button.size / 2.0
				_again_button.scale = Vector2.ONE * 1.08
		_again_button.scale = _again_button.scale.lerp(Vector2.ONE, minf(1.0, ui_dt * 8.0))


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or key.keycode != KEY_ESCAPE:
		return
	if mode == Mode.ACTIVE:
		_lifecycle.request_pause()
	elif mode == Mode.PAUSED:
		_lifecycle.request_resume()
	get_viewport().set_input_as_handled()


# --- Building ---------------------------------------------------------------

func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 18
	t.set_color("font_color", "Label", INK)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(state, "Button", INK)
	t.set_color("font_disabled_color", "Button", INK.lerp(PAPER, 0.55))
	t.set_color("icon_normal_color", "Button", Color.WHITE)
	var normal := _box(PAPER, INK, 3)
	var hover := _box(Color(1, 0.99, 0.94), INK, 3)
	var pressed := _box(PAPER_DARK, INK, 3)
	pressed.content_margin_top += 2
	var disabled := _box(PAPER.lerp(PAPER_DARK, 0.5), INK.lerp(PAPER, 0.5), 3)
	var focus := _box(Color(0, 0, 0, 0), MINT, 3)
	focus.expand_margin_left = 3
	focus.expand_margin_right = 3
	focus.expand_margin_top = 3
	focus.expand_margin_bottom = 3
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("hover_pressed", "Button", pressed)
	t.set_stylebox("disabled", "Button", disabled)
	t.set_stylebox("focus", "Button", focus)
	t.set_stylebox("panel", "PanelContainer", _box(PAPER, INK, 4, 18))
	return t


func _box(bg: Color, border: Color, width: int, pad := 8) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(10)
	s.set_content_margin_all(pad)
	return s


func _build_row() -> void:
	# UI s7: wooden bar + hanging order plaques, both laid out in device px (mock12).
	_board = OrderBoard.new()
	_board.setup(_guests, _book, _brewing)
	_board.flash_s = _cfg.hud.flash_s
	_row_layer.add_child(_board)
	_bar = TopBar.new()
	_row_layer.add_child(_bar)
	_bar.pause_pressed.connect(func() -> void:
		if mode == Mode.ACTIVE:
			_lifecycle.request_pause()
		elif mode == Mode.PAUSED:
			_lifecycle.request_resume())
	_bar.mute_pressed.connect(func() -> void: _audio.set_muted(not _audio.is_muted()))


func _relayout_if_needed() -> void:
	var vp := get_viewport().get_visible_rect().size
	var sc := float(get_window().size.x) / vp.x
	var key := Vector3(vp.x, vp.y, sc)
	if key == _ui_key:
		return
	_ui_key = key
	_bar.layout(vp, sc)
	_board.layout(sc, _bar.inner_x_dp, _bar.inner_w_dp, TopBar.BAR_H)


func _counter_label(font_size: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", font_size)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


func _icon_rect(name: String, size: int) -> TextureRect:
	var r := TextureRect.new()
	r.texture = Art.icon(name)
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = Vector2(size, size)
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _icon_button(icon: String) -> Button:
	var b := Button.new()
	var s: int = _cfg.hud.hud_button_size_dp
	b.custom_minimum_size = Vector2(s, s)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.icon = Art.icon(icon)
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	b.focus_mode = Control.FOCUS_NONE
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_constant_override("icon_max_width", s - 14)
	return b


func _dim() -> ColorRect:
	var dim := ColorRect.new()
	dim.color = Color(0.2, 0.14, 0.1, _cfg.hud.pause_dim_alpha)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	return dim


func _build_pause(theme: Theme) -> void:
	_pause_overlay = Control.new()
	_pause_overlay.theme = theme
	_pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pause_overlay.visible = false
	_overlay_layer.add_child(_pause_overlay)
	_pause_overlay.add_child(_dim())
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_pause_overlay.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	box.add_child(_title("Paused", 26))
	_continue_button = Button.new()
	_continue_button.text = "Resume"
	_continue_button.custom_minimum_size = Vector2(160, 52)
	_continue_button.add_theme_font_size_override("font_size", 20)
	_continue_button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	_continue_button.pressed.connect(func() -> void: _lifecycle.request_resume())
	box.add_child(_continue_button)


func _build_results(theme: Theme) -> void:
	_results = Control.new()
	_results.theme = theme
	_results.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_results.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_results.visible = false
	_overlay_layer.add_child(_results)
	_results.add_child(_dim())
	_results_panel = PanelContainer.new()
	_results_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_results_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_results_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_results.add_child(_results_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_results_panel.add_child(box)
	box.add_child(_title("Shift over", 22))
	var score_row := HBoxContainer.new()
	score_row.alignment = BoxContainer.ALIGNMENT_CENTER
	score_row.add_theme_constant_override("separation", 10)
	box.add_child(score_row)
	var star := _icon_rect("star", 32)
	star.modulate = Color(0.55, 1.4, 1.3)
	score_row.add_child(star)
	_results_score = _title("0", 44)
	score_row.add_child(_results_score)
	_results_record = _title("New best!", 22)
	_results_record.add_theme_color_override("font_color", RECORD)
	box.add_child(_results_record)
	_results_best = _title("Best: 0", 18)
	box.add_child(_results_best)
	_results_coins = _title("", 16)
	box.add_child(_results_coins)
	_results_playtest = _title("", 12)
	_results_playtest.modulate = Color(1, 1, 1, 0.6)
	box.add_child(_results_playtest)
	_again_button = Button.new()
	_again_button.text = "Play again"
	_again_button.custom_minimum_size = Vector2(200, 56)
	_again_button.add_theme_font_size_override("font_size", 22)
	_again_button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	_again_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_again_button.pressed.connect(func() -> void:
		_again_button.disabled = true
		play_again_pressed.emit())
	box.add_child(_again_button)
	# Demo aid, not in the GDD: empties the till without waiting for 00:00 UTC.
	var new_day := Button.new()
	new_day.text = "New day (demo)"
	new_day.flat = true
	new_day.focus_mode = Control.FOCUS_NONE
	new_day.add_theme_font_size_override("font_size", 14)
	new_day.pressed.connect(func() -> void: new_day_pressed.emit())
	box.add_child(new_day)


## Start screen (owner decision 2026-09-30, the GDD had none): the press on
## "Start shift" is also the browser gesture that unlocks music.
func _build_start(theme: Theme) -> void:
	_start = Control.new()
	_start.theme = theme
	_start.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_start.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_start.visible = false
	_overlay_layer.add_child(_start)
	_start.add_child(_dim())
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_start.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	box.add_child(_title("Tea Rush", 34))
	var hint := _title("Brew and serve tea\nbefore the guests leave", 16)
	box.add_child(hint)
	_start_best = _title("", 16)
	box.add_child(_start_best)
	_start_button = Button.new()
	_start_button.text = "Start shift"
	_start_button.custom_minimum_size = Vector2(200, 56)
	_start_button.add_theme_font_size_override("font_size", 22)
	_start_button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	_start_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_start_button.pressed.connect(func() -> void:
		_start_button.disabled = true
		start_pressed.emit())
	box.add_child(_start_button)


func show_start() -> void:
	_start.visible = true
	_start_best.text = "Best: %d   ·   Till: %d / %d" % [_currency.best_score, _till.till_amount, _till.till_capacity]
	_start_button.grab_focus()


func _title(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	return l


# --- Popups -----------------------------------------------------------------

func _spawn_popup(text: String, icon: String, color: Color, from: Vector2, to: Vector2, dur := -1.0) -> void:
	if _popups.size() >= _cfg.hud.popup_max_concurrent:
		var oldest: Dictionary = _popups.pop_front()
		oldest.node.queue_free()
	var node := HBoxContainer.new()
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_theme_constant_override("separation", 2)
	node.add_child(_popup_icon(icon))
	if text != "":
		var l := Label.new()
		l.text = text
		l.add_theme_font_override("font", Kit.font())
		l.add_theme_font_size_override("font_size", 24)
		l.add_theme_color_override("font_color", color)
		l.add_theme_color_override("font_outline_color", PAPER)
		l.add_theme_constant_override("outline_size", 7)
		node.add_child(l)
	_popup_layer.add_child(node)
	node.position = from
	_popups.append({"node": node, "from": from, "to": to, "t": 0.0,
		"dur": dur if dur > 0.0 else _cfg.hud.popup_s})


## Popup icon: the plaque's coin art for coins, the pixel star for score.
func _popup_icon(icon: String) -> TextureRect:
	var r := _icon_rect(icon, 18)
	if icon == "coin":
		r.texture = load(Kit.DIR + "hud_coin.png")
		r.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return r


func _update_popups(dt: float) -> void:
	for i in range(_popups.size() - 1, -1, -1):
		var p: Dictionary = _popups[i]
		p.t += dt
		var k := clampf(p.t / p.dur, 0.0, 1.0)
		var node: Control = p.node
		if reduced_motion:
			node.position = p.to
		else:
			var e := 1.0 - pow(1.0 - k, 2.0)
			node.position = p.from.lerp(p.to, e) + Vector2(0, -40.0 * sin(k * PI))
		node.modulate.a = 1.0 if k < 0.75 else (1.0 - k) * 4.0
		if k >= 1.0:
			node.queue_free()
			_popups.remove_at(i)
