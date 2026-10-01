# Story 004: Дневной сброс: проверка на match_started/холодном старте/меню

> **Epic**: Till & Day Cycle
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/till-day-cycle.md`
**Requirement**: `TR-till-007`, `TR-till-008`, `TR-till-010`, `TR-till-011`, `TR-till-012`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Match simulation — clock, tick order, pause; ADR-0005: Local persistence (SaveStore); ADR-0001: Web build platform shell
**ADR Decision Summary**: Весь матч ведёт один `MatchDirector._process` в фиксированном порядке тика; модули — `RefCounted`, общаются типизированными синхронными сигналами, соединёнными только в `_compose()`; `SceneTree.paused` не используется.
**ADR Version**: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: Post-cutoff APIs: нет. Типизированные сигналы на `RefCounted`, `Callable` — без изменений в 4.4–4.7.

**Control Manifest Rules (this layer)**:
- Required: модуль — `RefCounted`, без `_process`/`_physics_process`, без чтения `Time`/`OS`/`Engine` (from ADR-0003)
- Required: сигналы типизированы, соединяются только в `MatchDirector._compose()`, без `CONNECT_DEFERRED`, без лямбд и `.bind()` (from ADR-0003)
- Forbidden: глобальный event bus, `get_tree().paused`, ссылки на autoload по имени (from ADR-0003)
- Required: доступ к сохранению только через инъектированный `SaveScope`; каждый ключ объявлен (`declare_*`) с default и диапазоном до первого чтения (from ADR-0005)
- Required: владелец сам не вызывает `flush_if_dirty()`; flush — шаг 6 тика и скрытие страницы (from ADR-0005)
- Forbidden: запись `match_score` и внутриматчевого состояния в SaveStore; `user://` на web; владелец не создаёт backend (from ADR-0005)

---

## Acceptance Criteria

*From GDD `design/gdd/till-day-cycle.md`, scoped to this story:*

- [ ] Full с `full_since_utc` 23:00 UTC и часами 00:05 следующих суток: на `match_started` → Open, `amount = 0`, `full_since_utc` очищен; 3 суток простоя → ровно один сброс; на холодном старте 00:10 → Open, 23:50 → остаётся Full (AC 7, 26, 40)
- [ ] Проверка выполняется только на `match_started`, холодном старте и публичном `check_day_reset()` (меню, AC 44); полночь посреди партии/на итогах/при возврате из фона не сбрасывает (AC 24). Open-касса не сбрасывается никогда, `till_amount = 120` через двое суток остаётся (AC 27, 41)
- [ ] Граница суток считается по UTC независимо от часового пояса устройства (AC 25); `time_to_reset` в 21:48:00 UTC = 7920 с (AC 43, Formula 6); перевод часов вперёд сбрасывает по локальным часам — принятый MVP-риск, зафиксирован тестом-документом (AC 31)

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/feature/till.gd` (`check_reset`, `on_match_started`). Слайсовая формула `next_reset` уже корректна для многодневного простоя — покрыть тестами. `check_reset()` переименовать в публичный `check_day_reset()` с doc-комментарием (UI вызывает его при показе меню и по истечении отсчёта, поправка game-flow 2026-10-01); добавить `time_to_reset(now) -> int`. Убрать `debug_new_day()` из `src/` (оставить за `OS.is_debug_build()` в debug-модуле либо удалить). Часы — инжектируемые. Ссылка на ADR-0001 — только основание принятого риска TR-till-012.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- UI-строка «New day in Hh Mm» и скриншот AC 45 — эпик GameFlow
- Story 005: сохранение

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/till/till_daily_reset_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003
- Unlocks: Story 005
