# Epic: Guest AI & Patience + Match Lifecycle

> **Layer**: Feature
> **GDD**: design/gdd/guest-ai-patience.md
> **Architecture Module**: MatchLifecycle · GuestSim
> **Engine Risk**: HIGH
> **GDD Requirements Covered by ADRs**: 23 / 23 active
> **Status**: Ready
> **Stories**: 11 stories

## Overview

Жизненный цикл партии (BOOTING/IDLE/RUNNING/ENDED, пауза, `match_started`/`match_ended`) и гости: спавн по кривой, 4 слота, терпение, подача любому гостю с совпадающим заказом, уход и конец после 3 ушедших. Онбординг первых 15 с. Бюджет Guest AI ≤ 0,5 мс в среднем. Детерминизм через внедрённый RNG.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0003: Match simulation — clock, tick order, pause | GameClock + MatchDirector, фиксированный порядок тика, без SceneTree.paused, типизированные сигналы, DI через корень композиции | LOW |
| ADR-0004: Data config & load-time validation | GameConfig + подресурсы .tres, ConfigValidator собирает все ошибки, RNG инъекцией | LOW |
| ADR-0006: Navigation & tap picking | NavMesh из данных + прямые запросы NavigationServer3D, выбор тапа без физики, ID (owner_id, index), запасной GridNavigator | MEDIUM |
| ADR-0007: Performance & load budgets | 60/30 fps, мс на систему, draw calls ≤ 180, .pck ≤ 11 МБ, загрузка ≤ 21,5 МБ, уровни качества Low/Mid/High, PerfProbe | MEDIUM |
| ADR-0002: Viewport, camera fit & 2.5D presentation | Явный stretch, перспективная камера-диорама (дистанция от safe_aspect, кухня ≥ 95 %; было ortho), HUD-полосы, 3D-окружение + toon-спрайты, мировые оверлеи | HIGH |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-guest-001 | Машина состояний гостя Approaching → Waiting → {Served \\\| Leaving} → удалён | Leaving} → удалён ✅ |
| TR-guest-002 | `guest_slot_count` = 4 со стабильными ID; невалидное значение — ошибка загрузки | ADR-0004 ✅ |
| TR-guest-003 | `spawn_interval = 60 / (gpm(t) × onboarding_multiplier)`; фиксируется при спавне | ADR-0004 ✅ |
| TR-guest-004 | Отложенный спавн при занятых слотах; в очереди максимум один | ADR-0003 ✅ |
| TR-guest-005 | Терпение тикает с момента спавна | ADR-0003 ✅ |
| TR-guest-006 | Путь к слоту на 3,0 м/с; нет пути → сразу Waiting + лог | ADR-0006 ✅ |
| TR-guest-007 | Точка взаимодействия — всегда слот гостя | ADR-0003 ✅ |
| TR-guest-008 | Подача: `matches()` → `consume_held_cup()` один раз → Served в том же тике | ADR-0003 ✅ |
| TR-guest-009 | `remaining_fraction = clamp(1 − t/patience_max_g, 0, 1)`; `patience_max_g` фиксируется при спавне | ADR-0003 ✅ |
| TR-guest-010 | Слот освобождается при переходе в Served/Leaving | ADR-0003 ✅ |
| TR-guest-011 | Порядок тика: подачи → таймауты → конец → спавн; подача побеждает таймаут | ADR-0003 ✅ |
| TR-guest-012 | Player Control обновляется раньше Guest AI в том же кадре | ADR-0003 ✅ |
| TR-guest-013 | `guests_lost == 3` → заморозка, `match_ended` ровно один раз | ADR-0003 ✅ |
| TR-guest-014 | Онбординг 15 с: только простые рецепты, спавн ×1,0 (не замедляется) | ADR-0004 ✅ |
| TR-guest-015 | Guest AI — единственный владелец паузы игрового времени | ADR-0003 ✅ |
| TR-guest-017 | Валидация констант при загрузке | ADR-0004 ✅ |
| TR-guest-018 | Повторная валидация выходов DifficultyCurve при спавне с откатом к базовым значениям | ADR-0004 ✅ |
| TR-guest-019 | `match_started` ровно один раз; дубликаты `request_new_match` игнорируются | ADR-0003 ✅ |
| TR-guest-020 | RNG уровня рецепта `U[0,1)`, детерминирован через `FakeRng` | ADR-0004 ✅ |
| TR-guest-021 | Свободный слот с наименьшим стабильным ID | ADR-0003 ✅ |
| TR-guest-022 | Guest AI ≤ 0,5 мс в среднем / ≤ 1,0 мс p99 на кадр | ADR-0007 ✅ |
| TR-guest-023 | Гость на `AnimatedSprite3D` в 4 направлениях; именованные ассеты | ADR-0002 ✅ |
| TR-guest-024 | Кольцо терпения: billboard, 3 уровня (0,60 / 0,25), снимается мгновенно | ADR-0002 ✅ |

## Port Source (vertical slice)

Логика уже проверена в `prototypes/tea-rush-vertical-slice/`. Истории переносят её в `src/`, а не пишут заново:
- `prototypes/tea-rush-vertical-slice/src/feature/guest_sim.gd`
- `prototypes/tea-rush-vertical-slice/src/feature/match_lifecycle.gd`
- `prototypes/tea-rush-vertical-slice/src/foundation/config/guest_config.gd`

## Stories

| # | Story | Type | Status | ADR | Estimate |
|---|-------|------|--------|-----|----------|
| 001 | GuestConfig: ресурс и валидация при загрузке | Logic | Ready | ADR-0004 | S |
| 002 | MatchLifecycle: состояния BOOTING/IDLE/RUNNING/ENDED и команды | Logic | Ready | ADR-0003 | M |
| 003 | Пауза игрового времени: hidden + user pause, max_step_delta | Logic | Ready | ADR-0003 | M |
| 004 | GuestSim: слоты, интервал спавна, отложенный спавн | Logic | Ready | ADR-0003 | M |
| 005 | Терпение, уход по таймауту и порядок тика | Logic | Ready | ADR-0003 | M |
| 006 | Подача: matches → consume_held_cup → Served | Logic | Ready | ADR-0003 | M |
| 007 | Назначение recipe_id, онбординг 15 с, RNG | Logic | Ready | ADR-0004 | M |
| 008 | Подход гостя к слоту по Navigator, нет пути → Waiting | Integration | Ready | ADR-0006 | M |
| 009 | Интеграция: партия от старта до match_ended с реальными подсистемами | Integration | Ready | ADR-0003 | L |
| 010 | GuestView: AnimatedSprite3D, 4 направления, якорь кольца терпения | Visual/Feel | Ready | ADR-0002 | L |
| 011 | Бюджет Guest AI ≤ 0,5 мс avg / 1,0 мс p99 | Integration | Ready | ADR-0007 | S |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/guest-ai-patience.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories guest-sim` to break this epic into implementable stories.
