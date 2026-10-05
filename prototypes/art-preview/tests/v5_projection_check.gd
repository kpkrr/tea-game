# VERTICAL SLICE - NOT FOR PRODUCTION (art-preview)
extends SceneTree
## ADR-0002 amendment V5: ViewFitMath.project must equal Camera3D.unproject_position
## (perspective + h_offset/v_offset) within 0.5 dp, on a real camera in a SubViewport.
## godot --headless --path . --script res://prototypes/art-preview/tests/v5_projection_check.gd

const R := "res://prototypes/art-preview/"
const ViewFitMath := preload(R + "src/foundation/view_fit_math.gd")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var v: Resource = load(R + "data/game_config.tres").view
	var basis := ViewFitMath.camera_basis(v.camera_pitch_deg, v.camera_yaw_deg)
	var worst := 0.0
	for size: Vector2 in [Vector2(360, 640), Vector2(360, 800), Vector2(640, 640)]:
		var vp := SubViewport.new()
		vp.size = Vector2i(size)
		root.add_child(vp)
		var cam := Camera3D.new()
		vp.add_child(cam)
		await process_frame
		var r := ViewFitMath.fit(size, Rect2(Vector2.ZERO, size), v.frame_bounds, v.camera_look_at, basis, v.camera_fov_deg,
			v.viewport_aspect_min, v.viewport_aspect_max, v.kitchen_fill_target, v.hud_min_strip_dp)
		var c: Dictionary = r.camera
		cam.projection = Camera3D.PROJECTION_PERSPECTIVE
		cam.keep_aspect = Camera3D.KEEP_HEIGHT
		cam.fov = v.camera_fov_deg
		cam.basis = basis
		cam.position = v.camera_look_at + basis.z * c.distance
		cam.h_offset = c.h_offset
		cam.v_offset = c.v_offset
		cam.near = c.near
		for i in 8:
			var p: Vector3 = v.frame_bounds.get_endpoint(i)
			var mine := ViewFitMath.project(p, c.distance, c.h_offset, c.v_offset, v.camera_look_at, basis, c.k, size)
			var real := cam.unproject_position(p)
			worst = maxf(worst, mine.distance_to(real))
		print("%s  D=%.2f m  h=%.3f v=%.3f  kitchen_rect=%s  reserved=%s" % [size, c.distance, c.h_offset, c.v_offset, r.kitchen_rect, r.reserved])
		vp.queue_free()
	print("V5 worst corner error: %.4f dp -> %s" % [worst, "PASS" if worst < 0.5 else "FAIL"])
	quit(0 if worst < 0.5 else 1)
