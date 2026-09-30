# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30
extends Resource
## Root config: one sub-resource per owner (ADR-0004). Immutable after load.

@export var view: Resource
@export var kitchen: Resource
@export var control: Resource
@export var recipes: Resource
@export var brewing: Resource
@export var guest: Resource
@export var difficulty: Resource
@export var currency: Resource
@export var till: Resource
@export var hud: Resource
@export var audio: Resource
