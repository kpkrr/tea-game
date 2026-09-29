# ADR-0003: Match simulation — game clock, tick order, pause & event wiring

## Status
Proposed

## Date
2026-09-30

## Last Verified
2026-09-30

## Decision Makers
Yan (product owner) · godot-specialist (engine validation 2026-09-30: no blocking issues; 7 minor notes folded into Guidelines and Risks) · technical-director review skipped (review_mode `lean`) · decisions taken under `modes.automation: autonomous`, logged in `production/session-logs/decision-log.md`

## Summary
Every timed match system (barista movement, kettles, guest patience and spawning, difficulty `t`, HUD pulses) must share one pausable, clamped game time and run in one fixed order, and the GDDs (Guest AI Rule 8/11/13) fix *what* that order and pause must be while deferring the *mechanism* here. This ADR drives the whole match from a single `MatchDirector._process` (variable `dt` clamped to `max_step_delta`, not `_physics_process`), makes `GameClock` a pure `RefCounted` with independent *hidden* and *frozen* flags as the only pause source (no `SceneTree.paused`), and wires modules with typed, synchronous signals connected only by the composition root — no global event bus.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7.2 (GDScript, Compatibility renderer / WebGL2, single-thread web export) |
| **Domain** | Core (scripting / main loop) |
| **Knowledge Risk** | LOW for the domain — `Node._process`, `process_priority`, typed signals on `RefCounted`, `Callable` are pre-cutoff and unchanged in 4.4–4.7 per `breaking-changes.md`. Engine version overall is HIGH (`VERSION.md`), so the web main-loop behaviour below is verified, not assumed |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `breaking-changes.md` (no Core/main-loop entries 4.4→4.7; 4.6 moved 3D physics interpolation into `SceneTree` — not used here), `deprecated-apis.md`, `current-best-practices.md`, `modules/web.md` (browser halts the main loop while the tab is hidden; `NOTIFICATION_APPLICATION_*` broken on web); `prototypes/kitchen-core/kitchen_core.gd` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | (1) On the ADR-0001 spike device: after hiding the tab for ≥ 10 s and returning, the first `MatchDirector._process` sees `GameClock.resume()` already applied and the sim advances by 0, not by the hidden span (log `real_delta` and returned `dt`). (2) With the `visibilitychange` callback deliberately disabled, the first frame after return advances at most `max_step_delta` (0.25 s). (3) `process_priority` ordering: `MatchDirector` (−100) runs before every presentation node's `_process` in the same frame (debug assert on a frame counter). (4) The `JavaScriptBridge` callback fires between main-loop iterations, never inside `MatchDirector._process` (debug assert on an `_in_tick` flag). |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (Web build & platform shell) — consumes `PlatformBridge.visibility_changed(visible: bool)` and `ready_reached()`. ADR-0001 is Proposed; this ADR cannot be Accepted before it |
| **Enables** | ADR-0006 (Navigation & tap picking — `TapPicker.flush()` and `BaristaController.step(dt)` slots in the tick are fixed here), ADR-0007 (Perf budgets — per-system cost is measured per `step()` call defined here) |
| **Blocks** | GameClock, MatchDirector, MatchLifecycle stories and every Feature-layer simulation story (Brewing, GuestSim, Currency, Till, BaristaController) and the HUD game-time animation stories |
| **Ordering Note** | `max_step_delta` and the other constants named here are delivered through ADR-0004's config mechanism; until it lands they sit in one typed `Resource` owned by MatchDirector, never as literals. RNG injection is ADR-0004's, not this ADR's |

## Context

### Problem Statement
Tea Rush has five systems with timers that must stop and resume together — barista walking, two kettles, guest patience and the spawn timer, difficulty-curve `t` and HUD pulses — plus strict intra-frame ordering rules from the GDDs: Player Control before Guest AI, serves before timeouts before end-check before spawn, match start before step (1) of its tick, `match_ended` exactly once. Guest AI Rule 11 explicitly leaves "shared game time or `SceneTree.paused`" to this ADR. `architecture.md` sketched `GameClock` + `MatchDirector` on `_physics_process`; that choice needs checking against web-export behaviour (browser-halted main loop, physics catch-up steps) before any gameplay code is written, because every Feature story depends on it.

### Constraints
- Single-thread web export (ADR-0001); the browser halts `_process` and `_physics_process` while the tab is hidden, and the frame after return carries the whole hidden span as `delta`.
- The only visibility source is `PlatformBridge.visibility_changed`, delivered from a `JavaScriptBridge` callback (ADR-0001).
- No 3D physics in the project (architecture principle 6); nothing needs a fixed physics step.
- All public logic must be unit-testable without a scene (coding standards, principle 3): clock, RNG, config and storage are injected.
- Resize must never touch match state (ADR-0001/0002).

### Requirements
- One game time; the only pause source; `SceneTree.paused` and raw `delta` banned in gameplay (TR-guest-015, TR-control-016, TR-brewing-009/010, TR-hud-008).
- Step clamp `max_step_delta` = 0.25 s (TR-guest-016, TR-brewing-010).
- Tick order: Player Control before Guest AI; inside Guest AI serves → timeouts → end-check → spawn (TR-guest-011/012).
- Match start in one tick before step (1); `match_started` exactly once; duplicate/early `request_new_match` ignored; `match_ended` exactly once with freeze (TR-guest-013/019, TR-currency-004/005/008, TR-brewing-011, TR-till-007, TR-pacing-010).
- Served chain resolved synchronously in the same tick; subscriber order irrelevant (TR-currency-001/002/012/013, TR-till-002/003).
- Last tap press per frame wins; no queue; input rejected after match end (TR-control-003/018/019).
- HUD reads state after the sim each frame and caches nothing (TR-hud-003/021).

## Decision

**1. One driver, on `_process`.** `MatchDirector` (a `Node` in the kitchen scene, `process_priority = -100`) is the only node whose `_process` advances the match. The sim uses **variable `dt` from `_process`**, clamped by `GameClock`, not `_physics_process`: the project has no physics; a fixed 60 Hz step renders unevenly on 90/120 Hz phones without interpolation, doubles sim cost on 30 fps devices and, after a stall, Godot's physics catch-up (`max_physics_steps_per_frame`) replays several steps in one frame — a burst the clamp was meant to prevent. Every other simulation module is a `RefCounted` with a `step(dt: float)` method and has no `_process`/`_physics_process` of its own. Presentation nodes keep default priority 0, so in every frame they run after the sim and read fresh state.

**2. `GameClock` — the only pause source.** A pure `RefCounted` with two independent flags:
- `hidden` — set/cleared by `pause()`/`resume()` (visibility policy from MatchLifecycle);
- `frozen` — set by `freeze()` at match end, cleared only by `reset()` at match start.

`advance(real_delta)` returns `sim_dt = 0` if either flag is set, else `min(real_delta, max_step_delta)`, and adds `sim_dt` to `t`. `resume()` also arms a **one-shot discard**: the first `advance()` after it returns 0, because that frame's `real_delta` is the hidden span. The clamp remains the fallback for the case where the hide event never arrived (Guest AI edge case). A second output, `ui_dt` = `0 if hidden else min(real_delta, max_step_delta)`, serves results-overlay timing (fade, 500 ms grace), which must keep running while the match is frozen but not while the page is hidden. `running_changed(running: bool)` is emitted when `hidden or frozen` flips, so sprite animation players can pause. `SceneTree.paused` is never set.

**3. Tick order.** Fixed in exactly one function:

```
MatchDirector._process(real_delta):
  _in_tick = true
  lifecycle.apply_pending()           # 0: queued start → reset clock, emit match_started (sync)
  var dt := clock.advance(real_delta) # 1: 0 when hidden / frozen / first frame after resume
  tap_picker.flush(dt > 0.0)          # 2: last press of the frame → tapped(target); dropped if not running
  if dt > 0.0:
    barista.step(dt)                  # 3: movement; in Holding → offer_action() to target owner (sync reply)
    brewing.step(dt)                  # 4: kettle timers
    guests.step(dt)                   # 5: (a) serves → (b) timeouts → (c) end check → (d) spawn
  save_store.flush_if_dirty()         # 6: added by ADR-0005 — one durable write per dirty frame
  _in_tick = false
# HUD / world overlays: _process at priority 0 — read-only, after the sim
```

Barista `offer_action()` to a guest is answered synchronously inside step 3 and recorded; GuestSim resolves it as sub-step (a) of step 5 in the same frame, before timeouts — this is how "serve beats timeout" also holds *between* systems (Guest AI Rule 8). Difficulty curves are stateless and called by GuestSim at spawn with `clock.t`.

**4. Match lifecycle.** `MatchLifecycle` (`RefCounted`, owned by the Guest AI feature — policy per Guest AI Rule 11/13) is a state machine `Booting → Running → Ended → Running`, orthogonal to the clock's `hidden` flag.
- `request_new_match()` — **a method, not a signal** (a command; the project signal convention is past tense). Accepted only in `Ended`, or once in `Booting` from `ready_reached`; otherwise ignored with one debug log. It only *queues* a start; duplicates while queued collapse to one.
- `apply_pending()` at tick step 0 executes the start: `clock.reset()` → state `Running` → emit `match_started()` exactly once. Receivers reset synchronously (Brewing, Currency, Till reset check, BaristaController → Idle, GuestSim clears all guests and arms "spawn now" so the first guest spawns in step 5d of the same tick).
- `on_guests_lost_reached()` (called by GuestSim in step 5c): `clock.freeze()` → state `Ended` → emit `match_ended()` exactly once; GuestSim skips 5d.
- `on_visibility_changed(visible)` → `clock.pause()`/`clock.resume()`. Visibility arrives between frames (JS callback), so its effect lands at the next `advance()`. Hidden during `Booting`: the first match still starts on `ready_reached` but with the clock paused.

**5. Event wiring.** Typed signals declared on the owning `RefCounted` (`served`, `target_vanished`, `match_started`, `match_ended`, `coins_earned`, `score_earned`, `coins_added`, `running_changed`). Signals carry facts downstream; requests upstream are method calls on an injected collaborator (`offer_action` → `ActionReply`, `consume_held_cup()`, `request_new_match()`). All connections are made in one place, `MatchDirector._compose()`, which also constructs every module and injects `GameClock`, config, RNG, `SaveStore` and `UtcClock` through constructors. Connections are synchronous (no `CONNECT_DEFERRED`), so the whole Served chain (`served → coins_earned/score_earned → coins_added`) completes inside the emitting step. `PlatformBridge` is the one autoload and only `_compose()` refers to it by name.

**6. Presentation and game time.** Anything that must stop on pause reads `GameClock` rather than frame delta: patience-ring pulse and pop-number arcs accumulate `clock.sim_dt`; `AnimatedSprite3D` guests/barista call `pause()`/`play()` on `running_changed`; overlay fade and "Play again" grace accumulate `clock.ui_dt`. `Tween`, `AnimationPlayer` autoplay and `Timer` nodes are not used for anything bound to game time.

### Architecture Diagram

```
 JS visibilitychange ─► PlatformBridge ─visibility_changed─┐      ready_reached
                                                          ▼            │
 HUD tap "Play again" ─request_new_match()──────► MatchLifecycle ◄─────┘
                                                   │  pause/resume/freeze/reset
                                                   ▼
 MatchDirector._process (priority −100) ────────► GameClock ── sim_dt / ui_dt / t / running_changed
   0 lifecycle.apply_pending ─match_started─► Brewing · Currency · Till · Barista · GuestSim · HUD
   1 clock.advance
   2 TapPicker.flush ─tapped─► BaristaController
   3 BaristaController.step ─offer_action()─► Brewing | GuestSim (sync ActionReply)
   4 Brewing.step
   5 GuestSim.step: a serves ─served─► Currency ─coins_earned─► Till ─coins_added─► HUD
                                             └─score_earned─► HUD
                    b timeouts  c end ─► MatchLifecycle.on_guests_lost_reached ─match_ended─► Currency · HUD
                    d spawn (DifficultyCurve(t))
 HUD._process (priority 0) — read-only, after the sim
```

### Key Interfaces

```gdscript
class_name GameClock extends RefCounted
signal running_changed(running: bool)
var t: float                  # read-only: match time, excludes pauses
var sim_dt: float             # read-only: dt returned by the last advance()
var ui_dt: float              # read-only: 0 while hidden, else clamped real delta
func _init(max_step_delta: float) -> void
func advance(real_delta: float) -> float
func pause() -> void          # hidden = true
func resume() -> void         # hidden = false; discards the next advance()
func freeze() -> void         # frozen = true (match end)
func reset() -> void          # t = 0, frozen = false; hidden unchanged
func is_running() -> bool     # not hidden and not frozen

class_name MatchLifecycle extends RefCounted
enum State { BOOTING, RUNNING, ENDED }
signal match_started()
signal match_ended()
var state: State              # read-only
func request_new_match() -> void          # HUD command; queued, deduped
func on_ready_reached() -> void           # first match
func on_visibility_changed(visible: bool) -> void
func on_guests_lost_reached() -> void     # from GuestSim step 5c
func apply_pending() -> void              # MatchDirector step 0 only

# Contract for every simulation module
func step(dt: float) -> void              # dt > 0, already clamped; never reads Engine/OS time
```

### Implementation Guidelines
- Simulation modules must be `RefCounted` with `step(dt)`; they must never implement `_process`/`_physics_process` or read `get_process_delta_time()`, `Time`, `OS` or `Engine` time.
- `MatchDirector._process` must be the only caller of `step()`, `clock.advance()` and `lifecycle.apply_pending()`; the order in Decision §3 must not be changed without superseding this ADR.
- Gameplay must never set or read `get_tree().paused`, and must never use `_physics_process`.
- Modules must never reference autoloads by name; only `MatchDirector._compose()` touches `PlatformBridge`.
- All cross-module signals must be connected in `_compose()`, must be typed, and must not use `CONNECT_DEFERRED`.
- A signal handler must never call `step()`, `advance()`, `apply_pending()` or `request_new_match()` re-entrantly; a request that changes the match (new match) is queued and applied at step 0.
- Game-time-bound presentation must derive from `clock.sim_dt`/`t`/`running_changed`; `Tween`/`Timer`/`AnimationPlayer` autoplay must not drive game-time effects.
- `PlatformBridge.visibility_changed` must be emitted synchronously from the JS callback and handled synchronously by `MatchLifecycle` (no `call_deferred`), so the page-hide save flush (ADR-0005) runs inside the browser event.
- `MatchDirector._process` gains step 6 after the tick: `save_store.flush_if_dirty()` (ADR-0005); it runs even when `dt == 0`.
- `TapPicker` must keep at most one pending press per frame (last wins) and drop it when `flush(false)`.
- Presentation nodes must stay at `process_priority` ≥ 0 and must not write to logic modules (HUD's only write is `request_new_match()`).
- No node may set `process_thread_group` (a separate process group breaks cross-tree `process_priority` ordering); ordering by `process_priority` covers `_process` only, not `SceneTree` tweens/timers.
- Signals between `RefCounted` modules must connect plain method `Callable`s only — no lambdas and no `.bind()` holding a `RefCounted` (both keep strong references and leak cycles); injected references must point one way (downstream → collaborator), and `MatchDirector` must call `dispose()` (disconnect all, drop references) in `_exit_tree`. gdUnit4 orphan checks stay on.
- "Read-only" fields in Key Interfaces (`t`, `sim_dt`, `ui_dt`, `state`) must be `_private` fields exposed by a getter (or a property whose setter rejects writes) — GDScript has no read-only vars.
- `GameTimeSprite` must read `clock.is_running()` in `_ready` as well as subscribing to `running_changed`, so a sprite created while the clock is stopped starts paused.

## Alternatives Considered

### Alternative 1: `SceneTree.paused` + `PROCESS_MODE_PAUSABLE`
- **Description**: Pause by setting `get_tree().paused`; systems keep their own `_process`; HUD overlay nodes `PROCESS_MODE_ALWAYS`.
- **Pros**: Built-in; Tweens and AnimationPlayers pause for free.
- **Cons**: Does not clamp the post-stall `delta`; does not give an intra-frame order (tree order and priorities scattered over nodes); the match-end *freeze* and the page *hide* are different states that one flag cannot express (overlay must animate while frozen); logic becomes node-bound and untestable without a scene.
- **Rejection Reason**: Violates TR-guest-011/012/016 and architecture principles 1–3.

### Alternative 2: Fixed step on `_physics_process` (as sketched in `architecture.md`)
- **Description**: `MatchDirector._physics_process` at 60 Hz with the same `GameClock`.
- **Pros**: Deterministic step size; familiar pattern.
- **Cons**: No physics to synchronise with; visible judder on 90/120 Hz displays without physics interpolation; on 30 fps web devices two sim steps run per frame; after a stall the engine replays up to `max_physics_steps_per_frame` steps in one frame, reproducing the burst the clamp exists to prevent; `max_step_delta` becomes meaningless because `delta` is always 1/60.
- **Rejection Reason**: Costs more and behaves worse on the target platform; the determinism benefit is already obtained in tests by calling `step(dt)` with fixed `dt`.

### Alternative 3: Global `EventBus` autoload
- **Description**: One autoload re-emitting all game events; systems connect by name.
- **Pros**: Easy to add listeners; no composition code.
- **Cons**: Hidden coupling and load-order dependence; tests must reset a global; subscriber order and re-entrancy become implicit; conflicts with DI requirement in coding standards.
- **Rejection Reason**: Coupling and testability; the module graph is small and static, so explicit wiring in one function is cheap.

### Alternative 4: Each system ticks itself with `process_priority`
- **Description**: No central director; order via per-node priorities.
- **Pros**: Less central code.
- **Cons**: Order is spread across files and scenes; match start "before step (1)" and "skip spawn after end" need cross-node flags; logic stays in nodes.
- **Rejection Reason**: Violates principle 1 (one owner of order).

## Consequences

### Positive
- Pause, clamp, freeze and resume live in ~60 lines of pure GDScript with full unit-test coverage.
- Tick order is readable in one function and testable with spy modules.
- Served chain is atomic within a frame, so HUD never sees half-applied coins/score.
- Frame-rate independent: 30, 60 and 120 Hz devices run one sim step per rendered frame.

### Negative
- Variable `dt` makes sim results depend slightly on frame timing in live play (tests stay deterministic via fixed `dt`); accepted — no replay or netcode in MVP.
- Presentation authors cannot use `Tween`/`Timer` for game-time effects and must hand-accumulate `sim_dt`.
- `_compose()` grows with every module; acceptable at ~12 modules.

## Risks
- **JS callback timing differs from assumption** (callback runs mid-frame on some browser) → the `_in_tick` debug assert catches it; fix is to queue visibility like new-match requests. Verification (4).
- **First frame after resume not discarded** (e.g. a browser that keeps rAF alive in a hidden iframe) → clamp still bounds the jump to 0.25 s. Verification (1)/(2).
- **Large variable `dt` (up to 0.25 s) tunnels movement** past path points → TR-control-017 already requires multi-point advance per step; BaristaController and guest walkers must loop over path segments.
- **Visibility order not guaranteed on return** (Safari may render a frame before `visibilitychange`) → that frame advances 0 because `hidden` is still set, then `resume()` discards the next normal frame: one frame lost, harmless and accepted.
- **Offscreen or covered iframe embeds** (itch.io, portals) can throttle rAF without any `visibilitychange`, so the match ticks in clamped 0.25 s steps unseen → out of MVP scope (plain browser, own page); revisit if embeds are planned.
- **`JavaScriptBridge.create_callback` object collected** → callback silently stops firing; ADR-0001 owns the fix (keep it in a member variable), noted there.
- **Re-entrancy via signal handlers** (e.g. HUD handler calling back into lifecycle) → guideline forbids it; `request_new_match()` is queued so even a mistaken synchronous call is safe.
- **`AnimatedSprite3D` keeps animating on freeze if a node forgets `running_changed`** → a single `GameTimeSprite` helper script owns the subscription.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| guest-ai-patience.md | Rule 11 / TR-guest-015, -016: single game time, only pause source, clamp 0.25 s | `GameClock` hidden flag + clamp + resume discard; `SceneTree.paused` banned |
| guest-ai-patience.md | Rule 8 / TR-guest-011, -012: serves → timeouts → end → spawn; Player Control before Guest AI | Tick steps 3 → 5a–5d in `MatchDirector._process` |
| guest-ai-patience.md | Rule 9, 13 / TR-guest-013, -019: `match_ended`/`match_started` exactly once; duplicates ignored; start before step (1) | `MatchLifecycle` state machine, queued `request_new_match()`, `apply_pending()` at step 0 |
| guest-ai-patience.md | TR-guest-001, -004, -005, -007, -008, -009, -010, -021 (state machine, patience from spawn, serve in same tick) | `GuestSim.step(dt)` sub-steps on clamped `sim_dt`; serve resolved in 5a same frame |
| player-control-barista-movement.md | TR-control-003, -004, -009, -010, -013, -016, -019: last tap replaces target; Holding offers once per tick; pause from game time only; input rejected at match end | `TapPicker.flush` step 2, `BaristaController.step` step 3, sync `ActionReply`; `flush(false)` when not running |
| brewing-crafting-mechanic.md | TR-brewing-001, -002, -004…-012: kettle timers on clamped game time, reset on `match_started`, `consume_held_cup` once | `Brewing.step(dt)` step 4; `match_started` handler; call only from GuestSim 5a |
| difficulty-curve-session-pacing.md | TR-pacing-003, -004, -006, -007, -010: pure functions of `t`, `t` excludes pauses, resets on start | `clock.t` passed at spawn; reset in `apply_pending()` |
| currency-coins-score.md | TR-currency-001, -002, -004, -005, -007…-013: Served-only trigger, same-tick, order-independent, reset/freeze on lifecycle | Synchronous typed signal chain wired in `_compose()` |
| till-day-cycle.md | TR-till-002, -003, -004, -007, -008, -010, -013: `coins_added` always, Open→Full same tick, reset check on `match_started` | Synchronous `coins_earned → coins_added`; `match_started` handler |
| hud-feedback-ui.md | TR-hud-003, -004, -008, -016, -021: read-only after sim, pauses via game time, state from lifecycle, target change visible same frame | HUD priority 0 after director; `sim_dt`/`ui_dt`/`running_changed`; no caching |

## Performance Implications
- **CPU**: Director overhead is a handful of calls per frame (< 0.05 ms); one sim step per rendered frame instead of up to 2+ physics steps on 30 fps devices. Per-system budgets (Guest AI ≤ 0.5 ms avg) are set by ADR-0007.
- **Memory**: Negligible — a dozen `RefCounted` objects per match, reused across matches.
- **Load Time**: None.
- **Network**: None.

## Migration Plan
No production code exists. The prototype (`prototypes/kitchen-core/`) uses its own `_process`/`_physics_process` and is not migrated; production modules are written against this ADR. `architecture.md` §Data Flow 1/3 and §API Boundaries are updated alongside this ADR (`_process` driver, `request_new_match()` as a method, `GameClock` flags).

## Validation Criteria
- gdUnit4: `GameClock` — clamp, `pause/resume` with discard, `freeze/reset` independence, `running_changed` emissions, `t` excludes paused time.
- gdUnit4: `MatchLifecycle` — `match_started`/`match_ended` exactly once; `request_new_match()` ignored in `Running`, deduped while queued; hidden during `Booting`.
- Integration test: `MatchDirector` with spy modules records call order 0→5d every frame; a serve and a timeout on the same guest in one frame → Served wins; third loss + serve to another guest in one frame → serve counted, then `match_ended`.
- On-device: Verification Required (1)–(4) on the ADR-0001 spike device.

## Related
- Depends on: ADR-0001 (`visibility_changed`, `ready_reached`)
- Consistent with: ADR-0002 (resize never touches `GameClock`/`MatchLifecycle`)
- Enables: ADR-0006, ADR-0007; ADR-0004 supplies `max_step_delta` and RNG
- Design: `design/gdd/guest-ai-patience.md` (Rules 8, 9, 11, 13), `player-control-barista-movement.md`, `brewing-crafting-mechanic.md`, `difficulty-curve-session-pacing.md`, `currency-coins-score.md`, `till-day-cycle.md`, `hud-feedback-ui.md`
- Architecture: `docs/architecture/architecture.md` §Data Flow, §API Boundaries, Principles 1–3
