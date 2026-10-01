# Epic: Brewing & Crafting

> **Layer**: Feature
> **GDD**: design/gdd/brewing-crafting-mechanic.md
> **Architecture Module**: Brewing
> **Engine Risk**: LOW
> **GDD Requirements Covered by ADRs**: 12 / 12 active
> **Status**: Ready
> **Stories**: 8 stories

## Overview

Одна чашка в руках, 2 независимых чайника EMPTY→BREWING→READY с таймером на игровом времени, мгновенные станции, 7 слотов с безусловным обменом, испорченная чашка и мусорка (отклонение от GDD, решение владельца по срезу). Ответы EXECUTE/WAIT/REFUSE для BaristaController и `consume_held_cup()` ровно один раз на подачу.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0003: Match simulation — clock, tick order, pause | GameClock + MatchDirector, фиксированный порядок тика, без SceneTree.paused, типизированные сигналы, DI через корень композиции | LOW |
| ADR-0004: Data config & load-time validation | GameConfig + подресурсы .tres, ConfigValidator собирает все ошибки, RNG инъекцией | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-brewing-001 | Чашка `{steps, ruined}`; `held_cup` — максимум одна | ADR-0003 ✅ |
| TR-brewing-002 | 2 независимых чайника: EMPTY → BREWING → READY → EMPTY | ADR-0003 ✅ |
| TR-brewing-003 | `t_brew = 3,0 / speed_multiplier` | ADR-0004 ✅ |
| TR-brewing-004 | Мгновенные станции: выполнить или отказать в том же тике | ADR-0003 ✅ |
| TR-brewing-005 | Таблица ответов чайника: 12 комбинаций | ADR-0003 ✅ |
| TR-brewing-006 | WRONG_TEMP на пустом чайнике → `ruined = true`, чайник остаётся пустым | ADR-0003 ✅ |
| TR-brewing-007 | 7 слотов EMPTY/HOLDING, безусловный обмен | ADR-0003 ✅ |
| TR-brewing-008 | `consume_held_cup()` — ровно один раз на подачу | ADR-0003 ✅ |
| TR-brewing-009 | Таймер чайника идёт в фоне каждый кадр симуляции | ADR-0003 ✅ |
| TR-brewing-011 | `match_started` сбрасывает чайники, слоты и `held_cup` | ADR-0003 ✅ |
| TR-brewing-012 | Повторное добавление воды = OTHER (отказ), а не WRONG_TEMP | ADR-0003 ✅ |
| TR-brewing-013 | `speed_multiplier` — данные; в MVP 1,0 | ADR-0004 ✅ |

## Port Source (vertical slice)

Логика уже проверена в `prototypes/tea-rush-vertical-slice/`. Истории переносят её в `src/`, а не пишут заново:
- `prototypes/tea-rush-vertical-slice/src/feature/brewing.gd`
- `prototypes/tea-rush-vertical-slice/src/foundation/config/brewing_config.gd`

## Stories

| # | Story | Type | Status | ADR | Estimate |
|---|-------|------|--------|-----|----------|
| 001 | [Brewing: каркас, Cup, BrewingConfig и t_brew](story-001-brewing-core-config.md) | Logic | Ready | ADR-0003 | M |
| 002 | [Мгновенные станции: выдача чашек и ингредиенты](story-002-brewing-instant-stations.md) | Logic | Ready | ADR-0003 | M |
| 003 | [Чайники: состояния EMPTY/BREWING/READY и таблица ответов](story-003-brewing-kettle-state-machine.md) | Logic | Ready | ADR-0003 | L |
| 004 | [Фоновые таймеры чайников на игровом времени](story-004-brewing-background-timers.md) | Logic | Ready | ADR-0003 | M |
| 005 | [Слоты (безусловный обмен) и мусорка](story-005-brewing-slots-trash.md) | Logic | Ready | ADR-0003 | M |
| 006 | [consume_held_cup: подача очищает руки ровно один раз](story-006-brewing-serve-consume.md) | Logic | Ready | ADR-0003 | S |
| 007 | [Сброс Brewing на match_started](story-007-brewing-match-reset.md) | Logic | Ready | ADR-0003 | S |
| 008 | [Интеграция: Brewing + RecipeBook + BaristaController + GameClock](story-008-brewing-integration.md) | Integration | Ready | ADR-0003 | M |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/brewing-crafting-mechanic.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/story-readiness production/epics/brewing/story-001-*.md`, затем `/dev-story`.
