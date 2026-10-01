# ADR-0007: Performance & Load Budgets

## Status
Accepted

> Accepted 2026-09-30 by the owner. Technical-director sign-off: APPROVED WITH CONDITIONS (2026-09-30). Frame-time and per-system ms lines and the device boot sub-budget stay provisional until the first weak-Android `perf_probe` run, required at the Vertical Slice gate at the latest; pre-warm's 0.5 s benefit (Verification 4) re-checked in the same run.

## Date
2026-09-30

## Last Verified
2026-10-01 (diorama amendment: budget arithmetic and the effective-budget table reconciled across all four amendments; texture figures computed from atlas sizes, not measured) · 2026-09-30 (template sizes measured on the installed 4.7.2 web export template; size, TTI, heap and draw-call figures checked on iPhone Safari in the ADR-0001 spike — see Spike Results; **frame-time, per-system ms and RD boot sub-budget remain provisional** until a weak-Android run)

## Decision Makers
User (project owner); godot-specialist (engine validation, 3 blocking findings resolved). `technical-director` sign-off on the numbers is pending (TD-ADR skipped in Lean review mode) and is required before Accepted, as Guest AI Open Question #8 assigns the threshold to that role.

## Summary
Tea Rush has only a global 16.6 ms budget; GDDs ask for per-system thresholds (Guest AI ≤ 0.5 ms avg / ≤ 1.0 ms p99) and the load size/time question is open. This ADR fixes a reference low-end Android class, a 60 fps target with a 30 fps floor, per-system CPU allocations, draw-call / texture / memory ceilings, a compressed download ceiling (baseline 13.5 MB, of which the stock engine is a measured 10.2 MB — **raised by the 2026-10-01 amendments to 32.5 MB; current values: "Current effective budgets" table at the top of the Decision**), cold/warm time-to-interactive targets, a boot-time material pre-warm, and how each budget is enforced (CI size gate, worst-case scene census, on-device perf-probe evidence).

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7.2 |
| **Domain** | Core / Rendering (Compatibility, WebGL2) / Web export |
| **Knowledge Risk** | HIGH — 4.7 is post-cutoff; the APIs used here (`Performance` monitors, `Viewport.scaling_3d_scale`, `Time.get_ticks_usec`, export-preset custom features) predate 4.4 and have no entries in `breaking-changes.md` / `deprecated-apis.md` |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `breaking-changes.md`, `deprecated-apis.md`, `modules/rendering.md`, `modules/web.md`; installed template `~/Library/Application Support/Godot/export_templates/4.7.2.stable/web_nothreads_release.zip` (unzipped and measured 2026-09-30) |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | (1) On the reference device: every table value below re-measured with the `perf_probe` build; numbers that fail are revised in this ADR (not silently exceeded). (2) `Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME` reports real values in Compatibility/WebGL2 and `ALPHA_CUT_OPAQUE_PREPASS` sprites cost 1 or 2 calls each (sets the census ceiling). (3) Web timer resolution: `Time.get_ticks_usec()` is coarsened by browsers (≈100 µs Chromium, ≈1 ms Firefox/Safari) — confirm that windowed sums over ≥ 600 frames give stable per-step averages. (4) First-use hitch: frame-time spike on first guest spawn / first `Label3D` glyphs with and without the boot pre-warm. (5) ✅ spike: works on web. Whether `Engine.max_fps` has any effect in a web export (needed to cap 90/120 Hz phones; if it has none, capping is dropped, not emulated). (6) Brotli/gzip actually served by the chosen host for `.wasm` (compressed sizes below assume it). (7) Custom-feature tag `perf_probe` in the perf export presets is honoured by `OS.has_feature()` on web. (8) ✅ **Verified on 4.7.2 desktop (opengl3, `gl_compatibility`, 2026-09-30):** `Viewport.scaling_3d_scale` = 0.25 renders the 3D scene visibly at quarter resolution and upscales it (Bilinear) — the knob is not ignored in Compatibility. Still to confirm on WebGL2 on the RD (render at 0.5, compare screenshots). Fallback if it is ignored there: `display/window/dpi/allow_hidpi = false` (ADR-0002). (9) Which memory figure is real on web: `Performance.MEMORY_STATIC` and `OBJECT_ORPHAN_NODE_COUNT` are expected to read 0 in release templates (debug-only counters, per godot-specialist) — confirm, and fix the JS expression that reads the wasm heap size. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (spike supplies the device and the measured TTI/size; ADR-0001 is Proposed), ADR-0002 (draw-call estimate, `render_scale_3d` knob; Proposed), ADR-0003 (tick steps that are timed; Proposed). None is Accepted yet, so this ADR cannot be Accepted first |
| **Enables** | Vertical Slice perf gate; `tests/performance/` protocol; control-manifest guardrails; `/test-setup` CI size check |
| **Blocks** | Vertical Slice gate-check (perf evidence required there) |
| **Ordering Note** | The ADR-0001 spike ran on iPhone only (Android not run, owner decision). Size, TTI, heap and draw-call lines are checked against it. Frame-time (table 1), per-system ms (table 2) and the RD local-boot sub-budget stay *provisional* and become binding only after the first weak-Android `perf_probe` run (at the latest the Vertical Slice gate); if that run disagrees, this ADR is amended, not silently exceeded. Constrains ADR-0005 (flush cost) and ADR-0006 (bake/verify cost) — both already state figures that are consistent with this table |

## Context

### Problem Statement
`technical-preferences.md` holds only "60 FPS target, 30 FPS floor, 16.6 ms". Nothing states which device the floor applies to, how big the download may be, how long a player waits for the first tap, what memory a low-end tab may use, or how any of it is checked. Guest AI AC 48 and Open Question #8 explicitly defer its threshold to this ADR; ADR-0001 defers size/TTI, ADR-0002 defers the draw-call ceiling and the `render_scale_3d` default. Unowned budgets are how a 2.5D Sprite3D scene on a weak phone quietly ends up at 18 fps.

### Constraints
- Web only (WebGL2, Compatibility), single-thread export (ADR-0001) — no worker threads to hide cost.
- Everything in the kitchen is `Sprite3D`/`AnimatedSprite3D`/`Label3D`; Compatibility does not batch 3D instances, so cost scales with instance count (ADR-0002 §4).
- Coding standards: tests must be deterministic and free of time-dependent assertions, so on-device timings cannot be unit tests.
- Real-device numbers exist for iPhone Safari only (ADR-0001 spike, 2026-09-30); no weak-Android measurement exists yet.

### Requirements
- Guest AI ≤ 0.5 ms avg / ≤ 1.0 ms p99 per frame (Guest AI AC 48; 4 guests, 18 guests/min, 180 s).
- Tap feedback within ≤ 50 ms engine-internal (Player Control TR-control-015).
- A budget for load size and time-to-interactive (Platform GDD Open Question 1, `architecture.md` AQ-01).
- Every budget has an owner, a unit, a measurement method and an enforcement point.

## Decision

### Current effective budgets (authoritative — as of Amendment 2026-10-01 "diorama")

> Sections 1–8 below are the **2026-09-30 baseline** and keep their original numbers for history; the amendments after section 8 change them in order (music 2026-09-30 → art 2026-10-01 → audio 2026-10-01 → diorama 2026-10-01). **This table is the single current answer**; where any older line in this ADR (Summary, §3, §4, §5, §6, §8, Diagram, Guidelines, Validation) disagrees, this table wins. The CI constants file holds exactly these values.

| Budget | Current value | Set by | Superseded values |
|---|---|---|---|
| Engine `godot.wasm` + `godot.js` (gzip) | 10.2 MB planned, **gate ≤ 10.5 MB** | §4 | — |
| Game `.pck` | **≤ 22.0 MB** | diorama | 3.0 (§4) → 8.0 (art) → 11.0 (audio) |
| HTML shell + loader + loading art | ≤ 0.2 MB | §4 | — |
| **Boot download (gates play)** | **≤ 32.5 MB** (10.2 + 22.0 + 0.2 = 32.4) | diorama | 13.5 → 18.5 → 21.5 |
| Post-boot music set (outside boot) | ≤ 6.0 MB | audio | 2.7 (music) |
| First-visit transfer (boot + music) | ≈ 38.4 MB | diorama | 16.2 → 21.1 → 27.4 |
| Cold TTI, 25 Mbps / 60 ms RTT (reference link) | **≤ 21 s**, fail > 31 s | diorama | 15 / 25 → 16 / 26 |
| Cold TTI, 10 Mbps / 100 ms (secondary) | **≤ 36 s**, fail > 46 s | diorama | 20 / 30 → 25 / 35 → 28 / 38 |
| Warm TTI | **≤ 8 s**, fail > 12 s | diorama | 6 / 10 → 7 / 10 |
| RD local boot | **≤ 10 s** (wasm+init 5.0, config 0.1, scene 0.5, nav 0.1, pre-warm 1.0, texture decode + upload 2.0, slack 1.3) | diorama | ≤ 9 s |
| Texture memory (GPU, RGBA8, mips ×1.33 where mipped) | **Mid/High ≤ 192 MB; Low ≤ 144 MB** (no scenery) | diorama | 48 → 96 |
| WASM linear memory peak | ≤ 256 MB | §6 | — |
| Sample-mode decoded PCM (outside wasm heap) | ≈ 35 MB, total Sample duration ≤ 90 s | audio | — |
| Renderable 3D instances (census, worst-case frame) | **≤ 115** | diorama | 75 → 95 |
| Draw calls per frame (incl. shadow pass and HUD) | **target ≤ 140, ceiling 200** | diorama | 100 / 150 → 120 / 180 |
| Shadow casters | ≤ 12 | art | — |
| Triangles in frame | **kitchen env + clutter ≤ 30 k; scenery ≤ 20 k (Mid/High)** | diorama | env ≤ 20 k |
| VFX puffs on screen | **≤ 12 pooled quads**, none wider than 25 % of `kitchen_rect` | diorama | — |
| Frame rate | 60 fps target (mid/high), 30 fps floor on RD at Low | §1, art | — |
| Script CPU (RD) | avg ≤ 2.0 ms, p99 ≤ 4.0 ms (table 2) | §2 | — |
| Music decode CPU (Mid) | avg ≤ 2.5 ms | audio | 1.0 |
| GPU lines (Mid, provisional) | shadow pass ≤ 3 ms; scenery + VFX ≤ 2 ms; tilt-shift (High only, if enabled) ≤ 1.0 ms | art, diorama | — |
| Boot pre-warm | **≤ 1.0 s** | diorama | 0.5 → 0.8 |
| Render scale | `render_pixel_budget` 1.5 Mpx, `render_scale_min` 0.6, `render_scale_3d` 1.0 | §3 | — |

### 1. Reference device and frame targets
The **reference device (RD)** is a class, not a model: Android 9–12-era phone, 2–3 GB RAM, entry-level SoC (Adreno 5xx / Mali-G5x-class GPU), current Chrome for Android, canvas 720×1600 to 1080×2400 device px. The concrete phone was **not** chosen in the ADR-0001 spike (iPhone only); it is recorded with the first weak-Android `perf_probe` run, and every "RD" frame-time/CPU number below is provisional until then.

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
| **Total ceiling** | **13.5 MB** | 10.2 + 3.0 + 0.2 = 13.4 *(baseline; current 32.5 MB — effective table)* |

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

> **Amendment 2026-09-30 — music budget (owner decisions during `/ux-design hud`, revised the same day).** One looped track, `assets/audio/music/music_jazz_main.ogg`: Ogg Vorbis, stereo, 48 kHz, ≈ 102 kbps, 204.8 s, **2 608 161 B (2.61 MB)**. Owner chose **"raise the budget"** over trimming or re-encoding. The earlier split of the `.pck` line (music ≤ 1.0 MB + everything else ≤ 2.0 MB) and the ≤ 48 MB decoded-PCM line are **withdrawn**. Both rested on Sample playback, which 4.7.2 source shows is unusable for this track (ADR-0001 amendment: whole-track synchronous decode, no bus effects).
> - **Download (§4): music is off the boot path.** It is excluded from the `.pck`, shipped next to `index.html` and fetched after `ready_reached` (ADR-0001 amendment). The §4 table is unchanged: engine 10.2 MB, **`.pck` ≤ 3.0 MB, all of it for art, SFX, fonts, scenes and data**, shell ≤ 0.2 MB, **boot total 13.5 MB**. New line outside the boot total: **post-boot music download ≤ 2.7 MB** (Ogg is already compressed, so it is counted at raw size; the host must serve it as `audio/ogg`, and gzip gains nothing). First-visit transfer is 16.2 MB in all, of which only 13.5 MB gates play.
> - **TTI (§5): unchanged.** Cold ≤ 20 s at 10 Mbps (13.4 MB ≈ 10.7 s transfer + ≤ 9 s local), warm ≤ 6 s, fail thresholds 30 / 10 s. At 10 Mbps the music arrives ≈ 2.1 s after `ready_reached` and plays from the next gesture on (or at once if the player has already tapped). On a warm visit it comes from the browser HTTP cache. The first seconds of the first match may be silent; this is accepted.
> - **Memory (§6), new line:** music resident in the wasm heap ≈ **2.7 MB** (compressed `OggPacketSequence`, Stream playback). The transient `HTTPRequest` body adds ≈ 2.7 MB at load, so heap high-water rises ≤ 6 MB (the heap never shrinks). No browser-side PCM. **Sample playback for music is forbidden:** for this track it would cost ≈ 157 MB of transient wasm heap (kept as high-water mark: 48 + 157 ≈ 205 MB of the 256 MB ceiling), a resident ≈ 79 MB `AudioBuffer` and a multi-second main-thread decode.
> - **CPU (§2), new line outside the 2.0 ms script cap:** *Music stream decode + mix + low-pass filter* (engine audio callback on the main thread, between frames, not inside `step()`): **avg ≤ 1.0 ms per frame on RD, provisional.** It is not measurable by `PerfProbe`, so it is measured as the frame-time delta between music playing and `stream_paused` over 600 frames on the `web-perf` build. It still counts toward the table-1 p95 ≤ 33.3 ms. Ring buffer: `audio/driver/output_latency.web` = 100 ms (ADR-0001). The earlier "play the music at −80 dB in `RenderPrewarm`" step is **removed**: Stream mode has no first-play conversion, and the file is not loaded at boot.
> - **Enforcement (§8):** the CI size gate measures the boot set (`.wasm`, `.js`, `.pck`, shell), **excluding** `music_jazz_main.ogg`, against 13.5 MB (engine ≤ 10.5 MB). It separately fails when the music file exceeds 2.7 MB, or when the `.pck` contains any `assets/audio/music/` path. 2.7 joins 13.5 / 10.5 in the single constants file. No size script exists yet (`.github/workflows/tests.yml` runs gdUnit4 only), so the gate is written with these lines by the `/test-setup` follow-up.
> - **Contingency if Stream music crackles on the RD** (ADR-0001 Verification A7, after raising `output_latency.web` to 200 ms): owner decision between (a) trimming the loop to ≤ 60 s mono and switching music to Sample mode, which drops the low-pass effect and replaces it with a volume duck (≈ 11 MB `AudioBuffer`, ≈ 23 MB transient heap, decode moved into `RenderPrewarm` with the file back in the `.pck`), or (b) accepting occasional underruns on the weakest devices. Not decided now.
> - Web audio unlock on iOS Safari (first touch), loop/pause/mute/filter behaviour and the fetch cost are verification items A1–A8 in ADR-0001's amendment.

> **Amendment 2026-10-01 — quality over size (owner decision during `/art-bible`).** New art direction (art bible A1: hand-drawn 2D cartoon characters + stylized 3D environment + real-time light; `design/art/lighting-feasibility-2026-10-01.md`). Owner: *"quality over squeezing megabytes — weak hardware is a small share, internet is fast"* (art bible A7). Budgets are raised to fit the art, not the reverse; the RD remains the **Low-tier fallback** target, not the design target.
> - **Load (§4):** `.pck` ≤ **8.0 MB** (art, SFX, fonts, scenes, data; music stays outside, 2026-09-30 amendment). Boot total 10.2 + 8.0 + 0.2 = 18.4 → **ceiling 18.5 MB**; engine line unchanged (≤ 10.5 MB gate). Post-boot music ≤ 2.7 MB unchanged → first-visit transfer ≈ 21.1 MB. Art estimate ≈ 6.7–8.7 MB (art bible §8.5): if the first real-art export exceeds 8.0 the owner rule is to raise this line, not to cut frames; lossy WebP is allowed only for the pre-blurred background layer. Contingency order in §5 step (1) "shrink `.pck` / atlases" is demoted to last-before-template for art (step order becomes 2 → 1 → 3 → 4).
> - **TTI (§5):** reference link becomes **25 Mbps / 60 ms RTT**: cold ≤ **15 s** (18.4 MB ≈ 5.9 s transfer + ≤ 9 s local), fail > 25 s. The 10 Mbps line stays as a secondary check: cold ≤ **25 s**, fail > 35 s. Warm ≤ **7 s** (+1 s for larger texture upload), fail > 10 s. Local-boot sub-budget adds texture upload of ≈ 90 MB of atlases ≤ 1.0 s (slack reduced to 1.8 s).
> - **Texture memory (§3, §6):** ≤ **96 MB** GPU-side, RGBA8, no VRAM compression. Character sprite atlases are imported **without mipmaps** (orthographic camera, minification ≤ ~1.4×), everything else with mipmaps (×1.33). Planned ≈ 89–91 MB (art bible §8.5: barista 2048² + 2048×1024, 4 guest archetypes × 2048×1536, props, env trim + lightmap, FX, UI). If the spike shows shimmer on unmipped walk cycles, mipmaps are enabled on characters and this line is raised to ~120 MB by a further amendment. Side ≤ 2048 px (WebGL2) is unchanged.
> - **Real-time light (§3) — lifted:** exactly **one `DirectionalLight3D`** with a shadow map, shadows cast **only by dynamic objects** (barista, guests, cups, via shadow-only proxy capsules; static geometry is baked and excluded from the shadow pass by layer). Omni/Spot lights, SSAO/SSIL/SSR/SDFGI/VoxelGI, volumetric fog, runtime DOF, Compositor effects and screen-texture post-processing remain **forbidden** (not available or too costly in Compatibility/WebGL2). Allowed cheap effects: depth fog, tonemap / color adjustments, pre-blurred background quad (fake DOF), additive gradient quads. Glow — High tier only. MSAA and GPU particles stay off.
> - **Quality tiers (new, static):** **Low** — no real-time shadows (blob contact shadows only, present on all tiers), no glow, `render_scale_min` allowed; **Mid** — shadow map 512, hard/low filter, no glow; **High** — 1024–2048, soft filter, light glow. The tier is chosen once at boot (static detection + manual override in Settings) — no runtime adaptation (Alternative 2 still rejected). Detection method and whether tiers need their own ADR: architecture.md AQ-10.
> - **Render ceilings (§3):** census ≤ **95** renderable 3D instances (adds merged static env meshes ≤ 3, 7 station bases, background meshes/quads ≤ 10). Draw calls **target ≤ 120, hard ceiling 180**, now **including the shadow pass**: shadow casters ≤ **12** (each is one extra draw in the shadow pass). Environment ≤ 20 k triangles in frame (art bible §8.4).
> - **Frame targets (§1):** unchanged numbers (60 fps target mid/high, 30 fps floor on RD) — on the RD they are measured **at the Low tier**; Mid/High are measured on a mid-range 2021+ Android and an iPhone. Provisional GPU line for the shadow pass on Mid: ≤ 3 ms/frame.
> - **Pre-warm (§7):** the variant set now includes: the toon sprite material (lit + receives-shadow variant), shadow-caster pass for proxy capsules, unshaded vertex-color environment material, LightmapGI-receiving material (if used), fog-on/off, and every tier's light/shadow configuration that the device can select (only the chosen tier is pre-warmed). Budget ≤ 0.8 s (was 0.5 s; counted in §5).
> - **Enforcement (§8):** single constants file: 13.5 → **18.5 MB**, 48 → **96 MB**, census 75 → **95**, draw-call ceiling 150 → **180**; 10.5 MB engine and 2.7 MB music unchanged. Census test adds "shadow casters ≤ 12".
> - **Verification (spike, before art production):** (S1) shadow map + proxy casters + toon shader on RD and mid device — ms/frame with shadows on/off, `render_scale` 0.6–1.0; (S2) LightmapGI + vertex AO on WebGL2 — size, artefacts; opaque meshes vs alpha-blended sprites sort order (guest behind counter); (S3) unmipped 192×256 sprites — shimmer at walk; (S4) tokens excluded from fog/tonemap/adjustments (ADR-0002 Amendment 2026-10-01) — screenshot contrast check.

> **Amendment 2026-10-01 — audio (owner decisions S1–S4 in `design/gdd/audio-juice-feedback.md`; quality over size, art bible A7).** Adaptive 4-stem match music + menu track, non-verbal voices for 4 archetypes, layered ambience.
> - **Post-boot music (§4):** the single-file line (≤ 2.7 MB) is replaced by a **music set ≤ 6.0 MB**: menu track + 4 match stems (Ogg Vorbis, ≈ 100 kbps stereo, bass stem may be 64 kbps mono; ≈ 5.2 MB planned). The CI gate checks a **list of files** (`music_menu_golden_hour_loop.ogg`, `music_match_*_stem.ogg`) instead of one name and still fails if any `assets/audio/music/` path is inside the `.pck`. `music_jazz_main.ogg` leaves the export (ADR-0001 amendment 2026-10-01 audio).
> - **Load (§4):** `.pck` ≤ **11.0 MB** (art ≈ 6.7–8.7 MB + SFX/voices/stingers/ambience ≈ 2.6 MB QOA + fonts, scenes, data). Boot total 10.2 + 11.0 + 0.2 = 21.4 → **ceiling 21.5 MB**; engine line unchanged (≤ 10.5 MB gate). First-visit transfer ≈ 27.4 MB, of which 21.4 MB gates play.
> - **TTI (§5):** at the 25 Mbps / 60 ms reference, cold ≤ **16 s** (21.4 MB ≈ 6.9 s transfer + ≤ 9 s local), fail > 26 s; at 10 Mbps cold ≤ **28 s**, fail > 38 s. Warm unchanged (≤ 7 s).
> - **CPU (§2), music line:** *music stream decode + mix + filter* (4 Ogg decoders in `AudioStreamSynchronized`, main thread between frames) — **avg ≤ 2.5 ms per frame on Mid devices, provisional**; on the RD (Low tier) measured at the fallback path if S1 fails there. Replaces the 1.0 ms single-track line.
> - **Memory (§6), new lines:** music resident ≈ 5.2 MB compressed in the wasm heap (+ one transient request body ≤ 1.2 MB, released before the next fetch). **Sample-mode decoded PCM** (Web Audio `AudioBuffer`, float32, outside the wasm heap): budget ≈ **35 MB** for the sum of all Sample assets (≈ 0.4 MB per second of mono audio at 48 kHz) — tracked as total Sample duration ≤ 90 s per the audio GDD; fallback: voices and ambience resampled to 32 kHz.
> - **Pre-warm (§7):** decode of every Sample asset stays in pre-warm (≤ ~150 decodes); if it pushes pre-warm over 0.8 s, voices and ambience decode in the menu after the first gesture instead.
> - **Enforcement (§8):** single constants file: boot ceiling 18.5 → **21.5 MB**, `.pck` 8.0 → **11.0 MB**, music 2.7 → **6.0 MB (set)**, music CPU 1.0 → **2.5 ms**; new constants `sample_pcm_mb = 35`, `sample_total_s = 90`.
> - **Verification:** audio spikes S1–S3 (ADR-0001 amendment 2026-10-01 audio).

> **Amendment 2026-10-01 — diorama: perspective camera, hand-painted textured environment, scenery, VFX puffs (owner decision 2026-10-01, binding; ADR-0002 Amendment 2026-10-01 "diorama camera"; owner policy "quality over megabytes — raise budgets rather than cut art; Low tier = fallback only").** All resulting numbers are in the **Current effective budgets** table at the top of the Decision; this block gives the reasoning.
> - **Perspective camera — render cost.** Projection type does not change draw calls or shader cost; frustum culling now trims scenery outside the view. What changes: the 3D scene fills the **whole viewport** (letterbox and strips show scenery on Mid/High instead of a clear colour → roughly +40 % opaque fill on phones, more on wide windows; `render_scale` already caps the pixel count), the directional shadow covers a camera slice ≈ 22–46 m deep instead of an ortho box (texel density re-checked in S1/S5), and depth fog/shadow distances follow the solved camera distance (ADR-0002 diorama amendment, point 3). No draw-call increase is expected from the camera itself; the census increase below is scenery and VFX.
> - **Environment textures (hand-painted atlases).** Kitchen environment meshes (floor, walls, counters, station bases, periphery clutter) use **2 × 2048² albedo atlases**, mipmapped, multiplied by baked light/AO in vertex colors (optionally LightmapGI floor/walls, already in the art budget), unshaded; `.pck` storage **lossless WebP** (≈ 2.5–3.5 MB each). Floor/walls use anisotropic filtering where WebGL2 exposes it (ADR-0002 V8, проверить в 4.7.2). Scenery outside `frame_bounds` (water, cliffs, far props) uses **2 × 2048²** atlases, **lossy WebP** allowed (like the pre-blurred background layer; ≈ 1 MB each), **loaded only on Mid/High** — the Low tier never instantiates scenery and shows `background_color`. Static meshes merge into ≤ 5 kitchen meshes (was ≤ 3; second atlas + alpha-cut foliage) and ≤ 6 scenery meshes, all outside the shadow pass.
> - **VFX puffs (steam, smoke, sparks, fire glow).** Flipbook sprite sheets in **one 2048×1024 atlas** (mipped, lossless), drawn as a **pool of ≤ 12 camera-facing quads** (`Sprite3D`/`AnimatedSprite3D`, or one `CPUParticles3D` per emitter type if story 014 shows it is cheaper — each is one draw call; **GPU particles stay forbidden**). Their materials are alpha-blended or additive, `render_priority` in the **world band below every overlay band** and overlays keep `no_depth_test`, so a puff can never draw over a token, ring, price, tag or the target outline (TR-art-010); none is wider than 25 % of `kitchen_rect` (overdraw cap). Lantern and fire glow = baked into vertex color/lightmap + additive glow quads; Omni/Spot lights stay forbidden. Reduced motion: puffs keep their first frame or are hidden (HUD/flow rule).
> - **Texture memory (planned).** Previous plan ≈ 89–91 MB (art amendment) − old env trim ≈ 6 MB + kitchen atlases 42.7 MB + VFX atlas 10.7 MB + scenery 42.7 MB ≈ **180 MB on Mid/High**, ≈ 137 MB on Low (no scenery) → ceilings **192 / 144 MB**. Character atlases stay unmipped, but far-side characters are now ≈ 0.82× of near-side size, so worst-case minification rises to ≈ 1.7× — spike S3 re-runs at back-wall depth; if it shimmers, characters get mipmaps (+24 MB) and the Mid/High line becomes ≈ 216 MB by a further amendment. **This is a hard-platform risk, not only a budget**: mobile browsers kill tabs on GPU memory pressure regardless of policy. Contingency (cheapest first, before any art cut): (1) VRAM compression for environment/scenery/VFX atlases on web — ETC2/ASTC **and** S3TC/BPTC imports (≈ ¼ of RGBA8 in memory, ≈ 2× those textures' bytes in `.pck`) — needs its own spike and a §4 amendment; (2) scenery atlases 1024² on Mid; (3) Low-tier half-resolution kitchen atlases.
> - **Load.** `.pck` ≤ **22.0 MB** = 11.0 (previous line: characters, props, UI, old env, SFX, fonts, scenes, data) + kitchen atlases ≤ 7.0 + scenery atlases ≤ 2.0 + VFX ≤ 1.5 + scenery/clutter meshes ≤ 0.5. Boot = 10.2 + 22.0 + 0.2 = 32.4 → **ceiling 32.5 MB** (engine gate ≤ 10.5 MB unchanged). TTI at 25 Mbps: 32.4 MB ≈ 10.4 s + ≤ 10 s local → **≤ 21 s**, fail > 31 s; at 10 Mbps ≈ 25.9 s + 10 s → **≤ 36 s**, fail > 46 s; warm ≤ 8 s (fail > 12 s). RD local boot ≤ 10 s, of which texture decode + upload ≤ 2.0 s (WebP decode of ≈ 10 large atlases on the main thread) and pre-warm ≤ 1.0 s. Contingency step added before the custom template: **stream scenery atlases after `ready_reached`** (like music; letterbox shows `background_color` until they arrive) — saves ≈ 2.5 MB of boot.
> - **Census / draw calls / triangles.** Census ≤ **115** (+2 kitchen env meshes, +6 scenery meshes, +12 VFX quads). Draw calls **target ≤ 140, ceiling 200** including the shadow pass; scenery and VFX never cast shadows (shadow casters ≤ 12 unchanged). Triangles: kitchen env + clutter ≤ 30 k, scenery ≤ 20 k.
> - **Tilt-shift.** Baked (pre-blurred scenery textures) is allowed on all tiers and costs nothing extra. Runtime screen-space tilt-shift stays **forbidden** under the existing "no runtime DOF / screen-texture post-processing" rule, with one gated exception: High tier only, if spike S5 (visual-pipeline story 013) measures ≤ 1.0 ms/frame on a High-tier device and shows the mask never touches `kitchen_rect`, overlays or HUD.
> - **Pre-warm (§7).** Adds the textured env material (albedo × vertex color, ± lightmap), the scenery material (+ UV-scroll variant, Mid/High), the VFX alpha and additive flipbook materials, and the tilt-shift pass if enabled; ≤ **1.0 s**.
> - **Enforcement (§8).** Constants file: boot 21.5 → **32.5 MB**, `.pck` 11.0 → **22.0 MB**, texture 96 → **192 MB (Mid/High) / 144 MB (Low)**, census 95 → **115**, draw-call ceiling 180 → **200**, new `vfx_pool_max = 12`, `env_tris_max = 30000`, `scenery_tris_max = 20000`; engine 10.5 MB and music 6.0 MB unchanged. The census test builds the worst-case frame twice (Low without scenery, High with scenery and a full VFX pool) and asserts both texture lines.
> - **Verification (spikes).** S1 re-run with the perspective camera (shadow slice depth, texel density, peter-panning). **S5 (new, visual-pipeline story 013):** perspective fit vs `Camera3D` (ADR-0002 V5), per-sprite upright stretch on screen, overlay minimum size at the back wall, anisotropic vs trilinear floor, scenery + VFX GPU cost on Mid, optional runtime tilt-shift cost on High. S3 re-run at back-wall depth.

**Validation note (godot-specialist, 2026-09-30):** 3 blocking findings resolved — pre-warm rewritten (visible, in frustum, `frame_post_draw` ×2, text shaping and audio added), memory evidence split by template, `scaling_3d_scale` in Compatibility verified on desktop (WebGL2 pending). Per-line p99 un-gated.

### Architecture Diagram
```
Booting:  config ─ scene ─ Pathing.poll_ready ─ verify ─ RenderPrewarm(2 frames) ─► mark_boot_complete ─► ready_reached
Running:  MatchDirector._process
            └─ [PerfProbe] wraps step 2,3,4,5,6 ─► avg/p99 per second ─► overlay/log   (only with feature perf_probe)
Build:    export ─► CI: gzip-6 boot size ≤ 32.5 MB (blocking)   Tests: census ≤ 115 inst, tex ≤ 192/144 MB (blocking)
          (baseline was 13.5 MB / 75 / 48 MB — values from the effective-budget table)
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
- Budgets live in this ADR and the registry; numeric thresholds used by tests (currently 115, 192/144 MB, 32.5 MB — effective-budget table) come from a single data/constants file, not scattered literals.
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
- **Numbers were set before the RD exists.** *Mitigation*: iPhone spike confirmed size/TTI/heap/draw calls; frame-time and per-system lines are explicitly provisional and amended on the first weak-Android run.
- **Coarse browser timers hide sub-0.1 ms step costs.** *Mitigation*: windowed sums over ≥ 600 frames; p99 only asserted on total script time.
- **Prepass sprites may cost 2 draw calls each.** *Mitigation*: census ceiling 75 leaves room; Verification (2) sets the real ratio; fallback `ALPHA_CUT_DISCARD` for characters (ADR-0002).
- **Host may not compress `.wasm`.** *Mitigation*: hosting requirement recorded; CI measures compressed size; release checklist verifies served `Content-Encoding`.
- **90/120 Hz phones run the sim at display rate.** `Engine.max_fps` works on web (spike 2026-09-30), so a 60 fps cap is available if battery/heat becomes a playtest issue; not enabled by default in MVP.
- **Pre-warm drift** — a material, font or SFX added later is missing from the pre-warm set. *Mitigation*: census test asserts every material of the worst-case scene is in the set.

## Spike Results (2026-09-30)

Source: `prototypes/web-spike/README.md` (session `0b7b7c05`, iPhone Safari, DPR 3). **The reference device (weak Android) was not available**: iPhone numbers confirm size, load and memory budgets but say nothing about the 30 fps floor. Frame-time and per-system lines stay provisional until a weak-Android run.
- §4 ✅ engine gzip 10.11 MB + 0.07 MB js (as measured on the template).
- §5 ✅ (iPhone): measured cold ready 9.6 s over a phone hotspot; local boot ≈ 3.5 s; modelled cold TTI at 10 Mbps ≈ 13 s with the spike's ≈ 30 KB `.pck` — ≈ 15.5 s with a full 3.0 MB `.pck`, still ≤ 20 s; warm 1.2 s. Weak-Android local boot (budget ≤ 9 s) unmeasured.
- §6 ✅ wasm heap 48.4 MB after boot (JS-side `Memory.buffer.byteLength`).
- §3: 83 draw calls at 75 instances; 60 fps (display cap) at every render scale.
- Verification (5) ✅ `Engine.max_fps = 30` works on web (30.0 fps in iOS Safari and desktop Chromium) — 90/120 Hz phones can be capped; see Risks.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| guest-ai-patience.md | AC 48 / Open Question #8 — Guest AI ≤ 0.5 ms avg / ≤ 1.0 ms p99 on the reference weak Android (TR-guest-022) | Table 2 sets the threshold; measured by `PerfProbe`; path queries on their own line |
| player-control-barista-movement.md | TR-control-015 — feedback ≤ 50 ms (3 frames) engine-internal | Same-frame resolution and marker draw; ≤ 33 ms at the 30 fps floor |
| platform-integration-telegram-mini-app.md | Open Question 1 — exact load time/size budget on weak Android (Telegram deferred; applies to plain web) | Sections 4–5 (baseline 13.5 MB, cold ≤ 20 s / warm ≤ 6 s); current: 32.5 MB, cold ≤ 21 s at 25 Mbps, warm ≤ 8 s — effective-budget table |
| kitchen-station-layout.md | TR-layout-014 — reference device for the 360×640 dp canvas; baked-lighting look with weak-Android cost | RD class defined; no lights/shadows; draw-call and census ceilings |
| game-concept.md | Technical risk: web build size / load time on weak Android | Measured engine size baseline and contingency ladder |
| art-bible.md | TR-art-007 (revised 2026-10-01), TR-art-010, TR-art-011 — diorama budgets, VFX puffs never over tokens, scenery Mid/High only | Effective-budget table; Amendment 2026-10-01 "diorama" |

## Performance Implications
- **CPU**: script total avg ≤ 2.0 ms; `PerfProbe` costs nothing in normal builds.
- **Memory**: WASM ≤ 256 MB, textures ≤ 192 MB Mid/High / 144 MB Low (baseline 48 MB), no cross-match growth.
- **Load Time**: boot ceiling 32.5 MB (baseline 13.5); cold TTI ≤ 21 s at 25 Mbps / ≤ 36 s at 10 Mbps, warm ≤ 8 s; pre-warm ≤ 1.0 s (effective-budget table).
- **Network**: single static bundle; requires compressed `.wasm` from the host.

## Migration Plan
No production code exists. Doc syncs done with this ADR: `architecture.md` (ADR-0007 row), ADR-0002 §7 (`render_scale_3d` now a ceiling under a pixel budget), ADR-0003 (Booting pre-warm), ADR-0001 (`mark_boot_complete` prerequisites), ADR-0004 (`ViewConfig` fields), Guest AI GDD (AC 48 threshold, Open Question 8). Follow-ups: `render_pixel_budget`/`render_scale_min` fields in `ViewConfig` (sentinel defaults, ADR-0004); `tests/performance/` protocol at `/test-setup`; CI size script.

## Validation Criteria
- CI: boot export size ≤ 32.5 MB (gzip-6; baseline 13.5) and engine bytes ≤ 10.5 MB; census test ≤ 115 instances (baseline 75) and ≤ 192 MB (Mid/High) / 144 MB (Low) textures (baseline 48 MB), every worst-case material in the pre-warm set.
- gdUnit4 Logic: `ViewFitMath.render_scale` — 720×1600 → 1.0; 1080×2400 → ≈ 0.76; tiny budget → clamped to `render_scale_min`; `ConfigValidator` rejects bad `ViewConfig` render fields.
- On RD with `perf_probe` (Vertical Slice): table 1–3, 5, 6 met or the ADR amended with the measured values; no frame > 100 ms after ready; 5-match memory check passes.
- Spike recorded before Accepted (iPhone, done): cold/warm TTI, wasm size as served, draw-call count. Still open, due at the first weak-Android run / Vertical Slice gate: RD model, frame time, first-spawn hitch with/without pre-warm (Verification 4).

## Related
- Depends on ADR-0001 (spike, size/TTI), ADR-0002 (`render_scale_3d`, draw-call estimate), ADR-0003 (tick steps timed).
- Consistent with ADR-0005 (flush cost), ADR-0006 (bake ≤ 100 ms, path query cost).
- GDDs: `design/gdd/guest-ai-patience.md`, `player-control-barista-movement.md`, `kitchen-station-layout.md`, `platform-integration-telegram-mini-app.md`; `docs/architecture/architecture.md` (AQ-01, AQ-04).
