# Story 001: Brewing: каркас, Cup, BrewingConfig и t_brew

> **Epic**: Brewing & Crafting
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/brewing-crafting-mechanic.md`
**Requirement**: `TR-brewing-001`, `TR-brewing-003`, `TR-brewing-013`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Match simulation - clock, tick order, pause
**ADR Decision Summary**: Один драйвер MatchDirector._process с фиксированным порядком тика, GameClock (RefCounted, hidden/frozen) - единственный источник паузы, модули симуляции - RefCounted со step(dt), типизированные сигналы подключаются только в корне композиции, без SceneTree.paused и глобальной шины событий.
**ADR Version**: 2026-09-30
**Secondary ADRs**: ADR-0004 (Data config & load-time validation)

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: Node._process, process_priority, типизированные сигналы на RefCounted - до-cutoff API, без изменений 4.4-4.7. Post-cutoff API не используются.

**Control Manifest Rules (derived from governing ADRs — no manifest exists)**:
- Required (from ADR-0003): модули симуляции - RefCounted со step(dt), без _process/_physics_process и без чтения Time/OS/Engine.
- Required (from ADR-0003): кросс-модульные сигналы типизированы, подключаются только в MatchDirector._compose(), без CONNECT_DEFERRED, без лямбд и .bind() с RefCounted.
- Forbidden (from ADR-0003): get_tree().paused, _physics_process, autoload по имени внутри модулей.
- Required (from ADR-0004): Brewing получает RecipeBook, KitchenLayout и BrewingConfig через конструктор; unit-тесты подставляют `FakeRecipeGrammar` (сценарные ответы is_valid_next/matches) и конфиг из фабрики.

---

## Acceptance Criteria

*From GDD `design/gdd/brewing-crafting-mechanic.md`, scoped to this story:*

- [ ] Чашка - `Cup {steps, ruined}`; `held_cup` содержит 0 или 1 чашку, вторая не создаётся и не заменяет существующую ни одним путём (AC-1.3).
- [ ] `t_brew = t_brew_base / speed_multiplier`: MVP (множитель 1.0) -> 3.0 с; для {1.0, 1.15, 1.3, 1.5} результат равен `3.0 / множитель` и лежит в [2.0, 3.0] (AC-F1.1, F1.3).
- [ ] `BrewingConfig.t_brew_base` и `speed_multiplier` - данные (sentinel `NAN`); валидатор отклоняет отсутствующие, нечисловые и неположительные значения; `speed_multiplier` в MVP 1.0 и не зашит в код (TR-brewing-013).

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/feature/brewing.gd` (заголовок, `_init`, `t_brew`, сигналы) и `prototypes/tea-rush-vertical-slice/src/foundation/config/brewing_config.gd` (8 строк).

- `class_name Brewing extends RefCounted`; `_init(layout: KitchenLayout, book: RecipeBook, cfg: BrewingConfig)`.
- Слайс хранит чашку как Dictionary `{steps, ruined}` - заменить на `class Cup extends RefCounted` (`steps: Array[StringName]`, `ruined: bool`) с `duplicate()`; состояние чайника - typed `KettleState` вместо Dictionary `{water, state, cup, t, t_total}`.
- Сигналы (типизированные): `refused(station_id)`, `held_changed()`, `kettle_changed(id)`, `kettle_ready(id)`, `slot_changed(id)`, `cup_ruined()` - как в слайсе; HUD/audio подключаются в `_compose()`.
- Публичный API для BaristaController: `is_valid(target) -> bool`, `offer(target) -> ActionReply` (enum из barista-control story 008; до его готовности - локальный алиас EXECUTE/WAIT/REFUSE).
- Тип станции берётся из `KitchenLayout.station_type(id)`; ID чайников/слотов - `layout.kettle_ids`/`slot_ids`.
- Правила валидатора `brewing.t_brew_base > 0`, `brewing.speed_multiplier >= 1.0` - в тот же PR.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: мгновенные станции.
- Story 003: чайники.
- Story 005: слоты и мусорка.
- Story 007: сброс.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`.*

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/brewing_crafting/brewing_crafting_core_test.gd` - must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (`KitchenLayout`, `RecipeBook` - kitchen-layout / recipe-book epics; до готовности - фикстуры)
- Unlocks: Story 002, 003, 004, 005, 006, 007
