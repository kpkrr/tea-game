# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30
extends RefCounted
## Navigation on a private NavigationServer3D map baked at boot (ADR-0006).
## No physics nodes, no agents: plain path queries.

const CELL := 0.05

var _map: RID
var _region: RID
var _forced := false
var _ready := false
var _spawn: Vector3
var _tolerance: float


func _init(layout: RefCounted, control_cfg: Resource) -> void:
	_spawn = layout.cfg.barista_start
	_tolerance = control_cfg.path_end_tolerance
	var nm := NavigationMesh.new()
	nm.cell_size = CELL
	nm.cell_height = CELL
	nm.agent_radius = snappedf(control_cfg.agent_radius, CELL)
	nm.agent_height = 1.0
	nm.agent_max_climb = 0.0
	nm.agent_max_slope = 45.0
	nm.edge_max_error = 0.5
	nm.region_min_size = 0.0
	var src := NavigationMeshSourceGeometryData3D.new()
	var r: Rect2 = layout.cfg.nav_rect
	var a := Vector3(r.position.x, 0, r.position.y)
	var b := Vector3(r.end.x, 0, r.position.y)
	var c := Vector3(r.end.x, 0, r.end.y)
	var d := Vector3(r.position.x, 0, r.end.y)
	src.add_faces(PackedVector3Array([a, b, c, a, c, d]), Transform3D.IDENTITY)
	for f: Rect2 in layout.footprints():
		src.add_projected_obstruction(PackedVector3Array([
			Vector3(f.position.x, 0, f.position.y), Vector3(f.end.x, 0, f.position.y),
			Vector3(f.end.x, 0, f.end.y), Vector3(f.position.x, 0, f.end.y)]), -0.5, 2.0, false)
	NavigationServer3D.bake_from_source_geometry_data(nm, src)
	_map = NavigationServer3D.map_create()
	NavigationServer3D.map_set_cell_size(_map, CELL)
	NavigationServer3D.map_set_cell_height(_map, CELL)
	NavigationServer3D.map_set_use_async_iterations(_map, false)
	NavigationServer3D.map_set_active(_map, true)
	_region = NavigationServer3D.region_create()
	NavigationServer3D.region_set_map(_region, _map)
	NavigationServer3D.region_set_navigation_mesh(_region, nm)


## Call once per boot frame until true.
func poll_ready() -> bool:
	if _ready:
		return true
	if not _forced:
		_forced = true
		NavigationServer3D.map_force_update(_map)
	if NavigationServer3D.map_get_iteration_id(_map) > 0:
		var p := NavigationServer3D.map_get_closest_point(_map, _spawn)
		_ready = Vector2(p.x - _spawn.x, p.z - _spawn.z).length() < 0.01
	return _ready


## {points: PackedVector3Array (y=0), length, reached}
func path(from: Vector3, to: Vector3) -> Dictionary:
	var raw := NavigationServer3D.map_get_path(_map, from, to, true)
	var pts := PackedVector3Array()
	var length := 0.0
	var prev := Vector3(from.x, 0, from.z)
	for p: Vector3 in raw:
		var q := Vector3(p.x, 0, p.z)
		length += prev.distance_to(q)
		pts.append(q)
		prev = q
	var reached := not pts.is_empty() and Vector2(pts[-1].x - to.x, pts[-1].z - to.z).length() <= _tolerance
	return {"points": pts, "length": length, "reached": reached}


## Shortest path to any of the points; ties go to the lower index.
func shortest_to(from: Vector3, points: Array) -> Dictionary:
	var best := {}
	for p: Vector3 in points:
		var r := path(from, p)
		if best.is_empty() or r.length < best.length - 1e-4:
			best = r
	return best


## Boot self-check: every interaction point reachable from the barista start.
func verify(points: Array) -> String:
	for p: Vector3 in points:
		if not path(_spawn, p).reached:
			return "navigation: unreachable point %s" % p
	return ""


func dispose() -> void:
	NavigationServer3D.free_rid(_region)
	NavigationServer3D.free_rid(_map)
