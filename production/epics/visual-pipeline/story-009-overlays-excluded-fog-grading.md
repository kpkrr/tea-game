# Story 009: World overlays excluded from fog and grading

> **Epic**: Visual Pipeline (Lighting, Toon Shader, Quality Tiers)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Visual/Feel
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/art/art-bible.md`
**Requirement**: TR-art-004
*(Requirement text lives in `docs/architecture/tr-registry.yaml` / art bible — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Viewport, camera fit & 2.5D presentation; ADR-0007: Performance & load budgets
**ADR Decision Summary**: Overlays (tokens, rings, prices, cup tokens, kettle state, till fill, station tags, target outline, floor ring) use unshaded materials with disable_fog and keep hex under the mood shift.
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

- [ ] A shared overlay material set (alpha-blended, unshaded, `disable_fog = true`, `no_depth_test`, render_priority bands) is used by every world overlay; no overlay uses the toon or env material
- [ ] Day -> evening shift (light energy/colour + env material params, per spike S4 recommendation) leaves sampled overlay hex unchanged (automated pixel-sample check within a stated tolerance)
- [ ] Overlays are never parented under grading-affected fake-DOF/vignette quads; vignette stays inside `kitchen_rect`, below HUD, never over first-row tokens/rings (art bible §7.7 p.5)
- [ ] Screenshot in the darkest evening + last-strike vignette state shows token contrast >= 3:1 (measured, backing Parchment)

---

## Implementation Notes

- Follow ADR-0002 §5 overlay rules (`rotation.x = -camera_pitch_deg`, `no_depth_test`, render_priority bands); do not use scene-tree order.
- Tonemap mode per S4: if it touches overlays, use linear/neutral and carry mood by materials only.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 012: hooks into scene
- HUD epic: screen UI is separate from world overlays

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/Feel and UI screenshots are NOT waived (CLAUDE.md: a parse check is not a run).*

**Story Type**: Visual/Feel
**Required evidence**:
- `production/qa/evidence/overlays-excluded-fog-grading-evidence.md` + retained screenshot(s) in `production/qa/evidence/` + sign-off
- Retained: `production/qa/evidence/vp-overlays-grading-evidence.md` + day/evening/last-strike screenshots

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 004, Story 006
- Unlocks: Story 012
