# Story 011: Logo, carved wooden menu sign with lanterns, menu art, light/FX quads and share card

> **Epic**: Art Assets (MVP content)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Visual/Feel
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: 2026-10-01 (neon sign replaced by a carved wooden sign with lanterns — art bible A8, §7.6)

## Context

**GDD**: `design/art/art-bible.md`
**Requirement**: art-bible §2, 7.6, 7.7, 8.6, 8.7
*(Requirement text lives in `docs/architecture/tr-registry.yaml` / art bible — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Viewport, camera fit & 2.5D presentation; ADR-0007: Performance & load budgets
**ADR Decision Summary**: TEA RUSH carved wooden sign between two lanterns (lantern halo glow High only, baked halo sprite on Low), blob shadow, till light rays, sun/lantern light patches, vignette and the 1080x1350 share card.
**ADR Version**: ADR-0002 2026-09-30, ADR-0007 2026-09-30 *(both being amended for A8–A12 — read the current versions)*

**Engine**: Godot 4.7.2 (Compatibility / WebGL2) | **Risk**: HIGH
**Engine Notes**: Godot 4.7 is post-cutoff; check docs/engine-reference/godot/modules/rendering.md (Compatibility: depth prepass off on PowerVR/Mali/Adreno/Apple, render_priority orders transparent only, scaling_3d_scale adds an internal buffer + blit). Anything not verified there is UNVERIFIED — measure, do not assume.

**Control Manifest Rules (this layer)** *(no manifest — derived from the ADRs)*:
- Required (from ADR-0007): RGBA8 textures without VRAM compression (lossy WebP allowed only for hand-painted environment textures, art bible §8.1); side <= 2048 px; character atlases imported without mipmaps (others with); one constants file holds the texture / .pck thresholds
- Required (from ADR-0002): sprites upright, pivot at feet; environment = GLB with baked vertex color × hand-painted atlas texture; 2D layer has outline, 3D layer has none
- Guardrail (from ADR-0007 + art bible §8.5 art need): texture memory ≈ 150 MB (requested limit ≈ 160), .pck ≈ 11.3–13.8 MB (requested ≈ 14), scene ≤ 30k tris — limits per the amended ADR-0007; if exceeded raise the budget by ADR amendment (art bible A7), do not cut frames

---

## Acceptance Criteria

*From `design/art/art-bible.md` (revision 2026-10-01), scoped to this story:*

- [ ] `ui_logo_sign` — carved dark-walnut board on two ropes between two lantern posts; Fredoka-based lettering painted Parchment with Ink outline, small mint tea leaf above "TEA"; usable in the menu (diorama, perspective camera) and as a flat PNG on the HTML loading screen at the same position/scale with lanterns unlit (cross-fade = "lanterns light up"); lantern glow on High only, baked halo sprite on Low; reduced-motion variant (instant on)
- [ ] Menu composition per §7.6: sign in the top ~45 %, chibi barista hero pose raising a cup with a steam puff, key content inside the central 360x320 dp block on 9:20 and 1:1, status line on a Parchment pill, no text on bare art
- [ ] `fx_shadow_blob.png` 128x64 (Ink alpha 0.25, soft, no outline), `fx_rays_till_loop`, sun patch, lantern patch (Lantern Glow #FFE3B3, additive) and vignette quads delivered at <= 512^2; lantern patches stay off the till and slots; reduced-motion variants listed
- [ ] Share card `ui_share_*` 1080x1350: key content inside 1080x1080, score >= 20 % of height, only Ink on Parchment, outline >= 6 px, chibi barista in a corner; legible in a 250 px preview screenshot

---

## Implementation Notes

- Blob texture replaces the placeholder of visual-pipeline 008.
- Vignette is Ember Dusk and never red (§2).
- No neon anywhere in the world; "Mint Neon" stays only as a UI colour token (§4).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 012: audit
- Story 013: steam/smoke/dust/spark/flame flipbooks

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/Feel and UI screenshots are NOT waived (CLAUDE.md: a parse check is not a run).*

**Story Type**: Visual/Feel
**Required evidence**:
- `production/qa/evidence/logo-neon-fx-share-card-evidence.md` + retained screenshot(s) in `production/qa/evidence/` + sign-off
- Retained: `production/qa/evidence/aa-logo-fx-share-evidence.md` + screenshots (menu with lit sign on High, Low halo, loading screen, share card 250 px preview)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 010; Story 007
- Unlocks: Visual-pipeline 008; game-flow menu/results
