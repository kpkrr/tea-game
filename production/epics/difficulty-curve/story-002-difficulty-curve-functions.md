# Story 002: DifficultyCurve: progress и три кривые

> **Epic**: Difficulty Curve & Session Pacing
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/difficulty-curve-session-pacing.md`
**Requirement**: `TR-pacing-001`, `TR-pacing-002`, `TR-pacing-006`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Data config & load-time validation
**ADR Decision Summary**: Константы — в подресурсах GameConfig (.tres), ConfigValidator собирает все ошибки с именем константы, модули получают конфиг конструктором, RNG — инъекцией (отдельные потоки guest_tier / guest_recipe), кривые — статические функции DifficultyCurve (не Curve).
**ADR Version**: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: LOW (Resource/@export/duplicate_deep 4.5+ — сверить с breaking-changes.md)

`progress = clamp(t/ramp_duration, 0, 1)^exponent`; гостей/мин 15→18, терпение 50→25, доля сложных 0→0,40; плато при t ≥ ramp_duration.

**Control Manifest Rules (from ADR; no manifest at this tier)**:
- Required: все значения из GDD Tuning Knobs — из подресурса GameConfig с sentinel-default и правилом ConfigValidator в том же изменении (from ADR-0004)
- Forbidden: литералы настроек в коде; глобальные `randf()/randi()/randomize()`; `load()`/`preload()` конфига внутри модуля; запись в конфиг (from ADR-0004)
- Guardrail: тесты строят конфиг через `ConfigFactory.valid()` + override, не читают .tres с диска (кроме одного интеграционного) (from ADR-0004)

---

## Acceptance Criteria

*From GDD `design/gdd/difficulty-curve-session-pacing.md`, scoped to this story:*

- [ ] t = 0 / 30 / 90 / 120 → progress 0.0 (точно) / 0.02778 / 0.25 / 0.44444; t < 0 → 0.0; t = 180 / 600 → 1.0 точно; t = 179.75 → 0.99722 (AC 5–6).
- [ ] gpm(t) 15.0 / 15.0833 / 15.75 / 16.3333 / 18.0 / 18.0; patience 50.0 / 49.3056 / 43.75 / 38.8889 / 25.0 / 25.0; complex 0.0 / 0.01111 / 0.10 / 0.17778 / 0.40 / 0.40 (AC 9–11).
- [ ] Свип t = 0…600 шагом 0.25: значения в диапазонах, монотонны (gpm и complex не убывают, patience не возрастает); изменение только `guests_per_minute_end` не трогает остальные кривые (AC 7–8, 12).

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/feature/difficulty_curve.gd` (`progress`, `guests_per_minute`, `patience_max`, `complex_order_share` — статические функции, сейчас `d: Resource`). Типизировать параметр как `DifficultyConfig`, сигнатура `f(t: float, c: DifficultyConfig) -> float` по ADR-0004. Убрать defensive-fallback `v if v > 0 else start` из кривой: откат — ответственность Guest AI (Rule 12, guest-sim story 007), кривая чистая. `Curve`-ресурсы запрещены. Допуск float ±0.001; на границах clamp — точное равенство.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: чистота/детерминизм
- Story 004: контракт с Guest AI

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/Feel and UI evidence is not waived (see coding-standards).*

**Story Type**: Logic
**Required evidence**:
- `tests/unit/difficulty_curve/difficulty-curve-functions_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001
- Unlocks: См. таблицу зависимостей эпика
