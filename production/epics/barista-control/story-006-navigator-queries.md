# Story 006: Navigator: клэмп цели, выбор точки подхода, boot self-check

> **Epic**: Player Control / Barista Movement
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/player-control-barista-movement.md`
**Requirement**: `TR-control-002`, `TR-control-005`
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

- [ ] Цель-пол вне навигационной области (x in [0,4], z in [0,6]: (5,3) и (-1,-1)) -> путь кончается в ближайшей достижимой точке XZ ((4,3) и (0,0), допуск 0.001 м); цель внутри footprint -> `reached = false`, цель переносится к ближайшей точке сетки; в изолированном кармане - к ближайшей достижимой точке (AC 10-11).
- [ ] `shortest_to(from, points)` делает по запросу на точку и берёт кратчайший путь (W1 3.0 м против W2 7.0 м по прямой ближе -> W1); при равенстве длины (в пределах 1e-4 м) побеждает меньший индекс точки (AC 20).
- [ ] Станция/гость без пути (`reached = false` для всех точек) -> тап отклоняется, состояние/цель/путь прежние, в debug ровно одна ошибка с ID цели (AC 19).
- [ ] Boot self-check `verify`: путь от spawn до КАЖДОЙ точки взаимодействия (рабочие точки, слоты гостей, выход, касса) должен быть `reached`, иначе `fail_boot("navigation: unreachable <owner_id>#<index>")`; y всех точек пути принудительно 0.0.

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/core/pathing.gd`: `path`, `shortest_to`, `verify` (слайс уже делает y=0, `path_end_tolerance`, tie -> нижний индекс через строгое `<` с `1e-4`).

- Точка взаимодействия = `(owner_id, index)`, `index >= 0` в порядке данных (ADR-0006 §7); `verify` принимает массив `InteractionPoint`, а не `Vector3` - сообщение об ошибке должно называть `owner_id#index`.
- Для floor-цели "клэмп" = `points[-1]` результата; отдельной функции клэмпа нет (ADR-0006 §4).
- Путь считается один раз при принятии цели и не пересчитывается в движении; повторный тап по текущей цели - новое принятие (Edge Case), не repath.
- Тесты на реальном NavServer (gdUnit4 headless, `map_force_update` в setup) + `FakeNavigator` для логики отказа.
- `verify` вызывается MatchDirector на Booting после `poll_ready()`; сам `fail_boot` - platform-shell/foundation-runtime.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 005: запекание и готовность карты.
- Story 008: использование результатов контроллером.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`.*

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/player_control/player_control_navigator_queries_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 005
- Unlocks: Story 008, 011
