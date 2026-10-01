# Story 014: VFX puffs: pooled flipbook quads (steam, smoke, sparks, fire glow) below overlay bands

> **Epic**: Visual Pipeline (Lighting, Toon Shader, Quality Tiers)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Visual/Feel
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: 2026-10-01

## Context

**GDD**: `design/art/art-bible.md`, `design/gdd/audio-juice-feedback.md`
**Requirement**: TR-art-010, TR-art-007
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: Performance & load budgets (Amendment 2026-10-01 "diorama"); ADR-0002 §5 (overlay bands)
**ADR Decision Summary**: Cartoon VFX puffs are flipbook frames from one 2048×1024 atlas, drawn by a pool of ≤ 12 camera-facing quads (or one `CPUParticles3D` per emitter type if cheaper — one draw call each); GPU particles forbidden; alpha/additive materials with `render_priority` below every overlay band, so a puff never covers a token, ring, price, tag or target outline; none wider than 25 % of `kitchen_rect`.
**ADR Version**: ADR-0007 2026-10-01

**Engine**: Godot 4.7.2 (Compatibility / WebGL2) | **Risk**: MEDIUM
**Engine Notes**: `render_priority` orders transparent geometry only (`modules/rendering.md`); `CPUParticles3D` draw cost in Compatibility — проверить в 4.7.2.

**Control Manifest Rules (this layer)** *(no manifest — derived from the ADRs)*:
- Required (from ADR-0002): exactly one DirectionalLight3D; shadows only from dynamic proxies (SHADOWS_ONLY capsules); sprites use the project toon shader; overlays unshaded + disable_fog; static env = unshaded hand-painted atlas x baked vertex color, merged to <= 5 kitchen meshes (+ <= 6 scenery, Mid/High) outside the shadow pass; perspective diorama camera (ADR-0002 amendment 2026-10-01)
- Forbidden (from ADR-0002/0007): stock lit Sprite3D, Omni/Spot lights, SSAO/SSIL/SSR/SDFGI/VoxelGI, volumetric fog, runtime DOF, Compositor / screen_texture post-processing, global Environment.adjustment_* tint over overlays, MSAA, GPU particles, CanvasItem line primitives for rings
- Guardrail (from ADR-0007, effective-budget table 2026-10-01): draw calls target <= 140 / ceiling 200 incl. shadow pass; census <= 115; shadow casters <= 12; kitchen env <= 30k tris, scenery <= 20k; texture memory <= 192 MB Mid/High / 144 MB Low; .pck <= 22.0 MB; VFX pool <= 12; pre-warm <= 1.0 s; thresholds live in one constants/data file, not literals

---

## Acceptance Criteria

- [ ] `VfxPool` (presentation, no gameplay state) with ≤ `vfx_pool_max` (12, data) quads; requests over the cap drop the oldest lowest-priority puff; emitters: kettle steam, fire glow flicker under kettles, smoke on burnt/trash, sparks on serve (event map owned by audio-juice/hud; this story provides the API `play(kind, world_pos)`)
- [ ] Materials alpha-blended or additive, unshaded, `render_priority` in the world band; integration test: with a puff spawned over a Waiting guest's token, the token's pixels on a screenshot are unchanged (overlay draws on top) — retained screenshot
- [ ] Puffs advance on `GameClock` `sim_dt`/`ui_dt` (freeze on pause), never `Tween`; reduced motion → first frame or hidden
- [ ] Census test counts the full pool; draw calls stay ≤ 200 in the worst-case frame; materials registered in pre-warm (story 011)

---

## Implementation Notes

- Art (frames, atlas) comes from art-assets; until then placeholder puffs. Width cap: quad world size × `ViewFitMath.dp_per_metre` ≤ 0.25 × `kitchen_rect.size.x` at the emitter anchor.
- Pick sprites vs `CPUParticles3D` by spike S5's numbers (story 013).

---

## Out of Scope

- Final VFX art (art-assets); sound of the same events (audio-juice)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**:
- `production/qa/evidence/vfx-puffs-pool-evidence.md` + retained screenshots (puff over token, full pool) + lead sign-off; `tests/integration/visual_pipeline/vfx_pool_test.gd` for cap/eviction/pause

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 013 (S5 cost), Story 009 (overlay bands), Story 011 (pre-warm registration)
- Unlocks: hud/audio-juice event wiring of puffs
