# ART PREVIEW - NOT FOR PRODUCTION
# UI redesign s7 port (design/ux/ui-redesign-s7-port.md). Mirrors the Pillow mockup
# (tools/ui_mockup/ui/mock12.py chain) so the game draws the same pixels the owner approved.
extends RefCounted
## Static image helpers shared by the HUD bar, order plaques and kitchen signs.
## Every texture is pre-resized (Lanczos, like the mockup) to DEVICE pixels and drawn
## 1:1 with nearest filtering at device-pixel-snapped positions.

const DIR := "res://prototypes/art-preview/art/ui_s7/"
const INK := Color8(43, 29, 26)
const MINT := Color8(23, 112, 95)
const GOLD_INK := Color8(138, 94, 0)
const STEP_COL := {
	&"cup": Color8(245, 241, 232), &"lemon": Color8(247, 210, 58), &"leaf_green": Color8(124, 203, 78),
	&"water_80": Color8(88, 166, 238), &"iced_tea": Color8(168, 130, 219), &"water_100": Color8(232, 66, 79),
	&"leaf_black": Color8(176, 96, 42),
}
const RECIPE_ORDER: Array[StringName] = [&"cup", &"leaf_black", &"leaf_green", &"iced_tea", &"water_100", &"water_80", &"lemon"]
const CUP_BASE_H := 343   # cup_empty.png height: every mug state is normalised by it

static var _img := {}
static var _font: FontFile


static func font() -> FontFile:
	if _font == null:
		_font = load(DIR + "Jersey10.ttf")
	return _font


## Source art (RGBA8, transparent RGB bled from neighbours so Lanczos leaves no dark fringe).
static func img(name: String) -> Image:
	if not name in _img:
		var tex: Texture2D = load(DIR + name + ".png")
		var im := tex.get_image()
		if im.is_compressed():
			im.decompress()
		im.convert(Image.FORMAT_RGBA8)
		im.fix_alpha_edges()
		_img[name] = im
	return _img[name]


## Python's round() (banker's) so sizes match the mockup to the pixel.
static func pyround(v: float) -> int:
	var f := floorf(v)
	var d := v - f
	if is_equal_approx(d, 0.5):
		return int(f) if int(f) % 2 == 0 else int(f) + 1
	return int(roundf(v))


static func resized(im: Image, w: int, h: int) -> Image:
	var out := im.duplicate() as Image
	out.resize(maxi(1, w), maxi(1, h), Image.INTERPOLATE_LANCZOS)
	return out


static func rescale(im: Image, s: float) -> Image:
	return resized(im, maxi(1, pyround(im.get_width() * s)), maxi(1, pyround(im.get_height() * s)))


## mock.fit: scale to height h px, width keeps the aspect.
static func fit(im: Image, h: int) -> Image:
	return resized(im, maxi(1, pyround(float(im.get_width()) * h / im.get_height())), h)


static func crop(im: Image, x0: int, y0: int, x1: int, y1: int) -> Image:
	return im.get_region(Rect2i(x0, y0, x1 - x0, y1 - y0))


static func paste(dst: Image, src: Image, x: int, y: int) -> void:
	dst.blend_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), Vector2i(x, y))


static func blank(w: int, h: int) -> Image:
	return Image.create_empty(maxi(1, w), maxi(1, h), false, Image.FORMAT_RGBA8)


static func tex(im: Image) -> ImageTexture:
	return ImageTexture.create_from_image(im)


## mock4.nine_h: end caps scaled, the middle tiled (not stretched).
static func nine_h(im: Image, w: int, h: int, cap: int, s: float) -> Image:
	var c := maxi(1, pyround(cap * s))
	var W := im.get_width()
	var out := blank(w, h)
	paste(out, resized(crop(im, 0, 0, cap, im.get_height()), c, h), 0, 0)
	var mid := resized(crop(im, cap, 0, W - cap, im.get_height()), maxi(1, pyround((W - 2 * cap) * s)), h)
	var x := c
	while x < w - c:
		var cw := mini(mid.get_width(), w - c - x)
		paste(out, crop(mid, 0, 0, cw, h), x, 0)
		x += mid.get_width()
	paste(out, resized(crop(im, W - cap, 0, W, im.get_height()), c, h), w - c, 0)
	return out


## Final drink of a step list (order plaques, held cup, slot cups).
static func cup_state(steps: Array, ruined := false) -> String:
	if ruined:
		return "ruined"
	if &"iced_tea" in steps:
		return "cold_tea"
	var black := &"leaf_black" in steps
	var green := &"leaf_green" in steps
	if not black and not green:
		return "empty"
	var water := &"water_100" in steps or &"water_80" in steps
	if not water:
		return "leaf_black" if black else "leaf_green"
	return ("black_tea" if black else "green_tea") + ("_lemon" if &"lemon" in steps else "")


## Mug image normalised so the empty mug is h_px tall (contents/steam don't change the mug size).
static func cup_img(state: String, h_px: int) -> Image:
	return rescale(img("cup_" + state), float(h_px) / CUP_BASE_H)


## mock12.sticker (art/ui_s7/sticker_<step>.png, exported from the mockup code): 14x14 art px,
## upscaled by u (nearest). Tilt is applied by the caller (node rotation, nearest).
static func sticker(step: StringName, u: int) -> Image:
	var im := img("sticker_" + String(step)).duplicate() as Image
	im.resize(im.get_width() * u, im.get_height() * u, Image.INTERPOLATE_NEAREST)
	return im


## White silhouette of an image (shadows: modulate it).
static func silhouette(im: Image) -> Image:
	var out := im.duplicate() as Image
	for y in out.get_height():
		for x in out.get_width():
			var a := out.get_pixel(x, y).a
			out.set_pixel(x, y, Color(1, 1, 1, a))
	return out


## Baseline y for a string whose vertical middle (PIL anchor "m") sits at mid_y.
static func baseline_for_middle(mid_y: float, size: int) -> float:
	var f := font()
	return mid_y + (f.get_ascent(size) - f.get_descent(size)) / 2.0
