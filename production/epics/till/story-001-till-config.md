# Story 001: TillConfig и правила валидатора

> **Epic**: Till & Day Cycle
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/till-day-cycle.md`
**Requirement**: `TR-till-001`, `TR-till-006`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Data config & load-time validation
**ADR Decision Summary**: Тюнинг-значения — типизированные `Resource` (`.tres`) с sentinel-дефолтами; один чистый `ConfigValidator` собирает все ошибки во всех сборках; конфиг неизменяем и инъектируется через конструкторы.
**ADR Version**: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: Post-cutoff: только `Resource.duplicate_deep()` (4.5) в тестовых фикстурах. Sentinel: `-1` для int, `NAN` для float; неверные типы молча приводятся — нужен CI-тест на shipped `.tres`.

**Control Manifest Rules (this layer)**:
- Required: каждое тюнинг-значение из GDD — `@export` поле `Resource` со статическим типом и sentinel-дефолтом; новое поле поставляется вместе с правилом валидатора (from ADR-0004)
- Required: конфиг инъектируется через конструктор; в юнит-тестах — фабрика `ConfigFactory.valid()` + оверрайды, не загрузка `.tres` (from ADR-0004)
- Forbidden: числовые литералы тюнинг-значений в коде, `load()`/`preload()` конфига внутри модуля, запись в конфиг (from ADR-0004)

---

## Acceptance Criteria

*From GDD `design/gdd/till-day-cycle.md`, scoped to this story:*

- [ ] `TillConfig` содержит `till_capacity: int = -1` и `daily_reset_time_utc: int = -1`; пропущенное поле → ошибка `missing` по пути `till.till_capacity`/`till.daily_reset_time_utc`; `till_capacity ≥ 1`, `daily_reset_time_utc ∈ [0, 23]` (`range`)
- [ ] `till.tres` поставляется с `daily_reset_time_utc = 0` (00:00 UTC, AC 23) и временным `till_capacity = 250` (итоговое значение — story 006, Blocked); CI-тест загружает shipped `.tres` и валидирует
- [ ] В коде Till нет литералов 250 и 0 как конфигурации — всё через `TillConfig`

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/foundation/config/till_config.gd`. Добавить правила в `ConfigValidator._validate_till`, doc-комментарии, `assets/data/config/till.tres`. Значение `till_capacity = 250` — placeholder: открытый вопрос баланса (`design/balance/balance-check-till-day-cycle-2026-10-01.md`, Rec. 2), см. story 006. Единая константа, не зависит от уровня прокачки (AC 10).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 006: финальное значение `till_capacity`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/till/till_config_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Config-фундамент (`GameConfig`, `ConfigValidator`) из Foundation-эпика
- Unlocks: Story 002–004
