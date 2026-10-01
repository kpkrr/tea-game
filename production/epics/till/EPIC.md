# Epic: Till & Day Cycle

> **Layer**: Feature
> **GDD**: design/gdd/till-day-cycle.md
> **Architecture Module**: Till
> **Engine Risk**: HIGH
> **GDD Requirements Covered by ADRs**: 13 / 13 active
> **Status**: Ready
> **Stories**: 6 stories

## Overview

Касса как физический предмет: вместимость, заполнение, Open→Full с `day_filled`, сохранение между запусками и сброс в 00:00 UTC (проверка только на старте матча и холодном старте). Полная касса не блокирует игру: монеты перестают идти, очки идут. Значение `till_capacity` (250 или ~400) ждёт замеров владельца.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0003: Match simulation — clock, tick order, pause | GameClock + MatchDirector, фиксированный порядок тика, без SceneTree.paused, типизированные сигналы, DI через корень композиции | LOW |
| ADR-0004: Data config & load-time validation | GameConfig + подресурсы .tres, ConfigValidator собирает все ошибки, RNG инъекцией | LOW |
| ADR-0005: Local persistence (SaveStore) | JSON-блоб с schema_version, scope(owner), localStorage на web / user:// на desktop, шов под бэкенд | HIGH |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-till-001 | `till_amount` ∈ [0, 250], `till_capacity` = 250, Open/Full, `full_since_utc` | ADR-0004 ✅ |
| TR-till-002 | `coins_added = min(amount + coins, cap) − amount`, эмитится всегда (включая 0) | ADR-0003 ✅ |
| TR-till-003 | Open→Full в том же тике, когда касса заполнилась | ADR-0003 ✅ |
| TR-till-004 | Full не блокирует матчи | ADR-0003 ✅ |
| TR-till-005 | При переходе в Full сохраняется `full_since_utc` | ADR-0005 ✅ |
| TR-till-006 | `daily_reset_time_utc` = 00:00 UTC | ADR-0004 ✅ |
| TR-till-007 | Проверка сброса только на `match_started` и холодном старте | ADR-0003 ✅ |
| TR-till-008 | Сброс: amount = 0, `full_since_utc` очищается | ADR-0003 ✅ |
| TR-till-009 | `till_amount` переживает перезапуск | ADR-0005 ✅ |
| TR-till-010 | Незаполненная касса не сбрасывается | ADR-0003 ✅ |
| TR-till-011 | Несколько пропущенных полуночей → ровно один сброс | ADR-0005 ✅ |
| TR-till-012 | Подкрутка часов устройства — принятый риск MVP | ADR-0001, ADR-0005 (принятый риск) ✅ |
| TR-till-013 | Till не трогает score | ADR-0003 ✅ |

## Port Source (vertical slice)

Логика уже проверена в `prototypes/tea-rush-vertical-slice/`. Истории переносят её в `src/`, а не пишут заново:
- `prototypes/tea-rush-vertical-slice/src/feature/till.gd`
- `prototypes/tea-rush-vertical-slice/src/foundation/config/till_config.gd`

## Stories

| # | Story | Type | Status | ADR | Estimate |
|---|-------|------|--------|-----|----------|
| 001 | [TillConfig и правила валидатора](story-001-till-config.md) | Logic | Ready | ADR-0004 | S |
| 002 | [Накопление кассы и coins_added](story-002-till-accumulation.md) | Logic | Ready | ADR-0003 | S |
| 003 | [Переход Open→Full, day_filled и day_index](story-003-till-full-day-filled.md) | Logic | Ready | ADR-0003 | M |
| 004 | [Дневной сброс: проверка на match_started/холодном старте/меню](story-004-till-daily-reset.md) | Logic | Ready | ADR-0003 | M |
| 005 | [Сохранение кассы между запусками](story-005-till-persistence.md) | Integration | Ready | ADR-0005 | M |
| 006 | [Set till_capacity after owner measurements](story-006-set-till-capacity.md) | Config/Data | Blocked (reason: owner playtest — замеры скорости игрока ещё не получены) | ADR-0004 | S |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/till-day-cycle.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Stories созданы — далее `/story-readiness` и `/dev-story` по файлам `story-NNN-*.md`.
