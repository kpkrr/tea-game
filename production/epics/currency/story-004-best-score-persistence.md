# Story 004: best_score, is_new_record и локальное сохранение

> **Epic**: Currency: Coins & Score
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/currency-coins-score.md`
**Requirement**: `TR-currency-006`, `TR-currency-007`, `TR-currency-008`, `TR-currency-009`
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

*From GDD `design/gdd/currency-coins-score.md`, scoped to this story:*

- [ ] На `match_ended` сначала `is_new_record = match_score > best_score` (до обновления), затем `best_score := match_score` только при `is_new_record` и запись в `currency.best_score` через scope: 950 vs 900 → true/950; 900 и 850 vs 900 → false/900; первая партия 120 → true (AC 7, 23, 35)
- [ ] `best_score` никогда не уменьшается и не меняется на `served`, `match_started`, заполнении/сбросе кассы; `is_new_record = false` на `match_started` и при партии без Served (AC 8, 22, 30, 31)
- [ ] `match_ended(&"quit")` при 1500 > 1200 даёт `is_new_record = true`, `best_score = 1500` как при `lost` (AC 38); round-trip через `MemoryBackend`: значение переживает пересоздание `SaveStore`; невалидное значение ключа → 0 + один лог; `match_score` нигде не пишется в SaveStore (AC 32)

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/feature/currency.gd` (`_init` c `scope.declare_int("best_score", 0, 0, 1_000_000_000)`, `on_match_ended`). Ключ `currency.best_score`, владелец Currency (ADR-0005 §6). Не вызывать `flush_if_dirty()` — flush делает `MatchDirector` на шаге 6. Интеграционный тест: реальные `SaveStore` + `MemoryBackend` + `Currency`, «перезапуск» = `SaveStore.open(same_backend)`. Поведение на реальном устройстве (закрытие вкладки) покрывается on-device spike ADR-0005, не этой историей.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 005: `record_passed`
- Story 006: композиция в `_compose()`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/currency/currency_best_score_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003; SaveStore/SaveScope из Foundation-эпика
- Unlocks: Story 005, 006; player-stats story 003
