# Story 001: DifficultyConfig: ресурс и валидация при загрузке

> **Epic**: Difficulty Curve & Session Pacing
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/difficulty-curve-session-pacing.md`
**Requirement**: `TR-pacing-008`, `TR-pacing-011`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Data config & load-time validation
**ADR Decision Summary**: Константы — в подресурсах GameConfig (.tres), ConfigValidator собирает все ошибки с именем константы, модули получают конфиг конструктором, RNG — инъекцией (отдельные потоки guest_tier / guest_recipe), кривые — статические функции DifficultyCurve (не Curve).
**ADR Version**: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: LOW (Resource/@export/duplicate_deep 4.5+ — сверить с breaking-changes.md)

Подресурс `GameConfig.difficulty`; ошибки загрузки блокируют старт партии; `guests_per_minute_start` = 15,0 синхронизирован с Guest AI.

**Control Manifest Rules (from ADR; no manifest at this tier)**:
- Required: все значения из GDD Tuning Knobs — из подресурса GameConfig с sentinel-default и правилом ConfigValidator в том же изменении (from ADR-0004)
- Forbidden: литералы настроек в коде; глобальные `randf()/randi()/randomize()`; `load()`/`preload()` конфига внутри модуля; запись в конфиг (from ADR-0004)
- Guardrail: тесты строят конфиг через `ConfigFactory.valid()` + override, не читают .tres с диска (кроме одного интеграционного) (from ADR-0004)

---

## Acceptance Criteria

*From GDD `design/gdd/difficulty-curve-session-pacing.md`, scoped to this story:*

- [ ] Отгружаемый data file: ramp_duration 180, curve_exponent 2.0, gpm 15→18, patience 50→25, complex_share 0.0→0.40 — без ошибок (AC 1).
- [ ] `ramp_duration` ≤ 0, `curve_exponent` ∉ [1.0, 3.0], нулевые/отрицательные старт-значения, `complex_share` вне [0, 1], NaN/INF/пропуск/строка — ошибка с именем константы (AC 2–3); границы 1.0 и 3.0 проходят.
- [ ] Обратное направление (`_end` легче `_start`) — ошибка; `_end` = `_start` проходит (AC 4); `guests_per_minute_start` не равный значению, ожидаемому Guest AI (15,0) — ошибка или явное предупреждение.

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/foundation/config/difficulty_config.gd` (8 полей, NaN-sentinel). Добавить правила `ConfigValidator` в том же изменении; доп. проверка `_end` не легче `_start` для всех трёх кривых. Тесты — через `ConfigFactory.valid()` + override.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: сами функции кривых

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/Feel and UI evidence is not waived (see coding-standards).*

**Story Type**: Logic
**Required evidence**:
- `tests/unit/difficulty_curve/difficulty-config-validation_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: foundation-runtime (GameConfig, ConfigValidator)
- Unlocks: См. таблицу зависимостей эпика
