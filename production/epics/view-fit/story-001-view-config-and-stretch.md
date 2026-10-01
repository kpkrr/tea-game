# Story 001: ViewConfig resource, валидатор и явные stretch-настройки

> **Epic**: View Fit & Camera
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Config/Data
> **Estimate**: S
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/kitchen-station-layout.md`, `design/gdd/hud-feedback-ui.md`
**Requirement**: `TR-platform-007`, `TR-layout-015`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Viewport, camera fit & 2.5D presentation
**ADR Decision Summary**: Stretch `canvas_items`/`expand` на базе 360×640 (1 единица вьюпорта = 1 reference dp); одна **перспективная камера-диорама** (поправка 2026-10-01: FOV 30°, pitch 52°, yaw и точка взгляда фиксированы) — чистый `ViewFitMath.solve_camera` решает дистанцию вдоль оси взгляда и `h_offset`/`v_offset` от playfield так, что кухня занимает ≥ `kitchen_fill_target` (≥ 0,95) ограничивающей стороны (было: ortho `size`); на почти квадратных экранах HUD-полоса 56 dp резервируется (Mode C).
**ADR Version**: 2026-09-30 (secondary: ADR-0004 2026-09-30)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: Stretch-настройки 4.7 задаются явно (дефолты изменились); `Camera3D` perspective `fov`/`keep_aspect`/`h_offset`/`v_offset`, `unproject_position` — pre-cutoff API (учёт offsets в проекции под перспективой — проверить в 4.7.2, ADR-0002 V5); нужно проверить на web и устройстве, что `get_viewport().get_final_transform()` корректно переводит px в единицы вьюпорта.

**Control Manifest Rules (from ADR; no control manifest at this tier)**:
- Required: stretch mode/aspect/base size заданы явно в `project.godot` (`canvas_items` / `expand` / 360×640); не полагаться на дефолты 4.7 *(from ADR-0002)*
- Required: вся математика fit — чистые статические функции `ViewFitMath`; нода только применяет результат *(from ADR-0002)*
- Required: каждый `@export` конфиг-поля — статический тип + sentinel по умолчанию; новое поле поставляется вместе с правилом валидатора *(from ADR-0004)*
- Required: модули получают конфиг через конструктор (DI из `MatchDirector._compose()`); тесты строят конфиг фабрикой, не чтением `.tres` *(from ADR-0004)*

Фундамент эпика: типизированный `ViewConfig` с sentinel-полями, правила валидатора и явные настройки stretch в `project.godot`, чтобы 4.7-дефолты не влияли на результат. Значения `playfield_min_fill` и `min_tap_target` живут в данных, не в коде.

---

## Acceptance Criteria

*From GDD and ADR, scoped to this story:*

- [ ] `project.godot` содержит явно `window/stretch/mode = canvas_items`, `window/stretch/aspect = expand`, `window/size/viewport_width/height = 360/640` (тест читает `ProjectSettings` и сравнивает)
- [ ] `ViewConfig` хранит `viewport_aspect_min/max` (0,45 / 1,0), `kitchen_fill_target` (0,96), `playfield_min_fill` (0,95), `min_tap_target` (48), `hud_min_strip_dp` (56), `camera_fov_deg` (30), `camera_pitch_deg` (52), `camera_yaw_deg` (0), `camera_look_at`, `camera_far_m` (150), `frame_bounds`, `background_color` (бывш. `letterbox_color`), `scenery_cover_aspect` (2,4); **`camera_position` удалён** — позиция выводится из решённой дистанции (ADR-0002 поправка 2026-10-01); каждое поле — статический тип с sentinel (`NAN` / `-1`)
- [ ] Правила валидатора: пропущенное поле → `missing`; `0 < aspect_min < aspect_max ≤ 1`; `0,95 ≤ kitchen_fill_target ≤ 1,0`; `1 ≤ hud_min_strip_dp ≤ 160`; `25 ≤ camera_fov_deg ≤ 35`; `45 ≤ camera_pitch_deg ≤ 60`; `−30 ≤ camera_yaw_deg ≤ 30`; `camera_far_m ≥ 60`; `1,0 ≤ scenery_cover_aspect ≤ 3,0`; `playfield_min_fill == 0,95` и `min_tap_target == 48` совпадают с `design/registry/entities.yaml`; все ошибки собираются, а не только первая

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/foundation/config/view_config.gd` (sentinels верны; набор полей — дополнить камерными ключами диорамы и убрать `camera_position`, значение pitch 39,3 → 52) — добавить doc comments и `class_name ViewConfig`, файл в `src/foundation/config/view_config.gd`, данные в `assets/data/config/view.tres` (значения из `prototypes/tea-rush-vertical-slice/data/game_config.tres`). Правила зарегистрировать в `ConfigValidator` (эпик foundation-runtime); до его готовности тестировать правила через чистую функцию `ViewConfigRules.validate(cfg) -> Array[ConfigError]`. Тесты строят конфиг фабрикой (`ConfigFactory.valid()` + override), не читают `.tres` (кроме одного теста shipped-значений — неверные типы в `.tres` коэрсятся молча, ADR-0004).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002–004: сама математика fit
- Story 005: нода `ViewFit`, подписка на `safe_area_changed`
- `HudConfig.hud_row_height_dp` ≤ `hud_min_strip_dp` (кросс-системный invariant) — эпик hud

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**:
- Config/Data: smoke check pass (`production/qa/smoke-*.md`) + unit/integration test of the shipped `.tres` (см. Implementation Notes)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (ConfigValidator из foundation-runtime — мягкая зависимость)
- Unlocks: Story 002, 003, 004, 005
