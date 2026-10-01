# Epic: Difficulty Curve & Session Pacing

> **Layer**: Feature
> **GDD**: design/gdd/difficulty-curve-session-pacing.md
> **Architecture Module**: DifficultyCurve
> **Engine Risk**: LOW
> **GDD Requirements Covered by ADRs**: 11 / 11 active
> **Status**: Ready
> **Stories**: 6 stories

## Overview

Чистые функции от игрового времени `t`: гостей в минуту 15→18, терпение 50→25 с, доля сложных заказов 0→0,40 по ease-in за 3 минуты, потом плато. Без состояния, детерминированно, с валидацией при загрузке. Открытый вопрос баланса `medium_share_of_remaining` 0,5→0,75 закрывается здесь после подтверждения владельца.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0004: Data config & load-time validation | GameConfig + подресурсы .tres, ConfigValidator собирает все ошибки, RNG инъекцией | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-pacing-001 | `progress = clamp(t/180, 0, 1)^2,0` | ADR-0004 ✅ |
| TR-pacing-002 | Три кривые (гостей/мин 15→18, терпение 50→25, доля сложных 0→0,40) | ADR-0004 ✅ |
| TR-pacing-003 | Чистые функции от `t` (без учёта паузы), одинаковые для всех игроков | ADR-0003 ✅ |
| TR-pacing-004 | Без состояния; `t` передаётся аргументом | ADR-0003 ✅ |
| TR-pacing-005 | Онбординг применяет Guest AI, а не кривые | ADR-0004 ✅ |
| TR-pacing-006 | При `t ≥ ramp_duration` — плато на `_end` | ADR-0003 ✅ |
| TR-pacing-007 | Касса — не вход для кривых | ADR-0003 ✅ |
| TR-pacing-008 | Валидация при загрузке (диапазоны, NaN, `_end` не легче `_start`) | ADR-0004 ✅ |
| TR-pacing-009 | Детерминизм: побитово равные результаты | ADR-0004 ✅ |
| TR-pacing-010 | `t` сбрасывается по `match_started` | ADR-0003 ✅ |
| TR-pacing-011 | `guests_per_minute_start` = 15,0 синхронизирован с Guest AI | ADR-0004 ✅ |

## Port Source (vertical slice)

Логика уже проверена в `prototypes/tea-rush-vertical-slice/`. Истории переносят её в `src/`, а не пишут заново:
- `prototypes/tea-rush-vertical-slice/src/feature/difficulty_curve.gd`
- `prototypes/tea-rush-vertical-slice/src/foundation/config/difficulty_config.gd`

## Stories

| # | Story | Type | Status | ADR | Estimate |
|---|-------|------|--------|-----|----------|
| 001 | DifficultyConfig: ресурс и валидация при загрузке | Logic | Ready | ADR-0004 | S |
| 002 | DifficultyCurve: progress и три кривые | Logic | Ready | ADR-0004 | M |
| 003 | Чистота, отсутствие состояния и детерминизм кривых | Logic | Ready | ADR-0003 | S |
| 004 | Контракт с Guest AI: значения при спавне, онбординг, сброс t | Integration | Ready | ADR-0004 | M |
| 005 | Sync medium_share_of_remaining после плейтеста владельца | Config/Data | Blocked | ADR-0004 | S |
| 006 | Плейтест темпа: ≤ X потерь до t = 120, заметность смены заказов | Visual/Feel | Blocked | ADR-0004 | M |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/difficulty-curve-session-pacing.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories difficulty-curve` to break this epic into implementable stories.
