# Story 006: Hand-painted textured environment material (atlas x baked vertex color) and merged static meshes

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
**ADR Decision Summary**: Static environment = simple GLB meshes with light/AO baked into vertex colors, unshaded material, merged into <= 3 meshes by material, excluded from the shadow pass by layer mask; optional LightmapGI for floor/walls.
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

- [ ] `assets/shaders/` or material resource `env_vertex_color.tres` (unshaded, hand-painted albedo atlas on UV0 (2 x 2048², lossless, mipmapped; anisotropic on floor/walls if WebGL2 exposes it — ADR-0002 V8) multiplied by baked vertex-color light/AO; amended 2026-10-01) used by all static kitchen env meshes; greybox env (floor, walls, counters, island) renders with visible baked AO contact darkening
- [ ] Static kitchen env merges into <= 5 meshes (census line), kitchen env + clutter triangles <= 30k, layer mask keeps them out of the shadow pass (verified: shadow casters count unchanged when env added)
- [ ] LightmapGI included or dropped per spike S2 verdict; if included, UV1 + 512-1024 atlas size recorded in MB and within the texture budget
- [ ] Import check script (or editor tool) flags GLB without `COLOR_0` or with VRAM compression

---

## Implementation Notes

- Follow art bible §8.4: Y-up, metres, pivot at base, UV0 hand-painted atlas <= 2048^2 (was trim <= 1024^2; diorama amendment 2026-10-01), UV1 only for lightmapped surfaces.
- Shadow-pass exclusion via `GeometryInstance3D.layers` / `VisualInstance3D` layer vs light `cull_mask`; verify by counting casters, not by eye.
- Greybox geometry stands in for final art until art-assets story 007.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Art-assets 007: final environment models
- Story 012: scene assembly

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/Feel and UI screenshots are NOT waived (CLAUDE.md: a parse check is not a run).*

**Story Type**: Integration
**Required evidence**:
- `tests/integration/visual_pipeline/baked_vertex_color_environment_material_test.gd` OR playtest doc; measured numbers in `production/qa/evidence/baked-vertex-color-environment-material-evidence.md`
- Retained: `production/qa/evidence/vp-env-material-evidence.md` + screenshot (AO contact, shadow-pass caster count printout)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002
- Unlocks: Stories 009, 011, 012
