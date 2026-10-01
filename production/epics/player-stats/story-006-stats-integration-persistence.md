# Story 006: Интеграция: порядок match_ended и сохранение статистики

> **Epic**: Player Stats
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
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

- [ ] Реальные `Currency`, `Till`, `PlayerStats` на `MemoryBackend`, подключённые как в `_compose()`: на `match_ended` порядок Currency → Till → PlayerStats, `recent[0].new_record` равен актуальному `is_new_record`
- [ ] Полный «перезапуск» (пересоздание `SaveStore` на том же backend) сохраняет все `stats.*` (счётчики, серия, `recent`); v1-блоб без ключей `stats.*` валидируется в defaults без перезаписи
- [ ] `SaveStore.persistent = false`: статистика живёт в памяти сессии без ошибок; записи смены и серии за один тик = один `write_blob`

---

## Implementation Notes

Тест-фикстура повторяет фрагмент `_compose()`. Скриншотная проверка экрана Records (GDD AC 9, UI) принадлежит эпику GameFlow — здесь только логика и персистентность. Проверить отсутствие утечек (`dispose()`).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Экран Records и скриншоты AC 9 — эпик GameFlow

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/player_stats/player_stats_integration_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002–005; currency story 004; till story 003, 005
- Unlocks: Закрытие эпика
