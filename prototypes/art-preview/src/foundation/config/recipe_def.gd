# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30
extends Resource
## One drink: ordered steps (cup first, serve last), tier and price in coins.

@export var recipe_id: StringName = &""
@export var steps: Array[StringName] = []
@export var tier: StringName = &""
@export var price: int = -1
