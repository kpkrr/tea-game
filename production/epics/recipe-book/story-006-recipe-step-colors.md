# Story 006: Карта цветов шагов для HUD

> **Epic**: Order & Recipe System
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/order-recipe-system.md`
**Requirement**: `TR-recipe-012`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Data config & load-time validation
**ADR Decision Summary**: Конфиг - типизированные Resource (.tres) под корнем GameConfig, поля с sentinel-значениями, единый ConfigValidator собирает все ошибки во всех сборках, конфиг неизменяем после загрузки и инжектится через конструкторы, RNG - инъектируемый.
**ADR Version**: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: Custom Resource + @export - до-cutoff API. Проверено на 4.7.2: неверные типы в .tres молча приводятся ("abc" -> 0.0), поэтому обязателен CI-тест отгружаемых значений. duplicate_deep() (4.5) - только в фикстурах тестов; .tres-деревья копировать с DEEP_DUPLICATE_ALL.

**Control Manifest Rules (derived from governing ADRs — no manifest exists)**:
- Required (from ADR-0004): каждое тюнинг-значение из GDD/entities.yaml берётся из подресурса GameConfig; литералы в коде запрещены (кроме граничных тестов).
- Required (from ADR-0004): каждый @export имеет статический тип и sentinel-значение по умолчанию; новое поле поставляется вместе с правилом валидатора в том же изменении.
- Guardrail (from ADR-0004): значения цветов - данные (RecipeConfig), а не константы в presentation-коде; HUD/KitchenView читают через RecipeBook.

---

## Acceptance Criteria

*From GDD `design/gdd/order-recipe-system.md`, scoped to this story:*

- [ ] `step_color(step)` возвращает цвет для каждого из 7 не-`serve` шагов: `cup` белый, `iced_tea` фиолетовый, `leaf_green` зелёный, `leaf_black` оранжево-коричневый, `water_100` красный, `water_80` синий, `lemon` жёлтый (AC 7).
- [ ] Валидатор сообщает об ошибке, если у какого-либо не-`serve` шага любого рецепта нет цвета; для `serve` цвет не требуется.

---

## Implementation Notes

Цвета в слайсе живут в `prototypes/tea-rush-vertical-slice/src/presentation/pixel_art.gd` (`STEP_COLORS`, строка ~29) - это presentation-код; переносим значения в данные.

- `RecipeConfig.step_colors: Dictionary[StringName, Color]` (типизированный Dictionary, Godot 4.4+; пустой = "ключ отсутствует") + правило валидатора "для каждого шага рецептов есть цвет".
- Точные значения берём из `design/art/art-bible.md` (палитра шагов) - она приоритетнее слайса; различимость для дальтоников проверяет HUD/art, не эта история.
- `RecipeBook.step_color(step: StringName) -> Color`; неизвестный шаг - `push_error` и `Color.GRAY` (валидатор делает ситуацию недостижимой в отгруженных данных).
- Потребители (HUD жетон заказа, KitchenView иконка чашки) подключаются в своих эпиках.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- HUD/kitchen-view: отрисовка жетонов и иконок.
- Art-assets epic: спрайты предметов.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`.*

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/order_recipe/order_recipe_step_colors_test.gd` - must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001, 002
- Unlocks: Story 007; hud epic
