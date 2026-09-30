# VERTICAL SLICE — tea-rush

**Статус:** in-progress (2026-09-30) — цикл играбелен, ждёт плейтеста.

> Не переносить в `src/`: при PROCEED продакшн пишется заново, слайс — справка.

## Вопрос

Почувствует ли новый игрок «я бариста, держу час пик» за ~3 минуты без
объяснений — и можно ли собрать полный цикл из GDD/UX/ADR в представительном
качестве?

## Что внутри

Сборка с нуля по GDD, `design/ux/hud.md` и ADR-0001…0007, слои из
`architecture.md`. Все числа лежат в `data/game_config.tres` и проверяются
валидатором при загрузке.
- Кухня, тап-управление, NavMesh-пути. Рецепты 2/5/5/7/7, заварка, 7 слотов, мусорка.
- Гости: терпение, онбординг 30 с, ease-in кривая. Монеты и очки, касса 250 с дневным сбросом.
- HUD: очки, 3 жизни, пауза, mute, попапы, итоги. Музыка владельца, SFX-заглушки.
- Пиксель-арт рисуется кодом из ASCII-карт (`src/presentation/pixel_art.gd`), файлов картинок нет.

## Отклонения от документов

| Что | Почему |
|---|---|
| Мусорка есть (в GDD её нет) | Решение владельца 2026-09-30: любая чашка в руках → в мусор |
| PlatformBridge — узел сцены, не autoload | Прототип не меняет настройки проекта (кроме main_scene для web) |
| localStorage-хелпер через `JavaScriptBridge.eval`, без кастомного shell | Быстрее, тот же API |
| Гости входят справа, уходят влево | Точек входа/выхода в доках нет |
| Цифры кассы в верхней полосе под очками и на итогах (HUD-GDD D9 запрещал) | Решение владельца 2026-09-30 |
| Экран старта «Начать смену» (в GDD партия стартует сразу) | Решение владельца 2026-09-30; клик = жест для звука в браузере |
| Кнопка «Новый день (демо)» на итогах | Для показа кассы без ожидания 00:00 UTC |
| SFX — синтезированные тоны | Файлов звуков нет |
| Темп старта: `guests_per_minute_start` 7 → 15, `onboarding_factor` 0.5 → 1.0, `onboarding_duration` 30 → 15 с | Плейтест владельца 2026-10-01: старт пустой, «как для детей», повторным игрокам утомительно. Гость раз в 4 с с t = 0, первые 15 с только `cold_tea`. Расходится с game-concept («редкие гости ~30 с») и GDD — ждёт пропагации |
| `medium_share_of_remaining` 0.5 → 0.75 | Плейтест владельца 2026-10-01: в середине/конце разгона слишком много простых заказов. Простых на t=90 45% → 22%, на плато 30% → 15%. Ждёт пропагации в guest-ai-patience (Formula 3) |
| Строка «Замер» на итогах, `user://playtest_log.csv` | Замер для `/balance-check till-day-cycle` 2026-10-01 (`src/debug/playtest_log.gd`) |

## Запуск

```
# редактор / десктоп (это main_scene проекта)
/Applications/Godot.app/Contents/MacOS/Godot --path .
# бот сам играет; скриншот: -- --bot --shot=/tmp/a.png --shot-at=30 [--size=360x800] [--pause-at=20]
# тесты логики
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/gdunit4_runner.gd -a res://prototypes/tea-rush-vertical-slice/tests/slice_logic_test.gd
# web-сборка (build/ в .gitignore, в ней .gdignore)
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --export-release "Web" prototypes/tea-rush-vertical-slice/build/index.html
cp assets/audio/music/music_jazz_main.ogg prototypes/tea-rush-vertical-slice/build/
```
Пресет Web: `exclude_filter` исключает addons, tests, старые прототипы и музыку (`.pck` ≈ 140 КБ).

## Выводы

*Заполнить после плейтеста (REPORT.md).*
