# VERTICAL SLICE - NOT FOR PRODUCTION (art-preview)
extends SceneTree
## Grey-box render of the kitchen from data/game_config.tres for a given camera.
## Used to pick the camera and as the layout base for the painted plate.
## godot --path . --script res://prototypes/art-preview/tools/blockout.gd -- --out=/tmp/b.png
##   [--yaw=0] [--pitch=52] [--fov=30] [--size=540x960] [--fill=0.96] [--people] [--crop]

const R := "res://prototypes/art-preview/"
const ViewFitMath := preload(R + "src/foundation/view_fit_math.gd")

const STONE := Color(0.42, 0.4, 0.38)
const FLOOR := Color(0.5, 0.46, 0.42)
const WOOD := Color(0.42, 0.24, 0.12)
const WOOD_D := Color(0.3, 0.17, 0.09)
const COPPER := Color(0.78, 0.45, 0.28)
const WATER := Color(0.12, 0.42, 0.48)

var args := {}
var cfg: Resource


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	cfg = load(R + "data/game_config.tres")
	var wh: PackedStringArray = String(args.get("size", "540x960")).split("x")
	var size := Vector2(float(wh[0]), float(wh[1]))
	DisplayServer.window_set_size(Vector2i(size))
	root.size = Vector2i(size)
	_build_world()
	var v: Resource = cfg.view
	var pitch := float(args.get("pitch", v.camera_pitch_deg))
	var yaw := float(args.get("yaw", v.camera_yaw_deg))
	var fov := float(args.get("fov", v.camera_fov_deg))
	var fill := float(args.get("fill", v.kitchen_fill_target))
	var basis := ViewFitMath.camera_basis(pitch, yaw)
	# Fit the kitchen into the 9:20 centre crop of the frame (the narrowest phone).
	var crop_w := minf(size.x, size.y * 0.45)
	var fit_rect := Rect2((size.x - crop_w) / 2.0, 0, crop_w, size.y)
	var c := ViewFitMath.solve_camera(size, fit_rect, v.frame_bounds, v.camera_look_at, basis, fov, fill)
	var cam := Camera3D.new()
	cam.fov = fov
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	cam.basis = basis
	cam.position = v.camera_look_at + basis.z * c.distance
	cam.h_offset = c.h_offset
	cam.v_offset = c.v_offset
	cam.far = 300
	root.add_child(cam)
	print("pitch=%s yaw=%s fov=%s D=%.2f h=%.3f v=%.3f pos=%s" % [pitch, yaw, fov, c.distance, c.h_offset, c.v_offset, cam.position])
	_shoot.call_deferred(String(args.get("out", "/tmp/blockout.png")), crop_w, size)


func _shoot(out: String, crop_w: float, size: Vector2) -> void:
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if args.has("crop"):
		var sx := img.get_width() / size.x
		var x0 := int((size.x - crop_w) / 2.0 * sx)
		for y in img.get_height():
			for d in 2:
				img.set_pixel(x0 + d, y, Color.RED)
				img.set_pixel(img.get_width() - 1 - x0 - d, y, Color.RED)
	img.save_png(out)
	quit()


func _mat(col: Color, rough := 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	return m


func _box(pos: Vector3, size: Vector3, col: Color) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.material_override = _mat(col)
	mi.position = pos + Vector3(0, size.y / 2.0, 0)
	root.add_child(mi)


func _cyl(pos: Vector3, r: float, h: float, col: Color, top_r := -1.0) -> void:
	var mi := MeshInstance3D.new()
	var m := CylinderMesh.new()
	m.bottom_radius = r
	m.top_radius = r if top_r < 0.0 else top_r
	m.height = h
	mi.mesh = m
	mi.material_override = _mat(col, 0.5)
	mi.position = pos + Vector3(0, h / 2.0, 0)
	root.add_child(mi)


func _ball(pos: Vector3, r: float, col: Color) -> void:
	var mi := MeshInstance3D.new()
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	mi.mesh = m
	mi.material_override = _mat(col, 0.4)
	mi.position = pos
	root.add_child(mi)


func _build_world() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = WATER
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.68, 0.62)
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.86, 0.68)
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 80
	sun.rotation = Vector3(deg_to_rad(-55), deg_to_rad(-40), 0)
	root.add_child(sun)

	var k: Resource = cfg.kitchen
	var fr: Rect2 = k.floor_rect
	# Stone base slab under the kitchen, water far below, cliffs behind.
	_box(Vector3(fr.get_center().x, -2.5, fr.get_center().y), Vector3(fr.size.x + 0.6, 2.5, fr.size.y + 0.6), STONE)
	_box(Vector3(0, -6, -2), Vector3(80, 0.1, 80), WATER)
	_box(Vector3(-9, -6, -14), Vector3(8, 9, 8), STONE.darkened(0.2))
	_box(Vector3(9, -6, -16), Vector3(9, 11, 9), STONE.darkened(0.25))
	_box(Vector3(fr.get_center().x, -0.05, fr.get_center().y), Vector3(fr.size.x, 0.05, fr.size.y), FLOOR)
	# Guest walkway continues off both sides of the slab.
	_box(Vector3(0, -0.05, k.guest_z + 0.15), Vector3(14, 0.05, 1.7), FLOOR.darkened(0.05))
	_box(Vector3(0, -2.5, k.guest_z + 0.15), Vector3(14, 2.45, 1.7), STONE)
	# Back wall low stone parapet.
	_box(Vector3(0, 0, fr.position.y + 0.15), Vector3(fr.size.x, 1.2, 0.3), STONE)
	var h: float = k.countertop_height
	for c: Dictionary in k.countertops:
		_box(Vector3(c.pos.x, 0, c.pos.y), Vector3(c.size.x, h, c.size.y), WOOD)
	var fc: Dictionary = k.front_counter
	_box(Vector3(fc.pos.x, 0, fc.pos.y), Vector3(fc.size.x, fc.height, fc.size.y), WOOD_D)
	_box(cfg.kitchen.till_anchor - Vector3(0, 0, 0), Vector3(0.6, 0.45, 0.45), Color(0.95, 0.75, 0.2))
	for s: Dictionary in k.stations:
		var p := Vector3(s.pos.x, 0, s.pos.y)
		var top: float = s.top
		match String(s.type):
			"water_100", "water_80":
				_box(p, Vector3(s.size.x, 0.8, s.size.y), STONE.lightened(0.1))
				_ball(p + Vector3(0, 1.1, 0), 0.32, COPPER)
				_ball(p + Vector3(0.0, 0.83, 0.55), 0.1, Color(1, 0.55, 0.1))
			"slot":
				_box(p, Vector3(s.size.x * 0.95, top, s.size.y * 0.95), WOOD.lightened(0.08))
				_cyl(p + Vector3(0, top, 0), 0.2, 0.02, Color(0.85, 0.75, 0.6))
			"trash":
				_box(p, Vector3(s.size.x, h, s.size.y), WOOD)
				_cyl(p + Vector3(0, h, 0), 0.3, 0.55, Color(0.45, 0.42, 0.4), 0.34)
			_:
				_box(p, Vector3(s.size.x, top, s.size.y), WOOD)
				var col: Color = {"cup": Color(0.97, 0.96, 0.92), "leaf_green": Color(0.45, 0.65, 0.3), "leaf_black": Color(0.3, 0.22, 0.18),
					"lemon": Color(1, 0.88, 0.25), "iced_tea": Color(0.75, 0.9, 0.95)}.get(String(s.type), Color.WHITE)
				if s.type == "lemon":
					_cyl(p + Vector3(0, top, 0), 0.3, 0.12, Color(0.9, 0.9, 0.88), 0.36)
					for i in 3:
						_ball(p + Vector3(-0.12 + 0.12 * i, top + 0.18, 0.05 * (i % 2)), 0.1, col)
				elif s.type == "cup":
					for i in 3:
						_cyl(p + Vector3(-0.2 + 0.2 * i, top, 0.05), 0.09, 0.3, col)
				else:
					_cyl(p + Vector3(0, top, 0), 0.2, 0.45, col)
	# Rope fence posts with lanterns along the front edge of the walkway.
	for x: float in [-4.5, -1.5, 1.5, 4.5]:
		_cyl(Vector3(x, 0, k.guest_z + 1.0), 0.08, 1.1, WOOD_D)
		_box(Vector3(x, 1.1, k.guest_z + 1.0), Vector3(0.22, 0.3, 0.22), Color(1, 0.8, 0.4))
	# Back corner posts with lanterns on the parapet.
	for x: float in [-4.0, 4.0]:
		_cyl(Vector3(x, 0, fr.position.y + 0.15), 0.1, 1.8, WOOD_D)
		_box(Vector3(x, 1.8, fr.position.y + 0.15), Vector3(0.28, 0.38, 0.28), Color(1, 0.8, 0.4))
	# Lower foreground terrace with crates, sacks, pots (scenery, outside frame_bounds).
	var tz: float = fr.end.y + 2.6
	_box(Vector3(0, -1.6, tz), Vector3(14, 0.1, 4.4), FLOOR.darkened(0.1))
	_box(Vector3(0, -4.5, tz), Vector3(14, 2.9, 4.4), STONE)
	for c: Array in [[-3.6, 5.6, 0.9], [-2.4, 6.4, 0.6], [2.9, 5.5, 0.9], [3.9, 6.6, 1.0], [-4.3, 7.0, 0.7]]:
		_box(Vector3(c[0], -1.55, c[1]), Vector3(c[2], c[2], c[2]), WOOD)
	for c: Array in [[-1.3, 5.8], [-0.4, 6.9], [1.6, 6.8]]:
		_cyl(Vector3(c[0], -1.55, c[1]), 0.35, 0.6, Color(0.7, 0.6, 0.45), 0.25)
	_ball(Vector3(1.0, -1.25, 5.6), 0.3, COPPER)
	if args.has("people"):
		var b: Vector3 = k.barista_start
		_cyl(b, 0.28, 1.6, Color(0.4, 0.3, 0.25))
		for x: float in k.guest_slot_x:
			_cyl(Vector3(x, 0, k.guest_z), 0.28, 1.6, Color(0.6, 0.4, 0.5))
