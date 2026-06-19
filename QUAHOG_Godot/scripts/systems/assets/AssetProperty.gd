# AssetProperty.gd
# Represents a purchasable world property (dock, building, lot, etc.).
# Implements the IInteractable duck-type via get_interact_prompt() / interact().
# Autoloads referenced: PlayerWallet, TimeOfDayClock, EmpireDatabaseManager (optional).
extends Node3D

class_name AssetProperty

# ── Exports ────────────────────────────────────────────────────────────────
@export var data: AssetPropertyData

# ── Signals ────────────────────────────────────────────────────────────────
signal purchased(property: Node)
signal yield_collected(property: Node)

# ── Lifecycle ──────────────────────────────────────────────────────────────
func _ready() -> void:
	if not data:
		push_warning("AssetProperty '%s': no AssetPropertyData assigned." % name)
		return
	# Connect to the global midnight signal so yield is processed each in-game day.
	if TimeOfDayClock.has_signal("midnight"):
		TimeOfDayClock.midnight.connect(_on_midnight)

# ── Public API ─────────────────────────────────────────────────────────────

## Attempt to purchase this property from the player's wallet.
func purchase() -> void:
	if data == null:
		push_warning("AssetProperty.purchase(): data is null on '%s'." % name)
		return
	if data.is_owned:
		push_warning("AssetProperty.purchase(): '%s' is already owned." % data.display_name)
		return
	if not PlayerWallet.can_afford(data.purchase_price):
		print("AssetProperty: cannot afford '%s' (price: %.2f)" % [data.display_name, data.purchase_price])
		return

	PlayerWallet.deduct(data.purchase_price)
	data.is_owned = true
	data.day_acquired = TimeOfDayClock.current_day if TimeOfDayClock.has_method("get") else 0

	# Persist to empire database if available.
	if has_node("/root/EmpireDatabaseManager"):
		EmpireDatabaseManager.record_purchase(data)

	emit_signal("purchased", self)
	print("AssetProperty: purchased '%s' for $%.2f" % [data.display_name, data.purchase_price])

## Collect the daily yield for this property and add it to the player's wallet.
## Returns the yield amount (0.0 if not owned).
func collect_daily_yield() -> float:
	if data == null or not data.is_owned:
		return 0.0
	var amount: float = data.daily_yield
	PlayerWallet.add_funds(amount)
	emit_signal("yield_collected", self)
	print("AssetProperty: collected $%.2f from '%s'" % [amount, data.display_name])
	return amount

## IInteractable duck-type — returns text shown in the HUD interaction prompt.
func get_interact_prompt() -> String:
	if data == null:
		return "Examine"
	if data.is_owned:
		return "Manage %s" % data.display_name
	return "Purchase %s — $%.0f" % [data.display_name, data.purchase_price]

## IInteractable duck-type — called when the player presses the interact key.
func interact() -> void:
	purchase()

# ── Private ────────────────────────────────────────────────────────────────
func _on_midnight() -> void:
	collect_daily_yield()
