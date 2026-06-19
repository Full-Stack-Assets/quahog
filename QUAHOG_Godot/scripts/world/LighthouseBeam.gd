## LighthouseBeam.gd
## res://scripts/world/LighthouseBeam.gd
## Rotates a lighthouse beam and emits a signal when the player is detected
## within range via a physics raycast.
## Attach to the lighthouse beam Node3D (the rotating part).
## Converted from LighthouseBeam.cs (Unity C#) for Project QUAHOG / Godot 4

extends Node3D

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------

## Degrees per second for the rotating beam.
@export var rotation_speed: float = 10.0

## Maximum distance at which the beam can detect the player.
@export var detection_radius: float = 200.0

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal player_detected()

# ---------------------------------------------------------------------------
# Private state
# ---------------------------------------------------------------------------
var _player: Node3D = null
var _space_state: PhysicsDirectSpaceState3D = null

# Cooldown to prevent signal spam (one emission per sweep).
var _detection_cooldown: float = 0.0
const _DETECTION_COOLDOWN_TIME: float = 1.0

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
	# Cache player reference — refreshed each frame if null.
	_cache_player()

func _process(delta: float) -> void:
	# 1. Rotate the beam around the world-space Y axis.
	rotate_y(deg_to_rad(rotation_speed) * delta)

	# 2. Tick detection cooldown.
	if _detection_cooldown > 0.0:
		_detection_cooldown -= delta

	# 3. Try to find the player if we lost the reference.
	if _player == null:
		_cache_player()
		return

	# 4. Only cast if player is within detection_radius.
	var distance: float = global_position.distance_to(_player.global_position)
	if distance > detection_radius:
		return

	# 5. Raycast from beam origin toward the player.
	if _space_state == null:
		_space_state = get_world_3d().direct_space_state

	var query := PhysicsRayQueryParameters3D.create(
		global_position,
		_player.global_position
	)
	# Exclude the lighthouse node itself from the query.
	query.exclude = [self]
	query.collision_mask = 0xFFFFFFFF  # All layers; tune per project.

	var result: Dictionary = _space_state.intersect_ray(query)

	if result.is_empty():
		return

	# Check whether the first hit is the player.
	var hit_body = result.get("collider")
	if hit_body != null and hit_body.is_in_group("player"):
		if _detection_cooldown <= 0.0:
			player_detected.emit()
			_detection_cooldown = _DETECTION_COOLDOWN_TIME

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------
func _cache_player() -> void:
	_player = get_tree().get_first_node_in_group("player") as Node3D
