# GridlockZone.gd
# res://scripts/systems/traffic/GridlockZone.gd
# Attach to an Area3D node (or extend one directly — requires an Area3D parent).
# For a standalone script, make the parent node an Area3D and connect body_entered/exited.
extends Area3D

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------
@export var zone_name: String = "Canal Bridge"
@export var max_vehicles_before_gridlock: int = 5
@export var frustration_threshold: float = 30.0    # seconds before honking

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var vehicles_in_zone: Array = []    # Array[Node]
var is_gridlocked: bool = false

## Per-vehicle frustration timers: { Node -> float }
var _frustration_timers: Dictionary = {}

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal gridlock_started()
signal gridlock_cleared()
signal vehicle_honked(vehicle_node)

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
	# Connect Area3D body signals to our handlers
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	_tick_frustration(delta)

# ---------------------------------------------------------------------------
# Area3D callbacks
# ---------------------------------------------------------------------------
func _on_body_entered(body: Node) -> void:
	# Only track VehicleAI / CharacterBody3D vehicles
	if not (body is CharacterBody3D or body is RigidBody3D):
		return
	# Optionally filter by group
	if not body.is_in_group("vehicle") and not body.get_script() != null:
		pass  # Accept anything with a body for now; filter via group in production

	if body in vehicles_in_zone:
		return

	vehicles_in_zone.append(body)
	_frustration_timers[body] = 0.0
	_evaluate_gridlock()

func _on_body_exited(body: Node) -> void:
	if body in vehicles_in_zone:
		vehicles_in_zone.erase(body)
		_frustration_timers.erase(body)
	_evaluate_gridlock()

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------
func _evaluate_gridlock() -> void:
	var over_limit: bool = vehicles_in_zone.size() >= max_vehicles_before_gridlock

	if over_limit and not is_gridlocked:
		is_gridlocked = true
		emit_signal("gridlock_started")
		_notify_vehicles_stopped(true)

	elif not over_limit and is_gridlocked:
		is_gridlocked = false
		emit_signal("gridlock_cleared")
		_notify_vehicles_stopped(false)

func _notify_vehicles_stopped(stopped: bool) -> void:
	for vehicle in vehicles_in_zone:
		if not is_instance_valid(vehicle):
			continue
		if stopped:
			if vehicle.has_method("set_state"):
				vehicle.set_state(1)  # VehicleAI.State.STOPPED = 1
		else:
			if vehicle.has_method("set_state"):
				vehicle.set_state(0)  # VehicleAI.State.DRIVING = 0

func _tick_frustration(delta: float) -> void:
	if not is_gridlocked:
		# Reset all timers when not gridlocked
		for key in _frustration_timers.keys():
			_frustration_timers[key] = 0.0
		return

	var to_remove: Array = []
	for vehicle in _frustration_timers.keys():
		if not is_instance_valid(vehicle):
			to_remove.append(vehicle)
			continue

		_frustration_timers[vehicle] += delta
		if _frustration_timers[vehicle] >= frustration_threshold:
			_frustration_timers[vehicle] = 0.0  # Reset so it honks again after another interval
			emit_signal("vehicle_honked", vehicle)

	for v in to_remove:
		_frustration_timers.erase(v)
		vehicles_in_zone.erase(v)
