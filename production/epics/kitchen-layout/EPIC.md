# Epic: Kitchen & Station Layout

> **Layer**: Foundation
> **GDD**: design/gdd/kitchen-station-layout.md
> **Architecture Module**: KitchenLayout
> **Engine Risk**: HIGH
> **GDD Requirements Covered by ADRs**: 8 / 13 active
> **Status**: Ready
> **Stories**: 7 stories

## Overview

Данные кухни ~8×11 м: станции у стен, остров 2×4 м, 7 слотов, 4 слота гостей, spawn/exit, точка кассы, footprints для NavMesh и pick-якоря со стабильными ID `(owner_id, index)`. Модуль только объявляет геометрию; занятость слотов принадлежит Brewing. Визуальная сборка 3D-окружения идёт в эпиках `visual-pipeline` и `art-assets` поверх этих данных.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0002: Viewport, camera fit & 2.5D presentation | Явный stretch, перспективная камера-диорама (дистанция от safe_aspect, кухня ≥ 95 %; было ortho), HUD-полосы, 3D-окружение + toon-спрайты, мировые оверлеи | HIGH |
| ADR-0004: Data config & load-time validation | GameConfig + подресурсы .tres, ConfigValidator собирает все ошибки, RNG инъекцией | LOW |
| ADR-0006: Navigation & tap picking | NavMesh из данных + прямые запросы NavigationServer3D, выбор тапа без физики, ID (owner_id, index), запасной GridNavigator | MEDIUM |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-layout-001 | Фиксированная кухня ~8×11 м, одна раскладка в MVP | ADR-0004 ✅ |
| TR-layout-002 | Станции по периметру с промежутками, остров 2×4 м делит кухню на два прохода | GDD/UX — ADR не требуется |
| TR-layout-003 | 7 слотов: 5 на острове + по 1 у боковых стен | GDD/UX — ADR не требуется |
| TR-layout-004 | Сплошная низкая столешница; станции — блоки; слоты — площадки | GDD/UX — ADR не требуется |
| TR-layout-005 | Till-anchor — фиксированная мировая точка, не станция и не слот | GDD/UX — ADR не требуется |
| TR-layout-006 | Занятость слотов принадлежит Brewing; layout только объявляет слоты | GDD/UX — ADR не требуется |
| TR-layout-007 | Bake NavMesh без ошибок и предупреждений | ADR-0006 ✅ |
| TR-layout-008 | Путь из till-anchor до каждого слота и станции существует, изолированных карманов нет | ADR-0006 ✅ |
| TR-layout-009 | `station_types` точно совпадает с расставленными станциями | ADR-0004 ✅ |
| TR-layout-012 | Зазор у точек взаимодействия ≥ `agent_radius` = 0,40 м (приёмка пути: ≥ `agent_radius − 0,05`) | ADR-0006 ✅ |
| TR-layout-013 | Footprints станций, столешниц и стен (данные `KitchenConfig`, не коллизионные формы) не пересекаются | ADR-0006, ADR-0004 ✅ |
| TR-layout-016 | Статика окружения — 3D-меши с запечённым в vertex colors светом и AO (unshaded); без шейдерных анимаций окружения и параллакса; единственный реальный свет — DirectionalLight3D для теней динамики (ADR-0002 amendment 2026-10-01); статичное свечение till-anchor | ADR-0002 ✅ |
| TR-layout-017 | Для гостей: 1 точка спавна, 4 точки очереди со стабильными ID, 1 выход — все на навигационной области | ADR-0006 ✅ |

## Port Source (vertical slice)

Логика уже проверена в `prototypes/tea-rush-vertical-slice/`. Истории переносят её в `src/`, а не пишут заново:
- `prototypes/tea-rush-vertical-slice/src/foundation/kitchen_layout.gd`
- `prototypes/tea-rush-vertical-slice/src/foundation/config/kitchen_config.gd`

## Stories

| # | Story | Type | Status | ADR | Estimate |
|---|-------|------|--------|-----|----------|
| 001 | [KitchenConfig: типизированная схема с sentinel-полями](story-001-kitchen-config-schema.md) | Logic | Ready | ADR-0004, ADR-0006 | M |
| 002 | [Shipped-данные: станции, остров, 7 слотов, мусорка, столешницы](story-002-kitchen-stations-slots-data.md) | Config/Data | Ready | ADR-0004 | M |
| 003 | [Shipped-данные: till-anchor, spawn, 4 слота очереди, выход](story-003-till-and-guest-points-data.md) | Config/Data | Ready | ADR-0004, ADR-0006 | S |
| 004 | [KitchenLayout: производная геометрия, стабильные ID, pick-якоря, footprints](story-004-kitchen-layout-derived-geometry.md) | Logic | Ready | ADR-0006, ADR-0004 | L |
| 005 | [ConfigValidator: station_types, footprints, слоты, мусорка](story-005-kitchen-config-validator-rules.md) | Logic | Ready | ADR-0004 | M |
| 006 | [NavMesh на данных кухни: bake без предупреждений, пути, зазоры](story-006-kitchen-navmesh-verification.md) | Integration | Ready | ADR-0006 | M |
| 007 | [Сцена кухни: gray-box из данных и ограничения рендера окружения](story-007-kitchen-scene-graybox-env-constraints.md) | Integration | Ready | ADR-0002, ADR-0006 | M |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/kitchen-station-layout.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories kitchen-layout` to break this epic into implementable stories.
