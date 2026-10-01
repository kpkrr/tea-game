# Story 004: Валидация структуры рецептов при загрузке

> **Epic**: Order & Recipe System
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/order-recipe-system.md`
**Requirement**: `TR-recipe-005`, `TR-recipe-006`, `TR-recipe-007`, `TR-recipe-008`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Data config & load-time validation
**ADR Decision Summary**: Конфиг - типизированные Resource (.tres) под корнем GameConfig, поля с sentinel-значениями, единый ConfigValidator собирает все ошибки во всех сборках, конфиг неизменяем после загрузки и инжектится через конструкторы, RNG - инъектируемый.
**ADR Version**: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: Custom Resource + @export - до-cutoff API. Проверено на 4.7.2: неверные типы в .tres молча приводятся ("abc" -> 0.0), поэтому обязателен CI-тест отгружаемых значений. duplicate_deep() (4.5) - только в фикстурах тестов; .tres-деревья копировать с DEEP_DUPLICATE_ALL.

**Control Manifest Rules (derived from governing ADRs — no manifest exists)**:
- Required (from ADR-0004): ConfigValidator чистая функция, собирает ВСЕ ошибки (path, rule, message), работает в debug и release одинаково.
- Required (from ADR-0004): при любой ошибке модули матча не создаются, вызывается `fail_boot` (MatchDirector._compose) - частично доступных рецептов нет.
- Required (from ADR-0004): unit-тесты строят конфиг через фабрику (`RecipeFixtures` + переопределения), не из .tres.

---

## Acceptance Criteria

*From GDD `design/gdd/order-recipe-system.md`, scoped to this story:*

- [ ] Первый шаг не `cup`, последний не `serve`, пустой список шагов или повторный `serve` -> ошибка с ID рецепта (AC 2, 21); проверка не срабатывает на валидных данных MVP.
- [ ] Шаг, которого нет в `station_types` (например `honey` в `black_tea`), -> ошибка, сообщение содержит `black_tea` и `honey`; `serve` в `station_types` отсутствует (AC 3, 18).
- [ ] Два рецепта с одинаковой последовательностью -> ошибка с обоими ID; префикс (`black_tea` внутри `black_tea_lemon`) дубликатом не считается (AC 22-23).
- [ ] Удаление единственного рецепта уровня -> ошибка, называющая пустой уровень; число рецептов != 5 -> ошибка (AC 24, TR-recipe-001).

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/foundation/config/config_validator.gd` -> `_check_recipes` (строки ~106-142) как отдельную функцию `_validate_recipes(cfg, errors)` внутри общего `ConfigValidator` (ADR-0004 §2: per-system функции, общий класс, чтобы кросс-проверки recipe <-> kitchen имели один дом).

- В слайсе ошибка - `Dictionary` `{path, rule, message}`; привести к `ConfigError` из foundation-runtime (если класса ещё нет - создать минимальный `ConfigError` здесь и согласовать).
- `path` в точечной нотации: `recipes.recipes[2].steps`; `rule` - `&"missing"|&"range"|&"invariant"`.
- `station_types` приходит из `KitchenConfig` (kitchen-layout epic); в тестах - константа из фикстуры.
- Каждое правило не прерывает проверку: один прогон должен вернуть все нарушения.
- Кросс-проверка `station_types == станции кухни` принадлежит kitchen-layout/foundation-runtime, здесь только шаги рецептов.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 005: цены и инварианты.
- Story 007: прогон отгружаемых данных.
- Foundation-runtime epic: `ConfigLoader`, `ConfigError`, `fail_boot`.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`.*

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/order_recipe/order_recipe_validation_test.gd` - must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001; foundation-runtime (`ConfigValidator`/`ConfigError`)
- Unlocks: Story 005, 007
