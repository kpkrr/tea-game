# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30
extends RefCounted
## Resolves one press to a target (ADR-0006): outside kitchen -> nothing;
## nearest pick anchor within radius; else ray vs boxes; else floor plane.
## Target = {kind: &"station"|&"guest"|&"floor", id, point}.

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
	for i in occupied.size():
		if occupied[i]:
			var d := pos.distance_to(camera.unproject_position(_layout.guest_anchors[i]))
			if d < best_d - 0.01:
				best_d = d
				best = {"kind": &"guest", "id": i}
	if not best.is_empty():
		return best
	var origin := camera.project_ray_origin(pos)
	var dir := camera.project_ray_normal(pos).normalized()
	var near := INF
	for id: StringName in _layout.station_ids:
		var hit: Variant = _layout.stations[id].box.intersects_ray(origin, dir)
		if hit != null and (hit - origin).dot(dir) < near:
			near = (hit - origin).dot(dir)
			best = {"kind": &"station", "id": id}
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
