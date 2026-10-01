# Story 002: Shipped-данные: станции, остров, 7 слотов, мусорка, столешницы

> **Epic**: Kitchen & Station Layout
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Config/Data
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/kitchen-station-layout.md`
**Requirement**: `TR-layout-002`, `TR-layout-003`, `TR-layout-004`
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

Заполнение `assets/data/config/kitchen.tres` геометрией станций по GDD. Мусорка `trash` восстановлена владельцем (Core Rule 9): одна, у левой стены, центр (−3,5; 0,75), footprint 1×1,5 м; это служебная станция, не шаг рецепта.

---

## Acceptance Criteria

*From GDD and ADR, scoped to this story:*

- [ ] GIVEN shipped `kitchen.tres`, THEN станции расположены по периметру с промежутками, остров 2×4 м стоит в центре и делит кухню на два прохода
- [ ] GIVEN перечисление слотов, THEN их ровно 7: 5 на острове, по 1 у левой и правой боковой стены, у каждого уникальная мировая точка взаимодействия; ровно одна станция типа `trash` у левой стены (центр (−3,5; 0,75), 1×1,5 м)
- [ ] GIVEN столешницы, THEN вдоль стен и по периметру острова — сплошная низкая столешница с единой `countertop_height`; станции — отдельные блоки, пустые слоты — размеченные площадки без мебели; участок рядом со станцией лимона на острове намеренно пуст, без слота

---

## Implementation Notes

Port from data in `prototypes/tea-rush-vertical-slice/data/game_config.tres` (секция `kitchen`): 15 станций + 12 блоков стен + столешницы уже замерены ADR-0006 (19 точек взаимодействия). Перенести в `assets/data/config/kitchen.tres`; сверить с Core Rules 1–4, 6, 9 GDD и станциями, которые требуются рецептам (`recipe-book`). Позиции — XZ в метрах. Тест shipped-данных загружает `.tres` через `ResourceLoader.load(path, "", CACHE_MODE_IGNORE_DEEP)` (ADR-0004) и проверяет количества/типы/IDs; пустые промежутки вдоль стен не функциональны в MVP (Open Question GDD) — не добавлять станций сверх списка.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: касса, гости, spawn/exit
- Story 005: валидатор (пересечения, `station_types`)
- Визуальная сборка 3D-окружения — эпики visual-pipeline / art-assets

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**:
- Config/Data: smoke check pass (`production/qa/smoke-*.md`) + `tests/unit/kitchen_layout/kitchen_layout_shipped_data_test.gd` for the shipped `.tres`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001
- Unlocks: Story 003, 004, 005, 006, 007
