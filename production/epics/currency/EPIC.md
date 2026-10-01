# Epic: Currency: Coins & Score

> **Layer**: Feature
> **GDD**: design/gdd/currency-coins-score.md
> **Architecture Module**: Currency
> **Engine Risk**: HIGH
> **GDD Requirements Covered by ADRs**: 14 / 14 active
> **Status**: Ready
> **Stories**: 6 stories

## Overview

Две независимые метрики: монеты = цена напитка (идут в кассу), очки = цена × 10 × (1 + доля оставшегося терпения), идут всегда. `match_score`, `best_score` с сохранением, `is_new_record` и одноразовый `record_passed` для NEW BEST! посреди партии.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0003: Match simulation — clock, tick order, pause | GameClock + MatchDirector, фиксированный порядок тика, без SceneTree.paused, типизированные сигналы, DI через корень композиции | LOW |
| ADR-0004: Data config & load-time validation | GameConfig + подресурсы .tres, ConfigValidator собирает все ошибки, RNG инъекцией | LOW |
| ADR-0005: Local persistence (SaveStore) | JSON-блоб с schema_version, scope(owner), localStorage на web / user:// на desktop, шов под бэкенд | HIGH |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-currency-001 | `coins_earned = recipe_price` | ADR-0003 ✅ |
| TR-currency-002 | `score_earned = round_half_up(price × 10 × (1 + rf))` | ADR-0003 ✅ |
| TR-currency-003 | `score_multiplier_base` = 10 — данные | ADR-0004 ✅ |
| TR-currency-004 | `match_score`: Idle → Accumulating → Frozen | ADR-0003 ✅ |
| TR-currency-005 | `match_score = 0` на `match_started` | ADR-0003 ✅ |
| TR-currency-006 | `best_score` сохраняется локально и никогда не уменьшается | ADR-0005 ✅ |
| TR-currency-007 | `is_new_record` вычисляется на `match_ended` до обновления `best_score` | ADR-0003 ✅ |
| TR-currency-008 | `is_new_record = false` на `match_started` | ADR-0003 ✅ |
| TR-currency-009 | `best_score := match_score` только при `is_new_record` | ADR-0005, ADR-0003 ✅ |
| TR-currency-010 | Монеты и очки не зависят от состояния кассы | ADR-0003 ✅ |
| TR-currency-011 | Нет трат монет и конвертации монеты↔очки | ADR-0003 ✅ |
| TR-currency-012 | Единственный триггер — `served(recipe_id, rf)` | ADR-0003 ✅ |
| TR-currency-013 | Несколько подач в одном тике — порядок не важен | ADR-0003 ✅ |
| TR-flow-022 | NEW BEST! в партии: один раз, только при рекорде на старте > 0, по `Currency.record_passed` (M11) | ADR-0003 ✅ |

## Port Source (vertical slice)

Логика уже проверена в `prototypes/tea-rush-vertical-slice/`. Истории переносят её в `src/`, а не пишут заново:
- `prototypes/tea-rush-vertical-slice/src/feature/currency.gd`
- `prototypes/tea-rush-vertical-slice/src/foundation/config/currency_config.gd`

## Stories

| # | Story | Type | Status | ADR | Estimate |
|---|-------|------|--------|-----|----------|
| 001 | [Формулы очков и монет + CurrencyConfig](story-001-score-coins-formulas.md) | Logic | Ready | ADR-0004 | S |
| 002 | [Обработка Served: независимые coins/score сигналы](story-002-served-handling.md) | Logic | Ready | ADR-0003 | S |
| 003 | [match_score: Idle → Accumulating → Frozen](story-003-match-score-states.md) | Logic | Ready | ADR-0003 | S |
| 004 | [best_score, is_new_record и локальное сохранение](story-004-best-score-persistence.md) | Integration | Ready | ADR-0005 | M |
| 005 | [Событие record_passed — NEW BEST! в партии](story-005-record-passed.md) | Logic | Ready | ADR-0003 | S |
| 006 | [Интеграция: цепочка Served → Currency → Till и порядок match_ended](story-006-currency-till-chain-integration.md) | Integration | Ready | ADR-0003 | M |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/currency-coins-score.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Stories созданы — далее `/story-readiness` и `/dev-story` по файлам `story-NNN-*.md`.
