# Story 004: KitchenLayout: производная геометрия, стабильные ID, pick-якоря, footprints

> **Epic**: Kitchen & Station Layout
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: L
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/kitchen-station-layout.md`
**Requirement**: `TR-layout-006`, `TR-layout-013`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: Navigation & tap picking
**Secondary ADRs**: ADR-0004: Data config & load-time validation
**ADR Decision Summary**: NavMesh запекается на старте из данных `KitchenConfig` (пол + footprints, `carve = false`, `cell_size` 0,05); пути — прямые запросы `NavigationServer3D` через `Navigator`; выбор тапа без физики по pick-якорям и AABB; ID `(owner_id, index)` стабильны и берутся из конфига.
**ADR Version**: 2026-09-30 (secondary: ADR-0004 2026-09-30)

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: `bake_from_source_geometry_data`, `add_projected_obstruction` проверены только на 4.7.2; `agent_radius` кратен `cell_size`; предупреждение bake = ошибка CI.

**Control Manifest Rules (from ADR; no control manifest at this tier)**:
- Required: pick-якоря, AABB, footprints, границы пола, точки и ID — из `KitchenConfig`; ID не пересоздаются из позиции в массиве *(from ADR-0006)*
- Forbidden: `NavigationAgent3D`/`NavigationRegion3D`/`NavigationObstacle3D`/nav links; физика (`CollisionObject3D`, `RayCast3D`, `Area3D`) в сцене кухни *(from ADR-0006)*
- Guardrail: bake с `carve = false`, `cell_size` 0,05, `agent_radius` кратен `cell_size`; предупреждение bake = отказ *(from ADR-0006)*
- Required: `@export`-поля со статическим типом и sentinel; новое поле — вместе с правилом валидатора; конфиг через конструктор *(from ADR-0004)*
- Forbidden: литералы для tuning-значений; `load()` конфига в модулях; запись в конфиг *(from ADR-0004)*
- Guardrail: валидатор собирает все ошибки с dotted-путём в debug и release *(from ADR-0004)*

Чистый `RefCounted`-модуль: из `KitchenConfig` (и радиуса работы из `ControlConfig`) выводит точки взаимодействия, pick-якоря, AABB, footprints и списки ID. Только читает и отдаёт данные: занятость слотов принадлежит Brewing — здесь её нет. Узлы через границы модулей не передаются, только ID.

---

## Acceptance Criteria

*From GDD and ADR, scoped to this story:*

- [ ] GIVEN `KitchenConfig`, WHEN `KitchenLayout.new(kitchen_cfg, control_cfg)`, THEN для каждой станции/слота доступны точка взаимодействия (work spot), pick-якорь (центр иконки/верх станции) и AABB; ID — `StringName` в стабильном порядке (сортировка по id), не по индексу массива
- [ ] GIVEN `footprints()`, THEN возвращаются `Array[Rect2]` на XZ для станций, столешниц и стен (данные `KitchenConfig`, не коллизионные формы), и никакие два footprint не пересекаются (кроме касания по границе)
- [ ] GIVEN публичный API `KitchenLayout`, THEN нет методов/полей, хранящих занятость слота или меняющих данные (только чтение); `station_type(id)`, `slot_ids`, `kettle_ids`, `station_ids`, `till_anchor`, гостевые точки доступны по ID
- [ ] GIVEN `KitchenLayout` без `Node`/сцены/физики, THEN класс создаётся в юнит-тесте с фабричным конфигом и не вызывает `load()`/`NavigationServer3D`

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/foundation/kitchen_layout.gd` (68 строк: `stations`, `station_ids`, `slot_ids`, `kettle_ids`, `guest_serve_points`, `guest_anchors`, `guest_boxes`, `blockers`, `footprints()`). Привести к стандартам: `class_name KitchenLayout extends RefCounted`, типизированные параметры `_init(kitchen_cfg: KitchenConfig, control_cfg: ControlConfig)`, doc comments на публичный API, записи станций — типизированные (`StationDef`/`StationGeometry`), а не `Dictionary`. Константы `0.45`/`0.4`/`1.6` в `guest_boxes` и `0.5` в `reach` вынести в конфиг (gameplay values — data-driven). Проверить расхождение: в слайсе `footprints()` берёт станции и стены, а столешницы идут только в `blockers` (tap-only) — ADR-0006 и TR-layout-013 требуют footprints столешниц тоже в данных; решить, входят ли они в nav-obstruction (проверяется Story 006 bake без предупреждений). Для pick-приоритета ID — порядок из ADR-0006 Decision 7.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 005: правила `ConfigValidator` (этот класс предполагает валидный конфиг)
- Story 006: NavMesh bake и пути
- `TapPicker` и `Pathing` (эпик barista-control) — потребители, не часть модуля

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/kitchen_layout/kitchen_layout_geometry_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001, 002, 003
- Unlocks: Story 005, 006, 007; view-fit story 006
