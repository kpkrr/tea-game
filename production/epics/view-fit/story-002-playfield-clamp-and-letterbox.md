# Story 002: ViewFitMath.playfield: clamp safe_aspect, letterbox, защита от деления на ноль

> **Epic**: View Fit & Camera
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/kitchen-station-layout.md`, `design/gdd/hud-feedback-ui.md`
**Requirement**: `TR-platform-008`, `TR-platform-009`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Viewport, camera fit & 2.5D presentation
**ADR Decision Summary**: Stretch `canvas_items`/`expand` на базе 360×640 (1 единица вьюпорта = 1 reference dp); одна **перспективная камера-диорама** (поправка 2026-10-01: FOV 30°, pitch 52°, yaw и точка взгляда фиксированы) — чистый `ViewFitMath.solve_camera` решает дистанцию вдоль оси взгляда и `h_offset`/`v_offset` от playfield так, что кухня занимает ≥ `kitchen_fill_target` (≥ 0,95) ограничивающей стороны (было: ortho `size`); на почти квадратных экранах HUD-полоса 56 dp резервируется (Mode C).
**ADR Version**: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: Stretch-настройки 4.7 задаются явно (дефолты изменились); `Camera3D` perspective `fov`/`keep_aspect`/`h_offset`/`v_offset`, `unproject_position` — pre-cutoff API (учёт offsets в проекции под перспективой — проверить в 4.7.2, ADR-0002 V5); нужно проверить на web и устройстве, что `get_viewport().get_final_transform()` корректно переводит px в единицы вьюпорта.

**Control Manifest Rules (from ADR; no control manifest at this tier)**:
- Required: stretch mode/aspect/base size заданы явно в `project.godot` (`canvas_items` / `expand` / 360×640); не полагаться на дефолты 4.7 *(from ADR-0002)*
- Required: вся математика fit — чистые статические функции `ViewFitMath`; нода только применяет результат *(from ADR-0002)*
- Required: все screen-space константы в dp = единицах вьюпорта; `camera_pitch_deg`, `kitchen_fill_target`, `viewport_aspect_min/max`, `hud_min_strip_dp` — из валидированного конфига *(from ADR-0002)*

Первый шаг fit: из safe area получить playfield — прямоугольник с аспектом в [0,45; 1,0], по центру safe area. Остаток вьюпорта — letterbox (фон, не отдельная нода).

---

## Acceptance Criteria

*From GDD and ADR, scoped to this story:*

- [ ] GIVEN safe area с аспектом < 0,45 или > 1,0, WHEN `ViewFitMath.playfield(safe, amin, amax)`, THEN результат имеет аспект ровно на границе clamp и центрирован в safe area; аспект внутри диапазона возвращается без изменений
- [ ] GIVEN safe area с высотой 0 или отрицательной, WHEN считается `safe_aspect`, THEN используется `safe_h = max(1, h)`, деления на ноль нет, результат конечен (не NaN/INF)
- [ ] GIVEN 360×800, 360×640, 640×640 и очень высокий 200×1000 вьюпорт, WHEN считается playfield, THEN он целиком внутри safe area, а остаток (letterbox) не пересекается с playfield

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/foundation/view_fit_math.gd` (`playfield()` уже реализует clamp и центрирование; `maxf(size.y, 1.0)` — это `safe_h`). Привести к сигнатуре ADR-0002: `static func playfield(safe: Rect2, aspect_min: float, aspect_max: float) -> Rect2`, `class_name ViewFitMath extends RefCounted`, файл `src/foundation/view_fit_math.gd`. Добавить doc comments. Границы аспекта передаются параметрами (из `ViewConfig`), не литералами. Тест — сетка аспектов с детерминированными значениями.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: масштаб кухни и смещения камеры
- Story 005: перевод px → dp и применение к ноде

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/view_fit/view_fit_playfield_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: Story 003, 004, 005
