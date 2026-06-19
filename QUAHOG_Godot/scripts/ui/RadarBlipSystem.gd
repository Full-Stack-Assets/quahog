# RadarBlipSystem.gd
# Project QUAHOG — Renders blips on a circular radar HUD element.
# Attach to a Control node that represents the radar face.
# Blips are instanced from blip_scene and positioned relative to the player.
extends Control

# ──────────────────────────────────────────────
# Exports
# ──────────────────────────────────────────────
@export var blip_scene: PackedScene      ## Small Control scene (e.g. a colored dot TextureRect)
@export var radar_radius: float  = 80.0  ## World-unit radius represented by the radar
@export var radar_ui_radius: float = 60.0 ## Pixel radius of the radar circle in the UI

# ──────────────────────────────────────────────
# Private state
# ──────────────────────────────────────────────
## Maps Node3D targets → their blip Control nodes
var _blips: Dictionary = {}

## Cached player reference — refreshed lazily
var _player: Node3D = null

# ──────────────────────────────────────────────
# Lifecycle
# ──────────────────────────────────────────────
func _ready() -> void:
	# Clip blips so they don't render outside the radar circle
	clip_contents = true


func _process(_delta: float) -> void:
	update_blip_positions()


# ──────────────────────────────────────────────
# Public API
# ──────────────────────────────────────────────
func add_blip(target: Node3D, color: Color) -> void:
	if _blips.has(target):
		return

	if blip_scene == null:
		push_warning("RadarBlipSystem: blip_scene is not set")
		return

	var blip: Control = blip_scene.instantiate() as Control
	if blip == null:
		push_error("RadarBlipSystem: blip_scene root must be a Control node")
		return

	# Tint the blip to the requested color
	blip.modulate = color
	add_child(blip)
	_blips[target] = blip


func remove_blip(target: Node3D) -> void:
	if not _blips.has(target):
		return
	var blip: Control = _blips[target]
	if is_instance_valid(blip):
		blip.queue_free()
	_blips.erase(target)


## Recompute screen positions for all tracked blips.
## Called every frame by _process; also called by HUDManager.update_radar_blips().
func update_blip_positions() -> void:
	var player: Node3D = _get_player()
	if player == null:
		return

	var center: Vector2 = size * 0.5   # Center of this Control in local space
	var player_pos: Vector3  = player.global_position
	var player_yaw: float    = player.rotation.y

	var dead: Array = []

	for target in _blips.keys():
		if not is_instance_valid(target):
			dead.append(target)
			continue

		var blip: Control = _blips[target]
		if not is_instance_valid(blip):
			dead.append(target)
			continue

		var world_delta: Vector3 = target.global_position - player_pos
		var dx: float = world_delta.x
		var dz: float = world_delta.z

		# Rotate delta into player-local space (so north is always "up" relative to player)
		var cos_y: float = cos(-player_yaw)
		var sin_y: float = sin(-player_yaw)
		var local_x: float = dx * cos_y - dz * sin_y
		var local_z: float = dx * sin_y + dz * cos_y

		# Scale world coords → UI pixels
		var scale_factor: float = radar_ui_radius / radar_radius
		var px: float = local_x * scale_factor
		var py: float = local_z * scale_factor   # Z increases away from camera → down on radar

		# Clamp to radar disc edge
		var offset: Vector2 = Vector2(px, py)
		if offset.length() > radar_ui_radius:
			offset = offset.normalized() * radar_ui_radius

		# Position blip: anchor it at center, offset by radar mapping
		var blip_size: Vector2 = blip.size
		blip.position = center + offset - blip_size * 0.5

	# Remove invalid blips
	for target in dead:
		remove_blip(target)


# ──────────────────────────────────────────────
# Private helpers
# ──────────────────────────────────────────────
func _get_player() -> Node3D:
	if is_instance_valid(_player):
		return _player

	# Try the PlayerController group first
	var players: Array = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0] as Node3D
		return _player

	# Fallback: search by class
	_player = get_tree().get_first_node_in_group("player") as Node3D
	return _player


## Expose blip count for debug / HUD summary
func get_blip_count() -> int:
	return _blips.size()
