# Story 005: Валидация цен и ценовых инвариантов

> **Epic**: Order & Recipe System
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/order-recipe-system.md`
**Requirement**: `TR-recipe-004`, `TR-recipe-013`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Data config & load-time validation
**ADR Decision Summary**: Конфиг - типизированные Resource (.tres) под корнем GameConfig, поля с sentinel-значениями, единый ConfigValidator собирает все ошибки во всех сборках, конфиг неизменяем после загрузки и инжектится через конструкторы, RNG - инъектируемый.
**ADR Version**: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: Custom Resource + @export - до-cutoff API. Проверено на 4.7.2: неверные типы в .tres молча приводятся ("abc" -> 0.0), поэтому обязателен CI-тест отгружаемых значений. duplicate_deep() (4.5) - только в фикстурах тестов; .tres-деревья копировать с DEEP_DUPLICATE_ALL.

**Control Manifest Rules (derived from governing ADRs — no manifest exists)**:
- Required (from ADR-0004): инварианты цен проверяются и в release (микросекунды); неверные данные = неотгружаемый билд.
- Required (from ADR-0004): арифметика инвариантов в целых числах (умножение на 100 и 10), без float.
- Forbidden (from ADR-0004): менять sentinel `price = -1` на реальное значение - отсутствующий ключ должен читаться как пропуск.

---

## Acceptance Criteria

*From GDD `design/gdd/order-recipe-system.md`, scoped to this story:*

- [ ] Цена - целое >= 1: у `cold_tea` цена 0 и -1 -> ошибка с `cold_tea`; цена 1 проверку проходит; отсутствующая цена (sentinel -1) `green_tea` -> ошибка с `green_tea` (AC 19-20).
- [ ] Отгружаемые цены 2/5/7 проходят оба инварианта; фикстура 2/5/9 -> ошибка, называющая оба нарушенных инварианта; 1/5/7 -> только `сложный <= (простой + средний) x 1.15` (700 > 690); 4/4/7 -> только `сложный <= средний x 1.6` (70 > 64) (AC 11-14).
- [ ] Граница 2/5/8 (80 <= 80) успешна; при разных ценах внутри уровней берутся max сложного и min простого/среднего: {2,3}/{5,6}/{7,9} -> ошибка, {7,8} -> успех (AC 15-17).

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/foundation/config/config_validator.gd` (`_check_recipes`, хвост: "complex price breaks the value invariants", ~строки 136-142), но разделить на два именованных правила - сообщение должно называть *каждый* нарушенный инвариант (AC 12-14 проверяют это).

- Инварианты (GDD Formulas -> Инварианты цен; сверить текст перед кодом): `max_hard * 100 <= (min_easy + min_med) * 115` и `max_hard * 10 <= min_med * 16`, целочисленно.
- Правило "цена - целое >= 1" реализует TR-recipe-013; int-тип поля `RecipeDef.price` гарантирует целое, sentinel -1 ловит пропуск.
- Фикстуры цен 2/5/9, 1/5/7, 4/4/7, 2/5/8, смешанные уровни - мутаторы `RecipeFixtures` (story 001); не хардкодить inline-числа в теле теста, кроме граничных значений (там число и есть смысл теста).
- Значения инвариантов (1.15, 1.6) - константы валидатора с пометкой "из GDD Formulas"; если позже уйдут в конфиг, добавить правило валидатора.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 004: структурные правила.
- Story 007: прогон на отгружаемых данных.
- Формула `coins_per_sec` - story 007 (только проверка отсутствия runtime-кода).

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`.*

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/order_recipe/order_recipe_price_invariants_test.gd` - must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001, 004
- Unlocks: Story 007
