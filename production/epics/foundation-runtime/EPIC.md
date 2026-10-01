# Epic: Foundation Runtime (Clock, Director, Config, Save)

> **Layer**: Foundation
> **GDD**: —  (инфраструктура из ADR-0003/0004/0005; обслуживает все GDD)
> **Architecture Module**: GameClock · MatchDirector · ConfigLoader · SaveStore · UtcClock · Rng
> **Engine Risk**: HIGH
> **GDD Requirements Covered by ADRs**: 3 / 3 active
> **Status**: Ready
> **Stories**: 9 stories

## Overview

Скелет, на котором стоит каждая партия: игровые часы с паузой и clamp шага, фиксированный порядок тика в MatchDirector и корень композиции (DI), загрузка и валидация всего тюнинга из `.tres` с полным списком ошибок, локальное сохранение с версией схемы и UTC-часы для дневного сброса. Код переносится из вертикального среза, приводится к стандартам (doc-комментарии, статическая типизация) и покрывается unit-тестами. Требований GDD здесь мало: модуль задан ADR, а не отдельной механикой.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0003: Match simulation — clock, tick order, pause | GameClock + MatchDirector, фиксированный порядок тика, без SceneTree.paused, типизированные сигналы, DI через корень композиции | LOW |
| ADR-0004: Data config & load-time validation | GameConfig + подресурсы .tres, ConfigValidator собирает все ошибки, RNG инъекцией | LOW |
| ADR-0005: Local persistence (SaveStore) | JSON-блоб с schema_version, scope(owner), localStorage на web / user:// на desktop, шов под бэкенд | HIGH |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-guest-016 | `max_step_delta` = 0,25 с | ADR-0003 ✅ |
| TR-brewing-010 | Таймеры на игровом времени с clamp `max_step_delta` = 0,25 с | ADR-0003 ✅ |
| TR-flow-027 | Новые ключи SaveStore аддитивны, `schema_version` = 1; `stats.recent` — валидируемая JSON-строка | ADR-0005 ✅ |

## Port Source (vertical slice)

Логика уже проверена в `prototypes/tea-rush-vertical-slice/`. Истории переносят её в `src/`, а не пишут заново:
- `prototypes/tea-rush-vertical-slice/src/foundation/game_clock.gd`
- `prototypes/tea-rush-vertical-slice/src/foundation/config/*`
- `prototypes/tea-rush-vertical-slice/src/foundation/save_store.gd`
- `prototypes/tea-rush-vertical-slice/src/foundation/save_backends.gd`
- `prototypes/tea-rush-vertical-slice/src/foundation/utc_clock.gd`
- `prototypes/tea-rush-vertical-slice/src/foundation/rng.gd`
- `prototypes/tea-rush-vertical-slice/src/feature/match_director.gd`

## Stories

| # | Story | Type | Status | ADR | Estimate |
|---|-------|------|--------|-----|----------|
| 001 | [GameClock: игровое время, пауза и clamp шага](story-001-game-clock.md) | Logic | Ready | ADR-0003 | S |
| 002 | [GameConfig, подресурсы и ConfigLoader + ConfigFactory](story-002-game-config-loader.md) | Logic | Ready | ADR-0004 | M |
| 003 | [ConfigValidator: все ошибки списком](story-003-config-validator.md) | Logic | Ready | ADR-0004 | M |
| 004 | [Shipped game_config.tres: CI-проверка](story-004-shipped-config-validation.md) | Integration | Ready | ADR-0004 | S |
| 005 | [Rng и UtcClock](story-005-rng-utc-clock.md) | Logic | Ready | ADR-0004 | S |
| 006 | [SaveStore + SaveScope: схема v1](story-006-save-store-core.md) | Logic | Ready | ADR-0005 | M |
| 007 | [Save backends: Memory, File, WebStorage](story-007-save-backends.md) | Integration | Ready | ADR-0005 | M |
| 008 | [MatchDirector: порядок тика, корень композиции](story-008-match-director-tick-order.md) | Integration | Ready | ADR-0003 | L |
| 009 | [MatchDirector: Booting, fail_boot, dispose](story-009-match-director-boot-dispose.md) | Integration | Ready | ADR-0003 | M |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All governing-ADR constraints are verified by tests
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/story-readiness production/epics/foundation-runtime/story-001-game-clock.md`, затем `/dev-story`.
