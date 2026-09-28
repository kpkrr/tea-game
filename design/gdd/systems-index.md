# Systems Index: Tea Rush (рабочее название)

> **Status**: Draft
> **Created**: 2026-09-27
> **Last Updated**: 2026-09-28 (Difficulty Curve & Session Pacing — Designed)
> **Source Concept**: design/gdd/game-concept.md

---

## Overview

Tea Rush — аркадный кухонный симулятор в духе Overcooked с уникальным
крючком: дневной лимит заработка — физический предмет (касса) на прилавке.
Core loop (Pillar 1: «Хаос за стойкой») требует пространства кухни, управления
тапом, системы рецептов и заваривания, а также ИИ гостей с терпением —
без любой из них 30-секундный цикл «принять заказ → собрать → подать» не
работает. Вокруг этого ядра стоят две независимые метрики (Pillar 4: «Монеты
за работу, очки за мастерство») и касса с дневным циклом (Pillar 3: «Одна
касса, одно правило»), а поверх — интерфейс, который должен читать цену
напитка с первого взгляда (Pillar 2: «Цена видна в чашке»). За пределами MVP
находятся серверная авторизация экономики, лидерборд и лиги, донат-прокачка
и, ещё дальше, кооп и токенизация Tea Coin. Ниже — все 17 систем, их
зависимости и порядок проектирования.

### Foundation

**Kitchen & Station Layout** *(inferred)* — Пространственная модель кухни:
вертикальный прямоугольник ~8×11м, станции у стен, остров 2×4 в центре,
7 слотов (5 на острове, по одному у каждой боковой стены), сплошная низкая
столешница вдоль стен и острова. Решения уже приняты и провалидированы
прототипом `kitchen-core`. Ничего другого не зависит от неё структурно, но
от неё зависят почти все остальные gameplay-системы — это самая
bottleneck-система индекса.

**Platform Integration (Telegram Mini App)** *(explicit)* — Одна web-сборка
Godot: обычный сайт по URL на ПК и телефоне, и та же сборка внутри Telegram
Mini App как обёртка (автодетект Telegram WebApp JS). Задаёт safe area и
диапазон пропорций экрана 9:20–1:1, в которые вписываются кухня и HUD.
Telegram SDK — только safe-area инсеты и тема; Telegram Stars исключены
(решение 2026-09-28). Не имеет игровых зависимостей, но без неё игру негде
показать целевой аудитории (Target Player Profile: «Telegram на мобильном»).

### Core

**Order & Recipe System** *(explicit)* — Определения рецептов: 5 напитков
MVP в 3 уровнях сложности (3/4/5 шагов: чашка → лист → вода нужной
температуры → лимон → подача), цены из таблицы 2/5/5/7/7 — растут со
сложностью, но не линейно по числу шагов (см. GDD). Зависит от Kitchen &
Station Layout, так как шаги рецепта завязаны на существующие типы станций.

**Player Control / Barista Movement** *(inferred)* — Тап по станции/гостю =
идти и выполнить действие; тап по полу = просто идти; новый тап сразу
перенаправляет баристу без очереди. Путь по сетке держится середины проходов
и спрямляется, где видна прямая линия. Зависит от Kitchen & Station Layout —
без раскладки кухни путь прокладывать некуда.

### Feature

**Brewing & Crafting Mechanic** *(inferred)* — Одна чашка в руках, таймер
заварки идёт в фоне и не блокирует чайник, но занимает его до тех пор, пока
готовый чай не заберут. Слот: обмен чашки в руках на чашку в слоте одним
тапом. Ошибка в рецепте — чашка в мусорку, начать заново. Зависит от Order &
Recipe (что заваривать), Player Control (как добраться до станции) и Kitchen
& Station Layout (где стоят чайники и слоты).

**Guest AI & Patience** *(inferred)* — Спавн гостей, убывающее терпение,
уход гостя по истечении терпения, конец партии после 3 ушедших гостей.
Подача — любому гостю с совпадающим заказом. Зависит от Kitchen & Station
Layout (точки появления и ожидания) и Order & Recipe (какие заказы
раздавать).

**Difficulty Curve & Session Pacing** *(explicit)* — Рост сложности по
ease-in (`curve_exponent` 2.0) с 0-й по 3-ю минуту партии, затем плато: поток гостей 8→18 гостей/мин, терпение 50→25 с,
доля сложных заказов (с лимоном) 0%→40%. Первые ~30 секунд служат встроенным
обучением (только одношаговые напитки, редкие гости). Зависит от Guest AI &
Patience (что именно модулирует) и Order & Recipe (какие заказы усложнять).

**Currency: Coins & Score** *(explicit)* — Две независимые метрики, которые
никогда не пересекаются: Tea Coin (заработок, идёт в кассу) и очки
(мастерство, идут в рекорд всегда, даже когда касса полна). Формула очков:
цена × 10 × (1 + доля оставшегося терпения гостя). Зависит от Order & Recipe
(цена напитка) и Guest AI & Patience (терпение на момент подачи).

**Till & Day Cycle** *(explicit)* — Видимая вместимость кассы (базово ≈5×
доход за эталонную 2-минутную партию), заполнение, закрытие дня («Чайная
закрыта до завтра») с локальным сохранением состояния между партиями внутри
запуска. После заполнения монеты не идут, очки — идут всегда. Зависит от
Currency: Coins & Score.

**Backend & Persistence** *(explicit, Vertical Slice)* — Серверный,
авторитативный учёт кассы, монет и дневного сброса; клиенту в вопросах
экономики доверять нельзя, как только Tea Coin станет токеном. Здесь же
разделение монет на фантомные (бесплатный игрок, копятся, но не выводятся) и
настоящие (после покупки). Зависит от Till & Day Cycle и Currency: Coins &
Score.

**Leaderboard & Leagues** *(explicit, Vertical Slice → расширяется на Alpha)*
— Лидерборд по очкам на Vertical Slice; лиги по уровню баристы добавляются
на Alpha, когда появляется Progression. Требует серверной проверки
правдоподобности очков. Зависит от Backend & Persistence и Currency: Coins &
Score.

**Progression & Upgrades** *(explicit, Alpha)* — Уровни кассы (0–3: 250 /
350 / 500 / 700 монет) и уровни скорости баристы (0–3: ×1.0 / 1.15 / 1.3 /
1.5 на ходьбу и заварку) за донат. Прокачка — уровнями, а не отдельными
предметами; бесплатной прокачки нет. Зависит от Till & Day Cycle, Currency:
Coins & Score и Player Control (что именно ускоряется).

**Monetization / IAP Integration** *(explicit, Alpha)* — Платёжный адаптер
(метод оплаты не выбран; Telegram Stars исключены 2026-09-28), вызывающий
интерфейс Progression & Upgrades для
выдачи купленного уровня. Зависимость однонаправленная — Monetization не
определяет, что продаётся, только проводит оплату и дёргает Progression.
Зависит от Progression & Upgrades.

**Co-op / Multiplayer** *(explicit, Full Vision)* — Кооп заявлен как часть
полного видения, после доказанного соло-ядра. Потребует сетевого слоя поверх
уже существующих Player Control, Kitchen & Station Layout, Guest AI &
Patience и Backend & Persistence.

**Token Integration** *(explicit, Full Vision)* — Превращение Tea Coin в
токен — самая юридически чувствительная часть экономики (см. Market Risks в
game-concept). Зависит от Currency: Coins & Score, Backend & Persistence и
Monetization / IAP Integration.

### Presentation

**HUD & Feedback UI** *(inferred)* — Отображение текущего заказа и его цены,
заполнения кассы, счётчика монет/очков, цветовых индикаторов шагов рецепта
(белый — чашка, фиолетовый — холодный чай, зелёный/оранжево-коричневый —
лист, красный/синий — вода, жёлтый — лимон). Прямое требование Pillar 2:
«Цена видна в чашке». Зависит от Order & Recipe, Guest AI & Patience,
Currency: Coins & Score, Till & Day Cycle и Brewing & Crafting Mechanic —
отображает состояние почти всего ядра.

**Audio & Juice Feedback** *(inferred, Vertical Slice)* — Звуковой и
тактильный фидбек: звон монет в кассе, пар, «успел!». Player Experience
Analysis называет Sensation приоритетом 3, Technical Considerations —
«Audio Needs: Moderate». Зависит от Brewing & Crafting Mechanic, Currency:
Coins & Score и Till & Day Cycle (события, на которые реагирует).

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | Kitchen & Station Layout (inferred) | Gameplay | MVP | Approved | design/gdd/kitchen-station-layout.md | Platform Integration (Telegram Mini App) |
| 2 | Platform Integration (Telegram Mini App) | Core | MVP | Approved | design/gdd/platform-integration-telegram-mini-app.md | — |
| 3 | Order & Recipe System | Gameplay | MVP | Approved | design/gdd/order-recipe-system.md | Kitchen & Station Layout |
| 4 | Player Control / Barista Movement (inferred) | Gameplay | MVP | Approved | design/gdd/player-control-barista-movement.md | Kitchen & Station Layout |
| 5 | Brewing & Crafting Mechanic (inferred) | Gameplay | MVP | Approved | design/gdd/brewing-crafting-mechanic.md | Order & Recipe System, Player Control, Kitchen & Station Layout |
| 6 | Guest AI & Patience (inferred) | Gameplay | MVP | Approved | design/gdd/guest-ai-patience.md | Kitchen & Station Layout, Order & Recipe System, Player Control, Brewing & Crafting Mechanic, Platform Integration (soft) |
| 7 | Difficulty Curve & Session Pacing | Gameplay | MVP | Designed | design/gdd/difficulty-curve-session-pacing.md | Guest AI & Patience, Order & Recipe System |
| 8 | Currency: Coins & Score | Economy | MVP | Not Started | — | Order & Recipe System, Guest AI & Patience |
| 9 | Till & Day Cycle | Economy | MVP | Not Started | — | Currency: Coins & Score |
| 10 | HUD & Feedback UI (inferred) | UI | MVP | Not Started | — | Platform Integration (Telegram Mini App), Kitchen & Station Layout, Order & Recipe System, Guest AI & Patience, Currency: Coins & Score, Till & Day Cycle, Brewing & Crafting Mechanic |
| 11 | Backend & Persistence | Persistence | Vertical Slice | Not Started | — | Till & Day Cycle, Currency: Coins & Score |
| 12 | Leaderboard & Leagues | Meta | Vertical Slice | Not Started | — | Backend & Persistence, Currency: Coins & Score |
| 13 | Audio & Juice Feedback (inferred) | Audio | Vertical Slice | Not Started | — | Brewing & Crafting Mechanic, Currency: Coins & Score, Till & Day Cycle |
| 14 | Progression & Upgrades | Progression | Alpha | Not Started | — | Till & Day Cycle, Currency: Coins & Score, Player Control |
| 15 | Monetization / IAP Integration | Economy | Alpha | Not Started | — | Progression & Upgrades |
| 16 | Co-op / Multiplayer | Core | Full Vision | Not Started | — | Player Control, Kitchen & Station Layout, Guest AI & Patience, Backend & Persistence |
| 17 | Token Integration | Economy | Full Vision | Not Started | — | Currency: Coins & Score, Backend & Persistence, Monetization / IAP Integration |

---

## Categories

| Category | Description | Systems in this project |
|----------|-------------|-----------------|
| **Core** | Foundation systems everything depends on | Platform Integration, Co-op / Multiplayer |
| **Gameplay** | The systems that make the game fun | Kitchen & Station Layout, Order & Recipe, Player Control, Brewing & Crafting, Guest AI & Patience, Difficulty Curve |
| **Progression** | How the player grows over time | Progression & Upgrades |
| **Economy** | Resource creation and consumption | Currency: Coins & Score, Till & Day Cycle, Monetization / IAP, Token Integration |
| **Persistence** | Save state and continuity | Backend & Persistence |
| **UI** | Player-facing information displays | HUD & Feedback UI |
| **Audio** | Sound and music systems | Audio & Juice Feedback |
| **Meta** | Systems outside the core game loop | Leaderboard & Leagues |

**Narrative** removed — game-concept explicitly states "Сюжета нет
(антистолп)".

---

## Priority Tiers

| Tier | Definition | Target Milestone | Design Urgency |
|------|------------|------------------|----------------|
| **MVP** | Required for the core loop to function — without these, "весело ли ядро?" can't be tested | 1 кухня, 3 напитка, web-экспорт в TMA (2–3 недели) | Design FIRST |
| **Vertical Slice** | Backend authority, real economy split, competitive layer | Бэкенд + лидерборд (+2–3 недели) | Design SECOND |
| **Alpha** | Donation-based progression, full content set (6–8 напитков) | Прокачка + лиги (+3–4 недели) | Design THIRD |
| **Full Vision** | Co-op and token — explicitly deferred until solo core is proven | Новые кухни, сезоны, кооп, токен (+2–3 месяца) | Design as needed |

> **Creative Director Note** (MVP): гейт CD-SYSTEMS пропущен — Lean mode.

---

## Dependency Map

### Foundation Layer (no dependencies)

1. **Kitchen & Station Layout** — пространственная модель, от которой зависит почти всё остальное. *С 2026-09-28 зависит от Platform Integration (safe area, пропорции 9:20–1:1) — строго говоря, это уже Core-слой; оставлена здесь, т.к. GDD уже написана и порядок проектирования не меняется.*
2. **Platform Integration (Telegram Mini App)** — технический фундамент доставки, независим от игровых систем; задаёт safe-area-контракт для Kitchen & Station Layout и HUD.

### Core Layer (depends on foundation)

1. **Order & Recipe System** — depends on: Kitchen & Station Layout
2. **Player Control / Barista Movement** — depends on: Kitchen & Station Layout

### Feature Layer (depends on core)

1. **Brewing & Crafting Mechanic** — depends on: Order & Recipe System, Player Control, Kitchen & Station Layout
2. **Guest AI & Patience** — depends on: Kitchen & Station Layout, Order & Recipe System, Player Control (контракт цели-гостя — добавлено при дизайне player-control), Brewing & Crafting Mechanic (очистка рук на подаче), Platform Integration (soft: сигнал ухода в фон → пауза) — добавлено при дизайне guest-ai-patience
3. **Difficulty Curve & Session Pacing** — depends on: Guest AI & Patience, Order & Recipe System
4. **Currency: Coins & Score** — depends on: Order & Recipe System, Guest AI & Patience
5. **Till & Day Cycle** — depends on: Currency: Coins & Score
6. **Backend & Persistence** — depends on: Till & Day Cycle, Currency: Coins & Score
7. **Leaderboard & Leagues** — depends on: Backend & Persistence, Currency: Coins & Score
8. **Progression & Upgrades** — depends on: Till & Day Cycle, Currency: Coins & Score, Player Control
9. **Monetization / IAP Integration** — depends on: Progression & Upgrades
10. **Co-op / Multiplayer** — depends on: Player Control, Kitchen & Station Layout, Guest AI & Patience, Backend & Persistence
11. **Token Integration** — depends on: Currency: Coins & Score, Backend & Persistence, Monetization / IAP Integration

### Presentation Layer (depends on features)

1. **HUD & Feedback UI** — depends on: Platform Integration (safe area — добавлено при дизайне platform-integration), Kitchen & Station Layout (till anchor, свободные полосы экрана — добавлено при дизайне kitchen-station-layout), Order & Recipe System, Guest AI & Patience, Currency: Coins & Score, Till & Day Cycle, Brewing & Crafting Mechanic
2. **Audio & Juice Feedback** — depends on: Brewing & Crafting Mechanic, Currency: Coins & Score, Till & Day Cycle

### Polish Layer (depends on everything)

Пусто на текущий момент. Онбординг встроен в Difficulty Curve & Session
Pacing (первые ~30 секунд партии), отдельной Polish-системы не требуется.

---

## Recommended Design Order

| Order | System | Priority | Layer | Agent(s) | Est. Effort |
|-------|--------|----------|-------|----------|-------------|
| 1 | Kitchen & Station Layout | MVP | Foundation | level-designer, game-designer | S |
| 2 | Platform Integration (Telegram Mini App) | MVP | Foundation | technical-director | S |
| 3 | Order & Recipe System | MVP | Core | game-designer | M |
| 4 | Player Control / Barista Movement | MVP | Core | game-designer, gameplay-programmer | M |
| 5 | Brewing & Crafting Mechanic | MVP | Feature | game-designer, systems-designer | M |
| 6 | Guest AI & Patience | MVP | Feature | ai-programmer, game-designer | M |
| 7 | Difficulty Curve & Session Pacing | MVP | Feature | systems-designer | S |
| 8 | Currency: Coins & Score | MVP | Feature | economy-designer | S |
| 9 | Till & Day Cycle | MVP | Feature | economy-designer, game-designer | S |
| 10 | HUD & Feedback UI | MVP | Presentation | ux-designer, ui-programmer | M |
| 11 | Backend & Persistence | Vertical Slice | Feature | technical-director, security-engineer | L |
| 12 | Leaderboard & Leagues | Vertical Slice | Feature | economy-designer, community-manager | M |
| 13 | Audio & Juice Feedback | Vertical Slice | Presentation | audio-director, sound-designer | S |
| 14 | Progression & Upgrades | Alpha | Feature | economy-designer | M |
| 15 | Monetization / IAP Integration | Alpha | Feature | economy-designer, technical-director | M |
| 16 | Co-op / Multiplayer | Full Vision | Feature | network-programmer | L |
| 17 | Token Integration | Full Vision | Feature | economy-designer, security-engineer | L |

---

## Circular Dependencies

- **None found.** Потенциальная петля Progression & Upgrades ↔ Monetization /
  IAP Integration разрешена контрактом: Progression владеет уровнями и их
  эффектами (что покупается), Monetization — только платёжный адаптер,
  вызывающий интерфейс Progression для выдачи уровня. Зависимость
  однонаправленная: Monetization → Progression.

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|-----------------|------------|
| Kitchen & Station Layout | Scope | Bottleneck — 5 систем зависят от неё напрямую; поздняя правка раскладки каскадом задевает Player Control, Order & Recipe, Brewing, Guest AI, Co-op | Уже провалидирована прототипом `kitchen-core` — зафиксировать как есть, менять только через ADR |
| Order & Recipe System | Design | Таблица цен рецептов стоит в основе Currency, Guest AI и Difficulty — ошибка в кривой цен ломает всю экономику; при заварке 3 с сложный заказ доминирует по монетам/с (см. Open Questions GDD) | Формулы и диапазоны — отдельная секция Formulas в GDD, обязательный `/balance-check` до Alpha |
| Currency: Coins & Score | Design | Стык экономики (4 системы зависят от неё); открытый вопрос из game-concept — "скрытая формула кассы будет вычислена комьюнити" | Формула должна быть спроектирована так, чтобы обрыв смены ощущался честным — playtest перед фиксацией |
| Platform Integration (Telegram Mini App) | Technical | Открытый технический риск из game-concept: размер и время загрузки web-сборки Godot в Telegram WebView на слабых Android | Прототипировать экспорт рано, независимо от приоритета — измерить размер сборки до конца MVP |
| Backend & Persistence | Technical | Как только Tea Coin станет токеном, клиенту в вопросах экономики доверять нельзя; лидерборд требует серверной проверки правдоподобности очков | Спроектировать серверную авторизацию до Vertical Slice, не как надстройку поверх готового клиента |
| Token Integration | Market | Юридически чувствительная зона (Market Risks в game-concept) — pay-to-earn при превращении монет в токен | Явно в Full Vision; не проектировать раньше юридической проверки |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 17 |
| Design docs started | 7 |
| Design docs reviewed | 6 |
| Design docs approved | 6 |
| MVP systems designed | 7/10 |
| Vertical Slice systems designed | 0/3 |

---

## Next Steps

- [x] Review and approve this systems enumeration
- [ ] Design MVP-tier systems first (use `/design-system [system-name]`, начиная с Kitchen & Station Layout)
- [ ] Run `/design-review` on each completed GDD
- [ ] Run `/gate-check pre-production` when MVP systems are designed
- [ ] Validate the highest-risk systems with `/vertical-slice` before committing to Production
