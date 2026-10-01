# Epic: Order & Recipe System

> **Layer**: Core
> **GDD**: design/gdd/order-recipe-system.md
> **Architecture Module**: RecipeBook
> **Engine Risk**: LOW
> **GDD Requirements Covered by ADRs**: 13 / 14 active
> **Status**: Ready
> **Stories**: 7 stories

## Overview

Модуль без состояния: 5 рецептов MVP в 3 уровнях сложности, таблица цен 2/5/5/7/7, грамматика шагов (`is_valid_next`, `matches`), разбивка по уровням и карта цветов шагов для HUD. Инварианты данных проверяются при загрузке. На этой грамматике стоят Brewing, Guest AI и Currency.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0004: Data config & load-time validation | GameConfig + подресурсы .tres, ConfigValidator собирает все ошибки, RNG инъекцией | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-recipe-001 | Рецепт `{recipe_id, steps, tier}`; ровно 5 рецептов MVP | ADR-0004 ✅ |
| TR-recipe-002 | `recipe_price` — поиск по таблице, не вычисление | ADR-0004 ✅ |
| TR-recipe-003 | Цены: cold_tea 2, black_tea 5, green_tea 5, *_lemon 7 | ADR-0004 ✅ |
| TR-recipe-004 | Инварианты цен в целых числах, проверка при загрузке | ADR-0004 ✅ |
| TR-recipe-005 | Первый шаг — `cup`, последний — `serve` (ровно один) | ADR-0004 ✅ |
| TR-recipe-006 | Каждый шаг, кроме `serve`, есть в `station_types` | ADR-0004 ✅ |
| TR-recipe-007 | Нет двух рецептов с одинаковой последовательностью (префикс допустим) | ADR-0004 ✅ |
| TR-recipe-008 | В каждом уровне ≥ 1 рецепт | ADR-0004 ✅ |
| TR-recipe-009 | `is_valid_next`; чёрный лист → water_100, зелёный лист → water_80 | ADR-0004 ✅ |
| TR-recipe-010 | `matches(steps)` сравнивает без `serve` | ADR-0004 ✅ |
| TR-recipe-011 | `recipes_by_tier` разбивает 5 рецептов без пересечений | ADR-0004 ✅ |
| TR-recipe-012 | Карта цветов шагов (7 записей) | GDD/UX — ADR не требуется |
| TR-recipe-013 | Цена — целое ≥ 1, иначе ошибка загрузки | ADR-0004 ✅ |
| TR-recipe-014 | Балансовая формула `coins_per_sec` — без runtime-кода | ADR-0004 ✅ |

## Port Source (vertical slice)

Логика уже проверена в `prototypes/tea-rush-vertical-slice/`. Истории переносят её в `src/`, а не пишут заново:
- `prototypes/tea-rush-vertical-slice/src/core/recipe_book.gd`
- `prototypes/tea-rush-vertical-slice/src/foundation/config/recipe_config.gd`
- `prototypes/tea-rush-vertical-slice/src/foundation/config/recipe_def.gd`

## Stories

| # | Story | Type | Status | ADR | Estimate |
|---|-------|------|--------|-----|----------|
| 001 | [RecipeDef / RecipeConfig и набор из 5 рецептов MVP](story-001-recipe-data-resources.md) | Config/Data | Ready | ADR-0004 | S |
| 002 | [RecipeBook: is_valid_next и matches](story-002-recipe-grammar.md) | Logic | Ready | ADR-0004 | M |
| 003 | [RecipeBook: цена и уровни рецептов](story-003-recipe-price-tier-lookup.md) | Logic | Ready | ADR-0004 | S |
| 004 | [Валидация структуры рецептов при загрузке](story-004-recipe-structure-validation.md) | Logic | Ready | ADR-0004 | M |
| 005 | [Валидация цен и ценовых инвариантов](story-005-recipe-price-validation.md) | Logic | Ready | ADR-0004 | M |
| 006 | [Карта цветов шагов для HUD](story-006-recipe-step-colors.md) | Logic | Ready | ADR-0004 | S |
| 007 | [Интеграция: отгружаемые рецепты, станции кухни, отсутствие runtime-формулы](story-007-recipe-shipped-data-integration.md) | Integration | Ready | ADR-0004 | S |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/order-recipe-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/story-readiness production/epics/recipe-book/story-001-*.md`, затем `/dev-story`.
