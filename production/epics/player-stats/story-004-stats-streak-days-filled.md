# Story 004: Серия дней, days_filled и флаг streak_grew

> **Epic**: Player Stats
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
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

- [ ] `day_filled(d)` по Formula 1: `last = d−1` → `streak+1` (101, 2 → 102 даёт 3); `last = d` → без изменений; иначе `streak = 1` (101, 5 → 104 даёт 1, `best_streak` остаётся 5); затем `streak_last_day = d`, `best_streak = max` (AC 4, 5)
- [ ] `days_filled` +1 на каждое `day_filled` (AC 8); `streak_grew_this_match = true`, когда `streak` вырос, сбрасывается на `match_started`
- [ ] `day_filled` и `match_ended` в одном тике: серия обновлена в том же тике, флаг виден на итогах; `d` берётся из payload события (полночь посреди партии), а не из часов

---

## Implementation Notes

Пишется с нуля (TDD). Вход — `Till.day_filled(day_index)` (till story 003). Любое нарушение инварианта (`streak_last_day > d`) обрабатывается веткой «иначе» по GDD; запись одной debug-строки не нужна, если только это не ветка часов назад (story 005).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 005: `displayed_streak`
- UI «🔥 N-day streak!» — эпик GameFlow

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/player_stats/player_stats_streak_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001; till story 003
- Unlocks: Story 005, 006
