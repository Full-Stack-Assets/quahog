# RevenueManager.gd  (Autoload)
# Tracks all owned AssetProperty nodes and orchestrates nightly yield payouts.
# Register via Project → Autoload as "RevenueManager".
extends Node

# ── Signals ────────────────────────────────────────────────────────────────
signal daily_yield(total: float)
signal property_yield(property: Node)

# ── State ──────────────────────────────────────────────────────────────────
var owned_properties: Array = []

# ── Lifecycle ──────────────────────────────────────────────────────────────
func _ready() -> void:
	# Process yield every in-game midnight.
	if TimeOfDayClock.has_signal("midnight"):
		TimeOfDayClock.midnight.connect(process_daily_yield)

# ── Public API ─────────────────────────────────────────────────────────────

## Add a property to the managed pool. Safe to call multiple times.
func register_property(p: Node) -> void:
	if p == null:
		push_warning("RevenueManager.register_property(): null node passed.")
		return
	if owned_properties.has(p):
		return
	owned_properties.append(p)
	print("RevenueManager: registered '%s'" % p.name)

## Remove a property from the managed pool.
func unregister_property(p: Node) -> void:
	owned_properties.erase(p)
	print("RevenueManager: unregistered '%s'" % p.name)

## Called automatically at midnight; iterates properties and collects yield.
func process_daily_yield() -> void:
	var total: float = 0.0
	for p in owned_properties:
		if p == null or not is_instance_valid(p):
			continue
		if p.has_method("collect_daily_yield"):
			var amount: float = p.collect_daily_yield()
			total += amount
			if amount > 0.0:
				emit_signal("property_yield", p)
	emit_signal("daily_yield", total)
	print("RevenueManager: nightly payout = $%.2f" % total)

## Returns the sum of daily_yield across all registered (owned) properties.
func get_total_daily_yield() -> float:
	var total: float = 0.0
	for p in owned_properties:
		if p == null or not is_instance_valid(p):
			continue
		if p.has_method("get") and p.data != null and p.data.is_owned:
			total += p.data.daily_yield
	return total

## Returns the sum of purchase_price (empire asset value) for all owned properties.
func get_total_empire_value() -> float:
	var total: float = 0.0
	for p in owned_properties:
		if p == null or not is_instance_valid(p):
			continue
		if p.has_method("get") and p.data != null and p.data.is_owned:
			total += p.data.purchase_price
	return total
