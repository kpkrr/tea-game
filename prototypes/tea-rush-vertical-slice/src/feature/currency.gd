# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30
extends RefCounted
## Coins (to the till) and score (to the record) never cross (currency-coins-score.md).

signal coins_earned(amount: int)
signal score_earned(amount: int)

var match_score: int:
	get: return _match_score
var best_score: int:
	get: return _best_score
var is_new_record: bool:
	get: return _is_new_record

var _book: RefCounted
var _cfg: Resource
var _scope: RefCounted
var _match_score := 0
var _best_score := 0
var _is_new_record := false


func _init(book: RefCounted, currency_cfg: Resource, scope: RefCounted) -> void:
	_book = book
	_cfg = currency_cfg
	_scope = scope
	scope.declare_int("best_score", 0, 0, 1_000_000_000)
	_best_score = scope.read_int("best_score")


static func score_for(price: int, base: int, remaining_fraction: float) -> int:
	return floori(price * base * (1.0 + remaining_fraction) + 0.5)


func on_served(recipe_id: StringName, remaining_fraction: float) -> void:
	var price: int = _book.recipe_price(recipe_id)
	var score := score_for(price, _cfg.score_multiplier_base, remaining_fraction)
	_match_score += score
	coins_earned.emit(price)
	score_earned.emit(score)


func on_match_started() -> void:
	_match_score = 0
	_is_new_record = false


func on_match_ended() -> void:
	_is_new_record = _match_score > _best_score
	if _is_new_record:
		_best_score = _match_score
		_scope.write_int("best_score", _best_score)
