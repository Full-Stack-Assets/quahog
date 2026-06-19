# DynamicSpawner.gd
# res://scripts/systems/ai/DynamicSpawner.gd
extends Node

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------
@export var pedestrian_scene: PackedScene
@export var max_pedestrians: int = 20
@export var spawn_radius: float = 80.0
@export var despawn_radius: float = 100.0
@export var region_profile: Resource   # RegionProfile

## How frequently (seconds) to run a spawn/despawn tick
@export var tick_interval: float = 2.0

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var _spawned_pedestrians: Array = []   # Array[Node3D]
var _tick_timer: float = 0.0

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _process(delta: float) -> void:
	_tick_timer -= delta
	if _tick_timer <= 0.0:
		_tick_timer = tick_interval
		_run_tick()

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------
func spawn_pedestrian(position: Vector3) -> void:
	if pedestrian_scene == null:
		push_warning("DynamicSpawner: pedestrian_scene is not set.")
		return

	var inst = pedestrian_scene.instantiate()
	get_tree().root.add_child(inst)
	inst.global_position = position

	# Apply region-specific NPC type if applicable
	if region_profile != null and "npc_types" in region_profile:
		var types: Array = region_profile.get("npc_types")
		if types.size() > 0 and inst.has_method("set") and "npc_type" in inst:
			inst.npc_type = types[randi() % types.size()]

	if region_profile != null and "region_name" in region_profile and "district" in inst:
		inst.district = region_profile.get("region_name")

	_spawned_pedestrians.append(inst)

func despawn_distant() -> void:
	var player: Node3D = get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return

	var to_remove: Array = []
	for ped in _spawned_pedestrians:
		if not is_instance_valid(ped):
			to_remove.append(ped)
			continue
		if ped.global_position.distance_to(player.global_position) > despawn_radius:
			to_remove.append(ped)

	for ped in to_remove:
		_spawned_pedestrians.erase(ped)
		if is_instance_valid(ped):
			ped.queue_free()

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------
func _run_tick() -> void:
	# Remove stale references first
	despawn_distant()

	var player: Node3D = get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return

	# Count valid pedestrians
	var valid_count: int = 0
	for ped in _spawned_pedestrians:
		if is_instance_valid(ped):
			valid_count += 1

	# Determine target count from density
	var density: float = 1.0
	if region_profile != null and "pedestrian_density" in region_profile:
		density = region_profile.get("pedestrian_density")

	var target_count: int = int(float(max_pedestrians) * clampf(density, 0.0, 2.0))

	if valid_count >= target_count:
		return

	# Spawn one pedestrian per tick to avoid frame spikes
	var angle: float = randf() * TAU
	var dist: float = randf_range(spawn_radius * 0.5, spawn_radius)
	var offset: Vector3 = Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
	spawn_pedestrian(player.global_position + offset)
