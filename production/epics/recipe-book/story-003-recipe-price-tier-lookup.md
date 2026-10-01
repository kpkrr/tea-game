# Story 003: RecipeBook: цена и уровни рецептов

> **Epic**: Order & Recipe System
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/order-recipe-system.md`
**Requirement**: `TR-recipe-002`, `TR-recipe-011`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Data config & load-time validation
**ADR Decision Summary**: Конфиг - типизированные Resource (.tres) под корнем GameConfig, поля с sentinel-значениями, единый ConfigValidator собирает все ошибки во всех сборках, конфиг неизменяем после загрузки и инжектится через конструкторы, RNG - инъектируемый.
**ADR Version**: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: Custom Resource + @export - до-cutoff API. Проверено на 4.7.2: неверные типы в .tres молча приводятся ("abc" -> 0.0), поэтому обязателен CI-тест отгружаемых значений. duplicate_deep() (4.5) - только в фикстурах тестов; .tres-деревья копировать с DEEP_DUPLICATE_ALL.

**Control Manifest Rules (derived from governing ADRs — no manifest exists)**:
- Required (from ADR-0004): цена - значение из данных (таблица), а не формула от числа шагов.
- Required (from ADR-0004): RecipeBook неизменяем после конструктора; внешний код получает копии/только чтение.
- Guardrail (from ADR-0004): вызовы поиска - O(число рецептов), без аллокаций в горячем пути step().

---

## Acceptance Criteria

*From GDD `design/gdd/order-recipe-system.md`, scoped to this story:*

- [ ] `recipe_price(id)` возвращает int из данных: 2, 5, 5, 7, 7 для 5 рецептов; для 4-шагового рецепта с ценой 11 в фикстуре возвращается 11 (AC 8-9).
- [ ] Все цены в [2, 7], рецепты одного уровня стоят одинаково (AC 10).
- [ ] `recipes_by_tier` разбивает 5 рецептов без пересечений: простой {`cold_tea`}, средний {`black_tea`,`green_tea`}, сложный {`black_tea_lemon`,`green_tea_lemon`}; объединение = все 5 (AC 25).

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/core/recipe_book.gd`: `recipe_price`, `recipe_tier`, `recipes_by_tier`, `token_steps`, `recipe_ids`.

- Неизвестный ID: слайс возвращает `0`/`&""`/`[]` молча - это допустимо только как защитный путь; добавить `push_error` в debug и покрыть тестом (неизвестный ID - ошибка вызывающего, валидатор гарантирует 5 ID).
- `recipes_by_tier` возвращает порядок из конфига (детерминированно, нужно GuestSim для воспроизводимого выбора по seed); в тесте сравнивать как множества, порядок проверить отдельно.
- `token_steps(id)` = шаги без `cup` и `serve` (используется HUD на жетоне заказа) - оставить, покрыть тестом.
- Не возвращать внутренний массив наружу без `.duplicate()`.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 005: инварианты цен при загрузке.
- Currency epic: начисление монет по `recipe_price`.
- Difficulty-curve/guest-sim epics: выбор уровня и рецепта.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`.*

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/order_recipe/order_recipe_price_tier_test.gd` - must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001, 002 (конструктор RecipeBook)
- Unlocks: Story 005, 007; currency, guest-sim, hud epics
