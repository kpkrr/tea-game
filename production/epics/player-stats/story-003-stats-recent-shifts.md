# Story 003: Список последних смен (recent)

> **Epic**: Player Stats
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/player-stats.md`
**Requirement**: `TR-flow-025`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: Local persistence (SaveStore); ADR-0003: Match simulation — clock, tick order, pause
**ADR Decision Summary**: `SaveStore` — in-memory модель с owner-scope (`SaveScope`), один версионированный JSON-блоб, валидация каждого ключа с дефолтом, flush раз за тик (шаг 6) и при скрытии страницы; backend: `localStorage` (web) / `user://` (desktop) / `MemoryBackend` (тесты).
**ADR Version**: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: Web-путь persistence — HIGH (`localStorage` через helper HTML-шелла, не `user://`). В юнит-тестах только `MemoryBackend`; `WebStorageBackend` покрыт on-device spike. JSON-числа возвращаются как float — читать через валидатор.

**Control Manifest Rules (this layer)**:
- Required: доступ к сохранению только через инъектированный `SaveScope`; каждый ключ объявлен (`declare_*`) с default и диапазоном до первого чтения (from ADR-0005)
- Required: владелец сам не вызывает `flush_if_dirty()`; flush — шаг 6 тика и скрытие страницы (from ADR-0005)
- Forbidden: запись `match_score` и внутриматчевого состояния в SaveStore; `user://` на web; владелец не создаёт backend (from ADR-0005)
- Required: модуль — `RefCounted`, без `_process`/`_physics_process`, без чтения `Time`/`OS`/`Engine` (from ADR-0003)
- Required: сигналы типизированы, соединяются только в `MatchDirector._compose()`, без `CONNECT_DEFERRED`, без лямбд и `.bind()` (from ADR-0003)
- Forbidden: глобальный event bus, `get_tree().paused`, ссылки на autoload по имени (from ADR-0003)

---

## Acceptance Criteria

*From GDD `design/gdd/player-stats.md`, scoped to this story:*

- [ ] На `match_ended` в начало `recent` добавляется `{score = match_score, coins = match_coins_added, new_record = is_new_record}`; при 5 записях и `{900, 40, true}` первая запись именно такая, длина 5, старейшая отброшена (AC 3)
- [ ] `match_ended(quit)` без Served даёт `{0, 0, false}`; длина ограничена `recent_shifts_max`
- [ ] Хранится JSON-строкой в `stats.recent`; `is_new_record` читается уже вычисленным из Currency (Currency обработал `match_ended` раньше)

---

## Implementation Notes

Пишется с нуля (TDD). Вход: `Currency.match_score`/`is_new_record` и `Till.match_added` (`match_coins_added`) — через инъектированные геттеры-коллабораторы (в тесте — фейки). Сериализация через `JSON.stringify`, разбор — `JSON` instance `parse()` (ADR-0005).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Отображение списка — эпик GameFlow

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/player_stats/player_stats_recent_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001, 002; currency story 004; till story 002
- Unlocks: Story 006
