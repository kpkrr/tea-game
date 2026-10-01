# Story 001: HudConfig data and read-only upstream accessors

> **Epic**: HUD & Feedback UI (in-match)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/hud-feedback-ui.md`
**Requirement**: `TR-hud-019`, `TR-hud-020`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Data config & load-time validation
**ADR Decision Summary**: GameConfig + .tres sub-resources, ConfigValidator collects all errors at load, RNG injected; AudioConfig and HudConfig are sub-resources.
**ADR Version**: 2026-09-30
**Secondary ADRs**:
- ADR-0003: Match simulation - clock, tick order, pause (Last Verified 2026-09-30)

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: Custom Resource scripts with @export; no post-cutoff API.

**Port source**: `prototypes/tea-rush-vertical-slice/src/presentation/hud.gd` (bring to standards: static typing, doc comments, DI, no cached state)

Все константы тюнинга HUD (patience_warn_threshold, results_fade_ms, restart_input_grace_ms, results_countup_ms, popup_arc_ms, hud_min_strip_dp, длительности пульсов) живут в `HudConfig` (.tres), валидируются `ConfigValidator`. Чужие константы (till_capacity, max_guests_lost, combat-значения) HUD только читает.

**Control Manifest Rules (this layer)** *(derived from ADRs — no manifest)*:
- Required (from ADR-0004): tuning constants come from HudConfig sub-resource, never literals; other systems' constants are read-only
- Required (from ADR-0004): ConfigValidator collects ALL errors at load and fails the boot on invalid HudConfig
- Forbidden (from ADR-0004): HUD writing or mirroring other systems' config values

---

## Acceptance Criteria

*From `design/gdd/hud-feedback-ui.md`, scoped to this story:*

- [ ] `HudConfig` содержит все ключи из GDD Tuning Knobs (§Tuning Knobs) с дефолтами и диапазонами; `ConfigValidator` отвергает значения вне диапазона и собирает все ошибки за один проход
- [ ] В `src/presentation/hud/` нет числовых литералов тюнинга (скан grep по списку ключей), а `till_capacity` / `max_guests_lost` читаются только через публичные геттеры владельцев
- [ ] Значения из .tres загружаются в тесте без запуска сцены

---

## Implementation Notes

- Port from `prototypes/tea-rush-vertical-slice/src/presentation/hud.gd` (bring to standards: static typing, doc comments, DI, no cached state) — вынести захардкоженные константы слайса в `HudConfig`.
- Ключи и единицы: `design/gdd/hud-feedback-ui.md` §Tuning Knobs.
- Предоставить `HudConfig` через DI из корня композиции (ADR-0004), без autoload-синглтона.

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- Story 002: HUD shell и state machine
- Любые визуальные элементы

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/UI evidence is not waived (see coding-standards: a parse check is not a run).*

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/hud/hud_config_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (needs Foundation epics: data-config, game-clock)
- Unlocks: 002, 003, 005, 006, 010
