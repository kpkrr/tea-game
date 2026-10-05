# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30
extends SceneTree
## Loads every slice script so parse errors surface in one run.


func _initialize() -> void:
	var bad := 0
	for f: String in _scan("res://prototypes/art-preview/src"):
		if load(f) == null:
			bad += 1
	print("parse_all: %d failing" % bad)
	quit(bad)


func _scan(dir: String) -> Array[String]:
	var out: Array[String] = []
	for d: String in DirAccess.get_directories_at(dir):
		out.append_array(_scan(dir + "/" + d))
	for f: String in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir + "/" + f)
	return out
