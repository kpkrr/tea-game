# Story 005: Guest archetypes: Clerk and Student

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
**ADR Decision Summary**: Each guest archetype: 2048x1536 atlas, 55 frames, 192x256 cells; silhouettes differ and never resemble cup/token/till.
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

- [ ] **Chibi** (head ≈ 1/1.8 of height, huge expressive faces, dynamic poses, slightly high-angle 3/4 view), adapted to the tea-house setting: Clerk (square, flat fringe, wide wharf-office waistcoat-coat with sleeve guards) and Student (down-pointing triangle, pointed travel-cloak hood, wide cloak shoulders, thin legs) each deliver walk 6, waiting_idle 4 (3/4 view, calm + wary variants), anger_loop 4, served 5, walk_happy 6, leaving 6 in one atlas each
- [ ] States Calm / Wary / Urgent are distinguishable by one pose at 48 dp, greyscale, ring hidden; urgent 'scribble' emote is beside the head, not above it; Clerk's "wary" gesture taps the wrist — no pocket watch or other round metal item (circle/gold = value)
- [ ] Clothing in natural fabrics, S 35-60 %, no pure step-recipe hues, step-colour accents <= 10 % of silhouette; validator + in-engine screenshots (perspective camera, day + evening, guest at the far queue point) pass

---

## Implementation Notes

- Follow archetype table in art bible §5; animation table §5 (guest frames 55).
- Guests walk_happy/leaving need only down and side directions.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 006: Neighbour and Schoolkid

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/Feel and UI screenshots are NOT waived (CLAUDE.md: a parse check is not a run).*

**Story Type**: Visual/Feel
**Required evidence**:
- `production/qa/evidence/guests-clerk-student-evidence.md` + retained screenshot(s) in `production/qa/evidence/` + sign-off
- Retained: `production/qa/evidence/aa-guests-clerk-student-evidence.md` + screenshots (48 dp greyscale silhouette strip)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003
- Unlocks: Visual-pipeline 012; guest view
