# Story 010: Quality tiers Low/Mid/High: detection and manual switch

> **Epic**: Visual Pipeline (Lighting, Toon Shader, Quality Tiers)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/art/art-bible.md`
**Requirement**: TR-art-006
*(Requirement text lives in `docs/architecture/tr-registry.yaml` / art bible — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: Performance & load budgets; ADR-0002: Viewport, camera fit & 2.5D presentation
**ADR Decision Summary**: Tiers are chosen statically at boot (detect + manual override in Settings): Low no real shadows/no glow/render_scale_min; Mid shadow 512 low filter; High 1024-2048 soft + light glow.
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

- [ ] `QualityTier` config (data-driven: shadow size, filter, glow, `render_scale_3d`) with pure function `detect_tier(inputs) -> tier` covered by unit tests (mobile GPU vendor, renderer string, memory hint, saved override)
- [ ] Tier applies once at boot before pre-warm; manual override persists through SaveStore and takes effect on next load (or safe re-apply), never adapts at runtime
- [ ] Low: light shadows off, glow off, blob shadows still on; Mid: 512, low filter, glow off; High: 1024-2048 soft + light glow; each verified by screenshot
- [ ] Unknown/undetectable device defaults to Mid and logs the reason (no silent permissive default); detection method noted for the AQ-10 open question

---

## Implementation Notes

- Detection inputs via PlatformBridge / RenderingServer adapter injected for tests; no `DisplayServer` reads in gameplay code.
- Whether a separate Quality Tiers ADR is needed stays open (architecture.md AQ-10); record the chosen detection method in the evidence doc for it.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 011: pre-warm per tier
- Settings UI toggle lives in game-flow/hud epics; expose the API here

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/Feel and UI screenshots are NOT waived (CLAUDE.md: a parse check is not a run).*

**Story Type**: Integration
**Required evidence**:
- `tests/integration/visual_pipeline/quality_tiers_detect_switch_test.gd` OR playtest doc; measured numbers in `production/qa/evidence/quality-tiers-detect-switch-evidence.md`
- Logic tests: `tests/unit/visual_pipeline/quality_tiers_detect_switch_test.gd`; screenshots of the three tiers in `production/qa/evidence/`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 007, Story 008
- Unlocks: Stories 011, 012
