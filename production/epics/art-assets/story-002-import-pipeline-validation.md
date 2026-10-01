# Story 002: Import pipeline: folders, presets and asset validation script

> **Epic**: Art Assets (MVP content)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: 2026-10-01 (art direction revised: art bible A8–A12 — lossy WebP for environment, new triangle categories)

## Context

**GDD**: `design/art/art-bible.md`
**Requirement**: art-bible §8.1, 8.2, 8.9; ADR-0007
*(Requirement text lives in `docs/architecture/tr-registry.yaml` / art bible — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: Performance & load budgets; ADR-0002: Viewport, camera fit & 2.5D presentation
**ADR Decision Summary**: No VRAM compression, sides <= 2048, character atlases without mipmaps, asset naming and provenance enforced before assets enter the build.
**ADR Version**: ADR-0007 2026-09-30, ADR-0002 2026-09-30

**Engine**: Godot 4.7.2 (Compatibility / WebGL2) | **Risk**: MEDIUM
**Engine Notes**: Godot 4.7 is post-cutoff; check docs/engine-reference/godot/modules/rendering.md (Compatibility: depth prepass off on PowerVR/Mali/Adreno/Apple, render_priority orders transparent only, scaling_3d_scale adds an internal buffer + blit). Anything not verified there is UNVERIFIED — measure, do not assume.

**Control Manifest Rules (this layer)** *(no manifest — derived from the ADRs)*:
- Required (from ADR-0007): RGBA8 textures without VRAM compression (lossy WebP allowed only for hand-painted environment textures, art bible §8.1); side <= 2048 px; character atlases imported without mipmaps (others with); one constants file holds the texture / .pck thresholds
- Required (from ADR-0002): sprites upright, pivot at feet; environment = GLB with baked vertex color × hand-painted atlas texture; 2D layer has outline, 3D layer has none
- Guardrail (from ADR-0007 + art bible §8.5 art need): texture memory ≈ 150 MB (requested limit ≈ 160), .pck ≈ 11.3–13.8 MB (requested ≈ 14), scene ≤ 30k tris — limits per the amended ADR-0007; if exceeded raise the budget by ADR amendment (art bible A7), do not cut frames

---

## Acceptance Criteria

*From `design/art/art-bible.md` / ADR amendments of 2026-10-01, scoped to this story:*

- [ ] Folders `assets/art/{characters,environment,props,fx,ui,lightmaps,fonts,share}/` and `art-source/{style-frame,msr}/` (`.gdignore`) created; import presets exist: character atlas (lossless, no mips, linear), prop/fx (lossless, mips), UI (no mips), **hand-painted environment atlases and surroundings (lossy WebP q ≈ 85–90, mips)** per art bible §8.1
- [ ] Validation script `tools/asset-pipeline/validate_assets.gd` (or .py) reports: name pattern violation (`chr_/env_/prop_/fx_/ui_/lm_`, snake_case), side > 2048, VRAM compression on, **lossy compression on anything that is not an `env_` texture**, mips on a character atlas, GLB without `COLOR_0` / over its art bible §8.4 triangle category, scene total over the triangle ceiling (read from the constants file), missing provenance entry
- [ ] Unit tests with fixture assets cover each rule (pass and fail case); validator output distinguishes 'violation' from 'could not check' (e.g. unreadable file)

---

## Implementation Notes

- Follows art bible §8.9 checklist items that are mechanically checkable; silhouette/outline checks stay manual.
- Script runs headless in CI (`godot --headless --script`) and locally.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 012: full audit using this script

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/Feel and UI screenshots are NOT waived (CLAUDE.md: a parse check is not a run).*

**Story Type**: Logic
**Required evidence**:
- `tests/unit/art_assets/import_pipeline_validation_test.gd` — must exist and pass
- Logic tests: `tests/unit/art_assets/import_pipeline_validation_test.gd`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (uses thresholds from ADR-0007 constants; spike S3 verdict on mips: visual-pipeline 003)
- Unlocks: Stories 003-011
