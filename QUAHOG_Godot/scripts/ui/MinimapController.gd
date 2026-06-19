# MinimapController.gd
# Project QUAHOG — Minimap rendered via a SubViewport with an orthographic Camera3D.
# Attach to a SubViewportContainer node that contains a SubViewport → Camera3D.
extends SubViewportContainer

# ──────────────────────────────────────────────
# Inner class: tracks a world object → minimap icon
# ──────────────────────────────────────────────
class MinimapIcon:
	var target: Node3D
	var ui_element: Control
	var icon_texture: Texture2D

	func _init(t: Node3D, ui: Control, tex: Texture2D) -> void:
		target      = t
		ui_element  = ui
		icon_texture = tex

# ──────────────────────────────────────────────
# Exports
# ──────────────────────────────────────────────
@export var minimap_camera: Camera3D   ## Must be an orthographic Camera3D inside the SubViewport
@export var zoom_level: float  = 100.0 ## Orthographic size (world units visible top-down)
@export var center_target: Node3D      ## Usually the player

# ──────────────────────────────────────────────
# Private state
# ──────────────────────────────────────────────
## key: Node3D target  value: MinimapIcon
var _icons: Dictionary = {}

# Reference to parent Control that holds icon UI elements
# (a plain Control node with clip_children that overlays the SubViewportContainer)
@export var icon_layer: Control

# ──────────────────────────────────────────────
# Lifecycle
# ──────────────────────────────────────────────
func _ready() -> void:
	if minimap_camera:
		minimap_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		minimap_camera.size = zoom_level
		minimap_camera.rotation_degrees = Vector3(-90.0, 0.0, 0.0)  # Look straight down


func _process(_delta: float) -> void:
	_follow_target()
	update_icon_positions()


# ──────────────────────────────────────────────
# Camera control
# ──────────────────────────────────────────────
func _follow_target() -> void:
	if minimap_camera == null or center_target == null:
		return
	var wp: Vector3 = center_target.global_position
	# Keep camera elevated above terrain; Y is set to a fixed height
	minimap_camera.global_position = Vector3(wp.x, minimap_camera.global_position.y, wp.z)


func set_zoom(zoom: float) -> void:
	zoom_level = maxf(zoom, 1.0)
	if minimap_camera:
		minimap_camera.size = zoom_level


func set_center(world_pos: Vector3) -> void:
	if minimap_camera:
		minimap_camera.global_position = Vector3(
			world_pos.x,
			minimap_camera.global_position.y,
			world_pos.z
		)


# ──────────────────────────────────────────────
# Icon management
# ──────────────────────────────────────────────
func add_icon(target: Node3D, texture: Texture2D) -> void:
	if _icons.has(target):
		return

	# Create a small TextureRect as the icon
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.custom_minimum_size = Vector2(12.0, 12.0)
	rect.pivot_offset = Vector2(6.0, 6.0)

	if icon_layer:
		icon_layer.add_child(rect)
	else:
		add_child(rect)

	var icon := MinimapIcon.new(target, rect, texture)
	_icons[target] = icon


func remove_icon(target: Node3D) -> void:
	if not _icons.has(target):
		return
	var icon: MinimapIcon = _icons[target]
	if is_instance_valid(icon.ui_element):
		icon.ui_element.queue_free()
	_icons.erase(target)


## Projects world positions onto the minimap rectangle.
func update_icon_positions() -> void:
	if minimap_camera == null or center_target == null:
		return

	var map_size: Vector2 = size  # SubViewportContainer size in pixels
	var half_size: Vector2 = map_size * 0.5
	# World units per pixel
	var world_per_px: float = zoom_level / minf(map_size.x, map_size.y)

	var dead: Array = []

	for key in _icons.keys():
		var icon: MinimapIcon = _icons[key]

		if not is_instance_valid(key) or not is_instance_valid(icon.ui_element):
			dead.append(key)
			continue

		var target_pos: Vector3  = key.global_position
		var player_pos: Vector3  = center_target.global_position

		var delta_x: float = target_pos.x - player_pos.x
		var delta_z: float = target_pos.z - player_pos.z

		# Rotate offset by player's Y angle so the minimap is player-relative
		var player_yaw: float = center_target.rotation.y
		var cos_y: float = cos(-player_yaw)
		var sin_y: float = sin(-player_yaw)
		var rotated_x: float = delta_x * cos_y - delta_z * sin_y
		var rotated_z: float = delta_x * sin_y + delta_z * cos_y

		var pixel_x: float = half_size.x + rotated_x / world_per_px
		var pixel_y: float = half_size.y + rotated_z / world_per_px   # Z → screen Y (down)

		# Clamp to minimap boundary
		var radius_px: float = half_size.x - 8.0
		var offset: Vector2  = Vector2(pixel_x - half_size.x, pixel_y - half_size.y)
		if offset.length() > radius_px:
			offset = offset.normalized() * radius_px
			pixel_x = half_size.x + offset.x
			pixel_y = half_size.y + offset.y

		icon.ui_element.position = Vector2(pixel_x - 6.0, pixel_y - 6.0)

	# Clean up stale icons
	for key in dead:
		remove_icon(key)
