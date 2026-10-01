# Story 007: Интеграция: отгружаемые рецепты, станции кухни, отсутствие runtime-формулы

> **Epic**: Order & Recipe System
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Estimate**: S
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/order-recipe-system.md`
**Requirement**: `TR-recipe-014`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Data config & load-time validation
**ADR Decision Summary**: Конфиг - типизированные Resource (.tres) под корнем GameConfig, поля с sentinel-значениями, единый ConfigValidator собирает все ошибки во всех сборках, конфиг неизменяем после загрузки и инжектится через конструкторы, RNG - инъектируемый.
**ADR Version**: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: Custom Resource + @export - до-cutoff API. Проверено на 4.7.2: неверные типы в .tres молча приводятся ("abc" -> 0.0), поэтому обязателен CI-тест отгружаемых значений. duplicate_deep() (4.5) - только в фикстурах тестов; .tres-деревья копировать с DEEP_DUPLICATE_ALL.

**Control Manifest Rules (derived from governing ADRs — no manifest exists)**:
- Required (from ADR-0004): один интеграционный тест загружает и валидирует отгружаемый `game_config.tres` (через `ResourceLoader.load(path, "", CACHE_MODE_IGNORE_DEEP)`); ловит тихое приведение типов.
- Required (from ADR-0004): при ошибках загрузки `ready_reached` не эмитится, матч не стартует.
- Forbidden (from ADR-0004): unit-тесты, читающие .tres с диска (только этот интеграционный тест).

---

## Acceptance Criteria

*From GDD `design/gdd/order-recipe-system.md`, scoped to this story:*

- [ ] Загрузка отгружаемых данных с реальными `station_types` кухни (kitchen-layout), а не фикстурой, успешна; каждый не-`serve` шаг соответствует физически размещённой станции; `RecipeBook` строится, цены 2/5/5/7/7 и цвета шагов на месте (AC 1, 7, 8, 38).
- [ ] Балансовая формула `coins_per_sec` не имеет runtime-кода: в `src/` нет её реализации (grep-тест), значение `t_step` = 2.0 используется только инструментами/`/balance-check`; advisory-сверка таблицы Formula 2 выполняется отчётом баланса (AC 37, ADVISORY).
- [ ] Негативный прогон: испорченная копия (`duplicate_deep(DEEP_DUPLICATE_ALL)` загруженного дерева) возвращает ошибки, а не падение; `RecipeBook` из невалидных данных не создаётся.

---

## Implementation Notes

Замыкает эпик на реальных данных. Слайс: `prototypes/tea-rush-vertical-slice/src/../tests/slice_logic_test.gd` -> `test_shipped_config_validates_and_bad_price_is_rejected` - перенести как основу.

- Тест живёт в `tests/integration/order_recipe/order_recipe_shipped_data_test.gd`.
- Grep-тест по `src/` на идентификатор `coins_per_sec` (и аналоги) - дешёвая защита TR-recipe-014 ("без runtime-кода"); исключения допускаются только в `tools/`.
- Блокируется готовностью `KitchenConfig.station_types` (kitchen-layout) и `ConfigLoader` (foundation-runtime); до тех пор допустим прогон с заглушкой `station_types`, но история закрывается только на реальных данных.
- Интеграционные AC 39-41 (Guest AI, Currency, Difficulty, Brewing) проверяются в тех эпиках.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- AC 39-41: проверяются в guest-sim / currency / difficulty-curve / brewing.
- Реализация `/balance-check` (формула Formula 2) - вне рантайма.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`.*

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/order_recipe/order_recipe_shipped_data_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001-006; kitchen-layout epic; foundation-runtime epic (`ConfigLoader`)
- Unlocks: None (закрывает эпик)
