# Story 007: Визуальное подтверждение fit: 9:20, 9:16, 3:4, 1:1 и порог Mode A/C

> **Epic**: View Fit & Camera
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Visual/Feel
> **Estimate**: S
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/kitchen-station-layout.md`, `design/gdd/hud-feedback-ui.md`
**Requirement**: `TR-layout-010`, `TR-hud-029`, `TR-layout-011`
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

Parse check — не запуск. Запускаем игру в браузере на нескольких аспектах и сохраняем скриншоты как доказательство, что кухня вписана, letterbox чистый, а HUD-полоса не перекрывает `kitchen_rect`.

---

## Acceptance Criteria

*From GDD and ADR, scoped to this story:*

- [ ] Скриншоты на 360×800 (9:20), 360×640 (9:16), 480×640 (3:4), 640×640 (1:1) и на двух аспектах по обе стороны порога Mode A/C сохранены в `production/qa/evidence/` и перечислены в `view-fit-evidence.md`
- [ ] На каждом кадре видны все 7 слотов, все станции и till anchor без обрезки; масштаб равномерный; на phone-аспектах кухня ≥ 95 % ограничивающей стороны playfield; на 1:1 сверху видна свободная полоса ≥ 56 dp
- [ ] *(2026-10-01)* Перспективная камера: скриншот широкого окна 16:9 на Mid/High (декорации в letterbox, не заходят в `kitchen_rect`) и на Low (`background_color`); задняя стена и ряд гостей читаются, спрайты не сплющены/не вытянуты (upright stretch на спрайт)
- [ ] Изменение размера окна через порог переключает fit в один кадр без анимации; в `view-fit-evidence.md` — подпись владельца/lead

---

## Implementation Notes

Процедура запуска и снятия скриншота — `.claude/docs/run-and-observe.md` (Godot web export или `--headless`-совместимый режим окна заданного размера). Кухня на этом этапе может быть gray-box/слайс-сценой: проверяется fit, а не финальный вид окружения (его готовят `visual-pipeline`/`art-assets`). При смене `frame_bounds` после появления финальной 3D-кухни скриншоты переснять.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Финальный арт окружения и персонажей — эпики visual-pipeline / art-assets
- Раскладка HUD — эпик hud

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**:
- Visual/Feel: `production/qa/evidence/fit-screenshot-evidence-evidence.md` + retained screenshot + sign-off

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 005
- Unlocks: None
