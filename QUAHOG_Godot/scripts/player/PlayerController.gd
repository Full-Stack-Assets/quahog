# PlayerController.gd
# Project QUAHOG — GTA-style open world, 1986 Massachusetts coast
# Converted from Unity C# CharacterController → Godot 4 CharacterBody3D
extends CharacterBody3D

# ──────────────────────────────────────────────
# Constants
# ──────────────────────────────────────────────
const WALK_SPEED: float   = 3.0
const RUN_SPEED: float    = 6.0
const SPRINT_SPEED: float = 10.0
const GRAVITY: float      = -15.0
const JUMP_FORCE: float   = 5.0

# ──────────────────────────────────────────────
# Exported references (assign in the Inspector)
# ──────────────────────────────────────────────
@export var camera_rig: Node3D       ## Pivot node that rotates vertically (pitch)
@export var camera_node: Camera3D    ## The actual Camera3D child of camera_rig

@export var orbit_sensitivity_x: float = 3.0
@export var orbit_sensitivity_y: float = 1.5
@export var min_pitch: float          = -30.0
@export var max_pitch: float          =  60.0

@export var default_fov: float          = 60.0
@export var ads_fov: float              = 40.0
@export var fov_transition_speed: float = 10.0

@export var interact_range: float          = 3.0
@export var cover_detection_radius: float  = 2.0

# ──────────────────────────────────────────────
# Private state
# ──────────────────────────────────────────────
var _pitch: float            = 0.0
var _yaw: float              = 0.0
var _vertical_velocity: float = 0.0

var _is_aiming: bool    = false
var _is_in_cover: bool  = false
var _current_cover              = null   # CoverPoint node or null
var _current_interact_target    = null   # IInteractable node or null

## Read-only public speed for animation / audio systems
var current_speed: float = 0.0

# ──────────────────────────────────────────────
# Signals
# ──────────────────────────────────────────────
signal interact_target_changed(target)
signal cover_changed(in_cover: bool)

# ──────────────────────────────────────────────
# Lifecycle
# ──────────────────────────────────────────────
func _ready() -> void:
	# Lock & hide cursor — MOUSE_MODE_CAPTURED handles both
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Seed pitch/yaw from current node transforms so we don't snap on first frame
	if camera_rig:
		_pitch = camera_rig.rotation.x
	_yaw = rotation.y

	if camera_node:
		camera_node.fov = default_fov


func _unhandled_input(event: InputEvent) -> void:
	# Camera orbit via mouse — handled here rather than polling for accuracy
	if event is InputEventMouseMotion:
		_yaw   -= event.relative.x * orbit_sensitivity_x * 0.01
		_pitch -= event.relative.y * orbit_sensitivity_y * 0.01
		_pitch  = clampf(_pitch, deg_to_rad(min_pitch), deg_to_rad(max_pitch))

		if camera_rig:
			camera_rig.rotation.x = _pitch
		rotation.y = _yaw

	# Toggle aim on button press
	if event.is_action_pressed("aim"):
		_is_aiming = true
	elif event.is_action_released("aim"):
		_is_aiming = false

	# Interact
	if event.is_action_just_pressed("interact"):
		_try_interact()

	# Toggle cover
	if event.is_action_just_pressed("take_cover"):
		if _is_in_cover:
			_exit_cover()
		else:
			_try_enter_cover()


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_jump()
	_handle_movement(delta)
	_handle_interaction_scan()
	_handle_fov_transition(delta)

	move_and_slide()

	# Expose current horizontal speed
	current_speed = Vector2(velocity.x, velocity.z).length()


# ──────────────────────────────────────────────
# Movement
# ──────────────────────────────────────────────
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		_vertical_velocity += GRAVITY * delta
	else:
		# Small negative value keeps the body pressed into the floor for
		# is_on_floor() to remain stable across frames
		_vertical_velocity = -0.5

	velocity.y = _vertical_velocity


func _handle_jump() -> void:
	# No jumping while in cover — matches GTA cover mechanics
	if InputManager.get_jump_down() and is_on_floor() and not _is_in_cover:
		_vertical_velocity = JUMP_FORCE
		velocity.y = _vertical_velocity


func _handle_movement(_delta: float) -> void:
	var move: Vector2 = InputManager.get_move_vector()
	# Build world-space direction from player's current basis
	var direction: Vector3 = (transform.basis * Vector3(move.x, 0.0, move.y)).normalized()

	if _is_in_cover and _current_cover != null:
		_handle_cover_movement(direction)
	else:
		var speed: float = SPRINT_SPEED if InputManager.get_sprint() else WALK_SPEED

		if direction.length() > 0.1:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			# Decelerate smoothly to zero
			velocity.x = move_toward(velocity.x, 0.0, speed)
			velocity.z = move_toward(velocity.z, 0.0, speed)


func _handle_cover_movement(world_direction: Vector3) -> void:
	# Constrain movement to the lateral axis of the cover surface
	if _current_cover == null:
		return

	# Assume cover node exposes a `cover_normal: Vector3` property
	var cover_normal: Vector3 = Vector3.ZERO
	if _current_cover.has_method("get_cover_normal"):
		cover_normal = _current_cover.get_cover_normal()
	else:
		# Fallback: use the direction from cover to player projected to XZ
		cover_normal = (global_position - _current_cover.global_position)
		cover_normal.y = 0.0
		cover_normal = cover_normal.normalized()

	# Lateral axis is perpendicular to normal in XZ plane
	var lateral: Vector3 = cover_normal.cross(Vector3.UP).normalized()
	var dot: float = world_direction.dot(lateral)

	velocity.x = lateral.x * dot * WALK_SPEED
	velocity.z = lateral.z * dot * WALK_SPEED


# ──────────────────────────────────────────────
# Interaction
# ──────────────────────────────────────────────
func _handle_interaction_scan() -> void:
	if camera_node == null:
		return

	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	# Cast forward along camera's -Z (Godot cameras look down -Z)
	var ray_origin: Vector3 = camera_node.global_position
	var ray_end: Vector3    = ray_origin + camera_node.global_transform.basis.z * -interact_range

	var ray_params := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	ray_params.exclude = [self]   # Don't hit ourselves

	var result: Dictionary = space.intersect_ray(ray_params)

	var new_target = null
	if result.size() > 0:
		var collider = result["collider"]
		if collider.has_method("interact"):
			new_target = collider

	if new_target != _current_interact_target:
		_current_interact_target = new_target
		emit_signal("interact_target_changed", _current_interact_target)


func _try_interact() -> void:
	if _current_interact_target != null and _current_interact_target.has_method("interact"):
		_current_interact_target.interact(self)


# ──────────────────────────────────────────────
# Cover system
# ──────────────────────────────────────────────
func _try_enter_cover() -> void:
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var shape_params := PhysicsShapeQueryParameters3D.new()

	var sphere := SphereShape3D.new()
	sphere.radius = cover_detection_radius
	shape_params.shape    = sphere
	shape_params.transform = Transform3D(Basis.IDENTITY, global_position)
	shape_params.exclude   = [self]
	shape_params.collision_mask = 0b0000_0010  # Adjust to match your "cover" layer

	var results: Array = space.intersect_shape(shape_params, 8)

	var best_cover  = null
	var best_dist: float = INF

	for hit in results:
		var col = hit["collider"]
		if col.is_in_group("cover_points"):
			var dist: float = global_position.distance_to(col.global_position)
			if dist < best_dist:
				best_dist  = dist
				best_cover = col

	if best_cover != null:
		_current_cover = best_cover
		_is_in_cover   = true
		emit_signal("cover_changed", true)


func _exit_cover() -> void:
	_current_cover = null
	_is_in_cover   = false
	emit_signal("cover_changed", false)


# ──────────────────────────────────────────────
# FOV / ADS transition
# ──────────────────────────────────────────────
func _handle_fov_transition(delta: float) -> void:
	if camera_node == null:
		return
	var target_fov: float = ads_fov if _is_aiming else default_fov
	camera_node.fov = lerpf(camera_node.fov, target_fov, fov_transition_speed * delta)


# ──────────────────────────────────────────────
# Public helpers
# ──────────────────────────────────────────────
func is_aiming() -> bool:
	return _is_aiming

func is_in_cover() -> bool:
	return _is_in_cover

func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
