# Story 005: NavMeshBaker и Pathing: запекание, готовность, dispose

> **Epic**: Player Control / Barista Movement
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/player-control-barista-movement.md`
**Requirement**: `TR-control-007`, `TR-control-008`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: Navigation & tap picking
**ADR Decision Summary**: Пути - прямые запросы NavigationServer3D на приватной карте, NavMesh запекается на старте из KitchenConfig (без NavigationAgent3D); выбор тапа - чистая математика (близость pick-якоря, затем луч против AABB и плоскость пола) без физики; стабильные ID (owner_id, index).
**ADR Version**: 2026-09-30
**Secondary ADRs**: ADR-0004 (Data config & load-time validation)

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: Post-cutoff/версионно-зависимые API: NavigationServer3D.bake_from_source_geometry_data, NavigationMeshSourceGeometryData3D.add_projected_obstruction, map_set_use_async_iterations (проверены только на 4.7.2); map_force_update deprecated с 4.5, но работает - только на Booting, single-thread. Имя константы InputEvent.DEVICE_ID_EMULATION подтвердить в первой истории TapInput. Запрос пути до первой синхронизации карты печатает ERROR и возвращает пусто - всегда ждать poll_ready().

**Control Manifest Rules (derived from governing ADRs — no manifest exists)**:
- Required (from ADR-0006): пути только через интерфейс Navigator; NavigationServer3D вызывается лишь из NavServerNavigator, NavMeshBaker и Pathing.
- Forbidden (from ADR-0006): NavigationAgent3D/NavigationRegion3D/NavigationObstacle3D/navigation links; физика (PhysicsDirectSpaceState3D, RayCast3D, Area3D, CollisionObject3D) для выбора тапа и путей.
- Guardrail (from ADR-0006): bake cell_size = 0.05, carve = false, agent_radius кратен 0.05; любое предупреждение бейка - отказ загрузки в CI.
- Guardrail (from ADR-0006): поллинг `poll_ready()` каждый кадр Booting, `map_force_update` один раз и только до готовности; `Pathing.dispose()` в teardown и в каждом тесте, строящем Pathing (иначе утечка RID).

---

## Acceptance Criteria

*From GDD `design/gdd/player-control-barista-movement.md`, scoped to this story:*

- [ ] NavMesh запекается на старте из `KitchenConfig` (пол - 2 треугольника, по `add_projected_obstruction` на footprint, `carve = false`) с `cell_size = cell_height = 0.05`, `agent_radius = 0.40`, `agent_height = 1.0`, `edge_max_error = 0.5`; бейк без единого предупреждения (AC 24-25).
- [ ] `poll_ready()` возвращает true, когда `map_get_iteration_id > 0` и ближайшая к spawn точка карты в пределах 0.01 м по XZ; запросы пути до готовности не выполняются (нет ERROR в логе).
- [ ] Путь держит зазор: на парах точек `nav_fixture_island` каждая точка через 0.05 м отстоит от любого footprint не менее `body_clearance - 0.05 = 0.35 м` (измерено 0.380 м); на реальной кухне рабочие точки не отбракованы эрозией (AC 25, 27).
- [ ] `Pathing.dispose()` освобождает регион и карту: движок не сообщает об утёкших RID в конце теста.

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/core/pathing.gd` (`_init` с бейком, `poll_ready`, `dispose`) - это рабочая реализация по ADR-0006; разделить на три класса по ADR:

- `NavMeshBaker` (pure RefCounted): данные кухни -> `NavigationMesh`; `agent_radius` проходит через `snappedf(..., 0.05)`, чтобы шум float не вызвал ceil до целых ячеек (ADR-0006 §2).
- `NavServerNavigator`: единственное место, где вызывается `NavigationServer3D` для запросов; реализует интерфейс `Navigator` (`path`, `shortest_to`, `verify`, `poll_ready`, `dispose`).
- `Pathing` - фасад/владелец карты. `FakeNavigator` (скриптованные `PathResult`) - для unit-тестов контроллера.
- `PathResult`: `points: PackedVector3Array`, `length: float`, `reached: bool` (вместо Dictionary слайса).
- Post-cutoff API (`bake_from_source_geometry_data`, `add_projected_obstruction`, `map_set_use_async_iterations`) проверены ТОЛЬКО на 4.7.2; bake в headless-тесте требует `map_force_update`.
- Footprints и spawn - из `KitchenConfig` (kitchen-layout epic). Фикстура `nav_fixture_island` - в `tests/fixtures/`.
- Web/Android: замерить время бейка на устройстве ADR-0001 (контингенция: > 100 мс -> отгружать предзапечённый ресурс, решение владельца - вне этой истории).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 006: семантика запросов пути, клэмп, shortest_to, boot self-check.
- Story 007: движение по пути.
- Kitchen-layout epic: данные footprints.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`.*

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/player_control/player_control_nav_bake_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001; kitchen-layout epic
- Unlocks: Story 006, 007, 011
