# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30
extends RefCounted
## Placeholder-plus pixel art drawn from ASCII maps and simple shapes at runtime,
## so the slice ships no image files. "." = transparent; letters index PALETTE.
## Every texture is cached by name + parameters.

const INK := Color(0.24, 0.16, 0.12)
const PALETTE := {
	"k": INK,
	"w": Color(1.0, 1.0, 1.0),
	"s": Color(0.98, 0.81, 0.67),
	"e": Color(0.2, 0.13, 0.1),
	"h": Color(0.45, 0.28, 0.16),
	"a": Color(0.36, 0.64, 0.46),
	"p": Color(0.34, 0.36, 0.5),
	"m": Color(0.72, 0.3, 0.3),
	"y": Color(1.0, 0.87, 0.3),
	"o": Color(0.86, 0.66, 0.16),
	"g": Color(0.62, 0.64, 0.66),
	"d": Color(0.45, 0.47, 0.5),
	"b": Color(0.55, 0.36, 0.22),
	"B": Color(0.42, 0.26, 0.15),
	"c": Color(0.93, 0.87, 0.74),
}

## Recipe step colours: identities only, never UI state (hud.md colour rule).
const STEP_COLORS := {
	&"cup": Color(0.97, 0.97, 0.95),
	&"iced_tea": Color(0.66, 0.45, 0.88),
	&"leaf_green": Color(0.45, 0.76, 0.38),
	&"leaf_black": Color(0.66, 0.38, 0.16),
	&"water_100": Color(0.92, 0.36, 0.32),
	&"water_80": Color(0.36, 0.58, 0.95),
	&"lemon": Color(0.98, 0.86, 0.3),
}
const TEA_COLORS := {
	&"leaf_black": Color(0.76, 0.43, 0.17),
	&"leaf_green": Color(0.68, 0.78, 0.36),
}
const MURKY := Color(0.47, 0.42, 0.35)
const PARCHMENT := Color(0.99, 0.95, 0.85)

## 12x20 person. Face rows 3..6 and leg rows 17..19 are swapped per pose.
const PERSON := [
	"...kkkkkk...",
	"..khhhhhhk..",
	"..khhhhhhk..",
	"..khsssshk..",
	"..ksessesk..",
	"..kssssssk..",
	"...kssssk...",
	"..kwwkkwwk..",
	".kwaaaaaawk.",
	".kwaaaaaawk.",
	"ksaaaaaaaask",
	"ksaaaaaaaask",
	".kaaaaaaaak.",
	".kaaaaaaaak.",
	".kaaaaaaaak.",
	"..kppppppk..",
	"..kppkkppk..",
	"..kpk..kpk..",
	"..kpk..kpk..",
	".kkkk..kkkk.",
]
const FACES := {
	"normal": ["..khsssshk..", "..ksessesk..", "..kssssssk..", "...kssssk..."],
	"happy": ["..khsssshk..", "..kskssksk..", "..kssmmssk..", "...kssssk..."],
	"angry": ["..kskssksk..", "..ksessesk..", "..ksskkssk..", "...kssssk..."],
	"sad": ["..khsssshk..", "..ksessesk..", "..ksskkssk..", "...kssssk..."],
	"back": ["..khhhhhhk..", "..khhhhhhk..", "..khhhhhhk..", "...khhhhk..."],
}
const LEGS := {
	0: ["..kpk..kpk..", "..kpk..kpk..", ".kkkk..kkkk."],
	1: ["...kpkkpk...", "...kpkkpk...", "..kkkkkkkk.."],
}

## 8x8 ink glyphs drawn on the round step jewels.
const GLYPHS := {
	&"cup": ["........", ".kkkkk..", ".kwwwkkk", ".kwwwk.k", ".kwwwkkk", ".kwwwk..", "..kkk...", "........"],
	&"iced_tea": [".k....k.", ".k.ww.k.", ".k.ww.k.", ".k....k.", ".k....k.", "..k..k..", "..kkkk..", "........"],
	&"leaf_green": ["......kk", "....kkwk", "...kwwwk", "..kwwkwk", ".kwwkwk.", ".kwkwk..", ".kkkk...", "k......."],
	&"leaf_black": ["..kkkk..", ".k....k.", "k..kk..k", "k.k..k.k", "k.k.k..k", ".k..k.k.", "..kk..k.", "......kk"],
	&"water_100": [".k.k.k..", ".k.k.k..", "...k....", "..kwk...", ".kwwwk..", ".kwwwk..", "..kkk...", "........"],
	&"water_80": ["...k....", "...k....", "...k....", "..kwk...", ".kwwwk..", ".kwwwk..", "..kkk...", "........"],
	&"lemon": ["........", "........", ".kkkkkk.", "kwkwwkwk", ".kwkkwk.", "..kwwk..", "...kk...", "........"],
}

const KETTLE := [
	"..............",
	"......kk......",
	".....kmmk.....",
	"...kkkkkkkk...",
	"..kmlmmmmmmk.k",
	"..kmlmmmmmmkkm",
	"kkkmlmmmmmmkm.",
	"k.kmlmmmmmmk..",
	"k.kmmmmmmmmk..",
	"kkkmmmmmmmmk..",
	"..kmmmmmmmmk..",
	"...kkkkkkkk...",
]
const TILL := [
	"................",
	"..kkkkkkkkkkkk..",
	"..kyyyyyyyyyyk..",
	"..kyykkkkkkyyk..",
	"..kyykwwwwkyyk..",
	"..kyykkkkkkyyk..",
	"kkkkkkkkkkkkkkkk",
	"kbbbbbbbbbbbbbbk",
	"kbbBbbBbbBbbBbbk",
	"kbbbbbbbbbbbbbbk",
	"kBBBBBBBkBBBBBBk",
	"kkkkkkkkkkkkkkkk",
]
const ICONS := {
	"trash": ["............", "....kkkk....", ".kkkkkkkkkk.", ".kggggggggk.", "..kggggggk..", "..kgkggkgk..", "..kgkggkgk..", "..kgkggkgk..", "..kgkggkgk..", "..kggggggk..", "..kkkkkkkk..", "............"],
	"coin": ["..kkkk..", ".kyyyyk.", "kyywyyok", "kywyyyok", "kyyyyyok", "kyyyyook", ".kooook.", "..kkkk.."],
	"star": ["...kk...", "...kk...", "kkkwwkkk", ".kwwwwk.", "..kwwk..", ".kwkkwk.", ".kk..kk.", "........"],
	"heart": [".kk.kk..", "kmmkmmk.", "kmwmmmk.", "kmmmmmk.", ".kmmmk..", "..kmk...", "...k....", "........"],
	"heart_off": [".kk.kk..", "k..k..k.", "k.....k.", "k.....k.", ".k...k..", "..k.k...", "...k....", "........"],
	"pause": ["............", "............", "...kkk.kkk..", "...kwk.kwk..", "...kwk.kwk..", "...kwk.kwk..", "...kwk.kwk..", "...kwk.kwk..", "...kwk.kwk..", "...kkk.kkk..", "............", "............"],
	"play": ["............", "...kk.......", "...kwkk.....", "...kwwwkk...", "...kwwwwwkk.", "...kwwwwwwk.", "...kwwwwwkk.", "...kwwwkk...", "...kwkk.....", "...kk.......", "............", "............"],
	"sound": ["............", ".....k......", "....kk...k..", "..kkwk.k..k.", ".kwwwk..k.k.", ".kwwwk..k.k.", ".kwwwk..k.k.", "..kkwk.k..k.", "....kk...k..", ".....k......", "............", "............"],
	"muted": ["............", ".....k......", "....kk......", "..kkwk.k...k", ".kwwwk..k.k.", ".kwwwk...k..", ".kwwwk..k.k.", "..kkwk.k...k", "....kk......", ".....k......", "............", "............"],
	"check": [".......k", "......kk", ".....kwk", "k...kwk.", "kk.kwk..", "kwkwk...", ".kwk....", "..k....."],
	"cross": ["kk....kk", "kwk..kwk", ".kwkkwk.", "..kwwk..", "..kwwk..", ".kwkkwk.", "kwk..kwk", "kk....kk"],
	"warn": ["..kkkk..", ".kwwwwk.", "kwwkkwwk", "kwwkkwwk", "kwwkkwwk", "kwwwwwwk", ".kwkkwk.", "..kkkk.."],
	"urgent": ["k.k..k.k", ".kwk.kwk", "kwwkkwwk", ".kk..kk.", ".kk..kk.", "kwwkkwwk", ".kwk.kwk", "k.k..k.k"],
	"puff": ["..dddd..", ".dggggd.", "dggddggd", "dgddddgd", "dgggdggd", ".dggggd.", "..dddd..", "........"],
	"steam1": ["........", "........", "........", "........", "...w....", "..w.....", "...w....", "........"],
	"steam2": ["........", "....w...", "...w.w..", "..w.w...", "...w.w..", "..w.w...", "...w....", "........"],
	"steam3": ["..w..w..", ".w..w...", "..w..w..", ".w.ww.w.", "..w..w..", ".w..w.w.", "..w.w...", "...w...."],
}

static var _cache := {}


static func _from_map(rows: Array, palette: Dictionary) -> Image:
	var w := 0
	for r: String in rows:
		w = maxi(w, r.length())
	var img := Image.create_empty(w, rows.size(), false, Image.FORMAT_RGBA8)
	for y in rows.size():
		var r: String = rows[y]
		for x in r.length():
			if r[x] in palette:
				img.set_pixel(x, y, palette[r[x]])
	return img


static func _tex(key: String, img: Image) -> ImageTexture:
	var t := ImageTexture.create_from_image(img)
	_cache[key] = t
	return t


## Person sprite. pose: normal/happy/angry/sad/back; legs 0/1; colours override shirt & hair.
static func person(pose: String, legs: int, apron: Color, hair: Color, shirt: Color) -> ImageTexture:
	var key := "person|%s|%d|%s|%s|%s" % [pose, legs, apron, hair, shirt]
	if key in _cache:
		return _cache[key]
	var rows := PERSON.duplicate()
	for i in 4:
		rows[3 + i] = FACES[pose][i]
	for i in 3:
		rows[17 + i] = LEGS[legs][i]
	var pal := PALETTE.duplicate()
	pal["a"] = apron
	pal["h"] = hair
	pal["w"] = shirt
	return _tex(key, _from_map(rows, pal))


static func icon(name: String) -> ImageTexture:
	var key := "icon|" + name
	if key in _cache:
		return _cache[key]
	return _tex(key, _from_map(ICONS[name], PALETTE))


static func kettle(tint: Color) -> ImageTexture:
	var key := "kettle|%s" % tint
	if key in _cache:
		return _cache[key]
	var pal := PALETTE.duplicate()
	pal["m"] = tint
	pal["l"] = tint.lightened(0.45)
	return _tex(key, _from_map(KETTLE, pal))


static func till() -> ImageTexture:
	if "till" in _cache:
		return _cache["till"]
	return _tex("till", _from_map(TILL, PALETTE))


## Round step jewel: step colour disc, ink outline, ink glyph. 12x12.
static func jewel_image(step: StringName, desaturate := false) -> Image:
	var img := Image.create_empty(12, 12, false, Image.FORMAT_RGBA8)
	var col: Color = STEP_COLORS.get(step, Color.GRAY)
	if desaturate:
		col = Color(col.get_luminance(), col.get_luminance(), col.get_luminance()).lerp(MURKY, 0.3)
	for y in 12:
		for x in 12:
			var d := Vector2(x + 0.5 - 6.0, y + 0.5 - 6.0).length()
			if d <= 5.0:
				img.set_pixel(x, y, col)
			elif d <= 6.0:
				img.set_pixel(x, y, INK)
	var glyph: Array = GLYPHS.get(step, [])
	var light := col.lightened(0.65) if not desaturate else Color(0.85, 0.85, 0.85)
	for y in glyph.size():
		for x in glyph[y].length():
			match glyph[y][x]:
				"k": img.set_pixel(2 + x, 2 + y, INK)
				"w": img.set_pixel(2 + x, 2 + y, light)
	return img


static func jewel(step: StringName) -> ImageTexture:
	var key := "jewel|" + step
	if key in _cache:
		return _cache[key]
	return _tex(key, jewel_image(step))


## A row of jewels with 1 px gaps on a transparent strip; ruined = greyed + cross.
static func jewel_row(steps: Array, ruined := false) -> ImageTexture:
	var key := "row|%s|%s" % [steps, ruined]
	if key in _cache:
		return _cache[key]
	var n := maxi(steps.size(), 1)
	var img := Image.create_empty(n * 13 - 1, 12, false, Image.FORMAT_RGBA8)
	for i in steps.size():
		img.blit_rect(jewel_image(steps[i], ruined), Rect2i(0, 0, 12, 12), Vector2i(i * 13, 0))
	if ruined:
		var cross := _from_map(ICONS["cross"], PALETTE)
		img.blend_rect(cross, Rect2i(0, 0, 8, 8), Vector2i((img.get_width() - 8) / 2, 2))
	return _tex(key, img)


## Order token (hud.md E5): parchment plate, jewels in brew order, coin icon slot
## on the right for the price digits (a separate Label3D).
static func order_plate(token_steps: Array) -> ImageTexture:
	var key := "plate|%s" % [token_steps]
	if key in _cache:
		return _cache[key]
	var n := token_steps.size()
	var w := 4 + n * 13 + 10 + 16
	var h := 18
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var corner := (x < 2 or x >= w - 2) and (y < 2 or y >= h - 2)
			if corner:
				continue
			var edge := x == 0 or y == 0 or x == w - 1 or y == h - 1
			img.set_pixel(x, y, INK if edge else PARCHMENT)
	for i in n:
		img.blit_rect(jewel_image(token_steps[i]), Rect2i(0, 0, 12, 12), Vector2i(3 + i * 13, 3))
	img.blend_rect(_from_map(ICONS["coin"], PALETTE), Rect2i(0, 0, 8, 8), Vector2i(4 + n * 13, 5))
	return _tex(key, img)


## Cup seen from the side, 12x12: liquid shows the contents, lemon wedge on the
## rim, ruined = murky fill. Empty cup = white.
static func cup(steps: Array, ruined: bool) -> ImageTexture:
	var key := "cup|%s|%s" % [steps, ruined]
	if key in _cache:
		return _cache[key]
	var liquid := Color(1, 1, 1)
	var leaf: Variant = null
	for s: StringName in steps:
		if s == &"iced_tea":
			liquid = STEP_COLORS[&"iced_tea"].lightened(0.2)
		elif s in TEA_COLORS:
			leaf = s
			liquid = Color(1, 1, 1).lerp(STEP_COLORS[s], 0.35)
		elif String(s).begins_with("water_") and leaf != null:
			liquid = TEA_COLORS[leaf]
	if ruined:
		liquid = MURKY
	var rows := [
		"............",
		"............",
		".kkkkkkkk...",
		".kLLLLLLkkk.",
		".kLLLLLLk.k.",
		".kwwwwwwk.k.",
		".kwwwwwwkkk.",
		".kwwwwwwk...",
		"..kwwwwk....",
		"..kkkkkk....",
		"............",
		"............",
	]
	var pal := PALETTE.duplicate()
	pal["L"] = liquid
	pal["w"] = MURKY.lightened(0.15) if ruined else Color(1, 1, 1)
	var img := _from_map(rows, pal)
	if &"lemon" in steps:
		img.set_pixel(7, 0, INK)
		img.set_pixel(8, 0, INK)
		img.set_pixel(6, 1, INK)
		img.set_pixel(7, 1, PALETTE["y"])
		img.set_pixel(8, 1, PALETTE["y"])
		img.set_pixel(9, 1, INK)
	return _tex(key, img)


## Neutral patience ring: cream arc on a dark rim, wiped clockwise from the top.
static func ring(fraction: float, size := 16) -> ImageTexture:
	var steps := 24
	var q := int(ceil(clampf(fraction, 0.0, 1.0) * steps))
	var key := "ring|%d|%d" % [q, size]
	if key in _cache:
		return _cache[key]
	var img := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var c := size / 2.0
	var r_out := c - 0.5
	var r_in := c - 3.5
	for y in size:
		for x in size:
			var v := Vector2(x + 0.5 - c, y + 0.5 - c)
			var d := v.length()
			if d > r_out + 0.5 or d < r_in - 1.0:
				continue
			var ang := fposmod(atan2(v.x, -v.y), TAU) / TAU
			var filled := ang <= float(q) / steps
			if d > r_out - 0.5 or d < r_in:
				img.set_pixel(x, y, INK)
			else:
				img.set_pixel(x, y, Color(0.98, 0.96, 0.9) if filled else Color(0.55, 0.52, 0.48))
	return _tex(key, img)


## Soft blob shadow.
static func blob(w: int, h: int) -> ImageTexture:
	var key := "blob|%d|%d" % [w, h]
	if key in _cache:
		return _cache[key]
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var v := Vector2((x + 0.5) / w * 2.0 - 1.0, (y + 0.5) / h * 2.0 - 1.0)
			var d := v.length()
			if d < 1.0:
				img.set_pixel(x, y, Color(0.3, 0.2, 0.12, 0.28 * (1.0 - d * d)))
	return _tex(key, img)


## Selection bracket (hud.md E13): four ink-and-white corners, no hue.
static func bracket(size := 20) -> ImageTexture:
	var key := "bracket|%d" % size
	if key in _cache:
		return _cache[key]
	var img := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var arm := size / 3
	for i in arm:
		for corner: Vector2i in [Vector2i(0, 0), Vector2i(size - 1, 0), Vector2i(0, size - 1), Vector2i(size - 1, size - 1)]:
			var sx := 1 if corner.x == 0 else -1
			var sy := 1 if corner.y == 0 else -1
			for t in 3:
				var col := INK if t != 1 else Color(1, 1, 1)
				img.set_pixel(corner.x + sx * i, corner.y + sy * t, col)
				img.set_pixel(corner.x + sx * t, corner.y + sy * i, col)
	return _tex(key, img)


## Flat destination ring for floor taps.
static func floor_ring(size := 24) -> ImageTexture:
	var key := "floor_ring|%d" % size
	if key in _cache:
		return _cache[key]
	var img := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var c := size / 2.0
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5 - c, y + 0.5 - c).length()
			if d <= c - 0.5 and d >= c - 2.5:
				img.set_pixel(x, y, Color(1, 1, 1))
			elif d <= c - 2.5 and d >= c - 4.0:
				img.set_pixel(x, y, INK)
	return _tex(key, img)
