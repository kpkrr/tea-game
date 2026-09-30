# Currency: Coins & Score

> **Status**: Approved (batch-fix 2026-09-29: все находки `gdd-cross-review-2026-09-29b.md`/`-29c.md` закрыты, см. review-log)
> **Author**: Yan + systems-designer, economy-designer, qa-lead
> **Last Updated**: 2026-09-29
> **Last Verified**: 2026-09-28
> **Implements Pillar**: Pillar 4 — Монеты за работу, очки за мастерство
> **Creative Director Review (CD-GDD-ALIGN)**: пропущен — Lean mode

## Summary

Currency: Coins & Score превращает каждую поданную чашку в два независимых
числа: Tea Coin, который копится в кассе и ограничивает заработок дня, и
Score, который идёт в личный рекорд и никогда не ограничен. Игрок видит оба
сразу при подаче заказа — цена рецепта даёт монеты напрямую, а скорость
подачи (остаток терпения гостя) умножает очки, так что мастерство
вознаграждается отдельно от заработка. Система существует, чтобы
реализовать Pillar 4 «Монеты за работу, очки за мастерство»: рекорд нельзя
купить, а прокачка и донат влияют только на заработок, никогда — на очки.

> **Quick reference** — Layer: `Feature` · Priority: `MVP` · Key deps: `Order & Recipe System, Guest AI & Patience`

## Overview

Currency: Coins & Score определяет два независимых числовых выхода партии —
Tea Coin (заработок, накапливается в кассе) и Score (мастерство, идёт в
личный рекорд). Оба вычисляются в момент подачи заказа (событие Served) из
уже существующих данных: цены рецепта (Order & Recipe System) и остатка
терпения гостя на момент подачи (Guest AI & Patience). Монеты — прямое
отражение цены; очки — цена, умноженная на бонус за скорость подачи, так
что дорогой заказ, поданный в последнюю секунду, даёт меньше очков, чем тот
же заказ, поданный быстро. Система реализует Pillar 4 «Монеты за работу,
очки за мастерство»: игра вознаграждает два разных стиля игры — стабильный
заработок и виртуозную скорость — не позволяя купить преимущество в одном
ценой другого. Без неё у Till & Day Cycle и будущего лидерборда нет входных
данных.

## Detailed Design

### Core Rules

1. На каждое событие Served (владеет Guest AI & Patience, Rule 5) эта
   система получает `(recipe_id, remaining_fraction)` и вычисляет два
   независимых значения: `coins_earned` и `score_earned` (Formula 1 и 2 —
   Formulas).
2. `coins_earned` равен `recipe_price(recipe_id)` (Order & Recipe System,
   Formula 1) — без модификаторов и бонусов. Цена, которую игрок видит на
   тикете заказа, и есть заработанные монеты.
3. `score_earned` равен `recipe_price(recipe_id) × 10 × (1 +
   remaining_fraction)` (Formula 1 этой GDD) — вознаграждает и цену
   напитка, и то, сколько терпения гостя осталось на момент подачи.
4. `coins_earned` передаётся в Till & Day Cycle на каждое событие Served;
   попадут ли монеты в видимую кассу — решение Till & Day Cycle (гейтинг
   по вместимости, граница уже зафиксирована в `order-recipe-system.md`).
   Эта система никогда не проверяет вместимость кассы и никогда не
   удерживает `coins_earned`.
5. `score_earned` добавляется в `match_score` безусловно, на каждое
   Served за всю партию — включая события после заполнения кассы и вплоть
   до конца партии (уход 3-го гостя, Guest AI Rule 9); всё, что подано до
   этого момента, засчитывается.
6. Tea Coin можно только заработать, потратить нельзя. Эта система не
   определяет ни одного пути расходования `coins_earned` или суммы в
   кассе; будущий механизм траты (если появится) — вне этой GDD
   (game-concept, Economy & Access Model).
7. `match_score` сбрасывается в 0 в начале каждой партии. По окончании
   партии (сигнал `match_ended` от Guest AI & Patience) система сначала
   вычисляет `is_new_record = match_score > best_score` (сравнение со
   значением **до** обновления), затем, если `is_new_record`, обновляет
   `best_score` и сохраняет его локально (в MVP бэкенда нет — см.
   Dependencies). `is_new_record` держится до следующего `match_started`,
   где сбрасывается в `false`; HUD читает его для акцента нового рекорда
   (HUD Core Rule 13) — сам HUD сравнение не повторяет, т.к. к моменту
   рендера `best_score` уже обновлён. *(Исправлено 2026-09-29 batch-fix:
   S4 — раньше флага не было, и HUD не мог вычислить «новый рекорд».)*
8. `best_score` никогда не уменьшается и не сбрасывается ничем в этой
   GDD — ни новой партией, ни заполнением кассы (состояние Full), ни
   дневным сбросом кассы (это вне области Till & Day Cycle).
9. Монеты и очки никогда не делят путь конвертации, который позволил бы
   купить одно за счёт другого: ничто в Progression & Upgrades,
   Monetization или Token Integration не может превращать
   `coins_earned`/сумму в кассе в `score_earned`/`match_score` или
   наоборот (design test Pillar 4).

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| `match_score`: Idle | Партия начинается (значение = 0) | Первое событие Served → Accumulating; или `match_ended` без единого Served → Frozen со значением 0 | Очки ещё не начислялись |
| `match_score`: Accumulating | Первое событие Served | Сигнал `match_ended` | Увеличивается на `score_earned` при каждом Served |
| `match_score`: Frozen | Сигнал `match_ended` | Старт следующей партии — сигнал `match_started` (Guest AI & Patience Rule 13), сброс в Idle | Значение зафиксировано; читается HUD/итогами партии |
| `best_score`: Held | Всегда (хранится между партиями, локальное сохранение) | Никогда не выходит | При переходе `match_score` в Frozen сравнивается и при необходимости обновляется на месте |
| `is_new_record` (bool) | `match_ended`: вычисляется как `match_score > best_score` до обновления `best_score` | `match_started` — сброс в `false` | Читается HUD на оверлее итогов (HUD Core Rule 13) |

### Interactions with Other Systems

| Система | Направление | Интерфейс |
|---|---|---|
| Order & Recipe System | Upstream, Hard | `recipe_price(recipe_id)` — вход обеих формул (монет и очков) |
| Guest AI & Patience | Upstream, Hard | Событие Served с `(recipe_id, remaining_fraction)` — единственный триггер расчёта; `match_ended` — заморозка `match_score` и сравнение с `best_score`; `match_started` (её Rule 13) — сброс `match_score` в Idle. Тот же контракт зафиксирован в Downstream Guest AI |
| Till & Day Cycle | Downstream, Hard | Получает `coins_earned` на каждый Served; владеет суммой кассы и её вместимостью — эта система не знает, приняты монеты или отброшены |
| HUD & Feedback UI | Downstream, Hard | Читает `match_score`, `best_score`, `score_earned` по каждому событию (счётчик и попап очков; попап монет HUD берёт из `coins_added` Till & Day Cycle); `is_new_record` на `match_ended` — для акцента нового рекорда (HUD Core Rule 13) |
| Audio & Juice Feedback | Downstream, Hard, Vertical Slice | Реагирует на выход события Served (звон монет из game-concept) |
| Backend & Persistence | Downstream, Hard, Vertical Slice | Позже возьмёт на себя серверный учёт `best_score`/лидерборда; в MVP `best_score` — только в локальном сохранении, серверных вызовов из этой системы нет |
| Leaderboard & Leagues | Downstream, Hard, Vertical Slice | Ранжирует игроков по `best_score`/`match_score` |
| Progression & Upgrades | Downstream, Hard, Alpha | Потребляет сумму кассы (не `score_earned`) для стоимости прокачки — никогда не меняет, как считаются `coins_earned`/`score_earned` (Core Rule 9) |
| Token Integration | Downstream, Hard, Full Vision | Потребляет `coins_earned`/сумму кассы как будущий источник токена — очки не участвуют (Core Rule 9) |

## Formulas

*С systems-designer и economy-designer (2026-09-28). Решения пользователя:
округление `round()` half-up; коэффициент `10` вынесен как именованная
константа `score_multiplier_base`.*

### Formula 1 — `score_earned`

The `score_earned` formula is defined as:

`score_earned = round(recipe_price(recipe_id) × score_multiplier_base × (1 + remaining_fraction))`

**Variables:**

| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| `recipe_id` | enum | {cold_tea, black_tea, green_tea, black_tea_lemon, green_tea_lemon} | Guest AI & Patience, payload события Served | Рецепт поданного заказа |
| `recipe_price(recipe_id)` | int | [2, 7] | registry formula `recipe_price`, owner `order-recipe-system.md` | Цена рецепта, табличный lookup |
| `remaining_fraction` | float | [0, 1] | registry formula `remaining_fraction`, owner `guest-ai-patience.md` | Доля терпения гостя, оставшаяся на момент подачи |
| `score_multiplier_base` | int | 10 (MVP) | data file (этот GDD; кандидат в реестр) | Коэффициент перевода цены и скорости подачи в очки |
| `score_earned` | int | [20, 140] теоретически | calculated | Очки, добавляемые в `match_score` за это событие Served |

**Output Range:** теоретически [20, 140], целое после округления. Монотонно
растёт и по цене, и по остатку терпения. Никогда не равен 0:
`(1 + remaining_fraction) ≥ 1` всегда, значит `score_earned ≥
recipe_price × score_multiplier_base ≥ 2 × 10 = 20`. Округляется `round()`
(half-up) непосредственно в момент вычисления — `score_earned`,
`match_score` и `best_score` всегда целые, без риска расхождения дробной
части между платформами (Telegram Mini App — веб-рантайм). Практический
потолок ниже теоретического: `remaining_fraction = 1.0` недостижим из-за
времени в пути гостя до слота (`guest_walk_speed`, Guest AI & Patience
Rule 4) — реалистичный максимум ближе к ~115–130, чем к 140; величина
зависит от раскладки кухни и не зафиксирована константой.

**Example:**
1. `green_tea_lemon` (price=7), `remaining_fraction=0.4` →
   `7 × 10 × 1.4 = 98` → `round(98) = 98`.
2. `cold_tea` (price=2), `remaining_fraction≈1.0` (теоретический предел,
   практически недостижим) → `2 × 10 × 2 = 40` → `round(40) = 40`.
3. `black_tea` (price=5), `remaining_fraction=0.5732` (типичное нецелое
   значение середины партии) → `5 × 10 × 1.5732 = 78.66` →
   `round(78.66) = 79`.

### Formula 2 — `coins_earned`

The `coins_earned` formula is defined as:

`coins_earned = recipe_price(recipe_id)`

**Variables:**

| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| `recipe_id` | enum | {cold_tea, black_tea, green_tea, black_tea_lemon, green_tea_lemon} | Guest AI & Patience, payload события Served | Рецепт поданного заказа |
| `recipe_price(recipe_id)` | int | [2, 7] | registry formula `recipe_price`, owner `order-recipe-system.md` | Прямой passthrough без модификаторов (Core Rule 2) |
| `coins_earned` | int | [2, 7] | calculated | Монеты, переданные в Till & Day Cycle за это событие Served |

**Output Range:** [2, 7], целое, совпадает с диапазоном `recipe_price` без
изменений — вычислений сверх табличного lookup нет, вопрос округления не
возникает.

**Example:**
1. `black_tea_lemon` (price=7) → `coins_earned = 7`.
2. `cold_tea` (price=2) → `coins_earned = 2` (минимум, независимо от того,
   есть ли место в кассе).

### Валидация баланса (economy-designer)

- **Диапазон `match_score` за партию**: грубая оценка — средний игрок
  ~1100–1300 очков за партию (~26 гостей × ~3.6 монеты,
  `remaining_fraction`≈0.25 на пределе throughput), сильный игрок
  ~3500–4000 (~61 гость, `remaining_fraction`≈0.45). *(Число гостей
  пересчитано симуляцией очереди `/balance-check till-day-cycle`
  2026-10-01 под поток 15→18; было ~20 / ~50.)* Разброс порядка ×3 — достаточен для
  осмысленного ранжирования в Leaderboard & Leagues (Vertical Slice). Но
  основной вклад в разброс даёт длительность выживания × throughput, а не
  сама формула очков — это тот же риск, что уже открыт как Open Question
  #4 в `difficulty-curve-session-pacing.md` (нет эскалации после плато
  180 с → потенциальный неограниченный фарм очков долгой партией). Точные
  границы — после замера реальной скорости игрока (`till-day-cycle.md`
  Open Questions).
- **Проверка пересечения по цене**: `cold_tea` идеально (2×10×2=40) всегда
  проигрывает `black_tea_lemon`/`green_tea_lemon` на грани ухода гостя
  (7×10×1=70) — простой рецепт никогда не обгоняет сложный по очкам.
  Но **medium может обогнать complex**: `black_tea`/`green_tea` идеально
  (5×10×2=100) превосходит complex на грани (7×10×1=70) при
  `remaining_fraction > 0.4` — достижимо в обычной игре (не экстремальный
  edge case). Это осознанное следствие текущей таблицы цен 2/5/5/7/7, не
  баг формулы — задокументировано как Edge Case ниже.
- **Вырожденные стратегии**: не обнаружены. Throughput-анализ (очки/сек
  занятости бариста) показывает, что дешёвые рецепты не выгоднее сложных
  даже с учётом лучшего `remaining_fraction`: ценовой разрыв (×3.5)
  перевешивает разрыв во времени исполнения (~×1.9). Игнорировать дорогие
  заказы ради скорости одновременно менее эффективно по очкам и
  рискованно для длины партии (потеря гостя = один из 3 страйков).

## Edge Cases

*Специалисты не привлекались отдельно — режим `lean`, секция не входит в
D/H; часть кейсов ниже перенесена из валидации баланса в Formulas.*

**Касса и монеты**

- **Если касса полна на момент Served**: `coins_earned` всё равно
  вычисляется и передаётся в Till & Day Cycle; попадёт ли он в видимую
  сумму — решает Till & Day Cycle, не эта система (граница уже
  зафиксирована в `order-recipe-system.md`). `score_earned` при этом
  начисляется как обычно — эти два пути никогда не блокируют друг друга.

**Формула очков**

- **Если `remaining_fraction = 0` на момент Served** (гость подан в тот же
  тик, что и истёк бы его лимит терпения — Guest AI & Patience Rule 8,
  «подача побеждает»): `score_earned` не становится 0 — минимум для
  рецепта `recipe_price × score_multiplier_base × 1` (например 20 для
  `cold_tea`). Формула структурно не может дать 0 очков за поданный заказ.
- **Если несколько гостей поданы в один и тот же тик**: каждое событие
  Served обрабатывается независимо со своими `recipe_id`/
  `remaining_fraction`; `match_score` — простой аккумулятор, сложение
  коммутативно, порядок обработки внутри тика не влияет на итог.
- **Medium-рецепт может обогнать complex по очкам**: при идеальной подаче
  (`remaining_fraction → 1`) `black_tea`/`green_tea` (5×10×2=100) даёт
  больше очков, чем `black_tea_lemon`/`green_tea_lemon`, поданный на грани
  ухода гостя (7×10×1=70) — порог пересечения `remaining_fraction > 0.4`,
  достижим в обычной игре. Это осознанное следствие текущей таблицы цен
  (2/5/5/7/7) и бонуса ×1–×2 за скорость, а не ошибка формулы
  (economy-designer, см. Formulas) — очки вознаграждают мастерство
  подачи, а не только цену рецепта, что соответствует Pillar 4.

**Партия и запись рекорда**

- **Если событие Served происходит в тот же тик, что и `match_ended`**
  (третий потерянный гость — другой, не тот, кого только что подали):
  порядок тика уже зафиксирован в `guest-ai-patience.md` Rule 8 (подачи и
  уходы обрабатываются раньше проверки конца партии) — `score_earned` от
  этого Served добавляется в `match_score` до перехода в Frozen.
- **Если партия заканчивается без единого Served** (все три потерянных
  гостя — до первой подачи): `match_score` = 0, переходит Idle → Frozen
  напрямую (минуя Accumulating); сравнение с `best_score` корректно не
  повышает рекорд, `is_new_record = false` (даже в первой партии: `0 > 0`
  ложно).
- **Если это первая партия за всё время игры**: `best_score` не имеет
  сохранённого значения — считается 0 при первом сравнении; любой
  `match_score` > 0 устанавливает `best_score`.
- **Если приложение закрывается или теряет соединение до конца партии**
  (Telegram WebView, сворачивание/закрытие вкладки): промежуточный
  `match_score` нигде не сохраняется инкрементально — только финальное
  значение при `match_ended`. Незавершённая партия не может повысить
  `best_score`. Пауза при уходе в фон (Platform Integration, через Guest
  AI & Patience Rule 11) не приравнивается к завершению партии — это
  разные события.

**Взаимодействие с прокачкой (Alpha, не в MVP)**

- **Если бариста ускорен прокачкой** (`speed_multiplier` ×1.15–1.5,
  Progression & Upgrades): формула `score_earned` не содержит ни
  `speed_multiplier`, ни любых переменных доната — Core Rule 9 держится
  на уровне формулы. Но ускорение сокращает `time_to_complete`
  (`order-recipe-system.md` Formula 2), а значит косвенно повышает
  типичный `remaining_fraction` на подаче для платящего игрока того же
  скилла — реальное, хоть и не прямое, конкурентное преимущество на
  будущем лидерборде (economy-designer). Это не нарушение Core Rule 9
  буквально, но требует решения при дизайне Leaderboard & Leagues —
  вынесено в Open Questions.

## Dependencies

**Upstream (эта система зависит от):**

| Система | Тип | Интерфейс |
|---|---|---|
| Order & Recipe System | Hard | `recipe_price(recipe_id)` — вход обеих формул (уже перечисляет эту систему в своём Downstream: «`recipe_price(recipe_id)` — монеты и множитель в формуле очков») |
| Guest AI & Patience | Hard | Событие Served с `(recipe_id, remaining_fraction)` — единственный триггер расчёта; `match_ended` (Rule 9) — заморозка `match_score`, вычисление `is_new_record`, обновление `best_score`; `match_started` (Rule 13) — сброс `match_score` в Idle и `is_new_record` в `false` (уже перечисляет эту систему в своём Downstream с тем же контрактом) |

**Downstream (зависят от этой системы)** — все hard:

| Система | Что получает |
|---|---|
| Till & Day Cycle | `coins_earned` на каждое событие Served — решает, сколько добавить в видимую сумму кассы (`coins_added`, её Core Rule 2) |
| HUD & Feedback UI | `match_score`, `best_score`, `score_earned` по каждому событию — для счётчика и попапа очков; `is_new_record` на `match_ended` — акцент нового рекорда |
| Backend & Persistence *(не спроектирована, Vertical Slice)* | Возьмёт на себя серверный учёт `best_score`; в MVP это локальное сохранение |
| Leaderboard & Leagues *(не спроектирована, Vertical Slice)* | `best_score`/`match_score` для ранжирования игроков |
| Audio & Juice Feedback *(не спроектирована, Vertical Slice)* | Выход события Served (звон монет) как триггер звука |
| Progression & Upgrades *(не спроектирована, Alpha)* | Сумму кассы (не очки) для стоимости прокачки |
| Token Integration *(не спроектирована, Full Vision)* | `coins_earned`/сумму кассы как источник будущего токена; очки не участвуют |

Имена функций и событий — описание контракта, не API; реализация — в ADR.

**Двунаправленность:**
- Order & Recipe System уже перечисляет Currency: Coins & Score в своих
  Downstream («`recipe_price(recipe_id)` — монеты и множитель в формуле
  очков») — сходится.
- Guest AI & Patience уже перечисляет Currency: Coins & Score в своих
  Downstream («`(recipe_id, remaining_fraction)` на каждое событие Served
  — вход для формулы монет и очков») — сходится; её же секция Dependencies
  явно требует, чтобы Currency, когда будет спроектирована, перечислила
  Guest AI & Patience в ответ — выполнено выше.
- Till & Day Cycle и HUD & Feedback UI спроектированы и перечисляют
  Currency: Coins & Score как Upstream (HUD — включая `is_new_record`) —
  сходится. Остальные пять downstream-систем ещё не спроектированы;
  каждая должна перечислить Currency: Coins & Score в своей секции
  Dependencies, когда будет написана.

## Visual/Audio Requirements

*Category Economy — не входит в обязательный список (Gameplay/UI/Narrative/
Audio); `art-director`/`audio-director` не привлекались (`lean`, визуальный
фидбек этой системы не центральный для неё самой). Эта система не владеет
ассетами и анимацией — она специфицирует, какие события нуждаются в
различимом фидбеке; конкретную форму (иконки, цвет, шрифт, звук) утверждают
HUD & Feedback UI и Audio & Juice Feedback при своём проектировании.*

| Событие | Визуальный фидбек | Аудио фидбек | Приоритет |
|---|---|---|---|
| Served → `coins_earned` | Всплывающее число `+coins_earned`, визуально связанное с кассой (например, монеты «летят» к ней) — ассет и анимация за HUD & Feedback UI | Короткий звон монет (game-concept: «звон монет в кассе») — за Audio & Juice Feedback | High — заработок должен быть виден мгновенно (Pillar 2/4) |
| Served → `score_earned` | Отдельное всплывающее число `+score_earned`, **визуально отличное** от монет (другой цвет/иконка — не золото, чтобы не путать с Tea Coin; Pillar 4: «две валюты не пересекаются никогда») | Отдельный, более «лёгкий»/мастерский звук, не совпадающий со звоном монет | Medium |
| `match_ended`, новый рекорд (`is_new_record = true`) | Заметное выделение нового рекорда на итоговом экране партии — форму определяет HUD & Feedback UI / `/art-bible` | Отдельный «триумфальный» звук/стингер | Medium |
| Касса приняла/отклонила `coins_earned` (касса полна) | Вне scope этой системы — визуальную/аудио реакцию на отказ кассы специфицирует Till & Day Cycle | Вне scope | — |

> 📌 **Asset Spec** — Visual/Audio requirements определены. После утверждения
> арт-библии запустите `/asset-spec system:currency-coins-score`, чтобы
> получить по-ассетные описания, размеры и промпты генерации из этой
> секции.

## Game Feel

*Category Economy — не входит в обязательный список (Gameplay/UI). У этой
системы нет собственного игрового ввода (нет хитбоксов, анимаций,
управления) — она реагирует на уже произошедшее событие Served. Большая
часть шаблонных подсекций (Animation Feel Targets, Impact Moments) поэтому
не применима напрямую и принадлежит HUD & Feedback UI / Audio & Juice
Feedback, которые владеют ассетами всплывающих чисел и звука. Единственное
жёсткое требование, которым владеет эта GDD, — синхронность.*

### Feel Reference

Не «input → response» в классическом смысле — референс здесь: Cooking
Fever, где числа заработка появляются без анимационной задержки в момент
подачи, а не отдельным «шоу» после паузы. Анти-референс: любая мобильная
экономика, где числа монет считаются вверх анимацией дольше 300–500 мс —
это создаёт ощущение, что игра «тянет» реакцию ради вовлечённости, а не
подтверждает действие игрока.

### Input Responsiveness

| Action | Max Input-to-Response Latency (ms) | Frame Budget (at 60fps) | Notes |
|---|---|---|---|
| Served → вычисление `coins_earned`/`score_earned` | ≤16.6 мс (1 кадр) | 1 frame | Вычисление синхронно с событием Served, не асинхронно — см. AC 33; задержки быть не должно, даже если сама всплывающая анимация чисел (HUD) длится дольше |

### Weight and Responsiveness Profile

Числа должны появляться мгновенно и без задержки вычисления — ощущение
подтверждения действия («щёлк»), а не отдельная презентация. Понятия веса
и «снапа» неприменимы — здесь нет физического действия, которым управляет
игрок; feel-нагрузка на удар/вес несёт станция подачи (Brewing & Crafting
Mechanic / Player Control), не эта система.

### Feel Acceptance Criteria

- [ ] Игрок не замечает задержки между подачей заказа и появлением чисел монет/очков
- [ ] Звук монет и звук очков различимы без визуальной подсказки (проверяется с закрытыми глазами)
- [ ] Число очков и число монет не путаются друг с другом ни по цвету, ни по расположению на экране

## UI Requirements

*Таблица фиксирует, что HUD & Feedback UI берёт от Currency (реализовано
в `hud-feedback-ui.md`); раскладку и стиль экрана утверждает `/ux-design`
для HUD.*

| Information | Display Location | Update Frequency | Condition |
|---|---|---|---|
| `match_score` (текущий счёт партии) | Единственный постоянный числовой счётчик в полосе HUD, рядом — индикатор страйков (HUD Core Rule 10, `design/ux/hud.md` E1) | На каждое событие Served | Всегда во время партии (`Active`, `Paused`) |
| `coins_added` за событие (фактический прирост кассы, не `coins_earned`) | Временный popup, летит от точки подачи к кассе; излишек — отскок без числа, при `coins_added = 0` числа нет (HUD Core Rule 11, `design/ux/hud.md` E12) | На событие Served | Одноразово, ~400 мс |
| `score_earned` за событие | Временный popup, летит от точки подачи к счётчику `match_score`; отличается от монет цветом, иконкой и направлением | На событие Served | Одноразово, ~400 мс |
| `best_score` (личный рекорд) | Оверлей итогов партии; стартовый экран «Начать смену» | При `match_ended`; при показе стартового экрана | На оверлее итогов и на стартовом экране (HUD Core Rule 19) *(Исправлено 2026-09-29 batch-fix: N5; 2026-10-01 — стартовый экран, решение владельца 2026-09-30)* |
| Индикатор нового рекорда | Оверлей итогов партии | Один раз при `match_ended` | Только если `is_new_record = true` |

*(Обновлено 2026-09-30 под `design/ux/hud.md`: попап монет летит к кассе,
тикета-виджета нет; попап показывает `coins_added`, а не `coins_earned`.)*

> **📌 UX Flag — Currency: Coins & Score**: у этой системы есть UI-требования.
> В Phase 4 (Pre-Production) запустите `/ux-design` для каждого экрана/
> HUD-элемента, который она затрагивает (постоянный HUD-счётчик, popup-числа,
> итоговый экран партии), **до** написания эпиков. Истории, ссылающиеся на UI,
> должны цитировать `design/ux/[screen].md`, а не эту GDD напрямую.
>
> Отметить это в systems-index для этой системы при следующем обновлении.

## Cross-References

*Обязательна: Dependencies называет другие GDD. Таблица — машинно
проверяемый список явных ссылок этого документа на чужие механики.*

| This Document References | Target GDD | Specific Element Referenced | Nature |
|---|---|---|---|
| `coins_earned = recipe_price(recipe_id)` (Formula 2) | `design/gdd/order-recipe-system.md` | `recipe_price` formula (Formula 1) output | Data dependency |
| `score_earned` множитель `(1 + remaining_fraction)` (Formula 1) | `design/gdd/guest-ai-patience.md` | `remaining_fraction` formula (Formula 2) output | Data dependency |
| Событие Served запускает расчёт монет и очков (Core Rule 1) | `design/gdd/guest-ai-patience.md` | Served state transition / payload `(recipe_id, remaining_fraction)` | State trigger |
| Сигнал `match_ended` замораживает `match_score`, вычисляет `is_new_record` и запускает сравнение с `best_score` (Core Rule 7, States and Transitions) | `design/gdd/guest-ai-patience.md` | `match_ended` signal (Rule 9) | State trigger |
| Сигнал `match_started` сбрасывает `match_score` в Idle и `is_new_record` в `false` (States and Transitions) | `design/gdd/guest-ai-patience.md` | `match_started` signal (Rule 13) | State trigger |
| `is_new_record` читается HUD для акцента нового рекорда (Core Rule 7) | `design/gdd/hud-feedback-ui.md` | Core Rule 13, AC 26/41 | Data dependency |
| Касса полна → монеты не начисляются, очки всё равно считаются (Core Rule 4, Edge Cases) | `design/gdd/order-recipe-system.md` | Edge Cases: «если касса полна — `recipe_price` по-прежнему используется в формуле очков; монеты не начисляются — решение Till & Day Cycle» | Rule dependency |
| Served и `match_ended` в один тик — очки от Served учитываются до заморозки (Edge Cases) | `design/gdd/guest-ai-patience.md` | Rule 8 — порядок обработки тика (подачи/уходы раньше проверки конца партии) | Rule dependency |
| `remaining_fraction = 0` при Served всё равно возможен (Edge Cases) | `design/gdd/guest-ai-patience.md` | Rule 8 — «подача побеждает» при одновременном истечении терпения и подаче | Rule dependency |

## Acceptance Criteria

*С qa-lead (2026-09-28). Критерии 6 и 9 — проверка отсутствия пути
(«ни один метод не делает X»), это ближе к code-review/architecture-audit
чеку, чем к чёрному ящику; сохранены как критерии, но помечены. Критерий
33 привязан к общему бюджету кадра 16.6 мс (Godot, 60 fps) — конкретное
число для этой системы не определено нигде в проекте, как и для Guest AI
& Patience (см. её Open Question о бюджете производительности) — вынесено
в Open Questions той же формулировкой, не придумано.*

**Core Rules**

1. **GIVEN** партия идёт и Guest AI & Patience генерирует событие Served с `(recipe_id, remaining_fraction)`, **WHEN** событие поступает в систему, **THEN** вычисляются `coins_earned` и `score_earned` независимо друг от друга в рамках одного события; оба присутствуют в выходе, ни одно не зависит от значения другого (Core Rule 1).
2. **GIVEN** Served с `recipe_id = black_tea_lemon` (`recipe_price = 7`), **WHEN** вычисляется `coins_earned`, **THEN** `coins_earned = 7` ровно — без бонусов, штрафов или зависимости от `remaining_fraction` (Core Rule 2).
3. **GIVEN** Served с `recipe_id = green_tea_lemon` (`recipe_price = 7`) и `remaining_fraction = 0.4`, **WHEN** вычисляется `score_earned`, **THEN** `score_earned = round(7 × 10 × 1.4) = 98` (Core Rule 3, Formula 1).
4. **GIVEN** касса Till & Day Cycle находится в любом состоянии заполненности (в т.ч. полна), **WHEN** происходит Served, **THEN** `coins_earned` вычисляется и передаётся в Till & Day Cycle на каждое событие без исключения; система не читает и не проверяет вместимость кассы (Core Rule 4).
5. **GIVEN** касса Till & Day Cycle уже полна, **WHEN** происходит Served после этого момента (вплоть до конца партии), **THEN** `score_earned` всё равно прибавляется к `match_score` — начисление очков не блокируется состоянием кассы (Core Rule 5).
6. **GIVEN** исходный код системы, **WHEN** производится поиск публичных методов/сигналов, уменьшающих `coins_earned`, сумму кассы или `match_score`, **THEN** такой метод/путь отсутствует — система экспортирует только начисление, не списание (Core Rule 6; code-review-style проверка, не игровой сценарий).
7. **GIVEN** партия завершается сигналом `match_ended`, **WHEN** `match_score` на этот момент строго больше текущего `best_score`, **THEN** `best_score` обновляется до значения `match_score` и сохраняется локально; **AND GIVEN** `match_score` равен или меньше `best_score`, **WHEN** `match_ended`, **THEN** `best_score` не изменяется (Core Rule 7).
8. **GIVEN** `best_score` имеет сохранённое значение > 0, **WHEN** происходит старт новой партии, заполнение кассы (Full), дневной сброс кассы или переход `match_score` в Frozen с меньшим значением, **THEN** `best_score` не уменьшается и не сбрасывается ни в одном из этих случаев (Core Rule 8).
9. **GIVEN** исходный код системы и её downstream-потребителей (Progression & Upgrades, Token Integration), **WHEN** производится поиск функции, принимающей `coins_earned`/сумму кассы на входе и изменяющей `score_earned`/`match_score` на выходе (или наоборот), **THEN** такая функция отсутствует (Core Rule 9, design test Pillar 4; code-review-style проверка).

**Formula 1 — `score_earned`**

10. **GIVEN** `recipe_id = cold_tea` (`recipe_price = 2`) и `remaining_fraction = 0`, **WHEN** вычисляется `score_earned`, **THEN** `score_earned = round(2 × 10 × 1) = 20` — минимально возможное значение формулы, не 0.
11. **GIVEN** `recipe_id = black_tea` (`recipe_price = 5`) и `remaining_fraction = 0.5732`, **WHEN** вычисляется `score_earned`, **THEN** `score_earned = round(78.66) = 79` (округление half-up на нецелом промежуточном значении).
12. **GIVEN** `recipe_id = cold_tea` (`recipe_price = 2`) и `remaining_fraction = 0.025` (промежуточное значение ровно `20.5`), **WHEN** вычисляется `score_earned`, **THEN** `score_earned = 21` — округление half-up на границе `.5` идёт вверх.
13. **GIVEN** любой валидный `recipe_id` и `remaining_fraction`, **WHEN** вычисляется `score_earned`, **THEN** тип результата — целое число, без дробной части.
14. **GIVEN** `recipe_id = green_tea_lemon` (`recipe_price = 7`) и `remaining_fraction`, близкий к практическому максимуму текущей раскладки кухни (не теоретическому 1.0, недостижимому), **WHEN** вычисляется `score_earned`, **THEN** результат не превышает теоретический потолок `140` и заметно ниже него (диапазон ~115–130).

**Formula 2 — `coins_earned`**

15. **GIVEN** `recipe_id = cold_tea` (минимальная цена в таблице), **WHEN** вычисляется `coins_earned`, **THEN** `coins_earned = 2` — минимум диапазона `[2, 7]`.
16. **GIVEN** `recipe_id = black_tea_lemon` или `green_tea_lemon` (максимальная цена в таблице), **WHEN** вычисляется `coins_earned`, **THEN** `coins_earned = 7` — максимум диапазона `[2, 7]`.
17. **GIVEN** каждый из пяти `recipe_id`, **WHEN** вычисляется `coins_earned` для каждого, **THEN** результат точно совпадает с `recipe_price(recipe_id)` без округления.

**Edge Cases**

18. **GIVEN** касса Till & Day Cycle полна, **WHEN** гость подан (Served), **THEN** `coins_earned` вычисляется и передаётся в Till & Day Cycle как обычно, **AND** `score_earned` прибавляется к `match_score` в том же тике без задержки или блокировки.
19. **GIVEN** гость подан ровно в тот тик, когда истёк бы лимит его терпения (`remaining_fraction = 0` на момент Served), **WHEN** вычисляется `score_earned`, **THEN** результат равен `recipe_price × 10` и никогда не равен 0.
20. **GIVEN** два и более гостя поданы в один и тот же тик, **WHEN** оба события обрабатываются в любом порядке, **THEN** итоговый `match_score` после тика равен сумме индивидуальных `score_earned` — результат не зависит от порядка обработки.
21. **GIVEN** третий потерянный гость истекает в тот же тик, в который другой гость подан (Served), **WHEN** тик обрабатывается, **THEN** `score_earned` от Served добавляется к `match_score` до перехода в Frozen.
22. **GIVEN** партия завершилась без единого Served (три страйка до первой подачи), **WHEN** приходит `match_ended`, **THEN** `match_score = 0` и переходит Idle → Frozen, **AND** `best_score` не понижается, **AND** `is_new_record = false`.
23. **GIVEN** это первая партия за всё время игры (сохранённого `best_score` не существует), **WHEN** партия завершается с `match_score = N > 0`, **THEN** `best_score` устанавливается в `N`.
24. **GIVEN** medium-рецепт (`recipe_price = 5`) подан с `remaining_fraction = 1.0` (`score_earned = 100`) и в той же партии complex-рецепт (`recipe_price = 7`) подан на грани ухода гостя с `remaining_fraction = 0` (`score_earned = 70`), **WHEN** сравниваются два значения, **THEN** medium даёт больше очков, чем complex — ожидаемое поведение формулы при `remaining_fraction > 0.4`, не дефект.

**States and Transitions**

25. **GIVEN** партия только началась, **WHEN** ещё не было ни одного Served, **THEN** `match_score` в состоянии Idle со значением `0`.
26. **GIVEN** `match_score` в Idle, **WHEN** происходит первое Served, **THEN** `match_score` переходит в Accumulating и увеличивается на `score_earned` этого события.
27. **GIVEN** `match_score` в Accumulating, **WHEN** приходит `match_ended`, **THEN** `match_score` переходит в Frozen и больше не увеличивается ничем в этой партии.
28. **GIVEN** `match_score` в Frozen, **WHEN** HUD или итоговый экран читают значение, **THEN** возвращается зафиксированное значение, идентичное моменту `match_ended`.
29. **GIVEN** `match_score` в Frozen, **WHEN** начинается следующая партия, **THEN** `match_score` переходит обратно в Idle со значением `0`.
30. **GIVEN** `best_score` в Held, **WHEN** `match_score` переходит в Frozen со значением строго больше текущего `best_score`, **THEN** `best_score` обновляется в этот момент — и только в этот момент.
31. **GIVEN** `best_score` в Held, **WHEN** происходит любое событие вне перехода `match_score` в Frozen (Served, старт партии, заполнение или дневной сброс кассы, Progression & Upgrades), **THEN** `best_score` не изменяется этим событием.
32. **GIVEN** приложение закрывается или теряет соединение до `match_ended`, **WHEN** партия не завершилась штатно, **THEN** промежуточный `match_score` не сохраняется, и `best_score` не повышается этой незавершённой партией.

**`is_new_record`** *(добавлено 2026-09-29 batch-fix, S4)*

35. **[Logic]** **GIVEN** `best_score = 900`, **WHEN** партия завершается `match_ended` с `match_score = 950`, **THEN** `is_new_record = true` и `best_score = 950`; **AND GIVEN** `match_score = 900` (равенство) или `850`, **THEN** `is_new_record = false`, `best_score = 900`; **AND GIVEN** первая партия за всё время (сохранённого `best_score` нет) и `match_score = 120`, **THEN** `is_new_record = true`; **AND WHEN** затем приходит `match_started`, **THEN** `is_new_record = false`.

**Производительность**

33. **GIVEN** событие Served поступает во время активной сессии, **WHEN** система вычисляет `coins_earned` и `score_earned` синхронно на это событие, **THEN** вычисление не создаёт заметного пропуска кадра в общем бюджете 16.6 мс (60 fps, Godot); точное число мс для этой системы не зафиксировано — см. Open Questions (тот же паттерн, что и нерешённый бюджет Guest AI & Patience).

**No hardcoded values**

34. **GIVEN** data-файл/ресурс с `score_multiplier_base`, **WHEN** просматривается код, реализующий Formula 1, **THEN** значение читается из data file по ключу, а не задано числовым литералом `10` внутри функции.

## Open Questions

| Question | Owner | Deadline | Resolution |
|---|---|---|---|
| Конкретный бюджет мс на вычисление `coins_earned`/`score_earned` за событие Served (в рамках общего кадрового бюджета 16.6 мс) — не зафиксирован нигде в проекте, как и для Guest AI & Patience | technical-director | perf-ADR до Vertical Slice | **Решено ADR-0007 (2026-09-30, Proposed):** строка «Currency / Till / SaveStore check» — ≤ 0,05 мс avg на кадр (p99 0,20 мс, только отчёт); запись `localStorage` при изменении ≤ 2,0 мс |
| Нужен ли отдельный сегмент/лига в Leaderboard & Leagues для игроков с ускорением баристы (Alpha `speed_multiplier`), раз оно косвенно повышает `remaining_fraction` на подаче и даёт измеримое конкурентное преимущество в очках (economy-designer, Edge Cases) | economy-designer / creative-director | при проектировании Leaderboard & Leagues (Alpha, когда лиги появляются) | — |
| Пересечение очков medium/complex при `remaining_fraction > 0.4` (AC 24) — принять как окончательный баланс или скорректировать таблицу цен (2/5/5/7/7) после реальных данных плейтеста | economy-designer | `/balance-check` до Alpha, вместе с уже открытыми вопросами `order-recipe-system.md` | — |
| Какая система/ADR владеет файлом локального сохранения `best_score` — MVP не включает Backend & Persistence (Vertical Slice), но личный рекорд должен переживать перезапуск игры уже в MVP | technical-director | до конца MVP-реализации этой системы | **Решено ADR-0005 (2026-09-30):** хранилищем владеет `SaveStore` (Foundation), ключом `currency.best_score` — эта система через свой `SaveScope`; на web — `localStorage` |
