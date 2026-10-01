# Story 006: Минимальная зона тапа 48×48 dp и минимальный размер оверлеев под перспективой

> **Epic**: View Fit & Camera
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/kitchen-station-layout.md`, `design/gdd/hud-feedback-ui.md`
**Requirement**: `TR-layout-014`, `TR-art-009`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Viewport, camera fit & 2.5D presentation
**ADR Decision Summary**: Stretch `canvas_items`/`expand` на базе 360×640 (1 единица вьюпорта = 1 reference dp); одна **перспективная камера-диорама** (поправка 2026-10-01: FOV 30°, pitch 52°, yaw и точка взгляда фиксированы) — чистый `ViewFitMath.solve_camera` решает дистанцию вдоль оси взгляда и `h_offset`/`v_offset` от playfield так, что кухня занимает ≥ `kitchen_fill_target` (≥ 0,95) ограничивающей стороны (было: ortho `size`); на почти квадратных экранах HUD-полоса 56 dp резервируется (Mode C).
**ADR Version**: 2026-09-30 (secondary: ADR-0006 2026-09-30)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: Stretch-настройки 4.7 задаются явно (дефолты изменились); `Camera3D` perspective `fov`/`keep_aspect`/`h_offset`/`v_offset`, `unproject_position` — pre-cutoff API (учёт offsets в проекции под перспективой — проверить в 4.7.2, ADR-0002 V5); нужно проверить на web и устройстве, что `get_viewport().get_final_transform()` корректно переводит px в единицы вьюпорта.

**Control Manifest Rules (from ADR; no control manifest at this tier)**:
- Required: stretch mode/aspect/base size заданы явно в `project.godot` (`canvas_items` / `expand` / 360×640); не полагаться на дефолты 4.7 *(from ADR-0002)*
- Required: вся математика fit — чистые статические функции `ViewFitMath`; нода только применяет результат *(from ADR-0002)*
- Required: pick-якоря, AABB, footprints, границы пола, точки взаимодействия и ID берутся из `KitchenConfig`; визуальные ноды размещаются из тех же данных *(from ADR-0006)*
- Required: ID `(owner_id, index)` стабильны — никогда не пересоздаются из позиции в массиве; tie-break по порядку из Decision 7 *(from ADR-0006)*

Эталонный размер 360×640 dp — худший практический случай для телефона. Проверяем, что после fit каждая интерактивная цель кухни (станции, слоты, гость, касса) имеет зону тапа не меньше `min_tap_target` = 48 dp: либо спроецированный размер, либо радиус подбора `tap_pick_radius` (28 dp) закрывает недостающее.

---

## Acceptance Criteria

*From GDD and ADR, scoped to this story:*

- [ ] GIVEN фактический `ViewConfig`/`ControlConfig`, THEN `2 × tap_pick_radius ≥ min_tap_target` (56 ≥ 48)
- [ ] GIVEN вьюпорт 360×640, WHEN fit и проекция всех pick-якорей/AABB из `KitchenLayout`, THEN для каждой интерактивной цели эффективная зона (спроецированный AABB, расширенный радиусом подбора) не меньше 48×48 dp
- [ ] *(2026-10-01, перспектива)* GIVEN сетка аспектов {0,45; 0,5625; 0,75; 1,0}, WHEN для каждого типа мирового оверлея берётся самая дальняя точка, которую он может занять (теги станций и чайники — свой якорь; жетон/кольцо/цена гостя — точки очереди и путь подхода; жетон чашки в руках, контур цели, кольцо пола — дальняя рабочая точка баристы), THEN `ViewFitMath.dp_per_metre × мировой размер` ≥ минимума HUD (текст ≥ 14 dp, цифры цены ≥ 12 dp); размеры читаются из конфига HUD, тест падает с именем оверлея
- [ ] GIVEN те же цели, THEN в отчёте теста перечислены значения min по категориям (станция / слот / гость / касса), чтобы регресс размеров был виден

---

## Implementation Notes

Новый тест, логики для порта нет (в слайсе этой проверки не было). Использует `ViewFitMath` (Story 003–004) и `KitchenLayout` (эпик kitchen-layout, story 004) для якорей/AABB; проекция — через перспективную `ViewFitMath.project`/`dp_per_metre` (ADR-0002 поправка 2026-10-01, п. 5–6), без сцены. Ожидаемое по симуляции: шаг слотов острова по глубине ≈ 27 dp (как и при ortho 39,3°) — ниже 48; если AC 9 Kitchen GDD не проходит, тест помечает это как известный layout-разрыв и эскалирует game-designer (не решается камерой). Единицы — dp = единицы вьюпорта, без DPR.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Размеры кнопок HUD (эпик hud)
- Сам `TapPicker` (эпик barista-control)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/view_fit/view_fit_tap_target_test.gd`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003, 004; kitchen-layout story 004
- Unlocks: None
