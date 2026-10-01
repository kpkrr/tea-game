# Story 004: Контракт с Guest AI: значения при спавне, онбординг, сброс t

> **Epic**: Difficulty Curve & Session Pacing
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/difficulty-curve-session-pacing.md`
**Requirement**: `TR-pacing-005`, `TR-pacing-010`, `TR-pacing-011`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Data config & load-time validation
**Secondary ADRs**: ADR-0003: Match simulation — clock, tick order, pause (Version 2026-09-30)
**ADR Decision Summary**: Константы — в подресурсах GameConfig (.tres), ConfigValidator собирает все ошибки с именем константы, модули получают конфиг конструктором, RNG — инъекцией (отдельные потоки guest_tier / guest_recipe), кривые — статические функции DifficultyCurve (не Curve).
**ADR Version**: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: LOW (Resource/@export/duplicate_deep 4.5+ — сверить с breaking-changes.md)

Guest AI читает кривые при спавне (`t_spawn`) и фиксирует значения; онбординг (15 с) применяет Guest AI, не кривая; `t` сбрасывается по `match_started`.

**Control Manifest Rules (from ADR; no manifest at this tier)**:
- Required: все значения из GDD Tuning Knobs — из подресурса GameConfig с sentinel-default и правилом ConfigValidator в том же изменении (from ADR-0004)
- Forbidden: литералы настроек в коде; глобальные `randf()/randi()/randomize()`; `load()`/`preload()` конфига внутри модуля; запись в конфиг (from ADR-0004)
- Required: sim-модули — `RefCounted` с `step(dt)`; без `_process`/`_physics_process`, без `Time`/`OS`/`Engine` времени (from ADR-0003)
- Forbidden: `get_tree().paused`, `_physics_process`, ссылки на autoload по имени, лямбды и `.bind()` в сигналах между RefCounted, `CONNECT_DEFERRED` (from ADR-0003)

---

## Acceptance Criteria

*From GDD `design/gdd/difficulty-curve-session-pacing.md`, scoped to this story:*

- [ ] Гость при t = 90: `patience_max_g` = 43.75 фиксирован и при t = 120 остаётся 43.75 (`remaining_fraction` = 0.31429); отложенный спавн в t = 120 берёт 38.8889, интервал 3.6735 с и `complex_order_share` 0.17778 (AC 18–19).
- [ ] Интервал при `t_spawn` = 0 / 15 / 30 / 90 → 4.0 / 3.9945 / 3.9779 / 3.8095 с; кривая не применяет онбординг сама (gpm(15) = 15.0208, complex(20) = 0.00494); при complex share 1.0 гости t < 15 — simple, первый при t ≥ 15 — complex (AC 16–17).
- [ ] После партии до t = 200 новая партия начинает с t = 0: первый гость с patience 50.0, интервал 4.0 с; пауза 600 кадров не сдвигает `t` (AC 15, 20); симуляция 300 с без единой записи fallback/clamp Guest AI (AC 21).

---

## Implementation Notes

Интеграционные тесты с настоящей `DifficultyCurve` и `GuestSim` (внешний `step(0.25)`). `guests_per_minute_start` = 15.0 проверяется как согласованность data file (TR-pacing-011). Код Guest AI, читающий кривые, — guest-sim stories 004/007.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 006: плейтест

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/Feel and UI evidence is not waived (see coding-standards).*

**Story Type**: Integration
**Required evidence**:
- `tests/integration/difficulty_curve/difficulty-guest-ai-contract_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 002, 003; guest-sim stories 004, 007
- Unlocks: См. таблицу зависимостей эпика
