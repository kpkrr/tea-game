# Story 003: match_score: Idle → Accumulating → Frozen

> **Epic**: Currency: Coins & Score
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/currency-coins-score.md`
**Requirement**: `TR-currency-004`, `TR-currency-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Match simulation — clock, tick order, pause
**ADR Decision Summary**: Весь матч ведёт один `MatchDirector._process` в фиксированном порядке тика; модули — `RefCounted`, общаются типизированными синхронными сигналами, соединёнными только в `_compose()`; `SceneTree.paused` не используется.
**ADR Version**: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: Post-cutoff APIs: нет. Типизированные сигналы на `RefCounted`, `Callable` — без изменений в 4.4–4.7.

**Control Manifest Rules (this layer)**:
- Required: модуль — `RefCounted`, без `_process`/`_physics_process`, без чтения `Time`/`OS`/`Engine` (from ADR-0003)
- Required: сигналы типизированы, соединяются только в `MatchDirector._compose()`, без `CONNECT_DEFERRED`, без лямбд и `.bind()` (from ADR-0003)
- Forbidden: глобальный event bus, `get_tree().paused`, ссылки на autoload по имени (from ADR-0003)

---

## Acceptance Criteria

*From GDD `design/gdd/currency-coins-score.md`, scoped to this story:*

- [ ] `match_started` ставит `match_score = 0` (Idle); первый `served` → Accumulating; `match_ended(reason)` → Frozen, значение больше не растёт и читается неизменным до следующего `match_started` (AC 25–29)
- [ ] `match_ended` без единого Served: `match_score = 0`, Idle → Frozen напрямую (AC 22, часть про score)
- [ ] `served` в тот же тик, что и `match_ended(lost)`, до перехода в Frozen, учитывается в `match_score` (AC 21); оба `reason` (`&"lost"`, `&"quit"`) обрабатываются одинаково

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/feature/currency.gd` (`on_match_started`, `on_match_ended`, поле `_match_score`). Слайс не хранит явного состояния — добавить приватный enum `ScoreState {IDLE, ACCUMULATING, FROZEN}` и геттер `match_score`; `served` во `FROZEN` игнорируется с одной debug-записью. Сигнатура `on_match_ended(reason: StringName)` по ADR-0003 (поправка 2026-10-01). Порядок обработки `match_ended` фиксирует ADR-0003: Currency → Till → PlayerStats → HUD; сам порядок проверяется в Story 006.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 004: сравнение с `best_score`
- Story 005: `record_passed`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/currency/currency_match_score_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002
- Unlocks: Story 004, 005
