# Tea Rush — Master Architecture

## Document Status

- Version: 1.0
- Last Updated: 2026-09-30
- Engine: Godot 4.7.2 (GDScript, Compatibility renderer / WebGL2, web export)
- Platform scope: **только обычный web** (браузер ПК и телефона). Telegram Mini App
  отложен решением 2026-09-30 — в MVP не детектится и не реализуется
- Workflow tier: `standard` — карта слоёв + владение модулями + список критичных ADR
- GDDs Covered: platform-integration-telegram-mini-app, kitchen-station-layout,
  order-recipe-system, player-control-barista-movement, brewing-crafting-mechanic,
  guest-ai-patience, difficulty-curve-session-pacing, currency-coins-score,
  till-day-cycle, hud-feedback-ui (10/10 MVP)
- ADRs Referenced: ADR-0001 (Web build & platform shell, Proposed), ADR-0002 (Viewport, camera fit & 2.5D presentation, Proposed)
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
| Navigation | MEDIUM | 3D API (`NavigationAgent3D`, `NavigationServer3D`) стабилен; изменения 4.5 касались 2D. Нерешённый вопрос — даёт ли NavMesh «середину прохода + спрямление» без постобработки (ADR-0006). |
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
│               · Page Visibility API · IndexedDB   [Telegram SDK — отложен]  │
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
| **PlatformBridge** (autoload) | Foundation | safe-area rect (= вьюпорт браузера), состояние `Loading/Ready` | `safe_area_changed(rect)`, `visibility_changed(visible)`, `ready_reached` | браузер: resize/orientationchange, Page Visibility API | ⚠️ `JavaScriptBridge` (только visibility), `get_viewport().size_changed` |
| **ViewFit** | Foundation | `safe_aspect`, playfield rect, letterbox, размер и смещение ortho-камеры, `kitchen_rect` (ADR-0002; 1 единица канваса = 1 dp) | `playfield_changed(playfield, kitchen_rect)` | `PlatformBridge.safe_area_changed`, габариты кухни | ⚠️ stretch mode, `Camera3D` (ortho `size`) |
| **GameClock** | Foundation | игровое время `t`, флаг паузы, clamp `max_step_delta` | `t`, `step_dt`, `paused` | команды паузы/сброса от MatchLifecycle | — (чистый GDScript) |
| **MatchDirector** | Foundation | порядок тика, корень композиции матча (DI) | — | все модули матча | `_physics_process` |
| **ConfigLoader** | Foundation | загруженные и провалидированные данные тюнинга | типизированные `Resource`-конфиги | файлы данных | `ResourceLoader`, `Resource` |
| **SaveStore** | Foundation | формат и версия файла сохранения | `get(key)`, `set(key, value)`, `flush()` | — | ⚠️ `FileAccess`/`ConfigFile` на `user://` (IndexedDB на web) |
| **KitchenLayout** | Foundation | станции, 7 слотов, 4 слота гостей, spawn/exit, till-anchor, `station_types`, NavMesh | позиции + стабильные ID, `station_types` | — | `NavigationRegion3D`, `Sprite3D` |
| **RecipeBook** | Core | 5 рецептов, прайс, грамматика шагов, цвета шагов | `is_valid_next`, `matches`, `recipe_price`, `recipes_by_tier` | `station_types`, конфиг | — |
| **TapPicker** | Core | правило выбора цели тапа | `tapped(target)` | ввод (в dp, ADR-0002), позиции KitchenLayout/Guests | `Camera3D.unproject_position`, `project_ray_*`, `Plane.intersects_ray` |
| **BaristaController** | Core | состояние `Idle/Walking/Holding`, путь, текущая цель | `state`, `target`, `offer_action()` | `tapped`, Pathing, валидность от Brewing/Guest | `AnimatedSprite3D` |
| **Pathing** | Core | запросы пути, `agent_radius` (одно значение) | `path_to(point) -> PackedVector3Array` | NavMesh / сетку KitchenLayout | ⚠️ `NavigationServer3D` *или* `AStarGrid2D` (решает ADR-0006) |
| **Brewing** | Feature | `held_cup`, 2 чайника (`EMPTY/BREWING/READY`), 7 слотов | ответы `EXECUTE/WAIT/REFUSE`, `consume_held_cup()`, состояния для HUD | RecipeBook, `GameClock.step_dt`, `match_started` | — |
| **MatchLifecycle** (Guest AI) | Feature | `match_started`/`match_ended`, `guests_lost`, политика паузы | `match_started`, `match_ended`, команды GameClock | `ready_reached`, `visibility_changed`, `request_new_match` | — |
| **GuestSim** (Guest AI) | Feature | гости (4 слота), терпение, спавн, RNG выбора рецепта | `served(recipe_id, remaining_fraction)`, `target_vanished`, данные гостей для HUD | DifficultyCurve, RecipeBook, Brewing, Pathing | `AnimatedSprite3D`, агент навигации |
| **DifficultyCurve** | Feature | ничего (без состояния) | `guests_per_minute(t)`, `patience_max(t)`, `complex_order_share(t)` | конфиг | — |
| **Currency** | Feature | `match_score`, `best_score`, `is_new_record` | `coins_earned(n)`, `score_earned(n)`, геттеры | `served`, `match_started`, `match_ended`, SaveStore | — |
| **Till** | Feature | `till_amount`, `Open/Full`, `full_since_utc` | `coins_added(n)`, `day_state`, `till_fill_ratio` | `coins_earned`, `match_started`, `UtcClock`, SaveStore | — |
| **HUD** | Presentation | ничего игрового (правило «без кэша») | `request_new_match` | всё перечисленное выше, только чтение | `Control`, `Sprite3D`/`Label3D`, `Tween` |

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

### 1. Тик симуляции (каждый `_physics_process`)

`MatchDirector` — единственное место, где задан порядок. Узлы систем свой
`_process` для симуляции **не используют**.

```
MatchDirector._physics_process(delta):
  dt = GameClock.advance(delta)        # 0 на паузе, иначе min(delta, max_step_delta = 0.25)
  if dt == 0: return
  TapPicker.flush()                     # последний press за кадр → tapped(target)
  BaristaController.step(dt)            # движение; в Holding → offer_action() владельцу
  Brewing.step(dt)                      # таймеры чайников
  GuestSim.step(dt)                     # (1) подачи → (2) таймауты → (3) проверка конца → (4) спавн
HUD._process(_delta):                   # только чтение, после симуляции
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
PlatformBridge.ready_reached + KitchenLayout загружен ─► MatchLifecycle.start()
HUD «Играть снова» (после grace 500 мс) ─request_new_match─► MatchLifecycle.start()
MatchLifecycle.start(): GameClock.reset(); emit match_started
    → Brewing сбрасывает всё, Currency: match_score=0, Till: проверка UTC-сброса,
      GuestSim: чистит гостей и сразу спавнит первого
GuestSim: guests_lost == 3 ─► MatchLifecycle: GameClock.freeze(); emit match_ended
    → Currency: is_new_record = match_score > best_score; при true сохраняет best_score
PlatformBridge.visibility_changed(false/true) ─► MatchLifecycle ─► GameClock.pause()/resume()
```

Единственный источник паузы — `GameClock`. Анимации HUD, привязанные к игровому
времени (пульс колец, всплывающие числа), берут время из него, а не из
`get_process_delta_time()` (TR-hud-008).

### 4. Сохранение и загрузка

| Ключ | Владелец | Когда пишется | Когда читается |
|---|---|---|---|
| `best_score` | Currency | на `match_ended`, только если `is_new_record` | холодный старт |
| `till_amount`, `day_state`, `full_since_utc` | Till | при каждом изменении (Served, Open↔Full) | холодный старт, `match_started` (проверка сброса) |
| `settings.language` | UI / настройки | при смене | холодный старт |

`SaveStore` — одна плоская схема с `schema_version`. На web `user://` лежит в
IndexedDB ⚠️: момент синхронизации и поведение при очистке хранилища WebView
проверяются в ADR-0005. `match_score` не сохраняется: если приложение упадёт
посреди партии, её результат теряется (TR-currency-006).

### 5. Порядок инициализации

```
1. HTML-оболочка: проверка WebGL2 → иначе статичный экран «обновите браузер» (движок не грузится)
2. PlatformBridge (autoload): первая safe area (= вьюпорт), подписка на resize и visibility
3. ConfigLoader: загрузка и валидация всех данных → ошибка = матч не стартует, текст ошибки в debug
4. SaveStore: чтение файла (при повреждении или его отсутствии — дефолты)
5. Kitchen-сцена: KitchenLayout, ViewFit (камера), MatchDirector собирает граф модулей (DI)
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
func advance(real_delta: float) -> float     # возвращает dt ≤ max_step_delta, 0 на паузе/заморозке
func pause() -> void; func resume() -> void; func freeze() -> void; func reset() -> void
var t: float                                  # игровое время матча, только чтение

class_name SaveStore extends RefCounted       # интерфейс; LocalSaveStore — реализация MVP
func read(key: StringName, default: Variant) -> Variant
func write(key: StringName, value: Variant) -> void   # синхронная запись в память
func flush() -> bool                          # запись на диск; false = ошибка (логируется)

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
signal request_new_match()                                          # HUD
```

**Инварианты для вызывающих:**
- `consume_held_cup()` вызывается ровно один раз на успешную подачу и только
  из GuestSim (TR-brewing-008).
- Значения из DifficultyCurve фиксируются в госте при спавне и больше не
  пересчитываются (TR-guest-009, TR-pacing-004).
- HUD не пишет ни в одну систему, кроме `request_new_match`.
- Till не читает score, Currency не читает состояние кассы (граница Pillar 4).

**Типы движка в интерфейсах:** в сигнатурах выше только `StringName`, `Array[T]`,
`PackedVector3Array` и `RefCounted`. Все они стабильны в 4.x. Узлы (`Node3D`)
через границы модулей не передаются: только ID и позиции.

---

## ADR Audit

ADR пока нет. Traceability: **0 из 164 требований покрыто ADR.** Каждое
требование ниже приписано к ADR, который его закроет.

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
| **ADR-0006** | **Navigation & tap picking** | NavMesh + `NavigationAgent3D` (так в GDD) против `AStarGrid2D` + спрямление по прямой видимости (так в прототипе, ощущение уже проверено). Единственный источник `agent_radius`, RVO для гостей да/нет, выбор тапа без физики (`unproject_position` + пересечение с плоскостью пола), стабильные ID точек. |

### Before Vertical Slice

| # | `/architecture-decision` | Решает |
|---|---|---|
| **ADR-0007** | **Performance & load budgets** | Размер загрузки (MB), time-to-interactive на эталонном слабом Android, 60/30 fps, потолок памяти, мс на систему (Guest AI ≤ 0,5 мс в среднем). Опирается на измерения spike из ADR-0001. |

### Can defer to implementation

- Пул объектов гостей на 4 слота (guest OQ5): решается в истории GuestSim.
- Формат стабильных ID слотов (guest OQ10, control OQ): решается в истории
  KitchenLayout в рамках ADR-0006.
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
   браузере на слабом Android. Никакой 3D-физики, пост-обработки,
   потоков и тяжёлых шейдеров без измерения на реальном устройстве.

---

## Open Questions

| ID | Вопрос | Приоритет | Где решается |
|---|---|---|---|
| AQ-01 | Single-thread или threads для web-экспорта 4.7 в мобильных браузерах (Chrome Android, Safari iOS), реальный размер сборки и время загрузки? | High | ADR-0001 (spike) |
| AQ-02 | NavMesh или `AStarGrid2D`: воспроизводит ли NavMesh «середину прохода + спрямление» без постобработки? | High | ADR-0006 |
| AQ-03 | Когда `user://` на web реально попадает в IndexedDB, и что будет при очистке данных сайта / приватном режиме? | High | ADR-0005 |
| AQ-04 | Задержка «касание → движок» в мобильном браузере не измерена (бюджет ≤ 50 мс только внутри движка). | Medium | ADR-0001 spike → ADR-0007 |
| AQ-05 | Что считается «кадром» для debounce safe area: `_process` или `requestAnimationFrame` (platform OQ5)? | Low | ADR-0001 |
| AQ-06 | Манипуляция системными часами устройства может досрочно сбросить кассу: принятый риск MVP. | Low | Backend & Persistence (VS) |

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
| 014 | Онбординг 30 с: только простые рецепты, спавн ×0,5 | Data-Config |
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
| 002 | Три кривые (гостей/мин 7→18, терпение 50→25, доля сложных 0→0,40) | Data-Config |
| 003 | Чистые функции от `t` (без учёта паузы), одинаковые для всех игроков | Core |
| 004 | Без состояния; `t` передаётся аргументом | Core |
| 005 | Онбординг применяет Guest AI, а не кривые | AI |
| 006 | При `t ≥ ramp_duration` — плато на `_end` | State |
| 007 | Касса — не вход для кривых | Core |
| 008 | Валидация при загрузке (диапазоны, NaN, `_end` не легче `_start`) | Data-Config |
| 009 | Детерминизм: побитово равные результаты | Data-Config |
| 010 | `t` сбрасывается по `match_started` | Time |
| 011 | `guests_per_minute_start` = 7,0 синхронизирован с Guest AI | Data-Config |

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
