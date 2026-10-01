# Story 007: Environment set: tea-house diorama terrace, counters, station bases, periphery clutter and surroundings

> **Epic**: Art Assets (MVP content)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Visual/Feel
> **Estimate**: L
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: 2026-10-01 (art direction revised: art bible A8–A10, reference ref-01)

## Context

**GDD**: `design/art/art-bible.md`
**Requirement**: art-bible A8–A10, §3, §4 (world vs UI), §6, 8.4, 8.5; ADR-0007
*(Requirement text lives in `docs/architecture/tr-registry.yaml` / art bible — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Viewport, camera fit & 2.5D presentation; ADR-0007: Performance & load budgets
**ADR Decision Summary**: Environment is chunky stylised GLB with hand-painted atlas textures × baked vertex-colour light/AO, no outline; play zone calm (S 15–40 %, L* 40–70, ΔL* ≤ 10 inside textures), periphery rich (S ≤ 55 %), surroundings pre-blurred; scene ≈ 24.5k tris (art need ceiling 30k, see ADR-0007).
**ADR Version**: ADR-0002 2026-09-30, ADR-0007 2026-09-30 *(both being amended for A8–A12 — read the current versions)*

**Engine**: Godot 4.7.2 (Compatibility / WebGL2) | **Risk**: HIGH
**Engine Notes**: Godot 4.7 is post-cutoff; check docs/engine-reference/godot/modules/rendering.md (Compatibility: depth prepass off on PowerVR/Mali/Adreno/Apple, render_priority orders transparent only, scaling_3d_scale adds an internal buffer + blit). Anything not verified there is UNVERIFIED — measure, do not assume.

**Control Manifest Rules (this layer)** *(no manifest — derived from the ADRs)*:
- Required (from ADR-0007): RGBA8 textures without VRAM compression (lossy WebP allowed only for hand-painted environment textures, art bible §8.1); side <= 2048 px; character atlases imported without mipmaps (others with); one constants file holds the texture / .pck thresholds
- Required (from ADR-0002): sprites upright, pivot at feet; environment = GLB with baked vertex color × hand-painted atlas texture; 2D layer has outline, 3D layer has none
- Guardrail (from ADR-0007 + art bible §8.5 art need): texture memory ≈ 150 MB (requested limit ≈ 160), .pck ≈ 11.3–13.8 MB (requested ≈ 14), scene ≤ 30k tris — limits per the amended ADR-0007; if exceeded raise the budget by ADR amendment (art bible A7), do not cut frames

---

## Acceptance Criteria

*From `design/art/art-bible.md` (revision 2026-10-01, A8–A10), scoped to this story:*

- [ ] GLBs (all with `COLOR_0` baked light/AO, pivots at base, bevels 4–8 %): perimeter counters + 2x4 island in thick honey-wood planks (one mesh, <= 3000 tris, top ≈ 1.5x thick, straight); stone-tile floor + stone/log parapet + lantern posts (<= 2500; near-camera parapet ≤ ≈ 0.6 m high); 7 station bases — stone hearths for the two kettles, wooden cabinets for the rest (<= 5000 total); periphery clutter — crates, closed tea sacks, clay teapots/jugs, herb bundles, potted plants, water barrels, ropes, hand-painted menu board, OPEN/CLOSED sign, sleeping cat (<= 9000, merged by atlas); diorama surroundings — cliffs, river water plane, far bank (<= 5000)
- [ ] Hand-painted atlases per art bible §8.5: `env_arch_atlas` 2048² at 128 px/m (2–3 floor tile variants, plank trims, parapet, station bases), `env_clutter_atlas` 2048² at 96–128 px/m, `env_surround_atlas` 2048x1024 pre-blurred at 32–64 px/m, `env_water_tile` 512² with UV scroll; painted material only (no cast shadows / strong AO in albedo), no Ink outlines; imported lossy WebP; density within ±20 % per class
- [ ] Colour rules (§4): play-zone surfaces S 15–40 %, L* 40–70, texture ΔL* ≤ 10, no element < 24 dp with ΔL* > 8 under the guest queue; periphery S ≤ 55 % (accents ≤ 60 %, ≤ 3 % frame each); every 3D colour > 8 dp at ΔE00 ≥ 20 from all 7 step hexes; no gold/brass, no mint, water not mint (L* ≤ 55); no red produce/banners
- [ ] Layout rules (§6): no clutter on counters, slots, station tags, queue points or guest path; no geometry above the play zone; lanterns only on the parapet, never between camera and slots/stations
- [ ] Day and evening light variants baked (method per visual-pipeline spike): play-zone counter/walkway lightness stays within ±5 %; surroundings darken ≈ 20 %; lantern patches grow
- [ ] In-engine screenshots (perspective camera, ≤ 5 merged static meshes) day + evening, Low + Mid: greyscale + 2 dp blur still separates characters, tokens and till from background; till's lit face ΔL* ≥ 10 above the brightest non-emissive surface near it; surroundings visible in the HUD strips / perspective wedges; census, triangle counts and measured texture memory + .pck delta recorded

---

## Implementation Notes

- Uses materials from visual-pipeline 006; geometry modelled by hand from the style frame / AI concepts (art bible §8.8 item 4); textures from master prompt §8.8-3d then hand-fixed for tiling and contrast.
- No coins/gold/round tokens in decor (Pillar 3); mint only on the barista patch and the menu sign leaf.
- Decorative clay teapots are 3D without outline and must not look like the outlined 2D kettle items on the stations.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 008: 2D station items and till
- Story 011: menu sign, light patches and fx quads
- Story 013: VFX flipbooks (steam, smoke, flames, sparks, dust)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/Feel and UI screenshots are NOT waived (CLAUDE.md: a parse check is not a run).*

**Story Type**: Visual/Feel
**Required evidence**:
- `production/qa/evidence/environment-3d-set-evidence.md` + retained screenshot(s) in `production/qa/evidence/` + sign-off
- Retained: `production/qa/evidence/aa-environment-evidence.md` + screenshots (day/evening, Low/Mid, greyscale blur test, side-by-side with the approved style frame)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003; visual-pipeline 002, 006
- Unlocks: Visual-pipeline 012
