# Story 003: TapPicker: луч против AABB и плоскость пола

> **Epic**: Player Control / Barista Movement
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/player-control-barista-movement.md`
**Requirement**: `TR-control-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: Navigation & tap picking
**ADR Decision Summary**: Пути - прямые запросы NavigationServer3D на приватной карте, NavMesh запекается на старте из KitchenConfig (без NavigationAgent3D); выбор тапа - чистая математика (близость pick-якоря, затем луч против AABB и плоскость пола) без физики; стабильные ID (owner_id, index).
**ADR Version**: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: Post-cutoff/версионно-зависимые API: NavigationServer3D.bake_from_source_geometry_data, NavigationMeshSourceGeometryData3D.add_projected_obstruction, map_set_use_async_iterations (проверены только на 4.7.2); map_force_update deprecated с 4.5, но работает - только на Booting, single-thread. Имя константы InputEvent.DEVICE_ID_EMULATION подтвердить в первой истории TapInput. Запрос пути до первой синхронизации карты печатает ERROR и возвращает пусто - всегда ждать poll_ready().

**Control Manifest Rules (derived from governing ADRs — no manifest exists)**:
- Required (from ADR-0006): пути только через интерфейс Navigator; NavigationServer3D вызывается лишь из NavServerNavigator, NavMeshBaker и Pathing.
- Forbidden (from ADR-0006): NavigationAgent3D/NavigationRegion3D/NavigationObstacle3D/navigation links; физика (PhysicsDirectSpaceState3D, RayCast3D, Area3D, CollisionObject3D) для выбора тапа и путей.
- Guardrail (from ADR-0006): bake cell_size = 0.05, carve = false, agent_radius кратен 0.05; любое предупреждение бейка - отказ загрузки в CI.

---

## Acceptance Criteria

*From GDD `design/gdd/player-control-barista-movement.md`, scoped to this story:*

- [ ] Если в радиусе нет якорей, выбор идёт по ближайшему лучевому попаданию против статических AABB (станции, столешницы, стены, касса, хит-боксы активных гостей): станция -> STATION, гость -> GUEST, столешница/касса/стена -> FLOOR в XZ точки попадания (AC 2, 6).
- [ ] Попадания сравниваются по `(hit - origin).dot(dir)` с нормализованным `dir`; при нескольких AABB на луче выигрывает ближайший к камере.
- [ ] Нет попадания в AABB: пересечение с `Plane(Vector3.UP, 0)`; точка внутри `floor_bounds` -> FLOOR, иначе цели нет (состояние, цель и путь баристы не меняются) (AC 3).
- [ ] В сцене кухни и в коде выбора нет `CollisionObject3D`, `Area3D`, `RayCast3D`, `PhysicsDirectSpaceState3D` (grep-проверка в тесте).

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/core/tap_picker.gd` (вторая половина `resolve`: `AABB.intersects_ray`, `blockers`, `Plane(Vector3.UP, 0).intersects_ray`). Слайс уже без физики - переносится почти 1:1.

- `AABB.intersects_ray` и `Plane.intersects_ray` возвращают `Vector3` или `null` - проверять `null` явно (типизированно: `Variant`).
- Список AABB - из `KitchenConfig` (footprints станций/столешниц/стен/кассы) - единый источник и для NavMesh (story 005), и для выбора; визуальные ноды размещаются из тех же данных.
- Результат для столешницы/кассы - FLOOR в точке попадания; клэмп к ближайшей достижимой точке делает Navigator (story 006), а не TapPicker.
- Использовать `TapProjector.ray()` (story 002); `FakeProjector` — перспективный pinhole (лучи расходятся из камеры, ADR-0006 поправка 2026-10-01) — делает тест чисто-логическим; добавить кейс: тап по верху высокой станции у задней стены → STATION, а не пол за ней.
- Производительность: <= 35 статических боксов, один проход на тап - вне бюджета.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: близость якоря.
- Story 006: клэмп пола к NavMesh.
- Story 004: приём ввода.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`.*

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/player_control/player_control_tap_geometry_test.gd` - must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002
- Unlocks: Story 004, 011
