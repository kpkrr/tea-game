# Story 006: Guest archetypes: Neighbour and Schoolkid

> **Epic**: Art Assets (MVP content)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Visual/Feel
> **Estimate**: L
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: 2026-10-01 (art direction revised: chibi proportions, tea-house outfits — art bible A11)

## Context

**GDD**: `design/art/art-bible.md`
**Requirement**: art-bible §3, 5, 8.3, 8.5
*(Requirement text lives in `docs/architecture/tr-registry.yaml` / art bible — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Viewport, camera fit & 2.5D presentation; ADR-0007: Performance & load budgets
**ADR Decision Summary**: Same standard as story 005 for the remaining two archetypes (Neighbour circle/cap; Schoolkid low square 0.65 height with big backpack).
**ADR Version**: ADR-0002 2026-09-30, ADR-0007 2026-09-30

**Engine**: Godot 4.7.2 (Compatibility / WebGL2) | **Risk**: HIGH
**Engine Notes**: Godot 4.7 is post-cutoff; check docs/engine-reference/godot/modules/rendering.md (Compatibility: depth prepass off on PowerVR/Mali/Adreno/Apple, render_priority orders transparent only, scaling_3d_scale adds an internal buffer + blit). Anything not verified there is UNVERIFIED — measure, do not assume.

**Control Manifest Rules (this layer)** *(no manifest — derived from the ADRs)*:
- Required (from ADR-0007): RGBA8 textures without VRAM compression (lossy WebP allowed only for hand-painted environment textures, art bible §8.1); side <= 2048 px; character atlases imported without mipmaps (others with); one constants file holds the texture / .pck thresholds
- Required (from ADR-0002): sprites upright, pivot at feet; environment = GLB with baked vertex color × hand-painted atlas texture; 2D layer has outline, 3D layer has none
- Guardrail (from ADR-0007 + art bible §8.5 art need): texture memory ≈ 150 MB (requested limit ≈ 160), .pck ≈ 11.3–13.8 MB (requested ≈ 14), scene ≤ 30k tris — limits per the amended ADR-0007; if exceeded raise the budget by ADR amendment (art bible A7), do not cut frames

---

## Acceptance Criteria

*From `design/art/art-bible.md` / ADR amendments of 2026-10-01, scoped to this story:*

- [ ] **Chibi**, adapted to the tea-house setting: Neighbour (circle, flat cap, round body in a knitted vest; head ≈ 1/1.8) and Schoolkid (low square 0.65 height, sticking-out tufts, huge symmetric woven basket backpack; head ≈ 1/1.6) deliver the full 55-frame set each in a 2048x1536 atlas with identical pivots/cells to the other guests
- [ ] All four archetypes side by side in one screenshot: silhouettes distinct at 48 dp in black fill; Schoolkid's basket backpack does not read as a cup/till; no round metal items; palettes <= 12 colours each
- [ ] Four-guest texture total (4 x 2048x1536 no mips = 48 MB) recorded against the texture budget (art bible §8.5, amended ADR-0007); validator passes

---

## Implementation Notes

- Backpack must be symmetric or hidden on the mirrored side (flip_h rule).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 012: audit

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/Feel and UI screenshots are NOT waived (CLAUDE.md: a parse check is not a run).*

**Story Type**: Visual/Feel
**Required evidence**:
- `production/qa/evidence/guests-neighbour-schoolkid-evidence.md` + retained screenshot(s) in `production/qa/evidence/` + sign-off
- Retained: `production/qa/evidence/aa-guests-neighbour-schoolkid-evidence.md` + four-guest lineup screenshot

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 005
- Unlocks: Story 012
