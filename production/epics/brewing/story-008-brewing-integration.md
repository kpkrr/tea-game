# Story 008: Интеграция: Brewing + RecipeBook + BaristaController + GameClock

> **Epic**: Brewing & Crafting
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/brewing-crafting-mechanic.md`
**Requirement**: `TR-brewing-008`, `TR-brewing-009`
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

- [ ] С реальными `RecipeBook` и `BaristaController` (на `FakeNavigator`): полная сборка `black_tea_lemon` (чашка -> лист -> чайник, ожидание в Holding без повторного тапа, вода, лимон) приходит к чашке, для которой `matches` = `black_tea_lemon`; действие в чайнике выполняется ровно один раз, когда заварка готова (AC 40a Player Control).
- [ ] Чашка не того листа портится и уходит в мусорку за два тапа (чайник -> мусорка), руки пусты, `consume_held_cup` не вызывался; подача (заглушка GuestSim) вызывает `consume_held_cup()` ровно один раз (AC-I1 - в части, не блокированной guest-sim).
- [ ] С реальным `GameClock`: чайник с остатком 1.2 с, `pause()` на >= 10 с и `resume()` -> остаток 1.2 с, первый кадр после `resume()` даёт dt = 0 (AC-E5); `freeze()` на конце матча останавливает таймеры.

---

## Implementation Notes

Замыкающий тест эпика. Слайс: `prototypes/tea-rush-vertical-slice/src/debug/demo_bot.gd` проходит тот же сквозной сценарий вручную - использовать как эталон последовательности тапов.

- Расположение: `tests/integration/brewing_crafting/brewing_crafting_full_flow_test.gd`; фикстуры `kitchen_fixture_*` с реальными Order & Recipe и Player Control (по GDD).
- Порядок тика воспроизводить как в `MatchDirector._process` (flush -> barista.step -> brewing.step), без `await` на реальном времени.
- AC-I2 (состояние чайника читается в мире, без виджета в HUD-полосах) - скриншот в эпике `hud`/`kitchen-view`, не здесь.
- AC-I1 полностью закрывается в guest-sim с реальным GuestSim.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- HUD epic: AC-I2 (индикация чайников скриншотом).
- Guest-sim epic: реальная подача гостю.
- Art-assets/visual-pipeline: спрайты чайников и чашек.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`.*

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/brewing_crafting/brewing_crafting_full_flow_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002-007; recipe-book story 002; barista-control story 008, 009; foundation-runtime (`GameClock`)
- Unlocks: None (закрывает эпик)
