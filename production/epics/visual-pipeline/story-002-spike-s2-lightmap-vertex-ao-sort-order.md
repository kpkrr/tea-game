# Story 002: Spike S2: vertex-color AO / LightmapGI on WebGL2 and opaque-vs-sprite sort order

> **Epic**: Visual Pipeline (Lighting, Toon Shader, Quality Tiers)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/art/art-bible.md`
**Requirement**: TR-art-001, TR-art-007
*(Requirement text lives in `docs/architecture/tr-registry.yaml` / art bible — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Viewport, camera fit & 2.5D presentation; ADR-0007: Performance & load budgets
**ADR Decision Summary**: Static env is unshaded baked vertex-color meshes (optional LightmapGI for floor/walls); alpha-blended/alpha-depth sprites must sort correctly against opaque meshes (guest behind counter).
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

- [ ] A test counter/floor GLB with baked vertex-color AO renders correctly on WebGL2 (desktop Chromium and iPhone Safari or Android Chrome); artefacts (banding, seams, sRGB/linear mismatch) listed with screenshots
- [ ] Optional LightmapGI 512 and 1024 on floor+wall: file size (MB) and visual gain vs vertex-color-only recorded; go/no-go for LightmapGI written down
- [ ] Sort order tested: guest sprite behind and in front of the counter mesh, with `ALPHA_CUT_OPAQUE_PREPASS` and with default alpha, on a device where the depth prepass is off (Adreno/Mali/Apple) and on desktop; chosen transparency mode named
- [ ] Result compared with the earlier sorting spike screenshot and the conclusion (what changes vs the code-drawn slice) stated

---

## Implementation Notes

- Prior work: `production/qa/evidence/spike-2026-09-30-mac-sorting-after-fix.png` (earlier sorting spike on the code-drawn slice; iPhone "before fix" shot also there) — reuse as the baseline for opaque-vs-sprite ordering, do not repeat that test blindly.
- Export GLB with a vertex-color attribute (`COLOR_0`); material `vertex_color_use_as_albedo`, `shading_mode = unshaded`; confirm Godot import keeps the colour channel.
- render_priority orders only transparent geometry and never reorders transparent vs opaque (rendering.md) — the test must show what actually happens, not infer it.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 006: production environment material and merged meshes
- Story 004: token exclusion from fog/tonemap

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/Feel and UI screenshots are NOT waived (CLAUDE.md: a parse check is not a run).*

**Story Type**: Integration
**Required evidence**:
- `tests/integration/visual_pipeline/spike_s2_lightmap_vertex_ao_sort_order_test.gd` OR playtest doc; measured numbers in `production/qa/evidence/spike-s2-lightmap-vertex-ao-sort-order-evidence.md`
- Retained: `production/qa/evidence/vp-spike-s2-lightmap-sorting.md` + screenshots per device; prior: `production/qa/evidence/spike-2026-09-30-mac-sorting-after-fix.png`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: Stories 006, 012; art-assets story 007 (environment)
