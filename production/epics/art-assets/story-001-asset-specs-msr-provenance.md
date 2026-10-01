# Story 001: Style frame (ref-01 → tea-house diorama), asset specs and Master Style Reference

> **Epic**: Art Assets (MVP content)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Visual/Feel
> **Estimate**: L
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: 2026-10-01 (art direction revised: art bible A8–A12, reference ref-01)

## Context

**GDD**: `design/art/art-bible.md`
**Requirement**: art-bible A8–A12, §8.8 (items 0–6), §5, §6, §7.3, §9 (ref-01); ADR-0007
*(Requirement text lives in `docs/architecture/tr-registry.yaml` / art bible — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: Performance & load budgets; ADR-0002: Viewport, camera fit & 2.5D presentation
**ADR Decision Summary**: Budgets bound all art; the art bible §8.8 pipeline requires an owner-approved **style frame** (our tea-house version of ref-01) and then an approved MSR before any production generation.
**ADR Version**: ADR-0007 2026-09-30, ADR-0002 2026-09-30 *(both being amended for A8–A12: perspective camera, texture/.pck/tris needs — read the current versions)*

**Engine**: Godot 4.7.2 (Compatibility / WebGL2) | **Risk**: HIGH
**Engine Notes**: Godot 4.7 is post-cutoff; check docs/engine-reference/godot/modules/rendering.md (Compatibility: depth prepass off on PowerVR/Mali/Adreno/Apple, render_priority orders transparent only, scaling_3d_scale adds an internal buffer + blit). Anything not verified there is UNVERIFIED — measure, do not assume.

**Control Manifest Rules (this layer)** *(no manifest — derived from the ADRs)*:
- Required (from ADR-0007): RGBA8 textures without VRAM compression (lossy WebP allowed only for hand-painted environment textures, art bible §8.1); side <= 2048 px; character atlases imported without mipmaps (others with); one constants file holds the texture / .pck thresholds
- Required (from ADR-0002): sprites upright, pivot at feet; environment = GLB with baked vertex color × hand-painted atlas texture; 2D layer has outline, 3D layer has none
- Guardrail (from ADR-0007 + art bible §8.5 art need): texture memory ≈ 150 MB (requested limit ≈ 160), .pck ≈ 11.3–13.8 MB (requested ≈ 14), scene ≤ 30k tris — limits per the amended ADR-0007; if exceeded raise the budget by ADR amendment (art bible A7), do not cut frames

---

## Acceptance Criteria

*From `design/art/art-bible.md` (revision 2026-10-01, A8–A12), scoped to this story:*

- [ ] **Style frame first (deliverable #1, gates everything else):** using `design/art/references/ref-01-cozy-diorama-kitchen.png` as the model's image reference and master prompt §8.8-3a, produce a **portrait (9:19.5) frame of OUR game**: cozy tea-house terrace diorama with the fixed perspective camera look (≈ 52° pitch, narrow FOV), stone-tile walkways, thick wooden counters, 7 stations incl. two kettles on hearths with small flames, leaf jars, lemon, cup stack, the Till (brightest warm object), chibi barista + 2–3 chibi guests in the queue, dense cozy clutter only at the periphery, river/cliffs around the edges, steam puffs. Hand-corrected so recipe-step colours and Till Gold match §4 and nothing from the "do not take" list of §9 ref-01 remains (chef hats, tomatoes/red produce on counters, red banners, turquoise water, big flames over the play area)
- [ ] Style frame passes the readability checks on the image itself: greyscale + 2 dp blur separates characters, cup/tokens and till from the background; clutter does not touch walkways, slots, queue points; **owner approval recorded (date + chosen iteration) before the MSR and before story 003 starts**; stored in `art-source/style-frame/` with provenance
- [ ] `/asset-spec` run for barista, 4 guests, environment (architecture, clutter, surroundings, water), props, VFX, UI set; specs + the §8.8 master prompts (EN) saved under `design/art/specs/` (one file per asset group) with sizes, pivots, frame counts, texel density (§8.5) and budget per asset
- [ ] Master Style Reference sheet (chibi barista + 2 guests turnarounds, cup, till, token, swatches, outline sample, 3–4 hand-painted material samples — stone, plank, sack, clay —, do/don't column) hand-cleaned, matches the approved style frame and is approved by the owner; stored in `art-source/msr/` with provenance entry
- [ ] `art-source/provenance.yaml` schema created (path, tool+model version, date, prompt, seed, input refs, cleaner, licence snapshot, hash); **first entry is ref-01 itself** (generating tool + commercial-use terms); rule 'no entry = no asset in build' documented

---

## Implementation Notes

- Order is fixed: ref-01 provenance → style frame → owner approval → specs → MSR. No other generation before the style frame is approved.
- ref-01 is the only image allowed as model input (owner-generated); third-party game screenshots stay human-only; no artist or game names in prompts (art bible §8.8 item 2).
- Model version and seed fixed per project; record them before generating anything else.
- Style frame is a concept image, not an in-engine render; the in-engine match is checked in story 003.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: import tooling
- Story 003: pilot production

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/Feel and UI screenshots are NOT waived (CLAUDE.md: a parse check is not a run).*

**Story Type**: Visual/Feel
**Required evidence**:
- `production/qa/evidence/asset-specs-msr-provenance-evidence.md` + retained images in `production/qa/evidence/` + sign-off
- Retained: approved style frame (+ its greyscale/blur check) and MSR image + spec index in `production/qa/evidence/aa-msr-evidence.md`; owner approval of both noted with dates

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: Stories 002, 003
