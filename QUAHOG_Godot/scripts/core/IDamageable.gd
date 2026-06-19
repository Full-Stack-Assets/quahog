## IDamageable.gd
## Base class for anything that can take damage — players, NPCs, vehicles,
## breakable props, etc. Extend it in your scene scripts.
##
## Usage:
##   class_name MyNPC extends IDamageable
##   func _ready() -> void:
##       health = 80.0
##   func take_damage(amount: float) -> void:
##       super.take_damage(amount)
##       play_hit_animation()
##
## Ported from GameInterfaces.cs (Unity) to Godot 4 GDScript.
class_name IDamageable extends Node

## Current hit-point value. Set in _ready() of your subclass.
var health: float = 100.0

## Maximum health. Used by heal() to cap the value.
@export var max_health: float = 100.0

## Emitted when damage is received.
signal damaged(amount: float, new_health: float)

## Emitted when health reaches zero.
signal died()


## Reduces health by amount. Clamps at 0 and emits died() when appropriate.
## Override to add armour, resistances, death animations, etc.
func take_damage(amount: float) -> void:
	if amount <= 0.0:
		return
	health = maxf(health - amount, 0.0)
	emit_signal("damaged", amount, health)
	if health <= 0.0:
		_on_death()


## Restores health by amount, clamped to max_health.
func heal(amount: float) -> void:
	if amount <= 0.0:
		return
	health = minf(health + amount, max_health)


## Returns true if health > 0.
func is_alive() -> bool:
	return health > 0.0


## Returns health as a normalised 0.0–1.0 fraction.
func get_health_fraction() -> float:
	if max_health <= 0.0:
		return 0.0
	return health / max_health


## Called internally when health hits zero. Override for custom death logic.
func _on_death() -> void:
	emit_signal("died")
