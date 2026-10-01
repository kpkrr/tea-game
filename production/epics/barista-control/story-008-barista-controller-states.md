# Story 008: BaristaController: Idle/Walking/Holding, перенаправление, валидность, протокол владельца

> **Epic**: Player Control / Barista Movement
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: L
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/player-control-barista-movement.md`
**Requirement**: `TR-control-003`, `TR-control-004`, `TR-control-009`, `TR-control-010`, `TR-control-013`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Match simulation - clock, tick order, pause
**ADR Decision Summary**: Один драйвер MatchDirector._process с фиксированным порядком тика, GameClock (RefCounted, hidden/frozen) - единственный источник паузы, модули симуляции - RefCounted со step(dt), типизированные сигналы подключаются только в корне композиции, без SceneTree.paused и глобальной шины событий.
**ADR Version**: 2026-09-30
**Secondary ADRs**: ADR-0006 (Navigation & tap picking)

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: Node._process, process_priority, типизированные сигналы на RefCounted - до-cutoff API, без изменений 4.4-4.7. Post-cutoff API не используются.

**Control Manifest Rules (derived from governing ADRs — no manifest exists)**:
- Required (from ADR-0003): модули симуляции - RefCounted со step(dt), без _process/_physics_process и без чтения Time/OS/Engine.
- Required (from ADR-0003): кросс-модульные сигналы типизированы, подключаются только в MatchDirector._compose(), без CONNECT_DEFERRED, без лямбд и .bind() с RefCounted.
- Forbidden (from ADR-0003): get_tree().paused, _physics_process, autoload по имени внутри модулей.
- Required (from ADR-0003): контроллер вызывается на шаге 3 тика после `tap_picker.flush`; в Holding предложение действия владельцу - синхронный вызов раз за шаг.

---

## Acceptance Criteria

*From GDD `design/gdd/player-control-barista-movement.md`, scoped to this story:*

- [ ] Очереди нет: принятый тап сразу заменяет цель из любого состояния с текущей позиции (первая точка нового пути = текущая позиция, без отката); отклонённый владельцем тап оставляет цель, путь и скорость без изменений. Повторный тап по текущей цели в Walking не прыгает и не дублирует действие; в Holding - остаётся Holding, путь не строится; `WAIT` + тап по полу -> Walking, прежняя цель больше не получает предложений (AC 12-17).
- [ ] Валидность запрашивается у владельца цели ДО выхода; цель-пол запросов не делает (0 вызовов на трёх тапах, включая вне области) и всегда валидна (AC 16, 18).
- [ ] Прибытие к станции/гостю -> в тот же шаг Holding и первое предложение; далее ровно одно предложение за шаг: `EXECUTE` -> Idle (ровно одно действие), `WAIT` -> Holding (5 x `WAIT` + `EXECUTE` = 6 предложений), `REFUSE` -> Idle в точке цели без остановок в пути (AC 29-31).
- [ ] Цель-пол никогда не переводит в Holding (Idle сразу по прибытию, 0 предложений за 10 шагов); нулевой путь к станции -> Holding в том же шаге, к полу -> Idle; новая партия -> Idle без цели, позиция не меняется (AC 28, 32-33).

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/core/barista_controller.gd` (`tap`, `step`, `_set_idle`, `_same`, enums `State`/`Reply`) - логика проверена слайсом (`test_kettle_*` и demo_bot); задача - привести к стандартам.

- Вместо Dictionary-целей - `TapTarget` (story 002); вместо `_router: Object` - типизированный интерфейс `ActionOwner` (`is_valid(target: TapTarget) -> bool`, `offer(target: TapTarget) -> ActionReply`), владельцы - Brewing и GuestSim; тесты - `FakeActionOwner` со счётчиками вызовов.
- Общий enum `ActionReply { EXECUTE, WAIT, REFUSE }` создаётся здесь (`src/core/action_reply.gd`) и используется Brewing (brewing story 002).
- Зависимости (`Navigator`, `KitchenLayout`, `ControlConfig`, owner router) через конструктор; `PathFollower` из story 007.
- `is_valid` у владельца сам показывает отказ (сигнал `refused`) - контроллер не дублирует обратную связь.
- Сигналы типизированы (`target_changed(target: TapTarget)`, `arrived_floor(point: Vector3)`); подключение - в `_compose()`.
- Слайс пишет `push_error("no path to target")` - оставить, теперь с `owner_id#index` (ADR-0006 §4).
- Тест-слой: `BaristaFixtures` (контроллер + внешний `step(dt)`), без реального NavServer (FakeNavigator).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 009: пауза/конец матча/исчезновение гостя/сброс.
- Story 010: спрайт и маркер.
- Brewing/guest-sim epics: реальные владельцы действий.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`.*

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/player_control/player_control_states_test.gd` - must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002, 006 (интерфейс Navigator; тесты на FakeNavigator), 007
- Unlocks: Story 009, 010, 011; brewing story 002
