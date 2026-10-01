# Story 001: KitchenConfig: типизированная схема с sentinel-полями

> **Epic**: Kitchen & Station Layout
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/kitchen-station-layout.md`
**Requirement**: `TR-layout-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Data config & load-time validation
**Secondary ADRs**: ADR-0006: Navigation & tap picking
**ADR Decision Summary**: Конфиг — типизированные `Resource` (`ViewConfig`, `KitchenConfig`, …) в `.tres` под `GameConfig`; sentinel-поля (`NAN`/`-1`), один чистый `ConfigValidator` собирает все ошибки в debug и release; модули получают конфиг через конструктор.
**ADR Version**: 2026-09-30 (secondary: ADR-0006 2026-09-30)

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: Pre-cutoff API (`Resource` + `@export`); неверные типы в `.tres` коэрсятся молча — нужен CI-тест на shipped-значения.

**Control Manifest Rules (from ADR; no control manifest at this tier)**:
- Required: `@export`-поля со статическим типом и sentinel; новое поле — вместе с правилом валидатора; конфиг через конструктор *(from ADR-0004)*
- Forbidden: литералы для tuning-значений; `load()` конфига в модулях; запись в конфиг *(from ADR-0004)*
- Guardrail: валидатор собирает все ошибки с dotted-путём в debug и release *(from ADR-0004)*
- Required: pick-якоря, AABB, footprints, границы пола, точки и ID — из `KitchenConfig`; ID не пересоздаются из позиции в массиве *(from ADR-0006)*
- Forbidden: `NavigationAgent3D`/`NavigationRegion3D`/`NavigationObstacle3D`/nav links; физика (`CollisionObject3D`, `RayCast3D`, `Area3D`) в сцене кухни *(from ADR-0006)*
- Guardrail: bake с `carve = false`, `cell_size` 0,05, `agent_radius` кратен `cell_size`; предупреждение bake = отказ *(from ADR-0006)*

Схема данных кухни ~8×11 м — единственной раскладки MVP. Поля описывают станции, стены, столешницы, кассу, точки гостей и границы пола; ADR-0006 добавляет к слайсу footprints, границы пола, якоря, точки и высоты тел для NavMesh и выбора тапа.

---

## Acceptance Criteria

*From GDD and ADR, scoped to this story:*

- [ ] `KitchenConfig` (`class_name`, `extends Resource`) хранит `floor_rect`, `nav_rect`, `stations`, `walls`, `countertops`, `countertop_height`, `front_counter`, `till_anchor`, `barista_start`, `guest_slot_x`/`guest_z`/`serve_z`, `guest_spawn_x`, `guest_exit_x`, `station_types`; каждое поле со статическим типом и sentinel (`NAN`, пустой массив)
- [ ] GIVEN `KitchenConfig.new()` без данных, WHEN валидатор проверяет, THEN каждое обязательное поле сообщается как `missing` с dotted-путём `kitchen.<field>`
- [ ] GIVEN shipped-размеры, THEN `floor_rect` = ~8×11 м (ширина 8, глубина 11) — одна раскладка, без параметризации и без изменений во время матча

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/foundation/config/kitchen_config.gd` (поля и sentinel уже верны) → `src/foundation/config/kitchen_config.gd`. Добавить по ADR-0006: явные footprints (станции, столешницы, стены), высоты тел для AABB, pick-якоря и точки взаимодействия как данные/производные. Станции в слайсе — `Dictionary` (`{id, type, pos, size, side, top}`); оценить перевод в типизированный вложенный `Resource` (`StationDef`) — если оставляете `Dictionary`, зафиксируйте обязательные ключи в валидаторе (Story 005). Для станций — `StringName` id; ID `(owner_id, index)` задаются данными, не порядком массива. Правила валидатора добавлять в том же изменении, что и поле (ADR-0004).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002–003: сами shipped-значения
- Story 005: правила валидатора станций/футпринтов
- Регистрация `KitchenConfig` в `GameConfig` и загрузка — эпик foundation-runtime

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/kitchen_layout/kitchen_layout_config_schema_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: Story 002, 003, 004, 005
