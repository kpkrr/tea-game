# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30
extends RefCounted
## Recipe grammar (order-recipe-system.md): prefix validity, exact match, price.

const SERVE := &"serve"

var _recipes := {}    # id -> Array[StringName] steps without serve
var _price := {}
var _tier := {}
var _by_tier := {}    # tier -> Array[StringName] ids in config order


func _init(recipe_cfg: Resource) -> void:
	for r: Resource in recipe_cfg.recipes:
		var steps: Array[StringName] = r.steps.duplicate()
		steps.erase(SERVE)
		_recipes[r.recipe_id] = steps
		_price[r.recipe_id] = r.price
		_tier[r.recipe_id] = r.tier
		_by_tier.get_or_add(r.tier, []).append(r.recipe_id)


## True iff steps + [step] is a prefix of some recipe.
func is_valid_next(steps: Array, step: StringName) -> bool:
	var n := steps.size() + 1
	for id: StringName in _recipes:
		var r: Array = _recipes[id]
		if r.size() < n or r[n - 1] != step:
			continue
		if r.slice(0, n - 1) == steps:
			return true
	return false


## Recipe whose steps (without serve) equal `steps` exactly; &"" if none.
func matches(steps: Array) -> StringName:
	for id: StringName in _recipes:
		if _recipes[id] == steps:
			return id
	return &""


func recipe_price(id: StringName) -> int:
	return _price.get(id, 0)


func recipe_tier(id: StringName) -> StringName:
	return _tier.get(id, &"")


func recipes_by_tier(tier: StringName) -> Array:
	return _by_tier.get(tier, [])


## Steps shown on an order token: everything except cup and serve.
func token_steps(id: StringName) -> Array:
	return _recipes.get(id, []).slice(1)


func recipe_ids() -> Array:
	return _recipes.keys()
