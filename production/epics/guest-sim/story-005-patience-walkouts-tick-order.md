# Story 005: Терпение, уход по таймауту и порядок тика

> **Epic**: Guest AI & Patience + Match Lifecycle
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/guest-ai-patience.md`
**Requirement**: `TR-guest-005`, `TR-guest-009`, `TR-guest-010`, `TR-guest-011`, `TR-guest-013`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Match simulation — clock, tick order, pause
**ADR Decision Summary**: MatchDirector._process — единственный драйвер; GameClock (RefCounted) — единственный источник паузы (флаги hidden/frozen, без SceneTree.paused); фиксированный порядок тика; MatchLifecycle владеет политикой партии; типизированные синхронные сигналы, проводка только в _compose().
**ADR Version**: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: LOW (домен Core; `_process`, типизированные сигналы на RefCounted — до cutoff и без изменений в 4.4–4.7)

`remaining_fraction = clamp(1 − t/patience_max_g, 0, 1)`; `patience_max_g` фиксируется при спавне; порядок тика: подачи → таймауты → конец → спавн; подача побеждает таймаут; на 3-м уходе — заморозка.

**Control Manifest Rules (from ADR; no manifest at this tier)**:
- Required: sim-модули — `RefCounted` с `step(dt)`; без `_process`/`_physics_process`, без `Time`/`OS`/`Engine` времени (from ADR-0003)
- Forbidden: `get_tree().paused`, `_physics_process`, ссылки на autoload по имени, лямбды и `.bind()` в сигналах между RefCounted, `CONNECT_DEFERRED` (from ADR-0003)
- Guardrail: запрос, меняющий партию (`request_new_match`), не вызывается реентерабельно из обработчика сигнала — ставится в очередь и применяется на шаге 0 (from ADR-0003)

---

## Acceptance Criteria

*From GDD `design/gdd/guest-ai-patience.md`, scoped to this story:*

- [ ] Formula 2: (t_since_spawn, patience_max) → 1.0 / 0.6 / 0.25 / 0.0 / 0.0 / 0.6 для набора из GDD; при 49.75/50 гость в Waiting с 0.005 (AC 21–22).
- [ ] `patience_max(t)` меняется после спавна — гость уходит по значению на момент спавна (AC 24); терпение тикает с момента спавна, включая Approaching.
- [ ] Терпение доходит до 0 в том же шаге, когда подача состоялась — гость Served, страйка нет (AC 23); два таймаута в одном шаге обрабатываются в порядке слотов.
- [ ] `guests_lost` = 2 + уход → `guests_lost` = 3, заморозка, шаг (d) спавна пропускается, `match_ended` ровно один раз (AC 25–27).

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/feature/guest_sim.gd`: `remaining_fraction`, блоки (b) walkouts и (c) end check в `step`, `guests_lost_reached`. Сигнал `guests_lost_reached` соединяет `_compose()` с `MatchLifecycle.on_guests_lost_reached`. Уходящий гость дорисовывается до выхода (`departing`) уже после конца партии (AC 28) — не блокирует freeze. `target_vanished(slot)` эмитится при уходе.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 006: подача (шаг a)
- Story 002: реализация match_ended

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/Feel and UI evidence is not waived (see coding-standards).*

**Story Type**: Logic
**Required evidence**:
- `tests/unit/guest/patience-walkouts-tick-order_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 002, 004
- Unlocks: См. таблицу зависимостей эпика
