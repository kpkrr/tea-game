# Story 009: Props: cup states (incl. ruined), lemon, leaves, step tokens

> **Epic**: Art Assets (MVP content)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Visual/Feel
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: 2026-10-01 (art direction revised: tea-house cup look — art bible A8, §3; step colours unchanged)

## Context

**GDD**: `design/art/art-bible.md`
**Requirement**: art-bible §3, 4, 5, 8.3
*(Requirement text lives in `docs/architecture/tr-registry.yaml` / art bible — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Viewport, camera fit & 2.5D presentation; ADR-0007: Performance & load budgets
**ADR Decision Summary**: Cup is the hero prop: tall rounded trapezoid, dome lid, diagonal straw; tokens are circles/pills on a Parchment backing with glyph duplicates for colour-blind safety.
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

- [ ] Cup sprites for each recipe state (empty, each ingredient stage, finished drinks, in-hand variant) and a clearly different ruined silhouette; cup = tall rounded thick-glass/ceramic tumbler with a dome lid and a **bamboo straw** (tea-house look, art bible §3); white cup has mandatory outline; straw is the only diagonal stroke in the play zone; steam over hot drinks is fx (story 013), never baked into the cup
- [ ] Seven step-token glyphs (cup, lemon slice, leaf, drop 1 steam, iced glass, drop 3 steam, curled leaf) with exact step hex (§4) on Parchment; Ink glyph contrast >= 3:1 on each (measured)
- [ ] Lemon and leaf props sized to the 128 px/m scale; all in one <= 1024^2 atlas with mips; validator + in-engine screenshot (perspective camera, day + evening; cup in hand, on the wooden counter, on till) pass with tokens on Parchment backing readable against warm wood

---

## Implementation Notes

- Red appears only on the water_100 token (§4 semantics).
- Cup in hand anchors to barista hand anchor from story 004.

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
- `production/qa/evidence/props-cups-lemon-leaves-evidence.md` + retained screenshot(s) in `production/qa/evidence/` + sign-off
- Retained: `production/qa/evidence/aa-props-evidence.md` + screenshots (cup states row, tokens on Parchment, greyscale)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003 (pilot verdict); Story 004 for the hand anchor
- Unlocks: Visual-pipeline 009, 012
