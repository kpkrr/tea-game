# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30
extends Node3D
## The 2.5D world: one static vertex-coloured mesh for floor and counters, pixel
## sprites for everything alive. Reads sim state every frame, owns no rules.
## Effects run on sim_dt (freeze with pause); after match end, pulses finish on ui_dt.

const Art := preload("pixel_art.gd")

const PERSON_PX := 0.075
const ICON_PX := 0.06
const TOKEN_PX := 0.04
const RING_PX := 0.045
const TOKEN_ROW_Y := [2.9, 3.65]   # alternate guests' tokens so neighbours never overlap
const RING_Y := 2.3
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
var _kettle_nodes := {}  # id -> {sprite, level, steam, glow}
var _slot_nodes := {}    # id -> {cup, row, shown}
var _barista_node: Node3D
var _barista_body: Sprite3D
var _barista_cup: Sprite3D
var _barista_row: Sprite3D
var _barista_check: Sprite3D
var _walk_phase := 0.0
var _guest_nodes := {}   # uid -> {root, body, ring, token, price, icon, shirt, hair, flash, wobble}
var _pulses: Array = []  # {node, t, start, dur}
var _pulse_last_start := -INF
var _local_t := 0.0
var _outline: Sprite3D
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
	guests.guest_left.connect(_on_guest_left)
	barista.target_changed.connect(_on_target_changed)
	till.coins_added.connect(_on_coins_added)


## Screen position (dp) of a world point, for HUD popups.
func screen_pos(p: Vector3) -> Vector2:
	return _camera.unproject_position(p)


func till_screen_pos() -> Vector2:
	return screen_pos(_cfg.kitchen.till_anchor + Vector3(0, 0.4, 0))


func guest_screen_pos(slot: int) -> Vector2:
	return screen_pos(Vector3(_cfg.kitchen.guest_slot_x[slot], 1.4, _cfg.kitchen.guest_z))


func on_match_started() -> void:
	_ended = false
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
	# Results cover the kitchen: tokens and rings go, frozen guests stay.
	for uid: int in _guest_nodes:
		var n: Dictionary = _guest_nodes[uid]
		n.ring.visible = false
		n.token.visible = false
		n.icon.visible = false
	_outline.visible = false
	_floor_ring.visible = false


func _process(_delta: float) -> void:
	if _clock == null:
		return
	var dt: float = _clock.sim_dt
	var fx_dt: float = _clock.ui_dt if _ended else dt
	_local_t += dt
	_update_kettles(dt)
	_update_slots()
	_update_barista(dt)
	_update_guests(dt)
	_update_till(dt)
	_update_effects(dt, fx_dt)


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


## Upright world sprite standing on its origin, stretched so it reads as drawn
## from the tilted camera.
func _upright(tex: Texture2D, px: float) -> Sprite3D:
	var s := _sprite(tex, px, false)
	s.offset.y = tex.get_height() / 2.0
	s.scale.y = 1.0 / cos(_pitch)
	return s


func _build_static() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var k: Resource = _cfg.kitchen
	var fr: Rect2 = k.floor_rect
	var hall_z: float = k.front_counter.pos.y
	for ix in int(ceil(fr.size.x)):
		for iz in int(ceil(fr.size.y)):
			var x0 := fr.position.x + ix
			var z0 := fr.position.y + iz
			var r := Rect2(x0, z0, minf(1.0, fr.end.x - x0), minf(1.0, fr.end.y - z0))
			var even := (ix + iz) % 2 == 0
			var hall := z0 >= hall_z
			var col := (HALL_A if even else HALL_B) if hall else (FLOOR_A if even else FLOOR_B)
			_top(st, r, 0.0, col)
	# Back wall with a trim, frames the kitchen.
	var wz := fr.position.y
	_quad(st, Vector3(fr.position.x, 0, wz), Vector3(fr.end.x, 0, wz), Vector3(fr.end.x, 1.7, wz), Vector3(fr.position.x, 1.7, wz), WALL)
	_quad(st, Vector3(fr.position.x, 1.7, wz), Vector3(fr.end.x, 1.7, wz), Vector3(fr.end.x, 1.85, wz), Vector3(fr.position.x, 1.85, wz), WALL_TRIM)
	var h: float = k.countertop_height
	for c: Dictionary in k.countertops:
		_block(st, Rect2(c.pos - c.size / 2.0, c.size), h, WOOD_TOP, WOOD_FRONT)
	var fc: Dictionary = k.front_counter
	_block(st, Rect2(fc.pos - fc.size / 2.0, fc.size), fc.height, WOOD_TOP.darkened(0.05), WOOD_FRONT.darkened(0.08))
	for id: StringName in _layout.station_ids:
		var s: Dictionary = _layout.stations[id]
		var size: Vector2 = s.size
		if s.type == &"slot":
			var pad := Rect2(s.pos - (size - Vector2(0.12, 0.12)) / 2.0, size - Vector2(0.12, 0.12))
			_block(st, pad, s.top, Color(0.97, 0.9, 0.78), WOOD_FRONT.lightened(0.1))
			continue
		var grow := -0.08 if String(s.side).begins_with("island") else 0.1
		var col: Color = Art.STEP_COLORS.get(s.type, Color(0.78, 0.79, 0.8))
		var top := col.lerp(Color(1, 1, 1), 0.55)
		var front := col.lerp(WOOD_FRONT, 0.35)
		_block(st, Rect2(s.pos - (size + Vector2(grow, grow)) / 2.0, size + Vector2(grow, grow)), s.top, top, front)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	add_child(mi)


func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color) -> void:
	for v: Vector3 in [a, b, c, a, c, d]:
		st.set_color(col)
		st.add_vertex(v)


func _top(st: SurfaceTool, r: Rect2, y: float, col: Color) -> void:
	_quad(st, Vector3(r.position.x, y, r.position.y), Vector3(r.end.x, y, r.position.y),
		Vector3(r.end.x, y, r.end.y), Vector3(r.position.x, y, r.end.y), col)


## Only top and front faces are visible from the fixed camera.
func _block(st: SurfaceTool, r: Rect2, h: float, top: Color, front: Color) -> void:
	_top(st, r, h, top)
	_quad(st, Vector3(r.position.x, 0, r.end.y), Vector3(r.end.x, 0, r.end.y),
		Vector3(r.end.x, h, r.end.y), Vector3(r.position.x, h, r.end.y), front)


func _build_stations() -> void:
	for id: StringName in _layout.station_ids:
		var s: Dictionary = _layout.stations[id]
		var front_z: float = s.pos.y + s.size.y / 2.0 - 0.25
		var base := Vector3(s.pos.x, s.top, front_z)
		if s.type == &"slot":
			var imprint := _sprite(Art.floor_ring(16), 0.04, false)
			imprint.rotation.x = -PI / 2
			imprint.modulate = Color(0.8, 0.7, 0.58, 0.8)
			imprint.position = Vector3(s.pos.x, s.top + 0.01, s.pos.y)
			add_child(imprint)
			var cup := _upright(Art.cup([&"cup"], false), ICON_PX)
			cup.position = Vector3(s.pos.x, s.top, s.pos.y + 0.1)
			cup.visible = false
			add_child(cup)
			var row := _sprite(Art.jewel_row([]), TOKEN_PX * 0.8, true, 2)
			row.position = Vector3(s.pos.x, s.top + 1.05, s.pos.y + 0.1)
			row.visible = false
			add_child(row)
			_slot_nodes[id] = {"cup": cup, "row": row, "shown": null}
			_badges[id] = cup
			continue
		var badge: Sprite3D
		if String(s.type).begins_with("water_"):
			badge = _upright(Art.kettle(Art.STEP_COLORS[s.type]), ICON_PX)
			badge.position = Vector3(s.pos.x, s.top, s.pos.y)
			var level := _sprite(_white(), 1.0, false)
			level.modulate = Color(0.95, 0.75, 0.35)
			level.visible = false
			add_child(level)
			var steam := _sprite(Art.icon("steam1"), ICON_PX, true, 1)
			steam.position = Vector3(s.pos.x + 0.05, s.top + 1.15, s.pos.y)
			steam.visible = false
			add_child(steam)
			var glow := _sprite(Art.blob(24, 24), 0.06, true, 0)
			glow.modulate = Color(1.0, 0.8, 0.35, 0.0)
			glow.position = Vector3(s.pos.x, s.top + 0.45, s.pos.y + 0.3)
			add_child(glow)
			var tag := _sprite(Art.jewel(s.type), ICON_PX * 0.8, true, 1)
			tag.position = Vector3(s.pos.x, s.top + 0.25, front_z + 0.3)
			add_child(tag)
			_kettle_nodes[id] = {"sprite": badge, "level": level, "steam": steam, "glow": glow, "base": Vector3(s.pos.x, s.top, s.pos.y)}
		elif s.type == &"trash":
			badge = _upright(Art.icon("trash"), ICON_PX * 1.25)
			badge.position = base
		else:
			badge = _upright(Art.jewel(s.type), ICON_PX * 1.25)
			badge.position = base
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
	var shadow := _sprite(Art.blob(16, 10), 0.06, false)
	shadow.rotation.x = -PI / 2
	shadow.position.y = 0.01
	shadow.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	_barista_node.add_child(shadow)
	_barista_body = _upright(_barista_tex("normal", 0), PERSON_PX)
	_barista_node.add_child(_barista_body)
	_barista_cup = _upright(Art.cup([&"cup"], false), ICON_PX * 0.9)
	_barista_cup.position = Vector3(0.28, 0.55, 0.12)
	_barista_node.add_child(_barista_cup)
	_barista_row = _sprite(Art.jewel_row([]), TOKEN_PX, true, 5)
	_barista_row.position = Vector3(0, 2.05, 0)
	_barista_node.add_child(_barista_row)
	_barista_check = _sprite(Art.icon("check"), TOKEN_PX * 1.2, true, 6)
	_barista_check.visible = false
	_barista_node.add_child(_barista_check)


func _barista_tex(pose: String, legs: int) -> Texture2D:
	return Art.person(pose, legs, Color(0.36, 0.64, 0.46), Color(0.45, 0.28, 0.16), Color(1, 1, 1))


func _build_till() -> void:
	_till_node = Node3D.new()
	_till_node.position = _cfg.kitchen.till_anchor
	add_child(_till_node)
	var box := _upright(Art.till(), ICON_PX)
	_till_node.add_child(box)
	var bg := _sprite(_white(), 1.0, true, 1)
	bg.modulate = Art.INK
	bg.scale = Vector3(0.9, 0.12, 1)
	bg.position = Vector3(0, -0.12, 0.35)
	_till_node.add_child(bg)
	_till_fill = _sprite(_white(), 1.0, true, 2)
	_till_fill.modulate = Color(1.0, 0.8, 0.25)
	_till_fill.position = Vector3(0, -0.12, 0.36)
	_till_node.add_child(_till_fill)
	_till_star = _sprite(Art.icon("star"), ICON_PX, true, 2)
	_till_star.modulate = Color(1.0, 0.85, 0.3)
	_till_star.position = Vector3(0.62, 0.55, 0.1)
	_till_node.add_child(_till_star)


# --- Per-frame updates ------------------------------------------------------

func _update_kettles(_dt: float) -> void:
	for id: StringName in _kettle_nodes:
		var n: Dictionary = _kettle_nodes[id]
		var k: Dictionary = _brewing.kettles[id]
		var sprite: Sprite3D = n.sprite
		var steam: Sprite3D = n.steam
		var level: Sprite3D = n.level
		var glow: Sprite3D = n.glow
		sprite.rotation.z = 0.0
		match k.state:
			0:  # EMPTY: muted, still
				sprite.modulate = Color(0.78, 0.76, 0.74)
				steam.visible = false
				level.visible = false
				glow.modulate.a = 0.0
			1:  # BREWING: liquid rises with the timer, steam grows by thirds
				var p: float = 1.0 - k.t / maxf(k.t_total, 0.001)
				sprite.modulate = Color(1, 1, 1)
				level.visible = true
				level.scale = Vector3(0.55, maxf(0.05, 0.55 * p), 1)
				level.position = n.base + Vector3(0, 0.12 + 0.55 * p / 2.0, 0.42)
				level.modulate = Color(0.95, 0.75, 0.35).lerp(Color(0.8, 0.45, 0.15), p)
				steam.visible = true
				steam.texture = Art.icon("steam1" if p < 0.34 else ("steam2" if p < 0.67 else "steam3"))
				steam.position.x = n.base.x + (0.0 if reduced_motion else sin(_local_t * 6.0) * 0.05)
				glow.modulate.a = 0.35 * p
			2:  # READY: warm glow, one thin curl, lid wobble
				sprite.modulate = Color(1.1, 1.05, 0.95)
				level.visible = true
				level.scale = Vector3(0.55, 0.55, 1)
				level.position = n.base + Vector3(0, 0.12 + 0.275, 0.42)
				level.modulate = Color(0.8, 0.45, 0.15)
				steam.visible = true
				steam.texture = Art.icon("steam1")
				glow.modulate.a = 0.55
				if not reduced_motion:
					sprite.rotation.z = sin(_local_t * 9.0) * 0.03


func _update_slots() -> void:
	for id: StringName in _slot_nodes:
		var n: Dictionary = _slot_nodes[id]
		var cup: Variant = _brewing.slots[id]
		var key: Variant = null if cup == null else [cup.steps.duplicate(), cup.ruined]
		if key == n.shown:
			continue
		n.shown = key
		n.cup.visible = cup != null
		n.row.visible = cup != null and cup.steps.size() > 1
		if cup != null:
			n.cup.texture = Art.cup(cup.steps, cup.ruined)
			n.row.texture = Art.jewel_row(cup.steps.slice(1), cup.ruined)


func _update_barista(dt: float) -> void:
	_barista_node.position = _barista.position
	var walking: bool = _barista.state == 1
	if walking:
		_walk_phase += dt * _barista.speed() * 2.2
	var legs := 0 if not walking else int(_walk_phase) % 2
	var f: Vector2 = _barista.facing
	var pose := "back" if f.y < -0.6 else "normal"
	_barista_body.texture = _barista_tex(pose, legs)
	_barista_body.flip_h = f.x < -0.3
	_barista_body.position.y = (0.04 * absf(sin(_walk_phase * PI))) if walking and not reduced_motion else 0.0
	var held: Variant = _brewing.held
	_barista_cup.visible = held != null
	_barista_row.visible = held != null and held.steps.size() > 1
	_barista_check.visible = false
	if held != null:
		_barista_cup.texture = Art.cup(held.steps, held.ruined)
		_barista_cup.position = Vector3(-0.28 if _barista_body.flip_h else 0.28, 0.55, 0.12 if pose != "back" else -0.12)
		_barista_row.texture = Art.jewel_row(held.steps.slice(1), held.ruined)
		if _brewing.held_match() != &"":
			_barista_check.visible = true
			_barista_check.position = Vector3(_barista_row.texture.get_width() * TOKEN_PX / 2.0 + 0.3, 2.05, 0)


func _update_guests(dt: float) -> void:
	var alive := {}
	for g: Variant in _guests.guests:
		if g != null:
			alive[g.uid] = g
	for g: Dictionary in _guests.departing:
		alive[g.uid] = g
	for uid: int in _guest_nodes.keys():
		if not uid in alive:
			_guest_nodes[uid].root.queue_free()
			_guest_nodes.erase(uid)
	for uid: int in alive:
		var g: Dictionary = alive[uid]
		if not uid in _guest_nodes:
			_guest_nodes[uid] = _make_guest(g)
		_sync_guest(_guest_nodes[uid], g, dt)


func _make_guest(g: Dictionary) -> Dictionary:
	var root := Node3D.new()
	add_child(root)
	var shadow := _sprite(Art.blob(16, 10), 0.06, false)
	shadow.rotation.x = -PI / 2
	shadow.position.y = 0.01
	shadow.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	root.add_child(shadow)
	var shirt: Color = SHIRTS[g.uid % SHIRTS.size()]
	var hair: Color = HAIRS[(g.uid * 7) % HAIRS.size()]
	var body := _upright(Art.person("normal", 0, shirt, hair, shirt.lightened(0.2)), PERSON_PX)
	root.add_child(body)
	var ring := _sprite(Art.ring(1.0), RING_PX, true, 2)
	ring.position = Vector3(0, RING_Y, 0)
	root.add_child(ring)
	var icon := _sprite(Art.icon("warn"), RING_PX, true, 3)
	icon.position = Vector3(0.5, RING_Y + 0.15, 0)
	icon.visible = false
	root.add_child(icon)
	var token_y: float = TOKEN_ROW_Y[g.slot % 2]
	var plate_tex := Art.order_plate(_book.token_steps(g.recipe))
	var token := _sprite(plate_tex, TOKEN_PX, true, 3)
	token.position = Vector3(0, token_y, 0)
	root.add_child(token)
	var price := Label3D.new()
	price.text = str(_book.recipe_price(g.recipe))
	price.font_size = 40
	price.pixel_size = 0.0065 * _cfg.hud.price_label_scale
	price.modulate = Art.INK
	price.outline_size = 0
	price.no_depth_test = true
	price.render_priority = 4
	price.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	# Digits sit in the plate's right end, after the coin icon.
	price.position = Vector3((plate_tex.get_width() / 2.0 - 7.0) * TOKEN_PX, 0.0, 0.01)
	token.add_child(price)
	price.rotation = Vector3.ZERO
	return {"root": root, "body": body, "ring": ring, "token": token, "icon": icon,
		"shirt": shirt, "hair": hair, "flash": 0.0, "wobble": 0.0, "bob": float(g.uid) * 1.7}


func _sync_guest(n: Dictionary, g: Dictionary, dt: float) -> void:
	n.root.position = Vector3(g.x, 0, _cfg.kitchen.guest_z)
	var state: int = g.state
	var moving := state != 1  # anything but WAITING walks
	if _ended:
		moving = false
	var pose := "normal"
	var level := &"calm"
	if state == 2:
		pose = "happy"
	elif state == 3:
		pose = "sad"
	else:
		level = _guests.patience_level(g)
		if level == &"urgent":
			pose = "angry"
	var speed_scale := 1.0 if level == &"calm" else (1.6 if level == &"warn" else 2.4)
	n.bob += dt * (8.0 if moving else 2.0 * speed_scale)
	var legs := int(n.bob) % 2 if moving else 0
	n.body.texture = Art.person(pose, legs, n.shirt, n.hair, n.shirt.lightened(0.2))
	n.body.flip_h = moving and (state == 2 or state == 3)
	n.body.position.y = 0.0 if reduced_motion else absf(sin(n.bob)) * (0.05 if moving else 0.015 * speed_scale)
	var active := state <= 1 and not _ended
	n.ring.visible = active
	n.token.visible = active
	n.icon.visible = active and level != &"calm"
	if not active:
		return
	var rf: float = _guests.remaining_fraction(g)
	n.ring.texture = Art.ring(rf)
	var approach: float = _cfg.hud.approaching_token_scale if state == 0 else 1.0
	n.token.scale = Vector3.ONE * approach
	n.token.modulate.a = approach
	# Pulse: ~0.5 Hz in warn, <= 2 Hz in urgent, sinusoidal; none with reduced motion.
	var pulse := 1.0
	if not reduced_motion and level != &"calm":
		var hz := 0.5 if level == &"warn" else 2.0
		pulse = 1.0 + 0.08 * sin(_local_t * TAU * hz)
	n.ring.scale = Vector3.ONE * pulse
	n.icon.texture = Art.icon("warn" if level == &"warn" else "urgent")
	n.icon.scale = Vector3.ONE * (1.0 if level == &"warn" else 1.35)
	# One-shot lightness flash when the held cup starts matching this order.
	n.flash = maxf(n.flash - dt, 0.0)
	var f: float = n.flash / _cfg.hud.flash_s
	n.token.modulate = Color(1 + 0.6 * f, 1 + 0.6 * f, 1 + 0.6 * f, approach)
	n.wobble = maxf(n.wobble - dt, 0.0)
	n.ring.position.x = sin(n.wobble * 60.0) * 0.08 * (n.wobble / 0.3) if not reduced_motion else 0.0


func _update_till(dt: float) -> void:
	var ratio: float = _till.fill_ratio()
	_till_fill.scale = Vector3(maxf(0.9 * ratio, 0.001), 0.1, 1)
	_till_fill.position.x = -0.45 + 0.45 * ratio
	_till_star.visible = _till.is_full
	_till_thump = maxf(_till_thump - dt, 0.0)
	var k := _till_thump / maxf(_till_thump_len, 0.001)
	if reduced_motion:
		_till_node.scale = Vector3.ONE
		_till_fill.modulate = Color(1.0, 0.8, 0.25).lightened(0.4 * k)
	else:
		_till_node.scale = Vector3.ONE * (1.0 + 0.12 * sin(k * PI))


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
			_outline.position = Vector3(g.x, 0.85, _cfg.kitchen.guest_z)


# --- Event handlers ---------------------------------------------------------

func _on_refused(id: StringName) -> void:
	_flash[id] = _cfg.hud.flash_s


func _on_guest_refused(slot: int) -> void:
	var g: Variant = _guests.guests[slot]
	if g != null and g.uid in _guest_nodes:
		_guest_nodes[g.uid].wobble = 0.3


func _on_held_changed() -> void:
	var m: StringName = _brewing.held_match()
	if m != &"" and m != _last_match:
		for g: Variant in _guests.guests:
			if g != null and g.recipe == m and g.uid in _guest_nodes:
				_guest_nodes[g.uid].flash = _cfg.hud.flash_s
	_last_match = m


## Leaving pulses are staggered by slot order, 100 ms apart (hud.md P16).
func _on_guest_left(slot: int, g: Dictionary) -> void:
	var node := _sprite(Art.icon("puff"), ICON_PX * 1.3, true, 5)
	var y := 1.7
	node.position = Vector3(g.x, y, _cfg.kitchen.guest_z)
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
	match t.kind:
		&"station":
			var s: Dictionary = _layout.stations[t.id]
			_outline.position = Vector3(s.pos.x, s.top + 0.45, s.pos.y + s.size.y / 2.0 - 0.25)
			_outline.scale = Vector3.ONE
			_outline.visible = true
		&"guest":
			_outline.position = Vector3(_cfg.kitchen.guest_slot_x[t.id], 0.85, _cfg.kitchen.guest_z)
			_outline.scale = Vector3.ONE * 1.6
			_outline.visible = true
		&"floor":
			_floor_ring.position = t.point + Vector3(0, 0.02, 0)
			_floor_ring.visible = true
			_floor_ring_t = 0.0
			_floor_ring.modulate.a = 0.0


func _on_coins_added(amount: int, _earned: int) -> void:
	if amount <= 0:
		return
	var full: bool = _till.is_full and _till.till_amount == _till.till_capacity
	_till_thump_len = 0.3 if full else 0.2
	_till_thump = _till_thump_len
