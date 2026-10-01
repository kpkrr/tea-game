# Story 005: Нода ViewFit: safe_area_changed → камера, playfield_changed, не чаще раза за кадр

> **Epic**: View Fit & Camera
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/kitchen-station-layout.md`, `design/gdd/hud-feedback-ui.md`
**Requirement**: `TR-platform-010`, `TR-layout-011`, `TR-platform-007`
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

Нода в сцене кухни (не autoload) применяет результаты `ViewFitMath` к `Camera3D` и сообщает HUD, где playfield и кухня. Пересчёт происходит только по `PlatformBridge.safe_area_changed`, склеенные события в один кадр дают один пересчёт.

---

## Acceptance Criteria

*From GDD and ADR, scoped to this story:*

- [ ] GIVEN `safe_area_changed(rect_px)`, WHEN нода обрабатывает, THEN px переводятся в dp через `get_viewport().get_final_transform().affine_inverse()`, `Camera3D.position` (= `camera_look_at − forward × D`), `h_offset`/`v_offset`, `near` обновляются в том же кадре (без tween; `projection = PERSPECTIVE`, `keep_aspect = KEEP_HEIGHT`, `fov` и поворот задаются один раз в `setup` и больше не меняются — поправка ADR-0002 2026-10-01), после чего эмитится `playfield_changed(playfield, kitchen_rect)` с полным `P`
- [ ] GIVEN fit применён, THEN `get_depth_range()` и `get_camera_position()` возвращают значения последнего fit (их читают свет/туман/спрайты в обработчике `playfield_changed`); интеграционный тест V5: `ViewFitMath.project` совпадает с `Camera3D.unproject_position` в пределах 0,5 dp для 8 углов `frame_bounds` на 360×640, 360×800, 640×640
- [ ] GIVEN несколько `safe_area_changed` за один кадр, WHEN кадр обработан, THEN пересчёт выполнен ровно один раз (счётчик вызовов `apply` в тесте), по последнему значению
- [ ] GIVEN нода ViewFit, THEN она не подключается к `size_changed` и не читает `DisplayServer`, не трогает `GameClock`/`MatchLifecycle`/состояние сущностей (проверка grep в тесте/CI); debug assert сверяет `final_transform` с `get_visible_rect()`

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/foundation/view_fit.gd` (`setup()` настраивает камеру, `apply()` применяет fit и эмитит сигнал). Доработать до стандартов: `class_name ViewFit extends Node`, типизированные зависимости через `setup(camera: Camera3D, cfg: ViewConfig)` (DI, без `Resource`), геттеры `get_playfield()`/`get_kitchen_rect()`, сигнал как в ADR. Слайс применяет fit синхронно — добавить коалесцирование: `safe_area_changed` сохраняет pending-rect и ставит флаг, `_process` применяет раз в кадр (снимок тестируется с двумя вызовами подряд). Тест использует фейковый источник сигнала и `SubViewport`/`Camera3D`; `PlatformBridge` — из эпика platform-shell (в тесте заменить эмиттером-заглушкой). Проверить на web: `final_transform` корректен при `canvas_items`/`expand` (Verification Required (1) ADR-0002), при провале assert переключиться на `get_screen_transform()`.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- PlatformBridge и само вычисление safe area — эпик platform-shell
- Story 007: визуальные доказательства

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/view_fit/view_fit_node_test.gd`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001, 003, 004; PlatformBridge (platform-shell) — можно заглушкой
- Unlocks: Story 006, 007
