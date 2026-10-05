# Epic: Art Assets (MVP content)

> **Layer**: Presentation
> **GDD**: design/art/art-bible.md
> **Architecture Module**: assets/art/* (контент для KitchenView, HUD, GameFlow)
> **Engine Risk**: HIGH
> **GDD Requirements Covered by ADRs**: 0 / 0 active
> **Status**: Ready
> **Stories**: 13 stories
> **Last Updated**: 2026-10-01 — направление арта пересмотрено владельцем по референсу ref-01 (art bible A8–A12)

## Overview

Производство арта MVP по арт-библии (AI-генерация + доработка) в направлении **«уютная чайная-диорама»** (art bible A8–A12, главный референс `design/art/references/ref-01-cozy-diorama-kitchen.png`). **Первый ассет — style frame**: кадр нашей чайной в портрете, сгенерированный по ref-01 и утверждённый владельцем до MSR и пилота (story 001). Дальше: бариста и 4 архетипа гостей — 2D-спрайты **ровно в стиле style frame v1-a** (коренастые мультяшные «3D-игрушечные», крупная голова, короткое тело; решение 2026-10-01, art bible §5 / §8.8 п. 6a), ячейки 192×256, 2 диагонали + зеркало (решение 2026-10-01); коренастое 3D-окружение террасы-диорамы с **рисованными текстурами** (каменная плитка, доски, тумбы-очаги, периферийный клаттер — ящики, мешки с чаем, глиняные чайники, фонари, верёвки) и **окрестностями диорамы** (скалы, вода) за краями кухни; тёплый свет «золотой полдень → вечер при фонарях»; 2D-предметы станций, чашки и жетоны (цвета шагов не меняются); **мультяшные VFX** — пар, дым, пуфы, искры, огоньки под чайниками (story 013); UI-скин полос HUD и экранов меню, иконки, деревянная вывеска-логотип. Камера — фиксированная перспектива-диорама (FOV ≈ 30°, наклон ≈ 52°). Пилот — бариста, станция-очаг и угол диорамы до полного производства. Спеки ассетов — через `/asset-spec`. Бюджеты — потребность арта в art bible §8.5 (текстуры ≈ 150 МБ, `.pck` ≈ 11,3–13,8 МБ, ≤ 30 k △), лимиты — см. ADR-0007 (поправка technical-director).

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0002: Viewport, camera fit & 2.5D presentation | Явный stretch, перспективная камера-диорама (FOV 30°, наклон 52°, поправка 2026-10-01) от safe_aspect (кухня ≥ 95 %), HUD-полосы, 3D-окружение + toon-спрайты, мировые оверлеи. **A12 требует перспективную камеру (FOV ≈ 30°, наклон ≈ 52°) — ждёт поправки ADR-0002** | HIGH |
| ADR-0007: Performance & load budgets | 60/30 fps, мс на систему, draw calls ≤ 180, .pck ≤ 11 МБ, загрузка ≤ 21,5 МБ, уровни качества Low/Mid/High, PerfProbe | MEDIUM |

## GDD Requirements

Нет TR-ID: эпик контентный. Источник требований — `design/art/art-bible.md` (секции стиля, персонажей, окружения, UI) и бюджеты ADR-0007.

## Port Source (vertical slice)

Логика уже проверена в `prototypes/tea-rush-vertical-slice/`. Истории переносят её в `src/`, а не пишут заново:
- `prototypes/tea-rush-vertical-slice/src/presentation/pixel_art.gd (заменяется)`

## Stories

| # | Story | Type | Status | ADR | Estimate |
|---|-------|------|--------|-----|----------|
| 001 | Style frame (ref-01 → tea-house diorama), asset specs and Master Style Reference | Visual/Feel | Ready | ADR-0007 | L |
| 002 | Import pipeline: folders, presets and asset validation script | Logic | Ready | ADR-0007 | M |
| 003 | PILOT: chibi barista sprite set + one hearth station + a textured diorama corner through the full pipeline | Visual/Feel | Ready | ADR-0002 | L |
| 004 | Barista full animation set and atlases | Visual/Feel | Ready | ADR-0002 | L |
| 005 | Guest archetypes: Clerk and Student | Visual/Feel | Ready | ADR-0002 | L |
| 006 | Guest archetypes: Neighbour and Schoolkid | Visual/Feel | Ready | ADR-0002 | L |
| 007 | Environment set: tea-house diorama terrace, counters, station bases, periphery clutter and surroundings | Visual/Feel | Ready | ADR-0002 | L |
| 008 | Station 2D items: kettles, leaf jars, lemon, cup stack, bin, till | Visual/Feel | Ready | ADR-0002 | L |
| 009 | Props: cup states (incl. ruined), lemon, leaves, step tokens | Visual/Feel | Ready | ADR-0002 | M |
| 010 | UI skin: HUD strips, panels, buttons and icon set | UI | Ready | ADR-0002 | L |
| 011 | Logo, carved wooden menu sign with lanterns, menu art, light/FX quads and share card | Visual/Feel | Ready | ADR-0002 | M |
| 012 | Asset audit against budgets and naming | Config/Data | Ready | ADR-0007 | M |
| 013 | VFX flipbook set: steam and smoke puffs, dust poofs, sparks, kettle flames | Visual/Feel | Ready | ADR-0002 | M |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/art/art-bible.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/story-readiness production/epics/art-assets/story-001-*.md`, then `/dev-story`.
