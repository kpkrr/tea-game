# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30
extends Node
## The only autoload (ADR-0001): browser visibility, reduced motion, safe area,
## boot state and asset URLs. Plain web only — no Telegram detection.

signal safe_area_changed(rect: Rect2)
signal visibility_changed(visible: bool)
signal ready_reached()
signal reduced_motion_changed(enabled: bool)

enum BootState { LOADING, READY, FAILED }

## Stand-in for the HTML shell helper (ADR-0005): localStorage access with every
## call guarded, so private mode degrades to in-memory saves.
const SAVE_JS := """
window.teaRushSave = {
  available: (function () { try { var k = '__tr'; localStorage.setItem(k, '1'); localStorage.removeItem(k); return true; } catch (e) { return false; } })(),
  read: function () { try { return localStorage.getItem('tea_rush.save'); } catch (e) { return null; } },
  write: function (s) { try { localStorage.setItem('tea_rush.save', s); return true; } catch (e) { return false; } },
  backup: function (s) { try { localStorage.setItem('tea_rush.save.corrupt', s); } catch (e) {} }
};
"""

var _state := BootState.LOADING
var _visible := true
var _reduced_motion := false
var _safe_dirty := true
var _safe := Rect2()
# JS callbacks must stay referenced for as long as the page lives.
var _vis_cb: JavaScriptObject
var _hide_cb: JavaScriptObject
var _rm_cb: JavaScriptObject
var _rm_query: JavaScriptObject


func _ready() -> void:
	process_priority = -200
	get_viewport().size_changed.connect(func() -> void: _safe_dirty = true)
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval(SAVE_JS, true)
	var doc := JavaScriptBridge.get_interface("document")
	var win := JavaScriptBridge.get_interface("window")
	_visible = str(doc.visibilityState) == "visible"
	_vis_cb = JavaScriptBridge.create_callback(_on_js_visibility)
	_hide_cb = JavaScriptBridge.create_callback(_on_js_pagehide)
	doc.addEventListener("visibilitychange", _vis_cb)
	win.addEventListener("pagehide", _hide_cb)
	_rm_query = win.matchMedia("(prefers-reduced-motion: reduce)")
	_reduced_motion = bool(_rm_query.matches)
	_rm_cb = JavaScriptBridge.create_callback(_on_js_reduced_motion)
	_rm_query.addEventListener("change", _rm_cb)


func _process(_delta: float) -> void:
	if _safe_dirty:
		_safe_dirty = false
		# No Telegram insets in the web MVP: the safe area is the visible viewport (dp).
		_safe = get_viewport().get_visible_rect()
		safe_area_changed.emit(_safe)


func get_safe_area() -> Rect2:
	return get_viewport().get_visible_rect()


func is_visible() -> bool:
	return _visible


func prefers_reduced_motion() -> bool:
	return _reduced_motion


func is_booted() -> bool:
	return _state == BootState.READY


func mark_boot_complete() -> void:
	if _state != BootState.LOADING:
		return
	_state = BootState.READY
	ready_reached.emit()


## Replaces the game with a static error message (all builds).
func fail_boot(message: String) -> void:
	if _state == BootState.FAILED:
		return
	_state = BootState.FAILED
	push_error("boot failed: " + message)
	var layer := CanvasLayer.new()
	layer.layer = 100
	var bg := ColorRect.new()
	bg.color = Color(0.97, 0.93, 0.86)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg)
	var label := Label.new()
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color(0.24, 0.16, 0.12))
	label.text = "Не удалось загрузить игру — обновите страницу"
	if OS.is_debug_build():
		label.text += "\n\n" + message
	bg.add_child(label)
	add_child(layer)


## Absolute URL of a file placed next to index.html; "" off-web.
func asset_url(file_name: String) -> String:
	if not OS.has_feature("web"):
		return ""
	return str(JavaScriptBridge.eval("new URL(%s, document.baseURI).href" % JSON.stringify(file_name), true))


func _on_js_visibility(_args: Array) -> void:
	var doc := JavaScriptBridge.get_interface("document")
	_set_visible(str(doc.visibilityState) == "visible")


func _on_js_pagehide(_args: Array) -> void:
	_set_visible(false)


func _on_js_reduced_motion(_args: Array) -> void:
	var v := bool(_rm_query.matches)
	if v != _reduced_motion:
		_reduced_motion = v
		reduced_motion_changed.emit(v)


func _set_visible(v: bool) -> void:
	if v == _visible:
		return
	_visible = v
	visibility_changed.emit(v)
