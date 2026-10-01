# Story 004: Spike S4: world overlays outside fog, tonemap and colour adjustments

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
**ADR Decision Summary**: All world overlays (tokens, rings, prices, tags, target outline) are unshaded with disable_fog and must keep their hex under the day->evening mood shift; if Compatibility tonemaps overlays regardless, the tonemap must be neutral and mood carried by materials.
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

- [ ] Test scene with WorldEnvironment (filmic tonemap, adjustments, depth fog) + overlay sprites (tokens of all 7 step colours, patience ring, price) on the test counter; overlay pixels sampled from a screenshot before/after the mood shift — hex deviation measured and tabulated
- [ ] Verdict: overlays unchanged with `disable_fog` + unshaded alone, or tonemap applies to them (then linear tonemap + materials-only mood is mandated); fake-DOF quad does not blur overlays
- [ ] Contrast of the worst pairs (leaf_black and water_100 on Parchment backing, evening lighting) measured on the screenshot vs the 3:1 target (art bible §4, §7.7 p.3); result recorded
- [ ] Final recommended Environment setup (tonemap mode, adjustments on/off, fog) written as the input for story 009

---

## Implementation Notes

- Use `StandardMaterial3D.disable_fog = true`, `shading_mode = unshaded`, `no_depth_test = true`, alpha-blended overlay material; do not use `Environment.adjustment_*` for the mood shift — drive light energy/colour and env material params.
- Screenshot sampling: use a small GDScript/Python script reading the PNG; store it next to the evidence.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 009: production overlay material rules

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/Feel and UI screenshots are NOT waived (CLAUDE.md: a parse check is not a run).*

**Story Type**: Visual/Feel
**Required evidence**:
- `production/qa/evidence/spike-s4-overlays-outside-fog-grading-evidence.md` + retained screenshot(s) in `production/qa/evidence/` + sign-off
- Retained: `production/qa/evidence/vp-spike-s4-overlay-grading.md` + screenshots (day / evening, tonemap on/off)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: Story 009; hud stories that depend on world overlays
