# Story 003: Переход Open→Full, day_filled и day_index

> **Epic**: Till & Day Cycle
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/till-day-cycle.md`
**Requirement**: `TR-till-003`, `TR-till-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Match simulation — clock, tick order, pause; ADR-0005: Local persistence (SaveStore)
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

- [ ] Served, доводящий сумму до `till_capacity` (245+7), переводит день Open → Full в том же тике, не дожидаясь `match_ended`, и сохраняет `full_since_utc = now` (AC 5, 11, 12, 18)
- [ ] `day_filled(day_index)` эмитится ровно один раз на переходе, после `coins_added`; последующие Served в Full его не эмитят (AC 42)
- [ ] `day_index(now) = floor((now − reset_hour×3600) / 86400)`: 23:59:59 и 00:00:00 соседних суток отличаются на 1 (AC 43, Formula 5); чистая функция на инжектируемых часах

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/feature/till.gd` (`became_full`, `_full_since`). Слайс эмитит `became_full()` без payload — заменить на `day_filled(day_index: int)` (GDD Rule 10, architecture.md сигнатура `day_filled()` — payload нужен PlayerStats для серии; при расхождении поправить architecture.md, не ADR). `day_index` вынести публичной функцией Till (её использует PlayerStats). Часы — инжектируемый `UtcClock` (в слайсе `fake_now`), `Time` напрямую не читать.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 004: сброс дня
- PlayerStats: реакция на `day_filled`
- HUD-плашка Till full — эпик HUD

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/till/till_day_filled_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002
- Unlocks: Story 004; player-stats story 004, 005
