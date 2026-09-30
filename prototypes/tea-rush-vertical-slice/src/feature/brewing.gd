# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30
extends RefCounted
## One cup in hand, two kettles, seven slots (brewing-crafting-mechanic.md).
## Cup = {steps: Array[StringName], ruined: bool}. Answers DO / WAIT / REFUSE.

signal refused(station_id: StringName)       # show lightness flash + cross
signal held_changed()
signal kettle_changed(id: StringName)
signal kettle_ready(id: StringName)
signal slot_changed(id: StringName)
signal cup_ruined()

enum Kettle { EMPTY, BREWING, READY }
enum Class { MATCH, WRONG_TEMP, EMPTY_HANDS, OTHER }
const EXECUTE := 0
const WAIT := 1
const REFUSE := 2

var held: Variant = null
var kettles := {}   # id -> {water: StringName, state: Kettle, cup, t, t_total}
var slots := {}     # id -> cup or null

var _layout: RefCounted
var _book: RefCounted
var _cfg: Resource


func _init(layout: RefCounted, book: RefCounted, brewing_cfg: Resource) -> void:
	_layout = layout
	_book = book
	_cfg = brewing_cfg
	reset()


func reset() -> void:
	held = null
	for id: StringName in _layout.kettle_ids:
		kettles[id] = {"water": _layout.station_type(id), "state": Kettle.EMPTY, "cup": null, "t": 0.0, "t_total": 0.0}
		kettle_changed.emit(id)
	for id: StringName in _layout.slot_ids:
		slots[id] = null
		slot_changed.emit(id)
	held_changed.emit()


func t_brew() -> float:
	return _cfg.t_brew_base / _cfg.speed_multiplier


func step(dt: float) -> void:
	for id: StringName in kettles:
		var k: Dictionary = kettles[id]
		if k.state == Kettle.BREWING:
			k.t = maxf(k.t - dt, 0.0)
			if k.t <= 0.0:
				k.state = Kettle.READY
				kettle_changed.emit(id)
				kettle_ready.emit(id)


## Pre-walk validity. False = tap rejected (refusal feedback where the GDD wants it).
func is_valid(id: StringName) -> bool:
	var reply := _decide(id)
	if reply.response == REFUSE and reply.feedback:
		refused.emit(id)
	return reply.response != REFUSE


## Called every Holding step at the station.
func offer(id: StringName) -> int:
	var reply := _decide(id)
	match reply.response:
		REFUSE:
			refused.emit(id)
		EXECUTE:
			_execute(id)
	return reply.response


## A successful serve takes the cup out of the hands (GuestSim only).
func consume_held_cup() -> void:
	held = null
	held_changed.emit()


func held_match() -> StringName:
	if held == null or held.ruined:
		return &""
	return _book.matches(held.steps)


func _decide(id: StringName) -> Dictionary:
	var type: StringName = _layout.station_type(id)
	if type == &"slot":
		return {"response": EXECUTE, "feedback": false}
	if type == &"trash":
		return {"response": EXECUTE if held != null else REFUSE, "feedback": false}
	if type == &"cup":
		if held == null or held.ruined:
			return {"response": EXECUTE, "feedback": false}
		return {"response": REFUSE, "feedback": false}
	if id in kettles:
		return _decide_kettle(kettles[id])
	# Ingredient stations: iced tea, leaves, lemon.
	if held == null:
		return {"response": REFUSE, "feedback": false}
	if held.ruined or not _book.is_valid_next(held.steps, type):
		return {"response": REFUSE, "feedback": true}
	return {"response": EXECUTE, "feedback": false}


func _decide_kettle(k: Dictionary) -> Dictionary:
	var c := _classify(k.water)
	match k.state:
		Kettle.EMPTY:
			if c == Class.MATCH or c == Class.WRONG_TEMP:
				return {"response": EXECUTE, "feedback": false}
			return {"response": REFUSE, "feedback": c == Class.OTHER}
		Kettle.BREWING:
			if c == Class.MATCH or c == Class.EMPTY_HANDS:
				return {"response": WAIT, "feedback": false}
			return {"response": REFUSE, "feedback": true}
		_:
			if c == Class.MATCH or c == Class.EMPTY_HANDS:
				return {"response": EXECUTE, "feedback": false}
			return {"response": REFUSE, "feedback": true}


func _classify(water: StringName) -> Class:
	if held == null:
		return Class.EMPTY_HANDS
	if held.ruined:
		return Class.OTHER
	if _book.is_valid_next(held.steps, water):
		return Class.MATCH
	if not held.steps.is_empty() and String(held.steps[-1]).begins_with("leaf_") and held.steps.size() == 2:
		return Class.WRONG_TEMP
	return Class.OTHER


func _execute(id: StringName) -> void:
	var type: StringName = _layout.station_type(id)
	if type == &"slot":
		var on_slot: Variant = slots[id]
		slots[id] = held
		held = on_slot
		slot_changed.emit(id)
		held_changed.emit()
		return
	if type == &"trash":
		held = null
		held_changed.emit()
		return
	if type == &"cup":
		held = _new_cup()
		held_changed.emit()
		return
	if id in kettles:
		var k: Dictionary = kettles[id]
		var c := _classify(k.water)
		if c == Class.WRONG_TEMP:
			held.ruined = true
			held_changed.emit()
			cup_ruined.emit()
			return
		var ready_cup: Variant = k.cup if k.state == Kettle.READY else null
		if c == Class.MATCH:
			var cup: Dictionary = held
			cup.steps.append(k.water)
			k.cup = cup
			k.state = Kettle.BREWING
			k.t = t_brew()
			k.t_total = k.t
		else:
			k.cup = null
			k.state = Kettle.EMPTY
		held = ready_cup
		kettle_changed.emit(id)
		held_changed.emit()
		return
	held.steps.append(type)
	held_changed.emit()


func _new_cup() -> Dictionary:
	var steps: Array[StringName] = [&"cup"]
	return {"steps": steps, "ruined": false}
