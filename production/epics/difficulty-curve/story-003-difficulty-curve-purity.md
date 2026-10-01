# Story 003: Чистота, отсутствие состояния и детерминизм кривых

> **Epic**: Difficulty Curve & Session Pacing
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/difficulty-curve-session-pacing.md`
**Requirement**: `TR-pacing-003`, `TR-pacing-004`, `TR-pacing-007`, `TR-pacing-009`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Match simulation — clock, tick order, pause
**Secondary ADRs**: ADR-0004: Data config & load-time validation (Version 2026-09-30)
**ADR Decision Summary**: MatchDirector._process — единственный драйвер; GameClock (RefCounted) — единственный источник паузы (флаги hidden/frozen, без SceneTree.paused); фиксированный порядок тика; MatchLifecycle владеет политикой партии; типизированные синхронные сигналы, проводка только в _compose().
**ADR Version**: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: LOW (домен Core; `_process`, типизированные сигналы на RefCounted — до cutoff и без изменений в 4.4–4.7)

Кривые — функции только от `t` и загруженных данных: не зависят от паузы, кассы, `guests_lost`, номера партии.

**Control Manifest Rules (from ADR; no manifest at this tier)**:
- Required: sim-модули — `RefCounted` с `step(dt)`; без `_process`/`_physics_process`, без `Time`/`OS`/`Engine` времени (from ADR-0003)
- Forbidden: `get_tree().paused`, `_physics_process`, ссылки на autoload по имени, лямбды и `.bind()` в сигналах между RefCounted, `CONNECT_DEFERRED` (from ADR-0003)
- Required: все значения из GDD Tuning Knobs — из подресурса GameConfig с sentinel-default и правилом ConfigValidator в том же изменении (from ADR-0004)
- Forbidden: литералы настроек в коде; глобальные `randf()/randi()/randomize()`; `load()`/`preload()` конфига внутри модуля; запись в конфиг (from ADR-0004)

---

## Acceptance Criteria

*From GDD `design/gdd/difficulty-curve-session-pacing.md`, scoped to this story:*

- [ ] Партии A (guests_lost 0, касса пуста) и B (guests_lost 2, касса полна, 5-я партия) при t = 90 получают 15.75 / 43.75 / 0.10; публичный API принимает только `t` и конфиг (проверка `get_method_list()`) (AC 13).
- [ ] Порядок вызовов f(120), f(90), f(90) не влияет на результат (0.25 / 15.75 / 43.75 / 0.10); два экземпляра дают побитово равные значения (AC 14).
- [ ] В `DifficultyCurve` нет полей состояния, ссылок на Till/Currency/Clock (статический класс без `var`).

---

## Implementation Notes

Класс `DifficultyCurve` — только `static func`, без полей. Побитовое равенство проверять `==` на float, а не `is_equal_approx`. Любой источник времени (`Time`, `OS`) запрещён (ADR-0003).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 004: стык с GuestSim

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/Feel and UI evidence is not waived (see coding-standards).*

**Story Type**: Logic
**Required evidence**:
- `tests/unit/difficulty_curve/difficulty-curve-purity_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002
- Unlocks: См. таблицу зависимостей эпика
