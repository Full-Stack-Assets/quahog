## GameInterfaces.gd
## Base classes that replace C# interfaces for Project QUAHOG.
##
## Godot 4 GDScript does not have interface contracts; instead we use:
##  - Concrete base classes with virtual methods (override in subclasses).
##  - Duck-typing patterns (documented below) for lightweight contracts.
##
## IMPORTANT: Do NOT instance IInteractable or IDamageable directly.
##            Extend them in your scene scripts.
##
## Ported from GameInterfaces.cs (Unity) to Godot 4 GDScript.

# ===========================================================================
# IInteractable — base class for all interactable world objects
# ===========================================================================
## Extend this class for any node the player can interact with (doors, NPCs,
## pickups, vehicles, ATMs, phone booths, etc.).
##
## Usage:
##   class_name MyDoor extends IInteractable
##   func interact() -> void:
##       open_door()
##   func get_interact_prompt() -> String:
##       return "Open Door"
class_name IInteractable extends Node

## Called when the player triggers interaction (presses the interact action).
## Override this in your subclass with the object's interaction logic.
func interact() -> void:
	push_warning("[IInteractable] interact() not implemented on %s." % name)


## Returns the HUD prompt string shown when the player is in range.
## Override to provide a context-appropriate label.
func get_interact_prompt() -> String:
	return "Interact"


## Optional: called every frame while the player is in the interaction trigger.
## Override to show/update a range indicator, highlight shader, etc.
func on_player_in_range(_player: Node) -> void:
	pass


## Optional: called when the player leaves the interaction range.
func on_player_out_of_range(_player: Node) -> void:
	pass

# ===========================================================================
# IDamageable — base class for anything that can take damage
# ===========================================================================
## Extend this class for players, NPCs, vehicles, breakable props, etc.
##
## Usage:
##   class_name MyNPC extends IDamageable
##   func _ready() -> void:
##       health = 80.0
##   func take_damage(amount: float) -> void:
##       super.take_damage(amount)
##       play_hit_animation()
class_name IDamageable extends Node

## Current hit-point value.  Set in _ready() of your subclass.
var health: float = 100.0

## Maximum health.  Used by heal() to cap the value.
@export var max_health: float = 100.0

## Emitted when damage is received.
signal damaged(amount: float, new_health: float)

## Emitted when health reaches zero.
signal died()


## Reduces health by amount.  Clamps at 0 and emits died() when appropriate.
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


## Called internally when health hits zero.  Override for custom death logic.
func _on_death() -> void:
	emit_signal("died")

# ===========================================================================
# Duck-typing patterns  (no base class required)
# ===========================================================================
#
# ISaveable — implement on any Node that persists extra state in save files.
# Required methods (duck-typed, not enforced):
#
#   func get_save_data() -> Dictionary:
#       ## Return a Dictionary of all data this object needs to save.
#       return {}
#
#   func apply_save_data(data: Dictionary) -> void:
#       ## Restore state from a previously returned Dictionary.
#       pass
#
#   func get_save_id() -> String:
#       ## Return a globally unique, stable identifier for this object.
#       return ""
#
# --
#
# IPurchasable — implement on properties/businesses the player can buy.
# Required methods (duck-typed, not enforced):
#
#   func get_purchase_price() -> float:
#       ## Return the buy price in dollars.
#       return 0.0
#
#   func get_display_name() -> String:
#       ## Return the human-readable name shown in the empire UI.
#       return ""
#
#   func purchase() -> bool:
#       ## Attempt to purchase. Calls PlayerWallet.deduct() internally.
#       ## Returns true if the transaction succeeded.
#       return false
#
#   func is_owned() -> bool:
#       ## Returns true if the player has already purchased this.
#       return false
