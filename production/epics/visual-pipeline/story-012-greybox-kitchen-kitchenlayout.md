# Story 012: Greybox kitchen scene hooked to KitchenLayout data + budget census

> **Epic**: Visual Pipeline (Lighting, Toon Shader, Quality Tiers)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/art/art-bible.md`
**Requirement**: TR-art-001, TR-art-002, TR-art-005, TR-art-007
*(Requirement text lives in `docs/architecture/tr-registry.yaml` / art bible — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Viewport, camera fit & 2.5D presentation; ADR-0007: Performance & load budgets
**ADR Decision Summary**: The 3D environment + hybrid stations is assembled from KitchenLayout data; census and draw-call budgets are asserted on the worst-case scene incl. shadow pass.
**ADR Version**: ADR-0002 2026-09-30, ADR-0007 2026-09-30

**Engine**: Godot 4.7.2 (Compatibility / WebGL2) | **Risk**: HIGH
**Engine Notes**: Godot 4.7 is post-cutoff; check docs/engine-reference/godot/modules/rendering.md (Compatibility: depth prepass off on PowerVR/Mali/Adreno/Apple, render_priority orders transparent only, scaling_3d_scale adds an internal buffer + blit). Anything not verified there is UNVERIFIED — measure, do not assume.

**Control Manifest Rules (this layer)** *(no manifest — derived from the ADRs)*:
- Required (from ADR-0002): exactly one DirectionalLight3D; shadows only from dynamic proxies (SHADOWS_ONLY capsules); sprites use the project toon shader; overlays unshaded + disable_fog; static env = unshaded hand-painted atlas x baked vertex color, merged to <= 5 kitchen meshes (+ <= 6 scenery, Mid/High) outside the shadow pass; perspective diorama camera (ADR-0002 amendment 2026-10-01)
- Forbidden (from ADR-0002/0007): stock lit Sprite3D, Omni/Spot lights, SSAO/SSIL/SSR/SDFGI/VoxelGI, volumetric fog, runtime DOF, Compositor / screen_texture post-processing, global Environment.adjustment_* tint over overlays, MSAA, GPU particles, CanvasItem line primitives for rings
- Guardrail (from ADR-0007, effective-budget table 2026-10-01): draw calls target <= 140 / ceiling 200 incl. shadow pass; census <= 115; shadow casters <= 12; kitchen env <= 30k tris, scenery <= 20k; texture memory <= 192 MB Mid/High / 144 MB Low; .pck <= 22.0 MB; VFX pool <= 12; pre-warm <= 1.0 s; thresholds live in one constants/data file, not literals

---

## Acceptance Criteria

*From `design/art/art-bible.md` / ADR amendments of 2026-10-01, scoped to this story:*

- [ ] Greybox scene in `src/` (replaces `prototypes/tea-rush-vertical-slice/src/presentation/kitchen_view.gd` + `pixel_art.gd` drawing) builds floor, walls, perimeter counters, 2x4 island and 7 station bases from KitchenLayout data at the correct camera fit; placeholder 2D items on stations; light, proxies, blob shadows, overlays and tier config from stories 006-010 wired in
- [ ] Budget census test on the worst-case scene: renderable 3D instances <= 95, draw calls <= 180 (target <= 120) including shadow pass, shadow casters <= 12, env triangles <= 20k, thresholds read from the single constants file (18.5 -> 21.5 MB, 96 MB from ADR-0007 amendments)
- [ ] Screenshots for aspect 9:20, 9:16 and 1:1 show kitchen fill per ADR-0002 and readable tokens; retained in `production/qa/evidence/`

---

## Implementation Notes

- Port the layout/placement logic from `kitchen_view.gd`, not its pixel drawing; KitchenLayout is the data source, no positions in literals.
- Art-assets replace placeholders later; scene must not need edits beyond swapping resources.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Art-assets stories 003-009: final art
- HUD epic: HUD strips

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/Feel and UI screenshots are NOT waived (CLAUDE.md: a parse check is not a run).*

**Story Type**: Integration
**Required evidence**:
- `tests/integration/visual_pipeline/greybox_kitchen_kitchenlayout_test.gd` OR playtest doc; measured numbers in `production/qa/evidence/greybox-kitchen-kitchenlayout-evidence.md`
- Integration test: `tests/integration/visual_pipeline/greybox_kitchen_census_test.gd`; screenshots `production/qa/evidence/vp-greybox-9x20.png`, `-9x16.png`, `-1x1.png`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 006, 007, 008, 009, 010, 011
- Unlocks: Art-assets 003+; vertical-slice replacement; playable MVP
