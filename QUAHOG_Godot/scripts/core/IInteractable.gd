## IInteractable.gd
## Base class for all interactable world objects (doors, NPCs, pickups,
## vehicles, ATMs, phone booths, etc.). Extend it in your scene scripts.
##
## Usage:
##   class_name MyDoor extends IInteractable
##   func interact() -> void:
##       open_door()
##   func get_interact_prompt() -> String:
##       return "Open Door"
##
## Ported from GameInterfaces.cs (Unity) to Godot 4 GDScript.
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
