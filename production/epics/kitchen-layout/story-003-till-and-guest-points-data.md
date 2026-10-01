# Story 003: Shipped-данные: till-anchor, spawn, 4 слота очереди, выход

> **Epic**: Kitchen & Station Layout
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Config/Data
> **Estimate**: S
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/kitchen-station-layout.md`
**Requirement**: `TR-layout-005`, `TR-layout-017`
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

Касса — фиксированная мировая точка на столешнице, не станция и не слот. Для гостей: одна точка спавна, четыре точки очереди со стабильными ID и один выход — все на навигационной области (проверка на NavMesh — Story 006).

---

## Acceptance Criteria

*From GDD and ADR, scoped to this story:*

- [ ] GIVEN сцена/данные кухни, WHEN запрашивается `till_anchor`, THEN возвращается ровно одна точка на столешнице, не совпадающая ни с одной станцией или слотом
- [ ] GIVEN данные гостей, THEN заданы 1 spawn, 4 слота очереди со стабильными ID `(owner_id, index)` (`guest_slot_x.size() == 4`, serve/guest z) и 1 exit; ID не зависят от порядка массива
- [ ] GIVEN все точки гостей, THEN каждая лежит внутри `nav_rect`/`floor_rect` и вне footprints станций и стен (геометрическая проверка в данных; проверка bake — Story 006)

---

## Implementation Notes

Port from `kitchen.tres` значений слайса (`till_anchor`, `guest_slot_x`, `guest_z`, `serve_z`, `guest_spawn_x`, `guest_exit_x`, `front_counter`) и `prototypes/tea-rush-vertical-slice/src/foundation/kitchen_layout.gd` (`guest_serve_points`, `guest_anchors`, `guest_boxes` — выводятся из этих данных, см. Story 004). Касса как объект — часть столешницы/`front_counter`; она не входит в `station_types` и не занимает слот.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 004: вычисление якорей/AABB гостей
- Story 006: достижимость по NavMesh
- Логика гостей и очереди — эпик guest-sim

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**:
- Config/Data: smoke check pass (`production/qa/smoke-*.md`) + `tests/unit/kitchen_layout/kitchen_layout_guest_points_test.gd` for the shipped `.tres`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001, 002
- Unlocks: Story 004, 006
