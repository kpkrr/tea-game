# ADR-0002: Viewport, camera fit & 2.5D presentation

## Status
Accepted

> Accepted 2026-09-30 by the owner. Open item (not a blocker): price `Label3D` ≈ 7.7 dp vs the 12 dp accessibility target — to be settled in `/ux-design hud`.

## Date
2026-09-30

## Last Verified
2026-09-30

## Decision Makers
Yan (product owner) · godot-specialist (engine validation 2026-09-30: no blocking issues; 3 minor notes folded in) · technical-director review skipped (review_mode `lean`)

## Summary
Every Foundation and Presentation module needs one agreed answer to "where is the kitchen on screen, in what units, and how is it drawn": the stretch mode, the playfield clamp and letterbox, the orthographic camera fit that keeps the kitchen at ≥ 95 % of the playfield, the dp unit used by taps and HUD, and how 2.5D sprites and world overlays render on WebGL2. This ADR pins `canvas_items`/`expand` on a 360×640 base (1 viewport unit = 1 reference dp), fits a single fixed-pitch orthographic camera with computed `size` and `h_offset`/`v_offset` (letterbox is just background), draws world overlays as camera-facing `Sprite3D`/`Label3D`, and renders everything unshaded with painted blob shadows.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7.2 (GDScript, Compatibility renderer / WebGL2) |
| **Domain** | Rendering / UI |
| **Knowledge Risk** | HIGH — post-cutoff (`VERSION.md`); 4.7 changed project stretch defaults and `CanvasItem` line AA |
| **References Consulted** | `docs/engine-reference/godot/modules/rendering.md` (dated 4.6), `modules/ui.md` (4.6), `modules/web.md` (2026-09-30), `breaking-changes.md` (4.6→4.7: stretch defaults, line AA feather, `Control` offset-transform), `deprecated-apis.md`; `prototypes/kitchen-core/kitchen_core.gd` (`_fit_camera`, pitch 39.3°) as a proven starting point |
| **Post-Cutoff APIs Used** | 4.7 `Control` offset-transform (§6 popup/slide animations): `offset_transform_enabled` plus `offset_transform_position`/`_scale`/`_rotation`/`_pivot` (visual-only by default; nothing applies until enabled — `modules/ui.md`, verified 2026-09-30). Otherwise none new. Relies on 4.7 *defaults* being overridden explicitly (`window/stretch/mode`, `window/stretch/aspect`). `Camera3D` ortho `size`/`keep_aspect`/`h_offset`/`v_offset`, `Sprite3D`/`AnimatedSprite3D`/`Label3D` flags are pre-cutoff APIs |
| **Verification Required** | (1) `get_viewport().get_final_transform()` maps window px → viewport units correctly under `canvas_items`/`expand` on web, and input/`unproject_position` are in viewport units (unit test + on-device check); if the debug assert against `get_visible_rect()` fails, switch to `get_screen_transform()`. (2) Alpha sorting of overlapping `AnimatedSprite3D`/`Sprite3D` with `ALPHA_CUT_OPAQUE_PREPASS` on Compatibility/WebGL2 looks correct (guest in front of counter, barista behind island). (3) Actual FPS gain from `Viewport.scaling_3d_scale` (default Bilinear mode, supported by all rendering methods including Compatibility; only FSR modes are Forward+/Mobile-only) on the weak-Android spike device; fallback `display/window/dpi/allow_hidpi = false`. (4) `Label3D` legibility at the 9:20 worst case on a real phone. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (Web build & platform shell) — consumes `safe_area_changed(rect: Rect2)` in window px and the Adaptive canvas resize policy. ADR-0001 is Proposed; this ADR cannot be Accepted before it |
| **Enables** | ADR-0006 (Navigation & tap picking — tap coordinates, `unproject_position` and `tap_pick_radius` are all in the dp unit fixed here), ADR-0007 (Perf budgets — draw-call and 3D render-scale ceilings) |
| **Blocks** | ViewFit, KitchenLayout presentation, HUD layout and world-overlay stories; any story that places sprites or reads tap positions |
| **Ordering Note** | Config values named here (`kitchen_fill_target`, `camera_pitch_deg`, `letterbox_color`, `render_scale_3d`) are loaded through ADR-0004's config mechanism; until ADR-0004 lands they live as a single typed `Resource` owned by ViewFit, not as literals in code |

## Context

### Problem Statement
The kitchen is a fixed 3D scene (~8×11 m) seen through a fixed, pitched camera, but the screen can be anything from a 9:20 phone to a wide desktop browser window. The GDDs fix the *contracts* — clamp the safe aspect to [0.45, 1.0] and letterbox outside it (Platform), fill ≥ 0.95 of the binding playfield side (Kitchen), leave the remaining strips to the HUD, 48 dp tap targets on a 360×640 reference — but explicitly defer the *mechanism* to this ADR. Godot 4.7 also silently changed the project's stretch defaults, so leaving them unset is itself a decision. Every module that draws something or reads a tap position depends on the answer.

### Constraints
- Compatibility renderer / WebGL2 only (ADR-0001); weak Android in a mobile browser is the performance floor (Architecture Principle 5).
- Portrait-only, aspect range 9:20–1:1; no landscape layout.
- Camera never pans or rotates; only zoom (ortho `size`) adapts to the viewport (Kitchen GDD).
- Art: 2D painted sprites in a 3D scene, drawn once for the fixed camera angle; no shader animation or parallax on static geometry; baked/painted lighting (game-concept Visual Identity Anchor, Kitchen GDD).
- `PlatformBridge` is the only source of viewport changes (`safe_area_changed`, already debounced to once per frame by ADR-0001).

### Requirements
- Explicit stretch mode/aspect, not the 4.7 default (TR-platform-007).
- Playfield = safe area clamped to [`viewport_aspect_min`, `viewport_aspect_max`], centred, letterboxed; `safe_h = max(1, …)` (TR-platform-008, -009, -016).
- Kitchen fills ≥ `playfield_min_fill` (0.95) of the binding playfield side at every aspect in range; uniform scale; camera zoom recomputed on each change (TR-layout-010, -011, -015).
- Mid-match resize changes only presentation, never match state (TR-platform-017).
- A single dp unit for taps and HUD (TR-layout-014, TR-control-011).
- World overlays for till, kettles, guest token and ring, cup tokens, station labels, target outline (TR-hud-002); screen strips for score and strikes that the world never enters (TR-hud-001, -012).

## Decision

**1. Stretch.** Project settings pin `window/stretch/mode = canvas_items`, `window/stretch/aspect = expand`, `window/size/viewport_width × height = 360 × 640`. Under `expand` the visible viewport grows beyond 360×640 on any other shape, but one viewport unit always equals one **reference dp** (the unit of the 360×640 design canvas). Input event positions, `Control` layout and `Camera3D.unproject_position` are expected to return viewport units under the documented stretch behaviour (the prototype already compares `unproject_position` with raw tap positions directly), so taps and HUD work in dp with no conversion (`dp_scale ≡ 1`) — confirmed by the unit test and on-device check in Verification Required (1). On CSS viewports smaller than 360×640 a reference dp is physically smaller than a CSS px — accepted: the whole kitchen shrinks with it, and TR-layout-014 is defined on the reference device.

**2. Safe area → playfield.** `ViewFit` listens only to `PlatformBridge.safe_area_changed(rect_px)` and converts it with `get_viewport().get_final_transform().affine_inverse() * rect_px` into viewport units, then applies the Platform GDD formula unchanged: `safe_h = max(1, h)`, `safe_aspect = w / safe_h`, clamp to [`viewport_aspect_min`, `viewport_aspect_max`] (0.45, 1.0 — data), playfield centred in the safe area. Letterbox is whatever remains of the viewport; it is not a separate node.

**3. Camera fit (single ortho camera, whole viewport).** The camera keeps a fixed transform (position and look target from config; pitch 39.3° in the prototype) with `projection = PROJECTION_ORTHOGONAL` and `keep_aspect = KEEP_HEIGHT`. At load, `ViewFit` projects the 8 corners of `KitchenLayout.frame_bounds` (the world AABB that must stay visible: floor, counters, station sprite tops, guest queue, till) onto the camera's right/up axes, giving a constant projected size `F = (F_w, F_h)` in metres and a projected centre `c`. On every playfield change:

```
s        = kitchen_fill_target × min(P.w / F_w, P.h / F_h)     # dp per metre; kitchen_fill_target ∈ [0.95, 1.0], default 0.96
size     = V.h / s                                             # ortho size = visible world height across the full viewport
h_offset = c.x − (P.center.x − V.w / 2) / s                    # shifts the frame centre onto the playfield centre
v_offset = c.y + (P.center.y − V.h / 2) / s                    # screen y grows downward; sign pinned by unit test
kitchen_rect = Rect2(P.center − F × s / 2, F × s)              # on-screen kitchen, dp
```

`V` is the visible viewport size, `P` the playfield, both in dp. By construction the binding side is filled to exactly `kitchen_fill_target` ≥ 0.95, satisfying the Kitchen GDD assert at every aspect; the non-binding side has more slack. The HUD strips are `P − kitchen_rect` (top/bottom on phones, sides on square windows) plus the letterbox. This is the prototype's `_fit_camera()` generalised from two hard-coded branches to the clamp-and-fill formula.

**4. 2.5D sprites.** Stations, items, floor and counters are `Sprite3D`/textured quads; barista and guests are `AnimatedSprite3D` (4 directions, side mirrored). All are **unshaded** (`shaded = false`); there are no real-time lights and no shadow maps. Characters get a painted soft blob-shadow quad on the floor; station shadows are painted into their textures. World sprites stand **upright** (no rotation) with `scale.y = 1 / cos(camera_pitch)` to undo the camera's foreshortening, not `BILLBOARD_ENABLED` and not a backward tilt — on screen they look camera-facing, in the world they stay inside their own footprint column. *(Changed 2026-09-30 after the spike: the earlier `rotation.x = −camera_pitch` leans a 1.6 m guest ≈ 1 m backwards, into whatever stands behind it — the phone showed guests' heads cut by the counter behind them in every alpha mode.)* Overlays (§5) keep the camera-facing tilt: they have no depth test, so leaning is harmless and text stays square to the view. Characters and stations use `alpha_cut = ALPHA_CUT_OPAQUE_PREPASS` so the depth buffer orders a guest in front of the counter correctly while keeping soft painted edges. The 3D engine owns draw order (depth), not the scene tree.

**5. World overlays.** Guest order token and patience ring, cup tokens, kettle state, till fill, station labels, target outline and floor ring are `Sprite3D`/`Label3D` children of the entity they describe, with the same fixed camera-facing rotation, `no_depth_test = true` and explicit `render_priority` bands (world < Approaching overlays < Waiting overlays < held-cup tokens), so a Waiting guest's token always draws over an Approaching one (TR-hud-013). They move and scale with the kitchen for free and pause with game time because they are driven by the same simulation state. `render_priority` orders **transparent** geometry only, so overlay materials must stay alpha-blended (never alpha-cut/opaque-prepass), and every `Label3D`'s `outline_render_priority` must be below its `render_priority`. Rings and pie-wipes are texture frames or sprite regions — never `CanvasItem.draw_arc`/line drawing, which lost its AA feather in 4.7.

**6. Screen UI.** Score, strikes, popup numbers and the results overlay are `Control`s under one `CanvasLayer`, laid out from `ViewFit.playfield_changed(playfield, kitchen_rect)` into the strips; they never overlap `kitchen_rect`. Popup/slide animations use the 4.7 `Control` offset-transform so they do not disturb container layout; they are hand-driven each frame from `GameClock.sim_dt`/`ui_dt` (ADR-0003 §6), never by `Tween`. Every non-interactive `Control` (strip roots, labels, containers) sets `mouse_filter = MOUSE_FILTER_IGNORE` — the default `STOP` on a full-rect root would swallow every kitchen tap before `TapInput` sees it (ADR-0006); only real buttons and the open results overlay stop events.

**7. Rendering settings.** `WorldEnvironment` with `background_mode = BG_COLOR` (`letterbox_color`, data), no glow, no tonemap post-processing, MSAA off, no SSAA. 3D resolution scale is applied through `Viewport.scaling_3d_scale` to cap cost on high-DPR phones: `ViewFitMath.render_scale()` = `clamp(sqrt(render_pixel_budget / canvas_px_area), render_scale_min, render_scale_3d)` (ADR-0007 §3; `render_scale_3d` 1.0 is the ceiling, budget 1.5 Mpx, floor 0.6 — all `ViewConfig` data). Verified 2026-09-30 on 4.7.2 desktop `gl_compatibility` that the scale is applied (WebGL2 pending).

### Architecture Diagram

```
PlatformBridge ──safe_area_changed(rect_px)──► ViewFit (Node, kitchen scene)
                                                 │ px → dp via get_final_transform()⁻¹
                                                 │ ViewFitMath (RefCounted, pure):
                                                 │   playfield() → kitchen_scale() → camera_offsets()
                                                 ├──► Camera3D: size, h_offset, v_offset   (ortho, fixed pitch)
                                                 └──playfield_changed(playfield, kitchen_rect)──► HUD CanvasLayer (strips)
KitchenLayout.frame_bounds ──(once, at load)──► ViewFit
World: Sprite3D / AnimatedSprite3D (unshaded, fixed −pitch rotation, opaque-prepass alpha)
       └─ overlays: Sprite3D / Label3D (no_depth_test, render_priority bands)
```

### Key Interfaces

```gdscript
class_name ViewFitMath extends RefCounted   # pure, unit-tested without a scene
static func playfield(safe: Rect2, aspect_min: float, aspect_max: float) -> Rect2
static func kitchen_scale(playfield: Rect2, frame_size: Vector2, fill_target: float) -> float  # dp per metre
static func camera_offsets(viewport_size: Vector2, playfield: Rect2, frame_center: Vector2, scale: float) -> Vector2
static func kitchen_rect(playfield: Rect2, frame_size: Vector2, scale: float) -> Rect2

class_name ViewFit extends Node             # lives in the kitchen scene, not an autoload
signal playfield_changed(playfield: Rect2, kitchen_rect: Rect2)   # dp; emitted after the camera is updated
func get_playfield() -> Rect2
func get_kitchen_rect() -> Rect2
```

`architecture.md` currently lists `playfield_changed(rect, dp_scale)`; with 1 unit = 1 dp the `dp_scale` argument is always 1 and is replaced by `kitchen_rect`, which the HUD actually needs. TapPicker reads `tap_pick_radius` (28 dp) directly, with no scale factor.

### Implementation Guidelines
- Must set `window/stretch/mode = canvas_items`, `window/stretch/aspect = expand`, base viewport 360×640 in `project.godot`; must never rely on the 4.7 defaults implicitly.
- Must express every screen-space constant (tap radius, tap target, HUD sizes) in dp = viewport units; must never multiply by DPR or window/screen scale in gameplay or HUD code.
- ViewFit must react only to `PlatformBridge.safe_area_changed`; must never connect to `get_viewport().size_changed` or read `DisplayServer` window size itself.
- Resize must update only the camera and HUD layout, snapping in the same frame (no tween); must never touch `GameClock`, `MatchLifecycle` or entity state.
- All fitting math lives in `ViewFitMath` (pure static functions); the node only applies results.
- `camera_pitch_deg`, camera position/target, `kitchen_fill_target`, `viewport_aspect_min/max`, `letterbox_color`, `render_scale_3d` must come from validated config, never literals.
- All sprite materials must be unshaded; must never add `DirectionalLight3D`/`OmniLight3D` or enable shadow casting in MVP.
- World sprites (stations, characters, items) must stand upright with `scale.y = 1 / cos(camera_pitch_deg)`; they must never be tilted toward the camera or use billboard modes. Overlays (`no_depth_test`) use the fixed camera-facing tilt `rotation.x = −camera_pitch_deg`.
- A sprite's footprint must not overlap solid geometry: an icon on a station stands on the block top, not half inside it.
- Overlays must use `no_depth_test` + `render_priority` bands; must never rely on scene-tree order for 3D draw order.
- Must never draw rings, arcs or outlines with `CanvasItem` line primitives.
- Screen UI must live under a single `CanvasLayer` and stay outside `kitchen_rect`.
- Non-interactive `Control`s must use `MOUSE_FILTER_IGNORE`; overlay materials must be alpha-blended; `Label3D.outline_render_priority` < `render_priority`.
- `Control` offset-transform animations must be driven from `sim_dt`/`ui_dt`, never `Tween`.

## Alternatives Considered

### Alternative 1: SubViewport sized to the playfield
- **Description**: Render the kitchen into a `SubViewport` inside a `SubViewportContainer` placed at the playfield rect; letterbox is the container's surroundings.
- **Pros**: Clean isolation; camera math only needs the playfield size.
- **Cons**: An extra render target and a full-screen blit on WebGL2 every frame; tap coordinates must be remapped from screen to sub-viewport; overlays and HUD live in two coordinate systems.
- **Rejection Reason**: Pays a per-frame GPU cost on the weakest target for a problem a two-number camera offset already solves.

### Alternative 2: Letterbox through stretch aspect `keep`
- **Description**: Use `canvas_items` + `keep` at a fixed design aspect and let the engine add black bars.
- **Pros**: Zero code.
- **Cons**: Supports exactly one aspect, not a clamp range; phones between 9:20 and 9:16 would get needless bars and the ≥ 0.95 fill would fail.
- **Rejection Reason**: Cannot satisfy the Platform clamp or the Kitchen fill contract.

### Alternative 3: Base canvas 540×960 (as in the prototype)
- **Description**: Keep the prototype's base resolution; dp = 1.5 viewport units.
- **Pros**: Prototype constants carry over unchanged.
- **Cons**: Every dp value in the GDDs needs a conversion factor in TapPicker and HUD — a permanent source of off-by-1.5 bugs.
- **Rejection Reason**: One-time conversion of a few prototype constants is cheaper than a conversion factor everywhere forever.

### Alternative 4: Screen-space overlays projected into `Control`
- **Description**: Draw guest tokens, rings and cup tokens as `Control`s positioned each frame via `unproject_position`.
- **Pros**: Fixed dp text size, crisp at any zoom.
- **Cons**: Per-frame projection for every overlay; layering against world sprites (a guest walking behind the island) is lost; one-frame lag against the entity.
- **Rejection Reason**: The GDDs specify world-space billboards; legibility is handled by sizing `Label3D` for the 9:20 worst case instead.

### Alternative 5: Real-time light and shadow maps
- **Description**: A `DirectionalLight3D` with shadows casting from sprites.
- **Pros**: Matches the literal wording "тени считает 3D-движок" in game-concept.
- **Cons**: A shadow-map pass every frame on WebGL2 on weak Android; shadows from flat sprites often look wrong; contradicts the Kitchen GDD's baked lighting.
- **Rejection Reason**: Architecture Principle 5 — cost without measured need; painted blob shadows give the intended look.

## Consequences

### Positive
- One unit system (dp) for taps, HUD and the projection API — TapPicker and HUD never convert.
- The fill contract holds by construction at every aspect and is unit-testable without a scene.
- One camera and one render target: the cheapest possible frame on WebGL2.
- Overlays follow entities, scale with the kitchen and pause with game time without extra code.

### Negative
- Prototype constants in 540×960 units (e.g. `TAP_RADIUS 42`) must be converted once (÷ 1.5).
- `Label3D` text size varies with zoom; the smallest case (9:20) must be checked by eye on a phone.
- game-concept.md's wording "тени считает 3D-движок" becomes inaccurate (depth order yes, shadows no) and needs a one-line edit.
- `architecture.md` Module Ownership lists `playfield_changed(rect, dp_scale)`; it must be updated to `(playfield, kitchen_rect)`.

## Risks
- **Opaque-prepass alpha sorting on WebGL2 may show halos or wrong order** where sprites overlap. On 4.7.2 `rendering/driver/depth_prepass/disable_for_vendors` defaults to `PowerVR,Mali,Adreno,Apple` — i.e. **every target phone GPU** — so on the reference device `ALPHA_CUT_OPAQUE_PREPASS` sprites likely lose the prepass and fall back to sorted blending (inferred from source, `modules/rendering.md`; unverified on device). *Mitigation*: the spike compares both options on the reference device — (a) clear that vendor list in `project.godot` and measure cost, (b) `ALPHA_CUT_DISCARD` (hard edges) for characters and stations; pick one and record it here before Accepted. `render_priority` is irrelevant for world sprites (it applies only to `alpha_cut = DISABLED` materials — the overlays).
- **High-DPR phones render 3D at full device resolution.** *Mitigation*: `render_scale_3d` knob via `scaling_3d_scale` (Bilinear, supported in Compatibility). In Compatibility a scale < 1 adds an intermediate buffer and an upscale blit — the same cost class Alternative 1 rejected — so the spike measures blit cost against the fill-rate saving; if the measured gain on the spike phone is too small, fall back to `allow_hidpi = false`. ADR-0007 sets the value.
- **`get_final_transform()` semantics under `expand` may differ from assumption.** *Mitigation*: unit test with known stretch; on web the safe area equals the full window, so the result must equal `get_visible_rect()` — a cheap runtime assert in debug; if it fails, use `get_screen_transform()` instead.
- **Pitch or frame-bounds changes silently break the fill contract.** *Mitigation*: the fill check is a unit test over `safe_aspect ∈ {0.45, 0.5625, 0.75, 1.0}` plus the 1.778 wide case.
- **Small tap targets at 9:20.** Station sprites may project below 48 dp; the tap zone itself is the 28 dp pick radius (ADR-0006). *Mitigation*: ADR-0006 validation computes the projected spacing between interaction points at `s(0.45)`.
- **`CanvasItem` line thinning (4.7)** — avoided by rule (no line primitives).

## Spike Results (2026-09-30)

Source: `prototypes/web-spike/README.md` (session `0b7b7c05`, iPhone Safari, DPR 3).
- Verification (1) ✅ `get_final_transform()` scale 3.27 = window px / visible dp (1179 / 361); visible viewport 361×640 dp under `canvas_items`/`expand`.
- Verification (2) — first run ❌ in all three alpha modes. Cause (screenshot): not the alpha mode but the backward tilt of §4 — guests' heads sank into the counter behind them, and the price token sat on the heads. Fixed by upright + stretched sprites (§4 amended) and tokens above the head. **Re-check ✅ on iPhone: all three modes correct** — so the stock project setting stays (mobile GPUs skip the depth prepass and fall back to sorted blending, which also renders correctly); materials keep `ALPHA_CUT_OPAQUE_PREPASS`. Evidence: `production/qa/evidence/spike-2026-09-30-*`.
- Verification (3) — not decidable on iPhone: 60 fps at every `scaling_3d_scale` (0.6 / 0.78 / 1.0) — capped by the display. Needs a weak Android.
- Verification (4) ⚠️ price `Label3D` ≈ 7.7 dp at 361×640 — the player reads it, but the accessibility target is ≥ 12 dp; size the label up in the HUD spec.
- Draw calls: 65 at 57 instances, 83 at 75 (prepass sprites ≈ 1 extra call each, not 2).

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|---------------------------|
| platform-integration-telegram-mini-app.md | TR-platform-007 — explicit stretch mode/aspect | §1: `canvas_items`/`expand`, base 360×640 pinned in project settings |
| platform-integration-telegram-mini-app.md | TR-platform-008 — clamp [0.45, 1.0], letterbox, centred playfield | §2: `ViewFitMath.playfield()` implements the GDD formula verbatim |
| platform-integration-telegram-mini-app.md | TR-platform-009 — `safe_h = max(1, …)` | §2, inside `playfield()` |
| platform-integration-telegram-mini-app.md | TR-platform-010 — recompute ≤ once/frame | ViewFit recomputes only on `safe_area_changed`, which ADR-0001 debounces |
| platform-integration-telegram-mini-app.md | TR-platform-016 — aspect limits are data | `viewport_aspect_min/max` from config |
| platform-integration-telegram-mini-app.md | TR-platform-017 — resize doesn't reset match state | Implementation Guidelines: resize touches camera and HUD layout only |
| kitchen-station-layout.md | TR-layout-010 / Formulas — fill ≥ 0.95 of the binding side, uniform scale | §3: `s = fill_target × min(P.w/F_w, P.h/F_h)`, binding side = `fill_target` exactly |
| kitchen-station-layout.md | TR-layout-011 — fixed camera, zoom recomputed from `safe_aspect` | §3: fixed transform, `size`/offsets recomputed |
| kitchen-station-layout.md | TR-layout-014 — 48×48 dp tap target on 360×640 reference | §1: 1 viewport unit = 1 reference dp; hit-testing itself is ADR-0006 |
| kitchen-station-layout.md | TR-layout-016 — no shader animation or parallax, baked light | §4, §7: unshaded, no lights, painted shadows |
| hud-feedback-ui.md | TR-hud-001 — screen strips; world never enters them | §6: strips = playfield − `kitchen_rect` + letterbox |
| hud-feedback-ui.md | TR-hud-002 — world overlays | §5: `Sprite3D`/`Label3D` children with priority bands |
| hud-feedback-ui.md | TR-hud-012 — at 9:20 score and strikes stay visible | §6: strips computed at every aspect; the 9:20 strip size is a known output of `kitchen_rect` |
| hud-feedback-ui.md | TR-hud-013 — Approaching at 0.7 scale/opacity, Waiting drawn on top | §5: `render_priority` bands; scale/opacity is data |
| guest-ai-patience.md | TR-guest-023 — guest `AnimatedSprite3D`, 4 directions | §4 |
| guest-ai-patience.md | TR-guest-024 — patience ring billboard, 3 levels, removed instantly | §5: camera-facing sprite overlay, texture-based, no line drawing |
| player-control-barista-movement.md | TR-control-014 — barista `AnimatedSprite3D`, 4 directions, no blend | §4 |
| player-control-barista-movement.md | TR-control-011 — `tap_pick_radius` 28 dp, recomputed on scale change | §1: dp is the viewport unit, so no recomputation is needed |

## Performance Implications
- **CPU**: Fit math runs only on resize (a few dozen float ops). Fixed-rotation sprites avoid per-frame billboard work.
- **GPU**: One camera, one render target, unshaded materials, no shadow pass, no post-processing. Draw calls ≈ one per sprite (~60–100 expected in MVP); ceiling set by ADR-0007. `render_scale_3d` caps fill-rate on high-DPR phones.
- **Memory**: Sprite textures dominate; atlas and compression policy belong to the art pipeline and ADR-0007.
- **Load Time**: No impact beyond texture size.

## Migration Plan
Prototype → production: replace the two-branch `_fit_camera()` with `ViewFitMath`; change base 540×960 → 360×640 and divide prototype screen constants by 1.5 (`TAP_RADIUS 42 → 28`); move `CAMERA_PITCH_DEG`, `CAMERA_VIEW_WIDTH` into config (`CAMERA_VIEW_WIDTH` is replaced by `frame_bounds`). The prototype itself stays untouched as a reference.

## Validation Criteria
- Unit tests (`tests/unit/view_fit/`): `playfield()` matches all five Platform GDD examples; fill of the binding side equals `kitchen_fill_target` for `safe_aspect ∈ {0.3, 0.45, 0.5625, 0.75, 1.0, 1.778}`; `kitchen_rect` is centred in the playfield; `safe_h = 0` does not divide by zero.
- Retained screenshots in `production/qa/evidence/` at 9:20, 9:16, 3:4, 1:1 and 16:9 windows: kitchen fills the binding side, strips visible, letterbox only outside [0.45, 1.0].
- On the spike phone: sprite overlap order correct (guest vs counter, barista vs island), no alpha halos, `Label3D` price readable at 9:20.
- Rotate/resize mid-match: guests, timers and held cup unchanged; camera snaps in the same frame.

## Related
- Depends on ADR-0001 (Web build & platform shell) — `safe_area_changed` contract.
- Enables ADR-0006 (Navigation & tap picking) and ADR-0007 (Perf budgets).
- `design/gdd/platform-integration-telegram-mini-app.md` (Formulas), `design/gdd/kitchen-station-layout.md` (Formulas, Visual), `design/gdd/hud-feedback-ui.md`, `design/gdd/game-concept.md` (Visual Identity Anchor).
