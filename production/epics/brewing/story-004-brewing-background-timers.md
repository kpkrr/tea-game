# Story 004: Фоновые таймеры чайников на игровом времени

> **Epic**: Brewing & Crafting
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/brewing-crafting-mechanic.md`
**Requirement**: `TR-brewing-009`, `TR-brewing-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Match simulation - clock, tick order, pause
**ADR Decision Summary**: Один драйвер MatchDirector._process с фиксированным порядком тика, GameClock (RefCounted, hidden/frozen) - единственный источник паузы, модули симуляции - RefCounted со step(dt), типизированные сигналы подключаются только в корне композиции, без SceneTree.paused и глобальной шины событий.
**ADR Version**: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: Node._process, process_priority, типизированные сигналы на RefCounted - до-cutoff API, без изменений 4.4-4.7. Post-cutoff API не используются.

**Control Manifest Rules (derived from governing ADRs — no manifest exists)**:
- Required (from ADR-0003): модули симуляции - RefCounted со step(dt), без _process/_physics_process и без чтения Time/OS/Engine.
- Required (from ADR-0003): кросс-модульные сигналы типизированы, подключаются только в MatchDirector._compose(), без CONNECT_DEFERRED, без лямбд и .bind() с RefCounted.
- Guardrail (from ADR-0003): шаг таймера вызывается только из `MatchDirector` на шаге 4 тика и только при `dt > 0`; `dt` уже зажат `max_step_delta` (0.25 с).

---

## Acceptance Criteria

*From GDD `design/gdd/brewing-crafting-mechanic.md`, scoped to this story:*

- [ ] Таймер идёт каждый кадр симуляции независимо от баристы: пока он уходит и делает другое, отсчёт не останавливается; при нуле чайник становится READY без действий игрока, сигнал `kettle_ready` эмитится один раз (AC-6.1-6.2).
- [ ] Два чайника с разным остатком становятся готовыми каждый в свой момент; заварка, начатая при t = 10.0 с партии, готова при t = 13.0 с (+/- 1 кадр) (AC-6.3, F1.2).
- [ ] Бариста ждёт у заваривающего чайника (`offer` каждый тик -> WAIT): при завершении заварки без повторного тапа готовая чашка оказывается в руках, принесённая - в чайнике с новым отсчётом (или чайник пуст при пустых руках) (AC-3.5-3.6).
- [ ] Уход баристы к другой цели не меняет отсчёт чайника (AC-E3); `step(0)` (пауза) ничего не меняет.

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/feature/brewing.gd::step` (цикл по чайникам: `k.t = maxf(k.t - dt, 0.0)`, переход в READY, эмит `kettle_changed` + `kettle_ready`).

- `step(dt: float)` - единственная точка времени; Brewing не читает `Time`/`Engine` и не имеет `_process` (ADR-0003).
- Автоподача: `offer()` на READY для подходящей/пустой руки возвращает EXECUTE и делает обмен - работает из того же `_decide/_execute`, что и в story 003; здесь тест цепочки WAIT -> ready -> EXECUTE.
- TR-brewing-010 (clamp `max_step_delta`) реализуется в `GameClock` (foundation-runtime), Brewing просто получает готовый dt.
- Тесты управляют временем вручную через `step(delta)`; `FakeRecipeGrammar` изолирует RecipeBook.
- Точность: +/- 1 кадр = допуск один `dt` теста.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: переходы по тапам.
- Story 008: интеграция с GameClock (скрытая вкладка, AC-E5) и BaristaController.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`.*

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/brewing_crafting/brewing_crafting_timers_test.gd` - must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001, 003
- Unlocks: Story 008
