# RegionalVehiclePool.gd
# res://scripts/systems/traffic/RegionalVehiclePool.gd
extends Node

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------
@export var vehicle_scenes: Array[PackedScene] = []
@export var vehicle_weights: Array[float] = []
@export var region: String = ""

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Returns a PackedScene chosen via weighted random selection.
## Returns null if no scenes are configured.
func pick_random_vehicle() -> PackedScene:
	if vehicle_scenes.is_empty():
		push_warning("RegionalVehiclePool (%s): no vehicle_scenes defined." % region)
		return null

	# Build weights array, defaulting to 1.0 if not provided or mismatched
	var weights: Array[float] = []
	for i in range(vehicle_scenes.size()):
		if i < vehicle_weights.size():
			weights.append(maxf(vehicle_weights[i], 0.0))
		else:
			weights.append(1.0)

	var total_weight: float = 0.0
	for w in weights:
		total_weight += w

	if total_weight <= 0.0:
		# Fallback: uniform selection
		return vehicle_scenes[randi() % vehicle_scenes.size()]

	var roll: float = randf() * total_weight
	var cumulative: float = 0.0
	for i in range(weights.size()):
		cumulative += weights[i]
		if roll <= cumulative:
			return vehicle_scenes[i]

	# Should not reach here, but return last as safety
	return vehicle_scenes[-1]

## Instantiate a vehicle from the pool at a given position.
func spawn_vehicle(position: Vector3, parent: Node = null) -> Node:
	var scene: PackedScene = pick_random_vehicle()
	if scene == null:
		return null

	var inst = scene.instantiate()
	var target_parent: Node = parent if parent != null else get_tree().root
	target_parent.add_child(inst)

	if inst is Node3D:
		inst.global_position = position

	return inst
