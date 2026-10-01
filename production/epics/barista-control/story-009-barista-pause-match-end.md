# Story 009: BaristaController: пауза, конец матча, исчезновение цели, сброс

> **Epic**: Player Control / Barista Movement
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/player-control-barista-movement.md`
**Requirement**: `TR-control-016`, `TR-control-019`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Match simulation - clock, tick order, pause
**ADR Decision Summary**: Один драйвер MatchDirector._process с фиксированным порядком тика, GameClock (RefCounted, hidden/frozen) - единственный источник паузы, модули симуляции - RefCounted со step(dt), типизированные сигналы подключаются только в корне композиции, без SceneTree.paused и глобальной шины событий.
**ADR Version**: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: Node._process, process_priority, типизированные сигналы на RefCounted - до-cutoff API, без изменений 4.4-4.7. Post-cutoff API не используются.

**Control Manifest Rules (derived from governing ADRs — no manifest exists)**:
- Required (from ADR-0003): модули симуляции - RefCounted со step(dt), без _process/_physics_process и без чтения Time/OS/Engine.
- Required (from ADR-0003): пауза - только через игровое время (`GameClock.advance` = 0); контроллер не ссылается на `PlatformBridge`/visibility-сигналы.
- Forbidden (from ADR-0003): `SceneTree.paused`, `Timer`/`Tween` для игровой логики баристы.

---

## Acceptance Criteria

*From GDD `design/gdd/player-control-barista-movement.md`, scoped to this story:*

- [ ] Пауза (и скрытая вкладка): в Walking и в Holding с `WAIT` за 60 шагов с 3 тапами позиция не меняется, 0 предложений, 0 запросов допустимости, цель прежняя (AC 35).
- [ ] Конец матча в любом состоянии: новый ввод отклоняется, путь сбрасывается, бариста стоит на месте; `reset()` при новой партии возвращает Idle в `barista_start` без цели.
- [ ] Сигнал исчезновения гостя-цели (`target_vanished`/`on_target_vanished(slot)`) в Walking или Holding останавливает баристу в текущей позиции в тот же шаг, состояние Idle, гость не получает предложений; для другого слота сигнал игнорируется (AC 34).

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/core/barista_controller.gd`: `reset`, `stop`, `on_target_vanished`; пауза в слайсе обеспечивается тем, что `step` не вызывается при `dt == 0`.

- Контроллер сам паузу не знает: `MatchDirector` не зовёт `barista.step(dt)` при `dt == 0`, а `tap_picker.flush(false)` гасит нажатия (ADR-0003 тик, шаги 2-3). Тест - через реальный порядок тика с `GameClock` (freeze/pause/resume) на `FakeNavigator`.
- Конец матча: `MatchLifecycle.match_ended` -> `barista.stop()` подключается в `_compose()`; после `freeze()` `flush(false)` не пропускает тапы.
- `match_started` -> `reset()`; порядок сигналов подтвердить у foundation-runtime.
- Edge Case "гость ушёл, бариста в Holding": `WAIT`-цикл прекращается тем же шагом.
- Проверить grep-тестом, что в контроллере нет `get_tree().paused`, `Timer`, ссылок на `PlatformBridge`.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 008: состояния.
- Guest-sim epic: источник `target_vanished`.
- Foundation-runtime: `GameClock`, `MatchLifecycle`.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`.*

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/player_control/player_control_pause_match_end_test.gd` - must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 004, 008; foundation-runtime (`GameClock`, `MatchDirector` тик)
- Unlocks: Story 011
