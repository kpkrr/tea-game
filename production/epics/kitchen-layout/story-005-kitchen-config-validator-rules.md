# Story 005: ConfigValidator: station_types, footprints, слоты, мусорка

> **Epic**: Kitchen & Station Layout
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/kitchen-station-layout.md`
**Requirement**: `TR-layout-009`, `TR-layout-013`, `TR-layout-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Data config & load-time validation
**ADR Decision Summary**: Конфиг — типизированные `Resource` (`ViewConfig`, `KitchenConfig`, …) в `.tres` под `GameConfig`; sentinel-поля (`NAN`/`-1`), один чистый `ConfigValidator` собирает все ошибки в debug и release; модули получают конфиг через конструктор.
**ADR Version**: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: Pre-cutoff API (`Resource` + `@export`); неверные типы в `.tres` коэрсятся молча — нужен CI-тест на shipped-значения.

**Control Manifest Rules (from ADR; no control manifest at this tier)**:
- Required: `@export`-поля со статическим типом и sentinel; новое поле — вместе с правилом валидатора; конфиг через конструктор *(from ADR-0004)*
- Forbidden: литералы для tuning-значений; `load()` конфига в модулях; запись в конфиг *(from ADR-0004)*
- Guardrail: валидатор собирает все ошибки с dotted-путём в debug и release *(from ADR-0004)*

Ошибки данных кухни должны ловиться при загрузке, а не в матче. Правила валидатора ADR-0004 для `KitchenConfig` собирают все нарушения сразу (dotted-путь к полю).

---

## Acceptance Criteria

*From GDD and ADR, scoped to this story:*

- [ ] GIVEN `station_types`, WHEN валидатор, THEN список точно совпадает с множеством расставленных станций рецепта: нет станции без типа и нет типа без станции; слоты (`slot`) и мусорка (`trash`) в `station_types` не входят; `trash` ровно одна
- [ ] GIVEN footprints станций, столешниц и стен, WHEN валидатор, THEN любое пересечение даёт ошибку `invariant` с id обеих сторон
- [ ] GIVEN `slots`, THEN ровно 7 (5 island + по 1 на боковых стенах), уникальные id и уникальные точки взаимодействия; все точки внутри `floor_rect`; нарушение даёт ошибку, валидатор собирает все ошибки за один проход

---

## Implementation Notes

Новые правила (в слайсе проверка `station_types` делалась только тестом в `slice_logic_test.gd` — см. `test_*station_types*` — перенести как правило валидатора). Регистрировать в `ConfigValidator` (foundation-runtime); до его появления — чистая функция `KitchenConfigRules.validate(cfg: KitchenConfig) -> Array[ConfigError]`. Тесты строят `KitchenConfig` фабрикой с точечными override (пересекающиеся футпринты, лишний тип, 6 слотов, вторая мусорка) — не читают `.tres`. Плюс один тест на shipped `kitchen.tres`: ошибок 0. Цифры 7/5/1/1 — из GDD (Core Rule 3), держать в конфиге/реестре, не литералами в правилах.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Сборка `KitchenLayout` (Story 004)
- Кросс-системная проверка `recipe.steps ⊆ station_types` — эпик recipe-book

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/kitchen_layout/kitchen_layout_validator_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001, 002, 003
- Unlocks: Story 006
