# Story 010: UI skin: HUD strips, panels, buttons and icon set

> **Epic**: Art Assets (MVP content)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: L
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: 2026-10-01 (HUD strips now sit over diorama surroundings — art bible A8, §7.1; UI tokens unchanged)

## Context

**GDD**: `design/art/art-bible.md`
**Requirement**: art-bible §7.1-7.5, 8.6; ADR-0002
*(Requirement text lives in `docs/architecture/tr-registry.yaml` / art bible — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Viewport, camera fit & 2.5D presentation; ADR-0007: Performance & load budgets
**ADR Decision Summary**: Screen UI is one Theme: StyleBoxFlat pills/panels (radii 4/8/16 dp, Ink outline), 9-slice only for the ticket slip; HUD plates on Parchment; icons SVG hand-cleaned.
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

- [ ] Godot `Theme` resource with Primary (Mint Neon/Ink), Secondary (Parchment), text, danger (double Ink frame), HUD disc (40 dp in 48 target) styles, pressed/hover/disabled states and the two-tone focus ring (Ink 3 dp + Parchment halo 2 dp); fonts Fredoka + Nunito imported with OFL.txt, Latin subset, tnum check for Nunito recorded
- [ ] Icon set SVG (24/48 dp grid): coin, star, strike on/off, pause/play, sound on/off, settings, records, share, back, install, streak, challenge, rotate, check/cross, 7 step glyphs; each passes the 24 dp silhouette test; no emoji dependency
- [ ] Ticket slip 9-slice + HUD strip screenshots on 9:20 and 1:1 **over the diorama surroundings** (blurred cliffs/water with Ink 30 % darkening under the strip, art bible §7.1), day and evening: no number on bare background; contrast targets §4 verified on screenshots; UI does not enter `kitchen_rect` except non-interactive plates

---

## Implementation Notes

- Emoji are replaced by built-in icons (RichTextLabel/TextureRect); no emoji font in the web build.
- Coordinate with HUD and game-flow epics: this story delivers the skin, not screens' logic.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 011: logo / wooden menu sign, share card, light quads; Story 013: VFX flipbooks

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/Feel and UI screenshots are NOT waived (CLAUDE.md: a parse check is not a run).*

**Story Type**: UI
**Required evidence**:
- `production/qa/evidence/ui-skin-hud-panels-icons-evidence.md` + retained screenshot(s) in `production/qa/evidence/` + sign-off
- Retained: `production/qa/evidence/aa-ui-skin-evidence.md` + screenshot of each HUD/panel/button state

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002
- Unlocks: HUD and game-flow epics screens
