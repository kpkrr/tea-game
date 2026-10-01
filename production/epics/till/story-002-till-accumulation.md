# Story 002: Накопление кассы и coins_added

> **Epic**: Till & Day Cycle
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/till-day-cycle.md`
**Requirement**: `TR-till-002`, `TR-till-004`, `TR-till-013`
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

*From GDD `design/gdd/till-day-cycle.md`, scoped to this story:*

- [ ] `till_amount' = min(amount + coins, capacity)`: 200+5 → 205; 248+7 → 250 с `coins_added = 2`; 0+2 → 2 (AC 2, 3, 15, 16, 38)
- [ ] `coins_added` эмитится на каждый `coins_earned`, включая `0` при полной кассе (AC 39); `till_amount` не убывает в течение дня (AC 19); несколько `coins_earned` за тик дают `min(до + Σ, cap)` в любом порядке (AC 17)
- [ ] Full не блокирует старт матча и не трогает счёт; у Till нет публичного пути, читающего или меняющего `score_earned`/`match_score`/`best_score` (AC 4, 6, 9, 14)

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/feature/till.gd` (`on_coins_earned`, `fill_ratio`, `match_added`). Слайсовая сигнатура `coins_added(amount, earned)` — сверить с ADR-0003 §5/architecture.md (`coins_added(n)`); HUD использует излишек `earned − added` для «отскока», поэтому оставить оба параметра и зафиксировать в doc-комментарии. `match_added` (монеты, реально вошедшие за партию) читает PlayerStats (`match_coins_added`) и сбрасывается на `match_started`. Статическая типизация, `till_capacity` только из `TillConfig`.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: переход Open→Full и `day_filled`
- Story 005: сохранение

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/till/till_accumulation_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001
- Unlocks: Story 003, 005
