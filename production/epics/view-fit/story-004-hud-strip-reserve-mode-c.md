# Story 004: Резерв верхней HUD-полосы: fit_playfield, Mode A / Mode C

> **Epic**: View Fit & Camera
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/kitchen-station-layout.md`, `design/gdd/hud-feedback-ui.md`
**Requirement**: `TR-hud-029`
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

Поправка ADR-0002 (2026-09-30): HUD — всегда горизонтальная верхняя строка. Если верхняя полоса вокруг вписанной кухни ≥ `hud_min_strip_dp` (Mode A) — HUD в ней; иначе (почти квадратные экраны, Mode C) кухня вписывается в playfield минус верхняя полоса 56 dp. Боковые полосы никогда не считаются. Это явное исключение из «≥ 95 %» Kitchen GDD.

---

## Acceptance Criteria

*From GDD and ADR, scoped to this story:*

- [ ] GIVEN 360×800 и 360×640, WHEN `fit_playfield`, THEN `P_fit == P` и результат идентичен формуле без поправки (регрессия, Mode A)
- [ ] GIVEN 640×640 (1:1), WHEN fit, THEN резерв взят: `kitchen_rect.position.y − P.position.y ≥ hud_min_strip_dp`, ограничивающая сторона `P_fit` заполнена ровно на `kitchen_fill_target`, а заполнение полного `P` < 0,95 принято как исключение
- [ ] GIVEN 480×640 (3:4) и случай, когда боковая полоса ≥ 56 dp, но верхняя < 56, THEN верхняя полоса ≥ 56 в обеих ветках, и резерв берётся (боковые полосы не учитываются); сигнал несёт полный `P`, а камера центрируется по `P_fit`
- [ ] GIVEN `hud_min_strip_dp` из `ViewConfig`, THEN в коде нет литерала 56; переключение ветки — чистая функция от `P` без гистерезиса

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/foundation/view_fit_math.gd::fit()` — ветка `reserved` (Mode C) уже реализована; вынести в `static func fit_playfield(playfield: Rect2, kitchen_rect_full: Rect2, hud_min_strip: float) -> Rect2` (возвращает `P_fit`; поправка ADR-0002 2026-10-01: сначала `solve_camera` для полного `P`, его `kitchen_rect` решает Mode A/C, при Mode C — второй `solve_camera` с `P_fit`). Тест расширяет `test_view_fit_mode_a_on_phone_mode_c_on_square` из слайса до сетки аспектов 9:20 … 1:1 (включая обе стороны порога переключения). Телефоны 9:20–9:16 не затронуты (их верхняя полоса заведомо больше 56 dp).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- HUD-раскладка строки (эпик hud) — HUD лишь читает `playfield`/`kitchen_rect`
- Story 007: скриншоты Mode A/C

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/view_fit/view_fit_hud_strip_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001, 003
- Unlocks: Story 005, 007
