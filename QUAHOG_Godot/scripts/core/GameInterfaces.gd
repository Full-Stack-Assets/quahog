## GameInterfaces.gd
## Documentation hub for the "interface" contracts used across Project QUAHOG.
##
## Godot 4 GDScript does not have C#-style interfaces, and a single .gd file may
## declare only ONE global class. So the base classes that replace C# interfaces
## live in their own files:
##
##   - IInteractable  → res://scripts/core/IInteractable.gd
##       Base class for interactable world objects (doors, NPCs, pickups...).
##   - IDamageable    → res://scripts/core/IDamageable.gd
##       Base class for anything that can take damage.
##
## Both are global classes (via class_name), so just `extends IInteractable` or
## `extends IDamageable` from anywhere — no preload needed.
##
## Ported from GameInterfaces.cs (Unity) to Godot 4 GDScript.
##
## ===========================================================================
## Duck-typing patterns  (no base class required)
## ===========================================================================
##
## ISaveable — implement on any Node that persists extra state in save files.
## Required methods (duck-typed, not enforced):
##
##   func get_save_data() -> Dictionary:
##       ## Return a Dictionary of all data this object needs to save.
##       return {}
##
##   func apply_save_data(data: Dictionary) -> void:
##       ## Restore state from a previously returned Dictionary.
##       pass
##
##   func get_save_id() -> String:
##       ## Return a globally unique, stable identifier for this object.
##       return ""
##
## --
##
## IPurchasable — implement on properties/businesses the player can buy.
## Required methods (duck-typed, not enforced):
##
##   func get_purchase_price() -> float:
##       ## Return the buy price in dollars.
##       return 0.0
##
##   func get_display_name() -> String:
##       ## Return the human-readable name shown in the empire UI.
##       return ""
##
##   func purchase() -> bool:
##       ## Attempt to purchase. Calls PlayerWallet.deduct() internally.
##       ## Returns true if the transaction succeeded.
##       return false
##
##   func is_owned() -> bool:
##       ## Returns true if the player has already purchased this.
##       return false
