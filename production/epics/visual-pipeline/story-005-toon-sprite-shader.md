# Story 005: Toon sprite shader (unshaded base x zone tint, 2-step ramp, rim)

> **Epic**: Visual Pipeline (Lighting, Toon Shader, Quality Tiers)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Visual/Feel
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/art/art-bible.md`
**Requirement**: TR-art-003
*(Requirement text lives in `docs/architecture/tr-registry.yaml` / art bible — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Viewport, camera fit & 2.5D presentation; ADR-0007: Performance & load budgets
**ADR Decision Summary**: Character and item sprites use a custom toon spatial shader; stock lit Sprite3D is forbidden. Base unshaded x zone tint <= 15 %, 2-step ramp from the single light via camera-facing pseudo-normal, 1 dp rim on the lit side.
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

- [ ] `assets/shaders/toon_sprite.gdshader` (+ `.tres` material presets for character / item) renders a sprite with unshaded base, zone tint <= 15 % (uniform cap enforced), 2-step ramp with the shadow step 12 % darker in lightness without hue shift, and a 1 dp rim tint (day Window Sky, evening warm)
- [ ] Flat neutral look preserved: side-by-side screenshot vs the stock lit Sprite3D shows no 'card with gradient' effect; silhouette test at 48 dp in greyscale still reads
- [ ] Shader exposes uniforms for tint, ramp threshold, rim colour, shadow-receive on/off (per S1 verdict); works with `flip_h` and alpha edges without halo
- [ ] Material and sprite respect filter/mip flags chosen in spike S3

---

## Implementation Notes

- Pseudo-normal from camera direction, not the card normal; use `light()` only if S1 confirmed `SHADOW_ATTENUATION` works, else a lit-without-receive variant.
- Zone tint sampled by world position from a small data-driven zone map (values in data, not literals).
- Two variants needed for pre-warm (story 011): lit and lit+shadow-receive.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 007: light and proxies
- Story 011: pre-warm
- Art-assets story 003: pilot checks real art in it

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/Feel and UI screenshots are NOT waived (CLAUDE.md: a parse check is not a run).*

**Story Type**: Visual/Feel
**Required evidence**:
- `production/qa/evidence/toon-sprite-shader-evidence.md` + retained screenshot(s) in `production/qa/evidence/` + sign-off
- Retained: `production/qa/evidence/vp-toon-shader-evidence.md` + screenshots (toon vs stock, day vs evening, 48 dp greyscale)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001, Story 003
- Unlocks: Stories 007, 011, 012; art-assets 003
