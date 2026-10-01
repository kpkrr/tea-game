# ADR-0002: Viewport, camera fit & 2.5D presentation

## Status
Accepted

> Accepted 2026-09-30 by the owner. Open item (not a blocker): price `Label3D` ≈ 7.7 dp vs the 12 dp accessibility target — to be settled in `/ux-design hud`.
>
> **Amended 2026-10-01 — diorama camera** (owner decision 2026-10-01 after `design/art/references/ref-01-cozy-diorama-kitchen.png`): the orthographic camera of §3 is replaced by a **perspective** camera with a narrow fixed FOV; see "Amendment 2026-10-01 — diorama camera" below. Every ortho statement in this ADR that the amendment contradicts is marked *(superseded 2026-10-01)*; where the two disagree, the amendment wins.

## Date
2026-09-30

## Last Verified
2026-10-01 (diorama-camera amendment: fit algorithm simulated numerically on the prototype kitchen geometry — pitch 52°, FOV 25/30/35°, viewports 360×640, 360×800, 640×640; engine-side claims about perspective `Camera3D` offsets/`fixed_size` in 4.7.2 are marked "проверить в 4.7.2" and are verification items V5–V8)

## Decision Makers
Yan (product owner) · godot-specialist (engine validation 2026-09-30: no blocking issues; 3 minor notes folded in) · technical-director review skipped (review_mode `lean`)

## Summary
Every Foundation and Presentation module needs one agreed answer to "where is the kitchen on screen, in what units, and how is it drawn": the stretch mode, the playfield clamp and letterbox, the orthographic camera fit that keeps the kitchen at ≥ 95 % of the playfield, the dp unit used by taps and HUD, and how 2.5D sprites and world overlays render on WebGL2. This ADR pins `canvas_items`/`expand` on a 360×640 base (1 viewport unit = 1 reference dp), fits a single fixed-pitch **perspective "diorama" camera** (fixed narrow FOV 30°, pitch 52°; only the distance along the view axis and `h_offset`/`v_offset` are computed — amendment 2026-10-01, which replaced the original orthographic camera with computed `size`), lets the letterbox show surrounding scenery or a background colour, draws world overlays as camera-facing `Sprite3D`/`Label3D` with a minimum on-screen size rule, and renders a baked, hand-painted textured environment with toon-shaded sprites and one directional light (amendments 2026-10-01).

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7.2 (GDScript, Compatibility renderer / WebGL2) |
| **Domain** | Rendering / UI |
| **Knowledge Risk** | HIGH — post-cutoff (`VERSION.md`); 4.7 changed project stretch defaults and `CanvasItem` line AA |
| **References Consulted** | `docs/engine-reference/godot/modules/rendering.md` (dated 4.6), `modules/ui.md` (4.6), `modules/web.md` (2026-09-30), `breaking-changes.md` (4.6→4.7: stretch defaults, line AA feather, `Control` offset-transform), `deprecated-apis.md`; `prototypes/kitchen-core/kitchen_core.gd` (`_fit_camera`, pitch 39.3°) as a proven starting point |
| **Post-Cutoff APIs Used** | (Diorama amendment 2026-10-01: `Camera3D` `PROJECTION_PERSPECTIVE`/`fov`/`keep_aspect`/`near`/`far`/`h_offset`/`v_offset`, `project_ray_origin/normal`, `unproject_position`, `SpriteBase3D.fixed_size`/`Label3D.fixed_size` are pre-cutoff APIs; no 4.7 entries in `breaking-changes.md`/`deprecated-apis.md`; exact behaviour of offsets and `fixed_size` under perspective — проверить в 4.7.2, Verification V5–V6.) 4.7 `Control` offset-transform (§6 popup/slide animations): `offset_transform_enabled` plus `offset_transform_position`/`_scale`/`_rotation`/`_pivot` (visual-only by default; nothing applies until enabled — `modules/ui.md`, verified 2026-09-30). Otherwise none new. Relies on 4.7 *defaults* being overridden explicitly (`window/stretch/mode`, `window/stretch/aspect`). `Camera3D` ortho `size`/`keep_aspect`/`h_offset`/`v_offset`, `Sprite3D`/`AnimatedSprite3D`/`Label3D` flags are pre-cutoff APIs |
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

**3. Camera fit (single ortho camera, whole viewport).** *(Superseded 2026-10-01 by the diorama-camera amendment: projection is now perspective and `size` no longer exists; the playfield, `kitchen_fill_target`, `kitchen_rect` and strip semantics below still hold, the formulas do not.)* The camera keeps a fixed transform (position and look target from config; pitch 39.3° in the prototype) with `projection = PROJECTION_ORTHOGONAL` and `keep_aspect = KEEP_HEIGHT`. At load, `ViewFit` projects the 8 corners of `KitchenLayout.frame_bounds` (the world AABB that must stay visible: floor, counters, station sprite tops, guest queue, till) onto the camera's right/up axes, giving a constant projected size `F = (F_w, F_h)` in metres and a projected centre `c`. On every playfield change:

```
s        = kitchen_fill_target × min(P.w / F_w, P.h / F_h)     # dp per metre; kitchen_fill_target ∈ [0.95, 1.0], default 0.96
size     = V.h / s                                             # ortho size = visible world height across the full viewport
h_offset = c.x − (P.center.x − V.w / 2) / s                    # shifts the frame centre onto the playfield centre
v_offset = c.y + (P.center.y − V.h / 2) / s                    # screen y grows downward; sign pinned by unit test
kitchen_rect = Rect2(P.center − F × s / 2, F × s)              # on-screen kitchen, dp
```

`V` is the visible viewport size, `P` the playfield, both in dp. By construction the binding side is filled to exactly `kitchen_fill_target` ≥ 0.95, satisfying the Kitchen GDD assert at every aspect; the non-binding side has more slack. The strips are `P − kitchen_rect` plus the letterbox; the HUD uses only the **top** strip (see the amendment below — side strips are never HUD). This is the prototype's `_fit_camera()` generalised from two hard-coded branches to the clamp-and-fill formula.

> **Amendment 2026-09-30 — reserved HUD strip on near-square screens (owner decision during `/ux-design hud`, "Mode C").** The HUD is **always a horizontal top row**; side strips are never used for HUD (they are just letterbox) — a side column was dropped on 2026-09-30 because the score block (≈ 128 dp wide) does not fit a 56 dp column, and PC windows are capped at 1:1 by the aspect clamp, so side columns would buy nothing. Near aspect ≈ 0.8–1.0 (tablets, near-square desktop windows) the fill rule leaves a top strip thinner than a HUD row. The owner accepted reserving a top strip there, even though the kitchen then covers < 95 % of the playfield. This is an **explicit exception** to the Kitchen GDD "≥ 95 %" assert, limited to that case. Phones from 9:20 to 9:16 are unaffected, because their top strip is already far above the threshold.
> ```
> m          = view.hud_min_strip_dp                               # 56 dp
> s0, rect0  = fit(P)                                              # the §3 formula, unchanged
> top0       = rect0.position.y − P.position.y                     # = bottom strip (kitchen centred)
> if top0 < m:                                                     # top strip cannot hold the HUD row (Mode C)
>     P_fit  = Rect2(P.position.x, P.position.y + m, P.size.x, P.size.y − m)
> else:
>     P_fit  = P
> s, kitchen_rect = fit(P_fit)                                     # s, size, h_offset, v_offset all from P_fit
> ```
> - Only the top strip is tested; side strips are ignored (Mode A = `top0 ≥ m`, HUD in the natural top strip; Mode C = reserve). There is no side-column mode.
> - The binding side of **`P_fit`** is filled to exactly `kitchen_fill_target` (≥ 0.95), so the Kitchen GDD assert holds against `P_fit`. Against the full `P`, fill drops to ≈ 0.87 at 1:1 (UX estimate, to be recomputed once `frame_bounds` is exact). The top strip is then ≥ `m` by construction.
> - `playfield_changed(playfield, kitchen_rect)` keeps its signature and still carries the **full** `P`. The HUD therefore sees a top strip ≥ `m` and lays out in its normal top-row mode; it needs no knowledge of the reserve. The camera's `h_offset`/`v_offset` centre the frame on `P_fit.center`.
> - All of this lives in `ViewFitMath` (new pure `static func fit_playfield(playfield: Rect2, frame_size: Vector2, fill_target: float, hud_min_strip: float) -> Rect2` returning `P_fit`; `kitchen_scale`/`kitchen_rect`/`camera_offsets` are then called with `P_fit`). There is no hysteresis: the choice is a pure function of `P`, recomputed on each debounced resize, and a window resized across the boundary snaps between the two fits in one frame (same as any resize).
> - **Config knob (ADR-0004 style):** `ViewConfig.hud_min_strip_dp: int = -1` (sentinel), default **56** in `view.tres`. It is a `ViewConfig` field because `ViewFit` owns the fit. The HUD reads the same field read-only for its layout modes (`design/ux/hud.md` names it `hud_min_strip_dp`). **Validator:** missing (−1) → `missing`; must satisfy `1 ≤ hud_min_strip_dp ≤ 160` (`range`; 160 = ¼ of the 640 dp minimum playfield height under `expand`, so `P_fit` never collapses). If `HudConfig` carries `hud_row_height_dp`, then `hud.hud_row_height_dp ≤ view.hud_min_strip_dp` (`invariant`, cross-system).
> - **Validation (added):** unit tests: 360×800 and 360×640 → `P_fit == P` and results identical to the unamended formula (regression); 640×640 → reserve taken, `kitchen_rect.position.y − P.position.y ≥ 56`, fill of `P_fit`'s binding side == `kitchen_fill_target`, and fill of `P` < 0.95 is accepted; 480×640 (3:4) → whichever branch the exact `frame_bounds` yields, with the **top** strip ≥ 56 in both cases; a case where a side strip ≥ 56 but the top strip < 56 must still take the reserve (side strips never count). Retained screenshot at 1:1 and one aspect just either side of the switch.

**4. 2.5D sprites.** *(Partly superseded 2026-10-01: the uniform `scale.y = 1 / cos(camera_pitch)` becomes a per-sprite `1 / cos(α)` — diorama-camera amendment, point 4; "unshaded, no lights" — lit-environment amendment.)* Stations, items, floor and counters are `Sprite3D`/textured quads; barista and guests are `AnimatedSprite3D` (4 directions, side mirrored). All are **unshaded** (`shaded = false`); there are no real-time lights and no shadow maps. Characters get a painted soft blob-shadow quad on the floor; station shadows are painted into their textures. World sprites stand **upright** (no rotation) with `scale.y = 1 / cos(camera_pitch)` to undo the camera's foreshortening, not `BILLBOARD_ENABLED` and not a backward tilt — on screen they look camera-facing, in the world they stay inside their own footprint column. *(Changed 2026-09-30 after the spike: the earlier `rotation.x = −camera_pitch` leans a 1.6 m guest ≈ 1 m backwards, into whatever stands behind it — the phone showed guests' heads cut by the counter behind them in every alpha mode.)* Overlays (§5) keep the camera-facing tilt: they have no depth test, so leaning is harmless and text stays square to the view. Characters and stations use `alpha_cut = ALPHA_CUT_OPAQUE_PREPASS` so the depth buffer orders a guest in front of the counter correctly while keeping soft painted edges. The 3D engine owns draw order (depth), not the scene tree.

**5. World overlays.** Guest order token and patience ring, cup tokens, kettle state, till fill, station labels, target outline and floor ring are `Sprite3D`/`Label3D` children of the entity they describe, with the same fixed camera-facing rotation, `no_depth_test = true` and explicit `render_priority` bands (world < Approaching overlays < Waiting overlays < held-cup tokens), so a Waiting guest's token always draws over an Approaching one (TR-hud-013). They move and scale with the kitchen for free and pause with game time because they are driven by the same simulation state. `render_priority` orders **transparent** geometry only, so overlay materials must stay alpha-blended (never alpha-cut/opaque-prepass), and every `Label3D`'s `outline_render_priority` must be below its `render_priority`. Rings and pie-wipes are texture frames or sprite regions — never `CanvasItem.draw_arc`/line drawing, which lost its AA feather in 4.7.

**6. Screen UI.** Score, strikes, popup numbers and the results overlay are `Control`s under one `CanvasLayer`, laid out from `ViewFit.playfield_changed(playfield, kitchen_rect)` into the strips; they never overlap `kitchen_rect`. Popup/slide animations use the 4.7 `Control` offset-transform so they do not disturb container layout; they are hand-driven each frame from `GameClock.sim_dt`/`ui_dt` (ADR-0003 §6), never by `Tween`. Every non-interactive `Control` (strip roots, labels, containers) sets `mouse_filter = MOUSE_FILTER_IGNORE` — the default `STOP` on a full-rect root would swallow every kitchen tap before `TapInput` sees it (ADR-0006); only real buttons and the open results overlay stop events.

**7. Rendering settings.** *(Letterbox wording superseded 2026-10-01: the letterbox may show scenery; `letterbox_color` is renamed `background_color` — diorama-camera amendment, point 6.)* `WorldEnvironment` with `background_mode = BG_COLOR` (`letterbox_color`, data), no glow, no tonemap post-processing, MSAA off, no SSAA. 3D resolution scale is applied through `Viewport.scaling_3d_scale` to cap cost on high-DPR phones: `ViewFitMath.render_scale()` = `clamp(sqrt(render_pixel_budget / canvas_px_area), render_scale_min, render_scale_3d)` (ADR-0007 §3; `render_scale_3d` 1.0 is the ceiling, budget 1.5 Mpx, floor 0.6 — all `ViewConfig` data). Verified 2026-09-30 on 4.7.2 desktop `gl_compatibility` that the scale is applied (WebGL2 pending).

> **Amendment 2026-10-01 — lit 3D environment + toon sprites (owner art direction, `design/art/art-bible.md` A1/A7, §1, §7.7; feasibility `design/art/lighting-feasibility-2026-10-01.md`).** Supersedes the "everything unshaded, no lights" parts of §4 and §7 and the matching Implementation Guideline. Camera fit, dp, upright-sprite rule, overlays (§5) and screen UI (§6) are unchanged.
> - **Environment is 3D meshes, not quads.** Floor, walls, counters, island and station **bases** are simple stylized meshes (GLB, ≤ 20 k △ total, art bible §8.4) with **light and AO baked into vertex colors**, rendered with an **unshaded** vertex-color material; optionally `LightmapGI` for floor and walls only (one 512–1024 atlas). Static meshes are merged into ≤ 3 meshes by material and are **excluded from the shadow pass** (layer mask). Stations become a hybrid: 3D base mesh + an upright outlined 2D `Sprite3D` item on top (kettle, leaf jar, lemon, cup stack) — the outline marks interactivity (art bible §3, §6).
> - **One `DirectionalLight3D`** (window key light), shadow map with one cascade, orthogonal fit, short shadow distance covering the kitchen; **only dynamic objects cast** (barista, guests, cups) — through invisible `SHADOWS_ONLY` proxy capsules, not through the sprite cards. Shadow settings per quality tier (ADR-0007 Amendment 2026-10-01): Low — light shadows off; Mid — 512, low filter; High — 1024–2048, soft filter.
> - **Character and item sprites use a custom toon spatial shader** instead of `shaded = false`: unshaded base colour × a zone tint sampled by world position (≤ 15 %), a 2-step ramp from the single light using a camera-facing pseudo-normal (not the card normal), a 1 dp rim tint on the lit side; receiving shadows via `SHADOW_ATTENUATION` in `light()` is optional and **needs verification** in Compatibility 4.7. The stock lit `Sprite3D` material is forbidden (card-with-gradient look). **Blob contact shadows stay on all tiers** under characters, cups and the till; real shadows draw on top on Mid/High. Upright placement and `scale.y = 1 / cos(pitch)` are unchanged; the `ALPHA_CUT_OPAQUE_PREPASS` depth ordering must be re-checked against opaque meshes (spike S2).
> - **Rendering settings (§7):** `WorldEnvironment` gets **tonemap** (filmic-like) and **color adjustments**, **depth fog**; **glow on High tier only**. No SSAO/SSIL/SSR/SDFGI/VoxelGI, volumetric fog, runtime DOF, Compositor or screen-texture post-processing (not available or too costly on WebGL2). "Depth of field" is a **pre-blurred background quad layer**; light shafts and vignettes are additive/alpha gradient quads. MSAA stays off.
> - **Tokens are excluded from grading** (art bible §7.7 p. 1, blocking UX rule): all §5 overlays (order tokens, patience rings, prices, cup tokens, kettle state, till fill, station tags, target outline, floor ring) use **unshaded materials with `disable_fog = true`** and must keep their hex values under the day→evening mood shift; the mood shift is driven by light energy/colour and environment material parameters, **not** by global `Environment.adjustment_*` changes that would tint overlays. If Compatibility applies tonemap to overlay sprites regardless, the tonemap must be neutral (linear) and the mood carried by materials only — decided by spike S4 (ADR-0007 Amendment).
> - **Verification (spike, before art production):** S1–S4 as listed in ADR-0007 Amendment 2026-10-01; plus peter-panning/bias of the directional shadow at kitchen scale (with the perspective camera of the next amendment, spike S5).
> - *(2026-10-01, diorama camera)* "Floor, walls, counters … light and AO baked into vertex colors … unshaded vertex-color material" now reads: **hand-painted textured** meshes (albedo atlases) **×** baked light/AO in vertex colors (optionally LightmapGI for floor/walls), still unshaded, still ≤ 3 merged kitchen meshes outside the shadow pass; scenery around the kitchen is a separate budget line (ADR-0007 amendment "diorama").
> - **GDD impact (outside this ADR):** Kitchen GDD TR-layout-016 ("no shader animation or parallax, baked light") — the "baked light" part now means baked vertex-color/lightmap for statics **plus** one real-time light for dynamics; station "painted into textures" shadows are replaced by baked AO. `game-concept.md` Visual Identity Anchor is superseded by art bible §1.

> **Amendment 2026-10-01 — diorama camera (owner decision 2026-10-01, binding; reference `design/art/references/ref-01-cozy-diorama-kitchen.png`; art detail in `design/art/art-bible.md`).** The kitchen is now seen as a cozy tea-house **diorama**: a perspective camera with a narrow FOV and a steep pitch, a hand-painted textured environment with dense periphery clutter, scenery around the kitchen that may fill the letterbox, chibi 2D toon sprites for characters (unchanged) and cartoon VFX puffs. **Supersedes** §3 (orthographic projection, `size`, the four formulas), the uniform upright stretch of §4, the letterbox wording of §7, the pitch 39.3° of the prototype and the ortho-only parts of Key Interfaces, Diagram and Validation. **Unchanged:** §1 dp units, §2 playfield clamp, the Mode C rule (now applied to the perspective `kitchen_rect`), §5 overlay bands / `no_depth_test` / alpha-blend rules, §6 screen UI, the lit-environment amendment above (except its "unshaded vertex-color only" material, now textured — see that amendment's last bullet).
>
> **1. Camera.** One `Camera3D`, `projection = PROJECTION_PERSPECTIVE`, `keep_aspect = KEEP_HEIGHT` (vertical FOV fixed; wider windows see more horizontally, which only adds letterbox), `fov = camera_fov_deg` (default **30°**, allowed 25–35°), basis fixed by `camera_pitch_deg` (default **52°**, allowed 45–60°) and `camera_yaw_deg` (default 0°), look target `camera_look_at` (world point ≈ centre of `frame_bounds`). The camera never pans, rotates or zooms during play. On each (debounced) playfield change exactly three things are recomputed: the **distance `D`** along the view axis (`position = camera_look_at − forward × D`), **`h_offset`/`v_offset`**, and `near = max(0.1, 0.5 × z_min)` (`far = camera_far_m`, data). `fov` is never changed at runtime.
>
> **2. Fit algorithm (pure `ViewFitMath`, one solve per debounced resize).** Notation: basis `(r, u, f)` from pitch/yaw (`f` = forward), look target `T`, viewport `V` and fit playfield `P_fit` in dp (Mode C rule unchanged), `k = V.h / (2·tan(fov/2))` = focal length in dp (KEEP_HEIGHT).
> ```
> project(p; D, a, b):                    # same math Camera3D applies; a = h_offset, b = v_offset
>     q = p − T ;  z = q·f + D
>     X = V.w/2 + k·(q·r − a)/z ;  Y = V.h/2 − k·(q·u − b)/z
> rect(D,a,b) = AABB of the 8 projected frame_bounds corners (dp)
> fill(D,a,b) = max(rect.w / P_fit.w, rect.h / P_fit.h)              # binding side
> a = b = 0
> repeat 3:                                                           # fixed count, no open loop
>     D = bisect(fill(D,a,b) == kitchen_fill_target, D ∈ [D_lo, D_hi], 32 steps)
>     e = P_fit.center − rect(D,a,b).center
>     a −= e.x·D/k ;  b += e.y·D/k                                    # recentre (screen y grows down)
> D = bisect(...) once more ;  kitchen_rect = rect(D,a,b) ;  depth_range = (z_min, z_max) of the corners
> ```
> `D_lo` = smallest `D` that keeps every corner ≥ 0.5 m in front of the camera; `D_hi` = 1000 m. `fill` falls monotonically with `D` for a frame fully in front of a camera aimed at it (asserted by the unit-test grid, not assumed). Cost ≈ 4 × 32 × 8 projections, only on the debounced `safe_area_changed` — the "≤ one recompute per frame" rule (TR-platform-010) holds. `kitchen_rect` is the bounding box of the projected frame (the kitchen is a trapezoid on screen — wider at the front); the fill contract, Mode C, the strips and the tap reject (ADR-0006 5a) all use this box. **Simulated on the prototype geometry** (x −4…4, y 0…1.8, z −7.5…3.8 m; pitch 52°, FOV 30°, fill 0.96): 360×640 → `D` ≈ 32.5 m, `kitchen_rect` 346×376 dp; 360×800 → `D` ≈ 39.5 m; 640×640 (Mode C) → `D` ≈ 22.3 m, 549×561 dp in a 640×584 `P_fit`; centre error < 0.01 dp after 3 passes; offsets ≤ 0.5 m. Scale is no longer uniform over the kitchen: at 360×640 a metre is ≈ 34 dp at the back wall and ≈ 42 dp at the guest row (ortho 39.3° was a uniform ≈ 43); far/near ratio 0.82 (0.85 at 9:20, 0.75 at 1:1).
>
> **Why `h_offset`/`v_offset` (not moving the look target).** In Godot both offsets translate the camera along its own right/up axes inside `get_camera_transform()`, which `unproject_position` and `project_ray_origin/normal` also use (проверить в 4.7.2 — Verification V5), so geometrically they are the same as moving `T` along `r`/`u`. Keeping them as separate fields leaves the authored `T`/pitch/yaw untouched, keeps the §3 output shape (`D` replaces `size`, offsets stay), and lets the node write only `position` + two floats. The translation is not a lens shift: it moves the viewpoint by ≤ 0.5 m at `D` ≥ 22 m (< 1.3°), which is invisible, and the fixed 3-pass solve absorbs the depth-dependent part. Rejected: an off-axis lens shift (`PROJECTION_FRUSTUM` + `frustum_offset`) would give an exact 2D shift and a 1-D solve, but it departs from the owner-named `fov` model and its `keep_aspect`/offset semantics in 4.7 are unverified — it is the fallback if the 3-pass solve ever fails its unit test.
>
> **3. Depth-dependent settings, recomputed with the fit (not per frame).** `D` varies ≈ 22–40 m across the aspect range, so anything measured from the camera must follow it. `ViewFit` exposes `get_depth_range() -> Vector2` (z_min, z_max of `frame_bounds`) and `get_camera_position() -> Vector3`; consumers update in their `playfield_changed` handler: `DirectionalLight3D.directional_shadow_max_distance = z_max + 2 m` (the shadow distance is measured from the camera; the old "short distance" assumed ortho), depth-fog begin/end as offsets from z_min/z_max (otherwise fog would differ per device), `near` (above). The upright-stretch values of point 4 for static sprites are refreshed in the same handler.
>
> **4. Upright sprites under perspective.** The uniform `scale.y = 1 / cos(camera_pitch_deg)` of §4 is replaced by a **per-sprite** `scale.y = 1 / cos(α)`, `α` = elevation angle of the ray from the camera to the sprite's base pivot: `ViewFitMath.upright_stretch(camera_pos: Vector3, pivot: Vector3) -> float`. With a single pitch-based factor the apparent height/width of a card would be off by −16 % at the guest row to +17 % at the back wall (±25 % at 1:1; simulated). Static sprites (station items, till, trash) get it once per fit; moving characters (barista, ≤ 4 guests) and carried cups get it each frame in their view scripts (≤ 10 calls of one normalize + one division). Yaw is not compensated (horizontal half-FOV ≤ ~9° on phones, cos ≥ 0.99). Upright placement, the "no lean / no billboard" rule and `ALPHA_CUT_OPAQUE_PREPASS` are unchanged. Overlays keep the fixed `rotation.x = −camera_pitch_deg` tilt: that plane is parallel to the image plane, which a perspective projection draws undistorted (uniform scale `k / z`), so overlays need no stretch. **Art impact (art-director):** 2D character and item art is painted for the 52° view (it was 39.3°).
>
> **5. World overlays — minimum on-screen size.** World overlays stay **world-sized** (default; they shrink slightly with depth, which reads as part of the diorama, and still scale with the kitchen across aspects). Rule: each overlay type's world size is authored so that, at the **farthest anchor it can occupy** and at the worst aspect of the grid {0.45, 0.5625, 0.75, 1.0}, its glyphs meet the HUD minimums (text ≥ 14 dp, price digits ≥ 12 dp, icons per `design/ux/hud.md`). The single measuring function is `ViewFitMath.dp_per_metre(fit, pivot) -> float` (= `k / z` for a segment parallel to the image plane). Farthest anchors: guest order token, patience ring and price — queue slots and the approach path (front of the kitchen, ≈ 42 dp/m at 360×640, ortho was 43 → the ×1.55 price estimate of ≈ 12 dp holds within −3 %); station tags and kettle state — their own static anchor (back wall ≈ 34 dp/m → ≈ 20 % smaller than under ortho, re-size them); held-cup token and target outline / floor ring — the farthest barista work point. The check is an automated test in view-fit story 006, sizes are owned by the HUD epic. `fixed_size = true` (constant screen size regardless of depth; semantics under perspective — проверить в 4.7.2, Verification V6) is **not** the default: under `KEEP_HEIGHT` a fixed-size overlay scales with `V.h` (1.25× larger at 9:20 than at 9:16 while the kitchen is not) and loses the depth cue. It is allowed per overlay type only if the size rule cannot be met without breaking the HUD overlap limit (HUD AC 8: ≤ 10 % tag overlap); the check then uses its `V.h`-dependent size.
>
> **6. Tap targets.** The 28 dp screen-space pick radius (ADR-0006) is unchanged; anchors are projected with the perspective camera. Simulated anchor spacing at 360×640: back-wall stations 86 dp, side stations 70 dp, guests 68 dp, island slots 36 dp across and **27 dp along depth** — the depth spacing of the island slots was the same ≈ 27 dp under the ortho 39.3° camera (the steeper pitch offsets the perspective shrink), so this is a pre-existing gap against the 48×48 dp rule (TR-layout-014), not a regression. View-fit story 006 reports per-target effective zones with the perspective projection; if the island slots fail Kitchen AC 9 the fix is layout (slot pitch) or a hit-zone rule — escalated to game-designer, not solved by the camera.
>
> **7. Letterbox and surroundings.** The camera always renders the full viewport, so outside `P` (side letterbox on wide windows, strips) the 3D scene simply continues: the art may place **scenery** there (water, cliffs, lanterns, clutter) — "letterbox is just background" now means "scenery or `background_color`". Rules: (i) scenery never enters `frame_bounds` and never stands between the camera and `frame_bounds` (the frustum over `kitchen_rect` stays occluder-free); periphery clutter inside the kitchen walls counts as kitchen art; (ii) scenery covers the viewport up to `scenery_cover_aspect` (2.4, 21:9 desktop) at the largest `D`; beyond that `WorldEnvironment` `BG_COLOR` (`background_color`, renamed from `letterbox_color`) shows; (iii) taps outside `kitchen_rect` stay rejected (ADR-0006 5a) and HUD legibility over scenery is the HUD panels' job; (iv) scenery is **Mid/High only** — the Low tier renders `background_color` (ADR-0007 diorama amendment); (v) scenery water/cloth may use one cheap UV-scroll material on Mid/High; shader animation inside `frame_bounds` stays forbidden (TR-layout-016).
>
> **8. Tilt-shift (optional, High tier only, spike-gated).** Default: **baked** — scenery outside the kitchen uses pre-blurred textures (the existing fake-DOF rule), allowed on every tier, no spike. A **runtime** screen-space tilt-shift blur stays forbidden (ADR-0007: no runtime DOF / screen-texture post-processing) **unless** spike S5 (visual-pipeline story 013) shows on a High-tier device that it costs ≤ 1.0 ms/frame and its mask never touches `kitchen_rect`, overlays or HUD; then it may be enabled on High only, by a one-line amendment here and in ADR-0007.
>
> **9. Config (`ViewConfig`, ADR-0004 sentinels; validator rules ship with the fields).** New: `camera_fov_deg` (30.0; 25 ≤ x ≤ 35), `camera_yaw_deg` (0.0; −30 ≤ x ≤ 30), `camera_far_m` (150.0; ≥ 60), `scenery_cover_aspect` (2.4; 1.0 ≤ x ≤ 3.0). Changed: `camera_pitch_deg` 39.3 → **52.0** (45 ≤ x ≤ 60), `letterbox_color` → **`background_color`**. Kept: `camera_look_at`, `frame_bounds`, `kitchen_fill_target`, `playfield_min_fill`, `viewport_aspect_min/max`, `hud_min_strip_dp`, `render_scale_3d`, `render_pixel_budget`, `render_scale_min`. Removed (ortho-only or now derived): `camera_position` (derived from `D`), ortho `size` (never a key), prototype `CAMERA_VIEW_WIDTH`.
>
> **10. Interfaces (replace `kitchen_scale` / `camera_offsets` / `kitchen_rect` of Key Interfaces).**
> ```gdscript
> class CameraFit extends RefCounted:     # value object returned by the solve
>     var distance: float; var h_offset: float; var v_offset: float; var near: float
>     var kitchen_rect: Rect2; var depth_range: Vector2
> static func camera_basis(pitch_deg: float, yaw_deg: float) -> Basis
> static func solve_camera(viewport_size: Vector2, playfield_fit: Rect2, frame_corners: PackedVector3Array, look_at: Vector3, basis: Basis, fov_deg: float, fill_target: float) -> CameraFit
> static func project(point: Vector3, fit: CameraFit, look_at: Vector3, basis: Basis, fov_deg: float, viewport_size: Vector2) -> Vector2
> static func fit_playfield(playfield: Rect2, kitchen_rect_full: Rect2, hud_min_strip: float) -> Rect2   # Mode C test uses the P-solve's kitchen_rect
> static func upright_stretch(camera_pos: Vector3, pivot: Vector3) -> float
> static func dp_per_metre(fit: CameraFit, look_at: Vector3, basis: Basis, fov_deg: float, viewport_size: Vector2, pivot: Vector3) -> float
> ```
> `ViewFit` keeps `playfield_changed(playfield, kitchen_rect)` and its getters, and adds `get_depth_range()` and `get_camera_position()`.
>
> **11. Validation (adds to / replaces the ortho items).** Unit: fill of the binding side of `P_fit` = `kitchen_fill_target` ± 1e-3 and `kitchen_rect` centre within 0.5 dp of `P_fit.center` for `safe_aspect` ∈ {0.45, 0.5, 0.5625, 0.6, 0.75, 0.8, 0.9, 1.0} and the 1.778 wide case, for FOV 25/30/35 and pitch 45/52/60; all 8 corners in front of `near`; Mode C regression cases of the 2026-09-30 amendment re-run with the new solve; `upright_stretch` on the optical axis = 1/cos(pitch) (1.624 at 52°); `dp_per_metre` = `k / z`. Integration (V5): `ViewFitMath.project` equals `Camera3D.unproject_position` within 0.5 dp for the 8 corners and the pick anchors on a real `Camera3D` with the solved `position`/offsets in a `SubViewport` at 360×640, 360×800, 640×640. Screenshots: the §Validation set re-taken with the perspective camera, plus one wide 16:9 window showing scenery in the letterbox (Mid/High) and `background_color` (Low).
>
> **12. Verification Required (added).** (V5) `h_offset`/`v_offset` under `PROJECTION_PERSPECTIVE` are included in `unproject_position` and `project_ray_origin/normal` in 4.7.2 — проверить в 4.7.2 (the V5 integration test). (V6) `fixed_size` semantics on `Sprite3D`/`Label3D` under perspective — only if any overlay opts in. (V7) Directional shadow with `directional_shadow_max_distance` ≈ 35–46 m from a narrow-FOV camera: texel density and peter-panning on Mid (spike S1/S5). (V8) Floor/wall texture sharpness at the oblique 52° view: mipmaps + anisotropic filtering (`TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC`, needs `EXT_texture_filter_anisotropic` in WebGL2 — проверить в 4.7.2) vs plain trilinear (spike S5).
>
> **Alternatives considered for this amendment.** (a) *Keep ortho, raise pitch* — loses the diorama depth the owner chose; rejected by the owner decision. (b) *Fixed camera position, solve FOV per aspect* — identical composition on every screen and fixed fog/shadow distances, but needs FOV ≈ 19–37° across 1:1…9:20, outside the owner's 25–35° range; rejected, revisit only if the per-aspect perspective change (far/near 0.75–0.85) is judged a problem in playtest. (c) *Lens shift via `PROJECTION_FRUSTUM`* — see point 2, fallback only. (d) *`fixed_size` overlays everywhere* — see point 5.

### Architecture Diagram

```
PlatformBridge ──safe_area_changed(rect_px)──► ViewFit (Node, kitchen scene)
                                                 │ px → dp via get_final_transform()⁻¹
                                                 │ ViewFitMath (RefCounted, pure):
                                                 │   playfield() → fit_playfield() → solve_camera()   (amended 2026-10-01)
                                                 ├──► Camera3D: position (distance D along the view axis), h_offset, v_offset, near
                                                 │      (perspective, fixed fov 30° / pitch 52° / yaw; was: ortho size)
                                                 ├──► get_depth_range() → shadow max distance, depth fog, static upright stretch
                                                 └──playfield_changed(playfield, kitchen_rect)──► HUD CanvasLayer (strips)
KitchenLayout.frame_bounds ──(once, at load)──► ViewFit
World: Sprite3D / AnimatedSprite3D (upright, per-sprite scale.y = 1/cos α, toon shader, opaque-prepass alpha)
       scenery outside frame_bounds (Mid/High) — may fill letterbox; else background_color
       └─ overlays: Sprite3D / Label3D (no_depth_test, render_priority bands)
```

### Key Interfaces

```gdscript
class_name ViewFitMath extends RefCounted   # pure, unit-tested without a scene
static func playfield(safe: Rect2, aspect_min: float, aspect_max: float) -> Rect2
# kitchen_scale / camera_offsets / kitchen_rect (ortho) — superseded 2026-10-01 by solve_camera() & co.,
# see "Amendment 2026-10-01 — diorama camera", point 10
static func solve_camera(viewport_size: Vector2, playfield_fit: Rect2, frame_corners: PackedVector3Array, look_at: Vector3, basis: Basis, fov_deg: float, fill_target: float) -> CameraFit
static func upright_stretch(camera_pos: Vector3, pivot: Vector3) -> float
static func dp_per_metre(fit: CameraFit, look_at: Vector3, basis: Basis, fov_deg: float, viewport_size: Vector2, pivot: Vector3) -> float

class_name ViewFit extends Node             # lives in the kitchen scene, not an autoload
signal playfield_changed(playfield: Rect2, kitchen_rect: Rect2)   # dp; emitted after the camera is updated
func get_playfield() -> Rect2
func get_kitchen_rect() -> Rect2
func get_depth_range() -> Vector2        # added 2026-10-01: z_min, z_max of frame_bounds from the camera
func get_camera_position() -> Vector3    # added 2026-10-01: for upright_stretch of moving sprites
```

`architecture.md` currently lists `playfield_changed(rect, dp_scale)`; with 1 unit = 1 dp the `dp_scale` argument is always 1 and is replaced by `kitchen_rect`, which the HUD actually needs. TapPicker reads `tap_pick_radius` (28 dp) directly, with no scale factor.

### Implementation Guidelines
- Must set `window/stretch/mode = canvas_items`, `window/stretch/aspect = expand`, base viewport 360×640 in `project.godot`; must never rely on the 4.7 defaults implicitly.
- Must express every screen-space constant (tap radius, tap target, HUD sizes) in dp = viewport units; must never multiply by DPR or window/screen scale in gameplay or HUD code.
- ViewFit must react only to `PlatformBridge.safe_area_changed`; must never connect to `get_viewport().size_changed` or read `DisplayServer` window size itself.
- Resize must update only the camera and HUD layout, snapping in the same frame (no tween); must never touch `GameClock`, `MatchLifecycle` or entity state.
- All fitting math lives in `ViewFitMath` (pure static functions); the node only applies results.
- `camera_fov_deg`, `camera_pitch_deg`, `camera_yaw_deg`, `camera_look_at`, `camera_far_m`, `kitchen_fill_target`, `viewport_aspect_min/max`, `background_color` (was `letterbox_color`), `scenery_cover_aspect`, `render_scale_3d` must come from validated config, never literals. *(Amended 2026-10-01: camera position is derived from the solved distance, not configured.)*
- *(2026-10-01)* Camera is `PROJECTION_PERSPECTIVE`, `KEEP_HEIGHT`; ViewFit writes only `position` (along −forward from `camera_look_at`), `h_offset`, `v_offset`, `near`; must never change `fov`, pitch or yaw at runtime and never tween any of them.
- *(2026-10-01)* Scenery must never enter `frame_bounds` or the frustum over `kitchen_rect`; shader animation is allowed only on scenery outside `frame_bounds`, Mid/High.
- ~~All sprite materials must be unshaded; must never add `DirectionalLight3D`/`OmniLight3D` or enable shadow casting in MVP.~~ *(Replaced 2026-10-01 — Amendment above.)* Exactly one `DirectionalLight3D`; shadows cast only by dynamic proxies; no Omni/Spot lights. Character/item sprites use the project toon shader (never the stock lit `Sprite3D` material); world overlays stay unshaded with fog disabled and are never tinted by grading; static environment is unshaded vertex-color (baked).
- World sprites (stations, characters, items) must stand upright with `scale.y = ViewFitMath.upright_stretch(camera_pos, pivot)` (= `1 / cos(α)` per sprite; amended 2026-10-01 — was `1 / cos(camera_pitch_deg)`); they must never be tilted toward the camera or use billboard modes. Overlays (`no_depth_test`) use the fixed camera-facing tilt `rotation.x = −camera_pitch_deg`.
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
- One camera and one render target: the cheapest possible frame on WebGL2 (perspective projection costs the same as ortho; scenery adds draw calls — ADR-0007 diorama amendment).
- Overlays follow entities, scale with the kitchen and pause with game time without extra code.

### Negative
- Prototype constants in 540×960 units (e.g. `TAP_RADIUS 42`) must be converted once (÷ 1.5).
- `Label3D` text size varies with zoom; the smallest case (9:20) must be checked by eye on a phone. *(2026-10-01: and with depth — the minimum-size rule of the diorama amendment, point 5.)*
- *(2026-10-01)* Perspective makes the far side ≈ 18 % smaller than the near side at 9:16 and the ratio varies with aspect (0.75 at 1:1 … 0.85 at 9:20); shadow distance, fog and upright stretch become fit outputs instead of constants.
- game-concept.md's wording "тени считает 3D-движок" becomes inaccurate (depth order yes, shadows no) and needs a one-line edit.
- `architecture.md` Module Ownership lists `playfield_changed(rect, dp_scale)`; it must be updated to `(playfield, kitchen_rect)`.

## Risks
- **Opaque-prepass alpha sorting on WebGL2 may show halos or wrong order** where sprites overlap. On 4.7.2 `rendering/driver/depth_prepass/disable_for_vendors` defaults to `PowerVR,Mali,Adreno,Apple` — i.e. **every target phone GPU** — so on the reference device `ALPHA_CUT_OPAQUE_PREPASS` sprites likely lose the prepass and fall back to sorted blending (inferred from source, `modules/rendering.md`; unverified on device). *Mitigation*: the spike compares both options on the reference device — (a) clear that vendor list in `project.godot` and measure cost, (b) `ALPHA_CUT_DISCARD` (hard edges) for characters and stations; pick one and record it here before Accepted. `render_priority` is irrelevant for world sprites (it applies only to `alpha_cut = DISABLED` materials — the overlays).
- **High-DPR phones render 3D at full device resolution.** *Mitigation*: `render_scale_3d` knob via `scaling_3d_scale` (Bilinear, supported in Compatibility). In Compatibility a scale < 1 adds an intermediate buffer and an upscale blit — the same cost class Alternative 1 rejected — so the spike measures blit cost against the fill-rate saving; if the measured gain on the spike phone is too small, fall back to `allow_hidpi = false`. ADR-0007 sets the value.
- **`get_final_transform()` semantics under `expand` may differ from assumption.** *Mitigation*: unit test with known stretch; on web the safe area equals the full window, so the result must equal `get_visible_rect()` — a cheap runtime assert in debug; if it fails, use `get_screen_transform()` instead.
- **Pitch or frame-bounds changes silently break the fill contract.** *Mitigation*: the fill check is a unit test over `safe_aspect ∈ {0.45, 0.5625, 0.75, 1.0}` plus the 1.778 wide case. *(2026-10-01: extended to FOV 25/30/35 × pitch 45/52/60 for the perspective solve.)*
- **(2026-10-01) Perspective solve or offsets do not match the engine.** If `h_offset`/`v_offset` are not applied the way `ViewFitMath.project` assumes, `kitchen_rect` and every tap anchor drift. *Mitigation*: V5 integration test compares `project` with `Camera3D.unproject_position`; fallback: write the offset into `position` (moving the look target — geometrically identical) or the `PROJECTION_FRUSTUM` lens shift.
- **(2026-10-01) Far-side legibility and tap spacing.** Back-wall overlays are ≈ 20 % smaller than under ortho; island-slot depth spacing stays ≈ 27 dp (< 48 dp, pre-existing). *Mitigation*: minimum-size rule + automated check (view-fit story 006); layout escalation to game-designer if Kitchen AC 9 fails.
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
| kitchen-station-layout.md | TR-layout-011 — fixed perspective diorama camera, distance recomputed from `safe_aspect` (revised 2026-10-01) | Diorama amendment 1–2: fixed FOV/pitch/yaw/look target; distance `D`, `h_offset`/`v_offset`, `near` recomputed (was §3 ortho `size`) |
| kitchen-station-layout.md | TR-layout-014 — 48×48 dp tap target on 360×640 reference | §1: 1 viewport unit = 1 reference dp; hit-testing itself is ADR-0006 |
| kitchen-station-layout.md | TR-layout-016 — hand-painted textured env with baked light/AO, no shader animation in the kitchen (revised 2026-10-01) | Lit-environment amendment + diorama amendment 7 (scenery animation only outside `frame_bounds`) |
| art-bible.md | TR-art-009 — perspective diorama camera, per-sprite upright stretch, overlay minimum size | Diorama amendment 1–5 |
| hud-feedback-ui.md | TR-hud-001 — screen strips; world never enters them | §6: strips = playfield − `kitchen_rect` + letterbox |
| hud-feedback-ui.md | TR-hud-002 — world overlays | §5: `Sprite3D`/`Label3D` children with priority bands |
| hud-feedback-ui.md | TR-hud-012 — at 9:20 score and strikes stay visible | §6: strips computed at every aspect; the 9:20 strip size is a known output of `kitchen_rect` |
| hud-feedback-ui.md | TR-hud-013 — Approaching at 0.7 scale/opacity, Waiting drawn on top | §5: `render_priority` bands; scale/opacity is data |
| guest-ai-patience.md | TR-guest-023 — guest `AnimatedSprite3D`, 4 directions | §4 |
| guest-ai-patience.md | TR-guest-024 — patience ring billboard, 3 levels, removed instantly | §5: camera-facing sprite overlay, texture-based, no line drawing |
| player-control-barista-movement.md | TR-control-014 — barista `AnimatedSprite3D`, 4 directions, no blend | §4 |
| player-control-barista-movement.md | TR-control-011 — `tap_pick_radius` 28 dp, recomputed on scale change | §1: dp is the viewport unit, so no recomputation is needed |

## Performance Implications
- **CPU**: Fit math runs only on resize (2026-10-01: ≈ 1 000 point projections for the perspective solve, still only on the debounced resize). Fixed-rotation sprites avoid per-frame billboard work; moving characters add ≤ 10 `upright_stretch` calls per frame (presentation line of ADR-0007).
- **GPU**: One camera, one render target, unshaded materials, no shadow pass, no post-processing. Draw calls ≈ one per sprite (~60–100 expected in MVP); ceiling set by ADR-0007. `render_scale_3d` caps fill-rate on high-DPR phones.
- **Memory**: Sprite textures dominate; atlas and compression policy belong to the art pipeline and ADR-0007.
- **Load Time**: No impact beyond texture size.

## Migration Plan
Prototype → production: replace the two-branch `_fit_camera()` with `ViewFitMath`; change base 540×960 → 360×640 and divide prototype screen constants by 1.5 (`TAP_RADIUS 42 → 28`); move `CAMERA_PITCH_DEG`, `CAMERA_VIEW_WIDTH` into config (`CAMERA_VIEW_WIDTH` is replaced by `frame_bounds`). The prototype itself stays untouched as a reference.

*(2026-10-01, diorama camera)* The vertical slice's `view_fit_math.gd` (ortho `project_frame`/`fit`) is **not** ported as is: `project_frame` survives only as the source of the 8 `frame_bounds` corners; `fit()` is replaced by `solve_camera()`. `CAMERA_PITCH_DEG` 39.3 → `camera_pitch_deg` 52.0; new `camera_fov_deg` 30. Slice test constants for 360×640/360×800 (ortho) are invalid; expected values for the new tests are derived independently (closed-form projection of the corners at the solved `D`), not by re-running the solver. Doc syncs done with this amendment: ADR-0006 (perspective `TapProjector`), ADR-0007 (textures, scenery, VFX, tilt-shift), `architecture.md` (ViewFit row), `tr-registry.yaml` (TR-layout-011, -016, TR-art-001, -007; new TR-art-009…011), Kitchen GDD camera lines, view-fit / visual-pipeline / kitchen-layout / barista-control stories. Outside this ADR's owner: `design/art/art-bible.md` (art-director) and `production/epics/art-assets/` (character art painted for 52°).

## Validation Criteria
- *(2026-10-01: the fill/centre items below are re-stated for the perspective solve in the diorama amendment, point 11.)* Unit tests (`tests/unit/view_fit/`): `playfield()` matches all five Platform GDD examples; fill of the binding side equals `kitchen_fill_target` for `safe_aspect ∈ {0.3, 0.45, 0.5625, 0.75, 1.0, 1.778}`; `kitchen_rect` is centred in the playfield; `safe_h = 0` does not divide by zero.
- Retained screenshots in `production/qa/evidence/` at 9:20, 9:16, 3:4, 1:1 and 16:9 windows: kitchen fills the binding side, strips visible, letterbox only outside [0.45, 1.0].
- On the spike phone: sprite overlap order correct (guest vs counter, barista vs island), no alpha halos, `Label3D` price readable at 9:20.
- Rotate/resize mid-match: guests, timers and held cup unchanged; camera snaps in the same frame.

## Related
- Depends on ADR-0001 (Web build & platform shell) — `safe_area_changed` contract.
- Enables ADR-0006 (Navigation & tap picking) and ADR-0007 (Perf budgets).
- `design/gdd/platform-integration-telegram-mini-app.md` (Formulas), `design/gdd/kitchen-station-layout.md` (Formulas, Visual), `design/gdd/hud-feedback-ui.md`, `design/gdd/game-concept.md` (Visual Identity Anchor).
