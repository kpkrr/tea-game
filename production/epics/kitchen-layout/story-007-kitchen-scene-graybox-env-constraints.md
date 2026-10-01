# Story 007: Сцена кухни: gray-box из данных и ограничения рендера окружения

> **Epic**: Kitchen & Station Layout
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/kitchen-station-layout.md`
**Requirement**: `TR-layout-016`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Viewport, camera fit & 2.5D presentation
**Secondary ADRs**: ADR-0006: Navigation & tap picking
**ADR Decision Summary**: Stretch `canvas_items`/`expand` на базе 360×640 (1 единица вьюпорта = 1 reference dp); одна перспективная камера-диорама (поправка 2026-10-01: FOV 30°, pitch 52°; дистанция и `h_offset`/`v_offset` решаются чистым `ViewFitMath.solve_camera`; было ortho `size`); кухня ≥ 95 % ограничивающей стороны playfield; статика окружения — unshaded рисованный атлас × vertex-color, один `DirectionalLight3D` для теней динамики.
**ADR Version**: 2026-09-30 (secondary: ADR-0006 2026-09-30)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: Stretch-настройки 4.7 задаются явно; `Camera3D` perspective — pre-cutoff API (offsets — проверить в 4.7.2); нужна проверка `get_final_transform()` на web.

**Control Manifest Rules (from ADR; no control manifest at this tier)**:
- Required: stretch mode/aspect/base size заданы явно в `project.godot`; вся математика fit — чистые функции `ViewFitMath` *(from ADR-0002)*
- Forbidden: подписка на `size_changed`, чтение `DisplayServer`; tween при resize *(from ADR-0002)*
- Required: константы в dp; pitch/fill/aspect/`hud_min_strip_dp` — из валидированного конфига; один `DirectionalLight3D`, без Omni/Spot, статика unshaded *(from ADR-0002)*
- Required: pick-якоря, AABB, footprints, границы пола, точки и ID — из `KitchenConfig`; ID не пересоздаются из позиции в массиве *(from ADR-0006)*
- Forbidden: `NavigationAgent3D`/`NavigationRegion3D`/`NavigationObstacle3D`/nav links; физика (`CollisionObject3D`, `RayCast3D`, `Area3D`) в сцене кухни *(from ADR-0006)*
- Guardrail: bake с `carve = false`, `cell_size` 0,05, `agent_radius` кратен `cell_size`; предупреждение bake = отказ *(from ADR-0006)*

Модуль KitchenLayout — данные; финальные 3D-меши с запечённым светом делают эпики visual-pipeline/art-assets. Здесь — сцена-контейнер, размещающая gray-box-блоки по `KitchenLayout` (те же данные, что у NavMesh и выбора тапа), и проверка ограничений TR-layout-016, чтобы последующий арт не мог их нарушить.

---

## Acceptance Criteria

*From GDD and ADR, scoped to this story:*

- [ ] GIVEN `KitchenLayout`, WHEN строится сцена кухни, THEN визуальные ноды (блоки станций, столешницы, стены, маркер кассы) размещены из тех же данных/ID, а не из отдельной ручной раскладки; у статики нет `CollisionObject3D`, `NavigationRegion3D`, `Area3D`
- [ ] GIVEN сцена кухни, THEN ровно один `DirectionalLight3D` (для теней динамики, ADR-0002 amendment 2026-10-01), нет `OmniLight3D`/`SpotLight3D`; материалы статического окружения — unshaded (рисованный атлас × запечённый vertex color, поправка 2026-10-01); камера сцены — `Camera3D` `PROJECTION_PERSPECTIVE` (FOV/pitch из `ViewConfig`), её дистанцию и offsets выставляет только ViewFit; декорации вокруг кухни не входят в `frame_bounds` vertex-color; нет шейдерных анимаций (`TIME`) и параллакса на окружении
- [ ] GIVEN маркер till-anchor, THEN у него статичное свечение (без анимации), а retained-скриншот gray-box сцены сохранён в `production/qa/evidence/kitchen-scene-graybox-evidence.md`

---

## Implementation Notes

Новая сцена `src/presentation/kitchen/kitchen_scene.tscn` + `kitchen_scene_builder.gd`; тест-линтер обходит дерево сцены и проверяет типы нод/материалы. Gray-box — простые `MeshInstance3D`-боксы; заменяются реальными ассетами в visual-pipeline/art-assets без изменения данных. Для `Sprite3D` (гибридные станции по art-bible) места оставить по pick-якорям. Запуск и скриншот — `.claude/docs/run-and-observe.md`. Реальные пост-обработка/tonemap решаются спайком S4 (ADR-0007) — не здесь.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Запечённые vertex colors/AO, финальные меши и тоон-спрайты — эпики visual-pipeline / art-assets
- Toon-шейдер персонажей и grading — эпик visual-pipeline
- Камера и fit — эпик view-fit

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/kitchen_layout/kitchen_scene_constraints_test.gd`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002, 003, 004; камера из view-fit story 005 для скриншота
- Unlocks: None
