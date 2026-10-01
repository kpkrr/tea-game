# Story 001: RecipeDef / RecipeConfig и набор из 5 рецептов MVP

> **Epic**: Order & Recipe System
> **Status**: Ready
> **Layer**: Core
> **Type**: Config/Data
> **Estimate**: S
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/order-recipe-system.md`
**Requirement**: `TR-recipe-001`, `TR-recipe-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Data config & load-time validation
**ADR Decision Summary**: Конфиг - типизированные Resource (.tres) под корнем GameConfig, поля с sentinel-значениями, единый ConfigValidator собирает все ошибки во всех сборках, конфиг неизменяем после загрузки и инжектится через конструкторы, RNG - инъектируемый.
**ADR Version**: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: Custom Resource + @export - до-cutoff API. Проверено на 4.7.2: неверные типы в .tres молча приводятся ("abc" -> 0.0), поэтому обязателен CI-тест отгружаемых значений. duplicate_deep() (4.5) - только в фикстурах тестов; .tres-деревья копировать с DEEP_DUPLICATE_ALL.

**Control Manifest Rules (derived from governing ADRs — no manifest exists)**:
- Required (from ADR-0004): каждое тюнинг-значение из GDD/entities.yaml берётся из подресурса GameConfig; литералы в коде запрещены (кроме граничных тестов).
- Required (from ADR-0004): каждый @export имеет статический тип и sentinel-значение по умолчанию; новое поле поставляется вместе с правилом валидатора в том же изменении.
- Guardrail (from ADR-0004): RecipeDef - внутренние sub-resource в recipes.tres; файлы конфигов лежат в assets/data/config/, скрипты - в src/foundation/config/.

---

## Acceptance Criteria

*From GDD `design/gdd/order-recipe-system.md`, scoped to this story:*

- [ ] Отгружаемый `recipes.tres` содержит ровно 5 рецептов с ID `cold_tea`, `black_tea`, `green_tea`, `black_tea_lemon`, `green_tea_lemon`; у каждого первый шаг `cup`, последний `serve` (GDD AC 1-2).
- [ ] Длины шагов: `cold_tea` = 3, `black_tea` = `green_tea` = 4, `black_tea_lemon` = `green_tea_lemon` = 5; лист+вода: `leaf_black` -> `water_100`, `leaf_green` -> `water_80` (AC 4-5).
- [ ] Уровни 1/2/2 (`cold_tea` простой; `black_tea`, `green_tea` средний; `*_lemon` сложный) и цены 2/5/5/7/7 - целые, заданы данными, а не вычисляются (AC 6, 8).
- [ ] Фабрика `RecipeFixtures` (`tests/helpers/recipe_fixtures.gd`) отдаёт валидный набор MVP и мутаторы для негативных тестов (цена, шаги, дубликат, пустой уровень).

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/foundation/config/recipe_def.gd` и `recipe_config.gd` (сейчас 10 и 7 строк), данные - из `prototypes/tea-rush-vertical-slice/data/game_config.tres`.

- `RecipeDef`: `recipe_id: StringName = &""`, `steps: Array[StringName] = []`, `tier: StringName = &""`, `price: int = -1` (sentinels по ADR-0004; пустое значение = "ключ отсутствует").
- `RecipeConfig.recipes: Array[RecipeDef]` (в слайсе `Array[Resource]` - ужесточить тип).
- Убрать заголовок `VERTICAL SLICE - NOT FOR PRODUCTION`, добавить doc-комментарии на публичные поля.
- `tier` хранить как `StringName` (`&"easy"|&"medium"|&"hard"`) - единый словарь уровней согласовать с DifficultyCurve и GuestSim (`recipes_by_tier`).
- `recipes.tres` подключается из `game_config.tres` как `uid://` ExtResource (ADR-0004 §1).
- `RecipeFixtures` строится в памяти, без чтения .tres с диска (ADR-0004 Implementation Guidelines).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002-003: поведение `RecipeBook` (грамматика, цены, уровни).
- Story 004-005: правила валидатора и инварианты цен.
- Story 006: карта цветов шагов.
- Kitchen-layout epic: `station_types` (источник допустимых шагов).

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`.*

**Story Type**: Config/Data
**Required evidence**:
- Config/Data: smoke check pass (`production/qa/smoke-*.md`); плюс `tests/unit/order_recipe/order_recipe_data_test.gd` (опционально; загрузка через фикстуру)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (`ConfigLoader`/`GameConfig` - эпик foundation-runtime; до его готовности работать на фикстурах)
- Unlocks: Story 002, 003, 004, 005, 006, 007
