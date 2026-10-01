# Story 011: Shader pre-warm for toon, shadow-caster, env material and fog variants

> **Epic**: Visual Pipeline (Lighting, Toon Shader, Quality Tiers)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/art/art-bible.md`
**Requirement**: TR-art-008
*(Requirement text lives in `docs/architecture/tr-registry.yaml` / art bible — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: Performance & load budgets; ADR-0002: Viewport, camera fit & 2.5D presentation
**ADR Decision Summary**: Pre-warm instantiates, from the same scenes/materials as gameplay, the toon (lit + shadow-receive), shadow-caster pass, textured vertex-color env material, scenery material (Mid/High), VFX alpha + additive flipbook materials, fog on/off for the chosen tier only (amended 2026-10-01); <= 0.8 s.
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

- [ ] Pre-warm scene draws every required variant visible, in frustum, under the gameplay Environment and camera, using the same material resources as gameplay (no look-alikes)
- [ ] Only the chosen tier's light/shadow configuration is warmed; measured pre-warm time <= 0.8 s on desktop and on a mid Android (or NOT MEASURED + reason recorded)
- [ ] No first-use hitch: frame-time capture of the first match seconds shows no shader-compile spike > 1 frame budget after pre-warm

---

## Implementation Notes

- Shader baker (4.5) does not work on GL/WebGL (ADR-0007) — warm by drawing.
- Audio sample decode stays in the same pre-warm budget (ADR-0007 audio amendment); coordinate, do not duplicate.
- Time via injected clock/PerfProbe only.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 012: scene assembly

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/Feel and UI screenshots are NOT waived (CLAUDE.md: a parse check is not a run).*

**Story Type**: Integration
**Required evidence**:
- `tests/integration/visual_pipeline/shader_prewarm_test.gd` OR playtest doc; measured numbers in `production/qa/evidence/shader-prewarm-evidence.md`
- Retained: `production/qa/evidence/vp-prewarm-evidence.md` (pre-warm ms, frame-time capture)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 005, 006, 007, 010
- Unlocks: Story 012
