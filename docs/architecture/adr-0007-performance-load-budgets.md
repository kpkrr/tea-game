# ADR-0007: Performance & Load Budgets

## Status
Proposed

## Date
2026-09-30

## Last Verified
2026-09-30 (template sizes measured on the installed 4.7.2 web export template; all device numbers are **provisional targets**, not measurements — see Verification Required)

## Decision Makers
User (project owner); godot-specialist (engine validation, 3 blocking findings resolved). `technical-director` sign-off on the numbers is pending (TD-ADR skipped in Lean review mode) and is required before Accepted, as Guest AI Open Question #8 assigns the threshold to that role.

## Summary
Tea Rush has only a global 16.6 ms budget; GDDs ask for per-system thresholds (Guest AI ≤ 0.5 ms avg / ≤ 1.0 ms p99) and the load size/time question is open. This ADR fixes a reference low-end Android class, a 60 fps target with a 30 fps floor, per-system CPU allocations, draw-call / texture / memory ceilings, a compressed download ceiling (13.5 MB, of which the stock engine is a measured 10.2 MB), cold/warm time-to-interactive targets, a boot-time material pre-warm, and how each budget is enforced (CI size gate, worst-case scene census, on-device perf-probe evidence).

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7.2 |
| **Domain** | Core / Rendering (Compatibility, WebGL2) / Web export |
| **Knowledge Risk** | HIGH — 4.7 is post-cutoff; the APIs used here (`Performance` monitors, `Viewport.scaling_3d_scale`, `Time.get_ticks_usec`, export-preset custom features) predate 4.4 and have no entries in `breaking-changes.md` / `deprecated-apis.md` |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `breaking-changes.md`, `deprecated-apis.md`, `modules/rendering.md`, `modules/web.md`; installed template `~/Library/Application Support/Godot/export_templates/4.7.2.stable/web_nothreads_release.zip` (unzipped and measured 2026-09-30) |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | (1) On the reference device: every table value below re-measured with the `perf_probe` build; numbers that fail are revised in this ADR (not silently exceeded). (2) `Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME` reports real values in Compatibility/WebGL2 and `ALPHA_CUT_OPAQUE_PREPASS` sprites cost 1 or 2 calls each (sets the census ceiling). (3) Web timer resolution: `Time.get_ticks_usec()` is coarsened by browsers (≈100 µs Chromium, ≈1 ms Firefox/Safari) — confirm that windowed sums over ≥ 600 frames give stable per-step averages. (4) First-use hitch: frame-time spike on first guest spawn / first `Label3D` glyphs with and without the boot pre-warm. (5) Whether `Engine.max_fps` has any effect in a web export (needed to cap 90/120 Hz phones; if it has none, capping is dropped, not emulated). (6) Brotli/gzip actually served by the chosen host for `.wasm` (compressed sizes below assume it). (7) Custom-feature tag `perf_probe` in the perf export presets is honoured by `OS.has_feature()` on web. (8) ✅ **Verified on 4.7.2 desktop (opengl3, `gl_compatibility`, 2026-09-30):** `Viewport.scaling_3d_scale` = 0.25 renders the 3D scene visibly at quarter resolution and upscales it (Bilinear) — the knob is not ignored in Compatibility. Still to confirm on WebGL2 on the RD (render at 0.5, compare screenshots). Fallback if it is ignored there: `display/window/dpi/allow_hidpi = false` (ADR-0002). (9) Which memory figure is real on web: `Performance.MEMORY_STATIC` and `OBJECT_ORPHAN_NODE_COUNT` are expected to read 0 in release templates (debug-only counters, per godot-specialist) — confirm, and fix the JS expression that reads the wasm heap size. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (spike supplies the device and the measured TTI/size; ADR-0001 is Proposed), ADR-0002 (draw-call estimate, `render_scale_3d` knob; Proposed), ADR-0003 (tick steps that are timed; Proposed). None is Accepted yet, so this ADR cannot be Accepted first |
| **Enables** | Vertical Slice perf gate; `tests/performance/` protocol; control-manifest guardrails; `/test-setup` CI size check |
| **Blocks** | Vertical Slice gate-check (perf evidence required there) |
| **Ordering Note** | Numbers marked *provisional* become binding only after the ADR-0001 spike records the reference device; if measurements disagree, this ADR is amended before either is Accepted. Constrains ADR-0005 (flush cost) and ADR-0006 (bake/verify cost) — both already state figures that are consistent with this table |

## Context

### Problem Statement
`technical-preferences.md` holds only "60 FPS target, 30 FPS floor, 16.6 ms". Nothing states which device the floor applies to, how big the download may be, how long a player waits for the first tap, what memory a low-end tab may use, or how any of it is checked. Guest AI AC 48 and Open Question #8 explicitly defer its threshold to this ADR; ADR-0001 defers size/TTI, ADR-0002 defers the draw-call ceiling and the `render_scale_3d` default. Unowned budgets are how a 2.5D Sprite3D scene on a weak phone quietly ends up at 18 fps.

### Constraints
- Web only (WebGL2, Compatibility), single-thread export (ADR-0001) — no worker threads to hide cost.
- Everything in the kitchen is `Sprite3D`/`AnimatedSprite3D`/`Label3D`; Compatibility does not batch 3D instances, so cost scales with instance count (ADR-0002 §4).
- Coding standards: tests must be deterministic and free of time-dependent assertions, so on-device timings cannot be unit tests.
- Real-device numbers do not exist yet (ADR-0001 spike pending); the installed engine template does exist and is measurable.

### Requirements
- Guest AI ≤ 0.5 ms avg / ≤ 1.0 ms p99 per frame (Guest AI AC 48; 4 guests, 18 guests/min, 180 s).
- Tap feedback within ≤ 50 ms engine-internal (Player Control TR-control-015).
- A budget for load size and time-to-interactive (Platform GDD Open Question 1, `architecture.md` AQ-01).
- Every budget has an owner, a unit, a measurement method and an enforcement point.

## Decision

### 1. Reference device and frame targets
The **reference device (RD)** is a class, not a model: Android 9–12-era phone, 2–3 GB RAM, entry-level SoC (Adreno 5xx / Mali-G5x-class GPU), current Chrome for Android, canvas 720×1600 to 1080×2400 device px. The concrete phone is chosen and recorded in the ADR-0001 spike; every "RD" number below is defined on it.

| Target | Value |
|---|---|
| Frame rate | **60 fps target** on mid/high devices and desktop; **30 fps floor on RD** |
| Frame time on RD | p95 ≤ 33.3 ms over a 3-minute match; **no frame > 100 ms after `ready_reached`** (page-return frame excluded) |
| Sim + presentation script cost | avg ≤ 2.0 ms, p99 ≤ 4.0 ms of frame time (table 2) |
| Tap-to-feedback | tap resolved at tick step 2 and marker drawn in the **same frame** (1 frame = ≤ 33 ms at the floor, inside TR-control-015); browser touch-to-engine latency is the spike's separate number |

### 2. Per-system CPU allocation (RD, ms per frame)
Measured around each `step()` call by the `PerfProbe` inside `MatchDirector._process` (the only place `step()` is called, ADR-0003).

| System (tick step) | Avg | p99 | Notes |
|---|---|---|---|
| MatchDirector + GameClock (all) | 0.05 | 0.10 | ADR-0003 estimate |
| TapPicker.flush (2) | 0.05 | 0.30 | per tap; ADR-0006: ≈35 ray-box tests |
| BaristaController + PathFollower (3) | 0.10 | 0.30 | includes ≤ 3 path queries per tap |
| Brewing / kettles (4) | 0.05 | 0.10 | |
| **GuestSim (5)** | **0.50** | **1.00** | Guest AI AC 48 |
| Guest path queries (5, separate line) | 0.10 | 0.30 | replaces "NavigationAgent separately" in AC 48 (ADR-0006) |
| Currency / Till / SaveStore check (6) | 0.05 | 0.20 | a dirty flush (`localStorage.setItem`) ≤ 2.0 ms once per change |
| Presentation scripts (sprite state, rings, pop numbers, HUD) | 0.80 | 1.50 | |
| **Sum of averages** | **1.70** | | cap 2.00 avg / 4.00 p99 total; 0.30 ms reserve |

Per-line **averages are gated**; per-line p99 values are **reported, not gated** — browser timers are coarsened (≈100 µs Chromium, ≈1 ms Firefox/Safari), so a per-frame p99 of a sub-0.1 ms step is noise. Only the total script time per frame has a gated p99. Guest AI AC 48's p99 ≤ 1.0 ms is therefore checked on the release perf build in Chrome, the browser with the finest timer.

### 3. Render ceilings
- **Draw calls per frame: target ≤ 100, hard ceiling 150** (`RENDER_TOTAL_DRAW_CALLS_IN_FRAME`, which also counts 2D/HUD canvas draws — the ceiling is for the whole frame, HUD included; the monitor reports the last completed frame).
- **Census: ≤ 75 renderable 3D instances** (`Sprite3D` + `AnimatedSprite3D` + `Label3D` + mesh instances) in the worst-case frame (4 guests, both kettles, all rings, pop numbers, tap marker, results overlay elements). 75 keeps the ceiling honest if prepass sprites cost two calls.
- Textures: no side > 2048 px (WebGL2 guaranteed minimum); **texture memory ≤ 48 MB** budgeted as uncompressed RGBA8 **including mipmaps (×1.33)** for 3D sprites, which are minified by distance. VRAM compression is an art-pipeline gain, not assumed; enabling it on web requires both S3TC/BPTC and ETC2/ASTC imports, which roughly doubles texture bytes in the `.pck` and needs an amendment to section 4 first.
- No real-time lights, shadows, post-processing, MSAA (ADR-0002), and no GPU particle systems; effects are sprite-based and count toward the census.
- **3D pixel budget.** `ViewFitMath` computes `render_scale = clamp(sqrt(render_pixel_budget / (W × H)), render_scale_min, render_scale_3d)` from the canvas size in device px (= window px only while `allow_hidpi` is on — ADR-0001 takes the value from `DisplayServer.window_get_size()`; if the `allow_hidpi = false` fallback is taken this formula must be re-derived — the window-px size `PlatformBridge` reports — under `canvas_items`/`expand` the root viewport renders 3D at real canvas px, not at the 360×640 base; `ViewFit` never reads `DisplayServer` itself, per the registry) and applies it through `Viewport.scaling_3d_scale`. Data knobs (`ViewConfig`, ADR-0004): `render_pixel_budget` 1 500 000, `render_scale_min` 0.6, `render_scale_3d` 1.0. A 720×1600 canvas (1.15 Mpx) is untouched; 1080×2400 (2.59 Mpx) renders at ≈ 0.76. The value is **static per canvas size**, recomputed on the debounced resize — no runtime adaptive quality in MVP. Only the 3D buffer is scaled; HUD/2D stay at full resolution, and tap picking is unaffected (camera projection works in viewport units).

### 4. Load budgets (first visit, cold cache, compressed transfer)

| Item | Budget | Basis |
|---|---|---|
| Engine `godot.wasm` + `godot.js` | **10.2 MB** (fixed line item) | Measured 2026-09-30, stock 4.7.2 `web_nothreads_release`: wasm 39 514 754 B raw → 10 114 302 B gzip-6; js 279 815 B → 68 749 B |
| Game `.pck` | ≤ 3.0 MB | Mostly PNG/WebP; treat raw size as transfer size |
| HTML shell, loader script, loading-screen art | ≤ 0.2 MB | ADR-0001 |
| **Total ceiling** | **13.5 MB** | 10.2 + 3.0 + 0.2 = 13.4 |

The stock template is the MVP baseline. A custom-built template (SCons, unused modules off) is a **contingency**, triggered only by the fail thresholds in table 5; its saving is not measured and is not assumed anywhere in this ADR. The ceiling assumes the host serves `.wasm` compressed (gzip at minimum); uncompressed it is ≈ 4× larger, so compression is a hosting requirement, not an optimisation.

### 5. Time-to-interactive (navigation start → `ready_reached`, input works)

| Scenario (RD) | Target | Fail threshold (triggers contingency) |
|---|---|---|
| Cold, 10 Mbps / 100 ms RTT | ≤ 20 s (≈ 11 s transfer + ≤ 9 s local) | > 30 s |
| Warm (files cached) | ≤ 6 s | > 10 s |

Local boot sub-budget (RD): wasm compile + engine init ≤ 5 s; `GameConfig` load + validate ≤ 0.1 s; kitchen scene instantiate ≤ 0.5 s; navmesh bake + `poll_ready` + `verify` ≤ 0.1 s (ADR-0006 contingency line: bake > 100 ms → ship the pre-baked resource); material pre-warm ≤ 0.5 s; slack 2.8 s. Slower links are unsupported for MVP; the loading screen (ADR-0001: progress, no timeout) is the only mitigation.

**Contingency order** if a fail threshold trips (cheapest first): (1) shrink `.pck` / texture atlases; (2) merge static kitchen layers into one baked background quad (also cuts draw calls); (3) custom export template; (4) a superseding ADR on threading — not before 1–3, and only with device data (ADR-0001).

### 6. Memory ceilings (RD)
- WASM linear memory peak ≤ 256 MB, read from JS (the module's memory buffer `byteLength`, via the shell) — not from `MEMORY_STATIC`, which counts only Godot's own allocations and reads 0 in release templates. Linear memory never shrinks, so the peak is the resident high-water mark; each growth copies the heap and can stall a frame, so boot (scene instantiate, pre-warm) should reach most of the peak behind the loading overlay.
- Texture memory ≤ 48 MB (section 3), GPU-side, separate from the wasm heap.
- **No growth across matches:** after 5 consecutive matches the wasm heap grew ≤ 2 MB versus after match 1 and `OBJECT_COUNT` is stable (release perf build); `OBJECT_ORPHAN_NODE_COUNT` = 0 and `MEMORY_STATIC` stable on the **debug** perf build (these counters exist only in debug templates). Guards the RefCounted cycle rule of ADR-0003. Any monitor used as evidence must read non-zero in the build it came from.

### 7. Boot pre-warm (new `Booting` prerequisite)
Compatibility compiles shader programs lazily on the **first draw** of each material/pass variant, `Label3D` builds its glyph atlas on the first text shaping, and WebAudio decodes a sample on first playback — each shows up as a stall on the first spawn, serve or pop number. During `Booting`, behind the HTML loading overlay (the canvas keeps rendering under it), `MatchDirector` runs `RenderPrewarm`:
- instantiates, **visible and inside the camera frustum** (small, placed in the real kitchen scene), one instance of every distinct material variant (opaque, alpha-cut prepass, no-depth-test overlay) and the first frame of every `AnimatedSprite3D` set, with the **same `Environment` and camera** as gameplay — a node with `visible = false`, an off-screen node or a `modulate.a = 0` trick is not drawn and compiles nothing;
- sets the full digit/currency charset on a live `Label3D`;
- plays every gameplay SFX once at zero volume on its bus;
- waits for two `RenderingServer.frame_post_draw` emissions — counted by a one-shot connection and **polled** by `MatchDirector._process` in the `PREWARM_WAIT` Booting sub-state (ADR-0003 §4); `_process` never `await`s — then frees the instances.

SFX during Booting run before any user gesture, so the WebAudio context is still suspended: pre-warm can force **decode** but not real playback. If Verification (4) still shows a first-SFX hitch, the audio part of pre-warm moves to the first user gesture (the first tap).

`PlatformBridge.mark_boot_complete()` is called only after `Pathing` is ready **and** pre-warm is done. This adds ≤ 0.5 s to boot (counted in section 5); Verification (4) checks it earns its cost. The 4.5 Shader Baker does not cover GL/WebGL and is not used.

### 8. Measurement and enforcement

| Budget | Mechanism | Gate |
|---|---|---|
| Download size | CI script gzip-6s the export output (`.wasm`, `.js`, `.pck`, shell) and fails above 13.5 MB or when engine bytes exceed 10.5 MB | BLOCKING (deterministic) |
| Census + texture memory | gdUnit4 integration test instantiates the worst-case kitchen and asserts instances ≤ 75 and summed texture bytes ≤ 48 MB | BLOCKING |
| Frame time, per-system ms, draw calls, wasm heap, TTI | Web export preset `web-perf` (**release** template) with custom feature `perf_probe`: `PerfProbe` (RefCounted) wraps each `step()` with `Time.get_ticks_usec()` **only** if `OS.has_feature("perf_probe")`, aggregates per second, exposes an on-screen overlay and a copyable log; run on RD, protocol in `tests/performance/`, evidence in `production/qa/evidence/perf-<date>.md` | ADVISORY per story; **required evidence at the Vertical Slice gate** |
| Orphans, static memory (leak run) | Preset `web-perf-debug` (**debug** template, same `perf_probe` feature): 5-match leak run only; its timings are pessimistic and never used as evidence for tables 1–2 | Same as above |
| Regression trend | Evidence files compared milestone to milestone | Producer review |

Timings are never asserted in unit tests (Testing Standards: determinism).

**Validation note (godot-specialist, 2026-09-30):** 3 blocking findings resolved — pre-warm rewritten (visible, in frustum, `frame_post_draw` ×2, text shaping and audio added), memory evidence split by template, `scaling_3d_scale` in Compatibility verified on desktop (WebGL2 pending). Per-line p99 un-gated.

### Architecture Diagram
```
Booting:  config ─ scene ─ Pathing.poll_ready ─ verify ─ RenderPrewarm(2 frames) ─► mark_boot_complete ─► ready_reached
Running:  MatchDirector._process
            └─ [PerfProbe] wraps step 2,3,4,5,6 ─► avg/p99 per second ─► overlay/log   (only with feature perf_probe)
Build:    export ─► CI: gzip-6 size ≤ 13.5 MB (blocking)     Tests: census ≤ 75 inst, tex ≤ 48 MB (blocking)
Device:   perf build on RD ─► production/qa/evidence/perf-<date>.md ─► Vertical Slice gate
```

### Key Interfaces
```gdscript
class_name PerfProbe extends RefCounted     # created only when OS.has_feature("perf_probe")
func begin(section: StringName) -> void
func end(section: StringName) -> void      # aggregates; no allocation per call
func frame_done(real_delta: float) -> void # windowed avg/p95/p99, draw calls, memory monitors

# ViewFitMath (pure static, ADR-0002)
static func render_scale(canvas_px: Vector2i, pixel_budget: int, scale_min: float, scale_cfg: float) -> float
```
`ViewConfig` (ADR-0002/0004) carries `render_scale_3d` (existing) plus new `render_pixel_budget` and `render_scale_min`; `ConfigValidator` rejects `render_scale_min` ∉ (0, 1] or `render_scale_3d` < `render_scale_min`.

### Implementation Guidelines
- Gameplay code must never call `Time`/`OS` timing functions itself; only `PerfProbe` (created and called only from `MatchDirector`) and injected clock adapters (the production `UtcClock` behind Till, `architecture.md` API Boundaries) may read `Time`.
- `PerfProbe` must be absent (null, no calls beyond one null check) in release builds without the `perf_probe` feature.
- New per-frame work must state its ms line in table 2 or fit the presentation line; exceeding a line requires amending this ADR.
- No new draw-call sources (particles, extra overlays) without updating the census test's worst-case scene.
- Budgets live in this ADR and the registry; numeric thresholds used by tests (75, 48 MB, 13.5 MB) come from a single data/constants file, not scattered literals.
- Pre-warm must instantiate from the same scenes/materials as gameplay (no separate look-alike materials), visible, in frustum, under the gameplay `Environment` and camera.
- `PerfProbe` must never be created from any condition other than the `perf_probe` feature tag.

## Alternatives Considered

### Alternative 1: Keep only the global 16.6 ms budget
- **Description**: No per-system lines; profile when something feels slow.
- **Pros**: Nothing to maintain.
- **Cons**: Guest AI AC 48 cannot be evaluated; a regression cannot be localised; the 30 fps floor has no defined device.
- **Rejection Reason**: The GDDs already require per-system thresholds.

### Alternative 2: Runtime adaptive quality (dynamic resolution, auto downgrade)
- **Description**: Measure frame time and lower `scaling_3d_scale` or disable effects on the fly.
- **Pros**: Handles unknown devices without a fixed cap.
- **Cons**: Needs an oscillation-safe controller and on-device tuning; browser timers are coarse; more code on the critical path before any measurement exists.
- **Rejection Reason**: Static pixel-budget cap covers the dominant cost (fill-rate on high-DPR phones); adaptive control can be a later ADR with data.

### Alternative 3: Timing assertions in CI
- **Description**: Fail the build if a step exceeds N ms in a headless benchmark.
- **Pros**: Automatic regression stop.
- **Cons**: Desktop headless numbers do not represent RD; violates determinism rules; flaky.
- **Rejection Reason**: Only deterministic proxies (size, census) block; timings are on-device evidence.

### Alternative 4: Custom engine template from day one
- **Description**: Build a slimmed web template with SCons.
- **Pros**: Smaller download and faster compile.
- **Cons**: Build pipeline and maintenance cost; gain unmeasured; harms Godot upgrade path.
- **Rejection Reason**: Kept as contingency 3 in section 5, triggered by measurement.

## Consequences

### Positive
- Every open budget question in the GDDs, ADR-0001 and ADR-0002 gets an owner and a number.
- Two blocking checks (size, census) need no device and catch the most common regressions early.
- A first-spawn hitch is designed out rather than discovered at playtest.

### Negative
- Most device numbers are provisional until the spike; some will move.
- Two perf export presets (release for timings, debug for the leak run) to maintain.
- Pre-warm adds up to 0.5 s to boot and one more Booting prerequisite.
- Static render scale can soften art on very high-DPR phones.

## Risks
- **Numbers were set before the RD exists.** *Mitigation*: status stays Proposed; amend on spike results; nothing here is called measured except template sizes.
- **Coarse browser timers hide sub-0.1 ms step costs.** *Mitigation*: windowed sums over ≥ 600 frames; p99 only asserted on total script time.
- **Prepass sprites may cost 2 draw calls each.** *Mitigation*: census ceiling 75 leaves room; Verification (2) sets the real ratio; fallback `ALPHA_CUT_DISCARD` for characters (ADR-0002).
- **Host may not compress `.wasm`.** *Mitigation*: hosting requirement recorded; CI measures compressed size; release checklist verifies served `Content-Encoding`.
- **`Engine.max_fps` on web is unconfirmed.** The web main loop is driven by `requestAnimationFrame`, but the engine may skip ticks until the target frame time, so a cap may work. No `OS.delay_*` emulation. *Mitigation*: Verification (5) decides; if the cap does nothing, 90/120 Hz phones run flat out, which is accepted for MVP, and battery impact is noted for playtests.
- **Pre-warm drift** — a material, font or SFX added later is missing from the pre-warm set. *Mitigation*: census test asserts every material of the worst-case scene is in the set.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| guest-ai-patience.md | AC 48 / Open Question #8 — Guest AI ≤ 0.5 ms avg / ≤ 1.0 ms p99 on the reference weak Android (TR-guest-022) | Table 2 sets the threshold; measured by `PerfProbe`; path queries on their own line |
| player-control-barista-movement.md | TR-control-015 — feedback ≤ 50 ms (3 frames) engine-internal | Same-frame resolution and marker draw; ≤ 33 ms at the 30 fps floor |
| platform-integration-telegram-mini-app.md | Open Question 1 — exact load time/size budget on weak Android (Telegram deferred; applies to plain web) | Sections 4–5: 13.5 MB ceiling, cold ≤ 20 s / warm ≤ 6 s with fail thresholds |
| kitchen-station-layout.md | TR-layout-014 — reference device for the 360×640 dp canvas; baked-lighting look with weak-Android cost | RD class defined; no lights/shadows; draw-call and census ceilings |
| game-concept.md | Technical risk: web build size / load time on weak Android | Measured engine size baseline and contingency ladder |

## Performance Implications
- **CPU**: script total avg ≤ 2.0 ms; `PerfProbe` costs nothing in normal builds.
- **Memory**: WASM ≤ 256 MB, textures ≤ 48 MB, no cross-match growth.
- **Load Time**: 13.5 MB ceiling; cold TTI ≤ 20 s at 10 Mbps, warm ≤ 6 s; pre-warm ≤ 0.5 s.
- **Network**: single static bundle; requires compressed `.wasm` from the host.

## Migration Plan
No production code exists. Doc syncs done with this ADR: `architecture.md` (ADR-0007 row), ADR-0002 §7 (`render_scale_3d` now a ceiling under a pixel budget), ADR-0003 (Booting pre-warm), ADR-0001 (`mark_boot_complete` prerequisites), ADR-0004 (`ViewConfig` fields), Guest AI GDD (AC 48 threshold, Open Question 8). Follow-ups: `render_pixel_budget`/`render_scale_min` fields in `ViewConfig` (sentinel defaults, ADR-0004); `tests/performance/` protocol at `/test-setup`; CI size script.

## Validation Criteria
- CI: export size ≤ 13.5 MB (gzip-6) and engine bytes ≤ 10.5 MB; census test ≤ 75 instances and ≤ 48 MB textures, every worst-case material in the pre-warm set.
- gdUnit4 Logic: `ViewFitMath.render_scale` — 720×1600 → 1.0; 1080×2400 → ≈ 0.76; tiny budget → clamped to `render_scale_min`; `ConfigValidator` rejects bad `ViewConfig` render fields.
- On RD with `perf_probe` (Vertical Slice): table 1–3, 5, 6 met or the ADR amended with the measured values; no frame > 100 ms after ready; 5-match memory check passes.
- Spike recorded before Accepted: RD model, cold/warm TTI, wasm size as served, draw-call count, first-spawn hitch with/without pre-warm.

## Related
- Depends on ADR-0001 (spike, size/TTI), ADR-0002 (`render_scale_3d`, draw-call estimate), ADR-0003 (tick steps timed).
- Consistent with ADR-0005 (flush cost), ADR-0006 (bake ≤ 100 ms, path query cost).
- GDDs: `design/gdd/guest-ai-patience.md`, `player-control-barista-movement.md`, `kitchen-station-layout.md`, `platform-integration-telegram-mini-app.md`; `docs/architecture/architecture.md` (AQ-01, AQ-04).
