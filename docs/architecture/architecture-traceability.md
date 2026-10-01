# Architecture Traceability Index
Last Updated: 2026-10-01
Engine: Godot 4.7.2

## Coverage Summary
- Total requirements: 222 in `tr-registry.yaml` (+3 TR-art-009…011 on 2026-10-01, diorama camera amendments of ADR-0002/0006/0007; TR-layout-011, -016, TR-art-001, -002, -007, -008 reworded); before that 219 (+13 TR-audio on 2026-10-01, audio GDD + ADR-0001/0007 audio amendments); before that 206 (+8 TR-art on 2026-10-01, art bible + ADR-0002/0007 amendments); previously 198 (164 at the 2026-09-30 review + TR-hud-023…029 added the same day + 27 TR-flow on 2026-10-01); matrix rows for TR-hud-023…029 were missing and are added below
- 2026-10-01: TR-flow-001…027 (`design/ux/game-flow.md`) covered by the 2026-10-01 amendments of ADR-0001/0003/0004/0005/0006 — amendments authored autonomously, pending owner review; 26 🟡, 1 routed (TR-flow-006, `tr()` convention)
- Covered by Accepted ADR: 0
- Covered by Proposed ADR (🟡): 145 (91% of active) — all seven ADRs Accepted 2026-09-30; counts are as of the review
- Partial: 11
- Routed to UX spec: 3
- Gaps: 0

## Full Matrix
| TR-ID | Система | Требование | ADR | Статус |
|---|---|---|---|---|
| TR-platform-001 | Platform | Одна HTML5/WebGL2-сборка, один URL (браузер ПК и телефона) | ADR-0001 | 🟡 |
| TR-platform-002 | Platform | Детект контекста: `window.Telegram.WebApp` + успешный `ready()` → TMA, иначе Standalone | — | ⏸ Отложено (Telegram) |
| TR-platform-003 | Platform | SDK есть, но init упал или вышел по таймауту → тихо как Standalone, без UI ошибки | — | ⏸ Отложено (Telegram) |
| TR-platform-004 | Platform | Scope TG SDK: safe-area инсеты + опционально тема; без платежей | — | ⏸ Отложено (Telegram) |
| TR-platform-005 | Platform | Safe area = `innerWidth/Height` на resize/orientationchange *(TMA-ветка отложена)* | ADR-0001 | 🟡 |
| TR-platform-006 | Platform | Экран загрузки с прогрессом до готовности кухни, без жёсткого таймаута | ADR-0001 | 🟡 |
| TR-platform-007 | Platform | Stretch mode/aspect задаются явно, не дефолт 4.7 | ADR-0002 | 🟡 |
| TR-platform-008 | Platform | Clamp `safe_aspect` в [0,45; 1,0], letterbox, playfield по центру safe area | ADR-0002 | 🟡 |
| TR-platform-009 | Platform | `safe_h = max(1, …)` против деления на ноль | ADR-0002 | 🟡 |
| TR-platform-010 | Platform | Пересчёт safe area не чаще 1 раза за кадр | ADR-0001, ADR-0002 | 🟡 |
| TR-platform-011 | Platform | Нет WebGL2 → статичный экран «обновите браузер», движок не грузится | ADR-0001 | 🟡 |
| TR-platform-012 | Platform | Один visibility-сигнал (Page Visibility API) | ADR-0001 | 🟡 |
| TR-platform-013 | Platform | Состояние `Ready` запускает первый матч | ADR-0001 | 🟡 |
| TR-platform-014 | Platform | TG `initData`/user ID опциональны, их отсутствие ничего не блокирует | — | ⏸ Отложено (Telegram) |
| TR-platform-015 | Platform | Флаг контекста доступен для будущей монетизации | — | ⏸ Отложено (Telegram) |
| TR-platform-016 | Platform | `viewport_aspect_min`/`max` — данные из реестра | ADR-0004, ADR-0002 | 🟡 |
| TR-platform-017 | Platform | Resize посреди партии не сбрасывает состояние матча | ADR-0001, ADR-0002 | 🟡 |
| TR-platform-018 | Platform | Переход Loading→Ready без белой вспышки | ADR-0001 | 🟡 |
| TR-layout-001 | Kitchen Layout | Фиксированная кухня ~8×11 м, одна раскладка в MVP | ADR-0004 | 🟡 |
| TR-layout-002 | Kitchen Layout | Станции по периметру с промежутками, остров 2×4 м делит кухню на два прохода | — | ⚠️ данные KitchenConfig (0004) + владение в architecture.md; ADR не называет |
| TR-layout-003 | Kitchen Layout | 7 слотов: 5 на острове + по 1 у боковых стен | — | ⚠️ то же — 7 слотов как данные KitchenConfig |
| TR-layout-004 | Kitchen Layout | Сплошная низкая столешница; станции — блоки; слоты — площадки | — | ⚠️ 0002 §4 рисует кухню спрайтами; сама форма столешницы — дизайн данных |
| TR-layout-005 | Kitchen Layout | Till-anchor — фиксированная мировая точка, не станция и не слот | — | ⚠️ 0006 проверяет till-anchor в verify(); отдельного решения нет |
| TR-layout-006 | Kitchen Layout | Занятость слотов принадлежит Brewing; layout только объявляет слоты | — | ⚠️ владение слотами — architecture.md (Brewing); ни один ADR не фиксирует |
| TR-layout-007 | Kitchen Layout | Bake NavMesh без ошибок и предупреждений | ADR-0006 | 🟡 |
| TR-layout-008 | Kitchen Layout | Путь из till-anchor до каждого слота и станции существует, изолированных карманов нет | ADR-0006 | 🟡 |
| TR-layout-009 | Kitchen Layout | `station_types` точно совпадает с расставленными станциями | ADR-0004 | 🟡 |
| TR-layout-010 | Kitchen Layout | Кухня заполняет ≥ 0,95 playfield при любом `safe_aspect` ∈ [0,45; 1,0], равномерный масш… | ADR-0002 | 🟡 |
| TR-layout-011 | Kitchen Layout | Камера фиксирована — перспективная диорама (FOV 30°, pitch 52°); от `safe_aspect` пересчитываются дистанция и h/v_offset (rev. 2026-10-01) | ADR-0002 (поправка 2026-10-01 diorama) | 🟡 |
| TR-layout-012 | Kitchen Layout | Зазор у точек взаимодействия ≥ `agent_radius` = 0,40 м | ADR-0006 | 🟡 |
| TR-layout-013 | Kitchen Layout | Формы станций и столешницы не пересекаются | ADR-0006, ADR-0004 | 🟡 |
| TR-layout-014 | Kitchen Layout | Минимальная зона тапа 48×48 dp на эталоне 360×640 dp | ADR-0002, ADR-0006 | 🟡 |
| TR-layout-015 | Kitchen Layout | `playfield_min_fill` = 0,95, `min_tap_target` = 48 dp — данные из реестра | ADR-0004 | 🟡 |
| TR-layout-016 | Kitchen Layout | Статика кухни — рисованные текстуры-атласы × запечённый свет/AO; без шейдерных анимаций внутри `frame_bounds`; 1 DirectionalLight3D (rev. 2026-10-01) | ADR-0002 (поправки 2026-10-01) | 🟡 |
| TR-layout-017 | Kitchen Layout | Для гостей: 1 точка спавна, 4 точки очереди со стабильными ID, 1 выход — все на навигаци… | ADR-0006 | 🟡 |
| TR-control-001 | Player Control | Выбор тапа: ближайшая точка в `tap_pick_radius` → иначе луч/проверка точки → иначе no-op | ADR-0006 | 🟡 |
| TR-control-002 | Player Control | Тап вне навигационной области → ближайшая достижимая точка XZ | ADR-0006 | 🟡 |
| TR-control-003 | Player Control | Очереди тапов нет: последний тап сразу заменяет цель в любом состоянии | ADR-0003 | 🟡 |
| TR-control-004 | Player Control | Запрос валидности у владельца цели до выхода; пол всегда валиден | ADR-0003 | 🟡 |
| TR-control-005 | Player Control | Станция с несколькими точками подхода: кратчайший путь, при равенстве — меньший ID | ADR-0006 | 🟡 |
| TR-control-006 | Player Control | `effective_speed = 4,0 м/с × speed_multiplier` {1,0; 1,15; 1,3; 1,5} | ADR-0004 | 🟡 |
| TR-control-007 | Player Control | Путь держит `body_clearance = agent_radius`, спрямляется по прямой видимости | ADR-0006 | 🟡 |
| TR-control-008 | Player Control | `agent_radius = work_gap 0,45 − clearance_margin 0,05 = 0,40 м` | ADR-0006, ADR-0004 | 🟡 |
| TR-control-009 | Player Control | Holding: предложение действия раз за тик; EXECUTE→Idle / WAIT→Holding / REFUSE→Idle | ADR-0003 | 🟡 |
| TR-control-010 | Player Control | Цель «пол» никогда не переводит в Holding | ADR-0003 | 🟡 |
| TR-control-011 | Player Control | `tap_pick_radius` = 28 dp, пересчёт в px при смене масштаба | ADR-0002, ADR-0006 | 🟡 |
| TR-control-012 | Player Control | `t_step` = 2,0 с — авторитетное значение для Order & Recipe | ADR-0004 | 🟡 |
| TR-control-013 | Player Control | Состояния Idle/Walking/Holding с заданными переходами | ADR-0003 | 🟡 |
| TR-control-014 | Player Control | `AnimatedSprite3D`, ходьба в 4 направлениях, без бленда | ADR-0002 | 🟡 |
| TR-control-015 | Player Control | Задержка ≤ 50 мс (3 кадра) на маркер, старт, перенаправление, отказ — внутри движка | ADR-0007 | 🟡 |
| TR-control-016 | Player Control | Пауза только через игровое время Guest AI, не через visibility-сигнал | ADR-0003 | 🟡 |
| TR-control-017 | Player Control | Шаг кадра `speed × dt` может пройти несколько точек пути без проскока | ADR-0006, ADR-0003 | 🟡 |
| TR-control-018 | Player Control | Тапом считается только press; последний press за кадр побеждает | ADR-0006 | 🟡 |
| TR-control-019 | Player Control | Конец матча: ввод отклоняется, путь сбрасывается, бариста стоит на месте | ADR-0003 | 🟡 |
| TR-recipe-001 | Order & Recipe | Рецепт `{recipe_id, steps, tier}`; ровно 5 рецептов MVP | ADR-0004 | 🟡 |
| TR-recipe-002 | Order & Recipe | `recipe_price` — поиск по таблице, не вычисление | ADR-0004 | 🟡 |
| TR-recipe-003 | Order & Recipe | Цены: cold_tea 2, black_tea 5, green_tea 5, *_lemon 7 | ADR-0004 | 🟡 |
| TR-recipe-004 | Order & Recipe | Инварианты цен в целых числах, проверка при загрузке | ADR-0004 | 🟡 |
| TR-recipe-005 | Order & Recipe | Первый шаг — `cup`, последний — `serve` (ровно один) | ADR-0004 | 🟡 |
| TR-recipe-006 | Order & Recipe | Каждый шаг, кроме `serve`, есть в `station_types` | ADR-0004 | 🟡 |
| TR-recipe-007 | Order & Recipe | Нет двух рецептов с одинаковой последовательностью (префикс допустим) | ADR-0004 | 🟡 |
| TR-recipe-008 | Order & Recipe | В каждом уровне ≥ 1 рецепт | ADR-0004 | 🟡 |
| TR-recipe-009 | Order & Recipe | `is_valid_next`; чёрный лист → water_100, зелёный лист → water_80 | ADR-0004 | 🟡 |
| TR-recipe-010 | Order & Recipe | `matches(steps)` сравнивает без `serve` | ADR-0004 | 🟡 |
| TR-recipe-011 | Order & Recipe | `recipes_by_tier` разбивает 5 рецептов без пересечений | ADR-0004 | 🟡 |
| TR-recipe-012 | Order & Recipe | Карта цветов шагов (7 записей) | — | ⚠️ architecture.md отдаёт ADR-0002, но ни 0002, ни 0004 его не перечисляют |
| TR-recipe-013 | Order & Recipe | Цена — целое ≥ 1, иначе ошибка загрузки | ADR-0004 | 🟡 |
| TR-recipe-014 | Order & Recipe | Балансовая формула `coins_per_sec` — без runtime-кода | ADR-0004 | 🟡 |
| TR-brewing-001 | Brewing | Чашка `{steps, ruined}`; `held_cup` — максимум одна | ADR-0003 | 🟡 |
| TR-brewing-002 | Brewing | 2 независимых чайника: EMPTY → BREWING → READY → EMPTY | ADR-0003 | 🟡 |
| TR-brewing-003 | Brewing | `t_brew = 3,0 / speed_multiplier` | ADR-0004 | 🟡 |
| TR-brewing-004 | Brewing | Мгновенные станции: выполнить или отказать в том же тике | ADR-0003 | 🟡 |
| TR-brewing-005 | Brewing | Таблица ответов чайника: 12 комбинаций | ADR-0003 | 🟡 |
| TR-brewing-006 | Brewing | WRONG_TEMP на пустом чайнике → `ruined = true`, чайник остаётся пустым | ADR-0003 | 🟡 |
| TR-brewing-007 | Brewing | 7 слотов EMPTY/HOLDING, безусловный обмен | ADR-0003 | 🟡 |
| TR-brewing-008 | Brewing | `consume_held_cup()` — ровно один раз на подачу | ADR-0003 | 🟡 |
| TR-brewing-009 | Brewing | Таймер чайника идёт в фоне каждый кадр симуляции | ADR-0003 | 🟡 |
| TR-brewing-010 | Brewing | Таймеры на игровом времени с clamp `max_step_delta` = 0,25 с | ADR-0003 | 🟡 |
| TR-brewing-011 | Brewing | `match_started` сбрасывает чайники, слоты и `held_cup` | ADR-0003 | 🟡 |
| TR-brewing-012 | Brewing | Повторное добавление воды = OTHER (отказ), а не WRONG_TEMP | ADR-0003 | 🟡 |
| TR-brewing-013 | Brewing | `speed_multiplier` — данные; в MVP 1,0 | ADR-0004 | 🟡 |
| TR-guest-001 | Guest AI | Машина состояний гостя Approaching → Waiting → {Served \| Leaving} → удалён | ADR-0003 | 🟡 |
| TR-guest-002 | Guest AI | `guest_slot_count` = 4 со стабильными ID; невалидное значение — ошибка загрузки | ADR-0004 | 🟡 |
| TR-guest-003 | Guest AI | `spawn_interval = 60 / (gpm(t) × onboarding_multiplier)`; фиксируется при спавне | ADR-0004 | 🟡 |
| TR-guest-004 | Guest AI | Отложенный спавн при занятых слотах; в очереди максимум один | ADR-0003 | 🟡 |
| TR-guest-005 | Guest AI | Терпение тикает с момента спавна | ADR-0003 | 🟡 |
| TR-guest-006 | Guest AI | Путь к слоту на 3,0 м/с; нет пути → сразу Waiting + лог | ADR-0006 | 🟡 |
| TR-guest-007 | Guest AI | Точка взаимодействия — всегда слот гостя | ADR-0003 | 🟡 |
| TR-guest-008 | Guest AI | Подача: `matches()` → `consume_held_cup()` один раз → Served в том же тике | ADR-0003 | 🟡 |
| TR-guest-009 | Guest AI | `remaining_fraction = clamp(1 − t/patience_max_g, 0, 1)`; `patience_max_g` фиксируется п… | ADR-0003 | 🟡 |
| TR-guest-010 | Guest AI | Слот освобождается при переходе в Served/Leaving | ADR-0003 | 🟡 |
| TR-guest-011 | Guest AI | Порядок тика: подачи → таймауты → конец → спавн; подача побеждает таймаут | ADR-0003 | 🟡 |
| TR-guest-012 | Guest AI | Player Control обновляется раньше Guest AI в том же кадре | ADR-0003 | 🟡 |
| TR-guest-013 | Guest AI | `guests_lost == 3` → заморозка, `match_ended` ровно один раз | ADR-0003 | 🟡 |
| TR-guest-014 | Guest AI | Онбординг 15 с: только простые рецепты, спавн ×1,0 (не замедляется) | ADR-0004 | 🟡 |
| TR-guest-015 | Guest AI | Guest AI — единственный владелец паузы игрового времени | ADR-0003 | 🟡 |
| TR-guest-016 | Guest AI | `max_step_delta` = 0,25 с | ADR-0003 | 🟡 |
| TR-guest-017 | Guest AI | Валидация констант при загрузке | ADR-0004 | 🟡 |
| TR-guest-018 | Guest AI | Повторная валидация выходов DifficultyCurve при спавне с откатом к базовым значениям | ADR-0004 | 🟡 |
| TR-guest-019 | Guest AI | `match_started` ровно один раз; дубликаты `request_new_match` игнорируются | ADR-0003 | 🟡 |
| TR-guest-020 | Guest AI | RNG уровня рецепта `U[0,1)`, детерминирован через `FakeRng` | ADR-0004 | 🟡 |
| TR-guest-021 | Guest AI | Свободный слот с наименьшим стабильным ID | ADR-0003 | 🟡 |
| TR-guest-022 | Guest AI | Guest AI ≤ 0,5 мс в среднем / ≤ 1,0 мс p99 на кадр | ADR-0007 | 🟡 |
| TR-guest-023 | Guest AI | Гость на `AnimatedSprite3D` в 4 направлениях; именованные ассеты | ADR-0002 | 🟡 |
| TR-guest-024 | Guest AI | Кольцо терпения: billboard, 3 уровня (0,60 / 0,25), снимается мгновенно | ADR-0002 | 🟡 |
| TR-pacing-001 | Difficulty | `progress = clamp(t/180, 0, 1)^2,0` | ADR-0004 | 🟡 |
| TR-pacing-002 | Difficulty | Три кривые (гостей/мин 15→18, терпение 50→25, доля сложных 0→0,40) | ADR-0004 | 🟡 |
| TR-pacing-003 | Difficulty | Чистые функции от `t` (без учёта паузы), одинаковые для всех игроков | ADR-0003 | 🟡 |
| TR-pacing-004 | Difficulty | Без состояния; `t` передаётся аргументом | ADR-0003 | 🟡 |
| TR-pacing-005 | Difficulty | Онбординг применяет Guest AI, а не кривые | ADR-0004 | 🟡 |
| TR-pacing-006 | Difficulty | При `t ≥ ramp_duration` — плато на `_end` | ADR-0003 | 🟡 |
| TR-pacing-007 | Difficulty | Касса — не вход для кривых | ADR-0003 | 🟡 |
| TR-pacing-008 | Difficulty | Валидация при загрузке (диапазоны, NaN, `_end` не легче `_start`) | ADR-0004 | 🟡 |
| TR-pacing-009 | Difficulty | Детерминизм: побитово равные результаты | ADR-0004 | 🟡 |
| TR-pacing-010 | Difficulty | `t` сбрасывается по `match_started` | ADR-0003 | 🟡 |
| TR-pacing-011 | Difficulty | `guests_per_minute_start` = 15,0 синхронизирован с Guest AI | ADR-0004 | 🟡 |
| TR-currency-001 | Currency | `coins_earned = recipe_price` | ADR-0003 | 🟡 |
| TR-currency-002 | Currency | `score_earned = round_half_up(price × 10 × (1 + rf))` | ADR-0003 | 🟡 |
| TR-currency-003 | Currency | `score_multiplier_base` = 10 — данные | ADR-0004 | 🟡 |
| TR-currency-004 | Currency | `match_score`: Idle → Accumulating → Frozen | ADR-0003 | 🟡 |
| TR-currency-005 | Currency | `match_score = 0` на `match_started` | ADR-0003 | 🟡 |
| TR-currency-006 | Currency | `best_score` сохраняется локально и никогда не уменьшается | ADR-0005 | 🟡 |
| TR-currency-007 | Currency | `is_new_record` вычисляется на `match_ended` до обновления `best_score` | ADR-0003 | 🟡 |
| TR-currency-008 | Currency | `is_new_record = false` на `match_started` | ADR-0003 | 🟡 |
| TR-currency-009 | Currency | `best_score := match_score` только при `is_new_record` | ADR-0005, ADR-0003 | 🟡 |
| TR-currency-010 | Currency | Монеты и очки не зависят от состояния кассы | ADR-0003 | 🟡 |
| TR-currency-011 | Currency | Нет трат монет и конвертации монеты↔очки | ADR-0003 | 🟡 |
| TR-currency-012 | Currency | Единственный триггер — `served(recipe_id, rf)` | ADR-0003 | 🟡 |
| TR-currency-013 | Currency | Несколько подач в одном тике — порядок не важен | ADR-0003 | 🟡 |
| TR-till-001 | Till | `till_amount` ∈ [0, 250], `till_capacity` = 250, Open/Full, `full_since_utc` | ADR-0004 | 🟡 |
| TR-till-002 | Till | `coins_added = min(amount + coins, cap) − amount`, эмитится всегда (включая 0) | ADR-0003 | 🟡 |
| TR-till-003 | Till | Open→Full в том же тике, когда касса заполнилась | ADR-0003 | 🟡 |
| TR-till-004 | Till | Full не блокирует матчи | ADR-0003 | 🟡 |
| TR-till-005 | Till | При переходе в Full сохраняется `full_since_utc` | ADR-0005 | 🟡 |
| TR-till-006 | Till | `daily_reset_time_utc` = 00:00 UTC | ADR-0004 | 🟡 |
| TR-till-007 | Till | Проверка сброса только на `match_started` и холодном старте | ADR-0003 | 🟡 |
| TR-till-008 | Till | Сброс: amount = 0, `full_since_utc` очищается | ADR-0003 | 🟡 |
| TR-till-009 | Till | `till_amount` переживает перезапуск | ADR-0005 | 🟡 |
| TR-till-010 | Till | Незаполненная касса не сбрасывается | ADR-0003 | 🟡 |
| TR-till-011 | Till | Несколько пропущенных полуночей → ровно один сброс | ADR-0005 | 🟡 |
| TR-till-012 | Till | Подкрутка часов устройства — принятый риск MVP | ADR-0001, ADR-0005 (принятый риск) | 🟡 |
| TR-till-013 | Till | Till не трогает score | ADR-0003 | 🟡 |
| TR-hud-001 | HUD | Экранные полосы: счёт, 3 страйка, всплывающие числа, оверлей итогов; мир в полосы не зах… | ADR-0002 | 🟡 |
| TR-hud-002 | HUD | Мировые оверлеи: касса, чайники, кольцо и жетон гостя, жетоны чашки, метки станций, конт… | ADR-0002 | 🟡 |
| TR-hud-003 | HUD | HUD ничего не хранит и не кэширует, значения читаются каждый кадр | ADR-0003 | 🟡 |
| TR-hud-004 | HUD | Состояния Inactive → Active → MatchEnd → Active | ADR-0003 | 🟡 |
| TR-hud-005 | HUD | Жетон и кольцо появляются уже в состоянии Approaching | — | ⚠️ 0002 §5 даёт оверлеи, но показ жетона уже в Approaching не назван |
| TR-hud-006 | HUD | Тапы по полосам не уходят в кухню; при открытом оверлее тапы получает только оверлей | ADR-0006 | 🟡 |
| TR-hud-007 | HUD | «Играть снова» принимает тапы после fade ~250 мс + grace 500 мс | ADR-0006, ADR-0003 | 🟡 |
| TR-hud-008 | HUD | Анимации HUD паузятся через игровое время | ADR-0003 | 🟡 |
| TR-hud-009 | HUD | `till_fill_ratio = amount / capacity` каждый кадр | ADR-0004 | 🟡 |
| TR-hud-010 | HUD | Open→Full — только акцент на кассе, без чисел в полосе | — | ⚠️ architecture.md отдаёт ADR-0002, ADR его не перечисляет (визуальный акцент) |
| TR-hud-011 | HUD | Испорченная чашка отличается силуэтом, не только цветом | — | ⚠️ architecture.md отдаёт ADR-0002; силуэт — задача арта/UX |
| TR-hud-012 | HUD | При 9:20 постоянные элементы — счёт и страйки; страйки не скрываются | ADR-0002 | 🟡 |
| TR-hud-013 | HUD | Жетоны в Approaching рисуются с масштабом и прозрачностью 0,7; Waiting — поверх | ADR-0002 | 🟡 |
| TR-hud-014 | HUD | Два ухода в одном кадре — пульсы со сдвигом 100 мс | — (/ux-design) | ➡️ UX-спека |
| TR-hud-015 | HUD | Всплывающие числа с полным значением сразу, дуга ~400 мс; overflow — отскок без числа | — | ⚠️ 0003 §6 (дуга на sim_dt) + 0002 §6 (offset-transform); тайминги — UX |
| TR-hud-016 | HUD | `is_new_record` читается готовым флагом из Currency | ADR-0003 | 🟡 |
| TR-hud-017 | HUD | Разделение snap и smooth для анимаций | — | ⚠️ 0002 (resize — snap) + 0003 (игровое время); общего правила нет |
| TR-hud-018 | HUD | Отдельный звук на каждое событие | — (/ux-design) | ➡️ UX-спека |
| TR-hud-019 | HUD | Константы тюнинга HUD — данные | ADR-0004 | 🟡 |
| TR-hud-020 | HUD | Чужие константы только читаются | ADR-0004 | 🟡 |
| TR-hud-021 | HUD | Контур цели и кольцо на полу меняются в том же кадре, что и цель Player Control | ADR-0003 | 🟡 |
| TR-hud-022 | HUD | Опция reduced-motion для пульса колец (решается в `/ux-design`) | — (/ux-design) | ➡️ UX-спека |
| TR-hud-023 | HUD | Кнопка паузы: пауза = hidden ИЛИ пауза игрока; только в Active; возврат вкладки не снимает | ADR-0003, ADR-0006 | 🟡 |
| TR-hud-024 | HUD | Кнопка звука: mute = шина Master; `settings.muted` в SaveStore | ADR-0001, ADR-0005 | 🟡 |
| TR-hud-025 | HUD | ~~Один зацикленный трек~~ — заменено TR-hud-027 | — | ↪ superseded |
| TR-hud-026 | HUD | ~~Бюджет музыки ≤ 1,0 МБ в `.pck`~~ — заменено TR-hud-028 | — | ↪ superseded |
| TR-hud-027 | HUD | Музыка: старт после жеста и загрузки; пауза с позиции; low-pass на итогах; «Играть снова» — с начала | ADR-0001, ADR-0003, ADR-0004 | 🟡 |
| TR-hud-028 | HUD | Бюджет музыки: ≤ 2,7 МБ вне `.pck`, Stream | ADR-0007 | 🟡 |
| TR-hud-029 | HUD | HUD — всегда верхняя строка; Mode A / Mode C (резерв 56 dp на аспектах ≈ 0,8–1,0) | ADR-0002, ADR-0004 | 🟡 |
| TR-flow-001 | Game Flow | Главное меню (Play / Records / Settings / How to Play) вместо стартового экрана E18; `re… | ADR-0001, ADR-0003 | 🟡 |
| TR-flow-002 | Game Flow | Из меню до партии — 1 тап, если `tutorial.seen` | ADR-0003 | 🟡 |
| TR-flow-003 | Game Flow | How to Play: 3 карточки автоматически перед первой сменой, дальше из меню; `tutorial.see… | ADR-0005 | 🟡 |
| TR-flow-004 | Game Flow | Settings: Music / Sound effects / Vibration, применяются сразу, сохраняются; доступны из… | ADR-0001, ADR-0003, ADR-0005 | 🟡 |
| TR-flow-005 | Game Flow | Строки Vibration нет, если `navigator.vibrate` не поддерживается | ADR-0001 | 🟡 |
| TR-flow-006 | Game Flow | Весь текст игры — только английский, строки через `tr()`-ключи; выбора языка нет (F3) | — | ➡️ UX-спека / конвенция кода (`tr()`), ADR не нужен |
| TR-flow-007 | Game Flow | Records: рекорд, до 5 последних смен, счётчики, серия; пустое состояние (F5) | ADR-0005 | 🟡 |
| TR-flow-008 | Game Flow | Пауза: Resume / Settings / Main Menu; Main Menu → подтверждение; выход = `match_ended(qu… | ADR-0003 | 🟡 |
| TR-flow-009 | Game Flow | Строка статуса в меню: Till A / C и Best; при Full — время до нового дня | ADR-0005 | 🟡 |
| TR-flow-010 | Game Flow | Кнопки меню срабатывают по release; Escape = назад; кнопка «назад» браузера не перехваты… | ADR-0006 | 🟡 |
| TR-flow-011 | Game Flow | Меню показывает «Progress can't be saved», если `SaveStore.persistent = false` | ADR-0005 | 🟡 |
| TR-flow-012 | Game Flow | Итоги (M1): порядок строк, накрутка счёта ≤ 0,8 с с пропуском по тапу, «N to beat», Play… | ADR-0003, ADR-0004, ADR-0006 | 🟡 |
| TR-flow-013 | Game Flow | Плашка «Till full!» (M2): 2 с, звон, вибрация, не останавливает партию и не ловит тапы (… | ADR-0003, ADR-0004, ADR-0006 | 🟡 |
| TR-flow-014 | Game Flow | Тач-устройство в ландшафте → оверлей «Rotate your phone» + пользовательская пауза; обрат… | ADR-0001, ADR-0003 | 🟡 |
| TR-flow-015 | Game Flow | Адресная строка не обрабатывается; «кухня ≥ 95 %» — от видимого вьюпорта (F7) | ADR-0002 | 🟡 |
| TR-flow-016 | Game Flow | Экран загрузки: логотип, прогресс, одна случайная подсказка (в HTML-оболочке) | ADR-0001 | 🟡 |
| TR-flow-017 | Game Flow | About: версия сборки, авторы, лицензии (включая Godot MIT) | ADR-0004 | 🟡 |
| TR-flow-018 | Game Flow | PWA: установка, строка Install app, одноразовая подсказка после 3-й смены, инструкция на… | ADR-0001 | 🟡 |
| TR-flow-019 | Game Flow | Шаринг: PNG-карточка 1080×1350, рендер на `match_ended`, Web Share с файлом; фолбэк — ск… | ADR-0001, ADR-0004 | 🟡 |
| TR-flow-020 | Game Flow | Wake lock только во время идущей партии | ADR-0001, ADR-0003 | 🟡 |
| TR-flow-021 | Game Flow | Send feedback открывает `feedback_url` в новой вкладке; пустой конфиг — строки нет (M10) | ADR-0001, ADR-0004 | 🟡 |
| TR-flow-022 | Game Flow | NEW BEST! в партии: один раз, только при рекорде на старте > 0, по `Currency.record_pass… | ADR-0003 | 🟡 |
| TR-flow-023 | Game Flow | Последний страйк: виньетка + сердцебиение при `guests_lost == max − 1`, замирают на пауз… | ADR-0003, ADR-0004, ADR-0006 | 🟡 |
| TR-flow-024 | Game Flow | Вызов `?beat=N`: валидация, сохранение, удаление параметра из адреса, строка в меню, ито… | ADR-0001, ADR-0005 | 🟡 |
| TR-flow-025 | Game Flow | Серия дней: `day_index` по `daily_reset_time_utc`, рост на Open→Full, сгоревшая серия по… | ADR-0005 | 🟡 |
| TR-flow-026 | Game Flow | Reduced motion: все переходы потока мгновенные | ADR-0001 | 🟡 |
| TR-flow-027 | Game Flow | Новые ключи SaveStore аддитивны, `schema_version` = 1; `stats.recent` — валидируемая JSO… | ADR-0005 | 🟡 |
| TR-art-001 | Art Direction | 3D-окружение с рисованными атласами × vertex-color свет/AO (unshaded); кухня ≤ 5 мешей, декорации ≤ 6 (rev. 2026-10-01) | ADR-0002, ADR-0007 (поправки 2026-10-01) | 🟡 |
| TR-art-002 | Art Direction | Один DirectionalLight3D, тени от прокси динамики; runtime DOF запрещён, tilt-shift — запечённый / High после S5 (rev. 2026-10-01) | ADR-0002, ADR-0007 (поправки 2026-10-01) | 🟡 |
| TR-art-003 | Art Direction | Спрайты персонажей и предметов — кастомный toon spatial-шейдер (unshaded база × тонировк… | ADR-0002 (поправка 2026-10-01) | 🟡 |
| TR-art-004 | Art Direction | Мировые оверлеи (жетоны, кольца, цены, контур цели, кольцо назначения) исключены из тума… | ADR-0002 (поправка 2026-10-01) | 🟡 |
| TR-art-005 | Art Direction | Blob-тени под персонажами, чашками и кассой на всех тирах; реальные тени Mid/High поверх… | ADR-0002 (поправка 2026-10-01) | 🟡 |
| TR-art-006 | Art Direction | Уровни качества Low/Mid/High выбираются статически при загрузке + ручной переключатель; … | ADR-0007 (поправка 2026-10-01) | 🟡 |
| TR-art-007 | Art Direction | Бюджеты: `.pck` ≤ 22,0 МБ, загрузка ≤ 32,5 МБ, текстуры ≤ 192/144 МБ, census ≤ 115, draw calls 140/200 (rev. 2026-10-01) | ADR-0007 (таблица текущих бюджетов) | 🟡 |
| TR-art-008 | Art Direction | Pre-warm: toon, shadow-caster, текстурный env, декорации, VFX, fog; ≤ 1,0 с (rev. 2026-10-01) | ADR-0007 (поправка 2026-10-01 diorama) | 🟡 |
| TR-art-009 | Art Direction | Перспективная камера-диорама, stretch `1/cos α` на спрайт, минимальный экранный размер оверлеев в дальней точке | ADR-0002 (поправка 2026-10-01 diorama), ADR-0006 | 🟡 |
| TR-art-010 | Art Direction | VFX-пуфы: пул ≤ 12, ниже полос оверлеев — не перекрывают жетоны | ADR-0007 (поправка 2026-10-01 diorama) | 🟡 |
| TR-art-011 | Art Direction | Декорации вокруг кухни в letterbox, вне `frame_bounds`, только Mid/High | ADR-0002, ADR-0007 (поправки 2026-10-01 diorama) | 🟡 |
| TR-audio-001 | Audio & Juice | Музыка партии — 4 stems (120 BPM, F major, 96,0 с) в одном AudioStreamSynchronized, Stre… | ADR-0001, ADR-0007 (поправка 2026-10-01) | 🟡 |
| TR-audio-002 | Audio & Juice | Переход слоя квантуется к ближайшему такту и нарастает stem_fade_bars (2) такта; огибающ… | ADR-0001, ADR-0003 (поправка 2026-10-01) | 🟡 |
| TR-audio-003 | Audio & Juice | Отдельный трек меню (Stream), с начала на каждый заход, fade-in 1 с; меню→партия 0,6 с, … | ADR-0001 (поправка 2026-10-01) | 🟡 |
| TR-audio-004 | Audio & Juice | Последний страйк: S4 гаснет, LP на Music 2500 Гц за 0,4 с, −3 dB, сердцебиение 1 Гц на S… | ADR-0001, ADR-0003 (поправка 2026-10-01) | 🟡 |
| TR-audio-005 | Audio & Juice | Шины Master ← Music; Master ← SFX ← {Voice, UI, Stinger, Amb}; mute: muted → Master, mus… | ADR-0001, ADR-0005 (поправка 2026-10-01) | 🟡 |
| TR-audio-006 | Audio & Juice | SFX/голоса/стингеры/фон — Sample (QOA), вариации и pitch выбираются в коде (без Randomiz… | ADR-0001 (поправка 2026-10-01) | 🟡 |
| TR-audio-007 | Audio & Juice | Награды разделены: монеты — аккорд только по цене (2 → F, 5 → F+A, 7 → F–A–C); очки — ст… | — (GDD-only) | 🟡 |
| TR-audio-008 | Audio & Juice | Лимитер голосов F4: ≤ 2 реплики, зазор 0,25 с, кулдаун гостя 2,5 с, p(order) падает с оч… | ADR-0003 (поправка 2026-10-01) | 🟡 |
| TR-audio-009 | Audio & Juice | Дакинг музыки под стингер — скриптом по громкости шины Music (−6 dB, атака 0,05, спад 0,… | ADR-0001 (поправка 2026-10-01) | 🟡 |
| TR-audio-010 | Audio & Juice | Полифония ≤ 16 одноразовых звуков, классы P0–P4 с потолками; вытеснение F6 (P0/P1 не выт… | ADR-0007 (поправка 2026-10-01) | 🟡 |
| TR-audio-011 | Audio & Juice | Пауза/скрытая вкладка: stream_paused для музыки, фона, сердцебиения и звуков в полёте в … | ADR-0003 (поправка 2026-10-01) | 🟡 |
| TR-audio-012 | Audio & Juice | Вибрация по карте событий audio GDD §C: haptics.vibration_on + navigator.vibrate, интерв… | ADR-0001, ADR-0005 (поправка 2026-10-01) | 🟡 |
| TR-audio-013 | Audio & Juice | Бюджеты: музыка ≤ 6,0 МБ набором файлов после загрузки; .pck ≤ 11,0 МБ; CPU музыки ≤ 2,5… | ADR-0007 (поправка 2026-10-01) | 🟡 |

## Known Gaps
None. Partial items and UX-routed items: see `architecture-review-2026-09-30.md`.

## Superseded Requirements
Reworded 2026-10-01 (diorama camera, same IDs): TR-layout-011 (ortho → perspective), TR-layout-016 and TR-art-001 (textured environment), TR-art-002, -007, -008 (budgets). Reworded 2026-09-30 after ADR-0006 GDD sync (same intent, IDs unchanged): TR-control-001 (pick anchors, physics-free picking), TR-control-007 and TR-layout-012 (clearance tolerance −0.05 m), TR-layout-013 (footprints instead of collision shapes). Deferred with Telegram: TR-platform-002, -003, -004, -014, -015.
