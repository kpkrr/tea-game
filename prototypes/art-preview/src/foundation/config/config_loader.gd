# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30
extends RefCounted
## Loads the root GameConfig and runs the validator (ADR-0004).
## Returns {config, errors}; any error means the match must not start.

const GameConfigScript := preload("game_config.gd")
const ConfigValidator := preload("config_validator.gd")


static func load_config(path: String) -> Dictionary:
	var res := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)
	if res == null or res.get_script() != GameConfigScript:
		return {"config": null, "errors": [ConfigValidator.err(path, &"missing", "config file missing or wrong type")]}
	return {"config": res, "errors": ConfigValidator.validate(res)}
