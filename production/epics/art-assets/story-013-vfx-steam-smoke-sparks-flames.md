# Story 013: VFX flipbook set: steam and smoke puffs, dust poofs, sparks, kettle flames

> **Epic**: Art Assets (MVP content)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Visual/Feel
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: 2026-10-01 (new story — art bible A12, §6 VFX, reference ref-01)

## Context

**GDD**: `design/art/art-bible.md`
**Requirement**: art-bible A12, §4 (semantics: steam = water, fire = decorative), §6 «VFX», §7.7 items 1 and 10, §8.5 (FX 1024²), §8.7 (VFX caps per tier), §8.8-3e
*(Requirement text lives in `docs/architecture/tr-registry.yaml` / art bible — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Viewport, camera fit & 2.5D presentation; ADR-0007: Performance & load budgets
**ADR Decision Summary**: Cartoon VFX are flat 2–3-tone flipbook quads without outline, drawn below the world overlays (tokens, rings, prices, till) and capped per tier; one 1024² FX atlas with mips.
**ADR Version**: ADR-0002 2026-09-30, ADR-0007 2026-09-30 *(both being amended for A8–A12 — read the current versions)*

**Engine**: Godot 4.7.2 (Compatibility / WebGL2) | **Risk**: HIGH
**Engine Notes**: Godot 4.7 is post-cutoff; check docs/engine-reference/godot/modules/rendering.md (Compatibility: depth prepass off on PowerVR/Mali/Adreno/Apple, render_priority orders transparent only, scaling_3d_scale adds an internal buffer + blit). Anything not verified there is UNVERIFIED — measure, do not assume. Alpha overdraw of many quads on weak mobile GPUs must be measured, not assumed.

**Control Manifest Rules (this layer)** *(no manifest — derived from the ADRs)*:
- Required (from ADR-0007): RGBA8 textures without VRAM compression (lossy WebP allowed only for hand-painted environment textures, art bible §8.1); side <= 2048 px; character atlases imported without mipmaps (others with); one constants file holds the texture / .pck thresholds
- Required (from ADR-0002): sprites upright, pivot at feet; environment = GLB with baked vertex color × hand-painted atlas texture; 2D layer has outline, 3D layer has none
- Guardrail (from ADR-0007 + art bible §8.5 art need): texture memory ≈ 150 MB (requested limit ≈ 160), .pck ≈ 11.3–13.8 MB (requested ≈ 14), scene ≤ 30k tris — limits per the amended ADR-0007; if exceeded raise the budget by ADR amendment (art bible A7), do not cut frames

---

## Acceptance Criteria

*From `design/art/art-bible.md` (revision 2026-10-01, A12), scoped to this story:*

- [ ] One `fx_` atlas <= 1024² (lossless, mips) with flipbooks: steam puff over kettles/cups (Parchment-white, alpha <= 0.7, appear -> dissolve 0.6–1.2 s), thin smoke wisp for hearths/lanterns, dust poof at the barista's feet (warm grey-beige, <= 32 dp), sparks (Lantern Glow, 2–4 px), kettle flame loop (<= 24 dp, partly hidden by the hearth rim); all flat 2–3 tones, soft edges, **no outline**; names per §8.2 (`fx_puff_steam_sheet`, `fx_flame_kettle_loop`, …); generated from master prompt §8.8-3e and hand-cleaned, provenance entries exist
- [ ] Layering: every VFX renders **below** tokens, patience rings, prices, target outline and till; in the play zone a puff is <= 48 dp and alpha <= 0.6 over counters; screenshot proof with a brewing kettle next to its station tag and a served cup on the till
- [ ] Caps per tier (§8.7): Low <= 12, Mid/High <= 24 simultaneous VFX quads; nothing flashes more than 3 times per second; reduced-motion variants: slower steam/smoke without bursts, sparks off
- [ ] Semantics (§4): flames are steady decoration, never a state; steam belongs to water/kettles; no red/green state colouring; colours outside the step hexes except steam whites
- [ ] In-engine capture (Low + Mid, day + evening) at peak load (all stations busy, queue full): tokens and rings readable in greyscale; measured frame-time cost of the VFX set recorded against the ADR-0007 per-system budget

---

## Implementation Notes

- Triggering (when steam/dust/sparks spawn) is owned by the Audio & Juice / kitchen view code; this story delivers the art and the per-effect spec (frames, fps, size, alpha, lifetime) in `design/art/specs/`.
- Till rays, light patches, vignette and blob shadow stay in story 011.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 011: till rays, light patches, vignette, blob
- Story 007: environment geometry and textures

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/Feel and UI screenshots are NOT waived (CLAUDE.md: a parse check is not a run).*

**Story Type**: Visual/Feel
**Required evidence**:
- `production/qa/evidence/vfx-steam-smoke-sparks-flames-evidence.md` + retained screenshot(s) in `production/qa/evidence/` + sign-off
- Retained: screenshots (peak load, Low + Mid, day + evening, greyscale), reduced-motion capture, frame-time measurement

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003 (pilot verdict), Story 008 (kettles/till positions)
- Unlocks: Visual-pipeline 012 integration; audio-juice visual doubles
