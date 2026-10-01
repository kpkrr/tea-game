# Story 001: GameClock: игровое время, пауза и clamp шага

> **Epic**: Foundation Runtime (Clock, Director, Config, Save)
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: — (инфраструктура из ADR-0003/0004/0005; обслуживает все GDD)
**Requirement**: `TR-guest-016`, `TR-brewing-010`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Match simulation — clock, tick order, pause
- Secondary: ADR-0004: Data config & load-time validation (Last Verified 2026-09-30)
**ADR Decision Summary**: GameClock + MatchDirector: фиксированный порядок тика в одной функции `_process` (priority -100), без SceneTree.paused/_physics_process, типизированные сигналы, DI в `_compose()`.
**ADR Version**: 2026-09-30 (Last Verified)

**Engine**: Godot 4.7.2 | **Risk**: LOW (engine overall HIGH)
**Engine Notes**: Post-cutoff APIs: none. Проверить на устройстве: hidden-время не попадает в sim, первый кадр после возврата ≤ max_step_delta, callback не внутри _process (_in_tick assert).

**Control Manifest Rules (this layer)**:
- Required (from ADR-0003): симуляционные модули — `RefCounted` с `step(dt)`; только `MatchDirector._process` вызывает `step()`/`clock.advance()`/`apply_pending()`; сигналы типизированные, подключаются в `_compose()`, без `CONNECT_DEFERRED`
- Forbidden (from ADR-0003): `SceneTree.paused`, `_physics_process`, `Time`/`OS`/`Engine` время в симуляции, `await` в `_process`, лямбды/`.bind()` между RefCounted-модулями
- Guardrail (from ADR-0003/0007): тик MatchDirector укладывается в бюджет ADR-0007 (сумма модулей ≤ 16.6 мс, 30 fps пол)

---

## Acceptance Criteria

*From the TR-IDs / ADR guidelines above, scoped to this story:*

- [ ] `advance(real_delta)` возвращает `min(max(real_delta,0), max_step_delta)`; `max_step_delta` приходит из конструктора (значение 0,25 с — из конфига, не литерал); спайк в 10 с даёт `sim_dt` = 0,25
- [ ] `pause()`/`freeze()` -> `sim_dt == 0`; `pause()` также обнуляет `ui_dt`; после `resume()` первый кадр несёт 0 времени (скрытое время отбрасывается), следующий — обычный шаг
- [ ] `running_changed(bool)` эмитится только при реальной смене `is_running()`; `reset()` обнуляет `t` и снимает freeze; `t`/`sim_dt`/`ui_dt` не присваиваются снаружи

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/foundation/game_clock.gd` (74 строки, уже соответствует ADR-0003). Работа: положить в `src/foundation/game_clock.gd`, убрать VERTICAL SLICE-шапку, Статическая типизация везде, doc-комментарии (`##`) на публичном API, зависимости через конструктор (DI), без синглтонов. Read-only поля — `_private` + getter (уже так). Убедиться, что в файле нет обращений к `Time`/`OS`. Тест кладёт конструкторный параметр из `ConfigFactory` (story 002), а не литерал 0.25, кроме boundary-кейса.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: GameConfig/ConfigFactory, откуда приходит `max_step_delta`
- Story 008: порядок тика и вызов `advance()` из MatchDirector
- Feature-эпики (Brewing/Guest): сами таймеры на `sim_dt`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/game_clock/game_clock_step_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (значение `max_step_delta` в тесте — через локальную константу до story 002)
- Unlocks: Story 008
