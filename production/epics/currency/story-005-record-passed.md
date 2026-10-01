# Story 005: Событие record_passed — NEW BEST! в партии

> **Epic**: Currency: Coins & Score
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/currency-coins-score.md`
**Requirement**: `TR-flow-022`
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

- [ ] На `match_started` запоминается `best_score_at_match_start`, флаг сбрасывается; на `served` после прибавления очков, если флаг не стоял, `best_at_start > 0` и `match_score > best_at_start`, эмитится `record_passed` ровно один раз (AC 35: 980→1040 при best 1000)
- [ ] Не эмитится при равенстве (`match_score == 1000`, AC 36) и никогда при `best_at_start = 0` (первая партия), при этом на `match_ended` `is_new_record = true` как обычно (AC 37)
- [ ] `best_score` остаётся прежним до `match_ended`; сигнал эмитится внутри цепочки Served (синхронно, без deferred)

---

## Implementation Notes

Нового кода в слайсе нет (`record_passed` появился в поправке game-flow 2026-10-01) — писать с нуля по TDD поверх портированного Currency. Сигнал объявляется типизированным на `Currency` (`signal record_passed()` по ADR-0003 §Key Interfaces поправки; GDD Rule 10 упоминает payload `(match_score, best_at_start)` — сверить с architecture.md и зафиксировать в doc-комментарии; потребителям нужен только факт). Слушатели (HUD-попап, стингер Audio) подключаются в `_compose()` другими эпиками. Состояние `record_passed_fired`/`best_at_start` не сохраняется.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- HUD-попап и аудио-стингер — эпики HUD и Audio & Juice
- Story 006: проверка порядка внутри цепочки

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/currency/currency_record_passed_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003, 004
- Unlocks: Story 006; эпики HUD/Audio
