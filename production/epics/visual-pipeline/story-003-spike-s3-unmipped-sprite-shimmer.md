# Story 003: Spike S3: unmipped 192x256 character sprites — shimmer while walking

> **Epic**: Visual Pipeline (Lighting, Toon Shader, Quality Tiers)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Visual/Feel
> **Estimate**: S
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/art/art-bible.md`
**Requirement**: TR-art-007, TR-art-003
*(Requirement text lives in `docs/architecture/tr-registry.yaml` / art bible — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: Performance & load budgets; ADR-0002: Viewport, camera fit & 2.5D presentation
**ADR Decision Summary**: Character atlases are imported without mipmaps (minification <= ~1.4x); if the walk cycle shimmers, mipmaps are enabled and the texture limit rises to ~120 MB by amendment.
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

- [ ] A 192x256 placeholder walk cycle (8 frames, outline 6-7 px) moves across the perspective diorama camera at the target size (64-100 dp, DPR 1/2/3) **including the back-wall depth** (≈ 0.82× of front-row size, minification up to ≈ 1.7×; ADR-0007 diorama amendment) with mipmaps OFF and ON; short capture or frame-sequence stored
- [ ] Verdict: shimmer / crawl on outline acceptable or not at DPR 3 and at the 64 dp minimum; decision 'no mips' or 'mips on + limit 120 MB' written
- [ ] If 'mips on': the needed ADR-0007 amendment text (texture memory 96 -> ~120 MB) is drafted in the evidence doc (amendment itself is applied by the owner/architect)

---

## Implementation Notes

- Import flags: `mipmaps/generate=false`, `texture_filter` linear; compare with `generate=true` + `anisotropic`.
- Can reuse the placeholder from spike S1; a real AI sprite is not required.
- Pixel-pilot-quality conclusion is re-checked on real art in art-assets story 003.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 005: shader (filter flags live in the material/import preset)
- Art-assets story 002: import presets

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/Feel and UI screenshots are NOT waived (CLAUDE.md: a parse check is not a run).*

**Story Type**: Visual/Feel
**Required evidence**:
- `production/qa/evidence/spike-s3-unmipped-sprite-shimmer-evidence.md` + retained screenshot(s) in `production/qa/evidence/` + sign-off
- Retained: `production/qa/evidence/vp-spike-s3-sprite-shimmer.md` + screenshots/frames (mips off vs on)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: Stories 005; art-assets stories 002, 003
