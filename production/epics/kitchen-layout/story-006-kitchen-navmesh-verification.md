# Story 006: NavMesh на данных кухни: bake без предупреждений, пути, зазоры

> **Epic**: Kitchen & Station Layout
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/kitchen-station-layout.md`
**Requirement**: `TR-layout-007`, `TR-layout-008`, `TR-layout-012`, `TR-layout-017`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: Navigation & tap picking
**ADR Decision Summary**: NavMesh запекается на старте из данных `KitchenConfig` (пол + footprints, `carve = false`, `cell_size` 0,05); пути — прямые запросы `NavigationServer3D` через `Navigator`; выбор тапа без физики по pick-якорям и AABB; ID `(owner_id, index)` стабильны и берутся из конфига.
**ADR Version**: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: `bake_from_source_geometry_data`, `add_projected_obstruction` проверены только на 4.7.2; `agent_radius` кратен `cell_size`; предупреждение bake = ошибка CI.

**Control Manifest Rules (from ADR; no control manifest at this tier)**:
- Required: pick-якоря, AABB, footprints, границы пола, точки и ID — из `KitchenConfig`; ID не пересоздаются из позиции в массиве *(from ADR-0006)*
- Forbidden: `NavigationAgent3D`/`NavigationRegion3D`/`NavigationObstacle3D`/nav links; физика (`CollisionObject3D`, `RayCast3D`, `Area3D`) в сцене кухни *(from ADR-0006)*
- Guardrail: bake с `carve = false`, `cell_size` 0,05, `agent_radius` кратен `cell_size`; предупреждение bake = отказ *(from ADR-0006)*

Интеграционная приёмка геометрии: shipped `KitchenConfig` должна запекаться в NavMesh без ошибок, а все точки взаимодействия и гостевые точки — быть достижимы с нужным зазором. Сам `NavMeshBaker`/`Pathing` реализуются в эпике barista-control; здесь — тест, доказывающий, что данные кухни ему подходят.

---

## Acceptance Criteria

*From GDD and ADR, scoped to this story:*

- [ ] GIVEN shipped `KitchenConfig`, WHEN `NavMeshBaker.bake(kitchen, agent_radius)` на 4.7.2, THEN запекание завершается без ошибок и предупреждений (лог чист, `cell_size` 0,05, `agent_radius` 0,40)
- [ ] GIVEN запечённая карта, WHEN `Navigator.path` от till anchor (и spawn) к каждому из 7 слотов, каждой станции и 4 слотам гостей и к выходу, THEN каждый путь существует (`reached`) и имеет ненулевую длину; изолированных карманов пола нет (`verify()` пуст)
- [ ] GIVEN все точки взаимодействия, THEN каждая лежит на NavMesh (≤ 0,03 м по XZ), а минимальный зазор пути до любого footprint ≥ `agent_radius − 0,05` (0,35 м)

---

## Implementation Notes

Новый тест; логики слайса для порта нет, но геометрию подтверждает spike ADR-0006 (15 станций + 12 стен, 19 точек, 342 пар, замеренный зазор 0,380 м). Зависит от `NavMeshBaker`/`Pathing` из эпика barista-control (story по Pathing) — до его готовности тест помечается pending, не skip-уется молча. Тест вызывает `Pathing.dispose()` в teardown (ADR-0006), опрашивает `poll_ready()`. Если bake выдаёт предупреждения, исправлять данные кухни (зазоры, footprints), а не ослаблять проверку.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Реализация `NavMeshBaker`, `Pathing`, `Navigator` — эпик barista-control
- `TapPicker` — эпик barista-control

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/kitchen_layout/kitchen_navmesh_verification_test.gd`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002, 003, 004, 005; NavMeshBaker/Pathing story в barista-control
- Unlocks: None
