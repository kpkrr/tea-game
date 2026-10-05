# ART PREVIEW - NOT FOR PRODUCTION
# UI redesign s7 port, section 2 (design/ux/ui-redesign-s7-port.md; mock12.ropes_signs / plaque_img).
extends Control
## Order plaques hanging on ropes from the top bar, one per queued guest, oldest on the
## left. Final-drink cup + price, recipe stickers on the bottom rim, patience timer in
## the rim channel (clockwise from 12 o'clock). Device-px space (scaled by 1/sc).

const Kit := preload("ui_kit.gd")
const PW := 74.0          # dp, plaque width
const PH := 56.0          # dp, board height
const GAP := 10.0         # dp between plaques
const CUP_DP := 22.0
const CP_GAP := 5.0       # dp between cup and price
const PRICE_DP := 18.0
const SLOTS := 4
# plaqueC.png measurements (src px): board top row, rim channel insets (outer, inner), rope centres.
const SRC_TOP := 361
const CUT := 99           # max(T inner, B inner) + 12
const INS_L := Vector2(44, 80)
const INS_R := Vector2(46, 82)
const INS_T := Vector2(53, 87)
const INS_B := Vector2(49, 84)
const ROPES := [113.0, 389.5]
const TILTS := [-10.0, 7.0, -5.0, 11.0, -8.0]
const TIMER_STOPS := [[1.0, Color8(108, 194, 74)], [0.6, Color8(242, 194, 48)], [0.25, Color8(240, 120, 106)], [0.0, Color8(216, 50, 60)]]
const MUTE := 0.35
const MUTE_TO := Color8(92, 70, 60)

const TIMER_SHADER := """
shader_type canvas_item;
uniform float board_y;          // board top inside the texture, px
uniform vec2 board_size;        // w, h px
uniform vec4 outer;             // L, T, R, B insets px (channel outer edge)
uniform vec4 inner;             // L, T, R, B insets px (channel inner edge)
uniform float pat = 1.0;
uniform vec4 col : source_color;
bool in_rect(vec2 p, vec4 r) {
	return p.x >= r.x && p.x < board_size.x - r.z && p.y >= r.y && p.y < board_size.y - r.w;
}
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec2 px = floor(UV / TEXTURE_PIXEL_SIZE);
	vec2 p = vec2(px.x, px.y - board_y);
	if (p.y >= 0.0 && p.y < board_size.y && in_rect(p, outer) && !in_rect(p, inner)) {
		float ang = mod(degrees(atan(p.x - (board_size.x - 1.0) / 2.0, -(p.y - (board_size.y - 1.0) / 2.0))) + 360.0, 360.0);
		if (ang >= 360.0 * (1.0 - pat)) {
			c.rgb = col.rgb;
		}
	}
	COLOR = c;
}
"""

var reduced_motion := false
var flash_s := 0.3

var _guests: RefCounted
var _book: RefCounted
var _brewing: RefCounted
var _sc := 1.0
var _shader: Shader
var _base: ImageTexture      # board + attachments, no content
var _w := 0
var _h := 0
var _oy := 0
var _fin_h := 0
var _s := 1.0
var _rope: ImageTexture
var _rope_xs: Array[int] = []
var _xs: Array[int] = []     # plaque left x (device px) per queue position
var _y := 0
var _rope_top := 0
var _warn: ImageTexture
var _urgent: ImageTexture
var _plaques := {}           # uid -> {root, mat, ropes, bubble, x, drop, fade, flash, recipe}
var _last_match: StringName = &""
var _t := 0.0


func setup(guests: RefCounted, book: RefCounted, brewing: RefCounted) -> void:
	_guests = guests
	_book = book
	_brewing = brewing
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shader = Shader.new()
	_shader.code = TIMER_SHADER


func _dp(v: float) -> int:
	return Kit.pyround(v * _sc)


## Rebuild for device scale sc under the bar's visible inner part (dp).
func layout(sc: float, inner_x_dp: float, inner_w_dp: float, bar_h_dp: float) -> void:
	_sc = sc
	scale = Vector2.ONE / sc
	_w = _dp(PW)
	_h = _dp(PH)
	_s = float(_w) / 512.0
	var full := Kit.img("plaqueC")
	var board := Kit.crop(full, 0, SRC_TOP, 512, full.get_height())
	var bh_src := board.get_height()
	var tp := Kit.rescale(Kit.crop(board, 0, 0, 512, CUT), _s)
	tp = Kit.resized(tp, _w, tp.get_height())
	var bt := Kit.rescale(Kit.crop(board, 0, bh_src - CUT, 512, bh_src), _s)
	bt = Kit.resized(bt, _w, bt.get_height())
	var mid := Kit.resized(Kit.crop(board, 0, CUT, 512, bh_src - CUT), _w, maxi(1, _h - tp.get_height() - bt.get_height()))
	var b := Kit.blank(_w, _h)
	Kit.paste(b, tp, 0, 0)
	Kit.paste(b, mid, 0, tp.get_height())
	Kit.paste(b, bt, 0, _h - bt.get_height())
	var att := Kit.rescale(Kit.crop(full, 0, SRC_TOP - 200, 512, SRC_TOP + int(CUT * 0.5)), _s)
	att = Kit.resized(att, _w, att.get_height())
	_oy = att.get_height() - int(CUT * 0.5 * _s)
	_fin_h = _oy + _h + _dp(4)
	var fin := Kit.blank(_w, _fin_h)
	Kit.paste(fin, b, 0, _oy)
	Kit.paste(fin, att, 0, 0)
	_base = Kit.tex(fin)
	var rp := Kit.rescale(Kit.img("ropeC"), _s)
	_rope = Kit.tex(rp)
	_rope_xs.clear()
	for r: float in ROPES:
		_rope_xs.append(int(r * _s - rp.get_width() / 2.0))
	var total := SLOTS * PW + (SLOTS - 1) * GAP
	var x0 := inner_x_dp + (inner_w_dp - total) / 2.0
	_xs.clear()
	for i in SLOTS:
		var cx := x0 + i * (PW + GAP) + PW / 2.0
		_xs.append(int(_dp(cx) - _w / 2.0))
	_y = _dp(bar_h_dp + 30) - _oy + _dp(4)
	_rope_top = _dp(bar_h_dp - 6)
	_warn = Kit.tex(Kit.fit(Kit.img("bubble_warn"), _dp(18)))
	_urgent = Kit.tex(Kit.fit(Kit.img("bubble_urgent"), _dp(20)))
	for uid: int in _plaques.keys():
		_plaques[uid].root.queue_free()
	_plaques.clear()


func clear() -> void:
	for uid: int in _plaques.keys():
		_plaques[uid].root.queue_free()
	_plaques.clear()


func step(dt: float, active: bool) -> void:
	_t += dt
	visible = active
	if not active or _base == null:
		return
	var m: StringName = _brewing.held_match()
	var flash_new := m != &"" and m != _last_match
	_last_match = m
	var queue: Array = _guests.queue()
	var alive := {}
	for i in queue.size():
		var g: Dictionary = queue[i]
		alive[g.uid] = true
		if not g.uid in _plaques:
			_plaques[g.uid] = _make(g, _xs[mini(i, SLOTS - 1)])
		var p: Dictionary = _plaques[g.uid]
		var tx: float = _xs[mini(i, SLOTS - 1)]
		p.x = tx if reduced_motion else lerpf(p.x, tx, 1.0 - exp(-14.0 * dt))
		if absf(p.x - tx) < 0.5:
			p.x = tx
		p.drop = maxf(p.drop - dt, 0.0)
		if flash_new and g.recipe == m:
			p.flash = flash_s
		p.flash = maxf(p.flash - dt, 0.0)
		_update(p, _guests.remaining_fraction(g))
	for uid: int in _plaques.keys():
		if uid in alive:
			continue
		var p: Dictionary = _plaques[uid]
		p.fade += dt
		p.root.modulate.a = clampf(1.0 - p.fade / 0.2, 0.0, 1.0)
		if p.fade >= 0.2 or reduced_motion:
			p.root.queue_free()
			_plaques.erase(uid)


func _make(g: Dictionary, x: int) -> Dictionary:
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var ropes: Array[TextureRect] = []
	for rx: int in _rope_xs:
		var r := TextureRect.new()
		r.texture = _rope
		r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		r.stretch_mode = TextureRect.STRETCH_TILE
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.position.x = rx
		root.add_child(r)
		ropes.append(r)
	# Everything on the plaque is clipped to its image (mock: composited into one canvas).
	var clip := Control.new()
	clip.clip_contents = true
	clip.size = Vector2(_w, _fin_h)
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(clip)
	var board := TextureRect.new()
	board.texture = _base
	board.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	mat.set_shader_parameter("board_y", float(_oy))
	mat.set_shader_parameter("board_size", Vector2(_w, _h))
	mat.set_shader_parameter("outer", Vector4(INS_L.x, INS_T.x, INS_R.x, INS_B.x) * _s)
	mat.set_shader_parameter("inner", Vector4(INS_L.y, INS_T.y, INS_R.y, INS_B.y) * _s)
	board.material = mat
	clip.add_child(board)
	_content(clip, g)
	var bubble := TextureRect.new()
	bubble.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.visible = false
	root.add_child(bubble)
	return {"root": root, "mat": mat, "ropes": ropes, "bubble": bubble, "x": float(x),
		"drop": 0.0 if reduced_motion else 0.25, "fade": 0.0, "flash": 0.0}


## mock11/12: final-drink cup + price centred in the parchment; recipe stickers on the bottom rim.
func _content(clip: Control, g: Dictionary) -> void:
	var steps: Array = _book.token_steps(g.recipe)
	var il := INS_L.y * _s
	var ir := _w - INS_R.y * _s
	var it := INS_T.y * _s
	var ib := _h - INS_B.y * _s
	var dr := Kit.cup_img(Kit.cup_state([&"cup"] + steps), _dp(CUP_DP))
	var cut_y := maxi(0, dr.get_height() - _dp(CUP_DP) - _dp(3))
	dr = Kit.crop(dr, 0, cut_y, dr.get_width(), dr.get_height())
	var price := str(_book.recipe_price(g.recipe))
	var fpx := _dp(PRICE_DP)
	var tw := Kit.font().get_string_size(price, HORIZONTAL_ALIGNMENT_LEFT, -1, fpx).x
	var tot := dr.get_width() + _dp(CP_GAP) + tw
	var x0 := int((il + ir) / 2.0 - tot / 2.0)
	var yc := int((it + ib) / 2.0)
	var cup := TextureRect.new()
	cup.texture = Kit.tex(dr)
	cup.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	cup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cup.position = Vector2(x0, _oy + yc - floori(dr.get_height() / 2.0) - _dp(1))
	clip.add_child(cup)
	var text := Control.new()
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.size = clip.size
	var tx := x0 + dr.get_width() + _dp(CP_GAP)
	var mid := float(_oy + yc + _dp(1))
	text.draw.connect(func() -> void:
		text.draw_string(Kit.font(), Vector2(tx, Kit.baseline_for_middle(mid, fpx)), price,
				HORIZONTAL_ALIGNMENT_LEFT, -1, fpx, Kit.INK))
	clip.add_child(text)
	# Stickers: cup first, then the recipe steps in the fixed order; tilted, overlapping 1 dp.
	var order: Array = [&"cup"]
	for st: StringName in Kit.RECIPE_ORDER:
		if st != &"cup" and st in steps:
			order.append(st)
	var u := _dp(1)
	var items := []
	var rw := 0
	for i in order.size():
		var im := Kit.sticker(order[i], u)
		var ang: float = TILTS[i % TILTS.size()]
		var ex := _expanded(im.get_size(), ang)
		items.append([im, ang, ex])
		rw += ex.x
	rw += -_dp(1) * (order.size() - 1)
	var x := int(_w / 2.0 - rw / 2.0)
	var hb := _oy + _h
	for i in items.size():
		var im: Image = items[i][0]
		var ex: Vector2i = items[i][2]
		var y := hb - _dp(3) - floori(ex.y / 2.0) + (_dp(1) if i % 2 == 1 else 0)
		var shadow := _tilted(Kit.silhouette(im), items[i][1], ex)
		shadow.modulate = Color8(20, 12, 8, 90)
		shadow.position = Vector2(x + _dp(1), y + _dp(1))
		clip.add_child(shadow)
		var face := _tilted(im, items[i][1], ex)
		face.position = Vector2(x, y)
		clip.add_child(face)
		x += ex.x - _dp(1)


## PIL rotate(expand=True) canvas size.
func _expanded(sz: Vector2i, ang: float) -> Vector2i:
	var a := deg_to_rad(ang)
	var hx := sz.x / 2.0 * absf(cos(a)) + sz.y / 2.0 * absf(sin(a))
	var hy := sz.x / 2.0 * absf(sin(a)) + sz.y / 2.0 * absf(cos(a))
	return Vector2i(int(ceil(sz.x / 2.0 + hx) - floor(sz.x / 2.0 - hx)), int(ceil(sz.y / 2.0 + hy) - floor(sz.y / 2.0 - hy)))


## A box of the expanded size holding the image rotated about its centre (PIL: + = counter-clockwise).
func _tilted(im: Image, ang: float, ex: Vector2i) -> Control:
	var box := Control.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.size = Vector2(ex)
	var t := TextureRect.new()
	t.texture = Kit.tex(im)
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.size = Vector2(im.get_size())
	t.position = (Vector2(ex) - t.size) / 2.0
	t.pivot_offset = t.size / 2.0
	t.rotation = deg_to_rad(-ang)
	box.add_child(t)
	return box


func _update(p: Dictionary, pat: float) -> void:
	var k: float = p.drop / 0.25
	var yoff: float = -_dp(26) * k * k
	var root: Control = p.root
	root.position = Vector2(roundi(p.x), _y + roundi(yoff))
	root.modulate.a = 1.0 - k
	var f: float = p.flash / maxf(flash_s, 0.001)
	root.self_modulate = Color.WHITE
	for c: Node in root.get_children():
		if c is Control and c != p.bubble:
			(c as Control).modulate = Color(1 + 0.6 * f, 1 + 0.6 * f, 1 + 0.6 * f)
	# Ropes from just under the bar's bottom edge to the plaque's attachments.
	var top := _rope_top - int(root.position.y)
	for r: TextureRect in p.ropes:
		r.position.y = top
		r.size = Vector2(_rope.get_width(), maxf(1.0, 4 - top))
	var mat: ShaderMaterial = p.mat
	mat.set_shader_parameter("pat", pat)
	mat.set_shader_parameter("col", timer_color(pat))
	var b: TextureRect = p.bubble
	b.visible = pat <= 0.6
	if b.visible:
		var urgent := pat <= 0.25
		b.texture = _urgent if urgent else _warn
		b.size = b.texture.get_size()
		var cx := _w - _dp(3)
		var cy := _oy + _dp(2)
		b.position = Vector2(int(cx - b.size.x / 2.0), int(cy - b.size.y / 2.0))
		b.pivot_offset = b.size / 2.0
		var hz := 2.0 if urgent else 0.5
		b.scale = Vector2.ONE * (1.0 if reduced_motion else 1.0 + 0.08 * sin(_t * TAU * hz))


## mock4.timer_col + mock9 mute (35 % toward the empty-channel brown).
static func timer_color(fr: float) -> Color:
	var c: Color = TIMER_STOPS[3][1]
	for i in 3:
		var hi: Array = TIMER_STOPS[i]
		var lo: Array = TIMER_STOPS[i + 1]
		if lo[0] <= fr and fr <= hi[0]:
			var t := (fr - float(lo[0])) / (float(hi[0]) - float(lo[0]))
			var a: Color = lo[1]
			var b: Color = hi[1]
			c = Color8(int(a.r8 + (b.r8 - a.r8) * t), int(a.g8 + (b.g8 - a.g8) * t), int(a.b8 + (b.b8 - a.b8) * t))
			break
	return Color8(int(c.r8 * (1 - MUTE) + MUTE_TO.r8 * MUTE), int(c.g8 * (1 - MUTE) + MUTE_TO.g8 * MUTE),
			int(c.b8 * (1 - MUTE) + MUTE_TO.b8 * MUTE))


## Viewport dp of a guest's plaque centre (popups); null if none.
func plaque_pos_dp(uid: int) -> Variant:
	if not uid in _plaques:
		return null
	var p: Dictionary = _plaques[uid]
	return (Vector2(p.x + _w / 2.0, _y + _oy + _h / 2.0)) / _sc
