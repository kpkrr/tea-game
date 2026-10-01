# Story 003: Чайники: состояния EMPTY/BREWING/READY и таблица ответов

> **Epic**: Brewing & Crafting
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: L
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/brewing-crafting-mechanic.md`
**Requirement**: `TR-brewing-002`, `TR-brewing-005`, `TR-brewing-006`, `TR-brewing-012`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Match simulation - clock, tick order, pause
**ADR Decision Summary**: Один драйвер MatchDirector._process с фиксированным порядком тика, GameClock (RefCounted, hidden/frozen) - единственный источник паузы, модули симуляции - RefCounted со step(dt), типизированные сигналы подключаются только в корне композиции, без SceneTree.paused и глобальной шины событий.
**ADR Version**: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: Node._process, process_priority, типизированные сигналы на RefCounted - до-cutoff API, без изменений 4.4-4.7. Post-cutoff API не используются.

**Control Manifest Rules (derived from governing ADRs — no manifest exists)**:
- Required (from ADR-0003): модули симуляции - RefCounted со step(dt), без _process/_physics_process и без чтения Time/OS/Engine.
- Required (from ADR-0003): кросс-модульные сигналы типизированы, подключаются только в MatchDirector._compose(), без CONNECT_DEFERRED, без лямбд и .bind() с RefCounted.
- Required (from ADR-0003): ответ на предложение - синхронный, один из EXECUTE/WAIT/REFUSE; REFUSE на заваривающемся чайнике немедленный (бариста не остаётся ждать).

---

## Acceptance Criteria

*From GDD `design/gdd/brewing-crafting-mechanic.md`, scoped to this story:*

- [ ] EMPTY: подходящая чашка -> уходит в чайник, заварка начинается, руки пусты (AC-3.1); руки пусты, чашка без листа или испорченная -> отказ, чайник и чашка не меняются (AC-3.3-3.4); чашка не того листа -> чашка помечается `ruined`, остаётся в руках, чайник остаётся EMPTY, сигнал `cup_ruined` (AC-3.2, TR-brewing-006).
- [ ] BREWING: подходящая чашка или пустые руки -> WAIT (Holding); чашка не того листа или без листа -> немедленный REFUSE, чашка не портится, заварка идёт (AC-3.7-3.8); READY: подходящая чашка -> за ОДИН тап готовая чашка в руках, принесённая в чайнике с новым отсчётом; пустые руки -> готовая чашка в руках, чайник EMPTY; не-подходящая -> REFUSE, готовая остаётся в чайнике (AC-3.9-3.12).
- [ ] Таблица ответов покрывает все 12 комбинаций (3 состояния x 4 класса: MATCH, WRONG_TEMP, EMPTY_HANDS, OTHER) одним параметризованным тестом; повторное добавление воды в уже заваренную чашку = OTHER (отказ), не WRONG_TEMP (TR-brewing-012).
- [ ] Два чайника независимы: действия над одним не меняют состояние, воду и таймер другого (AC-6.3, часть).

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/feature/brewing.gd`: `Kettle`/`Class` enum, `_decide_kettle`, `_classify`, ветка `id in kettles` в `_execute` (проверено `test_kettle_wrong_temperature_ruins_cup_and_ready_swap`).

- `_classify` в слайсе содержит хак: WRONG_TEMP = последний шаг начинается с `leaf_` и `steps.size() == 2`. При переносе не завязываться на строковый префикс: WRONG_TEMP = чашка `[cup, leaf_X]`, для которой вода ДРУГОГО чайника была бы допустимым шагом (`RecipeBook.is_valid_next`). Поведение должно остаться тем же - покрыть тестом.
- Слайс пишет `held.ruined = true` прямо в словарь; в `Cup` сделать метод `ruin()`.
- Обмен в READY: `held = ready_cup` после того, как принесённая чашка ушла в чайник - одна операция (не два тапа).
- Старт заварки: `t = t_total = t_brew()`; таймер - story 004.
- Вода чайника определяется типом станции (`water_100`/`water_80`) из layout, а не литералом.
- Таблицу из 12 комбинаций вынести в константу теста (GDD "Таблица ответов чайника") и сверить с GDD.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 004: фоновый таймер и автоподача без повторного тапа.
- Story 005: слоты и мусорка.
- HUD epic: индикаторы чайников (AC-I2).

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`.*

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/brewing_crafting/brewing_crafting_kettle_test.gd` - must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001, 002
- Unlocks: Story 004, 008
