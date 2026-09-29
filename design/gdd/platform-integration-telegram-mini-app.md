# Platform Integration (Telegram Mini App)

> **Status**: Approved
> **Creative Director Review (CD-GDD-ALIGN)**: skipped — Lean mode
> **Author**: user + agents
> **Last Updated**: 2026-09-28
> **Last Verified**: 2026-09-28
> **Implements Pillar**: инфраструктурная система — не обслуживает Pillar напрямую (см. Target Player Profile и MVP Definition в game-concept.md)

## Summary

Platform Integration доставляет игру до игрока: одна веб-сборка Godot
открывается как обычный сайт на ПК и телефоне, и она же запускается
внутри Telegram Mini App. Система определяет, в каком контексте запущена
игра, показывает экран загрузки и задаёт safe area с допустимыми
пропорциями экрана (9:20–1:1), в которые вписываются кухня и HUD. Без неё
игре негде запуститься, а кухне не во что масштабироваться.

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `None (upstream); downstream — Kitchen & Station Layout, HUD & Feedback UI`

> **Решение 2026-09-30 (пользователь, Technical Setup): интеграция с Telegram
> отложена.** MVP — только обычный web (Standalone Web) на ПК и телефоне.
> Контекст Telegram Mini App не детектится и не реализуется: Core Rules 2–4,
> Telegram-ветки Rule 5, состояния *Detecting Context* и *Telegram Mini App*,
> AC 3, 4, 12 и Telegram-части AC 1, 6, 11 помечены *(отложено)* и в MVP не
> проверяются. Всё остальное (одна сборка по одному URL, экран загрузки,
> safe area = вьюпорт браузера, клэмп 9:20–1:1 и леттербокс, WebGL2-fallback,
> единый сигнал видимости через Page Visibility API) остаётся в силе.
> Возврат Telegram — отдельным решением; шов под него остаётся в
> `PlatformBridge` (см. `docs/architecture/architecture.md`).

## Overview

Platform Integration — слой доставки и запуска игры: единая веб-сборка
Godot (HTML5-экспорт), которая работает как обычный сайт по URL на
десктопе и на телефоне, а та же сборка дополнительно грузится внутри
Telegram Mini App (Telegram WebView + Telegram SDK) как один из способов
встраивания, а не отдельная архитектура. Система задаёт контракт вьюпорта
и safe area (диапазон соотношения сторон экрана, зона, свободная от
системных элементов вроде шапки Telegram или выреза камеры), на который
уже опирается Kitchen & Station Layout. Игрок не взаимодействует с этой
системой напрямую — он ощущает её результат в том, насколько быстро и
корректно загрузилась и отмасштабировалась сцена. Без неё игре попросту
негде запуститься: ни в браузере на произвольном устройстве, ни в целевом
канале дистрибуции — Telegram (Target Player Profile: «Telegram на
мобильном»).

## Detailed Design

*Специалисты не привлекались — режим `lean` пропускает обязательный спавн
для секций вне D/H.*

### Core Rules

1. Единая веб-сборка (Godot HTML5-экспорт) обслуживает оба контекста
   запуска — обычный браузер (десктоп/телефон) и Telegram Mini App
   (WebView). Один билд, один URL, деплой один раз.
2. При загрузке страницы игра проверяет наличие объекта Telegram WebApp JS
   в `window`. Если объект присутствует и его инициализация
   (`Telegram.WebApp.ready()`) завершилась успешно — контекст = **Telegram
   Mini App**. Если объект отсутствует — контекст = **Standalone Web**.
3. Если объект Telegram WebApp найден, но инициализация SDK не
   завершилась (устаревший клиент Telegram, сбой) — игра **тихо**
   переключается на поведение Standalone Web: Telegram-специфичные функции
   не используются, игроку ничего не показывается и не блокируется.
4. Telegram SDK в этой системе используется только для: (a) safe-area
   инсетов (что перекрыто системными элементами Telegram), (b)
   опционального сопоставления темы. **Оплата не входит в scope этой
   системы** — Telegram Stars исключены как платёжный метод (решение
   2026-09-28, см. game-concept.md), способ оплаты для Monetization / IAP
   Integration не выбран.
5. Safe area (зона без системных элементов; на неё опирается Kitchen &
   Station Layout, AC#6/#10):
   - **Standalone Web** — весь вьюпорт браузера (`window.innerWidth`/
     `innerHeight`), пересчитывается на `resize`/`orientationchange`.
   - **Telegram Mini App** — вьюпорт минус Telegram-инсеты (шапка/
     системный chrome), пересчитывается на событие `viewportChanged`
     Telegram SDK.
6. Экран загрузки показывается до готовности сцены кухни; обязан
   укладываться в бюджет времени загрузки (открытый технический риск
   game-concept.md: размер и скорость загрузки на слабых Android — точный
   бюджет фиксируется в Acceptance Criteria).
7. Stretch mode/aspect проекта Godot задаётся explicit, не оставляется на
   дефолт движка (4.7 сменил дефолт `disabled/keep` → `canvas_items/expand`
   — см. `docs/engine-reference/godot/breaking-changes.md`, 4.6 → 4.7,
   Project defaults). Контракт «портрет
   9:20–1:1, шире — леттербокс» (Kitchen & Station Layout AC#6/#10) должен
   выполняться независимо от будущих смен дефолтов движка.

### States and Transitions

| Состояние | Вход | Выход |
|---|---|---|
| **Loading** | Страница/WebView открыты | → Detecting Context, как только рантайм Godot загружен |
| **Detecting Context** | Из Loading | → *Telegram Mini App*, если WebApp JS найден и SDK инициализировался; иначе → *Standalone Web* |
| **Telegram Mini App** | SDK инициализирован | → Ready; safe area = viewport минус Telegram-инсеты |
| **Standalone Web** | WebApp JS отсутствует ИЛИ SDK не инициализировался | → Ready; safe area = весь вьюпорт браузера |
| **Ready** | Detecting Context завершён | Кухня активна; постоянный listener на resize/orientationchange (Standalone) или `viewportChanged` (Telegram) — пересчитывает safe area без смены состояния |

### Interactions with Other Systems

Upstream: нет — Foundation-слой, как и Kitchen & Station Layout.

Downstream:

| Система | Тип | Интерфейс |
|---|---|---|
| Kitchen & Station Layout | Hard | Safe-area rect + допустимый диапазон соотношения сторон (9:20–1:1) — кухня масштабируется и центрируется внутри, пересчёт при каждом изменении safe area |
| HUD & Feedback UI | Hard | Тот же safe-area rect — HUD занимает свободные полосы |
| Guest AI & Patience | Hard | `Ready` → первая партия стартует (вместе с загрузкой сцены кухни, её Rule 13); сигнал смены видимости (уход в фон / возврат) — пауза игрового времени (её Rule 11) *(`Ready` добавлен 2026-09-29 batch-fix, N1)* |
| Monetization / IAP Integration *(не спроектирована, Alpha)* | Soft | Флаг контекста (Telegram / Standalone); платёжный метод пока не определён и не Stars |
| Backend & Persistence *(не спроектирована, Vertical Slice)* | Soft | В Telegram-контексте доступен Telegram user ID (`initData`) для идентификации игрока; в Standalone Web понадобится другой механизм — открытый вопрос, не решается здесь |

## Formulas

*Специалисты не привлекались — режим `lean`, секция не входит в D/H
(добавлена при ревью 2026-09-28: Core Rules п.5 задаёт пороги, что по
`.claude/rules/design-docs.md` делает секцию обязательной на tier `standard`).*

**Переменные:**
- `viewport_w`, `viewport_h` — ширина/высота вьюпорта (px в Standalone Web,
  CSS-px в Telegram WebView)
- `inset_top/bottom/left/right` — Telegram-инсеты (шапка, системный chrome);
  в Standalone Web все равны 0
- `safe_w = viewport_w - inset_left - inset_right`
- `safe_h = viewport_h - inset_top - inset_bottom`, зажат снизу минимумом
  1px (`max(1, ...)`) — защита от деления на ноль/отрицательное значение,
  если Telegram-инсеты когда-либо сравняются с высотой вьюпорта на
  экстремально маленьком WebView
- `safe_aspect = safe_w / safe_h`
- `viewport_aspect_min = 0.45` (9:20 — самый узкий/высокий разрешённый экран)
- `viewport_aspect_max = 1.0` (1:1 — самый широкий разрешённый экран; шире
  клэмпится)

**Playfield rect (clamp + letterbox):**

```
if safe_aspect < viewport_aspect_min:
    playfield_w = safe_w
    playfield_h = safe_w / viewport_aspect_min
    letterbox: top/bottom, (safe_h - playfield_h) / 2 каждая
elif safe_aspect > viewport_aspect_max:
    playfield_h = safe_h
    playfield_w = safe_h * viewport_aspect_max
    letterbox: left/right, (safe_w - playfield_w) / 2 каждая
else:
    playfield_w = safe_w
    playfield_h = safe_h
    letterbox: нет
```

`playfield` центрируется внутри `safe_area` по обеим осям.

**Примеры (граничные и типичные значения):**
- Телефон 360×640, без инсетов: `safe_aspect = 0.5625` → в диапазоне →
  playfield 360×640, без леттербокса.
- Узкий экран 300×800: `safe_aspect = 0.375 < 0.45` → playfield 300×666.7,
  леттербокс top/bottom по 66.65 px.
- Квадратное PC-окно 900×900: `safe_aspect = 1.0` (граница) → playfield
  900×900, без леттербокса.
- Широкое PC-окно 1600×900: `safe_aspect = 1.778 > 1.0` → playfield
  900×900, леттербокс left/right по 350 px.
- Telegram, инсет шапки 80px, вьюпорт 400×850: `safe_h = 770`,
  `safe_aspect = 0.519` → в диапазоне → playfield 400×770.

## Edge Cases

*Специалисты не привлекались — режим `lean`, секция не входит в D/H.*

- **Если браузер не поддерживает WebGL2/HTML5-экспорт Godot**: показывается
  статический (не-Godot) fallback-экран «Обновите браузер» без попытки
  загрузить движок. Пустой белый экран без объяснения хуже явного
  сообщения.
- **Если загрузка превышает разумное время** (точный бюджет не
  зафиксирован ни здесь, ни в Acceptance Criteria — открытый технический
  риск game-concept.md, требует измерения размера сборки на прототипе):
  экран загрузки остаётся видимым с прогресс-баром, жёсткого таймаута/
  отмены нет. Число вводится, когда появится замер — см. Open Questions.
- **Если вьюпорт меняется во время активной партии** (ресайз окна, поворот
  телефона): safe area пересчитывается немедленно, Kitchen & Station
  Layout масштабируется без сброса состояния партии (гости, таймеры,
  чашка в руках не сбрасываются).
- **Если фактическое соотношение сторон уже 9:20** (редкие нестандартные
  экраны): `safe_aspect == viewport_aspect_min` — формула клэмпа (ветка
  `else`) не добавляет леттербокс, playfield равен всей safe area. Кухня
  внутри playfield всё равно не занимает 100%: `kitchen-station-layout.md`
  AC#6 резервирует ~5% ограничивающей стороны, и эти полосы отдаются HUD.
  Free-strip-контракт здесь принадлежит Kitchen & Station Layout, а не
  клэмпу этой системы — в отличие от случая «шире 1:1» (Edge Case ниже),
  где леттербокс действительно производит эта система.
- **Если несколько событий resize приходят подряд быстро** (интерактивный
  ресайз окна, поворот телефона): пересчёт safe area дебaунсится — не
  чаще одного раза за кадр, а не на каждое сырое событие.
- **Если Telegram Mini App сворачивается / вкладка браузера уходит в
  фон**: платформа сигнализирует смену видимости (Page Visibility API в
  браузере, соответствующее событие Telegram SDK в Mini App) одинаково в
  обоих контекстах. Реакция на сигнал — пауза партии (`guest-ai-patience.md`,
  Rule 11); эта система только гарантирует, что сигнал существует.
- **Если Telegram SDK инициализировался, но `initData`/user ID
  недоступны** (ограничение приватности в Telegram, пустой ответ API):
  контекст остаётся Telegram Mini App, safe area и тема продолжают
  работать; функциональность, зависящая от идентификации игрока (будущий
  Backend & Persistence), недоступна — не блокирует запуск, интерфейс
  предполагает `user_id` опциональным.

## Dependencies

Upstream: нет — Foundation-слой (совпадает с Detailed Design →
Interactions).

Downstream:

| Система | Тип | Интерфейс |
|---|---|---|
| Kitchen & Station Layout | Hard | Safe-area rect + диапазон соотношения сторон (9:20–1:1) |
| HUD & Feedback UI | Hard | Тот же safe-area rect |
| Monetization / IAP Integration *(не спроектирована, Alpha)* | Soft | Флаг контекста (Telegram / Standalone); платёжный метод не определён |
| Backend & Persistence *(не спроектирована, Vertical Slice)* | Soft | Telegram user ID в Telegram-контексте, опционален |
| Guest AI & Patience | Hard | `Ready` → первая партия стартует (вместе с загрузкой сцены кухни, её Rule 13; добавлено 2026-09-29 batch-fix, N1); сигнал смены видимости (уход в фон / возврат) — Guest AI ставит партию на паузу (добавлено 2026-09-28 при проектировании `guest-ai-patience.md`) |

**Двунаправленная проверка**: `kitchen-station-layout.md` уже полагалось
на safe-area/viewport-контракт этой системы (AC#6, AC#10), но его секция
Dependencies заявляла «Upstream: нет» — исправлено в том же коммите
(добавлена строка Platform Integration → Hard).

## Visual/Audio Requirements

*Категория Core — секция не обязательна, `art-director` не привлекался
(режим `lean`, визуальный фидбек не центральный для этой системы).*

- Экран загрузки: минималистичный, в духе мягкого рисованного стиля
  (Visual Identity Anchor, game-concept.md) — логотип/название чайной,
  простой прогресс-индикатор. Не тянет тяжёлые ассеты — сам не должен
  утяжелять то, что измеряет.
- Fallback-экран (неподдерживаемый браузер): простой текст на нейтральном
  фоне, без брендированной графики (сама графика может не успеть
  загрузиться).
- Звук: не относится к этой системе — сочный аудио-фидбек (монеты, пар)
  принадлежит Audio & Juice Feedback и триггерится игровыми событиями, а
  не платформенными переходами.

## Game Feel

*Категория Core — секция не обязательна (обязательна только для Gameplay
и UI).*

- Переход Loading → Ready не должен давать видимую вспышку/скачок (без
  белого экрана между экраном загрузки и первым кадром кухни).
- Пересчёт safe area при resize — плавная перестройка масштаба, а не
  мгновенный snap посреди партии (детали реализации — Kitchen & Station
  Layout).

## UI Requirements

- Экран загрузки: прогресс-бар/спиннер, без интерактивных элементов.
- Fallback-экран: текстовое сообщение «Обновите браузер», без
  интерактивных элементов.
- Постоянного on-screen UI в состоянии Ready у этой системы нет — HUD
  принадлежит HUD & Feedback UI.

📌 **UX Flag — Platform Integration**: есть реальные UI-требования (экран
загрузки, fallback-экран). В Pre-Production запустить `/ux-design` для
этих двух экранов до написания эпиков.

## Cross-References

| Ссылка | Куда | Что именно |
|---|---|---|
| Safe-area rect, диапазон 9:20–1:1 | `design/gdd/kitchen-station-layout.md` AC#6, AC#10 | Кухня уже предполагает этот контракт |
| Safe-area rect (ожидаемо) | `design/gdd/hud-feedback-ui.md` *(не создана)* | HUD займёт свободные полосы того же safe area |
| Флаг контекста (Telegram / Standalone) | будущая `design/gdd/monetization-iap-integration.md` | Платёжный метод не определён |
| Telegram user ID (опционально) | будущая `design/gdd/backend-persistence.md` | Идентификация игрока в Telegram-контексте |
| Platform: Web / Telegram Mini App; MVP-пункт 6 | `design/gdd/game-concept.md` | Технические ограничения и MVP-требование |

## Tuning Knobs

*ADVISORY на tier `standard` — добавлена вместе с Formulas при ревью
2026-09-28, т.к. оба значения уже трекаются в `design/registry/entities.yaml`.*

| Параметр | Значение | Диапазон | Что меняет |
|---|---|---|---|
| `viewport_aspect_min` | 0.45 (9:20) | N/A — фиксировано архитектурным решением, не баланс-параметр. Бизнес-решение «портрет, без ландшафта» (game-concept.md, Platform); смена требует ревью Kitchen & Station Layout AC#6/#8. | Ниже границы — letterbox top/bottom |
| `viewport_aspect_max` | 1.0 (1:1) | N/A — фиксировано архитектурным решением, аналогично. | Выше границы — letterbox left/right |

## Acceptance Criteria

*Покрытие и тестируемость проверил `qa-lead`. Формулы — см. секцию
Formulas (добавлена при ревью 2026-09-28); остальные критерии выведены
из Core Rules и Edge Cases.*

1. *(Telegram-часть отложена 2026-09-30 — в MVP проверяется только браузер.)* **GIVEN** сборка задеплоена по одному URL, **WHEN** этот URL
   открывается и в обычном браузере, и из Telegram WebView, **THEN** оба
   контекста загружают один и тот же билд (одинаковые ассеты и версия).
   Отдельного билда или URL для Telegram нет.
2. **GIVEN** та же сборка, **WHEN** страница открывается в обычном
   браузере без объекта Telegram WebApp, **THEN** игра запускается в
   контексте Standalone Web, а safe area равна всему вьюпорту браузера.
3. *(Отложено 2026-09-30.)* **GIVEN** та же сборка, **WHEN** страница открывается внутри Telegram
   WebView и Telegram WebApp SDK успешно инициализируется, **THEN** игра
   запускается в контексте Telegram Mini App, а safe area равна вьюпорту
   минус Telegram-инсеты.
4. *(Отложено 2026-09-30.)* **GIVEN** страница открыта внутри Telegram WebView, **WHEN**
   инициализация Telegram SDK завершается ошибкой или таймаутом, **THEN**
   игра переключается на поведение Standalone Web без сообщения об ошибке
   и без блокировки запуска.
5. **GIVEN** игра в состоянии Loading, **WHEN** ассеты рантайма ещё
   загружаются, **THEN** до перехода в Ready виден экран загрузки с
   индикатором прогресса, который обновляется по мере загрузки. Белого
   или пустого экрана и зависания нет, жёсткого таймаута или отмены
   загрузки тоже нет.
6. *(Ветка `viewportChanged` отложена 2026-09-30.)* **GIVEN** игра в состоянии Ready и идёт партия, **WHEN** меняется
   размер вьюпорта (`resize`/`orientationchange` в браузере,
   `viewportChanged` в Telegram), **THEN** safe area пересчитывается и
   кухня масштабируется. Активные гости, их таймеры терпения и предмет в
   руках баристы сохраняются.
7. **GIVEN** в течение одного кадра приходит несколько событий resize
   подряд, **WHEN** они обрабатываются, **THEN** safe area
   пересчитывается не больше одного раза за кадр. *Какой именно "кадр" —
   см. Open Questions #5.*
8. **GIVEN** вьюпорт уже 9:20 (`safe_aspect == viewport_aspect_min`),
   **WHEN** отображается кухня, **THEN** формула клэмпа (см. Formulas)
   попадает в ветку `else` — playfield равен всей safe area, эта система
   леттербокс не добавляет. Полосы сверху и снизу, которые видит игрок,
   — это ~5% margin из `kitchen-station-layout.md` AC#6 («кухня занимает
   не менее 95% ограничивающей стороны»), а не леттербокс Platform
   Integration. *Integration-критерий: свободные полосы проверяются
   тестом `kitchen-station-layout.md` AC#6, отдельного теста здесь нет —
   симметрично AC#9 ниже.*
9. **GIVEN** вьюпорт шире 1:1, **WHEN** отображается кухня, **THEN** по
   высоте применяется леттербокс, кухня стоит по центру, боковые полосы
   свободны. *Integration-критерий: проверяется тестом
   `kitchen-station-layout.md` AC#10, отдельного теста здесь нет.*
10. **GIVEN** браузер без поддержки WebGL2, **WHEN** открывается
    страница, **THEN** показывается статический fallback-экран «Обновите
    браузер», а рантайм Godot не загружается.
11. *(Telegram-контекст отложен 2026-09-30 — в MVP только Page Visibility API.)* **GIVEN** игра запущена в любом из двух контекстов, **WHEN** Telegram
    Mini App сворачивается или вкладка браузера уходит в фон (и когда
    возвращается), **THEN** эмитится один и тот же сигнал платформы о
    смене видимости, с одним именем и сигнатурой независимо от
    контекста.
12. *(Отложено 2026-09-30.)* **GIVEN** Telegram SDK инициализирован, **WHEN** `initData` или user
    ID недоступны, **THEN** safe area и тема продолжают работать, запуск
    не блокируется, а `user_id` отдаётся как отсутствующий, без ошибки.

## Open Questions

| # | Вопрос | Владелец | Когда решать |
|---|---|---|---|
| ~~1~~ | ~~Точный бюджет времени/размера загрузки на слабых Android~~ **Решено ADR-0007 (2026-09-30, Proposed):** загрузка ≤ 13,5 МБ сжатыми (движок 10,2 МБ — замерено на шаблоне 4.7.2), TTI холодный ≤ 20 с при 10 Мбит/с / тёплый ≤ 6 с на эталонном классе устройств; числа на устройстве подтверждает spike ADR-0001 | technical-director / прототип | Закрыто (ждёт spike) |
| 2 | Платёжный метод вместо Telegram Stars | economy-designer (Monetization / IAP Integration) | Alpha |
| 3 | ~~Поведение при сворачивании Telegram Mini App / уходе вкладки в фон — пауза партии или потеря~~ **Решено 2026-09-28**: пауза, отсчёт продолжается после возврата (`guest-ai-patience.md`, Rule 11) | game-designer (Guest AI & Patience) | Закрыто |
| 4 | Механизм идентификации игрока в Standalone Web без Telegram user ID | technical-director (Backend & Persistence) | Vertical Slice |
| ~~5~~ | ~~Какой "кадр" имеется в виду в AC#7 — Godot `_process`/`_physics_process` или браузерный `requestAnimationFrame`~~ **Решено ADR-0001 (2026-09-30):** кадр = один тик Godot `_process`; флаг «грязный» гасится там раз за кадр | gameplay-programmer / technical-director | Закрыто |
