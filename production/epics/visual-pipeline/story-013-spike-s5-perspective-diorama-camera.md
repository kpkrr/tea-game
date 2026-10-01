# Story 013: Spike S5: perspective diorama camera — fit vs Camera3D, sprite stretch, overlay size, anisotropy, scenery/VFX cost, tilt-shift

> **Epic**: Visual Pipeline (Lighting, Toon Shader, Quality Tiers)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: 2026-10-01

## Context

**GDD**: `design/art/art-bible.md`, `design/gdd/kitchen-station-layout.md`
**Requirement**: TR-art-009, TR-art-011, TR-art-007, TR-layout-011
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Viewport, camera fit & 2.5D presentation (Amendment 2026-10-01 "diorama camera"); ADR-0007: Performance & load budgets (Amendment 2026-10-01 "diorama")
**ADR Decision Summary**: Owner decision 2026-10-01: perspective camera, FOV 30° (25–35), pitch 52°, fixed yaw/look target; distance and `h_offset`/`v_offset` solved per aspect; per-sprite upright stretch `1/cos α`; world overlays world-sized with a minimum on-screen size at their farthest anchor; scenery in the letterbox on Mid/High only; runtime tilt-shift forbidden unless this spike proves ≤ 1.0 ms on High.
**ADR Version**: ADR-0002 2026-10-01, ADR-0007 2026-10-01

**Engine**: Godot 4.7.2 (Compatibility / WebGL2) | **Risk**: HIGH
**Engine Notes**: Godot 4.7 is post-cutoff; `docs/engine-reference/godot/` has no entries on perspective `Camera3D` offsets, `fixed_size` or anisotropic filtering in Compatibility — everything here is проверить в 4.7.2 (ADR-0002 V5–V8). Measure, do not assume.

**Control Manifest Rules (this layer)** *(no manifest — derived from the ADRs)*:
- Required (from ADR-0002): exactly one DirectionalLight3D; shadows only from dynamic proxies (SHADOWS_ONLY capsules); sprites use the project toon shader; overlays unshaded + disable_fog; static env = unshaded hand-painted atlas x baked vertex color, merged to <= 5 kitchen meshes (+ <= 6 scenery, Mid/High) outside the shadow pass; perspective diorama camera (ADR-0002 amendment 2026-10-01)
- Forbidden (from ADR-0002/0007): stock lit Sprite3D, Omni/Spot lights, SSAO/SSIL/SSR/SDFGI/VoxelGI, volumetric fog, runtime DOF, Compositor / screen_texture post-processing, global Environment.adjustment_* tint over overlays, MSAA, GPU particles, CanvasItem line primitives for rings
- Guardrail (from ADR-0007, effective-budget table 2026-10-01): draw calls target <= 140 / ceiling 200 incl. shadow pass; census <= 115; shadow casters <= 12; kitchen env <= 30k tris, scenery <= 20k; texture memory <= 192 MB Mid/High / 144 MB Low; .pck <= 22.0 MB; VFX pool <= 12; pre-warm <= 1.0 s; thresholds live in one constants/data file, not literals

---

## Acceptance Criteria

- [ ] Throwaway scene `prototypes/art-spike/` (extends S1's scene): prototype kitchen geometry as greybox, perspective `Camera3D` placed by a draft `solve_camera` (ADR-0002 diorama amendment, point 2); at 360×640, 360×800, 640×640 the 8 `frame_bounds` corners and all pick anchors projected by the draft math match `Camera3D.unproject_position` within 0.5 dp (V5) — or the mismatch and the chosen fallback (offset via `position` / `PROJECTION_FRUSTUM`) are recorded
- [ ] Screenshot: placeholder character cards at the guest row and at the back wall with (a) uniform `1/cos(pitch)` and (b) per-sprite `1/cos α` stretch — the visual verdict confirms (b); FOV 25 / 30 / 35 shown side by side for the owner
- [ ] Overlay size: a station tag at the back wall and a price token at the guest row measured in dp on the 360×640 screenshot against 14 / 12 dp; `fixed_size` tried on one overlay and its behaviour under perspective noted (V6)
- [ ] Floor texture at 52°: trilinear vs anisotropic (if exposed in WebGL2) screenshots; verdict for story 006 (V8)
- [ ] GPU cost on a Mid device (or NOT MEASURED + reason): placeholder scenery (≤ 6 meshes, 2 atlases) + 12 alpha VFX quads on vs off — ms/frame and draw calls vs ADR-0007 (scenery + VFX ≤ 2 ms Mid; draw calls ≤ 200)
- [ ] Optional: runtime tilt-shift (screen-texture blur masked outside `kitchen_rect`) on a High-tier device — ms/frame; go only if ≤ 1.0 ms and the mask never touches `kitchen_rect`, overlays or HUD; otherwise the baked variant is confirmed

---

## Implementation Notes

- Throwaway code outside `src/`; the production solve is view-fit story 003, the node story 005.
- Reuse S1's spike probe for timings; device numbers need a web export.
- The FOV comparison is evidence for the owner, not a decision by the spike — the default stays 30° unless the owner changes `camera_fov_deg`.

---

## Out of Scope

- View-fit stories 003/005/006: production fit, node, automated size check
- Story 014: production VFX pool; art-assets: final scenery/VFX art

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Numbers + verdicts in `production/qa/evidence/spike-s5-perspective-diorama-camera-evidence.md`
- Retained screenshots in `production/qa/evidence/` (stretch a/b, FOV 25/30/35, overlay sizes, floor filtering, tilt-shift if tried)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (S1 scene and probe) — may run in parallel with it
- Unlocks: Stories 006, 007, 012, 014; view-fit story 003 (confirms the solve against the engine); art-assets pilot (art painted for 52°)
