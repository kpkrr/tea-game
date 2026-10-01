# Story 008: Station 2D items: kettles, leaf jars, lemon, cup stack, bin, till

> **Epic**: Art Assets (MVP content)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Visual/Feel
> **Estimate**: L
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: 2026-10-01 (art direction revised: tea-house diorama, warm light — art bible A8–A10)

## Context

**GDD**: `design/art/art-bible.md`
**Requirement**: art-bible §3, 6, 8.3
*(Requirement text lives in `docs/architecture/tr-registry.yaml` / art bible — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Viewport, camera fit & 2.5D presentation; ADR-0007: Performance & load budgets
**ADR Decision Summary**: Stations are 3D base + outlined 2D item carrying the step glyph; the till is the brightest, warmest object in frame (Till Gold), bin neutral grey.
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

- [ ] Items for 7 stations in the tea-house look (chunky, rounded, flat-coloured — no texture on the 2D layer): two kettles (water 80 and 100) sitting on the stone hearth bases, green and black leaf jars (glazed ceramic), lemon, cup stack, iced-tea glass source as the recipe needs + till (hero: rounded wooden box with arch, Till Gold, states empty/filling/full) + bin (wooden tub), in the toon-shaded style with 2.5 dp outline, pivot at base, placed on the block top (no footprint overlap); kettle items clearly differ from decorative 3D clay teapots (outline = interactive)
- [ ] Till with baked light patch is the brightest **object** on day **and evening** screenshots even on Low tier (no glow): lit face ΔL* ≥ 10 above the brightest non-emissive surface near it, lantern patches do not reach it; silhouettes pass the 48 dp black-fill test and differ from each other
- [ ] Item textures <= 1024^2 atlas, mips on; provenance + validator pass; screenshot in-engine on all three tiers

---

## Implementation Notes

- Station glyph per recipe step colours §4 (cup, lemon, leaf, water_80, iced_tea, water_100, leaf_black).
- Till fill rays/flash are fx (story 011); kettle flames and steam puffs are fx (story 013) — anchor points for them are delivered here.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 009: cups/props
- Story 011: fx

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/Feel and UI screenshots are NOT waived (CLAUDE.md: a parse check is not a run).*

**Story Type**: Visual/Feel
**Required evidence**:
- `production/qa/evidence/station-items-kettles-till-evidence.md` + retained screenshot(s) in `production/qa/evidence/` + sign-off
- Retained: `production/qa/evidence/aa-station-items-evidence.md` + screenshots per tier

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 007, Story 003
- Unlocks: Visual-pipeline 012
