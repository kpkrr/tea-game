# Story 006: Интеграция: цепочка Served → Currency → Till и порядок match_ended

> **Epic**: Currency: Coins & Score
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/currency-coins-score.md`
**Requirement**: `TR-currency-010`, `TR-currency-012`, `TR-currency-013`, `TR-flow-022`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Match simulation — clock, tick order, pause
**ADR Decision Summary**: Весь матч ведёт один `MatchDirector._process` в фиксированном порядке тика; модули — `RefCounted`, общаются типизированными синхронными сигналами, соединёнными только в `_compose()`; `SceneTree.paused` не используется.
**ADR Version**: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: Post-cutoff APIs: нет. Типизированные сигналы на `RefCounted`, `Callable` — без изменений в 4.4–4.7.

**Control Manifest Rules (this layer)**:
- Required: модуль — `RefCounted`, без `_process`/`_physics_process`, без чтения `Time`/`OS`/`Engine` (from ADR-0003)
- Required: сигналы типизированы, соединяются только в `MatchDirector._compose()`, без `CONNECT_DEFERRED`, без лямбд и `.bind()` (from ADR-0003)
- Forbidden: глобальный event bus, `get_tree().paused`, ссылки на autoload по имени (from ADR-0003)

---

## Acceptance Criteria

*From GDD `design/gdd/currency-coins-score.md`, scoped to this story:*

- [ ] Реальные `Currency` + `Till` (Memory-scope, `FakeUtcClock`), подключённые как в `_compose()`: при полной кассе `coins_added = 0`, а `match_score` продолжает расти в том же тике (AC 5, 18)
- [ ] Порядок на `match_ended`: Currency (`is_new_record`, `best_score`) обрабатывается раньше Till и PlayerStats; `is_new_record` читаем к моменту обработчика PlayerStats/HUD (ADR-0003 порядок, GDD Player Stats Rule 4)
- [ ] Запись `best_score` и `till.*` за один тик даёт один `write_blob` (шаг 6); в цепочке нет `CONNECT_DEFERRED`, лямбд, `.bind()` (проверка орфанов gdUnit4 зелёная)

---

## Implementation Notes

Тест-фикстура повторяет фрагмент `_compose()` (Currency → Till сигналы, порядок подключения `match_ended`). Сам `MatchDirector` — в эпике Match Director; здесь используется тонкая тестовая обвязка, вызывающая `on_served` в порядке шага 5a. Проверить отсутствие утечек (`dispose()` отключает все соединения). Цель — доказать границу Pillar 4: Currency не знает о кассе, Till не знает об очках.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Реальный `MatchDirector._compose()` и тик — эпик Match Director

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/currency/currency_till_chain_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002, 003, 004, 005; till story 002, 003
- Unlocks: Закрытие эпика
