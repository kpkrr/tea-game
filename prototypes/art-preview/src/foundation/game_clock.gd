# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30
extends RefCounted
## Single source of game time (ADR-0003). `hidden` = paused for any reason,
## `frozen` = match ended. sim_dt drives the world, ui_dt drives overlays.

signal running_changed(running: bool)

var t: float:
	get: return _t
var sim_dt: float:
	get: return _sim_dt
var ui_dt: float:
	get: return _ui_dt

var _max_step: float
var _t := 0.0
var _sim_dt := 0.0
var _ui_dt := 0.0
var _hidden := false
var _frozen := false
var _discard_next := false


func _init(max_step_delta: float) -> void:
	_max_step = max_step_delta


## Advances by one frame; returns the clamped simulation delta (0 when stopped).
func advance(real_delta: float) -> float:
	var step := minf(maxf(real_delta, 0.0), _max_step)
	_ui_dt = 0.0 if _hidden else step
	if _hidden or _frozen:
		_sim_dt = 0.0
	elif _discard_next:
		_discard_next = false
		_sim_dt = 0.0
	else:
		_sim_dt = step
		_t += step
	return _sim_dt


func pause() -> void:
	_set_flags(true, _frozen)


## Resumes; the first frame after resume carries no time (hidden time is dropped).
func resume() -> void:
	if _hidden:
		_discard_next = true
	_set_flags(false, _frozen)


func freeze() -> void:
	_set_flags(_hidden, true)


func reset() -> void:
	_t = 0.0
	_set_flags(_hidden, false)


func is_running() -> bool:
	return not _hidden and not _frozen


func _set_flags(hidden: bool, frozen: bool) -> void:
	var was := is_running()
	_hidden = hidden
	_frozen = frozen
	if was != is_running():
		running_changed.emit(is_running())
