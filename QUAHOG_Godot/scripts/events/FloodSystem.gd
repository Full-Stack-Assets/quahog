# FloodSystem.gd
# Raises and lowers a water plane Node3D during the Gloria hurricane event.
# Attach as a child of the level scene; assign the water_plane export.
extends Node3D

# ── Exports ────────────────────────────────────────────────────────────────
@export var water_plane: Node3D
@export var max_flood_height: float = 5.0
@export var rise_speed: float = 0.5   # units per second rising
@export var recede_speed: float = 0.2 # units per second receding

# ── Signals ────────────────────────────────────────────────────────────────
signal flood_level_changed(level: float)  # normalized 0.0–1.0

# ── State ──────────────────────────────────────────────────────────────────
var _base_y: float = 0.0
var _is_flooding: bool = false
var _is_receding: bool = false

# ── Lifecycle ──────────────────────────────────────────────────────────────
func _ready() -> void:
	if water_plane == null:
		push_warning("FloodSystem '%s': water_plane not assigned." % name)
		return
	_base_y = water_plane.global_position.y

func _process(delta: float) -> void:
	if water_plane == null:
		return

	var pos: Vector3 = water_plane.global_position
	var target_y: float = _base_y + max_flood_height if _is_flooding else _base_y
	var speed: float = rise_speed if _is_flooding else recede_speed

	if _is_flooding or _is_receding:
		pos.y = move_toward(pos.y, target_y, speed * delta)
		water_plane.global_position = pos

		var level: float = get_current_level()
		emit_signal("flood_level_changed", level)

		# Stop animation once we reach target.
		if is_equal_approx(pos.y, target_y):
			_is_flooding = false
			_is_receding = false

# ── Public API ─────────────────────────────────────────────────────────────

## Begin raising the water plane toward max_flood_height.
func start_rising() -> void:
	_is_flooding = true
	_is_receding = false
	print("FloodSystem: rising started.")

## Begin lowering the water plane back to the base level.
func start_receding() -> void:
	_is_receding = true
	_is_flooding = false
	print("FloodSystem: receding started.")

## Returns the current flood level as a 0.0–1.0 normalized float.
func get_current_level() -> float:
	if water_plane == null or is_equal_approx(max_flood_height, 0.0):
		return 0.0
	var raised: float = water_plane.global_position.y - _base_y
	return clampf(raised / max_flood_height, 0.0, 1.0)
