# ADR-0006: Navigation & tap picking

## Status
Proposed

## Date
2026-09-30

## Last Verified
2026-09-30

## Decision Makers
Yan (product owner) · godot-specialist (engine validation 2026-09-30: no architectural blockers; one wrong factual claim about map sync corrected; six minor notes folded into Decisions 2/3/5 and Verification) · technical-director review skipped (review_mode `lean`) · decisions taken under `modes.automation: autonomous`, logged in `production/session-logs/decision-log.md`

## Summary
Player Control needs a tap → target → path → movement chain that keeps one agent radius, clamps taps to the walkable floor, and picks stations forgivingly on a tilted 2.5D camera, without the 3D physics world that Architecture Principle 6 rules out. This ADR decides: paths come from direct `NavigationServer3D` queries on a private map whose `NavigationMesh` is baked at boot from `KitchenConfig` footprints (no `NavigationAgent3D`, no avoidance); tap picking is pure math (`Camera3D.unproject_position` proximity, then ray-vs-AABB and ray-vs-floor-plane over static data); interaction points get stable string IDs.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7.2 (GDScript, single-thread web export) |
| **Domain** | Navigation + Input |
| **Knowledge Risk** | MEDIUM — `modules/navigation.md` (last verified for 4.6) documents only the `NavigationAgent` flow; the map-sync behaviour below is not in it and was found by probe on 4.7.2. The engine's documented readiness signals for a map are `map_changed` and `map_get_iteration_id`. Input: HIGH per `VERSION.md`, but only `InputEventScreenTouch`/`InputEventMouseButton` press events are used |
| **References Consulted** | `docs/engine-reference/godot/modules/navigation.md`, `modules/input.md`, `breaking-changes.md`, `deprecated-apis.md` (no navigation or picking entries 4.4–4.7); ADR-0002 (dp = viewport units, camera math); ADR-0003 (tick steps 2–3, `FakeNavigator` slot); headless 4.7.2 spike 2026-09-30 (scripts in session scratchpad; results below) |
| **Post-Cutoff APIs Used** | `NavigationServer3D.bake_from_source_geometry_data`, `NavigationMeshSourceGeometryData3D.add_projected_obstruction`, `NavigationServer3D.map_set_use_async_iterations` — verified on 4.7.2 only; treat their behaviour as pinned to this version. `InputEvent.DEVICE_ID_EMULATION` named constant (4.7 device-ID changes; `modules/input.md` is dated 4.6 — confirm the constant name in the first TapPicker story). `NavigationServer3D.map_force_update` is **deprecated since 4.5** but still works in 4.7.2 (class reference; `modules/navigation.md`); it is used only during Booting and only on the single-thread build — if it is removed or a threaded build is adopted, replace it with waiting on `map_changed`/`map_get_iteration_id` across frames |
| **Verification Required** | (1) ✅ **Verified on 4.7.2 headless** (kitchen geometry from the prototype: 15 stations + 12 wall blocks, floor 8×11 m, 19 interaction points = 15 work points + 4 guest slots, 342 ordered pairs): every work point lies on the baked mesh at `cell_size` 0.05/0.1/0.2 with `agent_radius` 0.40; at `cell_size` 0.125/0.25 the engine warns *"agent_radius is ceiled to cell_size voxel units"*, erodes 0.50 m and 15/11 of 19 points fall off the mesh (54/342 pairs unreachable). `map_get_path(optimize=true)` path length = **0.958×** the prototype's A*+smoothing on average (range 0.78–1.09); minimum clearance to any footprint = **0.380 m** at `cell_size` 0.05, `edge_max_error` 0.5 (0.354 at 0.1; 0.300 at 0.2); `add_projected_obstruction(carve=true)` gives clearance **0.000** (path touches footprints). Production settings (below) bake with zero warnings. Baked surface sits `2 × cell_height` (0.10 m) above the floor. Tap inside a footprint → path ends at the nearest mesh point; target far outside → clamps to the mesh edge; start off the mesh → projected onto it, no error. Bake 4.7 ms, path query 12–17 µs (macOS, headless). Map sync: in a normal main-scene run an active hand-made map syncs from the main loop by frame 1 (`map_changed` fires, `map_get_iteration_id` 0 → 1); in `--script`/headless-test contexts it never syncs without `map_force_update` (40–120 frames observed); with `use_async_iterations = false` one forced call per frame suffices, a redundant forced sync on top of the loop's only bumps the iteration id. Queries before the first sync print an engine ERROR and return empty. Recast and the bake API are compiled into the official `web_nothreads_release` template (strings confirmed in `godot.wasm`). `AABB.intersects_ray` returns `Vector3` or `null`; `Plane.intersects_ray` likewise. (2) **Web/Android spike (ADR-0001 device):** runtime bake time, zero bake warnings in the web build, and frames-to-ready on the reference weak Android (contingency threshold: bake > 100 ms → ship the pre-baked resource, see Risks). (3) On-device: one physical tap yields exactly one resolved target (touch + emulated mouse collapse); two fingers in one frame → last press wins. (4) Screenshot evidence (Kitchen AC7): barista capsule (r 0.30 m) never overlaps a counter along paths that hug the eroded boundary. (5) Re-measure `d_avg_hop` with real path lengths (Player Control OQ) |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0002 (dp = viewport units; camera; `kitchen_rect`; `tap_pick_radius` needs no scale), ADR-0003 (`TapPicker.flush` = tick step 2, `BaristaController.step` = step 3, composition root, sim modules are `RefCounted`), ADR-0004 (`KitchenConfig`/`ControlConfig`, `ConfigValidator`, `fail_boot`). All Proposed; this ADR cannot be Accepted before them |
| **Enables** | ADR-0007 (nav bake + sync counted in TTI; path-query cost per tap); BaristaController, TapPicker, Pathing, KitchenLayout stories; Guest walker stories |
| **Blocks** | Player Control and KitchenLayout implementation stories; Guest AI path-to-slot stories |
| **Ordering Note** | Adds `Pathing` readiness to the `ready_reached` prerequisites of ADR-0001/0003; adds navigation/pick fields to `KitchenConfig` and a `ControlConfig.agent_radius` divisibility rule to ADR-0004's validator |

## Context

### Problem Statement
Four open questions sit on this decision: (a) does a baked NavMesh reproduce the prototype's "middle of the aisle + straight-line shortcuts" without custom smoothing (AQ-02); (b) where does `agent_radius` live so the bake and the mover cannot disagree (Player Control OQ: two places); (c) how does a tap become one deterministic target when the project has no physics world (Rule 1b names a raycast, Principle 6 removes the physics world); (d) what are the stable IDs the tie-break rule needs. Every Core-layer story (TapPicker, Pathing, BaristaController) and the guest walkers start from this.

### Constraints
- ADR-0003: simulation modules are `RefCounted` with `step(dt)`, no `_process`/`_physics_process`, no `CONNECT_DEFERRED`, one composition root; dt up to 0.25 s (movement must cross several path points per step).
- ADR-0002: input positions, `unproject_position` and `tap_pick_radius` (28 dp) share one unit; no scale factors.
- Architecture Principle 6: no reliance on 3D physics; Principle 4: tuning values are data.
- GDD contracts: single `agent_radius` = `work_gap` − `clearance_margin` = 0.40 m; work points sit 0.45 m from a station face; new tap replaces the target with no queue and **no recompute mid-path** (Rule 5); tap on counter/till/wall is a floor tap clamped to the nearest reachable point; tap outside the kitchen does nothing; ties → station before guest, then smaller stable ID; touch = press only, last press per frame wins.
- Web is single-thread (ADR-0001); every new engine dependency must survive on a weak Android device.

### Requirements
- One `agent_radius`, defined in config, and no second place to set it.
- Paths hold `body_clearance` from footprints and are shortest among such paths (Rule 7), with no game-side smoothing code.
- Picking and pathing are unit-testable without a `SceneTree` or a physics/navigation server (`FakeNavigator`, fake projector).
- A broken kitchen (unreachable point) must fail loudly at boot, not mid-match.
- ≤ 1 path query per accepted tap (2–3 for stations with several approach points); per-tap cost well under 1 ms on the target device.

## Decision

**1. Pathing = direct `NavigationServer3D` queries, no agent nodes.** `Pathing` (Core, `RefCounted`, built in `_compose()`) owns a private navigation map and one region and answers `Navigator.path(from, to) -> PathResult` with `NavigationServer3D.map_get_path(map, from, to, true)` (`optimize = true` = funnel/string-pulling). The project contains **no** `NavigationAgent3D`, `NavigationRegion3D`, `NavigationObstacle3D` or navigation links. Movement along the returned polyline is our code (`PathFollower`, pure, called from `BaristaController.step` and the guest walkers): advance `effective_speed × sim_dt` along XZ segments, several per step, never overshooting the end (TR-control-017); the path is computed once when a target is accepted and never recomputed while walking (Rule 5). A tap on the current target recomputes from the current position (GDD Edge Case) — that is a new acceptance, not a repath.

**2. NavMesh is baked at boot from data, not authored in the editor.** `NavMeshBaker` (pure, `RefCounted`) builds a `NavigationMeshSourceGeometryData3D` from `KitchenConfig`: the floor rectangle as two triangles at y = 0, plus one `add_projected_obstruction` per footprint (station bodies, counters, wall blocks; **`carve = false`**). Bake settings are constants of the baker except the radius: `agent_radius` = `ControlConfig.agent_radius` (computed from `work_gap − clearance_margin`, ADR-0004), `cell_size = cell_height = 0.05`, `agent_height = 1.0`, `agent_max_climb = 0.0`, `agent_max_slope = 45°`, `edge_max_error = 0.5`, `region_min_size = 0`. `ConfigValidator` gains the rule *`abs(agent_radius / 0.05 − round(agent_radius / 0.05)) < 1e-6` and `agent_radius < work_gap`* — otherwise the engine silently ceils the radius to whole cells (measured; a ratio of 8.0001 already erodes 9 cells). `NavMeshBaker` additionally passes `snappedf(agent_radius, 0.05)` to the `NavigationMesh`, so float noise from `work_gap − clearance_margin` can never trigger the ceil. This closes the "two places" question: the radius exists once in config, is consumed once by the baker, and no agent object carries another. The footprints are the single source for both the bake and picking (decision 5); the scene's visual nodes are placed from the same data and a CI test compares them.

**3. Map lifecycle and boot readiness.** `Pathing` creates its own map (`map_create`; `cell_size = cell_height = 0.05`; `map_set_use_async_iterations(false)`; `map_set_active(true)`), a region carrying the baked mesh, and exposes `poll_ready() -> bool`. While `MatchDirector` is in `Booting`, each `_process` calls `poll_ready()`: it calls `map_force_update(map)` once and returns true when `map_get_iteration_id(map) > 0` **and** `map_get_closest_point(map, spawn_point)` is within 0.01 m (XZ) of the spawn point (observed: 1 frame). A non-zero closest point is not the criterion — it only looks non-zero because the baked surface sits 0.10 m up. `ready_reached` (ADR-0001) is emitted only after config validation **and** `Pathing` ready **and** the boot self-check (decision 8) pass. After ready the map is static: no further `map_force_update`. `Pathing.dispose()` frees the region and map RIDs (the engine reports leaked RIDs otherwise); tests must call it. In a normal run an active hand-made map syncs from the main loop within about one frame; in `--script`/headless-test contexts it never syncs without `map_force_update`. Boot forces the sync deliberately so behaviour is identical in both contexts; the redundant sync in a normal run is harmless.

**4. Path semantics (`Navigator` interface).**
```gdscript
class_name PathResult extends RefCounted
var points: PackedVector3Array   # start .. end, y forced to 0.0 (the baked surface is 0.10 m above the floor; gameplay never reads its y)
var length: float                # XZ metres
var reached: bool                # end within path_end_tolerance (0.05 m, XZ) of the requested target
```
- Target outside the walkable area or inside a footprint: the path ends at the nearest mesh point (`reached = false`). For a **floor** target this *is* Rule 2's clamp — the destination marker uses `points[-1]`; no separate clamp call. For a **station/guest** target `reached = false` means unreachable → the tap is rejected (Player Control Edge Case), with a debug error naming the target ID.
- Start off the mesh is projected onto it by the server; no special handling.
- Several approach points (Rule 5): `Pathing.shortest_to(from, points: Array[InteractionPoint]) -> PathResult` runs one query per point and keeps the shortest; equal length (within 1e-4 m) → smaller point ID.
- All engine calls stay inside `NavServerNavigator`; every other module sees only the `Navigator` interface. Tests use `FakeNavigator` (scripted results).

**5. Tap picking is physics-free.** `TapPicker` (Core) is a `RefCounted` and cannot receive input itself: a thin `TapInput` node in the kitchen scene (or `MatchDirector`) owns `_unhandled_input` and forwards accepted presses to `TapPicker.on_press(position)`. Accepted presses are `InputEventScreenTouch` with `pressed` and `InputEventMouseButton` (left) with `pressed` **whose `device != InputEvent.DEVICE_ID_EMULATION`** (touch already emulates a mouse press by default, delivered before the touch in the same frame; filtering makes one tap = one event explicit, and last-press-wins would still resolve to the touch); releases and drags are ignored; device IDs are compared only through named constants; `event.position` is used directly as dp (ADR-0002). Events consumed by HUD `Control`s never reach it — which holds only because every non-interactive HUD `Control` uses `MOUSE_FILTER_IGNORE` (ADR-0002 §6). It stores at most one pending press (last wins); `flush(running)` at tick step 2 resolves it (dropped when `running = false`):
   a. **Reject outside `ViewFit.get_kitchen_rect()`** (HUD strips, letterbox) → no target (Rule 1c).
   b. **Proximity (Rule 1a).** Candidates are the *pick anchors* of stations (static, from `KitchenLayout`) and of active guests (Approaching/Waiting only, from a read-only `GuestTargets` provider). Screen position = `TapProjector.to_screen(anchor)`; nearest candidate with distance ≤ `tap_pick_radius` wins. Ties (distance equal within 0.01 dp): station before guest, then smaller `owner_id` (String `<`), then smaller point index — independent of iteration order.
   c. **Geometry (Rule 1b).** No candidate in radius: cast `TapProjector.ray(press)` against the static AABBs of station bodies, counters, wall blocks, the till, and active guest hit-boxes; nearest hit decides — `AABB.intersects_ray` returns a point, so hits are compared by `(hit − origin).dot(dir)` with a normalized `dir` (`project_ray_normal` already is) — station → STATION, guest → GUEST, counter/wall/till → FLOOR at the hit's XZ. No AABB hit: intersect `Plane(Vector3.UP, 0)`; a point inside `KitchenConfig.floor_bounds` → FLOOR at that point; otherwise no target.
   d. Emits `tapped(target: TapTarget)` with `TapTarget { kind: FLOOR|STATION|GUEST, owner_id: StringName, point_index: int, point: Vector3 }` (`point` = world XZ, y = 0, pre-clamp, for FLOOR only). Validity (Rule 4) and pathing are `BaristaController`'s job.
   The prototype's `PhysicsDirectSpaceState3D.intersect_ray` is not used and the kitchen scene contains **no** `CollisionObject3D`, `CollisionShape3D`, `Area3D`, `RayCast3D`: ≤ 35 static boxes is a trivial loop, once per tap. `TapProjector` (`to_screen(world) -> Vector2`, `ray(screen) -> Ray`) wraps the kitchen `Camera3D`; a `FakeProjector` with a known orthographic transform makes picking a Logic test.

**6. Pick anchors, not work points.** Rule 1a's "active interaction point" is implemented as a per-target *pick anchor* — the station icon/top centre and the guest token position, as the prototype (feel already playtested) measured — not the floor work point 0.5 m in front of the station, which would put the pick target off the sprite the player is aiming at. Anchors live in `KitchenConfig` with each station/guest slot. (GDD wording sync — see Migration.)

**7. Stable IDs.** IDs are `StringName`, `[a-z0-9_]+`, unique, validated: stations use their data id (`cups`, `kettle100`, `slot_island_l1`), guest slots `guest_slot_0`…`guest_slot_3`. An *interaction point* is `(owner_id, index)` with `index ≥ 0` (approach points in data order). Comparison: `owner_id` by String `<`, then `index` numerically. Never derived from array position at runtime. Closes the Player Control OQ on ID format.

**8. Boot self-check (all builds).** After `Pathing` is ready, `Pathing.verify(kitchen)` queries a path from the spawn point to **every** interaction point (15 work points, 4 guest slots, exit, till anchor) and requires `reached` for each; any failure → `PlatformBridge.fail_boot("navigation: unreachable <owner_id>#<index>")` (ADR-0004 pattern: broken data must not ship silently). This is Kitchen AC 2/8/12/17 executed against the shipped data; ~25 queries × ≤ 20 µs.

**9. No avoidance in MVP.** Guests use the same `Navigator`, map and radius (spawn → own slot; Guest AI Rule 4/no-path fallback: spawn directly in the slot). No RVO, no local avoidance, one navigation layer. Barista and guests may overlap visually; revisit only if playtest shows it reads as a bug.

### Architecture Diagram

```
KitchenConfig (footprints, floor, anchors, points)   ControlConfig.agent_radius
        │                                                     │
        ├──► NavMeshBaker (pure) ── NavigationMesh ◄──────────┘   (boot, once)
        │                              │
        │                     Pathing ─┴─ private map + region  ── poll_ready()/verify()
        │                        │  Navigator.path(from,to) -> PathResult
        │                        ▼
 input ─► TapPicker ─tapped(TapTarget)─► BaristaController ─► PathFollower (XZ, multi-segment)
 (dp)      │  ▲                                  ▲
           │  └ GuestTargets (active guests)     └ Rule 4 validity: Brewing / GuestSim
           └ TapProjector (Camera3D) · static AABBs · Plane(UP,0)      [no physics objects]
```

### Key Interfaces

```gdscript
class_name Navigator extends RefCounted                       # NavServerNavigator | FakeNavigator
func path(from: Vector3, to: Vector3) -> PathResult

class_name Pathing extends RefCounted
func poll_ready() -> bool                                      # call each Booting frame; one map_force_update per call; ready = iteration_id > 0 and spawn probe on mesh
func verify(kitchen: KitchenLayout) -> Array[String]           # empty = ok; used by boot self-check and CI
func shortest_to(from: Vector3, points: Array[InteractionPoint]) -> PathResult
func dispose() -> void

class_name NavMeshBaker extends RefCounted                     # pure; no server calls except bake
static func bake(kitchen: KitchenConfig, agent_radius: float) -> NavigationMesh

class_name TapPicker extends RefCounted
signal tapped(target: TapTarget)
func on_press(position: Vector2) -> void                       # from the input node; keeps last press only
func flush(running: bool) -> void                              # tick step 2

class_name TapProjector extends RefCounted
func to_screen(world: Vector3) -> Vector2
func ray(screen: Vector2) -> Ray                               # origin + direction (ortho: parallel rays)

class_name GuestTargets extends RefCounted                     # implemented by GuestSim, read-only
func active_targets() -> Array[PickCandidate]                  # Approaching/Waiting guests: id, anchor, hit-box AABB
```

### Implementation Guidelines
- Must query paths only through `Navigator`; must never call `NavigationServer3D` outside `NavServerNavigator`, `NavMeshBaker` and `Pathing`.
- Must never add `NavigationAgent3D`, `NavigationRegion3D`, `NavigationObstacle3D` or navigation links; must never use the world's default navigation map.
- Must bake with `carve = false`, `cell_size` = 0.05 and an `agent_radius` that is an integer multiple of it; must treat any bake warning as a boot failure in CI.
- Must overwrite the y of every returned path point with 0.0; must never use the navmesh surface height for placement.
- Must call `poll_ready()` every `Booting` frame until true and must never query before it; must not call `map_force_update` after ready.
- Must call `Pathing.dispose()` in `MatchDirector` teardown and in every test that builds a `Pathing`.
- Must compute the path once per accepted target and never repath while walking; must advance along all segments a step's distance covers and never overshoot the last point.
- Input must enter only through the `TapInput` node's `_unhandled_input` → `TapPicker.on_press()`; `TapPicker` stays a node-free `RefCounted`.
- Must resolve taps only in `TapPicker.flush` from a single stored press; must never resolve in the input callback, never queue, never read `get_viewport().size`.
- Must never use `PhysicsServer3D`, `PhysicsDirectSpaceState3D`, `RayCast3D`, `Area3D` or any `CollisionObject3D` in the kitchen scene or for picking.
- Pick anchors, AABBs, footprints, floor bounds, interaction points and IDs must come from `KitchenConfig`; the scene's visual nodes must be placed from the same data.
- IDs must never be regenerated from array positions at runtime; tie-breaks must use the ordering in decision 7.

## Alternatives Considered

### Alternative 1: `NavigationAgent3D` nodes + editor-baked `NavigationRegion3D` (what the GDDs assume)
- **Description**: Kitchen scene holds a `NavigationRegion3D` baked in the editor; barista and guests each carry a `NavigationAgent3D` that follows the path from `_physics_process`.
- **Pros**: The documented default path; editor preview of the mesh.
- **Cons**: One node per walker driven by `_physics_process`, which ADR-0003 forbids; the agent re-plans on its own, contradicting Rule 5; the radius exists on the agent *and* in the baked mesh (the "two places" problem) and the baked asset can go stale silently; the default world map syncs asynchronously (not ready in 10–20 frames in the headless probe); tests need a `SceneTree`.
- **Rejection Reason**: Conflicts with the tick architecture and reintroduces the two-radius risk for no benefit — the agent's steering and avoidance are not used.

### Alternative 2: `AStarGrid2D` + own smoothing (the prototype)
- **Description**: 0.5 m grid, weighted cells next to obstacles, string-pull with segment-vs-box tests.
- **Pros**: Feel already playtested; deterministic across engine versions; pure GDScript (no server, no RIDs, no web unknowns); synchronous.
- **Cons**: ~120 lines of own geometry (weights, segment/box slab test, target snapping) that duplicate what the engine's funnel does; 0.5 m cells force the tap clamp to cell granularity; Kitchen AC1/2/7/12 and TR-layout-007 are written against a baked NavMesh. The spike shows the engine result is 4 % shorter on average and needs no post-processing, so the shortcut code buys nothing.
- **Rejection Reason**: Not rejected on merit alone — it is kept as the **contingency behind the same `Navigator` interface** (`GridNavigator`, a port of the prototype). If the web spike shows the runtime bake or map sync is unacceptable, only that class and the baker are swapped; TapPicker, BaristaController and guests are unaffected.

### Alternative 3: Editor-baked `NavigationMesh` resource loaded at boot
- **Description**: Same server-side pathing, but the mesh is baked in the editor/CI and shipped as a `.res`.
- **Pros**: No bake cost at boot.
- **Cons**: Stale-asset risk when `agent_radius` or footprints change; needs a load-time consistency check anyway.
- **Rejection Reason**: Bake takes ~5 ms on desktop. Kept as the **first contingency** if wasm bake exceeds 100 ms: the same `NavMeshBaker` writes the `.res` in CI and the loader validates `agent_radius`/`cell_size` against config.

### Alternative 4: Physics raycast for picking (prototype, GDD Rule 1b literally)
- **Description**: `StaticBody3D` + `CollisionShape3D` per station/counter, `intersect_ray` on tap.
- **Pros**: Familiar; hit info comes with the collider metadata.
- **Cons**: Requires a 3D physics world (Principle 6), collision shapes duplicating footprints, a SceneTree in tests; Jolt stays in the web build for one ray per tap.
- **Rejection Reason**: The same answer is a ray-vs-AABB loop over ≤ 35 static boxes, testable as pure math.

### Alternative 5: Local avoidance (RVO) for guests and barista
- **Description**: `NavigationAgent3D.avoidance_enabled`.
- **Pros**: No visual overlap.
- **Cons**: Needs agent nodes (Alternative 1's costs); guests walk fixed spawn→slot routes on a 2 m aisle; nothing in the GDDs asks for it.
- **Rejection Reason**: No requirement; revisit on playtest evidence.

## Consequences

### Positive
- AQ-02 answered with measurements: no custom smoothing, no cost-weighting, exact nearest-point clamp, ~4 % shorter paths than the prototype (so `t_step` = 2.0 s keeps a margin).
- One radius in one place, enforced by a validator rule; a mis-set radius fails boot instead of silently eroding 0.5 m.
- Picking and pathing are Logic-testable (`FakeProjector`, `FakeNavigator`); no physics objects, no SceneTree needed for picking.
- A broken kitchen can no longer reach the player: the boot self-check names the unreachable point.

### Negative
- Clearance is 0.38 m, not the GDD's exact 0.40 (Recast erodes in whole cells and simplifies contours). Rule 7a needs a stated tolerance (0.05 m); the barista capsule (0.30 m) still clears by 0.08 m.
- Paths hug the eroded boundary instead of centring in aisles (equivalent to Rule 7 in practice, but visibly different from the prototype's weighting — check in screenshots).
- We depend on navigation-server behaviour that differs from the documented `NavigationAgent` flow (explicit sync, RID lifecycle); it is pinned to 4.7.2 and must be re-probed on any engine upgrade.
- `KitchenConfig` grows (footprints, floor bounds, anchors, points, body heights) and `ConfigValidator` gains rules.
- Pick anchors replace the GDD's literal "work point" wording (Migration).

## Risks
- **Runtime bake or map sync is slower/different on wasm.** Unmeasured. Mitigation: Verification (2); contingency ladder 1) pre-baked `.res` from the same baker, 2) `GridNavigator` behind `Navigator`.
- **Clearance tolerance regression** after an engine or `NavigationMesh` default change. Mitigation: CI test asserts min clearance ≥ `agent_radius − 0.05` over all 342 point pairs and that all 19 points are on the mesh; bake with warnings = failure.
- **`agent_radius` raised toward `work_gap`.** At 0.45 (= `work_gap`) all points still reached in the probe, clearance 0.424; above `work_gap` points fall off. The validator's `agent_radius < work_gap` rule is the guard; the GDD fallback (0.35 m) stays available and needs no code change.
- **Duplicate touch + emulated-mouse events** for one tap. Same position in the same frame collapse to one under last-press-wins; Verification (3) confirms on device.
- **A tap on the top of a tall station resolves to a station, not the floor behind it** — intended (same as the physics ray in the prototype), covered by a Logic test with the tilted camera.
- **RID leaks in tests** if `dispose()` is skipped — the engine prints errors at exit; CI treats them as failures.
- **Guests and barista overlap visually** (no avoidance). Accepted for MVP.

## Spike Results (2026-09-30)

Source: `prototypes/web-spike/README.md` (session `0b7b7c05`, iPhone Safari, DPR 3).
- Verification (2) ✅ runtime bake in wasm: 18 ms, 70 polygons, map ready after 1 forced update, `verify` 15/15 points in 3 ms — far under the 100 ms contingency threshold; no pre-baked resource needed.
- Verification (3) ✅ each physical tap yielded one `InputEventScreenTouch` plus one emulated mouse press (`DEVICE_ID_EMULATION`, filtered) — one target per tap.
- Path query per tap ≤ 1 ms (timer resolution).

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| player-control-barista-movement.md | TR-control-001 (Rule 1): proximity within `tap_pick_radius`, else point/ray test, else no-op | Decision 5 a–c: kitchen-rect reject → anchor proximity → AABB/plane math |
| player-control-barista-movement.md | TR-control-002 (Rule 2): tap outside the nav area → nearest reachable XZ point | Server path ends at the nearest mesh point (measured); marker uses `points[-1]` |
| player-control-barista-movement.md | TR-control-005 (Rule 5): several approach points → shortest, tie → smaller ID; no recompute mid-way | `Pathing.shortest_to`, decision 7 ordering; path computed once |
| player-control-barista-movement.md | TR-control-007 (Rule 7): clearance = `body_clearance`, shortcuts on line of sight | Baked erosion + `optimize = true` funnel; measured clearance 0.380 m, length 0.958× prototype (tolerance stated) |
| player-control-barista-movement.md | TR-control-008: `agent_radius` = 0.40 m, one value | Single config value → baker; validator rule for cell divisibility and `< work_gap` |
| player-control-barista-movement.md | TR-control-011: `tap_pick_radius` 28 dp | Applied directly to `event.position` (ADR-0002), no conversion |
| player-control-barista-movement.md | TR-control-017: multi-point advance per step, no overshoot | `PathFollower` decision 1 |
| player-control-barista-movement.md | TR-control-018: press only, last press per frame wins | Decision 5: one stored press, `flush` resolves |
| kitchen-station-layout.md | TR-layout-007, -008, -012, -017: bake without warnings; no isolated pockets; clearance at points; guest points on the nav area | Zero-warning bake settings; boot self-check `verify()` queries every point; CI test |
| kitchen-station-layout.md | TR-layout-013: shapes don't intersect | Footprints are data; validator checks pairwise non-overlap (no collision shapes exist) |
| guest-ai-patience.md | TR-guest-006: path to slot at 3.0 m/s; no path → spawn in slot + log | Same `Navigator`; `reached = false` → fallback |
| hud-feedback-ui.md | TR-hud-006, -007: target outline / destination ring from state and target | `tapped` → `BaristaController.target`; marker at `points[-1]` |

## Performance Implications
- **CPU**: Path query 12–17 µs headless macOS, ≤ 3 per tap; picking ≈ 35 ray-box tests + ≤ 20 projections per tap. Even ×20 on a weak phone < 1 ms per tap. Boot: bake ~5 ms + self-check ~0.5 ms (desktop; wasm unmeasured).
- **Memory**: ~70 polygons; negligible.
- **Load Time**: adds the bake and 1–3 sync frames to boot (counted in ADR-0007 TTI).
- **Network**: None.

## Migration Plan
No production code exists; the prototype's grid, smoothing and physics ray are not migrated. GDD/doc syncs done with this ADR: `architecture.md` (Pathing row, AQ-02, KitchenLayout row, ready prerequisites), Player Control (Rule 1a pick anchor, Rule 1b no physics, Rule 7 clearance tolerance, Open Questions closed), Kitchen & Station Layout (collision shapes → footprints; AC1/AC7 wording), ADR-0001/0003 (`Pathing` readiness), `docs/engine-reference/godot/modules/navigation.md` (verified 4.7.2 behaviours).

## Validation Criteria
- gdUnit4 Logic: `TapMath`/`TapPicker` with `FakeProjector` — nearest anchor within 28 dp wins; equal distance → station before guest → smaller ID, independent of candidate order; two presses in a frame → last only; emulated mouse press (`DEVICE_ID_EMULATION`) ignored, real touch in the same frame resolves; `flush(false)` drops; outside `kitchen_rect` → none; counter/till/wall hit → FLOOR at hit XZ; plane point outside `floor_bounds` → none; tall-station-top ray → STATION. `PathFollower`: 0.25 s step crosses several points, never overshoots, zero-length path. `Pathing.shortest_to` tie → smaller ID (with `FakeNavigator`).
- gdUnit4 Integration (real server, `dispose()` in teardown): bake with the shipped `KitchenConfig` produces **zero** warnings/errors; `poll_ready()` true within 3 calls; `verify()` empty; all 19 points within 0.03 m of the mesh; min clearance over all pairs ≥ `agent_radius − 0.05`; path length ratio to a reference implementation stays within 0.75–1.15; target inside a footprint → `reached = false` and end within 0.05 m of the nearest mesh point; `agent_radius` 0.42 (not a multiple of 0.05) → validator error.
- ConfigValidator: pairwise non-overlapping footprints, unique IDs matching `[a-z0-9_]+`, every point inside `floor_bounds`.
- CI grep: no `NavigationAgent3D|NavigationRegion3D|NavigationObstacle3D|PhysicsServer3D|intersect_ray|RayCast3D|CollisionObject3D` in `src/` or kitchen scenes.
- On-device: Verification (2)–(4); Player Control AC 36 (≤ N+2 frames from press to Walking) with the real `TapPicker`.

## Related
- Depends on: ADR-0002 (dp units, camera, `kitchen_rect`), ADR-0003 (tick steps 2–3, composition, RefCounted modules), ADR-0004 (config, validator, `fail_boot`)
- Consistent with: ADR-0001 (`ready_reached` prerequisites extended)
- Enables: ADR-0007; BaristaController / TapPicker / Pathing / KitchenLayout / guest walker stories
- Design: `player-control-barista-movement.md` (Rules 1–7, Formula 2–3, Edge Cases, Open Questions), `kitchen-station-layout.md` (AC 1/2/7/12/17), `guest-ai-patience.md` (Rule 4, no-path Edge Case)
- Architecture: `architecture.md` AQ-02; Principle 6 (no physics)
- Prototype: `prototypes/kitchen-core/kitchen_core.gd` (`_smooth_path`, `_physics_process` pick) — reference only
