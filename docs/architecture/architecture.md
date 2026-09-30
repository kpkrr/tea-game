# Tea Rush — Master Architecture

## Document Status

- Version: 1.0
- Last Updated: 2026-10-01 (game-flow: модули GameFlow, PlayerStats, Haptics; поправки ADR-0001/0003/0004/0005/0006 от 2026-10-01 — автономно, ждут ревью владельца)
- Engine: Godot 4.7.2 (GDScript, Compatibility renderer / WebGL2, web export)
- Platform scope: **только обычный web** (браузер ПК и телефона). Telegram Mini App
  отложен решением 2026-09-30 — в MVP не детектится и не реализуется
- Workflow tier: `standard` — карта слоёв + владение модулями + список критичных ADR
- GDDs Covered: platform-integration-telegram-mini-app, kitchen-station-layout,
  order-recipe-system, player-control-barista-movement, brewing-crafting-mechanic,
  guest-ai-patience, difficulty-curve-session-pacing, currency-coins-score,
  till-day-cycle, hud-feedback-ui (10/10 MVP); UX-спек потока экранов `design/ux/game-flow.md` (TR-flow)
- ADRs Referenced: ADR-0001 (Web build & platform shell, Accepted), ADR-0002 (Viewport, camera fit & 2.5D presentation, Accepted), ADR-0003 (Match simulation: clock, tick order, pause & events, Accepted), ADR-0004 (Data config & load-time validation, Accepted), ADR-0005 (Local persistence — SaveStore, Accepted), ADR-0006 (Navigation & tap picking, Accepted), ADR-0007 (Performance & load budgets, Accepted)
- Technical Director Sign-Off: 2026-09-30 — APPROVED WITH CONDITIONS (код не
  начинать, пока ADR-0001…0005 не Accepted; ADR-0001 начинается с модуля
  `engine-reference/godot/modules/web.md` и spike на реальном телефоне)
- Lead Programmer Feasibility: — (skipped, review_mode `lean`)

---

## Engine Knowledge Gap Summary

Модель знает Godot примерно до 4.6; 4.7 — после отсечки. Всё, что ниже помечено
⚠️, проверяется по `docs/engine-reference/godot/` или на реальном билде до того,
как ADR получит статус Accepted.

| Домен | Риск | Что важно для Tea Rush |
|---|---|---|
| **Web export** | ⚠️ HIGH | В `engine-reference` **нет модуля web-экспорта**. Потоки vs single-thread (SharedArrayBuffer и COOP/COEP-заголовки хостинга), `JavaScriptBridge`, синхронизация `user://` с IndexedDB, поведение в мобильных браузерах (Chrome Android, Safari iOS) — не проверены для 4.7. Первым делом — добавить модуль `modules/web.md` и сделать spike (ADR-0001). |
| Rendering | ⚠️ HIGH | Compatibility = WebGL2. В 4.7 дефолт stretch сменился на `canvas_items`/`expand` — задаём явно (TR-platform-007). Линии `CanvasItem` в 4.7 тоньше (нет AA-feather) — касается колец терпения, если рисовать их 2D-линиями. |
| Input | ⚠️ HIGH | Именованные `InputEvent.DEVICE_ID_MOUSE/KEYBOARD` (4.7); dual-focus (4.6) — касается кнопки «Играть снова» при мыши и тапе. |
| GUI | ⚠️ HIGH | `Control` offset-transform независим от layout (4.7) — использовать для анимаций оверлея итогов и всплывающих чисел. |
| Navigation | MEDIUM | Решено ADR-0006 и проверено пробой на 4.7.2: прямые запросы `NavigationServer3D` на собственной карте, NavMesh запекается на старте из данных; `NavigationAgent3D` не используется. Карта не готова сразу после создания — нужен `map_force_update` и опрос готовности; `agent_radius` округляется вверх до целого числа ячеек (`modules/navigation.md`). |
| Physics (Jolt) | MEDIUM → не используется | Архитектура не опирается на 3D-физику (см. принцип 6). Критические изменения Jolt в 4.7 (WorldBoundary, SoftBody) проект не затрагивают. |
| Animation / Audio | LOW | `AnimatedSprite3D`, `Sprite3D`, `AudioStreamPlayer` — стабильны. |

---

## System Layer Map

```
┌────────────────────────────────────────────────────────────────────────────┐
│ PRESENTATION  HUD (экранные полосы + мировые оверлеи) · ResultsOverlay      │
│               · [Audio & Juice Feedback — Vertical Slice]                   │
├────────────────────────────────────────────────────────────────────────────┤
│ FEATURE       GuestSim + MatchLifecycle (Guest AI & Patience)               │
│               · Brewing (чайники, слоты, held_cup)                          │
│               · DifficultyCurve (чистые функции от t)                       │
│               · Currency (match_score, best_score, is_new_record)           │
│               · Till (касса, день Open/Full, UTC-сброс)                     │
├────────────────────────────────────────────────────────────────────────────┤
│ CORE          RecipeBook (Order & Recipe, stateless)                        │
│               · BaristaController (Player Control) · TapPicker · Pathing    │
├────────────────────────────────────────────────────────────────────────────┤
│ FOUNDATION    PlatformBridge · ViewFit · GameClock · MatchDirector          │
│               · ConfigLoader · SaveStore · KitchenLayout (статика + NavMesh)│
├────────────────────────────────────────────────────────────────────────────┤
│ PLATFORM      Godot web export (WebGL2, single-thread) · HTML-оболочка      │
│               · Page Visibility API · localStorage [Telegram SDK — отложен] │
└────────────────────────────────────────────────────────────────────────────┘
```

**Почему так.** Слой определяется тем, *кто от кого зависит*, а не тем, насколько
система «игровая». `KitchenLayout` — Foundation, потому что от него зависят почти
все gameplay-системы, а сам он — статические данные и NavMesh. `GameClock` и
`MatchDirector` вынесены из Guest AI в Foundation как *механизм*, хотя *политику*
(когда пауза, когда матч стартует) по GDD по-прежнему решает Guest AI
(Rule 11/13) — это сохраняет владение из дизайна и делает часы тестируемыми
отдельно. `RecipeBook` — Core: он без состояния, но на его грамматику опираются
Brewing, Guest AI и Currency. Currency и Till — Feature, а не Foundation:
персистентность у них своя, но хранилище (`SaveStore`) — общий Foundation-сервис.

Системы Vertical Slice и дальше (Backend & Persistence, Leaderboard, Audio,
Progression, Monetization, Co-op, Token) в этот документ **не входят**. Для них
заложены два шва: интерфейс `SaveStore` (под бэкенд) и `PlatformBridge` —
единственное место, куда позже добавится Telegram Mini App (детект, инсеты,
`viewportChanged`, `user_id`). Остальные модули о контексте запуска не знают:
они получают только safe-area rect и сигнал видимости.

---

## Module Ownership

| Модуль | Слой | Владеет | Отдаёт наружу | Потребляет | Engine API |
|---|---|---|---|---|---|
| **PlatformBridge** (autoload) | Foundation | safe-area rect (= вьюпорт браузера в px окна, `DisplayServer.window_get_size()`), видимость (`is_visible()`), состояние `Loading/Ready/Failed` | `safe_area_changed(rect)`, `visibility_changed(visible)`, `ready_reached`; поправка 2026-10-01: `orientation_blocked_changed`, `install_availability_changed`, `share_finished`, PWA/share/wake lock/launch param/`open_external`/vibrate (ADR-0001) | браузер: resize/orientationchange, Page Visibility API, `pointer: coarse`, `beforeinstallprompt`, Web Share, Wake Lock, `location.search` | ⚠️ `JavaScriptBridge` (visibility + хелпер оболочки `teaRushPlatform`), `get_viewport().size_changed`, PWA-опции экспорта (⚠️ проверить в 4.7.2) |
| **ViewFit** | Foundation | `safe_aspect`, playfield rect, letterbox, размер и смещение ortho-камеры, `kitchen_rect` (ADR-0002; 1 единица канваса = 1 dp; поправка 2026-09-30: HUD — всегда верхняя строка; если верхняя полоса < `hud_min_strip_dp` = 56 dp (аспекты ≈ 0,8–1,0), она резервируется, кухня < 95 % поля — исключение; боковые полосы — только letterbox) | `playfield_changed(playfield, kitchen_rect)` | `PlatformBridge.safe_area_changed`, габариты кухни | ⚠️ stretch mode, `Camera3D` (ortho `size`) |
| **GameClock** | Foundation | игровое время `t`, флаги `hidden` и `frozen`, clamp `max_step_delta` (ADR-0003) | `t`, `sim_dt`, `ui_dt`, `running_changed(running)` | команды pause/resume/freeze/reset от MatchLifecycle | — (чистый GDScript) |
| **MatchDirector** | Foundation | порядок тика, корень композиции матча (DI) | — | все модули матча | `_process` с `process_priority = -100` (ADR-0003; не `_physics_process`) |
| **ConfigLoader** | Foundation | загруженные и провалидированные данные тюнинга (ADR-0004: `GameConfig` + подресурсы на систему, `.tres` в `assets/data/config/`, `ConfigValidator` собирает все ошибки во всех сборках) | типизированные `Resource`-конфиги, инъекция через конструкторы | файлы данных | `ResourceLoader`, `Resource` |
| **SaveStore** | Foundation | формат и версия сохранения (JSON-блоб, `schema_version`), backend по платформе (ADR-0005) | `scope(owner) -> SaveScope` (`read_int/write_int`, …), `flush_if_dirty()` | — | web: `localStorage` через хелпер оболочки + `JavaScriptBridge.get_interface`; desktop: `user://` + атомарная замена; `user://` на web не используется |
| **KitchenLayout** | Foundation | станции, 7 слотов, 4 слота гостей, spawn/exit, till-anchor, `station_types`, footprints (данные для NavMesh и выбора тапа), pick-якоря, точки взаимодействия со стабильными ID `(owner_id, index)` (ADR-0006) | позиции + стабильные ID, `station_types`, footprints | `KitchenConfig` | `Sprite3D` (коллизий и `NavigationRegion3D` нет) |
| **RecipeBook** | Core | 5 рецептов, прайс, грамматика шагов, цвета шагов | `is_valid_next`, `matches`, `recipe_price`, `recipes_by_tier` | `station_types`, конфиг | — |
| **TapPicker** | Core | правило выбора цели тапа (ADR-0006): reject вне `kitchen_rect` → близость к pick-якорю ≤ 28 dp → ray-vs-AABB → плоскость пола | `tapped(target: TapTarget)`, `on_press(pos)`, `flush(running)` | ввод (в dp, ADR-0002), KitchenLayout, `GuestTargets` | `Camera3D` через `TapProjector`, `AABB.intersects_ray`, `Plane.intersects_ray`; физики нет |
| **BaristaController** | Core | состояние `Idle/Walking/Holding`, путь, текущая цель | `state`, `target`, `offer_action()` | `tapped`, Pathing, валидность от Brewing/Guest | `AnimatedSprite3D` |
| **Pathing** | Core | приватная карта навигации + регион, `agent_radius` (одно значение, из `ControlConfig`), готовность карты (ADR-0006) | `Navigator.path(from, to) -> PathResult`, `shortest_to(from, points)`, `poll_ready()`, `verify(kitchen)`, `dispose()` | footprints KitchenLayout, `ControlConfig.agent_radius` | `NavigationServer3D` (карта/регион/`map_get_path`, `bake_from_source_geometry_data`); запасной вариант — `GridNavigator` (`AStarGrid2D`) за тем же интерфейсом |
| **Brewing** | Feature | `held_cup`, 2 чайника (`EMPTY/BREWING/READY`), 7 слотов | ответы `EXECUTE/WAIT/REFUSE`, `consume_held_cup()`, состояния для HUD | RecipeBook, `step(dt)` от MatchDirector, `match_started` | — |
| **MatchLifecycle** (Guest AI) | Feature | `match_started`/`match_ended`, `guests_lost`, политика паузы; состояния `BOOTING/IDLE/RUNNING/ENDED` (IDLE — меню, поправка 2026-10-01) | `match_started`, `match_ended(reason)` (`guests_lost` \| `quit`), `paused_changed`, команды GameClock | `ready_reached` (→ IDLE, без автостарта), `visibility_changed`, `orientation_blocked_changed`, `request_new_match`, `request_quit_match`, `request_pause`/`request_resume` | — |
| **GuestSim** (Guest AI) | Feature | гости (4 слота), терпение, спавн, RNG выбора рецепта | `served(recipe_id, remaining_fraction)`, `target_vanished`, данные гостей для HUD | DifficultyCurve, RecipeBook, Brewing, Pathing (`Navigator`) | `AnimatedSprite3D` (без `NavigationAgent3D`, ADR-0006) |
| **DifficultyCurve** | Feature | ничего (без состояния) | `guests_per_minute(t)`, `patience_max(t)`, `complex_order_share(t)` | конфиг | — |
| **Currency** | Feature | `match_score`, `best_score`, `is_new_record`, `best_score_at_match_start` | `coins_earned(n)`, `score_earned(n)`, `record_passed()` (раз за партию, при рекорде на старте > 0; поправка 2026-10-01), геттеры | `served`, `match_started`, `match_ended`, SaveStore | — |
| **Till** | Feature | `till_amount`, `Open/Full`, `full_since_utc` | `coins_added(n)`, `day_filled()` (Open→Full, поправка 2026-10-01), `day_state`, `till_fill_ratio` | `coins_earned`, `match_started`, `UtcClock`, SaveStore | — |
| **AudioDirector** | Presentation | шины Master → Music, SFX; mute (шина Master); low-pass на шине Music (итоги, нарастание по `ui_dt`); музыкальный плеер; загрузка трека после `ready_reached`; ключи `settings.muted`, `settings.music_on`, `settings.sfx_on` (поправки ADR-0001/0005); слой «сердцебиение» на последнем страйке (поправка 2026-10-01) | `is_muted()`, `set_music_on()`, `set_sfx_on()` | `set_muted()` от HUD, `MatchLifecycle.paused_changed`/`match_started`/`match_ended`, `GameClock.ui_dt`, `cfg.audio`, первый жест игрока, `SaveScope` `settings`, URL от `PlatformBridge.asset_url()` через `_compose()` | `AudioServer.set_bus_mute`, `AudioEffectLowPassFilter`, `AudioStreamPlayer` (SFX: Sample; музыка: Stream), `AudioStreamOggVorbis.load_from_buffer`, `HTTPRequest` |
| **HUD** | Presentation | ничего игрового (правило «без кэша») | `request_new_match`, `request_pause`/`request_resume`, `set_muted` | всё перечисленное выше, только чтение; поправка 2026-10-01: `record_passed`, `day_filled`, `guests_lost` (плашка «касса полна», NEW BEST!, виньетка последнего страйка — не блокируют тапы, ADR-0006) | `Control`, `Sprite3D`/`Label3D`, `Tween` |
| **GameFlow** *(поправка 2026-10-01, `design/ux/game-flow.md`)* | Presentation | экраны вне партии и навигация: Main Menu, How to Play, Records, Settings, About, подтверждение «End shift?», итоги (M1), оверлей «Rotate your phone», подсказка установки; ключи `tutorial.seen`, `ui.install_hint_shown`, `challenge.target`; строки только английские через `tr()` | `request_new_match`, `request_quit_match`, `request_resume`; сеттеры настроек AudioDirector/Haptics; команды PlatformBridge через `_compose()` (share, install, open_external) | `ready_reached`, `match_ended(reason)`, Currency/Till/PlayerStats геттеры, `FlowConfig`, `SaveScope` `tutorial`/`ui`/`challenge`, `PlatformBridge` (через инъекцию из `_compose()`) | `Control`, `Tween` (только вне партии, ADR-0003 поправка), `SubViewport` → `Image.save_png_to_buffer` (карточка шаринга) |
| **PlayerStats** *(поправка 2026-10-01)* | Feature (Meta) | счётчики смен и чашек, `recent` (≤ 5), серия дней (`streak`, `best_streak`, `streak_last_day`), `days_filled` | геттеры для Records, меню и итогов; `streak_grew_this_match` для строки на итогах | `served`, `match_ended(*)`, `Till.day_filled`, `UtcClock`, `TillConfig.daily_reset_time_utc`, `FlowConfig`, `SaveScope` `stats` | — (чистый GDScript, `RefCounted`) |
| **Haptics** *(поправка 2026-10-01)* | Presentation | `haptics.vibration_on` | `set_enabled()`, `is_supported()` | `day_filled`, `record_passed`, `SaveScope` `haptics`, `HudConfig` (длительности) | `PlatformBridge.vibrate()` через инъекцию |

```
            PlatformBridge ──► ViewFit ──► TapPicker ──► BaristaController ──► Pathing
                 │                                              │                 │
   visibility/ready                                   validity/offer             NavMesh
                 ▼                                              ▼                 │
          MatchLifecycle ──► GameClock ◄── MatchDirector ──► Brewing ◄── RecipeBook ◄── KitchenLayout
                 │                              │               ▲             ▲
          match_started/ended                   ▼               │             │
                 └──────────────────────► GuestSim ─────────────┘─────────────┘
                                             │ served(recipe_id, remaining_fraction)
                                             ▼
                               Currency ──coins_earned──► Till ──coins_added──► HUD
                                  │  ▲                     │  ▲
                                  └──┴──── SaveStore ──────┘  └── UtcClock
```

---

## Data Flow

### 1. Тик симуляции (каждый `_process`, ADR-0003)

`MatchDirector` — единственное место, где задан порядок. Узлы систем свой
`_process` для симуляции **не используют**.

```
MatchDirector._process(delta):          # process_priority = -100 — раньше всех узлов отображения
  MatchLifecycle.apply_pending()        # 0: отложенный старт → GameClock.reset(), match_started
  dt = GameClock.advance(delta)         # 1: 0 если hidden/frozen или первый кадр после resume, иначе min(delta, 0.25)
  TapPicker.flush(dt > 0)               # 2: последний press за кадр → tapped(target); без хода — сбрасывается
  if dt > 0:
    BaristaController.step(dt)          # 3: движение; в Holding → offer_action() владельцу
    Brewing.step(dt)                    # 4: таймеры чайников
    GuestSim.step(dt)                   # 5: (a) подачи → (b) таймауты → (c) проверка конца → (d) спавн
  SaveStore.flush_if_dirty()            # 6: одна запись за кадр, если что-то менялось (ADR-0005)
HUD._process(_delta):                   # priority 0 — только чтение, после симуляции
```

Порядок «Player Control → Guest AI» и «подача раньше таймаута» — требования
TR-guest-011/012. Всё выполняется синхронно в главном потоке; потоков нет.

### 2. Цепочка `Served` (синхронные типизированные сигналы, один тик)

```
GuestSim ─served(recipe_id, rf)─► Currency: coins = recipe_price; score = round(price×10×(1+rf))
                                   ├─coins_earned(coins)─► Till: added = min(amount+coins, cap) − amount
                                   │                               └─coins_added(added)─► HUD (число/отскок)
                                   └─score_earned(score)─► HUD (всплывающее число)
```

Порядок подписчиков не важен: суммы коммутативны (TR-currency-013). HUD ничего не
кэширует и значения со всплывающими числами берёт из payload сигнала.

### 3. Жизненный цикл матча и пауза

```
PlatformBridge.ready_reached (конфиг валиден + Pathing готов + самопроверка достижимости точек, ADR-0006) ─► MatchLifecycle.start()
HUD «Играть снова» (после grace 500 мс) ─request_new_match() (метод, ставит старт в очередь)─► MatchLifecycle
MatchLifecycle.apply_pending() (шаг 0 тика): GameClock.reset(); emit match_started
    → Brewing сбрасывает всё, Currency: match_score=0, Till: проверка UTC-сброса,
      GuestSim: чистит гостей и сразу спавнит первого
GuestSim: guests_lost == 3 ─► MatchLifecycle: GameClock.freeze(); emit match_ended
    → Currency: is_new_record = match_score > best_score; при true сохраняет best_score
PlatformBridge.visibility_changed(false/true) ─► MatchLifecycle ─► GameClock.pause()/resume() (resume отбрасывает первый кадр)
PlatformBridge.ready_reached ─► MatchLifecycle: BOOTING → IDLE (без автостарта); GameFlow показывает Main Menu; Play / Start shift ─request_new_match()─►  (поправка 2026-10-01)
GameFlow «End shift» ─request_quit_match()─► MatchLifecycle (шаг 0): freeze; emit match_ended(&"quit") → IDLE; GameFlow пропускает итоги → меню  (поправка 2026-10-01)
PlatformBridge.orientation_blocked_changed(true) ─► MatchLifecycle.request_pause() (обратный поворот паузу не снимает)  (поправка 2026-10-01)
HUD пауза / «Продолжить» ─request_pause()/request_resume()─► MatchLifecycle: пауза = hidden ИЛИ user_paused ─► GameClock.pause()/resume(); paused_changed ─► AudioDirector (музыка)  (поправка ADR-0003, 2026-09-30)
match_ended ─► AudioDirector: low-pass на шине Music (нарастание по ui_dt); match_started ─► фильтр снят, трек с начала  (поправка ADR-0001/0003, 2026-09-30)
```

Единственный источник паузы — `GameClock`. Анимации HUD, привязанные к игровому
времени (пульс колец, всплывающие числа), берут `sim_dt` из него, а не из
`get_process_delta_time()` (TR-hud-008); оверлей итогов (fade, grace) — `ui_dt`,
который идёт при `frozen`, но стоит при `hidden`. Спрайты паузятся по
`running_changed` (ADR-0003).

### 4. Сохранение и загрузка

| Ключ | Владелец | Когда пишется | Когда читается |
|---|---|---|---|
| `best_score` | Currency | на `match_ended`, только если `is_new_record` | холодный старт |
| `till_amount`, `day_state`, `full_since_utc` | Till | при каждом изменении (Served, Open↔Full) | холодный старт, `match_started` (проверка сброса) |
| ~~`settings.language`~~ | — | — | снято 2026-10-01: весь текст игры только на английском (game-flow F3), выбора языка нет |
| `settings.music_on`, `settings.sfx_on` | AudioDirector | переключатели Settings | холодный старт (ADR-0005, поправка 2026-10-01) |
| `haptics.vibration_on` | Haptics | переключатель Settings | холодный старт (ADR-0005, поправка 2026-10-01; в UX-спеке назван `settings.vibration_on`) |
| `tutorial.seen`, `ui.install_hint_shown`, `challenge.target` | GameFlow | конец How to Play / показ подсказки / `?beat=` и выполнение вызова | холодный старт |
| `stats.*` (`shifts_played`, `cups_served`, `days_filled`, `streak`, `best_streak`, `streak_last_day`, `recent` — JSON-строка) | PlayerStats | `match_ended(*)`, `Till.day_filled` | холодный старт |
| `settings.muted` (bool, по умолчанию `false`) | AudioDirector | при переключении кнопки звука в HUD | холодный старт, до первого звука (ADR-0005, поправка 2026-09-30) |

`SaveStore` — одна плоская схема с `schema_version` (ADR-0005). На web — `localStorage`
(синхронная запись), а не `user://`/IndexedDB; сброс на диск — шаг 6 тика и синхронно при
уходе страницы в фон; владельцы пишут только через свой `SaveScope`. Исходный вопрос про
IndexedDB: момент синхронизации и поведение при очистке хранилища WebView
проверяются в ADR-0005. `match_score` не сохраняется: если приложение упадёт
посреди партии, её результат теряется (TR-currency-006).

### 5. Порядок инициализации

```
1. HTML-оболочка: проверка WebGL2 → иначе статичный экран «обновите браузер» (движок не грузится)
2. PlatformBridge (autoload): первая safe area (= вьюпорт), подписка на resize и visibility
3. ConfigLoader: загрузка и валидация всех данных → ошибка = `PlatformBridge.fail_boot()`, статичный экран «обновите страницу» во всех сборках, полный список ошибок в debug (ADR-0004)
4. SaveStore: чтение блоба (при повреждении или его отсутствии — дефолты по ключам, игра не блокируется; ADR-0005)
5. Kitchen-сцена: KitchenLayout, ViewFit (камера), MatchDirector собирает граф модулей (DI); Pathing запекает NavMesh и опрашивается каждый кадр `Booting`, пока карта не готова (обычно 1 кадр), затем `verify()` — путь от spawn до каждой точки взаимодействия, иначе `fail_boot` (ADR-0006)
6. Till: проверка UTC-сброса на холодном старте
7. PlatformBridge.ready_reached → экран загрузки уходит без белой вспышки → MatchLifecycle.start()
```

---

## API Boundaries

Сигнатуры — контракты между модулями; ADR уточняют детали. Всё типизировано и
по наименованию следует `project.yaml` (сигналы — в прошедшем времени).

```gdscript
# Foundation
class_name GameClock extends RefCounted
signal running_changed(running: bool)
func advance(real_delta: float) -> float     # возвращает dt ≤ max_step_delta, 0 на паузе/заморозке (ADR-0003)
func pause() -> void; func resume() -> void; func freeze() -> void; func reset() -> void
var t: float; var sim_dt: float; var ui_dt: float   # только чтение

class_name SaveStore extends RefCounted       # ADR-0005; backend: WebStorage | File | Memory
func scope(owner: StringName) -> SaveScope    # read_int/write_int/read_string/write_string, только свой префикс
func flush_if_dirty() -> void                 # только MatchDirector (шаг 6) и уход в фон

class_name UtcClock extends RefCounted        # инъецируется в Till; FakeUtcClock в тестах
func now_unix() -> int

# Core
class_name RecipeBook extends RefCounted
func is_valid_next(steps: Array[StringName], step: StringName) -> bool
func matches(steps: Array[StringName]) -> StringName   # &"" = нет совпадения
func recipe_price(recipe_id: StringName) -> int

enum ActionReply { EXECUTE, WAIT, REFUSE }    # общий контракт Holding (TR-control-009)

# Feature
signal served(recipe_id: StringName, remaining_fraction: float)   # GuestSim
signal match_started(); signal match_ended()                        # MatchLifecycle
signal coins_earned(amount: int); signal score_earned(amount: int)  # Currency
signal coins_added(amount: int)                                     # Till (включая 0)
func request_new_match() -> void    # MatchLifecycle; вызывает HUD (команда, не сигнал — ADR-0003)
func request_pause() -> void; func request_resume() -> void   # MatchLifecycle; вызывает HUD (поправка ADR-0003, 2026-09-30)
signal paused_changed(paused: bool)                                 # MatchLifecycle: hidden ИЛИ user_paused
func set_muted(muted: bool) -> void                                 # AudioDirector; вызывает HUD (поправка ADR-0001)
# поправка 2026-10-01 (game-flow)
signal match_ended(reason: StringName)                              # заменяет match_ended(): &"lost" | &"quit"
func request_quit_match() -> void                                   # MatchLifecycle; вызывает только GameFlow
signal record_passed()                                              # Currency, раз за партию
signal day_filled()                                                 # Till, переход Open → Full
signal guests_lost_changed(count: int)                              # GuestSim
func set_music_on(on: bool) -> void; func set_sfx_on(on: bool) -> void   # AudioDirector; вызывает GameFlow (Settings)
func set_enabled(on: bool) -> void                                  # Haptics; вызывает GameFlow (Settings)
```

**Инварианты для вызывающих:**
- `consume_held_cup()` вызывается ровно один раз на успешную подачу и только
  из GuestSim (TR-brewing-008).
- Значения из DifficultyCurve фиксируются в госте при спавне и больше не
  пересчитываются (TR-guest-009, TR-pacing-004).
- HUD не пишет ни в одну систему, кроме `request_new_match`, `request_pause`/`request_resume` и `AudioDirector.set_muted` (поправки 2026-09-30).
- GameFlow пишет только `request_new_match`, `request_quit_match`, `request_resume`, сеттеры настроек AudioDirector/Haptics и свои ключи SaveStore (поправка 2026-10-01).
- PlayerStats читает и Currency, и Till — это мета-слой, граница Pillar 4 (Till ↔ Currency) не нарушается.
- Till не читает score, Currency не читает состояние кассы (граница Pillar 4).

**Типы движка в интерфейсах:** в сигнатурах выше только `StringName`, `Array[T]`,
`PackedVector3Array` и `RefCounted`. Все они стабильны в 4.x. Узлы (`Node3D`)
через границы модулей не передаются: только ID и позиции.

---

## ADR Audit

Написаны ADR-0001…0007; все Accepted 2026-09-30. По `/architecture-review` 2026-09-30:
145 из 159 активных требований закрыты ADR (на момент ревью Proposed, с 2026-09-30 Accepted), 11 частично, 3 уходят в
UX-спеку, 5 отложены вместе с Telegram, пробелов нет. Постоянные ID —
`tr-registry.yaml`, полная матрица — `architecture-traceability.md`. Таблица
ниже — исходное распределение.

| Группа TR | Всего | Закроет |
|---|---|---|
| TR-platform-001…018 | 18 (5 отложены) | ADR-0001 (001, 005 — только браузер, 006, 011–013, 017, 018), ADR-0002 (007–010), ADR-0004 (016); **отложены с Telegram: 002, 003, 004, 014, 015** |
| TR-layout-001…017 | 17 | ADR-0002 (010, 011, 014, 016), ADR-0004 (001, 009, 015), ADR-0006 (007, 008, 012, 013, 017), остальное — дизайн данных KitchenLayout |
| TR-control-001…019 | 19 | ADR-0006 (001, 002, 005, 007, 008, 011, 017, 018), ADR-0003 (003, 004, 009, 010, 013, 016, 019), ADR-0004 (006, 012), ADR-0002 (014), ADR-0007 (015) |
| TR-recipe-001…014 | 14 | ADR-0004 (все, кроме 012), ADR-0002 (012) |
| TR-brewing-001…013 | 13 | ADR-0003 (001, 002, 004–012), ADR-0004 (003, 013) |
| TR-guest-001…024 | 24 | ADR-0003 (001, 004, 005, 007–013, 015, 016, 019, 021), ADR-0004 (002, 003, 014, 017, 018, 020), ADR-0006 (006), ADR-0002 (023, 024), ADR-0007 (022) |
| TR-pacing-001…011 | 11 | ADR-0004 (001, 002, 005, 008, 009, 011), ADR-0003 (003, 004, 006, 007, 010) |
| TR-currency-001…013 | 13 | ADR-0003 (001, 002, 004, 005, 007–013), ADR-0004 (003), ADR-0005 (006, 009) |
| TR-till-001…013 | 13 | ADR-0003 (002–004, 007, 008, 010, 013), ADR-0005 (005, 009, 011), ADR-0004 (001, 006), ADR-0001 (012 — принятый риск) |
| TR-hud-001…022 | 22 | ADR-0002 (001, 002, 010–013, 017), ADR-0003 (003, 004, 008, 016, 021), ADR-0006 (006, 007), ADR-0004 (009, 019, 020), UX-спека (014, 015, 018, 022) |

Полный текст требований — в приложении A. `/architecture-review` перенесёт их в
`tr-registry.yaml` с постоянными ID.

---

## Required ADRs

### Must have before coding starts (Foundation)

| # | `/architecture-decision` | Решает | Пробелы в знаниях |
|---|---|---|---|
| **ADR-0001** | **Web build & platform shell** | Single-thread-экспорт против threads (COOP/COEP-заголовки хостинга), профиль шаблона экспорта и размер, HTML-оболочка + проверка WebGL2 + экран загрузки, resize/orientationchange с debounce, единый `visibility_changed` через Page Visibility API, `ready_reached` без белой вспышки, хостинг. **Spike на реальном слабом Android в мобильном браузере — часть этого ADR.** Telegram не входит. | ⚠️ HIGH — сначала добавить `docs/engine-reference/godot/modules/web.md` |
| **ADR-0002** | **Viewport, camera fit & 2.5D presentation** | Явный stretch mode/aspect, ortho-камера и формула её `size` от `safe_aspect` (заполнение ≥ 0,95), letterbox, масштаб dp→px, мировые оверлеи (`Sprite3D`/`Label3D` против проекции в `Control`), billboard-персонажи, бюджет draw calls. | ⚠️ HIGH (дефолты stretch в 4.7, Compatibility) |
| **ADR-0003** | **Match simulation: game clock, tick order, pause & event wiring** | `GameClock` + `MatchDirector`, фиксированный порядок тика, отказ от `SceneTree.paused`, типизированные сигналы без глобального event bus, корень композиции и DI, сброс по `match_started`. | LOW (чистый GDScript) |
| **ADR-0004** | **Data config & load-time validation** | Формат данных (`Resource .tres` против JSON), единый валидатор, поведение инвариантов в release-сборке (recipe OQ), реализация кривых сложности (`Curve` против формулы), потоки RNG и инъекция `RandomNumberGenerator` (guest OQ9). | LOW |
| **ADR-0005** | **Local persistence (SaveStore)** | Интерфейс `SaveStore`, формат, `schema_version`, момент `flush()`, `user://` → IndexedDB на web, очистка хранилища WebView, шов под Backend & Persistence. Закрывает `currency-coins-score.md:483`. | ⚠️ HIGH (синхронизация IDBFS в 4.7) |

### Should have before the relevant system is built (Core)

| # | `/architecture-decision` | Решает |
|---|---|---|
| **ADR-0006** | **Navigation & tap picking** | ✅ Accepted: NavMesh из данных + прямые запросы `NavigationServer3D` (без `NavigationAgent3D`), один `agent_radius` из конфига, без RVO, выбор тапа без физики, ID `(owner_id, index)`. Запасной вариант — `GridNavigator` за тем же интерфейсом. |

### Before Vertical Slice

| # | `/architecture-decision` | Решает |
|---|---|---|
| **ADR-0007** | **Performance & load budgets** | ✅ Accepted: эталонное слабое Android-устройство как класс, 60 fps цель / 30 fps пол, мс на систему (Guest AI 0,5/1,0), потолки draw calls (100/150) и инстансов (75), текстуры 48 МБ, загрузка ≤ 13,5 МБ (движок 10,2 МБ — замерено; музыка 2,7 МБ вне `.pck`, догружается после `ready_reached` — поправка 2026-09-30), TTI холодный ≤ 20 с / тёплый ≤ 6 с, пре-прогрев материалов при `Booting`, `PerfProbe` + CI-гейты. Числа на устройстве предварительные до spike ADR-0001. |

### Can defer to implementation

- Пул объектов гостей на 4 слота (guest OQ5): решается в истории GuestSim.
- ~~Формат стабильных ID слотов (guest OQ10, control OQ)~~ **Решено ADR-0006:**
  `StringName` `[a-z0-9_]+`, точка взаимодействия = `(owner_id, index)`,
  порядок — `owner_id` по `String <`, затем `index`.
- Владение `till_fill_ratio` в реестре (hud OQ5): только когда появится второй
  потребитель.

---

## Architecture Principles

1. **Один хозяин порядка.** Симуляцию матча тикает только `MatchDirector` в
   явном порядке. Порядок нод в дереве и `_process` отдельных систем на игровую
   логику не влияют.
2. **Одно игровое время.** Всё, что паузится, берёт `dt` из `GameClock`.
   `SceneTree.paused` и сырой `delta` в игровой логике запрещены.
3. **Логика — в `RefCounted`, узлы — только для отображения.** Формулы и машины
   состояний живут в чистых классах с инъецированными часами, RNG, конфигом и
   хранилищем. Это даёт gdUnit4-тесты без сцены (требование `coding-standards`).
4. **Данные, а не литералы.** Каждое число из «Tuning Knobs» и реестра
   приходит из провалидированного конфига. Невалидный конфиг блокирует старт
   матча, а не падает посреди партии.
5. **Веб прежде всего.** Каждое решение проверяется на WebGL2 в мобильном
   браузере на слабом Android. Никакой пост-обработки, потоков и тяжёлых
   шейдеров без измерения на реальном устройстве.
6. **Без 3D-физики.** В кухне нет `CollisionObject3D`, `Area3D`, `RayCast3D`
   и запросов к `PhysicsServer3D`: пути — `NavigationServer3D`, выбор тапа —
   математика над статическими AABB из данных (ADR-0006). На этот принцип
   ссылаются ADR-0003, ADR-0006 и таблица рисков движка выше.

---

## Open Questions

| ID | Вопрос | Приоритет | Где решается |
|---|---|---|---|
| AQ-01 | Single-thread или threads для web-экспорта 4.7 в мобильных браузерах (Chrome Android, Safari iOS), реальный размер сборки и время загрузки? | High | ADR-0001 (spike) |
| AQ-02 | ~~NavMesh или `AStarGrid2D`: воспроизводит ли NavMesh «середину прохода + спрямление» без постобработки?~~ **Решено ADR-0006 (замер на 4.7.2):** да — длина путей 0,958× от прототипа, зазор 0,380 м при `agent_radius` 0,40, все 19 точек на сетке. Остаток — запекание и готовность карты на wasm/слабом Android (spike ADR-0001) | High | ADR-0006 (spike) |
| AQ-03 | ~~Когда `user://` на web реально попадает в IndexedDB, и что будет при очистке данных сайта / приватном режиме?~~ **Решено ADR-0005:** на web `localStorage`, не `user://`; приватный режим → `persistent = false`, игра продолжается; очистка данных → первый запуск. Остаток — проверка на устройстве | High | ADR-0005 (spike) |
| AQ-04 | Задержка «касание → движок» в мобильном браузере не измерена (бюджет ≤ 50 мс только внутри движка). | Medium | ADR-0001 spike → ADR-0007 |
| AQ-05 | Что считается «кадром» для debounce safe area: `_process` или `requestAnimationFrame` (platform OQ5)? | Low | ADR-0001 |
| AQ-06 | Манипуляция системными часами устройства может досрочно сбросить кассу: принятый риск MVP. | Low | Backend & Persistence (VS) |
| AQ-07 | Хватает ли transient user activation для `navigator.share` / `window.open` / `prompt()` из обработчика кнопки Godot (ввод обрабатывается в следующем кадре), особенно в iOS Safari? Запасной вариант — прозрачная HTML-кнопка над канвасом. | High | ADR-0001 поправка 2026-10-01, проверка W1 |
| AQ-08 | Точные ключи PWA-пресета и `JavaScriptBridge.pwa_needs_update()/pwa_update()` в 4.7.2; кэширует ли сгенерированный service worker музыку рядом с `index.html`. | Medium | ADR-0001 поправка 2026-10-01, W2/W3 |
| AQ-09 | Адрес игры (`FlowConfig.game_url`) и `feedback_url` — решение владельца; до него Share и Send feedback скрыты. | Medium | владелец |

---

## Appendix A — Technical Requirements Baseline

Извлечено из 10 GDD, **164 требования**. Это рабочие ID;
`/architecture-review` закрепит их в `tr-registry.yaml`.

### Platform Integration (TR-platform)
| ID | Требование | Домен |
|---|---|---|
| 001 | Одна HTML5/WebGL2-сборка, один URL (браузер ПК и телефона) | Platform-Web |
| 002 | *(отложено 2026-09-30)* Детект контекста: `window.Telegram.WebApp` + успешный `ready()` → TMA, иначе Standalone | Platform-Web |
| 003 | *(отложено 2026-09-30)* SDK есть, но init упал или вышел по таймауту → тихо как Standalone, без UI ошибки | Platform-Web |
| 004 | *(отложено 2026-09-30)* Scope TG SDK: safe-area инсеты + опционально тема; без платежей | Platform-Web |
| 005 | Safe area = `innerWidth/Height` на resize/orientationchange *(TMA-ветка отложена)* | Platform-Web |
| 006 | Экран загрузки с прогрессом до готовности кухни, без жёсткого таймаута | UI |
| 007 | Stretch mode/aspect задаются явно, не дефолт 4.7 | Rendering |
| 008 | Clamp `safe_aspect` в [0,45; 1,0], letterbox, playfield по центру safe area | Rendering |
| 009 | `safe_h = max(1, …)` против деления на ноль | Core |
| 010 | Пересчёт safe area не чаще 1 раза за кадр | Rendering |
| 011 | Нет WebGL2 → статичный экран «обновите браузер», движок не грузится | Platform-Web |
| 012 | Один visibility-сигнал (Page Visibility API) | Platform-Web |
| 013 | Состояние `Ready` запускает первый матч | Platform-Web |
| 014 | *(отложено 2026-09-30)* TG `initData`/user ID опциональны, их отсутствие ничего не блокирует | Save-Load |
| 015 | *(отложено 2026-09-30)* Флаг контекста доступен для будущей монетизации | Data-Config |
| 016 | `viewport_aspect_min`/`max` — данные из реестра | Data-Config |
| 017 | Resize посреди партии не сбрасывает состояние матча | Core |
| 018 | Переход Loading→Ready без белой вспышки | Rendering |

### Kitchen & Station Layout (TR-layout)
| ID | Требование | Домен |
|---|---|---|
| 001 | Фиксированная кухня ~8×11 м, одна раскладка в MVP | Data-Config |
| 002 | Станции по периметру с промежутками, остров 2×4 м делит кухню на два прохода | Core |
| 003 | 7 слотов: 5 на острове + по 1 у боковых стен | Core |
| 004 | Сплошная низкая столешница; станции — блоки; слоты — площадки | Rendering |
| 005 | Till-anchor — фиксированная мировая точка, не станция и не слот | Core |
| 006 | Занятость слотов принадлежит Brewing; layout только объявляет слоты | Data-Config |
| 007 | Bake NavMesh без ошибок и предупреждений | Navigation |
| 008 | Путь из till-anchor до каждого слота и станции существует, изолированных карманов нет | Navigation |
| 009 | `station_types` точно совпадает с расставленными станциями | Data-Config |
| 010 | Кухня заполняет ≥ 0,95 playfield при любом `safe_aspect` ∈ [0,45; 1,0], равномерный масштаб | Rendering |
| 011 | Камера фиксирована, zoom/ortho-size пересчитывается от `safe_aspect` | Rendering |
| 012 | Зазор у точек взаимодействия ≥ `agent_radius` = 0,40 м | Navigation |
| 013 | Формы станций и столешницы не пересекаются | Physics |
| 014 | Минимальная зона тапа 48×48 dp на эталоне 360×640 dp | UI/Input |
| 015 | `playfield_min_fill` = 0,95, `min_tap_target` = 48 dp — данные из реестра | Data-Config |
| 016 | Без шейдерных анимаций и параллакса; запечённый свет; статичное свечение till-anchor | Rendering |
| 017 | Для гостей: 1 точка спавна, 4 точки очереди со стабильными ID, 1 выход — все на навигационной области | Navigation |

### Player Control / Barista Movement (TR-control)
| ID | Требование | Домен |
|---|---|---|
| 001 | Выбор тапа: ближайшая точка в `tap_pick_radius` → иначе луч/проверка точки → иначе no-op | Input |
| 002 | Тап вне навигационной области → ближайшая достижимая точка XZ | Navigation |
| 003 | Очереди тапов нет: последний тап сразу заменяет цель в любом состоянии | Core |
| 004 | Запрос валидности у владельца цели до выхода; пол всегда валиден | Core |
| 005 | Станция с несколькими точками подхода: кратчайший путь, при равенстве — меньший ID | Navigation |
| 006 | `effective_speed = 4,0 м/с × speed_multiplier` {1,0; 1,15; 1,3; 1,5} | Data-Config |
| 007 | Путь держит `body_clearance = agent_radius`, спрямляется по прямой видимости | Navigation |
| 008 | `agent_radius = work_gap 0,45 − clearance_margin 0,05 = 0,40 м` | Data-Config |
| 009 | Holding: предложение действия раз за тик; EXECUTE→Idle / WAIT→Holding / REFUSE→Idle | Core |
| 010 | Цель «пол» никогда не переводит в Holding | Core |
| 011 | `tap_pick_radius` = 28 dp, пересчёт в px при смене масштаба | Input/UI |
| 012 | `t_step` = 2,0 с — авторитетное значение для Order & Recipe | Data-Config |
| 013 | Состояния Idle/Walking/Holding с заданными переходами | Core |
| 014 | `AnimatedSprite3D`, ходьба в 4 направлениях, без бленда | Animation |
| 015 | Задержка ≤ 50 мс (3 кадра) на маркер, старт, перенаправление, отказ — внутри движка | Input/Perf |
| 016 | Пауза только через игровое время Guest AI, не через visibility-сигнал | Core |
| 017 | Шаг кадра `speed × dt` может пройти несколько точек пути без проскока | Core |
| 018 | Тапом считается только press; последний press за кадр побеждает | Input |
| 019 | Конец матча: ввод отклоняется, путь сбрасывается, бариста стоит на месте | Core |

### Order & Recipe System (TR-recipe)
| ID | Требование | Домен |
|---|---|---|
| 001 | Рецепт `{recipe_id, steps, tier}`; ровно 5 рецептов MVP | Data-Config |
| 002 | `recipe_price` — поиск по таблице, не вычисление | Core |
| 003 | Цены: cold_tea 2, black_tea 5, green_tea 5, *_lemon 7 | Data-Config |
| 004 | Инварианты цен в целых числах, проверка при загрузке | Core |
| 005 | Первый шаг — `cup`, последний — `serve` (ровно один) | Core |
| 006 | Каждый шаг, кроме `serve`, есть в `station_types` | Core |
| 007 | Нет двух рецептов с одинаковой последовательностью (префикс допустим) | Core |
| 008 | В каждом уровне ≥ 1 рецепт | Core |
| 009 | `is_valid_next`; чёрный лист → water_100, зелёный лист → water_80 | Core |
| 010 | `matches(steps)` сравнивает без `serve` | Core |
| 011 | `recipes_by_tier` разбивает 5 рецептов без пересечений | Core |
| 012 | Карта цветов шагов (7 записей) | UI |
| 013 | Цена — целое ≥ 1, иначе ошибка загрузки | Core |
| 014 | Балансовая формула `coins_per_sec` — без runtime-кода | Data-Config |

### Brewing & Crafting (TR-brewing)
| ID | Требование | Домен |
|---|---|---|
| 001 | Чашка `{steps, ruined}`; `held_cup` — максимум одна | State |
| 002 | 2 независимых чайника: EMPTY → BREWING → READY → EMPTY | State |
| 003 | `t_brew = 3,0 / speed_multiplier` | Core |
| 004 | Мгновенные станции: выполнить или отказать в том же тике | Core |
| 005 | Таблица ответов чайника: 12 комбинаций | Core |
| 006 | WRONG_TEMP на пустом чайнике → `ruined = true`, чайник остаётся пустым | Core |
| 007 | 7 слотов EMPTY/HOLDING, безусловный обмен | State |
| 008 | `consume_held_cup()` — ровно один раз на подачу | Core |
| 009 | Таймер чайника идёт в фоне каждый кадр симуляции | Time |
| 010 | Таймеры на игровом времени с clamp `max_step_delta` = 0,25 с | Time |
| 011 | `match_started` сбрасывает чайники, слоты и `held_cup` | State |
| 012 | Повторное добавление воды = OTHER (отказ), а не WRONG_TEMP | Core |
| 013 | `speed_multiplier` — данные; в MVP 1,0 | Data-Config |

### Guest AI & Patience (TR-guest)
| ID | Требование | Домен |
|---|---|---|
| 001 | Машина состояний гостя Approaching → Waiting → {Served \| Leaving} → удалён | State |
| 002 | `guest_slot_count` = 4 со стабильными ID; невалидное значение — ошибка загрузки | Data-Config |
| 003 | `spawn_interval = 60 / (gpm(t) × onboarding_multiplier)`; фиксируется при спавне | Time |
| 004 | Отложенный спавн при занятых слотах; в очереди максимум один | State |
| 005 | Терпение тикает с момента спавна | Time |
| 006 | Путь к слоту на 3,0 м/с; нет пути → сразу Waiting + лог | Navigation |
| 007 | Точка взаимодействия — всегда слот гостя | Navigation |
| 008 | Подача: `matches()` → `consume_held_cup()` один раз → Served в том же тике | Core |
| 009 | `remaining_fraction = clamp(1 − t/patience_max_g, 0, 1)`; `patience_max_g` фиксируется при спавне | Core |
| 010 | Слот освобождается при переходе в Served/Leaving | State |
| 011 | Порядок тика: подачи → таймауты → конец → спавн; подача побеждает таймаут | Core |
| 012 | Player Control обновляется раньше Guest AI в том же кадре | Core/Time |
| 013 | `guests_lost == 3` → заморозка, `match_ended` ровно один раз | State |
| 014 | Онбординг 15 с: только простые рецепты, спавн ×1,0 (не замедляется) | Data-Config |
| 015 | Guest AI — единственный владелец паузы игрового времени | Time |
| 016 | `max_step_delta` = 0,25 с | Time |
| 017 | Валидация констант при загрузке | Data-Config |
| 018 | Повторная валидация выходов DifficultyCurve при спавне с откатом к базовым значениям | Data-Config |
| 019 | `match_started` ровно один раз; дубликаты `request_new_match` игнорируются | State |
| 020 | RNG уровня рецепта `U[0,1)`, детерминирован через `FakeRng` | Data-Config |
| 021 | Свободный слот с наименьшим стабильным ID | Core |
| 022 | Guest AI ≤ 0,5 мс в среднем / ≤ 1,0 мс p99 на кадр | Perf |
| 023 | Гость на `AnimatedSprite3D` в 4 направлениях; именованные ассеты | Animation |
| 024 | Кольцо терпения: billboard, 3 уровня (0,60 / 0,25), снимается мгновенно | Rendering |

### Difficulty Curve & Session Pacing (TR-pacing)
| ID | Требование | Домен |
|---|---|---|
| 001 | `progress = clamp(t/180, 0, 1)^2,0` | Data-Config |
| 002 | Три кривые (гостей/мин 15→18, терпение 50→25, доля сложных 0→0,40) | Data-Config |
| 003 | Чистые функции от `t` (без учёта паузы), одинаковые для всех игроков | Core |
| 004 | Без состояния; `t` передаётся аргументом | Core |
| 005 | Онбординг применяет Guest AI, а не кривые | AI |
| 006 | При `t ≥ ramp_duration` — плато на `_end` | State |
| 007 | Касса — не вход для кривых | Core |
| 008 | Валидация при загрузке (диапазоны, NaN, `_end` не легче `_start`) | Data-Config |
| 009 | Детерминизм: побитово равные результаты | Data-Config |
| 010 | `t` сбрасывается по `match_started` | Time |
| 011 | `guests_per_minute_start` = 15,0 синхронизирован с Guest AI | Data-Config |

### Currency: Coins & Score (TR-currency)
| ID | Требование | Домен |
|---|---|---|
| 001 | `coins_earned = recipe_price` | Core |
| 002 | `score_earned = round_half_up(price × 10 × (1 + rf))` | Core |
| 003 | `score_multiplier_base` = 10 — данные | Data-Config |
| 004 | `match_score`: Idle → Accumulating → Frozen | State |
| 005 | `match_score = 0` на `match_started` | State |
| 006 | `best_score` сохраняется локально и никогда не уменьшается | Save-Load |
| 007 | `is_new_record` вычисляется на `match_ended` до обновления `best_score` | Core |
| 008 | `is_new_record = false` на `match_started` | State |
| 009 | `best_score := match_score` только при `is_new_record` | Core |
| 010 | Монеты и очки не зависят от состояния кассы | Core |
| 011 | Нет трат монет и конвертации монеты↔очки | Core |
| 012 | Единственный триггер — `served(recipe_id, rf)` | Core |
| 013 | Несколько подач в одном тике — порядок не важен | Core |

### Till & Day Cycle (TR-till)
| ID | Требование | Домен |
|---|---|---|
| 001 | `till_amount` ∈ [0, 250], `till_capacity` = 250, Open/Full, `full_since_utc` | State |
| 002 | `coins_added = min(amount + coins, cap) − amount`, эмитится всегда (включая 0) | Core |
| 003 | Open→Full в том же тике, когда касса заполнилась | Core |
| 004 | Full не блокирует матчи | Core |
| 005 | При переходе в Full сохраняется `full_since_utc` | Save-Load |
| 006 | `daily_reset_time_utc` = 00:00 UTC | Data-Config |
| 007 | Проверка сброса только на `match_started` и холодном старте | Time |
| 008 | Сброс: amount = 0, `full_since_utc` очищается | Core |
| 009 | `till_amount` переживает перезапуск | Save-Load |
| 010 | Незаполненная касса не сбрасывается | Core |
| 011 | Несколько пропущенных полуночей → ровно один сброс | Core |
| 012 | Подкрутка часов устройства — принятый риск MVP | Platform-Web |
| 013 | Till не трогает score | Core |

### HUD & Feedback UI (TR-hud)
| ID | Требование | Домен |
|---|---|---|
| 001 | Экранные полосы: счёт, 3 страйка, всплывающие числа, оверлей итогов; мир в полосы не заходит | UI |
| 002 | Мировые оверлеи: касса, чайники, кольцо и жетон гостя, жетоны чашки, метки станций, контур цели и кольцо на полу | Rendering |
| 003 | HUD ничего не хранит и не кэширует, значения читаются каждый кадр | Core |
| 004 | Состояния Inactive → Active → MatchEnd → Active | Core |
| 005 | Жетон и кольцо появляются уже в состоянии Approaching | UI |
| 006 | Тапы по полосам не уходят в кухню; при открытом оверлее тапы получает только оверлей | Input |
| 007 | «Играть снова» принимает тапы после fade ~250 мс + grace 500 мс | Input |
| 008 | Анимации HUD паузятся через игровое время | Core |
| 009 | `till_fill_ratio = amount / capacity` каждый кадр | Data-Config |
| 010 | Open→Full — только акцент на кассе, без чисел в полосе | UI |
| 011 | Испорченная чашка отличается силуэтом, не только цветом | Rendering |
| 012 | При 9:20 постоянные элементы — счёт и страйки; страйки не скрываются | UI |
| 013 | Жетоны в Approaching рисуются с масштабом и прозрачностью 0,7; Waiting — поверх | Animation |
| 014 | Два ухода в одном кадре — пульсы со сдвигом 100 мс | Animation |
| 015 | Всплывающие числа с полным значением сразу, дуга ~400 мс; overflow — отскок без числа | Animation |
| 016 | `is_new_record` читается готовым флагом из Currency | Core |
| 017 | Разделение snap и smooth для анимаций | Animation |
| 018 | Отдельный звук на каждое событие | Audio |
| 019 | Константы тюнинга HUD — данные | Data-Config |
| 020 | Чужие константы только читаются | Data-Config |
| 021 | Контур цели и кольцо на полу меняются в том же кадре, что и цель Player Control | Input |
| 022 | Опция reduced-motion для пульса колец (решается в `/ux-design`) | UI |
| 023 | Кнопка паузы: пауза = hidden ИЛИ пауза игрока (единый GameClock); только в Active; возврат вкладки не снимает; снятие «Продолжить» / Escape / Enter; тапы по кухне игнорируются (2026-09-30, ADR-0003/0006) | Core |
| 024 | Кнопка звука: mute = шина Master; `settings.muted` в SaveStore, schema_version без изменений (2026-09-30, ADR-0001/0005) | Audio |
| 025 | ~~Один зацикленный музыкальный трек: старт по первому жесту, пауза вместе с матчем~~ — заменено TR-hud-027 (2026-09-30) | Audio |
| 026 | ~~Бюджет музыки: ≤ 1,0 МБ в `.pck` 3,0 МБ (остальное ≤ 2,0 МБ), PCM ≤ 48 МБ~~ — заменено TR-hud-028 (2026-09-30) | Performance |
| 027 | Музыка: старт после жеста и загрузки; пауза/скрытие — пауза с позиции; на итогах low-pass (800 Гц / 0,3 с, конфиг, по `ui_dt`); «Играть снова» — с начала без фильтра; mute = Master (2026-09-30, ADR-0001/0003/0004) | Audio |
| 028 | Бюджет музыки: файл ≤ 2,7 МБ вне `.pck`, после `ready_reached`; Stream, ≈ 2,7 МБ в куче, ≤ 1,0 мс/кадр (предв.); `.pck` 3,0 МБ целиком под остальное (2026-09-30, ADR-0007) | Performance |
| 029 | HUD — всегда верхняя строка: Mode A, если верхняя полоса ≥ 56 dp (`ViewConfig.hud_min_strip_dp`), иначе Mode C — резерв верхней полосы 56 dp (аспекты ≈ 0,8–1,0); кухня < 95 % поля — явное исключение; боковые полосы под HUD не используются (2026-09-30, ADR-0002/0004) | UI |

### Game Flow & Meta (TR-flow) — `design/ux/game-flow.md`, 2026-10-01
| ID | Требование | Домен |
|---|---|---|
| 001 | Главное меню (Play / Records / Settings / How to Play) вместо стартового экрана E18; `ready_reached` → меню, без автостарта партии (F1) | UI |
| 002 | Из меню до партии — 1 тап, если `tutorial.seen` | UI |
| 003 | How to Play: 3 карточки автоматически перед первой сменой, дальше из меню; `tutorial.seen` сохраняется (F4) | UI |
| 004 | Settings: Music / Sound effects / Vibration, применяются сразу, сохраняются; доступны из меню и из паузы; из паузы пауза не снимается (F2) | UI |
| 005 | Строки Vibration нет, если `navigator.vibrate` не поддерживается | Platform-Web |
| 006 | Весь текст игры — только английский, строки через `tr()`-ключи; выбора языка нет (F3) | UI |
| 007 | Records: рекорд, до 5 последних смен, счётчики, серия; пустое состояние (F5) | UI |
| 008 | Пауза: Resume / Settings / Main Menu; Main Menu → подтверждение; выход = `match_ended(quit)`, очки засчитываются, итоги пропускаются | Core |
| 009 | Строка статуса в меню: Till A / C и Best; при Full — время до нового дня | UI |
| 010 | Кнопки меню срабатывают по release; Escape = назад; кнопка «назад» браузера не перехватывается | Input |
| 011 | Меню показывает «Progress can't be saved», если `SaveStore.persistent = false` | Persistence |
| 012 | Итоги (M1): порядок строк, накрутка счёта ≤ 0,8 с с пропуском по тапу, «N to beat», Play Again / Share / Menu с grace | UI |
| 013 | Плашка «Till full!» (M2): 2 с, звон, вибрация, не останавливает партию и не ловит тапы (F9) | UI |
| 014 | Тач-устройство в ландшафте → оверлей «Rotate your phone» + пользовательская пауза; обратный поворот паузу не снимает; на ПК оверлея нет (F6) | Platform-Web |
| 015 | Адресная строка не обрабатывается; «кухня ≥ 95 %» — от видимого вьюпорта (F7) | Platform-Web |
| 016 | Экран загрузки: логотип, прогресс, одна случайная подсказка (в HTML-оболочке) | Platform-Web |
| 017 | About: версия сборки, авторы, лицензии (включая Godot MIT) | UI |
| 018 | PWA: установка, строка Install app, одноразовая подсказка после 3-й смены, инструкция на iOS, скрыто в standalone; обновление — при следующем запуске | Platform-Web |
| 019 | Шаринг: PNG-карточка 1080×1350, рендер на `match_ended`, Web Share с файлом; фолбэк — скачать PNG + текст в буфер (F8) | Platform-Web |
| 020 | Wake lock только во время идущей партии | Platform-Web |
| 021 | Send feedback открывает `feedback_url` в новой вкладке; пустой конфиг — строки нет (M10) | UI |
| 022 | NEW BEST! в партии: один раз, только при рекорде на старте > 0, по `Currency.record_passed` (M11) | Core |
| 023 | Последний страйк: виньетка + сердцебиение при `guests_lost == max − 1`, замирают на паузе, reduced motion — без пульса (M12) | UI |
| 024 | Вызов `?beat=N`: валидация, сохранение, удаление параметра из адреса, строка в меню, итог на экране результатов, сброс при выполнении (M13) | Platform-Web |
| 025 | Серия дней: `day_index` по `daily_reset_time_utc`, рост на Open→Full, сгоревшая серия показывается 0 (M14) | Persistence |
| 026 | Reduced motion: все переходы потока мгновенные | UI |
| 027 | Новые ключи SaveStore аддитивны, `schema_version` = 1; `stats.recent` — валидируемая JSON-строка | Persistence |
