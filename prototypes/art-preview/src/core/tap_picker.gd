# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30
extends RefCounted
## Resolves one press to a target (ADR-0006): outside kitchen -> nothing;
## nearest pick anchor within radius; else ray vs boxes; else floor plane.
## Target = {kind: &"station"|&"guest"|&"till"|&"floor", id, point}.
## Art-preview (UI s7): serving is a tap on the till; guests are not tap targets.

var radius: float
var _layout: RefCounted


func _init(layout: RefCounted, view_cfg: Resource, control_cfg: Resource) -> void:
	_layout = layout
	radius = roundf(control_cfg.pick_radius_factor * view_cfg.min_tap_target / 2.0)


func resolve(pos: Vector2, camera: Camera3D, kitchen_rect: Rect2, occupied: Array) -> Dictionary:
	if not kitchen_rect.has_point(pos):
		return {}
	# Fat finger: nearest anchor wins; stations before guests, then lower id.
	var best := {}
	var best_d := radius + 0.01
	for id: StringName in _layout.station_ids:
		var d := pos.distance_to(camera.unproject_position(_layout.stations[id].anchor))
		if d < best_d - 0.01:
			best_d = d
			best = {"kind": &"station", "id": id}
	var dt := pos.distance_to(camera.unproject_position(_layout.till_anchor))
	if dt < best_d - 0.01:
		best_d = dt
		best = {"kind": &"till", "id": 0}
	for i in occupied.size():
		if occupied[i]:
			var d := pos.distance_to(camera.unproject_position(_layout.guest_anchors[i]))
			if d < best_d - 0.01:
				best_d = d
				best = {"kind": &"guest", "id": i}
	if not best.is_empty():
		return best
	var ray := camera_ray(camera, pos)
	var origin: Vector3 = ray[0]
	var dir: Vector3 = ray[1]
	var near := INF
	for id: StringName in _layout.station_ids:
		var hit: Variant = _layout.stations[id].box.intersects_ray(origin, dir)
		if hit != null and (hit - origin).dot(dir) < near:
			near = (hit - origin).dot(dir)
			best = {"kind": &"station", "id": id}
	var till_hit: Variant = _layout.till_box.intersects_ray(origin, dir)
	if till_hit != null and (till_hit - origin).dot(dir) < near:
		near = (till_hit - origin).dot(dir)
		best = {"kind": &"till", "id": 0}
	for i in occupied.size():
		if occupied[i]:
			var hit: Variant = _layout.guest_boxes[i].intersects_ray(origin, dir)
			if hit != null and (hit - origin).dot(dir) < near:
				near = (hit - origin).dot(dir)
				best = {"kind": &"guest", "id": i}
	for box: AABB in _layout.blockers:
		var hit: Variant = box.intersects_ray(origin, dir)
		if hit != null and (hit - origin).dot(dir) < near:
			near = (hit - origin).dot(dir)
			best = {"kind": &"floor", "point": Vector3(hit.x, 0, hit.z)}
	if not best.is_empty():
		return best
	var ground: Variant = Plane(Vector3.UP, 0).intersects_ray(origin, dir)
	if ground != null and _layout.cfg.floor_rect.has_point(Vector2(ground.x, ground.z)):
		return {"kind": &"floor", "point": Vector3(ground.x, 0, ground.z)}
	return {}


## [origin, dir] of the camera ray through a viewport point, from the full projection
## (art-preview: the off-axis frustum offset; Camera3D.project_ray_normal ignores it).
static func camera_ray(camera: Camera3D, pos: Vector2) -> Array:
	var vp := camera.get_viewport().get_visible_rect().size
	var inv := camera.get_camera_projection().inverse()
	var ndc := Vector2(pos.x / vp.x * 2.0 - 1.0, 1.0 - pos.y / vp.y * 2.0)
	var n4 := inv * Vector4(ndc.x, ndc.y, -1.0, 1.0)
	var f4 := inv * Vector4(ndc.x, ndc.y, 1.0, 1.0)
	var xf := camera.global_transform
	var a := xf * (Vector3(n4.x, n4.y, n4.z) / n4.w)
	var b := xf * (Vector3(f4.x, f4.y, f4.z) / f4.w)
	return [a, (b - a).normalized()]
