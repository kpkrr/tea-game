# Epic: Player Control / Barista Movement

> **Layer**: Core
> **GDD**: design/gdd/player-control-barista-movement.md
> **Architecture Module**: TapPicker · BaristaController · Pathing
> **Engine Risk**: HIGH
> **GDD Requirements Covered by ADRs**: 19 / 19 active
> **Status**: Ready
> **Stories**: 11 stories

## Overview

Управление одним тапом: выбор цели (pick-якорь в 28 dp → луч по AABB → пол), путь по NavMesh с отступом `agent_radius`, мгновенное перенаправление без очереди, состояния Idle/Walking/Holding с предложением действия владельцу цели каждый тик и отказ ввода после конца матча. Отклик ≤ 50 мс.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0006: Navigation & tap picking | NavMesh из данных + прямые запросы NavigationServer3D, выбор тапа без физики, ID (owner_id, index), запасной GridNavigator | MEDIUM |
| ADR-0003: Match simulation — clock, tick order, pause | GameClock + MatchDirector, фиксированный порядок тика, без SceneTree.paused, типизированные сигналы, DI через корень композиции | LOW |
| ADR-0004: Data config & load-time validation | GameConfig + подресурсы .tres, ConfigValidator собирает все ошибки, RNG инъекцией | LOW |
| ADR-0002: Viewport, camera fit & 2.5D presentation | Явный stretch, перспективная камера-диорама (дистанция от safe_aspect, кухня ≥ 95 %; было ortho), HUD-полосы, 3D-окружение + toon-спрайты, мировые оверлеи | HIGH |
| ADR-0007: Performance & load budgets | 60/30 fps, мс на систему, draw calls ≤ 180, .pck ≤ 11 МБ, загрузка ≤ 21,5 МБ, уровни качества Low/Mid/High, PerfProbe | MEDIUM |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-control-001 | Выбор тапа: ближайший pick-якорь (иконка станции / жетон гостя) в `tap_pick_radius` → иначе луч против статических AABB и плоскости пола (без физики) → иначе no-op | ADR-0006 ✅ |
| TR-control-002 | Тап вне навигационной области → ближайшая достижимая точка XZ | ADR-0006 ✅ |
| TR-control-003 | Очереди тапов нет: последний тап сразу заменяет цель в любом состоянии | ADR-0003 ✅ |
| TR-control-004 | Запрос валидности у владельца цели до выхода; пол всегда валиден | ADR-0003 ✅ |
| TR-control-005 | Станция с несколькими точками подхода: кратчайший путь, при равенстве — меньший ID | ADR-0006 ✅ |
| TR-control-006 | `effective_speed = 4,0 м/с × speed_multiplier` {1,0; 1,15; 1,3; 1,5} | ADR-0004 ✅ |
| TR-control-007 | Путь держит `body_clearance = agent_radius` (допуск −0,05 м из-за эрозии Recast целыми ячейками), спрямляется по прямой видимости | ADR-0006 ✅ |
| TR-control-008 | `agent_radius = work_gap 0,45 − clearance_margin 0,05 = 0,40 м` | ADR-0006, ADR-0004 ✅ |
| TR-control-009 | Holding: предложение действия раз за тик; EXECUTE→Idle / WAIT→Holding / REFUSE→Idle | ADR-0003 ✅ |
| TR-control-010 | Цель «пол» никогда не переводит в Holding | ADR-0003 ✅ |
| TR-control-011 | `tap_pick_radius` = 28 dp, пересчёт в px при смене масштаба | ADR-0002, ADR-0006 ✅ |
| TR-control-012 | `t_step` = 2,0 с — авторитетное значение для Order & Recipe | ADR-0004 ✅ |
| TR-control-013 | Состояния Idle/Walking/Holding с заданными переходами | ADR-0003 ✅ |
| TR-control-014 | `AnimatedSprite3D`, ходьба в 4 направлениях, без бленда | ADR-0002 ✅ |
| TR-control-015 | Задержка ≤ 50 мс (3 кадра) на маркер, старт, перенаправление, отказ — внутри движка | ADR-0007 ✅ |
| TR-control-016 | Пауза только через игровое время Guest AI, не через visibility-сигнал | ADR-0003 ✅ |
| TR-control-017 | Шаг кадра `speed × dt` может пройти несколько точек пути без проскока | ADR-0006, ADR-0003 ✅ |
| TR-control-018 | Тапом считается только press; последний press за кадр побеждает | ADR-0006 ✅ |
| TR-control-019 | Конец матча: ввод отклоняется, путь сбрасывается, бариста стоит на месте | ADR-0003 ✅ |

## Port Source (vertical slice)

Логика уже проверена в `prototypes/tea-rush-vertical-slice/`. Истории переносят её в `src/`, а не пишут заново:
- `prototypes/tea-rush-vertical-slice/src/core/tap_picker.gd`
- `prototypes/tea-rush-vertical-slice/src/core/barista_controller.gd`
- `prototypes/tea-rush-vertical-slice/src/core/pathing.gd`
- `prototypes/tea-rush-vertical-slice/src/foundation/config/control_config.gd`

## Stories

| # | Story | Type | Status | ADR | Estimate |
|---|-------|------|--------|-----|----------|
| 001 | [ControlConfig и производные значения (скорость, радиусы, t_step)](story-001-control-config-derived-values.md) | Logic | Ready | ADR-0004 | S |
| 002 | [TapPicker: отбор цели по близости pick-якоря](story-002-tap-picker-proximity.md) | Logic | Ready | ADR-0006 | M |
| 003 | [TapPicker: луч против AABB и плоскость пола](story-003-tap-picker-geometry.md) | Logic | Ready | ADR-0006 | M |
| 004 | [TapInput: приём нажатий, последний press за кадр, сброс вне игры](story-004-tap-input-node.md) | Integration | Ready | ADR-0006 | M |
| 005 | [NavMeshBaker и Pathing: запекание, готовность, dispose](story-005-nav-mesh-baker-pathing.md) | Integration | Ready | ADR-0006 | L |
| 006 | [Navigator: клэмп цели, выбор точки подхода, boot self-check](story-006-navigator-queries.md) | Integration | Ready | ADR-0006 | M |
| 007 | [PathFollower: движение по пути без разгона и проскока](story-007-path-follower-movement.md) | Logic | Ready | ADR-0006 | S |
| 008 | [BaristaController: Idle/Walking/Holding, перенаправление, валидность, протокол владельца](story-008-barista-controller-states.md) | Logic | Ready | ADR-0003 | L |
| 009 | [BaristaController: пауза, конец матча, исчезновение цели, сброс](story-009-barista-pause-match-end.md) | Logic | Ready | ADR-0003 | M |
| 010 | [BaristaView: 4-направленная ходьба, маркер цели, чашка в руках](story-010-barista-view-animation.md) | Visual/Feel | Ready | ADR-0002 | M |
| 011 | [Интеграция: отклик на тап <= 3 кадра (маркер, старт, перенаправление, отказ)](story-011-control-response-latency.md) | Integration | Ready | ADR-0007 | M |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/player-control-barista-movement.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/story-readiness production/epics/barista-control/story-001-*.md`, затем `/dev-story`.
