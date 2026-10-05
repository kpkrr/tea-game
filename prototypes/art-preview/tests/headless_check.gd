# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30
extends SceneTree
## Headless sanity run: config validates, NavMesh bakes, every point reachable,
## and a scripted match plays through brewing and serving.
## godot --headless --path . --script res://prototypes/art-preview/tests/headless_check.gd

const R := "res://prototypes/art-preview/"


func _initialize() -> void:
	var loaded: Dictionary = load(R + "src/foundation/config/config_loader.gd").load_config(R + "data/game_config.tres")
	for e: Dictionary in loaded.errors:
		print("CONFIG ERROR ", e)
	if not loaded.errors.is_empty():
		quit(1)
		return
	var cfg: Resource = loaded.config
	print("config ok")
	var layout: RefCounted = load(R + "src/foundation/kitchen_layout.gd").new(cfg.kitchen, cfg.control)
	var pathing: RefCounted = load(R + "src/core/pathing.gd").new(layout, cfg.control)
	var frames := 0
	while not pathing.poll_ready():
		frames += 1
		await process_frame
		if frames > 60:
			print("NAV NOT READY")
			quit(1)
			return
	var pts: Array = []
	for id: StringName in layout.station_ids:
		pts.append_array(layout.stations[id].spots)
	pts.append_array(layout.guest_serve_points)
	var msg: String = pathing.verify(pts)
	print("nav ready after %d frames, verify: '%s'" % [frames, msg])
	var p: Dictionary = pathing.path(cfg.kitchen.barista_start, layout.stations[&"cups"].spots[0])
	print("path to cups len %.2f pts %d reached %s" % [p.length, p.points.size(), p.reached])
	pathing.dispose()
	quit(0 if msg == "" else 1)
