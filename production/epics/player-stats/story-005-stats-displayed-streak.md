# Story 005: displayed_streak и часы назад

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

- [ ] `displayed_streak = streak`, если `streak_last_day >= today − 1`, иначе 0: при last 102, streak 3 и сегодня 103 → 3, сегодня 104 → 0 (AC 6, Formula 2); хранимое `streak` геттер не трогает
- [ ] `today` считается `Till.day_index(utc.now_unix())` по инжектируемым часам и `daily_reset_time_utc` — «день» совпадает с днём кассы
- [ ] Часы отведены назад (`today < streak_last_day`): `displayed_streak = streak`, запись не меняется, одна debug-строка (Rule 9); первый запуск (`streak_last_day = −1`) → 0

---

## Implementation Notes

Пишется с нуля (TDD), чистая функция над сохранёнными значениями + `day_index` из Till. Тесты на `FakeUtcClock`.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Строка меню `🔥 N · fill the till to keep it` — эпик GameFlow

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/player_stats/player_stats_displayed_streak_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 004; till story 003
- Unlocks: Story 006
