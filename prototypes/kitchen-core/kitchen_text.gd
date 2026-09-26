## All player-facing text of the kitchen-core prototype: key -> [English, Russian].
## Read through `_t()` in kitchen_core.gd. Guide bodies are BBCode; `{step}`
## tokens (e.g. `{cup}`) become colour swatches matching STEP_COLORS.
extends RefCounted

const LANGS := ["en", "ru"]

const TEXT := {
	# Drinks and steps
	"drink_iced": ["Iced tea", "Холодный чай"],
	"drink_black": ["Black tea", "Чёрный"],
	"drink_green": ["Green tea", "Зелёный"],
	"drink_black_lemon": ["Black tea with lemon", "Чёрный с лимоном"],
	"drink_green_lemon": ["Green tea with lemon", "Зелёный с лимоном"],
	"step_cup": ["cup", "чашка"],
	"step_iced_tea": ["iced tea", "холодный чай"],
	"step_black_leaf": ["black leaf", "чёрный лист"],
	"step_green_leaf": ["green leaf", "зелёный лист"],
	"step_water100": ["boiling water", "кипяток"],
	"step_water80": ["80° water", "вода 80°"],
	"step_lemon": ["lemon", "лимон"],

	# Station signs
	"st_cups": ["Cups", "Чашки"],
	"st_green_leaf": ["Green", "Зелёный"],
	"st_black_leaf": ["Black", "Чёрный"],
	"st_kettle100": ["100°", "100°"],
	"st_kettle80": ["80°", "80°"],
	"st_trash": ["Trash", "Мусорка"],
	"st_iced_tea": ["Iced", "Холодный"],
	"st_lemon": ["Lemon", "Лимон"],

	# In-world labels
	"price": ["%d coins", "%d мон."],
	"brewing": ["%.1f s\n%s", "%.1f с\n%s"],
	"ready": ["READY\n%s", "ГОТОВО\n%s"],

	# HUD
	"hud": [
		"Time: %d s    Left: %d/%d\nCoins: %d    Points: %d\nDifficulty: %d%%    FPS: %d",
		"Время: %d с    Ушли: %d/%d\nМонеты: %d    Очки: %d\nСложность: %d%%    FPS: %d",
	],
	"register": ["Cash box: %d / %d", "Касса: %d / %d"],
	"register_full": ["Cash box full — play for the record", "Касса полна — играй на рекорд"],
	"boost_register": ["Cash box: lv. %d (%d)", "Касса: ур. %d (%d)"],
	"boost_speed": ["Speed: lv. %d (×%.2f)", "Скорость: ур. %d (×%.2f)"],
	"lang_button": ["EN", "RU"],

	# Hints
	"guest_wants": ["Guest wants: %s (%s)", "Гость ждёт: %s (%s)"],
	"why_slot": ["Nothing to put down — hands are empty", "Нечего поставить — руки пустые"],
	"why_cups": ["Hands full — put the cup on a slot or trash it", "Руки заняты — поставь чашку в слот или выкинь"],
	"why_take_cup": ["Take a cup first", "Сначала возьми чашку"],
	"why_empty_cup": ["%s: needs an empty cup", "%s: нужна пустая чашка"],
	"why_lemon": ["Lemon: needs brewed tea", "Лимон: нужен заваренный чай"],
	"why_trash": ["Hands are empty", "Руки пустые"],
	"why_kettle_empty": ["%s: needs a cup with leaf", "%s: нужна чашка с листом"],
	"why_kettle_busy": ["%s is busy — to swap, bring a cup with leaf", "%s занят — для замены нужна чашка с листом"],
	"why_no": ["Can't do that", "Нельзя"],

	# Round over
	"round_over": [
		"Round over\n\nTime: %d s\nServed: %d\nCoins this round: %d\nPoints: %d%s\nBest: %d",
		"Партия окончена\n\nВремя: %d с\nОбслужено: %d\nМонет за партию: %d\nОчки: %d%s\nРекорд: %d",
	],
	"new_best": ["  — new best!", "  — новый рекорд!"],
	"boosts_line": ["\nBoosts: cash box lv. %d, speed lv. %d", "\nБусты: касса ур. %d, скорость ур. %d"],
	"missed": ["\nDidn't fit in the cash box: %d", "\nНе влезло в кассу: %d"],
	"closed": [
		"\n\nThe cash box is full.\nThe tea house is closed until tomorrow.",
		"\n\nКасса полна.\nЧайная закрыта до завтра.",
	],
	"closed_start": [
		"The cash box is full.\nThe tea house is closed until tomorrow.\n\nBest: %d",
		"Касса полна.\nЧайная закрыта до завтра.\n\nРекорд: %d",
	],
	"again": ["Play again", "Ещё раз"],
	"new_day": ["New day (test)", "Новый день (тест)"],

	# Guide
	"guide_title": ["How to play", "Как играть"],
	"guide_play": ["Play", "Играть"],
	"guide_continue": ["Back to the game", "Вернуться в игру"],
	"guide_body": [
		"""[b]Goal[/b]
You are the barista of a tiny tea house. Guests line up at the counter, each with an order. Make the drink and serve it before the guest runs out of patience. When [b]3 guests[/b] leave without their tea, the round is over.

[b]Controls[/b]
• [b]Tap a station[/b] — the barista walks there and uses it.
• [b]Tap a guest[/b] — the barista brings them the drink in hand.
• [b]Tap the floor[/b] — the barista just walks there.
A new tap cancels the previous one. If an action is impossible, the station blinks red and a hint appears at the top of the screen. The barista carries [b]one cup at a time[/b].

[b]Reading an order[/b]
Above each guest are the recipe (coloured squares, left to right), the price and a patience bar. The bar goes from green to red; when it runs out, the guest leaves.

[b]Stations[/b]
Each station is painted in the colour of the step it adds:
{cup} [b]Cups[/b] — take an empty cup
{iced_tea} [b]Iced[/b] — iced tea, ready at once
{green_leaf} [b]Green[/b] — green tea leaf
{black_leaf} [b]Black[/b] — black tea leaf
{water100} [b]100° kettle[/b] — boiling water, for black tea
{water80} [b]80° kettle[/b] — 80° water, for green tea
{lemon} [b]Lemon[/b] — goes into brewed tea
[b]Trash[/b] (grey) — throws away the cup in hand.

[b]Menu[/b]
Iced tea — {cup}{iced_tea} — 2 coins
Black tea — {cup}{black_leaf}{water100} — 5 coins
Green tea — {cup}{green_leaf}{water80} — 5 coins
Black tea with lemon — {cup}{black_leaf}{water100}{lemon} — 9 coins
Green tea with lemon — {cup}{green_leaf}{water80}{lemon} — 9 coins
Steps go in this order. The wrong water (black leaf in the 80° kettle) makes a drink nobody ordered — take it to the Trash and start over.

[b]Kettles[/b]
Bring a cup with leaf: the kettle takes it and brews for a few seconds while your hands are free. Ready tea waits as long as needed, but the kettle stays busy until you pick it up. Holding a new cup with leaf, one tap takes the ready tea and puts the new cup in. If it is still brewing, the barista waits at the kettle.

[b]Slots[/b]
The flat pads on the counters hold one cup each. A tap puts your cup down, picks one up, or swaps the cup in hand with the one on the slot. Use slots to work on several orders at once.

[b]Serving[/b]
Any guest who ordered exactly what you hold can be served. The faster you serve, the more points you get.

[b]The round gets harder[/b]
From the first second until 3:00: more guests, less patience, more lemon orders.

[b]Coins and the cash box[/b]
Each served drink pays its price in coins into the cash box — the yellow bar at the top. The cash box holds a limited amount per day. When it is full, coins stop coming in, but you can finish the round for points; after that the tea house is closed until tomorrow.

[b]Points and the record[/b]
Points = price × 10 × (1 + share of patience left). Two quick cheap orders or one expensive one — your call. Beat your best!

[b]Boosts (test)[/b]
The panel at the bottom stands in for future paid upgrades: a bigger cash box and a faster barista (walking and brewing). [b]New day (test)[/b] on the round-over screen empties the cash box.

The [b]?[/b] button at the top right opens this guide again; the button next to it switches the language.""",
		"""[b]Цель[/b]
Ты — бариста маленькой чайной. Гости выстраиваются у стойки, у каждого свой заказ. Приготовь напиток и подай его, пока у гостя не кончилось терпение. Когда [b]3 гостя[/b] уйдут без чая, партия окончена.

[b]Управление[/b]
• [b]Тап по станции[/b] — бариста идёт к ней и использует её.
• [b]Тап по гостю[/b] — бариста несёт ему напиток из рук.
• [b]Тап по полу[/b] — бариста просто идёт туда.
Новый тап отменяет предыдущий. Если действие невозможно, станция мигает красным, а вверху экрана появляется подсказка. Бариста носит [b]одну чашку за раз[/b].

[b]Как читать заказ[/b]
Над каждым гостем — рецепт (цветные квадраты слева направо), цена и полоска терпения. Полоска идёт от зелёного к красному; когда она кончится, гость уйдёт.

[b]Станции[/b]
Каждая станция окрашена в цвет шага, который она добавляет:
{cup} [b]Чашки[/b] — взять пустую чашку
{iced_tea} [b]Холодный[/b] — холодный чай, готов сразу
{green_leaf} [b]Зелёный[/b] — лист зелёного чая
{black_leaf} [b]Чёрный[/b] — лист чёрного чая
{water100} [b]Чайник 100°[/b] — кипяток, для чёрного чая
{water80} [b]Чайник 80°[/b] — вода 80°, для зелёного чая
{lemon} [b]Лимон[/b] — добавляется в заваренный чай
[b]Мусорка[/b] (серая) — выбрасывает чашку из рук.

[b]Меню[/b]
Холодный чай — {cup}{iced_tea} — 2 монеты
Чёрный — {cup}{black_leaf}{water100} — 5 монет
Зелёный — {cup}{green_leaf}{water80} — 5 монет
Чёрный с лимоном — {cup}{black_leaf}{water100}{lemon} — 9 монет
Зелёный с лимоном — {cup}{green_leaf}{water80}{lemon} — 9 монет
Шаги идут именно в таком порядке. Не та вода (чёрный лист в чайнике 80°) даёт напиток, который никто не заказывал, — неси его в мусорку и начинай заново.

[b]Чайники[/b]
Принеси чашку с листом: чайник забирает её и заваривает несколько секунд, а руки свободны. Готовый чай ждёт сколько угодно, но чайник занят, пока его не заберёшь. С новой чашкой с листом в руках одним тапом забираешь готовый чай и ставишь новую. Если чай ещё заваривается, бариста ждёт у чайника.

[b]Слоты[/b]
Плоские площадки на столешницах вмещают по одной чашке. Тап ставит чашку, забирает её или меняет чашку в руках на ту, что в слоте. Слоты помогают вести несколько заказов сразу.

[b]Подача[/b]
Подать можно любому гостю, который заказал ровно то, что у тебя в руках. Чем быстрее подал, тем больше очков.

[b]Партия становится сложнее[/b]
С первой секунды и до 3:00: больше гостей, меньше терпения, больше заказов с лимоном.

[b]Монеты и касса[/b]
Каждый поданный напиток приносит свою цену в монетах в кассу — жёлтая полоска вверху. Касса вмещает ограниченную сумму в день. Когда она полна, монеты больше не идут, но партию можно доиграть ради очков; после неё чайная закрыта до завтра.

[b]Очки и рекорд[/b]
Очки = цена × 10 × (1 + доля оставшегося терпения). Два быстрых дешёвых заказа или один дорогой — решай сам. Побей свой рекорд!

[b]Бусты (тест)[/b]
Панель внизу заменяет будущие платные улучшения: касса побольше и бариста побыстрее (ходьба и заварка). [b]Новый день (тест)[/b] на экране конца партии обнуляет кассу.

Кнопка [b]?[/b] справа вверху снова открывает этот гайд; кнопка рядом переключает язык.""",
	],
}
