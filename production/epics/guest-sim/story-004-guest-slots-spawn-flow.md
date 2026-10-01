# Story 004: GuestSim: слоты, интервал спавна, отложенный спавн

> **Epic**: Guest AI & Patience + Match Lifecycle
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/guest-ai-patience.md`
**Requirement**: `TR-guest-001`, `TR-guest-003`, `TR-guest-004`, `TR-guest-021`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Match simulation — clock, tick order, pause
**Secondary ADRs**: ADR-0004: Data config & load-time validation (Version 2026-09-30)
**ADR Decision Summary**: MatchDirector._process — единственный драйвер; GameClock (RefCounted) — единственный источник паузы (флаги hidden/frozen, без SceneTree.paused); фиксированный порядок тика; MatchLifecycle владеет политикой партии; типизированные синхронные сигналы, проводка только в _compose().
**ADR Version**: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: LOW (домен Core; `_process`, типизированные сигналы на RefCounted — до cutoff и без изменений в 4.4–4.7)

Четыре слота со стабильными ID; `spawn_interval = 60 / (gpm(t) × onboarding_multiplier)` фиксируется при спавне; при занятых слотах таймер даёт максимум один отложенный спавн; выбирается свободный слот с наименьшим ID.

**Control Manifest Rules (from ADR; no manifest at this tier)**:
- Required: sim-модули — `RefCounted` с `step(dt)`; без `_process`/`_physics_process`, без `Time`/`OS`/`Engine` времени (from ADR-0003)
- Forbidden: `get_tree().paused`, `_physics_process`, ссылки на autoload по имени, лямбды и `.bind()` в сигналах между RefCounted, `CONNECT_DEFERRED` (from ADR-0003)
- Required: все значения из GDD Tuning Knobs — из подресурса GameConfig с sentinel-default и правилом ConfigValidator в том же изменении (from ADR-0004)
- Forbidden: литералы настроек в коде; глобальные `randf()/randi()/randomize()`; `load()`/`preload()` конфига внутри модуля; запись в конфиг (from ADR-0004)

---

## Acceptance Criteria

*From GDD `design/gdd/guest-ai-patience.md`, scoped to this story:*

- [ ] baseline: t = 0 → 4.0 с, t = 60 при 18 гост/мин → 3.333333; новая партия спавнит первого гостя в первом шаге (t = 0) (AC 5–6).
- [ ] 4 слота заняты, интервал истёк: одна отложенная заявка; при 60 с занятости в очереди не копится больше одного; освободившийся слот занимается в том же тике (AC 9–11).
- [ ] Слоты ID 10/20/30/40, заняты 20 и 40 → новый гость получает 10; освобождение слота при Served/Leaving (AC 12–13).
- [ ] Состояния гостя Approaching → Waiting → {Served | Leaving} → удалён; переходы только по правилам GDD.

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/feature/guest_sim.gd`: `reset`, `spawn_interval`, `_spawn`, блок `(d) spawn` в `step`, `_deferred`, `GState`. Привести к стандартам: слот — типизированный `GuestState` (RefCounted/inner class) вместо Dictionary, ID слота из KitchenConfig, зависимости (clock, config, curve, book, rng, navigator) — в конструктор. Интервал считать через `DifficultyCurve` (статические функции) в момент спавна. `onboarding_multiplier` — множитель ≤ 1 из конфига; в онбординге спавн не замедляется (×1.0 по TR-guest-014, см. story 007).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 005: терпение и уходы
- Story 006: подача
- Story 007: выбор рецепта и онбординг
- Story 008: путь до слота

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/Feel and UI evidence is not waived (see coding-standards).*

**Story Type**: Logic
**Required evidence**:
- `tests/unit/guest/guest-slots-spawn-flow_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001; difficulty-curve stories 001–002
- Unlocks: См. таблицу зависимостей эпика
