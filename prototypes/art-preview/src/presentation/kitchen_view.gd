# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30
extends Node3D
## The 2.5D world: one static vertex-coloured mesh for floor and counters, pixel
## sprites for everything alive. Reads sim state every frame, owns no rules.
## Effects run on sim_dt (freeze with pause); after match end, pulses finish on ui_dt.

const Art := preload("pixel_art.gd")
const Kit := preload("ui_kit.gd")
const TapPicker := preload("../core/tap_picker.gd")
const ViewFitMath := preload("../foundation/view_fit_math.gd")
const ViewFit := preload("../foundation/view_fit.gd")
const ART := "res://prototypes/art-preview/art/"
const CHAR_H := 2.1          # chibi height on the plate (v1-a proportions), m
const CHAR_W := 1.0          # guests keep the v1-a cut-out proportions (owner)
const BARISTA_H := 2.45      # owner: the hero reads a bit bigger
const BARISTA_W := 1.0       # no width stretch: keep the v1-a proportions (owner)
const FEET_SINK := 0.04      # feet slightly into the floor so they read as standing
const WALK_FPS := 8.0
const VFX_FPS := 8.0
const PLATE_PX := Vector2(2304, 3456)   # plate-v14 (GPT outpaint); original v9 frame sits at (384, 704)
const FILL_REGION := Rect2(0, 0, 2304, 1300)   # cliffs + water only: blurred backdrop around the plate
# Plate-pixel spots of painted light sources (art/plate.png).
const LANTERNS := [Vector2(1157, 1117), Vector2(437, 1424), Vector2(1857, 1424), Vector2(514, 2354)]
const HEARTH_GLOWS := [Vector2(719, 1949), Vector2(1594, 1959)]
# [mask sprite, plate px of its top-left, halo centre, halo scale, is fire, kettle id]
const FLAMES := [
	["fire_ring_l", Vector2(479, 1844), Vector2(580, 1885), 1.3, true, &"kettle_100"],
	["fire_mouth_l", Vector2(679, 1884), Vector2(710, 1957), 1.2, true, &"kettle_100"],
	["fire_ring_r", Vector2(1649, 1844), Vector2(1736, 1886), 1.3, true, &"kettle_80"],
	["fire_mouth_r", Vector2(1524, 1894), Vector2(1604, 1963), 1.0, true, &"kettle_80"],
	["lantern_0", Vector2(1097, 1034), Vector2(1159, 1143), 2.6, false, &""],
	["lantern_1", Vector2(384, 1344), Vector2(457, 1463), 2.6, false, &""],
	["lantern_2", Vector2(1797, 1344), Vector2(1852, 1455), 2.6, false, &""],
	["lantern_3", Vector2(454, 2274), Vector2(528, 2368), 2.6, false, &""],
]
const KETTLE_PX := {&"kettle_100": Vector2(564, 1824), &"kettle_80": Vector2(1739, 1824)}
const CHAR_TINT := Color(0.98, 0.95, 0.93)
# Time of day (owner): morning -> day -> evening -> night -> morning, looping on sim
# time; each phase holds DAY_HOLD s, then blends into the next over DAY_BLEND s.
# Feeds art/grade.gdshader: outside the light mask the frame takes `dusk` (tint) and
# `sat`, the kitchen takes the hue of `lit` (brightness and contrast stay as by day, so
# it is equally crisp in every phase); `lamps` scales lantern glow; `haze` = outside mist.
const DAY_HOLD := 30.0
const DAY_BLEND := 15.0
const DAY_PHASES := [
	{"dusk": Vector3(0.93, 0.85, 0.9), "sat": 0.7, "lit": Vector3(1.08, 0.95, 0.96), "vig": 0.15, "lamps": 0.35, "haze": 0.2},   # morning mist
	{"dusk": Vector3(1.0, 1.0, 1.0), "sat": 1.0, "lit": Vector3(1.0, 1.0, 1.0), "vig": 0.06, "lamps": 0.0, "haze": 0.0},        # day
	{"dusk": Vector3(0.8, 0.68, 0.76), "sat": 0.85, "lit": Vector3(1.04, 0.98, 0.95), "vig": 0.32, "lamps": 0.75, "haze": 0.0}, # evening
	{"dusk": Vector3(0.36, 0.42, 0.66), "sat": 0.55, "lit": Vector3(1.06, 1.0, 0.9), "vig": 0.45, "lamps": 1.0, "haze": 0.0},   # night
]
# Reference window for the look (vignettes): the plate area a 16:10 desktop shows.
const LOOK_REF_VP := Vector2(1280, 800)
# Guests come up the painted stairs (presentation only; the sim walks them along x).
const STAIRS_TOP := Vector3(0, 0, 4.59)
const STAIRS_BOTTOM := Vector3(0, -1.4, 6.48)
const OFFSCREEN := Vector3(0, -1.4, 9.6)    # below the bottom edge of the plate

const ICON_PX := 0.06
# UI s7 (design/ux/ui-redesign-s7-port.md): the queue stands on the stairs in a checkerboard, the
# first guest just below the counter (mock6 COL, phone 360x800 dp: feet points, front -> back).
const QUEUE_PHONE_DP := [Vector2(170, 700), Vector2(196, 730), Vector2(166, 760), Vector2(192, 790)]
const PHONE_VP := Vector2(360, 800)
const SLOT_CUP_M := 0.36           # slot cup height (cup_empty basis): ~15 dp like the held cup
const SIGN_TYPES := [&"cup", &"leaf_green", &"leaf_black", &"water_100", &"water_80", &"iced_tea", &"lemon"]
const ISLAND := [&"iced_tea", &"lemon"]
const GAUGE_FILL := Vector2(46, 346)   # gauge art: amber fill columns (src px)
const READY_STEAM_LIFT := 0.0          # plate px: READY steam above the kettle sign board
const SHIRTS := [Color(0.93, 0.55, 0.45), Color(0.55, 0.7, 0.93), Color(0.95, 0.78, 0.4),
	Color(0.7, 0.55, 0.85), Color(0.5, 0.8, 0.75), Color(0.95, 0.65, 0.75)]
const HAIRS := [Color(0.45, 0.28, 0.16), Color(0.2, 0.15, 0.12), Color(0.85, 0.65, 0.35), Color(0.6, 0.3, 0.2)]
const FLOOR_A := Color(0.96, 0.91, 0.83)
const FLOOR_B := Color(0.92, 0.86, 0.77)
const HALL_A := Color(0.9, 0.93, 0.93)
const HALL_B := Color(0.86, 0.9, 0.9)
const WOOD_TOP := Color(0.87, 0.72, 0.54)
const WOOD_FRONT := Color(0.73, 0.56, 0.4)
const WALL := Color(0.86, 0.93, 0.88)
const WALL_TRIM := Color(0.74, 0.84, 0.78)

var reduced_motion := false
## Dev aid (`--clean-ui`): hide every pixel-art overlay so a UI mockup can be drawn on the frame.
var clean_ui := false
## Dev aid (`--no-guests`): hide guest sprites too (mockups re-place them).
var no_guests := false
var _ui_layer: CanvasLayer      # world UI over the grade (gauges, held cup), device-px space
var _ui_root: Control
var _held_rect: TextureRect
var _held_key := ""
var _gauges := {}                # kettle id -> {root, empty, full, type}
var _sign_decal: Sprite2D        # station signs, behind the 3D world (occluders sample it too)
var _kettle_decal: Sprite2D      # kettle signs (fg layer, over the 3D world, under the steam)
var _masks := {}                 # station type -> {img: Image (RGBA, alpha = mask), off: Vector2 (phone frame px)}
var _layout_key := Vector4.ZERO  # viewport + device scale + shift the UI was built for
var _queue_world: Array = []     # world feet points of the 4 queue spots
var _shadow_tex: Texture2D
var _slot_tex := {}              # cup state -> Texture2D (slot cups)
var _till_cross: Sprite3D
var _till_cross_t := 0.0

var _cfg: Resource
var _layout: RefCounted
var _brewing: RefCounted
var _guests: RefCounted
var _barista: RefCounted
var _till: RefCounted
var _clock: RefCounted
var _book: RefCounted
var _camera: Camera3D
var _pitch: float

var _badges := {}        # station id -> Sprite3D (flash target)
var _crosses := {}       # station id -> Sprite3D
var _flash := {}         # station id -> remaining s
var _kettle_nodes := {}  # id -> {sprite, fire, steam, glow, phase}
var _slot_nodes := {}    # id -> {cup, row, shown}
var _barista_node: Node3D
var _barista_body: Sprite3D
var _walk_phase := 0.0
var _barista_shadow: Sprite3D
var _uprights: Array[Sprite3D] = []
var _tex := {}           # name -> Texture2D
var _plate_root: Node2D
var _bg_layer: CanvasLayer
var _plate_fill: Sprite2D
var _grade_mat: ShaderMaterial
var _fg_root: Node2D     # plate-space VFX drawn over the 3D world (steam, fire, hearth glow)
var _occluder_mat: ShaderMaterial
var _halos: Array = []
var _flames: Array = []   # {dim: ShaderMaterial, glow, halo, fire, kettle, phase}
var _steam2d := {}       # kettle id -> Sprite2D
var _guest_nodes := {}   # uid -> {root, body, shadow, flip, sel, wobble, bob}
var _pulses: Array = []  # {node, t, start, dur}
var _pulse_last_start := -INF
var _local_t := 0.0
var _day_t := 0.0
var _lamps := 1.0
var _outline: Sprite3D
var _sel_glow: Sprite3D
var _sel_t := 0.0
const SEL_S := 0.35
var _floor_ring: Sprite3D
var _floor_ring_t := -1.0
var _till_node: Node3D
var _till_fill: Sprite3D
var _till_star: Sprite3D
var _till_thump := 0.0
var _till_thump_len := 0.2
var _last_match: StringName = &""
var _ended := false


func setup(cfg: Resource, layout: RefCounted, book: RefCounted, brewing: RefCounted, guests: RefCounted,
		barista: RefCounted, till: RefCounted, clock: RefCounted, camera: Camera3D) -> void:
	_cfg = cfg
	_layout = layout
	_book = book
	_brewing = brewing
	_guests = guests
	_barista = barista
	_till = till
	_clock = clock
	_camera = camera
	_pitch = deg_to_rad(cfg.view.camera_pitch_deg)
	_build_static()
	_build_stations()
	_build_barista()
	_build_till()
	_sel_glow = _sprite(_soft_tex(), 1.4 / 128.0, true, 1)
	_sel_glow.modulate = Color(1.0, 0.95, 0.8, 0.0)
	_sel_glow.scale = Vector3(1.0, 0.6, 1.0)
	add_child(_sel_glow)
	_outline = _sprite(Art.bracket(24), 0.05, true, 3)
	_outline.visible = false
	add_child(_outline)
	_floor_ring = _sprite(Art.floor_ring(24), 0.03, false)
	_floor_ring.rotation.x = -PI / 2
	_floor_ring.visible = false
	add_child(_floor_ring)
	brewing.refused.connect(_on_refused)
	brewing.held_changed.connect(_on_held_changed)
	guests.guest_refused.connect(_on_guest_refused)
	guests.till_refused.connect(_on_till_refused)
	guests.guest_left.connect(_on_guest_left)
	barista.target_changed.connect(_on_target_changed)
	till.coins_added.connect(_on_coins_added)


## Screen position (dp) of a world point, for HUD popups.
func screen_pos(p: Vector3) -> Vector2:
	return _camera.unproject_position(p)


func till_screen_pos() -> Vector2:
	return screen_pos(_cfg.kitchen.till_anchor + Vector3(0, 0.4, 0))


## Head of a guest (served popups start there); falls back to the till.
func guest_screen_pos(uid: int) -> Vector2:
	if uid in _guest_nodes:
		var n: Dictionary = _guest_nodes[uid]
		return screen_pos(n.root.global_position + Vector3(0, CHAR_H * 0.8, 0))
	return till_screen_pos()


func on_match_started() -> void:
	_ended = false
	_day_t = _day_start()
	for uid: int in _guest_nodes.keys():
		_guest_nodes[uid].root.queue_free()
	_guest_nodes.clear()
	for p: Dictionary in _pulses:
		p.node.queue_free()
	_pulses.clear()
	_pulse_last_start = -INF
	_outline.visible = false
	_floor_ring.visible = false


func on_match_ended() -> void:
	_ended = true
	# Results cover the kitchen: frozen guests stay.
	_outline.visible = false
	_floor_ring.visible = false


func _process(_delta: float) -> void:
	if _clock == null:
		return
	var dt: float = _clock.sim_dt
	var fx_dt: float = _clock.ui_dt if _ended else dt
	_local_t += dt
	_day_t += dt
	_update_daylight()
	_relayout_if_needed()
	_update_kettles(dt)
	_update_slots()
	_update_barista(dt)
	_update_guests(dt)
	_update_till(dt)
	_update_effects(dt, fx_dt)
	_update_uprights()
	_update_plate()
	if clean_ui:
		_hide_overlays()


func _hide_overlays() -> void:
	_ui_layer.visible = false
	_sign_decal.visible = false
	_kettle_decal.visible = false
	for n: Dictionary in _slot_nodes.values():
		n.cup.visible = false
	for n: Dictionary in _guest_nodes.values():
		if no_guests:
			n.root.visible = false


## Dev aid: screen positions (viewport px) and state of every UI anchor, for mockups.
func ui_anchors() -> Dictionary:
	var px := func(v: Vector3) -> Array:
		var p := _camera.unproject_position(v)
		return [snappedf(p.x, 0.1), snappedf(p.y, 0.1)]
	var guests := []
	for g: Variant in _guests.guests:
		if g == null or not g.uid in _guest_nodes:
			continue
		var n: Dictionary = _guest_nodes[g.uid]
		var root: Vector3 = n.root.global_position
		var head: float = CHAR_H * 0.97 * n.body.scale.y
		guests.append({"slot": g.slot, "state": g.state, "feet": px.call(root),
			"head": px.call(root + Vector3(0, head, 0)),
			"steps": _book.token_steps(g.recipe), "price": _book.recipe_price(g.recipe),
			"patience": _guests.remaining_fraction(g), "level": _guests.patience_level(g)})
	var stations := {}
	for id: StringName in _layout.station_ids:
		var s: Dictionary = _layout.stations[id]
		var st := {"type": s.type, "top": px.call(Vector3(s.pos.x, s.top, s.pos.y)),
			"front": px.call(Vector3(s.pos.x, s.top, s.pos.y + s.size.y / 2.0))}
		if id in _brewing.kettles:
			var k: Dictionary = _brewing.kettles[id]
			st["state"] = k.state
			st["progress"] = 1.0 - k.t / maxf(k.t_total, 0.001) if k.state == 1 else (1.0 if k.state == 2 else 0.0)
		if id in _brewing.slots and _brewing.slots[id] != null:
			st["cup"] = _brewing.slots[id].steps
		stations[id] = st
	var held: Variant = _brewing.held
	var b: Vector3 = _barista_node.global_position
	return {"guests": guests, "stations": stations,
		"barista": {"feet": px.call(b), "hand": px.call(b + Vector3(0.3, 0.75, 0.12)),
			"head": px.call(b + Vector3(0, BARISTA_H, 0)),
			"held": null if held == null else held.steps, "match": held != null and _brewing.held_match() != &""},
		"till": {"pos": px.call(_cfg.kitchen.till_anchor), "amount": _till.till_amount, "cap": _till.till_capacity}}


# --- Building ---------------------------------------------------------------

func _sprite(tex: Texture2D, px: float, overlay: bool, priority := 0) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = tex
	s.pixel_size = px
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.shaded = false
	if overlay:
		s.no_depth_test = true
		s.render_priority = priority
		s.rotation.x = -_pitch
		s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	else:
		s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	return s


## Upright world sprite standing on its origin; its scale.y follows the
## per-sprite perspective stretch (ADR-0002 amendment point 4), see _update_uprights.
func _upright(tex: Texture2D, px: float) -> Sprite3D:
	var s := _sprite(tex, px, false)
	s.offset.y = tex.get_height() / 2.0
	s.scale.y = 1.0 / cos(_pitch)
	_uprights.append(s)
	return s


## Painted art (v1-a cut-outs): smooth filtering, opaque-prepass alpha for soft edges.
func _art(name: String, height_m: float) -> Sprite3D:
	var tex := _art_tex(name)
	var s := _upright(tex, height_m / tex.get_height())
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	return s


func _art_tex(name: String) -> Texture2D:
	if not name in _tex:
		_tex[name] = load(ART + name + ".png")
	return _tex[name]


func _build_static() -> void:
	_build_plate()
	_build_occluders()


## Painted plate (art/plate.png) behind the 3D world, plus 2D light and VFX in
## plate pixel space: lantern halos, hearth fire, steam, water glints.
func _build_plate() -> void:
	var bg := CanvasLayer.new()
	bg.layer = -10
	add_child(bg)
	_bg_layer = bg
	_plate_fill = Sprite2D.new()   # wide backdrop (GPT outpaint) continuing the plate on desktop windows
	_plate_fill.texture = _art_tex("plate_wide")
	_plate_fill.centered = false
	_plate_fill.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	bg.add_child(_plate_fill)
	_plate_root = Node2D.new()
	bg.add_child(_plate_root)
	var plate := Sprite2D.new()
	plate.texture = _art_tex("plate")
	plate.centered = false
	plate.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS   # pixel-art plate-v14 (GPT), mipmaps for phone downscale
	var mat := ShaderMaterial.new()
	mat.shader = load(ART + "plate_water.gdshader")
	plate.material = mat
	_plate_root.add_child(plate)
	# Station signs (UI s7): device-px decal right over the plate, so the 3D world (barista)
	# passes in front of them and the counter occluders repaint them like painted pixels.
	_sign_decal = Sprite2D.new()
	_sign_decal.centered = false
	_sign_decal.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.add_child(_sign_decal)
	# World UI drawn over the grade, like the mockup pasted it on the finished frame.
	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 2
	add_child(_ui_layer)
	_ui_root = Control.new()
	_ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_layer.add_child(_ui_root)
	_held_rect = TextureRect.new()
	_held_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_held_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_held_rect.visible = false
	_ui_root.add_child(_held_rect)
	var fg := CanvasLayer.new()
	fg.layer = 0
	add_child(fg)
	_fg_root = Node2D.new()
	fg.add_child(_fg_root)
	# Front fence posts cut from the plate: drawn over the 3D world so queued guests stand behind them.
	for post: Array in [["post_l", Vector2(752, 2582)], ["post_r", Vector2(1498, 2572)]]:
		var sp := Sprite2D.new()
		sp.texture = _art_tex(post[0])
		sp.set_meta(&"post", true)
		sp.centered = false
		sp.position = post[1]
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		_fg_root.add_child(sp)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var halo := _halo_tex()
	# Painted flames and lantern glass flicker in place: each light has its own mask
	# cut from the plate. Low = the painted light dims toward embers (multiply),
	# high = it glows (the same pixels added) with a soft halo. Drawn over the 3D
	# world because the counter occluders repaint the plate under them.
	for l: Array in FLAMES:
		var tex := _art_tex(l[0])
		var mul := Sprite2D.new()
		mul.texture = tex
		mul.centered = false
		mul.position = l[1]
		var mm := ShaderMaterial.new()
		mm.shader = load(ART + "light_dim.gdshader")
		mul.material = mm
		_fg_root.add_child(mul)
		var glow := Sprite2D.new()
		glow.texture = tex
		glow.centered = false
		glow.position = l[1]
		glow.material = add
		_fg_root.add_child(glow)
		var h := Sprite2D.new()
		h.texture = halo
		h.material = add
		h.position = l[2]
		h.scale = Vector2.ONE * l[3]
		h.modulate = Color(1.0, 0.62, 0.3, 0.0) if l[4] else Color(1.0, 0.8, 0.5, 0.0)
		_fg_root.add_child(h)
		_flames.append({"dim": mm, "glow": glow, "halo": h, "fire": l[4], "kettle": l[5], "phase": _flames.size() * 2.37})
	_kettle_decal = Sprite2D.new()
	_kettle_decal.centered = false
	_kettle_decal.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fg.add_child(_kettle_decal)
	fg.move_child(_kettle_decal, 0)   # before _fg_root: kettle steam rolls in front of the sign (owner)
	# Warm grade + vignette over the whole frame (characters included), under the HUD.
	var fx := CanvasLayer.new()
	fx.layer = 1
	add_child(fx)
	var grade := ColorRect.new()
	grade.set_anchors_preset(Control.PRESET_FULL_RECT)
	grade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gm := ShaderMaterial.new()
	gm.shader = load(ART + "grade.gdshader")
	gm.set_shader_parameter("light_mask", _art_tex("light_mask"))
	gm.set_shader_parameter("kitchen_mask", _art_tex("kitchen_mask"))
	grade.material = gm
	_grade_mat = gm
	fx.add_child(grade)


func _light(parent: Node2D, tex: Texture2D, mat: Material, pos: Vector2, size: float, col: Color,
		alpha: float, amount: float, speed: float) -> void:
	var h := Sprite2D.new()
	h.texture = tex
	h.material = mat
	h.position = pos
	h.scale = Vector2.ONE * size
	h.modulate = Color(col, alpha)
	parent.add_child(h)
	_halos.append({"node": h, "alpha": alpha, "size": size, "amount": amount, "speed": speed})


## 0 = dimmed to embers, 1 = full glow. Fire: fast and uneven with short deep
## dips; lanterns: slow candle breathing. A cold kettle's hearth stays low.
func _flicker(l: Dictionary) -> float:
	if reduced_motion:
		return 0.6
	var t := _local_t + float(l.phase)
	var n: float
	if l.fire:
		n = 0.5 + 0.28 * sin(t * 7.1) + 0.16 * sin(t * 12.7 + 1.3) + 0.08 * sin(t * 23.3 + 0.7)
		n -= 0.35 * pow(maxf(sin(t * 1.9 + 0.4), 0.0), 6.0)
		if l.kettle != &"" and _brewing.kettles[l.kettle].state == 0:
			n *= 0.55
	else:
		n = 0.6 + 0.22 * sin(t * 2.3) + 0.12 * sin(t * 5.9 + 1.1) + 0.06 * sin(t * 11.0)
	return clampf(n, 0.0, 1.0)


func _halo_tex() -> Texture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.25, Color(1, 1, 1, 0.45))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 128
	t.height = 128
	return t


## Plate pixel -> viewport dp (same zoom/crop as ViewFit).
func _plate_xform() -> Transform2D:
	return ViewFit.plate_xform(get_viewport().get_visible_rect().size)


## Invisible-looking blockers: counters re-draw the plate pixels under them, so
## characters walking behind a counter are hidden by the painted counter.
func _build_occluders() -> void:
	_occluder_mat = ShaderMaterial.new()
	_occluder_mat.shader = load(ART + "plate_occluder.gdshader")
	_occluder_mat.set_shader_parameter("plate", _art_tex("plate"))
	var k: Resource = _cfg.kitchen
	var h: float = k.countertop_height
	for c: Dictionary in k.countertops:
		_occluder(Vector3(c.pos.x, 0, c.pos.y), Vector3(c.size.x, h, c.size.y))
	var fc: Dictionary = k.front_counter
	_occluder(Vector3(fc.pos.x, 0, fc.pos.y), Vector3(fc.size.x, fc.height, fc.size.y))
	for id: StringName in _layout.station_ids:
		var s: Dictionary = _layout.stations[id]
		var top: float = 1.35 if String(s.type).begins_with("water_") else s.top
		_occluder(Vector3(s.pos.x, 0, s.pos.y), Vector3(s.size.x, top, s.size.y))
	var fr: Rect2 = k.floor_rect
	_occluder(Vector3(fr.get_center().x, 0, fr.position.y + 0.15), Vector3(fr.size.x, 1.2, 0.3))


func _occluder(pos: Vector3, size: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.material_override = _occluder_mat
	mi.position = pos + Vector3(0, size.y / 2.0, 0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


func _update_plate() -> void:
	var xf := _plate_xform()
	_plate_root.transform = xf
	# Look reference (vignettes) follows the kitchen shift, scaled to the reference window.
	var vp_now := get_viewport().get_visible_rect().size
	var ref := ViewFit.plate_xform(LOOK_REF_VP, ViewFit.shift_y(vp_now) * LOOK_REF_VP.y / vp_now.y).affine_inverse()
	var r0 := ref * Vector2.ZERO
	_grade_mat.set_shader_parameter("ref_rect", Vector4(r0.x / PLATE_PX.x, r0.y / PLATE_PX.y,
			(ref * LOOK_REF_VP - r0).x / PLATE_PX.x, (ref * LOOK_REF_VP - r0).y / PLATE_PX.y))
	var vp0 := get_viewport().get_visible_rect().size
	var ws: float = xf.get_scale().x * ViewFit.WIDE_PX.size.y / float(_plate_fill.texture.get_height())
	_plate_fill.transform = Transform2D(0.0, Vector2(ws, ws), 0.0, xf.origin + ViewFit.WIDE_PX.position * xf.get_scale().x)
	_plate_fill.visible = xf.origin.x > 0.5
	_fg_root.transform = xf
	var vp := get_viewport().get_visible_rect().size
	var r := Rect2(xf.origin / vp, PLATE_PX * xf.get_scale() / vp)
	_occluder_mat.set_shader_parameter("plate_rect", Vector4(r.position.x, r.position.y, r.size.x, r.size.y))
	if _sign_decal.texture != null:
		var dr := Rect2(_sign_decal.position / vp, _sign_decal.texture.get_size() * _sign_decal.scale / vp)
		_occluder_mat.set_shader_parameter("decal_rect", Vector4(dr.position.x, dr.position.y, dr.size.x, dr.size.y))
		_occluder_mat.set_shader_parameter("decal_on", 1.0 if _sign_decal.visible else 0.0)
	_grade_mat.set_shader_parameter("plate_rect", Vector4(r.position.x, r.position.y, r.size.x, r.size.y))
	var lantern_sum := 0.0
	for l: Dictionary in _flames:
		var i := _flicker(l)
		if not l.fire:
			lantern_sum += i
		var dim_amt := (1.0 - i) * (0.75 if l.fire else 0.5)
		(l.dim as ShaderMaterial).set_shader_parameter("dim", dim_amt)
		l.glow.modulate.a = i * (0.9 if l.fire else 0.55 * _lamps)
		l.halo.modulate.a = (0.05 + 0.2 * i) if l.fire else (0.12 + 0.28 * i) * _lamps
	# Light pools breathe with the lanterns (0.6 = their resting level).
	_grade_mat.set_shader_parameter("light_gain", 1.0 + 0.1 * _lamps * (lantern_sum / 4.0 - 0.6))


## Blends the two neighbouring DAY_PHASES for the current _day_t into the grade.
func _update_daylight() -> void:
	var span := DAY_HOLD + DAY_BLEND
	var cycle := fposmod(_day_t, span * DAY_PHASES.size())
	var i := int(cycle / span)
	var a: Dictionary = DAY_PHASES[i]
	var b: Dictionary = DAY_PHASES[(i + 1) % DAY_PHASES.size()]
	var k := smoothstep(DAY_HOLD, span, cycle - i * span)
	_lamps = lerpf(a.lamps, b.lamps, k)
	_grade_mat.set_shader_parameter("dusk_tint", (a.dusk as Vector3).lerp(b.dusk, k))
	_grade_mat.set_shader_parameter("dusk_sat", lerpf(a.sat, b.sat, k))
	_grade_mat.set_shader_parameter("lit_tint", (a.lit as Vector3).lerp(b.lit, k))
	_grade_mat.set_shader_parameter("dusk_vignette", lerpf(a.vig, b.vig, k))
	_grade_mat.set_shader_parameter("haze", lerpf(a.haze, b.haze, k))


## Dev aid: `-- --day-at=seconds` starts the match at that point of the cycle (screenshots).
func _day_start() -> float:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--day-at="):
			return float(arg.trim_prefix("--day-at="))
	return 0.0


func _build_stations() -> void:
	for id: StringName in _layout.station_ids:
		var s: Dictionary = _layout.stations[id]
		var front_z: float = s.pos.y + s.size.y / 2.0 - 0.25
		var base := Vector3(s.pos.x, s.top, front_z)
		if s.type == &"slot":
			var cup := _upright(_slot_cup_tex("empty"), SLOT_CUP_M / Kit.CUP_BASE_H)
			cup.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			cup.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
			cup.position = Vector3(s.pos.x, s.top, s.pos.y + 0.1)
			cup.visible = false
			add_child(cup)
			_slot_nodes[id] = {"cup": cup, "shown": null}
			_badges[id] = cup
			continue
		# The plate paints every station; badge is an empty flash/cross anchor.
		var badge := Sprite3D.new()
		badge.position = base
		if String(s.type).begins_with("water_"):
			var kp: Vector2 = KETTLE_PX[id]
			var steam := Sprite2D.new()
			steam.position = kp + Vector2(0, -150)
			steam.visible = false
			_fg_root.add_child(steam)
			_steam2d[id] = steam
			_kettle_nodes[id] = {"phase": float(_kettle_nodes.size()) * 0.37}
			var groot := Control.new()
			groot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			groot.visible = false
			_ui_root.add_child(groot)
			var empty := TextureRect.new()
			var full := TextureRect.new()
			for t: TextureRect in [empty, full]:
				t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				t.mouse_filter = Control.MOUSE_FILTER_IGNORE
				t.stretch_mode = TextureRect.STRETCH_KEEP
				groot.add_child(t)
			full.clip_contents = true
			_gauges[id] = {"root": groot, "empty": empty, "full": full, "type": s.type, "w": 0}
		add_child(badge)
		_badges[id] = badge
		var cross := _sprite(Art.icon("cross"), ICON_PX * 1.2, true, 4)
		cross.position = Vector3(s.pos.x, s.top + 0.55, front_z)
		cross.visible = false
		add_child(cross)
		_crosses[id] = cross


func _white() -> ImageTexture:
	var img := Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 0, Color.WHITE)
	return ImageTexture.create_from_image(img)


func _build_barista() -> void:
	_barista_node = Node3D.new()
	add_child(_barista_node)
	_contact_shadow(_barista_node)
	_barista_body = _character("barista_idle_0", BARISTA_H)
	_barista_body.scale.x = BARISTA_W
	_barista_shadow = _cast_shadow(_barista_node, _barista_body)
	_barista_node.add_child(_barista_body)


## v1-a frames: idle; walk = 4 keys per diagonal (se = toward camera, ne = away), left = flip_h.
## Character card: chunkier than the cut-out, feet sunk a touch into the floor.
func _character(name: String, h: float) -> Sprite3D:
	var body := _art(name, h)
	body.scale.x = CHAR_W
	body.set_meta(&"hs", 1.0)
	body.set_meta(&"native", true)
	body.offset.y -= FEET_SINK / body.pixel_size
	body.modulate = CHAR_TINT
	return body


## Contact shadow: soft dark ellipse right under the feet.
func _contact_shadow(parent: Node3D) -> void:
	var sh := Sprite3D.new()
	sh.texture = _soft_tex()
	sh.pixel_size = 0.95 / 128.0
	sh.scale = Vector3(CHAR_W, 0.55, 1.0)
	sh.rotation.x = -PI / 2
	sh.position = Vector3(0.0, 0.015, 0.05)
	sh.modulate = Color(0.16, 0.07, 0.06, 0.75)
	sh.shaded = false
	sh.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	sh.render_priority = -1
	parent.add_child(sh)


func _soft_tex() -> Texture2D:
	if not "soft" in _tex:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.45, Color(1, 1, 1, 0.75))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 128
		t.height = 128
		_tex["soft"] = t
	return _tex["soft"]


## Soft cast shadow: the character silhouette laid on the floor, pointing away
## from the warm key light (down-right on screen, like the plate's shadows).
func _cast_shadow(parent: Node3D, body: Sprite3D) -> Sprite3D:
	var sh := Sprite3D.new()
	sh.texture = body.texture
	sh.pixel_size = body.pixel_size
	sh.offset.y = body.offset.y + FEET_SINK / body.pixel_size
	sh.shaded = false
	sh.modulate = Color(0.14, 0.05, 0.1, 0.26)
	sh.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sh.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	sh.basis = Basis(Vector3.UP, deg_to_rad(40.0)) * Basis(Vector3.RIGHT, PI / 2.0) * Basis.from_scale(Vector3(CHAR_W, 0.6, 1.0))
	sh.position.y = 0.02
	sh.render_priority = -1
	parent.add_child(sh)
	parent.move_child(sh, 0)
	return sh


func _barista_tex(back: bool, walking: bool) -> Texture2D:
	if not walking:
		return _art_tex("barista_ne_2" if back else "barista_idle_0")
	return _art_tex("barista_%s_%d" % ["ne" if back else "se", int(_walk_phase) % 4])


func _build_till() -> void:
	_till_node = Node3D.new()
	_till_node.position = _cfg.kitchen.till_anchor
	add_child(_till_node)
	var bg := _sprite(_white(), 1.0, true, 1)
	bg.modulate = Art.INK
	bg.scale = Vector3(0.9, 0.12, 1)
	bg.position = Vector3(0, -0.12, 0.35)
	_till_node.add_child(bg)
	bg.visible = false  # till fill reads from the HUD; the pixel bar sat on queued guests
	_till_fill = _sprite(_white(), 1.0, true, 2)
	_till_fill.modulate = Color(1.0, 0.8, 0.25)
	_till_fill.position = Vector3(0, -0.12, 0.36)
	_till_node.add_child(_till_fill)
	_till_fill.visible = false
	_till_star = _sprite(Art.icon("star"), ICON_PX, true, 2)
	_till_star.modulate = Color(1.0, 0.85, 0.3)
	_till_star.position = Vector3(0.62, 0.55, 0.1)
	_till_node.add_child(_till_star)
	# Refusal at the till (no order matches the cup): the station cross, like a refused station.
	_till_cross = _sprite(Art.icon("cross"), ICON_PX * 1.2, true, 4)
	_till_cross.position = Vector3(0, 0.75, 0.1)
	_till_cross.visible = false
	_till_node.add_child(_till_cross)


# --- Per-frame updates ------------------------------------------------------

func _update_kettles(_dt: float) -> void:
	for id: StringName in _kettle_nodes:
		var n: Dictionary = _kettle_nodes[id]
		var k: Dictionary = _brewing.kettles[id]
		var steam: Sprite2D = _steam2d[id]
		var f := int((_local_t + n.phase) * VFX_FPS)
		match k.state:
			0:  # EMPTY: embers only
				steam.visible = false
				_gauges[id].root.visible = false
			1:  # BREWING: the same rolling puffs as READY (owner); the gauge tells brewing from ready
				var p: float = 1.0 - k.t / maxf(k.t_total, 0.001)
				_set_gauge(id, p)
				steam.visible = true
				steam.texture = _art_tex("steam_%d" % (f % 4))
				steam.scale = Vector2.ONE * 0.95
				steam.modulate.a = 0.85
				steam.position.y = KETTLE_PX[id].y - 190.0 - READY_STEAM_LIFT
			2:  # READY: big rolling puffs (READY = the steam, no extra overlay)
				_gauges[id].root.visible = false
				steam.visible = true
				steam.texture = _art_tex("steam_%d" % (f % 4))
				steam.scale = Vector2.ONE * 0.95
				steam.modulate.a = 0.85
				# UI s7: the kettle sign stands above the kettle; READY puffs roll out above its board.
				steam.position.y = KETTLE_PX[id].y - 190.0 - READY_STEAM_LIFT


func _update_slots() -> void:
	for id: StringName in _slot_nodes:
		var n: Dictionary = _slot_nodes[id]
		var cup: Variant = _brewing.slots[id]
		var key: Variant = null if cup == null else [cup.steps.duplicate(), cup.ruined]
		if key == n.shown:
			continue
		n.shown = key
		n.cup.visible = cup != null
		if cup != null:
			n.cup.texture = _slot_cup_tex(Kit.cup_state(cup.steps, cup.ruined))


func _update_barista(dt: float) -> void:
	_barista_node.position = _barista.position
	var walking: bool = _barista.state == 1
	if walking:
		_walk_phase += dt * WALK_FPS
	var f: Vector2 = _barista.facing
	var back := f.y < -0.2
	var pose := "back" if back else "normal"
	_barista_body.texture = _barista_tex(back, walking)
	_barista_body.flip_h = f.x < -0.05
	_barista_shadow.texture = _barista_body.texture
	_barista_shadow.flip_h = _barista_body.flip_h
	_barista_body.position.y = 0.0
	_update_held_cup(pose == "back")


func _update_guests(dt: float) -> void:
	var alive := {}
	for g: Variant in _guests.guests:
		if g != null:
			alive[g.uid] = g
	for g: Dictionary in _guests.departing:
		alive[g.uid] = g
	for uid: int in _guest_nodes.keys():
		if not uid in alive:
			# Gone from the sim: finish the walk down the stairs, then free.
			var n: Dictionary = _guest_nodes[uid]
			if _ended or n.root.position.distance_to(OFFSCREEN) < 0.05:
				n.root.queue_free()
				_guest_nodes.erase(uid)
			else:
				_sync_guest(n, n.last, dt)
	for uid: int in alive:
		var g: Dictionary = alive[uid]
		if not uid in _guest_nodes:
			_guest_nodes[uid] = _make_guest(g)
		_guest_nodes[uid].last = g
		_sync_guest(_guest_nodes[uid], g, dt)


func _make_guest(g: Dictionary) -> Dictionary:
	var root := Node3D.new()
	add_child(root)
	root.position = OFFSCREEN
	# mock6.base3: one soft ellipse under the feet (46 x 12 dp at the phone reference), no cast shadow.
	var shadow := Sprite3D.new()
	shadow.texture = _guest_shadow_tex()
	shadow.shaded = false
	shadow.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	shadow.rotation.x = -_pitch
	shadow.render_priority = -1
	shadow.modulate = Color8(25, 15, 10, 110)
	root.add_child(shadow)
	var body := _character("guest_%d_0" % (g.uid % 3), CHAR_H * 0.97)
	body.set_meta(&"manual", true)   # _sync_guest sets both scales (mockup size)
	root.add_child(body)
	# Same face twice in a row reads as a clone: every other repeat is mirrored.
	return {"root": root, "body": body, "shadow": shadow, "flip": (g.uid / 3) % 2 == 1,
		"sel": 0.0, "wobble": 0.0, "bob": float(g.uid) * 1.7}


## Screen-parallel soft ellipse (mock6: ellipse 46x12 dp, Gaussian blur 3 frame px).
func _guest_shadow_tex() -> Texture2D:
	if _shadow_tex == null:
		var w := 92 + 16
		var h := 24 + 16
		var im := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
		for y in h:
			for x in w:
				var nx := (x + 0.5 - w / 2.0) / 46.0
				var ny := (y + 0.5 - h / 2.0) / 12.0
				im.set_pixel(x, y, Color(1, 1, 1, 1.0 if nx * nx + ny * ny <= 1.0 else 0.0))
		for _pass in 3:   # three box passes ~ Gaussian sigma 3 px
			var src := im.duplicate() as Image
			for y in h:
				for x in w:
					var acc := 0.0
					for k in range(-2, 3):
						acc += src.get_pixel(clampi(x + k, 0, w - 1), y).a
					im.set_pixel(x, y, Color(1, 1, 1, acc / 5.0))
			src = im.duplicate() as Image
			for y in h:
				for x in w:
					var acc := 0.0
					for k in range(-2, 3):
						acc += src.get_pixel(x, clampi(y + k, 0, h - 1)).a
					im.set_pixel(x, y, Color(1, 1, 1, acc / 5.0))
		_shadow_tex = ImageTexture.create_from_image(im)
	return _shadow_tex


## Dev aid: floor point under a phone-reference (360x800) dp position.
func world_at_phone_dp(p: Vector2) -> Vector3:
	var scr := _plate_xform() * (ViewFit.plate_xform(PHONE_VP, 0.0).affine_inverse() * p)
	var w := _floor_at(scr)
	return w


## World feet point of queue spot i (mock6 COL in the phone frame, through the same plate pixel).
func _queue_spot(i: int) -> Vector3:
	if _queue_world.size() != QUEUE_PHONE_DP.size():
		_queue_world.clear()
		var ph := ViewFit.plate_xform(PHONE_VP, 0.0)
		var xf := _plate_xform()
		for p: Vector2 in QUEUE_PHONE_DP:
			_queue_world.append(_floor_at(xf * (ph.affine_inverse() * p)))
	return _queue_world[i]


func _ray(screen: Vector2) -> Array:
	return TapPicker.camera_ray(_camera, screen)


## Floor or stairs point under a screen position.
func _floor_at(screen: Vector2) -> Vector3:
	var r := _ray(screen)
	var o: Vector3 = r[0]
	var d: Vector3 = r[1]
	var hit: Variant = Plane(Vector3.UP, 0.0).intersects_ray(o, d)
	if hit != null and (hit as Vector3).z <= STAIRS_TOP.z:
		return hit
	var along := (STAIRS_BOTTOM - STAIRS_TOP).normalized()
	var n := along.cross(Vector3.RIGHT).normalized()
	if n.y < 0.0:
		n = -n
	hit = Plane(n, STAIRS_TOP).intersects_ray(o, d)
	return hit if hit != null else STAIRS_BOTTOM


## mock6: guest height in phone dp grows down the stairs (111 dp at y = 614), here mapped
## through the plate to the current screen.
func _guest_height_dp(feet: Vector3) -> float:
	var ph := ViewFit.plate_xform(PHONE_VP, 0.0)
	var xf := _plate_xform()
	var phone := ph * (xf.affine_inverse() * _camera.unproject_position(feet))
	return 111.0 * (1.0 + (phone.y - 614.0) / 600.0) * xf.get_scale().x / ph.get_scale().x


func _sync_guest(n: Dictionary, g: Dictionary, dt: float) -> void:
	var state: int = g.state
	var rank: int = _guests.queue().find(g)
	var target: Vector3 = _queue_spot(rank) if state <= 1 and rank >= 0 else OFFSCREEN
	var root: Node3D = n.root
	var moving := false
	if not _ended:
		var v: float = _cfg.guest.guest_walk_speed * dt * (1.3 if state == 2 else 1.0)
		moving = root.position.distance_to(target) > 0.01
		root.position = root.position.move_toward(target, v)
	var level := &"calm"
	if state <= 1:
		level = _guests.patience_level(g)
	var speed_scale := 1.0 if level == &"calm" else (1.6 if level == &"warn" else 2.4)
	n.bob += dt * (8.0 if moving else 2.0 * speed_scale)
	n.body.flip_h = g.get("flip", n.flip)
	n.body.modulate = Color(1, 0.8, 0.78) if level == &"urgent" else CHAR_TINT
	n.sel = maxf(n.sel - dt, 0.0)
	if n.sel > 0.0:
		var k: float = sin(PI * (1.0 - n.sel / SEL_S))
		n.body.modulate = n.body.modulate.lerp(Color(1.35, 1.3, 1.2), 0.6 * k)
	n.body.position.y = 0.0 if reduced_motion else absf(sin(n.bob)) * (0.05 if moving else 0.015 * speed_scale)
	# Size and shadow exactly as the mockup drew them, in screen dp.
	var feet := root.global_position
	var h_dp := _guest_height_dp(feet)
	var p0 := _camera.unproject_position(feet)
	var dx := p0.distance_to(_camera.unproject_position(feet + _camera.global_basis.x))
	var tex_h: float = n.body.texture.get_height() * n.body.pixel_size
	n.body.scale.x = h_dp / maxf(tex_h * dx, 0.001)
	# Height from the real projection of the sprite top (a tall upright is not linear in
	# perspective), so the guest is exactly h_dp tall like the mockup's fit(sprite, h).
	var dy := p0.distance_to(_camera.unproject_position(feet + Vector3.UP))
	var sy: float = n.body.scale.x * dx / maxf(dy, 0.001)
	var top := _camera.unproject_position(feet + Vector3(0, tex_h * sy, 0))
	n.body.scale.y = sy * h_dp / maxf(p0.distance_to(top), 0.001)
	var sw_dp := 46.0 * _plate_xform().get_scale().x / ViewFit.plate_xform(PHONE_VP, 0.0).get_scale().x
	n.shadow.pixel_size = sw_dp / 92.0 / maxf(dx, 0.001)
	n.shadow.position = Vector3(0, 0.02, 0.05)


func _update_till(dt: float) -> void:
	var ratio: float = _till.fill_ratio()
	_till_fill.scale = Vector3(maxf(0.9 * ratio, 0.001), 0.1, 1)
	_till_fill.position.x = -0.45 + 0.45 * ratio
	_till_star.visible = false  # till fullness reads from the HUD; the pixel star sat on guests' faces
	_till_thump = maxf(_till_thump - dt, 0.0)
	var k := _till_thump / maxf(_till_thump_len, 0.001)
	if reduced_motion:
		_till_node.scale = Vector3.ONE
		_till_fill.modulate = Color(1.0, 0.8, 0.25).lightened(0.4 * k)
	else:
		_till_node.scale = Vector3.ONE * (1.0 + 0.12 * sin(k * PI))


## Per-sprite upright stretch from the live camera (ADR-0002 amendment point 4).
func _update_uprights() -> void:
	var cam := _camera.global_position
	for i in range(_uprights.size() - 1, -1, -1):
		var sp := _uprights[i]
		if not is_instance_valid(sp):
			_uprights.remove_at(i)
			continue
		if sp.is_inside_tree():
			if sp.has_meta(&"manual"):
				pass
			elif sp.has_meta(&"native"):
				# Characters are painted for this view already: keep their on-screen
				# aspect exactly as drawn (1 m up projects as long as 1 m across).
				var p0 := _camera.unproject_position(sp.global_position)
				var dx := p0.distance_to(_camera.unproject_position(sp.global_position + _camera.global_basis.x))
				var dy := p0.distance_to(_camera.unproject_position(sp.global_position + Vector3.UP))
				sp.scale.y = sp.scale.x * dx / maxf(dy, 0.001)
			else:
				sp.scale.y = float(sp.get_meta(&"hs", sp.scale.x)) * ViewFitMath.upright_stretch(cam, sp.global_position)


func _update_effects(dt: float, fx_dt: float) -> void:
	for id: StringName in _flash.keys():
		_flash[id] -= dt
		var f: float = maxf(_flash[id], 0.0) / _cfg.hud.flash_s
		var b: Sprite3D = _badges[id]
		b.modulate = Color(1 + 0.8 * f, 1 + 0.8 * f, 1 + 0.8 * f)
		if id in _crosses:
			_crosses[id].visible = f > 0.0
		if _flash[id] <= 0.0:
			_flash.erase(id)
	for i in range(_pulses.size() - 1, -1, -1):
		var p: Dictionary = _pulses[i]
		p.t += fx_dt
		var node: Sprite3D = p.node
		var local: float = p.t - p.start
		node.visible = local >= 0.0
		if local >= p.dur:
			node.queue_free()
			_pulses.remove_at(i)
			continue
		var k := clampf(local / p.dur, 0.0, 1.0)
		node.modulate.a = 1.0 - k
		if not reduced_motion:
			node.scale = Vector3.ONE * (1.0 + 0.6 * k)
			node.position.y = p.y + 0.4 * k
	_till_cross_t = maxf(_till_cross_t - dt, 0.0)
	_till_cross.visible = _till_cross_t > 0.0 and not clean_ui
	_sel_t = maxf(_sel_t - fx_dt, 0.0)
	_sel_glow.modulate.a = 0.55 * sin(PI * (1.0 - _sel_t / SEL_S)) if _sel_t > 0.0 else 0.0
	if _floor_ring_t >= 0.0:
		_floor_ring_t += dt
		var m: float = _cfg.hud.marker_s
		var a := clampf(_floor_ring_t / m, 0.0, 1.0) if _floor_ring_t < m else clampf(2.0 - _floor_ring_t / m, 0.0, 1.0)
		_floor_ring.modulate.a = a
		if _floor_ring_t >= 2.0 * m or _barista.target.is_empty():
			_floor_ring.visible = false
			_floor_ring_t = -1.0
	var t: Dictionary = _barista.target
	if _outline.visible and not t.is_empty() and t.kind == &"guest":
		var g: Variant = _guests.guests[t.id]
		if g != null:
			_outline.position = Vector3(g.x, 1.2, _cfg.kitchen.guest_z)


# --- UI s7: station signs, kettle gauge, held cup ----------------------------

## Device px per viewport dp (the window is content-scaled from 360x640).
func _device_scale() -> float:
	return float(get_window().size.x) / get_viewport().get_visible_rect().size.x


## mock: dp(v) = round(v * sc) device px.
func _dpx(v: float) -> int:
	return Kit.pyround(v * _device_scale())


func _relayout_if_needed() -> void:
	var vp := get_viewport().get_visible_rect().size
	var key := Vector4(vp.x, vp.y, _device_scale(), ViewFit.shift_y(vp))
	if key == _layout_key:
		return
	_layout_key = key
	_queue_world.clear()
	_held_key = ""
	_ui_root.scale = Vector2.ONE / _device_scale()
	_build_sign_decal()
	for id: StringName in _gauges:
		_build_gauge(id)


## Item mask (painted station item) in the phone reference frame (720x1600 device px).
func _mask(t: StringName) -> Dictionary:
	if _masks.is_empty():
		var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Kit.DIR + "masks/masks.json"))
		for n: String in meta.offsets:
			var im: Image = (load(Kit.DIR + "masks/mask_%s.png" % n) as Texture2D).get_image()
			if im.is_compressed():
				im.decompress()
			im.convert(Image.FORMAT_RGBA8)
			var w := im.get_width()
			var h := im.get_height()
			for y in h:   # L -> alpha
				for x in w:
					var v := im.get_pixel(x, y).r
					im.set_pixel(x, y, Color(1, 1, 1, 1.0 if v > 0.5 else 0.0))
			_masks[StringName(n)] = {"img": im, "off": Vector2(meta.offsets[n][0], meta.offsets[n][1])}
	return _masks[t]


## Phone reference frame px -> current device px (same plate pixel).
func _phone_to_device() -> Transform2D:
	var ph := ViewFit.plate_xform(PHONE_VP, 0.0)
	var xf := _plate_xform()
	var sc := _device_scale()
	# device = sc * (xf * (ph^-1 * (p / 2)))
	return Transform2D(0.0, Vector2.ONE * sc, 0.0, Vector2.ZERO) * xf * ph.affine_inverse() * Transform2D(0.0, Vector2(0.5, 0.5), 0.0, Vector2.ZERO)


## Item bbox (device px, inclusive like numpy min/max): x0, y0 (top), x1, y1 (bottom).
func _item_box(t: StringName) -> Rect2:
	var m := _mask(t)
	var im: Image = m.img
	var used := im.get_used_rect()
	var tr := _phone_to_device()
	var a: Vector2 = tr * (m.off + Vector2(used.position))
	var b: Vector2 = tr * (m.off + Vector2(used.end) - Vector2.ONE)
	return Rect2(a, b - a)


## mock8.sign6: board rows 0..319 squashed to a square `w` px, legs stretched to `legs` px.
func _sign_img(t: StringName, w: int, legs: int) -> Image:
	var im := Kit.img("signA_" + String(t))
	var r := 319
	var board := Kit.resized(Kit.crop(im, 0, 0, im.get_width(), r), w, w)
	var leg := Kit.resized(Kit.crop(im, 0, r, im.get_width(), im.get_height()), w, maxi(2, legs))
	var out := Kit.blank(w, w + leg.get_height())
	Kit.paste(out, leg, 0, w)
	Kit.paste(out, board, 0, 0)
	return out


## mock10.base3: back-row signs above their item (item drawn over the legs), island signs low
## behind their item and over the back row. Two device-px decals: the plate one (behind the 3D
## world) and the kettle one (over the kettle steam).
func _build_sign_decal() -> void:
	var main := _compose_signs(SIGN_TYPES.filter(func(t: StringName) -> bool: return not String(t).begins_with("water_")))
	var kettles := _compose_signs([&"water_100", &"water_80"])
	var sc := _device_scale()
	for pair: Array in [[_sign_decal, main], [_kettle_decal, kettles]]:
		var sp: Sprite2D = pair[0]
		sp.texture = ImageTexture.create_from_image(pair[1][0])
		sp.position = Vector2(pair[1][1]) / sc
		sp.scale = Vector2.ONE / sc
	_occluder_mat.set_shader_parameter("decal", _sign_decal.texture)


## Signs of `types` composited like mock10.base3 (with the item restores); [Image, top-left device px].
func _compose_signs(types: Array) -> Array:
	var wpx := _dpx(36)
	var placed := []   # [type, image, x, y]
	for t: StringName in types:
		var bx := _item_box(t)
		var top := bx.position.y
		var bot := bx.end.y
		var cx := (bx.position.x + bx.end.x) / 2.0
		var sg: Image
		var y: int
		if t in ISLAND:
			sg = _sign_img(t, wpx, _dpx(3))
			y = int(top + (bot - top) * 0.35 - sg.get_height())
		else:
			var b := bot - _dpx(4)
			var legs := maxi(_dpx(3), int(b - (top - _dpx(3))))
			sg = _sign_img(t, wpx, legs)
			y = int(b - sg.get_height() + _dpx(1))
		placed.append([t, sg, int(cx - sg.get_width() / 2.0), y])
	var lo := Vector2i(1 << 30, 1 << 30)
	var hi := Vector2i(-(1 << 30), -(1 << 30))
	for p: Array in placed:
		lo = lo.min(Vector2i(p[2], p[3]))
		hi = hi.max(Vector2i(p[2], p[3]) + (p[1] as Image).get_size())
	var decal := Kit.blank(hi.x - lo.x, hi.y - lo.y)
	for island: bool in [false, true]:
		for p: Array in placed:
			if (p[0] in ISLAND) == island:
				Kit.paste(decal, p[1], p[2] - lo.x, p[3] - lo.y)
		# Restore the painted items over their signs (sign pixels under the item go transparent).
		for t: StringName in SIGN_TYPES:
			if (t in ISLAND) != island:
				continue
			var m := _mask(t)
			var tr := _phone_to_device()
			var k := tr.get_scale().x
			var mi: Image = (m.img as Image).duplicate()
			mi.resize(maxi(1, Kit.pyround(mi.get_width() * k)), maxi(1, Kit.pyround(mi.get_height() * k)), Image.INTERPOLATE_NEAREST)
			var at := Vector2i((tr * m.off).round()) - lo
			decal.blit_rect_mask(Kit.blank(mi.get_width(), mi.get_height()), mi, Rect2i(Vector2i.ZERO, mi.get_size()), at)
	return [decal, lo]


## mock10: brewing pill 26 dp wide at 42 % of the kettle height; fill = brew progress.
func _build_gauge(id: StringName) -> void:
	var g: Dictionary = _gauges[id]
	var src := Kit.img("gauge_empty")
	var s := float(_dpx(26)) / src.get_width()
	var empty := Kit.rescale(src, s)
	var full := Kit.rescale(Kit.img("gauge_full"), s)
	(g.empty as TextureRect).texture = Kit.tex(empty)
	(g.full as TextureRect).texture = Kit.tex(full)
	(g.empty as TextureRect).size = Vector2(empty.get_size())
	(g.full as TextureRect).size = Vector2(full.get_size())
	g.w = full.get_width()
	g.s = s
	var bx := _item_box(g.type)
	var cx := (bx.position.x + bx.end.x) / 2.0
	(g.root as Control).position = Vector2(int(cx - empty.get_width() / 2.0), int(bx.position.y + bx.size.y * 0.42))


func _set_gauge(id: StringName, p: float) -> void:
	var g: Dictionary = _gauges[id]
	g.root.visible = not clean_ui
	if g.w == 0:
		return
	var x := roundi((GAUGE_FILL.x + (GAUGE_FILL.y - GAUGE_FILL.x) * clampf(p, 0.0, 1.0)) * g.s)
	(g.full as TextureRect).size.x = x


## mock7: held cup 15 dp at the hand anchor (x - 0.35 w, y - 0.75 h); hidden when the barista
## faces away (the cup is in front of him).
func _update_held_cup(back: bool) -> void:
	var held: Variant = _brewing.held
	_held_rect.visible = held != null and not clean_ui   # mockup: shown in every pose
	if held == null:
		return
	var state := Kit.cup_state(held.steps, held.ruined)
	if state != _held_key:
		_held_key = state
		var im := Kit.cup_img(state, _dpx(15))
		_held_rect.texture = Kit.tex(im)
		_held_rect.size = Vector2(im.get_size())
	var b := _barista_node.global_position
	# Front view: the hand on the side he faces; back view mirrors it (the mockup's back-left pose
	# holds the cup on the screen right).
	var side := 1.0 if _barista_body.flip_h == back else -1.0
	var hand := Vector3(0.3 * side, 0.75, 0.12)
	var p := _camera.unproject_position(b + hand) * _device_scale()
	var sz := _held_rect.size
	_held_rect.flip_h = side < 0.0
	_held_rect.position = Vector2(int(p.x - sz.x * (0.35 if side > 0.0 else 0.65)), int(p.y - sz.y * 0.75))


func _slot_cup_tex(state: String) -> Texture2D:
	if not state in _slot_tex:
		var im := Kit.img("cup_" + state).duplicate() as Image
		im.generate_mipmaps()
		_slot_tex[state] = ImageTexture.create_from_image(im)
	return _slot_tex[state]


# --- Event handlers ---------------------------------------------------------

func _on_refused(id: StringName) -> void:
	_flash[id] = _cfg.hud.flash_s


func _on_guest_refused(slot: int) -> void:
	var g: Variant = _guests.guests[slot]
	if g != null and g.uid in _guest_nodes:
		_guest_nodes[g.uid].wobble = 0.3


func _on_till_refused() -> void:
	_till_cross_t = _cfg.hud.flash_s


func _on_held_changed() -> void:
	_last_match = _brewing.held_match()


## Leaving pulses are staggered by slot order, 100 ms apart (hud.md P16).
func _on_guest_left(slot: int, g: Dictionary) -> void:
	var node := _sprite(Art.icon("puff"), ICON_PX * 1.3, true, 5)
	var y := 1.7
	var at: Vector3 = _guest_nodes[g.uid].root.position if g.uid in _guest_nodes else Vector3(0, 0, _cfg.kitchen.guest_z)
	node.position = at + Vector3(0, y, 0)
	y = node.position.y
	node.visible = false
	add_child(node)
	var start := maxf(0.0, _pulse_last_start + _cfg.hud.leaving_pulse_stagger_s - _pulse_clock())
	_pulse_last_start = _pulse_clock() + start
	_pulses.append({"node": node, "t": 0.0, "start": start, "dur": _cfg.hud.leaving_pulse_s, "y": y})


func _pulse_clock() -> float:
	return _local_t


func _on_target_changed(t: Dictionary) -> void:
	_outline.visible = false
	if t.is_empty():
		return
	# Owner: no brackets or floor rings. A tapped guest briefly brightens; a tapped
	# station gets a short soft glow; a floor tap just walks.
	match t.kind:
		&"station":
			var s: Dictionary = _layout.stations[t.id]
			_sel_glow.position = Vector3(s.pos.x, s.top + 0.15, s.pos.y)
			_sel_t = SEL_S
		&"guest":
			var g: Variant = _guests.guests[t.id]
			if g != null and g.uid in _guest_nodes:
				_guest_nodes[g.uid].sel = SEL_S


func _on_coins_added(amount: int, _earned: int) -> void:
	if amount <= 0:
		return
	var full: bool = _till.is_full and _till.till_amount == _till.till_capacity
	_till_thump_len = 0.3 if full else 0.2
	_till_thump = _till_thump_len
