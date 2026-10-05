# ART PREVIEW - NOT FOR PRODUCTION
# UI redesign s7 port, section 1 (design/ux/ui-redesign-s7-port.md; mock12.bar_hud / hud_on_bar).
extends Control
## Top wooden bar: score/till plaque, 3 hearts, pause, sound. Laid out in DEVICE px
## (this node is scaled by 1/sc) so every number matches the Pillow mockup.

signal pause_pressed()
signal mute_pressed()

const Kit := preload("ui_kit.gd")
const BAR_H := 68.0                       # dp, visible bar height
const CAP_SRC := 120                      # layout: end-cap width, source px
const CAP_ART := 125                      # art 3-slice: end-cap width, source px (mock4.wood_bar_art)
const BAR_INNER_BOTTOM := 229.0 / 245.0   # last plank row above the bottom outline
const PLQ_ICON_R := (135.0 + 10.0) / 769.0   # score plaque: right edge of the star/coin icons

var score := 0
var till_text := "0/0"
var muted := false
## Visible inner part of the bar (dp): where the order plaques hang.
var inner_x_dp := 0.0
var inner_w_dp := 360.0

var _sc := 1.0
var _bar := TextureRect.new()
var _plaque := TextureRect.new()
var _hearts: Array[TextureRect] = []
var _heart_tex: Array[Texture2D] = []    # full, empty
var _pause := TextureButton.new()
var _mute := TextureButton.new()
var _text := Control.new()
var _tx := 0
var _score_mid := 0.0
var _coin_mid := 0.0
var _score_px := 23
var _coin_px := 19


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for t: TextureRect in [_bar, _plaque]:
		_px(t)
		add_child(t)
	for i in 3:
		var h := TextureRect.new()
		_px(h)
		add_child(h)
		_hearts.append(h)
	for b: TextureButton in [_pause, _mute]:
		b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		b.ignore_texture_size = true
		b.stretch_mode = TextureButton.STRETCH_KEEP
		b.focus_mode = Control.FOCUS_NONE
		b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.button_down.connect(func() -> void: b.self_modulate = Color(0.82, 0.78, 0.74))
		b.button_up.connect(func() -> void: b.self_modulate = Color.WHITE)
		add_child(b)
	_pause.pressed.connect(func() -> void: pause_pressed.emit())
	_mute.pressed.connect(func() -> void: mute_pressed.emit())
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text.draw.connect(_draw_text)
	add_child(_text)


func _px(t: TextureRect) -> void:
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.stretch_mode = TextureRect.STRETCH_KEEP
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE


func _dp(v: float) -> int:
	return Kit.pyround(v * _sc)


## Rebuild for a viewport (dp) at device scale sc.
func layout(vp: Vector2, sc: float) -> void:
	_sc = sc
	scale = Vector2.ONE / sc
	position = Vector2.ZERO
	var fw := Kit.pyround(vp.x * sc)
	var pl := Kit.fit(Kit.img("hud_score_plaque"), _dp(46))
	var hf := Kit.fit(Kit.img("hud_heart_full"), _dp(22))
	var he := Kit.fit(Kit.img("hud_heart_empty"), _dp(22))
	var hw := hf.get_width() * 2 + he.get_width() + _dp(3) * 2
	var b0 := Kit.fit(Kit.img("hud_btn_pause"), _dp(40))
	var b1 := Kit.fit(Kit.img("hud_btn_sound"), _dp(40))
	var content := pl.get_width() + hw + b0.get_width() + b1.get_width()
	var bar_img := Kit.img("hud_bar")
	var s := _dp(BAR_H) / (bar_img.get_height() * 0.86)
	var cap := Kit.pyround(CAP_SRC * s)
	var bx: int
	var bw: int
	var inner: int
	if content + 3 * _dp(8) + 2 * _dp(6) + 2 * cap <= fw - _dp(8):   # wide: whole bar, content between the caps
		inner = content + 3 * _dp(14) + 2 * _dp(8)
		bw = inner + 2 * cap
		bx = floori((fw - bw) / 2.0)
	else:                                                               # phone: caps run off-screen
		bx = -cap + _dp(2)
		bw = fw + 2 * cap - _dp(4)
		inner = bw - 2 * cap
	var full_h := Kit.pyround(bar_img.get_height() * s)
	var off := full_h - _dp(BAR_H)
	_put(_bar, Kit.nine_h(bar_img, bw, full_h, CAP_ART, s), Vector2(bx, -off))
	var yc := int((bar_img.get_height() * s * BAR_INNER_BOTTOM - off) / 2.0)
	var gap := (inner - 2 * _dp(8) - content) / 3.0
	var x := float(bx + cap + _dp(8))
	var xs: Array[int] = []
	for w: int in [pl.get_width(), hw, b0.get_width(), b1.get_width()]:
		xs.append(int(x))
		x += w + gap
	var vis_l := maxi(0, bx + cap)
	var vis_r := mini(fw, bx + bw - cap)
	inner_x_dp = vis_l / sc
	inner_w_dp = (vis_r - vis_l) / sc
	var ph := pl.get_height()
	_put(_plaque, pl, Vector2(xs[0], yc - floori(ph / 2.0)))
	_heart_tex = [Kit.tex(hf), Kit.tex(he)]
	var hx := xs[1]
	for i in 3:
		var im := hf if i < 2 else he
		_hearts[i].texture = _heart_tex[0 if i < 2 else 1]
		_hearts[i].size = Vector2(im.get_size())
		_hearts[i].position = Vector2(hx, yc - floori(im.get_height() / 2.0))
		_hearts[i].pivot_offset = _hearts[i].size / 2.0
		hx += im.get_width() + _dp(3)
	for pair: Array in [[_pause, b0, xs[2]], [_mute, b1, xs[3]]]:
		var b: TextureButton = pair[0]
		var im: Image = pair[1]
		b.texture_normal = Kit.tex(im)
		b.size = Vector2(im.get_size())
		b.position = Vector2(pair[2], yc - floori(im.get_height() / 2.0))
	var y := yc - floori(ph / 2.0)
	_tx = xs[0] + int(pl.get_width() * PLQ_ICON_R) + _dp(4)
	_score_mid = y + ph * 0.30
	_coin_mid = y + ph * 0.72
	_score_px = _dp(23)
	_coin_px = _dp(19)
	_text.size = Vector2(fw, _dp(BAR_H))
	_text.queue_redraw()


func _put(t: TextureRect, im: Image, at: Vector2) -> void:
	t.texture = Kit.tex(im)
	t.size = Vector2(im.get_size())
	t.position = at


## Per frame: strikes (lost from the right), heart pulse scale, mute look.
func set_state(new_score: int, new_till: String, lost: int, pulse: Array, is_muted: bool, pause_enabled: bool) -> void:
	if new_score != score or new_till != till_text:
		score = new_score
		till_text = new_till
		_text.queue_redraw()
	if _heart_tex.is_empty():
		return
	for i in 3:
		_hearts[i].texture = _heart_tex[0 if i < 3 - lost else 1]
		_hearts[i].scale = Vector2.ONE * float(pulse[i])
	_mute.modulate = Color(0.62, 0.6, 0.6) if is_muted else Color.WHITE
	_pause.disabled = not pause_enabled


func _draw_text() -> void:
	var f := Kit.font()
	_text.draw_string(f, Vector2(_tx, Kit.baseline_for_middle(_score_mid, _score_px)), str(score),
			HORIZONTAL_ALIGNMENT_LEFT, -1, _score_px, Kit.MINT)
	_text.draw_string(f, Vector2(_tx, Kit.baseline_for_middle(_coin_mid, _coin_px)), till_text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, _coin_px, Kit.GOLD_INK)


## Viewport dp of the score / till numbers (popups fly there).
func score_pos_dp() -> Vector2:
	return Vector2(_tx + _dp(14), _score_mid) / _sc


func till_pos_dp() -> Vector2:
	return Vector2(_tx + _dp(30), _coin_mid) / _sc
