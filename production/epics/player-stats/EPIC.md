# Epic: Player Stats

> **Layer**: Feature
> **GDD**: design/gdd/player-stats.md
> **Architecture Module**: PlayerStats
> **Engine Risk**: HIGH
> **GDD Requirements Covered by ADRs**: 1 / 1 active
> **Status**: Ready
> **Stories**: 6 stories

## Overview

Локальная статистика для экрана Records и меню: сыгранные смены, поданные чашки, дни с полной кассой, 5 последних смен, серия дней подряд и лучшая серия. Только пишет и читает свой scope `stats`, на партию не влияет. Нового кода в срезе нет — пишется с нуля, через TDD.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0005: Local persistence (SaveStore) | JSON-блоб с schema_version, scope(owner), localStorage на web / user:// на desktop, шов под бэкенд | HIGH |
| ADR-0003: Match simulation — clock, tick order, pause | GameClock + MatchDirector, фиксированный порядок тика, без SceneTree.paused, типизированные сигналы, DI через корень композиции | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-flow-025 | Серия дней: `day_index` по `daily_reset_time_utc`, рост на Open→Full, сгоревшая серия показывается 0 (M14) | ADR-0005 ✅ |

## Port Source (vertical slice)

В срезе нет — пишется с нуля.

## Stories

| # | Story | Type | Status | ADR | Estimate |
|---|-------|------|--------|-----|----------|
| 001 | [PlayerStats: ключи stats.*, загрузка и валидация recent](story-001-stats-scope-persistence.md) | Logic | Ready | ADR-0005 | M |
| 002 | [Счётчики смен и чашек](story-002-stats-shift-cup-counters.md) | Logic | Ready | ADR-0005 | S |
| 003 | [Список последних смен (recent)](story-003-stats-recent-shifts.md) | Logic | Ready | ADR-0005 | S |
| 004 | [Серия дней, days_filled и флаг streak_grew](story-004-stats-streak-days-filled.md) | Logic | Ready | ADR-0005 | M |
| 005 | [displayed_streak и часы назад](story-005-stats-displayed-streak.md) | Logic | Ready | ADR-0005 | S |
| 006 | [Интеграция: порядок match_ended и сохранение статистики](story-006-stats-integration-persistence.md) | Integration | Ready | ADR-0005 | M |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/player-stats.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Stories созданы — далее `/story-readiness` и `/dev-story` по файлам `story-NNN-*.md`.
