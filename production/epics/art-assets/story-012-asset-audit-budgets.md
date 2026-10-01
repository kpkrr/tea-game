# Story 012: Asset audit against budgets and naming

> **Epic**: Art Assets (MVP content)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Config/Data
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: 2026-10-01 (budgets per art bible §8.5 after A8–A12; limits per amended ADR-0007)

## Context

**GDD**: `design/art/art-bible.md`
**Requirement**: ADR-0007 budgets; art-bible §8.5, 8.9
*(Requirement text lives in `docs/architecture/tr-registry.yaml` / art bible — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: Performance & load budgets; ADR-0002: Viewport, camera fit & 2.5D presentation
**ADR Decision Summary**: Final check that all art fits the amended ADR-0007 limits (art need per art bible §8.5: ≈ 150 MB texture memory, ≈ 11.3–13.8 MB .pck, ≤ 30k tris), side <= 2048, no VRAM compression, lossy WebP only on environment textures; overflows go to the owner as a budget amendment, not a cut.
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

- [ ] `/asset-audit` run: naming, folders, orphans, missing references, provenance coverage, import flags; report saved in `production/qa/` with violations fixed or ticketed
- [ ] Measured totals from a real web export: texture memory (MB) per art bible §8.5 line (characters no-mip 72, env atlases arch/clutter/surround+water, lightmaps day+evening, FX, props, UI) vs the ≈ 148–152 MB plan; `.pck` size (MB) incl. lossy env share; scene triangles by §8.4 category; simultaneous VFX quads per tier; pre-warm time; each line marked PASS / FAIL / NOT MEASURED with reason
- [ ] Texel density spot-check (§8.5: 128 px/m play zone, 96–128 clutter, 32–64 surroundings, ±20 %) and colour rules for decor (ΔE00 ≥ 20 from step hexes, no gold/brass/mint) on in-game screenshots
- [ ] If any line fails the amendment request (budget raise per art bible A7) is drafted; the 8.9 checklist is ticked per asset group with in-game screenshots retained

---

## Implementation Notes

- Uses validate script from story 002; `.pck` size from export preset build.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- None

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/Feel and UI screenshots are NOT waived (CLAUDE.md: a parse check is not a run).*

**Story Type**: Config/Data
**Required evidence**:
- `production/qa/evidence/asset-audit-budgets-evidence.md` + retained screenshot(s) in `production/qa/evidence/` + sign-off
- Smoke/audit pass: `production/qa/smoke-asset-audit-2026-10.md`; numbers in `production/qa/evidence/aa-budget-audit.md`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 004-011, 013
- Unlocks: Gate: production art complete
