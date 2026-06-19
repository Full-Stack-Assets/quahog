# FactionHostilityManager.gd
# res://scripts/systems/combat/FactionHostilityManager.gd
extends Node

# ---------------------------------------------------------------------------
# Inner class
# ---------------------------------------------------------------------------
class FactionTerritory:
	var faction_id: String = ""
	var territory_zone: Area3D = null      # Area3D node in the scene
	var territory_color: Color = Color.WHITE
	# Convenience radius for position-based detection (exported via register_territory)
	var detection_radius: float = 50.0

	func _init(
		fid: String,
		zone: Area3D,
		col: Color = Color.WHITE,
		radius: float = 50.0
	) -> void:
		faction_id = fid
		territory_zone = zone
		territory_color = col
		detection_radius = radius

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------
@export var territories: Array = []         # Array[FactionTerritory]
@export var hit_squad_scene: PackedScene
@export var squad_size: int = 3
@export var spawn_radius: float = 25.0

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var current_territory_faction: String = ""

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal territory_entered(faction_id: String)
signal hit_squad_spawned(faction_id: String)

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Returns the faction that controls the given world position.
## Uses distance check against each territory_zone's global_position.
func get_controlling_faction(position: Vector3) -> String:
	for territory in territories:
		var t: FactionTerritory = territory as FactionTerritory
		if t == null or t.territory_zone == null:
			continue
		var dist: float = position.distance_to(t.territory_zone.global_position)
		if dist <= t.detection_radius:
			return t.faction_id
	return ""

## Spawn `squad_size` hit-squad members near target_position.
func spawn_hit_squad(faction_id: String, target_position: Vector3) -> void:
	if hit_squad_scene == null:
		push_warning("FactionHostilityManager: hit_squad_scene is not set.")
		return

	for i in range(squad_size):
		var angle: float = (TAU / squad_size) * i
		var offset: Vector3 = Vector3(
			cos(angle) * spawn_radius,
			0.0,
			sin(angle) * spawn_radius
		)
		var spawn_pos: Vector3 = target_position + offset

		var inst = hit_squad_scene.instantiate()
		get_tree().root.add_child(inst)
		if inst.has_method("set_faction"):
			inst.set_faction(faction_id)
		inst.global_position = spawn_pos

	emit_signal("hit_squad_spawned", faction_id)

## Poll all territories and update current_territory_faction.
func update_territory_control() -> void:
	var player_node: Node3D = get_tree().get_first_node_in_group("player") as Node3D
	if player_node == null:
		return

	var faction: String = get_controlling_faction(player_node.global_position)
	if faction != current_territory_faction:
		current_territory_faction = faction
		if faction != "":
			emit_signal("territory_entered", faction)

## Dynamically register a territory at runtime.
func register_territory(
	faction_id: String,
	zone: Area3D,
	color: Color = Color.WHITE,
	radius: float = 50.0
) -> void:
	var t := FactionTerritory.new(faction_id, zone, color, radius)
	territories.append(t)

## Remove all registered territories.
func clear_territories() -> void:
	territories.clear()
	current_territory_faction = ""
