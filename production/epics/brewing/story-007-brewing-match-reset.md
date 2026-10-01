# Story 007: Сброс Brewing на match_started

> **Epic**: Brewing & Crafting
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/brewing-crafting-mechanic.md`
**Requirement**: `TR-brewing-011`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Match simulation - clock, tick order, pause
**ADR Decision Summary**: Один драйвер MatchDirector._process с фиксированным порядком тика, GameClock (RefCounted, hidden/frozen) - единственный источник паузы, модули симуляции - RefCounted со step(dt), типизированные сигналы подключаются только в корне композиции, без SceneTree.paused и глобальной шины событий.
**ADR Version**: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: Node._process, process_priority, типизированные сигналы на RefCounted - до-cutoff API, без изменений 4.4-4.7. Post-cutoff API не используются.

**Control Manifest Rules (derived from governing ADRs — no manifest exists)**:
- Required (from ADR-0003): модули симуляции - RefCounted со step(dt), без _process/_physics_process и без чтения Time/OS/Engine.
- Required (from ADR-0003): кросс-модульные сигналы типизированы, подключаются только в MatchDirector._compose(), без CONNECT_DEFERRED, без лямбд и .bind() с RefCounted.
- Forbidden (from ADR-0003): get_tree().paused, _physics_process, autoload по имени внутри модулей.

---

## Acceptance Criteria

*From GDD `design/gdd/brewing-crafting-mechanic.md`, scoped to this story:*

- [ ] После `match_started` оба чайника EMPTY (в том числе заваривавшийся с остатком времени и READY), все 7 слотов пусты, `held_cup` = null, испорченная чашка исчезает (AC-E4).
- [ ] `reset()` эмитит `kettle_changed`/`slot_changed`/`held_changed` для обновления HUD и не эмитит `refused`/`cup_ruined`; повторный `reset()` идемпотентен.

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/feature/brewing.gd::reset` (вызывается из `_init` и при старте матча).

- Подключение `MatchLifecycle.match_started -> Brewing.reset` - только в `MatchDirector._compose()`; сигнал синхронный (ADR-0003 step 0), таймеры не "доживают" старую партию.
- Состояние конца матча (`frozen`) не требует действий Brewing: часы замораживаются, `step` не вызывается.
- Тест: наполнить состояние (руки, оба чайника, 7 слотов), вызвать `reset()`, проверить всё.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Foundation-runtime epic: `MatchLifecycle`, порядок сигналов.
- Story 008: проверка сброса в сквозном сценарии.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`.*

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/brewing_crafting/brewing_crafting_reset_test.gd` - must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001, 003, 005
- Unlocks: Story 008
