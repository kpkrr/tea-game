# Story 009: MatchDirector: polled Booting, fail_boot на невалидном конфиге, dispose

> **Epic**: Foundation Runtime (Clock, Director, Config, Save)
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: — (инфраструктура из ADR-0003/0004/0005; обслуживает все GDD)
**Requirement**: ADR-0003 / ADR-0004 (boot-путь и жизненный цикл); поддерживает `TR-platform-013`
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
- Required (from ADR-0004): каждое тюнинг-значение из GameConfig-подресурса, `@export` со статическим типом и sentinel-дефолтом; новое поле шипится вместе с правилом валидатора

---

## Acceptance Criteria

*From the TR-IDs / ADR guidelines above, scoped to this story:*

- [ ] В `Booting` `_process` не симулирует, только опрашивает sub-state (`NAV_WAIT -> PREWARM_WAIT -> DONE`) без `await`; по завершении вызывает `PlatformBridge.mark_boot_complete()` (готово -> `ready_reached` -> `IDLE`, `match_started` не эмитится сам)
- [ ] Невалидный конфиг (любая ошибка `ConfigLoader`) -> `fail_boot(message)` со списком всех ошибок, симуляция не стартует, `ready_reached` не эмитится
- [ ] `dispose()` в `_exit_tree` отключает все сигналы и обнуляет ссылки; gdUnit4 orphan-check чистый после создания/уничтожения директора и spy-модулей
- [ ] Перед первым матчем состояние видимости из `PlatformBridge.is_visible()` применяется к lifecycle (скрытая вкладка при загрузке -> пауза)

---

## Implementation Notes

Port from `feature/match_director.gd` (`_step_boot`, `_on_ready_reached`, `_exit_tree`). Pathing/RenderPrewarm принадлежат другим эпикам — здесь poll-контракт (`poll_ready()`/`prewarm_done`) с заглушками. Строку локализации в `fail_boot` привести к английскому (в срезе RU-текст; проект English-only UI).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 008: порядок тика
- Pathing.verify и RenderPrewarm — navigation/perf эпики
- HTML-экран ошибки — platform-shell story 005

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/match_director/match_director_boot_test.gd` — must exist and pass (или документированный playtest)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003, 004, 007, 008
- Unlocks: platform-shell 008
