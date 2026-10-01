# Epic: View Fit & Camera

> **Layer**: Foundation
> **GDD**: design/gdd/kitchen-station-layout.md, design/gdd/hud-feedback-ui.md
> **Architecture Module**: ViewFit (+ view_fit_math)
> **Engine Risk**: HIGH
> **GDD Requirements Covered by ADRs**: 10 / 10 active
> **Status**: Ready
> **Stories**: 7 stories

## Overview

Вписывание кухни в любой портретный экран 9:20–1:1: явный stretch mode, перспективная камера-диорама (FOV 30°, pitch 52° фиксированы; поправка ADR-0002 2026-10-01), дистанция и `h_offset`/`v_offset` которой решаются от `safe_aspect` так, чтобы кухня занимала ≥ 95 % поля, letterbox, масштаб dp→px и верхняя строка HUD (Mode A/C с резервом 56 dp для почти квадратных экранов). Математика — чистые функции с unit-тестами.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0002: Viewport, camera fit & 2.5D presentation | Явный stretch, перспективная камера-диорама (дистанция от safe_aspect, кухня ≥ 95 %; было ortho), HUD-полосы, 3D-окружение + toon-спрайты, мировые оверлеи | HIGH |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-platform-007 | Stretch mode/aspect задаются явно, не дефолт 4.7 | ADR-0002 ✅ |
| TR-platform-008 | Clamp `safe_aspect` в [0,45; 1,0], letterbox, playfield по центру safe area | ADR-0002 ✅ |
| TR-platform-009 | `safe_h = max(1, …)` против деления на ноль | ADR-0002 ✅ |
| TR-platform-010 | Пересчёт safe area не чаще 1 раза за кадр | ADR-0001, ADR-0002 ✅ |
| TR-layout-010 | Кухня заполняет ≥ 0,95 playfield при любом `safe_aspect` ∈ [0,45; 1,0], равномерный масштаб | ADR-0002 ✅ |
| TR-layout-011 | Камера фиксирована — перспективная диорама; от `safe_aspect` пересчитываются дистанция и h/v_offset (rev. 2026-10-01) | ADR-0002 ✅ |
| TR-art-009 | Перспективная камера-диорама, stretch `1/cos α` на спрайт, минимальный экранный размер оверлеев в дальней точке | ADR-0002, ADR-0006 ✅ |
| TR-layout-014 | Минимальная зона тапа 48×48 dp на эталоне 360×640 dp | ADR-0002, ADR-0006 ✅ |
| TR-layout-015 | `playfield_min_fill` = 0,95, `min_tap_target` = 48 dp — данные из реестра | ADR-0004 ✅ |
| TR-hud-029 | HUD — всегда горизонтальная верхняя строка; боковые полосы под HUD не используются (только letterbox). Mode A: если верхняя полоса вокруг вписанной кухни ≥ `hud_min_strip_dp` (56 dp, конфиг ViewConfig) — HUD в ней. Иначе Mode C (почти квадратные экраны, аспект ≈ 0,8–1,0): кухня вписывается в поле минус верхняя полоса этой высоты; заполнение ≥ 95 % уменьшенного поля, от полного поля может быть < 95 % (явное исключение); телефоны 9:20–9:16 не затронуты | ADR-0002, ADR-0004 ✅ |

## Port Source (vertical slice)

Логика уже проверена в `prototypes/tea-rush-vertical-slice/`. Истории переносят её в `src/`, а не пишут заново:
- `prototypes/tea-rush-vertical-slice/src/foundation/view_fit.gd`
- `prototypes/tea-rush-vertical-slice/src/foundation/view_fit_math.gd`

## Stories

| # | Story | Type | Status | ADR | Estimate |
|---|-------|------|--------|-----|----------|
| 001 | [ViewConfig resource, валидатор и явные stretch-настройки](story-001-view-config-and-stretch.md) | Config/Data | Ready | ADR-0002, ADR-0004 | S |
| 002 | [ViewFitMath.playfield: clamp safe_aspect, letterbox, защита от деления на ноль](story-002-playfield-clamp-and-letterbox.md) | Logic | Ready | ADR-0002 | S |
| 003 | [ViewFitMath.solve_camera: дистанция и смещения перспективной камеры, kitchen_rect, глубина, upright stretch](story-003-kitchen-scale-and-camera-offsets.md) | Logic | Ready | ADR-0002 | L |
| 004 | [Резерв верхней HUD-полосы: fit_playfield, Mode A / Mode C](story-004-hud-strip-reserve-mode-c.md) | Logic | Ready | ADR-0002, ADR-0004 | M |
| 005 | [Нода ViewFit: safe_area_changed → камера, playfield_changed, не чаще раза за кадр](story-005-view-fit-node-camera-apply.md) | Integration | Ready | ADR-0002 | M |
| 006 | [Минимальная зона тапа 48×48 dp и минимальный размер оверлеев под перспективой](story-006-tap-target-min-size.md) | Integration | Ready | ADR-0002, ADR-0006 | M |
| 007 | [Визуальное подтверждение fit: 9:20, 9:16, 3:4, 1:1 и порог Mode A/C](story-007-fit-screenshot-evidence.md) | Visual/Feel | Ready | ADR-0002 | S |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/kitchen-station-layout.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories view-fit` to break this epic into implementable stories.
