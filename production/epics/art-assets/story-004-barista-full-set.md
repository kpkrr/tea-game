# Story 004: Barista full animation set and atlases

> **Epic**: Art Assets (MVP content)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Visual/Feel
> **Estimate**: L
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: 2026-10-01 (art direction revised: chibi proportions, art bible A11)

## Context

**GDD**: `design/art/art-bible.md`
**Requirement**: art-bible §5, 8.3, 8.5
*(Requirement text lives in `docs/architecture/tr-registry.yaml` / art bible — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Viewport, camera fit & 2.5D presentation; ADR-0007: Performance & load budgets
**ADR Decision Summary**: Barista: 54 frames (idle/idle_carry 4, walk/walk_carry 8, action 3) x 2 diagonals + flip_h (owner decision 2026-10-01, art bible §8.3); atlases `chr_barista_move_atlas` 2048^2 + `chr_barista_action_atlas` 2048x1024, no mips.
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

- [ ] All 54 barista frames (2 diagonals + flip_h, art bible §8.3) delivered in the two atlases (10 columns x 256 px, 4 px padding, edge-colour bleed 2 px) in the **chibi design approved in the pilot** (head ≈ 1/2 of height, huge expressive face, tall bun with symmetric band, linen shirt, long espresso apron with mint leaf patch), drawn in slightly high-angle 3/4 view; pivot and cup-anchor identical per frame, squash/stretch <= +-15 % with constant outline width, bun silhouette readable at 48 dp
- [ ] Poses are dynamic (body lean up to ±15 °, idle never stiff); emotion reads on the face (eager, never panicked — art bible §9 ref-01 "do not take")
- [ ] SpriteFrames/animation resources built with fps per art bible §5 (idle 8, walk 14, action 12); `_carry` frames have hand anchors; `flip_h` mirror has no asymmetric marks
- [ ] In-engine screenshots (perspective camera, Low/Mid, day + evening, toon shader with warm rim) of each animation, near and far row; no shimmer on the far row without mips; file sizes and texture memory recorded against the 24 MB no-mip line; validator passes

---

## Implementation Notes

- Keyframes via AI from MSR, in-betweens and smear by hand (§8.8 item 3).
- Cup in hand is a separate sprite (story 009), never baked into frames.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 009: cup sprites
- Story 007: no dependency

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/Feel and UI screenshots are NOT waived (CLAUDE.md: a parse check is not a run).*

**Story Type**: Visual/Feel
**Required evidence**:
- `production/qa/evidence/barista-full-set-evidence.md` + retained screenshot(s) in `production/qa/evidence/` + sign-off
- Retained: `production/qa/evidence/aa-barista-evidence.md` + screenshots

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003
- Unlocks: Visual-pipeline 012 integration; gameplay view
