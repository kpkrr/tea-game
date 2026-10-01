# Story 008: MatchDirector: порядок тика, step 0/6, корень композиции

> **Epic**: Foundation Runtime (Clock, Director, Config, Save)
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: — (инфраструктура из ADR-0003/0004/0005; обслуживает все GDD)
**Requirement**: `TR-guest-016`, `TR-brewing-010` (clamp применяется в тике)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Match simulation — clock, tick order, pause
- Secondary: ADR-0004: Data config & load-time validation (Last Verified 2026-09-30)
- Secondary: ADR-0005: Local persistence (SaveStore) (Last Verified 2026-09-30)
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

- [ ] `MatchDirector._process` (`process_priority = -100`) — единственный вызывающий `lifecycle.apply_pending()` (0) -> `clock.advance()` (1) -> `flush_tap` (2) -> barista (3) -> brewing (4) -> guests (5) -> `save.flush_if_dirty()` (6); порядок проверен тестом на spy-модулях, шаг 6 выполняется и при `dt == 0`
- [ ] `_compose()` — единственное место, где создаются модули, инжектируются `GameConfig`/`Rng`/`UtcClock`/`SaveScope` и подключаются типизированные сигналы (без `CONNECT_DEFERRED`, без лямбд/`.bind()` между RefCounted); модули не обращаются к автозагрузкам по имени, `PlatformBridge` трогает только `_compose()`
- [ ] Гейм-пауза НЕ использует `get_tree().paused`; при `clock` остановленном шаги 3–5 не выполняются; запрос нового матча/quit ставится в очередь и применяется на step 0 (повторный/ранний запрос игнорируется), а обработчик сигнала не вызывает `step()`/`advance()` реентерабельно
- [ ] Debug-флаг `_in_tick` утверждает, что JS-callback видимости не срабатывает внутри `_process`

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/feature/match_director.gd` (331 строка) `_compose()`/`_process()` в `src/feature/match_director.gd` (или `src/foundation/` — положить по architecture.md; MatchDirector — Foundation-модуль). Feature-модули (Brewing/Guest/Barista/Currency/Till/Lifecycle) приходят из других эпиков: здесь интерфейсы вызова `step(dt)` и сигналы объявляются как тонкие протоколы, в тестах — spy-заглушки. Не переносить debug-части среза (`demo_bot`, `_maybe_screenshot`, `playtest_log`) в продакшен-код. Амендмент 2026-10-01: нет автостарта (`ready_reached` -> IDLE), команды `request_new_match/quit/pause/resume` очередью. Статическая типизация везде, doc-комментарии (`##`) на публичном API, зависимости через конструктор (DI), без синглтонов.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 009: Booting-подстейт, dispose/утечки, fail_boot-путь
- Реализации Brewing/Guest/Barista/Currency/Till/MatchLifecycle — feature-эпики
- PlatformBridge — platform-shell эпик

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/match_director/match_director_tick_order_test.gd` — must exist and pass (или документированный playtest)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001, 002, 005, 006
- Unlocks: Story 009; platform-shell 003, 008
