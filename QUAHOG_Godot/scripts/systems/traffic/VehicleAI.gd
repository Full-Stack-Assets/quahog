# VehicleAI.gd
# res://scripts/systems/traffic/VehicleAI.gd
# Uses CharacterBody3D for broad compatibility; swap to VehicleBody3D for
# physics-based vehicle simulation if desired.
extends CharacterBody3D

# ---------------------------------------------------------------------------
# State enum
# ---------------------------------------------------------------------------
enum State {
	DRIVING,
	STOPPED,
	FLEEING,
	ABANDONED
}

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------
@export var drive_speed: float = 8.0
@export var flee_speed: float = 15.0
@export var gravity: float = -9.8

## Distance from waypoint before selecting the next one
@export var waypoint_tolerance: float = 2.0

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var state: int = State.DRIVING
var _nav_agent: NavigationAgent3D = null

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal state_changed(new_state: int)

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
	_nav_agent = _get_or_create_nav_agent()
	_nav_agent.path_desired_distance = waypoint_tolerance
	_nav_agent.target_desired_distance = waypoint_tolerance
	_pick_new_drive_destination()

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	match state:
		State.DRIVING:
			_tick_driving(delta)
		State.STOPPED:
			velocity.x = 0.0
			velocity.z = 0.0
		State.FLEEING:
			_tick_fleeing(delta)
		State.ABANDONED:
			velocity.x = 0.0
			velocity.z = 0.0

	move_and_slide()

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------
func set_state(new_state: int) -> void:
	if new_state == state:
		return
	state = new_state
	emit_signal("state_changed", state)

	match state:
		State.DRIVING:
			_pick_new_drive_destination()
		State.FLEEING:
			_pick_flee_destination()
		State.STOPPED, State.ABANDONED:
			velocity.x = 0.0
			velocity.z = 0.0

func react_to_player_crime() -> void:
	match state:
		State.DRIVING:
			# 70 % flee, 30 % stop
			if randf() < 0.7:
				set_state(State.FLEEING)
			else:
				set_state(State.STOPPED)
		State.STOPPED:
			if randf() < 0.5:
				set_state(State.FLEEING)

# ---------------------------------------------------------------------------
# State ticks
# ---------------------------------------------------------------------------
func _tick_driving(_delta: float) -> void:
	if _nav_agent == null or _nav_agent.is_navigation_finished():
		_pick_new_drive_destination()
		return
	_move_along_path(drive_speed)

func _tick_fleeing(_delta: float) -> void:
	if _nav_agent == null or _nav_agent.is_navigation_finished():
		_pick_flee_destination()
		return
	_move_along_path(flee_speed)

# ---------------------------------------------------------------------------
# Movement helpers
# ---------------------------------------------------------------------------
func _move_along_path(speed: float) -> void:
	if _nav_agent == null:
		return
	var next_pos: Vector3 = _nav_agent.get_next_path_position()
	var dir: Vector3 = (next_pos - global_position)
	dir.y = 0.0
	dir = dir.normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed

	# Face direction of travel
	if dir.length_squared() > 0.01:
		var target_angle: float = atan2(dir.x, dir.z)
		rotation.y = lerpf(rotation.y, target_angle, 0.15)

func _pick_new_drive_destination() -> void:
	if _nav_agent == null:
		return
	# Pick a random point within 200 m in the navigation mesh
	var offset: Vector3 = Vector3(
		randf_range(-200.0, 200.0),
		0.0,
		randf_range(-200.0, 200.0)
	)
	_nav_agent.target_position = global_position + offset

func _pick_flee_destination() -> void:
	var player: Node3D = get_tree().get_first_node_in_group("player") as Node3D
	var flee_dir: Vector3
	if player != null:
		flee_dir = (global_position - player.global_position).normalized()
	else:
		flee_dir = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)).normalized()

	if _nav_agent != null:
		_nav_agent.target_position = global_position + flee_dir * 200.0

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------
func _get_or_create_nav_agent() -> NavigationAgent3D:
	for child in get_children():
		if child is NavigationAgent3D:
			return child
	var agent := NavigationAgent3D.new()
	agent.name = "NavigationAgent3D"
	add_child(agent)
	return agent
