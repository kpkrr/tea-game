# Player Stats

> **Status**: Designed (pending review)
> **Author**: Yan + systems-designer (автономный режим)
> **Last Updated**: 2026-10-01
> **Implements Pillar**: Pillar 3 (Одна касса, одно правило — серия дней), Pillar 4 (Монеты за работу, очки за мастерство — статистика мастерства)
> **Source**: `design/ux/game-flow.md` F5, M1, M14 (решения владельца 2026-10-01)
> **Creative Director Review (CD-GDD-ALIGN)**: пропущен — Lean mode

---

## Overview

Player Stats — маленькая Meta-система, которая копит локальную статистику
игрока для экрана **Records**, строки статуса главного меню и строк итогов
партии: сколько смен сыграно, сколько чашек подано, сколько дней касса была
заполнена, пять последних смен и **серия дней** подряд с заполненной
кассой. Она только слушает события других систем и пишет свои счётчики в
scope сохранения `stats` (ADR-0005). На игру она не влияет: ни одна
формула партии не читает эти значения. В MVP всё хранится локально;
серверный учёт — Backend & Persistence (Vertical Slice).

## Player Fantasy

«Я вижу, как расту». Achiever открывает Records и видит свой путь: рекорд,
последние смены, сотни поданных чашек и огонёк серии `🔥 5`, который
жалко потерять. Серия превращает дневную цель «наполнить кассу» в привычку:
заходишь не только за рекордом, но и чтобы не сгорел огонёк.

## Detailed Rules

1. **Владение.** Система — единственный писатель ключей `stats.*` (scope
   `stats`, ADR-0005 §1). Остальные читают через её публичные геттеры.
2. **`shifts_played`** +1 на каждый `match_ended` (Guest AI Rule 9), любой
   причины (`lost` и `quit`).
3. **`cups_served`**: на каждый Served система увеличивает счётчик партии
   `match_cups`; на `match_ended` прибавляет его к `cups_served` и
   отдаёт для строки итогов «N cups served» (`game-flow.md` M1).
   `match_cups` сбрасывается на `match_started`, не сохраняется.
4. **`recent`** — массив не длиннее `recent_max` (5) записей
   `{score, coins, new_record}`, новые — в начале. На `match_ended`
   добавляется запись: `score = match_score`, `coins = match_coins_added`
   (Till), `new_record = is_new_record` (Currency; Currency обрабатывает
   `match_ended` раньше — порядок фиксирует ADR-0003). Лишние с конца
   отбрасываются. Хранится как JSON-строка (ADR-0005 допускает только
   примитивы).
5. **`days_filled`** +1 на каждое событие `day_filled(day_index)` (Till
   Rule 10) — «всего дней с полной кассой».
6. **Серия дней** — на `day_filled(d)` (Formula 1):
   - `streak_last_day == d − 1` → `streak += 1`;
   - `streak_last_day == d` → без изменений (повтор не бывает, но
     защищаемся);
   - иначе → `streak = 1`;
   - затем `streak_last_day = d`, `best_streak = max(best_streak, streak)`.
7. **Показ серии** (`displayed_streak`, Formula 2): если последний
   заполненный день — сегодня или вчера, показывается `streak`; иначе 0
   («сгорела»). Хранимое `streak` не трогается до следующего `day_filled`,
   где правило 6 начнёт серию заново с 1.
8. **Серия выросла в этой партии**: флаг `streak_grew_this_match`
   (сбрасывается на `match_started`, ставится в правиле 6, когда `streak`
   стал больше) — для строки итогов «🔥 N-day streak!» (`game-flow.md` M14).
9. **Часы** — инжектируемые (как в Till). Перевод часов устройства
   может накрутить или сломать серию; в MVP это принимается (всё
   локально, как касса). Если `day_index` текущего момента **меньше**
   `streak_last_day` (часы отведены назад) — `displayed_streak = streak`,
   запись не меняется, одна строка в debug-лог.

### States and Transitions

У системы нет состояний, кроме хранимых значений; события обрабатываются
синхронно в тике, где они пришли.

### Interactions with Other Systems

| Система | Направление | Интерфейс |
|---|---|---|
| Guest AI & Patience | Upstream | `match_started` (сброс `match_cups`, флага серии), Served (`match_cups` +1), `match_ended(reason)` |
| Currency: Coins & Score | Upstream | `match_score`, `is_new_record` на `match_ended` |
| Till & Day Cycle | Upstream | `day_filled(day_index)` (Till Rule 10), `match_coins_added`, Formula 5 `day_index` |
| SaveStore (ADR-0005) | Downstream | Scope `stats`: ключи ниже |
| UI (`design/ux/game-flow.md`) | Downstream | Геттеры для Records, строки меню `🔥 N`, строк итогов «N cups served», «🔥 N-day streak!» |

**Ключи сохранения** (дополнение к ADR-0005 §6, аддитивно, `schema_version` 1):

| Ключ | Тип | Default |
|---|---|---|
| `stats.shifts_played` | int | 0 |
| `stats.cups_served` | int | 0 |
| `stats.days_filled` | int | 0 |
| `stats.recent` | string (JSON-массив) | `"[]"` |
| `stats.streak` | int | 0 |
| `stats.streak_last_day` | int | −1 |
| `stats.best_streak` | int | 0 |

Невалидное значение ключа → default этого ключа + одна запись в лог
(правило ADR-0005 §3). Невалидный JSON в `recent` → `[]`.

## Formulas

### Formula 1 — обновление серии на `day_filled(d)`

```
if streak_last_day == d - 1:  streak = streak + 1
elif streak_last_day == d:    streak = streak
else:                         streak = 1
streak_last_day = d
best_streak = max(best_streak, streak)
```

| Variable | Type | Range | Source |
|---|---|---|---|
| `d` | int | ≥ 0 | `day_filled`, Till Formula 5 |
| `streak`, `best_streak` | int | ≥ 0 | сохранение |
| `streak_last_day` | int | ≥ −1 | сохранение (−1 = ни разу) |

**Example:** заполнения в дни 100, 101, 102 → `streak` 1, 2, 3; следующее —
в день 105 → `streak = 1`, `best_streak = 3`.

### Formula 2 — `displayed_streak`

```
today = day_index(now)            # Till Formula 5
displayed_streak = streak  if streak_last_day >= today - 1  else 0
```

**Example:** последнее заполнение в день 102; сегодня 103 → показывается 3
(серию ещё можно продлить, меню подсказывает «fill the till to keep it»);
сегодня 104 → 0.

## Edge Cases

- **Первый запуск**: все счётчики 0, `recent = []`, `streak_last_day = −1` → Records показывает пустое состояние (`game-flow.md` States).
- **`match_ended(quit)` без единого Served**: `shifts_played` +1, в `recent` запись `{0, 0, false}` — выход засчитывается как смена (как рекорд в Currency).
- **Касса заполнилась в последнем тике партии** (`day_filled` и `match_ended` в одном тике): серия обновлена в этом же тике, флаг `streak_grew_this_match` виден на итогах.
- **Полночь UTC посреди партии**: `day_filled` несёт `day_index` момента заполнения; серия считается по нему, а не по началу партии.
- **Хранилище недоступно** (`SaveStore.persistent = false`): статистика живёт только в памяти до закрытия вкладки; меню показывает строку «Progress can't be saved» (`game-flow.md`).
- **Часы отведены назад**: см. правило 9.

## Dependencies

- **Hard upstream**: Guest AI & Patience (`match_started`, Served, `match_ended`), Currency (`match_score`, `is_new_record`), Till & Day Cycle (`day_filled`, `match_coins_added`, `day_index`).
- **Hard downstream**: экраны вне партии (`design/ux/game-flow.md`: Records, меню, итоги).
- **Architecture**: ADR-0005 amendment (scope `stats`, ключи выше), ADR-0003 (порядок обработки `match_ended`: Currency → Till → Player Stats → HUD).
- **Future**: Backend & Persistence перенесёт счётчики и серию на сервер; Leaderboard может читать `best_streak`.

## Tuning Knobs

| Knob | Default | Range | Effect |
|---|---|---|---|
| `recent_max` | 5 | 1–10 | Сколько последних смен в Records |

Правило серии (день = граница сброса кассы) — не ручка: оно наследуется от
`daily_reset_time_utc` Till, чтобы «день» у кассы и серии был одним и тем же.

## Acceptance Criteria

1. **[Logic]** **GIVEN** `shifts_played = 3`, **WHEN** `match_ended(lost)` и затем в другой партии `match_ended(quit)`, **THEN** `shifts_played = 5`.
2. **[Logic]** **GIVEN** 12 Served за партию и `cups_served = 100`, **WHEN** `match_ended`, **THEN** `cups_served = 112`, геттер итогов возвращает 12; на `match_started` счётчик партии = 0.
3. **[Logic]** **GIVEN** `recent` из 5 записей, **WHEN** `match_ended` с `match_score = 900`, `match_coins_added = 40`, `is_new_record = true`, **THEN** первая запись `{900, 40, true}`, длина 5, самая старая отброшена.
4. **[Logic]** **GIVEN** `streak_last_day = 101`, `streak = 2`, **WHEN** `day_filled(102)`, **THEN** `streak = 3`, `best_streak ≥ 3`, `streak_grew_this_match = true`.
5. **[Logic]** **GIVEN** `streak_last_day = 101`, `streak = 5`, `best_streak = 5`, **WHEN** `day_filled(104)`, **THEN** `streak = 1`, `best_streak = 5`.
6. **[Logic]** **GIVEN** `streak_last_day = 102`, `streak = 3`, инжектируемые часы дают сегодня 103 / 104, **WHEN** запрашивается `displayed_streak`, **THEN** 3 / 0.
7. **[Logic]** **GIVEN** `stats.recent = "not json"` в сохранении, **WHEN** загрузка, **THEN** `recent = []`, остальные ключи сохранены, одна запись в лог.
8. **[Logic]** **GIVEN** `day_filled(d)`, **WHEN** обработан, **THEN** `days_filled` +1.
9. **[UI]** **GIVEN** 0 смен / 3 смены / серия 4, **WHEN** открыт Records, **THEN** пустое состояние / 3 строки / «Current streak 4»; скриншоты в `production/qa/evidence/`.

## Open Questions

| # | Вопрос | Владелец | Когда |
|---|---|---|---|
| 1 | Отдельная система-владелец или счётчики пишут Currency/Till сами (`game-flow.md` OQ 13) — решить в архитектуре; этот GDD описывает поведение независимо от размещения кода | lead-programmer | ADR-0005 amendment |
| 2 | Нужна ли «заморозка» серии (пропуск одного дня без сгорания) — снизила бы фрустрацию без push-уведомлений | game-designer | После первого плейтеста серии |
