# Story 003: ViewFitMath.solve_camera: дистанция и смещения перспективной камеры, kitchen_rect, глубина, upright stretch

> **Epic**: View Fit & Camera
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: L
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/kitchen-station-layout.md`, `design/gdd/hud-feedback-ui.md`
**Requirement**: `TR-layout-010`, `TR-layout-011`, `TR-art-009`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Viewport, camera fit & 2.5D presentation
**ADR Decision Summary**: Stretch `canvas_items`/`expand` на базе 360×640 (1 единица вьюпорта = 1 reference dp); одна **перспективная камера-диорама** (поправка 2026-10-01: FOV 30°, pitch 52°, yaw и точка взгляда фиксированы) — чистый `ViewFitMath.solve_camera` решает дистанцию вдоль оси взгляда и `h_offset`/`v_offset` от playfield так, что кухня занимает ≥ `kitchen_fill_target` (≥ 0,95) ограничивающей стороны (было: ortho `size`); на почти квадратных экранах HUD-полоса 56 dp резервируется (Mode C).
**ADR Version**: 2026-10-01 (diorama camera amendment)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: Stretch-настройки 4.7 задаются явно (дефолты изменились); `Camera3D` perspective `fov`/`keep_aspect`/`h_offset`/`v_offset`, `unproject_position` — pre-cutoff API (учёт offsets в проекции под перспективой — проверить в 4.7.2, ADR-0002 V5); нужно проверить на web и устройстве, что `get_viewport().get_final_transform()` корректно переводит px в единицы вьюпорта.

**Control Manifest Rules (from ADR; no control manifest at this tier)**:
- Required: stretch mode/aspect/base size заданы явно в `project.godot` (`canvas_items` / `expand` / 360×640); не полагаться на дефолты 4.7 *(from ADR-0002)*
- Required: вся математика fit — чистые статические функции `ViewFitMath`; нода только применяет результат *(from ADR-0002)*
- Required: все screen-space константы в dp = единицах вьюпорта; `camera_pitch_deg`, `kitchen_fill_target`, `viewport_aspect_min/max`, `hud_min_strip_dp` — из валидированного конфига *(from ADR-0002)*

Ядро fit (переписано 2026-10-01 под перспективную камеру-диораму, ADR-0002 поправка «diorama camera», п. 1–4, 10–11): фиксированные FOV/pitch/yaw/точка взгляда; чистая функция решает **дистанцию `D`** вдоль оси взгляда (бисекция по монотонному `fill`) и **`h_offset`/`v_offset`** (3 фиксированных прохода перецентровки), отдаёт `kitchen_rect` (AABB 8 спроецированных углов `frame_bounds`), `depth_range` и `near`. Плюс `upright_stretch` и `dp_per_metre`. Камера игроком не двигается и не зумится; `fov` в рантайме не меняется.

---

## Acceptance Criteria

*From GDD and ADR, scoped to this story:*

- [ ] GIVEN `safe_aspect` ∈ {0,45; 0,5; 0,5625; 0,6; 0,75; 0,8; 0,9; 1,0} и широкий 1,778, FOV ∈ {25, 30, 35}, pitch ∈ {45, 52, 60}, WHEN `solve_camera`, THEN ограничивающая сторона `P_fit` заполнена на `kitchen_fill_target` ± 1e-3, центр `kitchen_rect` в пределах 0,5 dp от центра `P_fit`, `kitchen_rect` целиком внутри playfield, все 8 углов перед `near`
- [ ] GIVEN эталонная геометрия (x −4…4, y 0…1,8, z −7,5…3,8 м; pitch 52°, FOV 30°, fill 0,96) и вьюпорт 360×640, THEN `D` ≈ 32,5 м и `kitchen_rect` ≈ 346×376 dp (допуск задаётся в тесте; ожидания выведены независимо — прямой проекцией углов при найденном `D`, а не тем же решателем)
- [ ] GIVEN `project()`, THEN это та же формула, что у `Camera3D` (`k = V.h / (2·tan(fov/2))`, KEEP_HEIGHT, offsets — сдвиг камеры по своим осям); знак `v_offset` зафиксирован тестом (экранный y растёт вниз)
- [ ] GIVEN `upright_stretch(cam, pivot)` на оптической оси, THEN = 1/cos(pitch) (1,624 при 52°); `dp_per_metre` = `k / z`
- [ ] Число итераций фиксировано (3 прохода × 32 шага бисекции + финальная бисекция) — нет открытых циклов; функция вызывается только на debounced resize

---

## Implementation Notes

Из слайса (`prototypes/tea-rush-vertical-slice/src/foundation/view_fit_math.gd`) переносится только получение 8 углов `frame_bounds`; ortho-`fit()` **не переносится** (заменён `solve_camera`). Сигнатуры — ADR-0002 поправка «diorama camera», п. 10 (`CameraFit` — RefCounted value object: `distance`, `h_offset`, `v_offset`, `near`, `kitchen_rect`, `depth_range`). Ортоконстанты тестов слайса (`test_view_fit_*` для 360×640/360×800) недействительны. Эталонные числа симуляции — в ADR-0002 поправке, п. 2. Если `fill` окажется немонотонным на сетке — стоп и эскалация technical-director (запасной вариант — `PROJECTION_FRUSTUM` с lens shift).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 004: резерв HUD-полосы (Mode C) — `fit_playfield`
- Story 005: применение к `Camera3D`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/view_fit/view_fit_camera_solve_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002
- Unlocks: Story 004, 005, 006, 007
