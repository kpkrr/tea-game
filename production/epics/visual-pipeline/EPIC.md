# Epic: Visual Pipeline (Lighting, Toon Shader, Quality Tiers)

> **Layer**: Presentation
> **GDD**: design/art/art-bible.md
> **Architecture Module**: KitchenView (рендер) · материалы · уровни качества
> **Engine Risk**: HIGH
> **GDD Requirements Covered by ADRs**: 11 / 11 active
> **Status**: Ready
> **Stories**: 14 stories

## Overview

Техническая основа нового визуала из арт-библии: **перспективная камера-диорама** (поправка ADR-0002 2026-10-01), 3D-окружение с рисованными текстурами-атласами × запечённым в vertex colors светом, декорации вокруг кухни (Mid/High), VFX-пуфы, один DirectionalLight3D с тенями только от динамики через прокси, toon-шейдер для 2D-спрайтов персонажей и предметов, blob-тени, мировые оверлеи вне тумана и грейдинга, уровни качества Low/Mid/High и пре-прогрев шейдеров. **Первым делом — spike S1–S5** (стоимость теней и toon-шейдера, LightmapGI и порядок прозрачности на WebGL2, мерцание спрайтов без мипов, оверлеи вне тонмаппинга; S5 — перспективная камера: fit против `Camera3D`, stretch спрайтов, размер оверлеев у дальней стены, анизотропия, стоимость декораций/VFX, опц. tilt-shift): до них арт не производится. Заменяет code-drawn pixel art среза.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0002: Viewport, camera fit & 2.5D presentation | Явный stretch, перспективная камера-диорама (дистанция от safe_aspect, кухня ≥ 95 %; было ortho), HUD-полосы, 3D-окружение + toon-спрайты, мировые оверлеи | HIGH |
| ADR-0007: Performance & load budgets | 60/30 fps, мс на систему; таблица текущих бюджетов (2026-10-01 diorama): draw calls 140/200, census ≤ 115, текстуры ≤ 192/144 МБ, .pck ≤ 22 МБ, загрузка ≤ 32,5 МБ; уровни качества Low/Mid/High, PerfProbe | MEDIUM |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-art-001 | Презентация: 3D-окружение из простых мешей, свет и AO запечены в vertex colors (unshaded), опц. LightmapGI для пола/стен; статика ≤ 3 меша, вне теневого прохода | ADR-0002 (поправка 2026-10-01) ✅ |
| TR-art-002 | Один DirectionalLight3D; тени отбрасывают только динамические объекты через shadow-only прокси-капсулы; Omni/Spot, SSAO/SSR/SDFGI/VoxelGI, volumetric fog, runtime DOF запрещены | ADR-0002, ADR-0007 (поправка 2026-10-01) ✅ |
| TR-art-003 | Спрайты персонажей и предметов — кастомный toon spatial-шейдер (unshaded база × тонировка зоны ≤ 15 %, ramp 2 шага по псевдонормали, rim 1 dp); стандартный lit Sprite3D запрещён | ADR-0002 (поправка 2026-10-01) ✅ |
| TR-art-004 | Мировые оверлеи (жетоны, кольца, цены, контур цели, кольцо назначения) исключены из тумана и грейдинга: unshaded, disable_fog; смена «день → вечер» — светом и материалами окружения, их hex не меняется | ADR-0002 (поправка 2026-10-01) ✅ |
| TR-art-005 | Blob-тени под персонажами, чашками и кассой на всех тирах; реальные тени Mid/High поверх | ADR-0002 (поправка 2026-10-01) ✅ |
| TR-art-006 | Уровни качества Low/Mid/High выбираются статически при загрузке + ручной переключатель; Low — без реальных теней и glow | ADR-0007 (поправка 2026-10-01) ✅ |
| TR-art-007 | Бюджеты «качество важнее мегабайт»: `.pck` ≤ 11,0 МБ, загрузка ≤ 21,5 МБ (с аудио-поправкой ADR-0007), texture memory ≤ 96 МБ (спрайты персонажей без мипов), census ≤ 95, draw calls ≤ 180 вкл. теневой проход, shadow casters ≤ 12 | ADR-0007 (поправка 2026-10-01) ✅ |
| TR-art-008 | Pre-warm: toon, shadow-caster, текстурный env, декорации, VFX, fog; ≤ 1,0 с (rev. 2026-10-01) | ADR-0007 (поправка 2026-10-01) ✅ |
| TR-art-009 | Перспективная камера-диорама, stretch `1/cos α` на спрайт, минимальный экранный размер оверлеев | ADR-0002 (поправка 2026-10-01 diorama) ✅ |
| TR-art-010 | VFX-пуфы: пул ≤ 12, ниже полос оверлеев — не перекрывают жетоны | ADR-0007 (поправка 2026-10-01 diorama) ✅ |
| TR-art-011 | Декорации вокруг кухни в letterbox, вне `frame_bounds`, только Mid/High | ADR-0002, ADR-0007 (поправки 2026-10-01 diorama) ✅ |

## Port Source (vertical slice)

Логика уже проверена в `prototypes/tea-rush-vertical-slice/`. Истории переносят её в `src/`, а не пишут заново:
- `prototypes/tea-rush-vertical-slice/src/presentation/kitchen_view.gd`

## Stories

| # | Story | Type | Status | ADR | Estimate |
|---|-------|------|--------|-----|----------|
| 001 | Spike S1: shadow map + proxy casters + toon shader cost | Integration | Ready | ADR-0007 | L |
| 002 | Spike S2: vertex-color AO / LightmapGI on WebGL2 and opaque-vs-sprite sort order | Integration | Ready | ADR-0002 | M |
| 003 | Spike S3: unmipped 192x256 character sprites — shimmer while walking | Visual/Feel | Ready | ADR-0007 | S |
| 004 | Spike S4: world overlays outside fog, tonemap and colour adjustments | Visual/Feel | Ready | ADR-0002 | M |
| 005 | Toon sprite shader (unshaded base x zone tint, 2-step ramp, rim) | Visual/Feel | Ready | ADR-0002 | M |
| 006 | Hand-painted textured environment material (atlas x baked vertex color) and merged static meshes | Integration | Ready | ADR-0002 | M |
| 007 | Directional light and shadow-only proxy capsules | Integration | Ready | ADR-0002 | M |
| 008 | Blob contact shadows under characters, cups and till (all tiers) | Visual/Feel | Ready | ADR-0002 | S |
| 009 | World overlays excluded from fog and grading | Visual/Feel | Ready | ADR-0002 | M |
| 010 | Quality tiers Low/Mid/High: detection and manual switch | Integration | Ready | ADR-0007 | M |
| 011 | Shader pre-warm for toon, shadow-caster, env material and fog variants | Integration | Ready | ADR-0007 | M |
| 012 | Greybox kitchen scene hooked to KitchenLayout data + budget census | Integration | Ready | ADR-0002 | L |
| 013 | [Spike S5: perspective diorama camera — fit vs Camera3D, sprite stretch, overlay size, anisotropy, scenery/VFX cost, tilt-shift](story-013-spike-s5-perspective-diorama-camera.md) | Integration | Ready | ADR-0002, ADR-0007 | M |
| 014 | [VFX puffs: pooled flipbook quads (steam, smoke, sparks, fire glow) below overlay bands](story-014-vfx-puffs-pool.md) | Visual/Feel | Ready | ADR-0007 | M |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/art/art-bible.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/story-readiness production/epics/visual-pipeline/story-001-*.md`, then `/dev-story`.
