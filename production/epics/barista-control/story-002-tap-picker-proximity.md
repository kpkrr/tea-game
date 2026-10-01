# Story 002: TapPicker: отбор цели по близости pick-якоря

> **Epic**: Player Control / Barista Movement
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/player-control-barista-movement.md`
**Requirement**: `TR-control-001`, `TR-control-011`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: Navigation & tap picking
**ADR Decision Summary**: Пути - прямые запросы NavigationServer3D на приватной карте, NavMesh запекается на старте из KitchenConfig (без NavigationAgent3D); выбор тапа - чистая математика (близость pick-якоря, затем луч против AABB и плоскость пола) без физики; стабильные ID (owner_id, index).
**ADR Version**: 2026-09-30
**Secondary ADRs**: ADR-0002 (Viewport, camera fit & presentation)

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: Post-cutoff/версионно-зависимые API: NavigationServer3D.bake_from_source_geometry_data, NavigationMeshSourceGeometryData3D.add_projected_obstruction, map_set_use_async_iterations (проверены только на 4.7.2); map_force_update deprecated с 4.5, но работает - только на Booting, single-thread. Имя константы InputEvent.DEVICE_ID_EMULATION подтвердить в первой истории TapInput. Запрос пути до первой синхронизации карты печатает ERROR и возвращает пусто - всегда ждать poll_ready().

**Control Manifest Rules (derived from governing ADRs — no manifest exists)**:
- Required (from ADR-0006): пути только через интерфейс Navigator; NavigationServer3D вызывается лишь из NavServerNavigator, NavMeshBaker и Pathing.
- Forbidden (from ADR-0006): NavigationAgent3D/NavigationRegion3D/NavigationObstacle3D/navigation links; физика (PhysicsDirectSpaceState3D, RayCast3D, Area3D, CollisionObject3D) для выбора тапа и путей.
- Guardrail (from ADR-0006): bake cell_size = 0.05, carve = false, agent_radius кратен 0.05; любое предупреждение бейка - отказ загрузки в CI.
- Required (from ADR-0006): TapPicker - node-free RefCounted; координаты входа и радиус в dp (viewport units), без умножения на DPR.

---

## Acceptance Criteria

*From GDD `design/gdd/player-control-barista-movement.md`, scoped to this story:*

- [ ] Тап вне `ViewFit.get_kitchen_rect()` (HUD-полосы, леттербокс) -> цели нет (Rule 1c); станция A на 30 px и B на 10 px при 1.5 px/dp -> цель B, даже если под тапом пол (AC 1, 3).
- [ ] Кандидаты - только pick-якоря станций и активных гостей (Approaching/Waiting); пустой слот гостя в 5 px в подборе не участвует (AC 5).
- [ ] Ничья (расстояния равны в пределах 0.01 dp): станция раньше гостя, затем меньший `owner_id` (String `<`), затем меньший индекс - результат не зависит от порядка входного списка (AC 4).
- [ ] Радиус = 28 dp включительно: якорь в 42 px при 1.5 px/dp выбирается, при 2.0 px/dp граница 56 px выбирается, 57 px - нет; ломаная пути не меняется при смене масштаба (AC 7-8).

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/core/tap_picker.gd` (`radius`, первая половина `resolve`: проверка `kitchen_rect`, цикл по станциям/гостям, `best_d - 0.01`).

- Вместо `Camera3D` в сигнатуре - интерфейс `TapProjector` (`to_screen(world: Vector3) -> Vector2`, `ray(screen: Vector2) -> Ray`); тесты используют `FakeProjector` — **перспективный** pinhole (точка взгляда, pitch, FOV, дистанция, offsets — та же формула, что `ViewFitMath.project`; ADR-0006 поправка 2026-10-01; один тест оставляет ортографический вариант, доказывая независимость от проекции) (ADR-0006 §5). Реальный враппер над `Camera3D` - отдельный тонкий класс.
- Вместо Dictionary `{kind, id, point}` - `TapTarget` (`kind: FLOOR|STATION|GUEST`, `owner_id: StringName`, `point_index: int`, `point: Vector3`); `tapped(target: TapTarget)`.
- Якоря станций/гостей - из `KitchenLayout`/`KitchenConfig` (kitchen-layout epic), активные гости - через read-only провайдер `GuestTargets` (инъекция, не ссылка на GuestSim).
- ID: `[a-z0-9_]+`, сравнение `owner_id` как String `<` (ADR-0006 §7); не выводить ID из позиции в массиве.
- Радиус вычисляется один раз в конструкторе через `ControlMath` (story 001).
- Порядок в слайсе (станции до гостей, `< best_d - 0.01`) сохранить - он уже отыгран плейтестом.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: fallback на геометрию (луч против AABB, плоскость пола).
- Story 004: приём ввода и правило одного нажатия за кадр.
- Story 006/008: клэмп пола и валидность цели.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`.*

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/player_control/player_control_tap_proximity_test.gd` - must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001; kitchen-layout epic (якоря, `kitchen_rect` через view-fit)
- Unlocks: Story 003, 004
