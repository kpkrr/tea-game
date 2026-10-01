# Story 003: PILOT: chibi barista sprite set + one hearth station + a textured diorama corner through the full pipeline

> **Epic**: Art Assets (MVP content)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Visual/Feel
> **Estimate**: L
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: 2026-10-01 (art direction revised: art bible A8–A12, reference ref-01)

## Context

**GDD**: `design/art/art-bible.md`
**Requirement**: art-bible A8–A12, §5, 6, 8.3, 8.4, 8.5, 8.8, 9; ADR-0007
*(Requirement text lives in `docs/architecture/tr-registry.yaml` / art bible — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Viewport, camera fit & 2.5D presentation; ADR-0007: Performance & load budgets
**ADR Decision Summary**: Toon-shaded 2D chibi characters in a warm, hand-painted 3D tea-house diorama seen by a fixed perspective camera; the pilot proves style frame -> AI-gen -> cleanup -> import -> in-engine look before full production.
**ADR Version**: ADR-0002 2026-09-30, ADR-0007 2026-09-30 *(both being amended for A8–A12 — read the current versions)*

**Engine**: Godot 4.7.2 (Compatibility / WebGL2) | **Risk**: HIGH
**Engine Notes**: Godot 4.7 is post-cutoff; check docs/engine-reference/godot/modules/rendering.md (Compatibility: depth prepass off on PowerVR/Mali/Adreno/Apple, render_priority orders transparent only, scaling_3d_scale adds an internal buffer + blit). Anything not verified there is UNVERIFIED — measure, do not assume.

**Control Manifest Rules (this layer)** *(no manifest — derived from the ADRs)*:
- Required (from ADR-0007): RGBA8 textures without VRAM compression (lossy WebP allowed only for hand-painted environment textures, art bible §8.1); side <= 2048 px; character atlases imported without mipmaps (others with); one constants file holds the texture / .pck thresholds
- Required (from ADR-0002): sprites upright, pivot at feet; environment = GLB with baked vertex color × hand-painted atlas texture; 2D layer has outline, 3D layer has none
- Guardrail (from ADR-0007 + art bible §8.5 art need): texture memory ≈ 150 MB (requested limit ≈ 160), .pck ≈ 11.3–13.8 MB (requested ≈ 14), scene ≤ 30k tris — limits per the amended ADR-0007; if exceeded raise the budget by ADR amendment (art bible A7), do not cut frames

---

## Acceptance Criteria

*From `design/art/art-bible.md` (revision 2026-10-01, A8–A12), scoped to this story:*

- [ ] Barista pilot set in **chibi proportions** (head ≈ 1/2 of height, huge expressive face, tall bun with symmetric band, linen shirt + long espresso apron with mint leaf patch): idle + walk in 3 directions (front/back/side, left = flip_h), drawn in slightly high-angle 3/4 view; 192x256 cells, pivot 8 px above cell bottom, outline 6-7 px / 4 px, palette <= 12 colours, no baked shadows, symmetric details only; plus the carried-cup anchor data
- [ ] One **kettle station** end to end: stone hearth base GLB (<= 1000 tris, baked vertex colour, UV0 on `env_arch_atlas`) + outlined 2D kettle item + small looping flame flipbook under it (decorative, not a state) and one steam-puff loop; provenance entries exist; validation script (story 002) passes
- [ ] One **diorama corner**: ~2x2 m of stone-tile walkway at 128 px/m, a counter segment, a parapet section with a lantern post and 3–5 periphery clutter pieces (crate, closed tea sack, clay pot, plant) on a first cut of `env_arch_atlas` / `env_clutter_atlas`, plus a pre-blurred strip of surroundings (cliff + water) visible past the edge
- [ ] In-engine screenshots with the **perspective camera (FOV ≈ 30°, pitch ≈ 52°)** in the greybox/test scene, toon shader, warm key light + lantern patch, real shadow (Mid) and blob (Low), day and evening light variants: barista reads at 48 dp in greyscale, flat look preserved, no halo, no shimmer on the far row (64 dp minimum, no mips); walkway texture under the character has no element < 24 dp with ΔL* > 8; till/kettle tokens not covered by steam/flame; **side-by-side with the approved style frame (story 001)** and owner says "matches"
- [ ] Pilot verdict written: prompt/cleanup time per frame and per texture, issues found, measured texture memory and .pck delta of the pilot atlases (lossy WebP), go/no-go and changes to the pipeline or bible before full production

---

## Implementation Notes

- Do not start stories 004-011 and 013 until this verdict is written.
- Checklist for each asset: art bible §8.9; cleanup checklist §8.8 item 5.
- Needs visual-pipeline stories 001/003 (spike verdicts, incl. perspective camera, mips on far row, day/evening bake blend, lossy WebP) and 005 (toon shader).
- Character cell size and `pixel_size` are unchanged by chibi proportions — only the proportions inside the silhouette change (art bible §8.3).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Stories 004-011, 013: full production

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/Feel and UI screenshots are NOT waived (CLAUDE.md: a parse check is not a run).*

**Story Type**: Visual/Feel
**Required evidence**:
- `production/qa/evidence/pilot-barista-and-station-evidence.md` + retained screenshot(s) in `production/qa/evidence/` + sign-off
- Retained: `production/qa/evidence/aa-pilot-evidence.md` + in-engine screenshots (Low + Mid, day + evening) + greyscale 48 dp check + side-by-side with the style frame; owner sign-off

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (approved style frame + MSR), 002; visual-pipeline 001, 003, 005
- Unlocks: Stories 004-011, 013
