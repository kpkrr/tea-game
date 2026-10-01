# Story 003: Пауза игрового времени: hidden + user pause, max_step_delta

> **Epic**: Guest AI & Patience + Match Lifecycle
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/guest-ai-patience.md`
**Requirement**: `TR-guest-015`, `TR-guest-016`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Match simulation — clock, tick order, pause
**ADR Decision Summary**: MatchDirector._process — единственный драйвер; GameClock (RefCounted) — единственный источник паузы (флаги hidden/frozen, без SceneTree.paused); фиксированный порядок тика; MatchLifecycle владеет политикой партии; типизированные синхронные сигналы, проводка только в _compose().
**ADR Version**: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: LOW (домен Core; `_process`, типизированные сигналы на RefCounted — до cutoff и без изменений в 4.4–4.7)

Guest AI/MatchLifecycle — единственный владелец паузы: два ортогональных флага `_hidden` и `_user_paused`; часы ставятся на паузу по рёбрам OR. Первый кадр после resume отбрасывается.

**Control Manifest Rules (from ADR; no manifest at this tier)**:
- Required: sim-модули — `RefCounted` с `step(dt)`; без `_process`/`_physics_process`, без `Time`/`OS`/`Engine` времени (from ADR-0003)
- Forbidden: `get_tree().paused`, `_physics_process`, ссылки на autoload по имени, лямбды и `.bind()` в сигналах между RefCounted, `CONNECT_DEFERRED` (from ADR-0003)
- Guardrail: запрос, меняющий партию (`request_new_match`), не вызывается реентерабельно из обработчика сигнала — ставится в очередь и применяется на шаге 0 (from ADR-0003)

---

## Acceptance Criteria

*From GDD `design/gdd/guest-ai-patience.md`, scoped to this story:*

- [ ] t = 40, терпение гостя 0.8: пауза (или hidden) на 600 кадров — `t`, `remaining_fraction`, спавны и позиции не меняются; после снятия `step(0.25)` даёт t = 40.25 (AC 32).
- [ ] `request_pause()` принимается только в RUNNING; hide→show при user-pause остаётся на паузе; resume при hidden остаётся на паузе до show; `paused_changed` — один раз на ребро.
- [ ] При `max_step_delta` = 0.25 кадр с `real_delta` = 5.0 продвигает `t` не более чем на 0.25 с (терпение гостя уменьшается на 0.25/patience_max) (AC 53).

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/feature/match_lifecycle.gd` (`_hidden`, `_user_paused`, `_sync_pause`, `request_pause/resume`, `on_visibility_changed`). `GameClock.advance` с clamp и one-shot discard после resume реализует foundation-runtime — здесь только политика и тесты на стыке. Запрещено `SceneTree.paused`. `_compose()` посеет `is_visible()` один раз (ADR-0001) — вне этой истории.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- foundation-runtime: GameClock.advance/clamp
- hud epic: кнопка паузы

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/Feel and UI evidence is not waived (see coding-standards).*

**Story Type**: Logic
**Required evidence**:
- `tests/unit/guest/match-pause-ownership_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002
- Unlocks: См. таблицу зависимостей эпика
