# Godot Navigation — Quick Reference

Last verified: 2026-02-12 | Engine: Godot 4.6 | Section "Verified on 4.7.2" added 2026-09-30

## Verified on 4.7.2 (headless probe, 2026-09-30 — used by ADR-0006)

Everything below was observed on `4.7.2.stable.official.ed1daf0bf` with a
hand-made map (`NavigationServer3D.map_create()` + `region_create()`), not
taken from documentation. Re-probe on any engine upgrade.

- **Map is not queryable right after setup.** A query before the first sync
  prints `ERROR: ... query failed because it was made before first map
  synchronization` and returns empty / `Vector3.ZERO`. In a **normal
  main-scene run** an active hand-made map syncs from the main loop by frame 1
  (`map_changed` fires, `map_get_iteration_id` 0 → 1). In a `--script`
  SceneTree run it is **never** synced (40–120 frames);
  `NavigationServer3D.map_force_update(map)` is required there. Readiness
  signals: `map_get_iteration_id(map) > 0` / `map_changed`
  (`region_get_iteration_id` is not useful). With
  `map_set_use_async_iterations(map, false)` one call is enough (1 frame); with
  async iterations it took 3 frames. Consecutive `map_force_update` calls in
  the same frame do not finish the sync (worker-thread hand-off) — poll once
  per frame and probe with `map_get_closest_point`.
- **Runtime bake is synchronous**: `NavigationServer3D.bake_from_source_geometry_data(nm, src)`
  (8×11 m floor + 27 obstructions: ~5 ms, 70 polygons, `cell_size` 0.05).
- **`agent_radius` is ceiled to whole cells** (`ceil(radius / cell_size)`);
  the engine warns *"agent_radius is ceiled to cell_size voxel units and loses
  precision"* when it is not a multiple. `agent_max_climb` is floored to
  `cell_height` units with a similar warning (set it to 0 on flat floors).
  Cell sizes 0.05/0.1/0.2 are exact for radius 0.40; 0.125/0.25 erode 0.50 m.
  Radius 0.20–0.60 in 0.05 steps erodes exactly k cells with no warning, but
  0.400005 already ceils to 9 cells — snap the radius (`snappedf`) before baking.
- Recast and the bake API are compiled into the official `web_nothreads_release`
  template (strings present in `godot.wasm`); the ceil warning is emitted in release.
- Touch input: `emulate_mouse_from_touch` is on by default; one touch yields an
  emulated `InputEventMouseButton` (`device == InputEvent.DEVICE_ID_EMULATION`)
  first, then the `InputEventScreenTouch`, same frame and position. A `Control`
  with `mouse_filter` STOP consumes both before `_unhandled_input`.
- **Erosion is coarse**: with radius 0.40, measured minimum path clearance to
  an obstruction was 0.380 m at `cell_size` 0.05 / `edge_max_error` 0.5, 0.354
  at 0.1, 0.300 at 0.2. Do not assume clearance ≥ `agent_radius`.
- **`add_projected_obstruction(..., carve = true)`** carves exactly and ignores
  the agent radius (path clearance 0.000). Use `carve = false`.
- **Baked surface height** is `2 × cell_height` above the source floor
  (0.10 m for 0.05). Never use returned path `y` for placement.
- **Path behaviour**: `map_get_path(map, from, to, true)` returns the funnel
  (string-pulled) path; target inside an obstruction or outside the mesh ends at
  the nearest mesh point; a start off the mesh is projected onto it silently.
  Query cost 8–17 µs (macOS, 19-point kitchen).
- **RID hygiene**: freeing a map/region is manual (`free_rid`); the engine
  reports leaked `NavMap3D`/`NavRegion3D` RIDs at exit otherwise.
- `AABB.intersects_ray(from, dir)` and `Plane.intersects_ray(from, dir)`
  return a `Vector3` on hit, `null` on miss.

## What Changed Since ~4.3 (LLM Cutoff)

### 4.5 Changes
- **Dedicated 2D navigation server**: No longer a proxy to 3D NavigationServer
  - Reduces export binary size for 2D-only games
  - API remains the same for both 2D and 3D

### 4.3 Changes (in training data)
- **`NavigationRegion2D`**: Removed `avoidance_layers` and `constrain_avoidance` properties

## Current API Patterns

### NavigationAgent3D (Preferred for Most Cases)
```gdscript
@onready var nav_agent: NavigationAgent3D = %NavigationAgent3D

func _ready() -> void:
    nav_agent.path_desired_distance = 0.5
    nav_agent.target_desired_distance = 1.0
    nav_agent.velocity_computed.connect(_on_velocity_computed)

func navigate_to(target: Vector3) -> void:
    nav_agent.target_position = target

func _physics_process(delta: float) -> void:
    if nav_agent.is_navigation_finished():
        return
    var next_pos: Vector3 = nav_agent.get_next_path_position()
    var direction: Vector3 = global_position.direction_to(next_pos)
    nav_agent.velocity = direction * move_speed

func _on_velocity_computed(safe_velocity: Vector3) -> void:
    velocity = safe_velocity
    move_and_slide()
```

### NavigationAgent2D
```gdscript
@onready var nav_agent: NavigationAgent2D = %NavigationAgent2D

func navigate_to(target: Vector2) -> void:
    nav_agent.target_position = target

func _physics_process(delta: float) -> void:
    if nav_agent.is_navigation_finished():
        return
    var next_pos: Vector2 = nav_agent.get_next_path_position()
    var direction: Vector2 = global_position.direction_to(next_pos)
    velocity = direction * move_speed
    move_and_slide()
```

### Low-Level Path Query (3D)
```gdscript
# Direct server query for custom pathfinding logic
var query := NavigationPathQueryParameters3D.new()
query.map = get_world_3d().navigation_map
query.start_position = global_position
query.target_position = target_pos
query.navigation_layers = navigation_layers

var result := NavigationPathQueryResult3D.new()
NavigationServer3D.query_path(query, result)
var path: PackedVector3Array = result.path
```

### Avoidance
```gdscript
# Enable RVO2-based local avoidance
nav_agent.avoidance_enabled = true
nav_agent.radius = 0.5
nav_agent.max_speed = move_speed
nav_agent.neighbor_distance = 10.0

# Use velocity_computed signal for avoidance-safe movement
nav_agent.velocity_computed.connect(_on_velocity_computed)

# Set velocity each frame (avoidance needs this)
nav_agent.velocity = desired_velocity
```

### Navigation Layers
```gdscript
# Use layers to separate walkable areas by agent type
# Layer 1: Ground units
# Layer 2: Flying units
# Layer 3: Swimming units
nav_agent.navigation_layers = 1  # Ground only
nav_agent.navigation_layers = 1 | 2  # Ground + Flying
```

## Common Mistakes
- Calling `get_next_path_position()` without checking `is_navigation_finished()`
- Not setting `velocity` on the agent when avoidance is enabled (required for RVO2)
- Using `NavigationRegion2D.avoidance_layers` (removed in 4.3)
- Forgetting to bake navigation mesh after modifying geometry
- Not setting `navigation_layers` (defaults to all layers)
