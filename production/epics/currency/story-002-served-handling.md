# Story 002: Обработка Served: независимые coins/score сигналы

> **Epic**: Currency: Coins & Score
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/currency-coins-score.md`
**Requirement**: `TR-currency-012`, `TR-currency-010`, `TR-currency-011`, `TR-currency-013`
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

- [ ] Единственный триггер расчёта — `on_served(recipe_id, remaining_fraction)`; на каждый вызов эмитятся `coins_earned(price)` и `score_earned(score)` (в том числе при полной кассе), значения не зависят друг от друга (AC 1, 4, 18)
- [ ] Система не читает состояние и вместимость кассы (у `Currency` нет ссылки на `Till`); публичного метода, уменьшающего монеты/очки или конвертирующего одно в другое, нет (AC 6, 9 — проверка грепом/ревью)
- [ ] Два и более `served` в одном тике: итоговый `match_score` равен сумме и не зависит от порядка (AC 20)

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/feature/currency.gd` (`on_served`). Добавить типизацию (`recipe_id: StringName`, `remaining_fraction: float`), doc-комментарии. Сигналы эмитятся синхронно внутри шага 5a тика (ADR-0003 §5): `coins_earned` → Till, затем `score_earned` → HUD. Юнит-тест Currency работает на `FakeRecipeBook` и `MemoryBackend`-scope. Аудит AC 6/9 оформить как тест, грепающий `src/feature/currency/` на запрещённые сигнатуры (`spend`, `convert`, `subtract`), либо пункт code-review чеклиста.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: состояния `match_score`
- Story 006: сквозная цепочка Currency → Till

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/currency/currency_served_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001
- Unlocks: Story 003, 006
