# Story 002: RecipeBook: is_valid_next и matches

> **Epic**: Order & Recipe System
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/order-recipe-system.md`
**Requirement**: `TR-recipe-009`, `TR-recipe-010`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Data config & load-time validation
**ADR Decision Summary**: Конфиг - типизированные Resource (.tres) под корнем GameConfig, поля с sentinel-значениями, единый ConfigValidator собирает все ошибки во всех сборках, конфиг неизменяем после загрузки и инжектится через конструкторы, RNG - инъектируемый.
**ADR Version**: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: Custom Resource + @export - до-cutoff API. Проверено на 4.7.2: неверные типы в .tres молча приводятся ("abc" -> 0.0), поэтому обязателен CI-тест отгружаемых значений. duplicate_deep() (4.5) - только в фикстурах тестов; .tres-деревья копировать с DEEP_DUPLICATE_ALL.

**Control Manifest Rules (derived from governing ADRs — no manifest exists)**:
- Required (from ADR-0004): RecipeBook получает `RecipeConfig` через конструктор (DI), не читает ресурсы по пути и не пишет в конфиг.
- Required (from ADR-0003): RecipeBook остаётся `RefCounted` без состояния симуляции и без `step()`; чистые функции над данными.
- Forbidden (from ADR-0004): глобальный randf()/randomize() - в модуле нет случайности.

---

## Acceptance Criteria

*From GDD `design/gdd/order-recipe-system.md`, scoped to this story:*

- [ ] `is_valid_next(steps, step)` истинно только для шагов, которые продолжают префикс какого-либо рецепта: S=[] -> только `cup`; [`cup`] -> `iced_tea`, `leaf_black`, `leaf_green`; [`cup`,`leaf_black`] -> только `water_100` (симметрично `leaf_green` -> `water_80`); [`cup`,`leaf_black`,`water_100`] -> только `lemon`; не-префикс или полный рецепт -> false (AC 32-36).
- [ ] `matches(steps)` сравнивает шаги без `serve` и возвращает ID рецепта или `&""`: все 5 рецептов находятся по своим шагам; [`cup`,`leaf_black`,`water_100`] -> `black_tea` (полный и префикс `black_tea_lemon`); неполные и перепутанные (`leaf_black`+`water_80`, `lemon` до воды, `iced_tea`+`lemon`) -> none (AC 26-30).
- [ ] Функции чистые: два вызова `matches` с одним входом равны, входной массив и данные рецептов не меняются (AC 31).

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/core/recipe_book.gd` (`_init`, `is_valid_next`, `matches`) - логика проверена слайсом (`test_recipe_grammar_prefix_and_match`), переносится, не переписывается.

- `class_name RecipeBook extends RefCounted`; `_init(cfg: RecipeConfig)`: `serve` отбрасывается из внутреннего списка шагов (как в слайсе).
- Сигнатуры: `is_valid_next(steps: Array[StringName], step: StringName) -> bool`, `matches(steps: Array[StringName]) -> StringName`. Сравнение типизированных массивов в GDScript - поэлементное, но покрыть тестом случай untyped/typed входа.
- Возвращаемое "none" = `&""` (константа `RecipeBook.NO_MATCH`), чтобы Brewing/GuestSim не сравнивали с литералами.
- Doc-комментарии на всех публичных методах (coding-standards).
- Тестовые данные - `RecipeFixtures` (story 001), без .tres с диска.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: `recipe_price`, `recipe_tier`, `recipes_by_tier`, `token_steps`.
- Story 004-005: валидация данных при загрузке.
- Brewing epic: применение грамматики к чайникам и станциям.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`.*

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/order_recipe/order_recipe_grammar_test.gd` - must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001
- Unlocks: Story 003; Brewing story 002-003; guest-sim epic
