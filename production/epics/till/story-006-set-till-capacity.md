# Story 006: Set till_capacity after owner measurements

> **Epic**: Till & Day Cycle
> **Status**: Blocked (reason: owner playtest — замеры скорости игрока ещё не получены)
> **Layer**: Feature
> **Type**: Config/Data
> **Estimate**: S
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/till-day-cycle.md`
**Requirement**: `TR-till-001`
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

- [ ] Владелец предоставил замеры реальной скорости (`k`) и принял решение: 250 (править копирайт на «~2 партии, ~7 мин»), ~400 (шкала уровней 400/550/800/1100) или оставить до замеров
- [ ] `assets/data/config/till.tres` содержит итоговое `till_capacity`; shipped-значение проходит `ConfigValidator` (CI-тест)
- [ ] При изменении значения выполнен `/propagate-design-change design/gdd/till-day-cycle.md` (registry `till_capacity`, game-concept, systems-index); тестовые числа GDD AC 2–5, 16, 20–22, 38–39 обновлены или параметризованы

---

## Implementation Notes

Открытый пункт баланса: `design/balance/balance-check-till-day-cycle-2026-10-01.md` — `till_capacity = 250` держится на устаревших входах; при реальной скорости ≈ 1.8 партии вместо ~3; кандидат ~400. Рекомендация отчёта (c): не менять до замера. Код менять не нужно — только данные и документы. Юнит-тесты остальных историй используют `ConfigFactory` с явной ёмкостью, поэтому от значения не зависят.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Любые изменения логики Till

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**:
- Config/Data: smoke check pass (`production/qa/smoke-*.md`) + `tests/unit/till/till_shipped_config_test.gd` (CI-проверка shipped-значений)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Owner playtest measurements (внешний блокер); story 001
- Unlocks: Закрытие эпика (не блокирует остальные истории)
