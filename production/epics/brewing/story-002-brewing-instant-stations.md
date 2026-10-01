# Story 002: Мгновенные станции: выдача чашек и ингредиенты

> **Epic**: Brewing & Crafting
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/brewing-crafting-mechanic.md`
**Requirement**: `TR-brewing-004`
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

---

## Acceptance Criteria

*From GDD `design/gdd/brewing-crafting-mechanic.md`, scoped to this story:*

- [ ] Станция чашек: пустые руки -> ровно одна новая пустая чашка (AC-1.1); неиспорченная чашка в руках -> отказ, вторая не создаётся и текущая не заменяется (AC-1.2); испорченная чашка -> исчезает, выдаётся новая пустая (AC-2.1); выдача работает и когда все чайники и 7 слотов заняты (AC-E6).
- [ ] Станции льда/листа/лимона при пустых руках -> отказ, чашка не создаётся (AC-2.2); если ингредиент - допустимый следующий шаг по `RecipeBook.is_valid_next`, он добавляется в тот же тик без таймера (AC-2.3).
- [ ] Ингредиент не допустим следующим шагом -> чашка не меняется, станция подаёт сигнал отказа (`refused`) (AC-2.4); испорченная чашка отклоняется всеми ингредиентными станциями (AC-E1).

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/feature/brewing.gd`: ветки `cup` и ингредиентных станций в `_decide`, `_execute`, `is_valid`, `offer`.

- Решение и выполнение разделены (`_decide(id) -> Reply{response, feedback}` и `_execute(id)`) - сохранить: `is_valid` вызывается до выхода баристы и сам эмитит `refused` там, где GDD требует сигнал (флаг `feedback`), `offer` - каждый Holding-тик.
- Станция чашек при пустых руках/испорченной чашке: EXECUTE; при неиспорченной - REFUSE без сигнала отказа (как в слайсе, `feedback = false`) - сверить с GDD Core Rule 2 перед кодом.
- Ингредиентная ветка: `held == null` -> REFUSE без сигнала; `ruined` или не `is_valid_next` -> REFUSE с сигналом; иначе EXECUTE -> `held.steps.append(type)`.
- Мгновенные станции исполняются или отказывают в том же тике - никаких таймеров/ожидания (TR-brewing-004): `WAIT` они не возвращают.
- `FakeRecipeGrammar` - в `tests/helpers/`.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: чайники.
- Story 005: слоты и мусорка.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`.*

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/brewing_crafting/brewing_crafting_instant_stations_test.gd` - must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001; barista-control story 008 (enum `ActionReply`)
- Unlocks: Story 003, 008
