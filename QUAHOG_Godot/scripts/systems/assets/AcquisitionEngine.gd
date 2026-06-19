# AcquisitionEngine.gd
# Handles the validation and execution of property purchase flow.
# Used by UI or other systems to safely acquire AssetProperty nodes.
# Autoloads referenced: PlayerWallet, TimeOfDayClock, MissionManager, RevenueManager.
extends Node

class_name AcquisitionEngine

# ── Signals ────────────────────────────────────────────────────────────────
signal acquisition_success()

# ── Public API ─────────────────────────────────────────────────────────────

## Returns true if the player meets all conditions to purchase this property.
func can_purchase(property: Node) -> bool:
	if property == null:
		push_warning("AcquisitionEngine.can_purchase(): null property.")
		return false
	if not property.has_method("get") or property.data == null:
		push_warning("AcquisitionEngine.can_purchase(): property has no data.")
		return false
	if property.data.is_owned:
		return false
	if not PlayerWallet.can_afford(property.data.purchase_price):
		return false
	return true

## Executes the full purchase flow: deducts wallet, marks owned, registers with
## RevenueManager, unlocks any linked mission, and emits acquisition_success.
## Returns true on success, false otherwise.
func process_purchase(property: Node) -> bool:
	if not can_purchase(property):
		print("AcquisitionEngine: purchase conditions not met for '%s'." % (property.name if property else "null"))
		return false

	# Deduct cost and mark ownership.
	var price: float = property.data.purchase_price
	PlayerWallet.deduct(price)
	property.data.is_owned = true
	property.data.day_acquired = TimeOfDayClock.current_day if "current_day" in TimeOfDayClock else 0

	# Register with revenue tracking.
	RevenueManager.register_property(property)

	# Unlock linked story mission if applicable.
	unlock_linked_mission(property)

	emit_signal("acquisition_success")
	print("AcquisitionEngine: acquired '%s' for $%.2f" % [property.data.display_name, price])
	return true

## Unlocks the mission linked to this property, if one is set and not yet available.
func unlock_linked_mission(property: Node) -> void:
	if property == null or property.data == null:
		return
	var mid: String = property.data.linked_mission_id
	if mid == "":
		return
	if MissionManager.has_method("unlock_mission"):
		MissionManager.unlock_mission(mid)
		print("AcquisitionEngine: unlocked mission '%s' via property '%s'." % [mid, property.data.display_name])
