# Story 001: Spike S1: shadow map + proxy casters + toon shader cost

> **Epic**: Visual Pipeline (Lighting, Toon Shader, Quality Tiers)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/art/art-bible.md`
**Requirement**: TR-art-002, TR-art-003, TR-art-007
*(Requirement text lives in `docs/architecture/tr-registry.yaml` / art bible — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: Performance & load budgets; ADR-0002: Viewport, camera fit & 2.5D presentation
**ADR Decision Summary**: Budgets raised for lit art; one DirectionalLight3D with shadows from dynamic proxies only; toon sprite shader. S1 must prove the ms/frame cost before art production.
**ADR Version**: ADR-0007 2026-09-30, ADR-0002 2026-09-30

**Engine**: Godot 4.7.2 (Compatibility / WebGL2) | **Risk**: HIGH
**Engine Notes**: Godot 4.7 is post-cutoff; check docs/engine-reference/godot/modules/rendering.md (Compatibility: depth prepass off on PowerVR/Mali/Adreno/Apple, render_priority orders transparent only, scaling_3d_scale adds an internal buffer + blit). Anything not verified there is UNVERIFIED — measure, do not assume.

**Control Manifest Rules (this layer)** *(no manifest — derived from the ADRs)*:
- Required (from ADR-0002): exactly one DirectionalLight3D; shadows only from dynamic proxies (SHADOWS_ONLY capsules); sprites use the project toon shader; overlays unshaded + disable_fog; static env = unshaded hand-painted atlas x baked vertex color, merged to <= 5 kitchen meshes (+ <= 6 scenery, Mid/High) outside the shadow pass; perspective diorama camera (ADR-0002 amendment 2026-10-01)
- Forbidden (from ADR-0002/0007): stock lit Sprite3D, Omni/Spot lights, SSAO/SSIL/SSR/SDFGI/VoxelGI, volumetric fog, runtime DOF, Compositor / screen_texture post-processing, global Environment.adjustment_* tint over overlays, MSAA, GPU particles, CanvasItem line primitives for rings
- Guardrail (from ADR-0007, effective-budget table 2026-10-01): draw calls target <= 140 / ceiling 200 incl. shadow pass; census <= 115; shadow casters <= 12; kitchen env <= 30k tris, scenery <= 20k; texture memory <= 192 MB Mid/High / 144 MB Low; .pck <= 22.0 MB; VFX pool <= 12; pre-warm <= 1.0 s; thresholds live in one constants/data file, not literals

---

## Acceptance Criteria

*From `design/art/art-bible.md` / ADR amendments of 2026-10-01, scoped to this story:*

- [ ] Throwaway scene `prototypes/art-spike/` (outside `src/`): 1 DirectionalLight3D, perspective diorama camera (FOV 30°, pitch 52°, distance from the ADR-0002 solve at 360×640; was ortho), 12 SHADOWS_ONLY proxy capsules + 12 sprite cards with a first-cut toon material (placeholder textures)
- [ ] Measured on desktop, a mid-range 2021+ Android and the reference device/Low fallback (or explicitly marked NOT MEASURED + reason): ms/frame and draw calls with shadows off / 512 / 1024, and `render_scale` 0.6 / 0.8 / 1.0
- [ ] Verdict written per tier against ADR-0007 (Mid shadow pass <= 3 ms provisional, draw calls <= 180); shadow bias / peter-panning and texel density with `directional_shadow_max_distance` = z_max + 2 m (≈ 35–46 m from the perspective camera) checked on a screenshot; whether `SHADOW_ATTENUATION` in `light()` works in Compatibility 4.7 is stated (yes/no)
- [ ] If a line fails: the fallback (smaller map / fewer casters / Low-only shadows) is named and the ADR amendment needed is listed in the evidence doc

---

## Implementation Notes

- Use `Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME`, `Time.get_ticks_usec` via a spike-local probe (not gameplay code; PerfProbe stays a match-only tool).
- Build a web export (Compatibility) for the device runs; desktop-only numbers do not close this spike.
- Record numbers in a table: device | tier | shadow size | render_scale | ms | draw calls | fps.
- Toon shader here is a throwaway draft; the production shader is story 005.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 005: production toon shader
- Story 007: production light/shadow proxies
- Story 010: tier switching

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/Feel and UI screenshots are NOT waived (CLAUDE.md: a parse check is not a run).*

**Story Type**: Integration
**Required evidence**:
- `tests/integration/visual_pipeline/spike_s1_shadow_toon_cost_test.gd` OR playtest doc; measured numbers in `production/qa/evidence/spike-s1-shadow-toon-cost-evidence.md`
- Retained: `production/qa/evidence/vp-spike-s1-numbers.md` (table) + screenshots with shadows off/on/peter-panning check

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (first story; gates all art production)
- Unlocks: Stories 002-005, 007; art-assets story 003 (pilot)
