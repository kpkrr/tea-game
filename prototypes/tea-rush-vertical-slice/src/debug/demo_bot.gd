# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30
extends RefCounted
## Dev aid (`-- --bot`): plays through the same tap API a player uses, so
## screenshots and soak runs show a live kitchen. Not smart on purpose.

var _d: Node


func _init(director: Node) -> void:
	_d = director


func step() -> void:
	var barista: RefCounted = _d._barista
	if barista.state != 0 or _d._lifecycle.state != 1:
		return
	var brewing: RefCounted = _d._brewing
	var held: Variant = brewing.held
	var guests: Array = _d._guests.guests
	if held != null and held.ruined:
		return _tap_station_type(&"cup")
	# Serve anyone whose order the cup already matches.
	var m: StringName = brewing.held_match()
	for i in guests.size():
		if guests[i] != null and m != &"" and guests[i].recipe == m:
			barista.tap({"kind": &"guest", "id": i})
			return
	if held == null:
		for id: StringName in brewing.kettles:
			if brewing.kettles[id].state != 0:
				barista.tap({"kind": &"station", "id": id})
				return
		if guests.any(func(g: Variant) -> bool: return g != null):
			_tap_station_type(&"cup")
		return
	var book: RefCounted = _d._book
	for g: Variant in guests:
		if g == null:
			continue
		var steps: Array = book._recipes[g.recipe]
		if steps.size() > held.steps.size() and steps.slice(0, held.steps.size()) == held.steps:
			return _tap_station_type(steps[held.steps.size()])
	# Nobody wants this cup: park it.
	for id: StringName in brewing.slots:
		if brewing.slots[id] == null:
			barista.tap({"kind": &"station", "id": id})
			return


func _tap_station_type(type: StringName) -> void:
	var layout: RefCounted = _d._layout
	for id: StringName in layout.station_ids:
		if layout.stations[id].type == type:
			_d._barista.tap({"kind": &"station", "id": id})
			return
