# Story 007: Directional light and shadow-only proxy capsules

> **Epic**: Visual Pipeline (Lighting, Toon Shader, Quality Tiers)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/art/art-bible.md`
**Requirement**: TR-art-002
*(Requirement text lives in `docs/architecture/tr-registry.yaml` / art bible — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Viewport, camera fit & 2.5D presentation; ADR-0007: Performance & load budgets
**ADR Decision Summary**: One DirectionalLight3D (window key light), one cascade, ortho shadow fit, distance following the perspective camera depth range; only dynamic objects cast, via invisible SHADOWS_ONLY proxy capsules, not sprite cards.
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

- [ ] One `DirectionalLight3D` from top-left-front with shadow enabled, one cascade, shadow distance tuned to the kitchen; no other lights exist in the scene (test asserts node count of Light3D == 1 and no Omni/Spot)
- [ ] A reusable proxy scene (capsule, `cast_shadow = SHADOWS_ONLY`) follows barista, each guest and each cup; casters in the scene <= 12 at worst case, asserted by the census test
- [ ] Shadow appearance checked on screenshot: no acne, no visible peter-panning at kitchen scale, sprite card itself casts nothing; shadow strength/bias/size values come from data
- [ ] Tier hook: shadow size / filter / on-off are set by the tier config (story 010); day->evening changes light energy/colour only

---

## Implementation Notes

- `DirectionalLight3D`: `directional_shadow_mode = ORTHOGONAL`, `directional_shadow_max_distance` = `ViewFit.get_depth_range().y` + 2 m, updated in the `playfield_changed` handler (perspective camera distance varies ≈ 22–40 m with aspect — ADR-0002 diorama amendment, point 3); depth-fog begin/end likewise relative to the depth range; bias per S1 result.
- Proxy follows its owner in `_process` of the view layer (presentation only; no sim state touched).
- Real shadows are drawn over the blob shadow (story 008) on Mid/High.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 008: blob shadows
- Story 010: tier switching

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/Feel and UI screenshots are NOT waived (CLAUDE.md: a parse check is not a run).*

**Story Type**: Integration
**Required evidence**:
- `tests/integration/visual_pipeline/directional_light_shadow_proxies_test.gd` OR playtest doc; measured numbers in `production/qa/evidence/directional-light-shadow-proxies-evidence.md`
- Retained: `production/qa/evidence/vp-light-proxies-evidence.md` + screenshot (shadow on floor, caster count)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001, Story 005
- Unlocks: Stories 010, 011, 012
