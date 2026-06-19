# PedestrianAI.gd
# res://scripts/systems/ai/PedestrianAI.gd
extends CharacterBody3D

# ---------------------------------------------------------------------------
# State enum
# ---------------------------------------------------------------------------
enum State {
	IDLE,
	WALKING,
	FLEEING,
	COWERING,
	INVESTIGATING
}

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------
@export var walk_speed: float = 1.5
@export var flee_speed: float = 4.0
@export var district: String = ""
@export var npc_type: String = "civilian"

## How long to stay COWERING before returning to IDLE
@export var cower_duration: float = 8.0
## How long to INVESTIGATE before returning to IDLE
@export var investigate_duration: float = 5.0
## How far the pedestrian will wander from its spawn point
@export var wander_radius: float = 15.0
## Time between choosing new wander destinations
@export var wander_interval: float = 4.0

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var state: int = State.IDLE
var _cower_timer: float = 0.0
var _investigate_timer: float = 0.0
var _wander_timer: float = 0.0
var _spawn_position: Vector3 = Vector3.ZERO

# ---------------------------------------------------------------------------
# Child-node references (set up in _ready)
# ---------------------------------------------------------------------------
var _nav_agent: NavigationAgent3D = null

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal state_changed(new_state: int)

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
	_spawn_position = global_position
	_nav_agent = _get_or_create_nav_agent()
	_nav_agent.path_desired_distance = 0.5
	_nav_agent.target_desired_distance = 0.5
	set_state(State.IDLE)

func _physics_process(delta: float) -> void:
	match state:
		State.IDLE:
			_tick_idle(delta)
		State.WALKING:
			_tick_walking(delta)
		State.FLEEING:
			_tick_fleeing(delta)
		State.COWERING:
			_tick_cowering(delta)
		State.INVESTIGATING:
			_tick_investigating(delta)

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
		State.COWERING:
			_cower_timer = cower_duration
			velocity = Vector3.ZERO
		State.INVESTIGATING:
			_investigate_timer = investigate_duration
		State.IDLE:
			velocity = Vector3.ZERO
			_wander_timer = wander_interval

func react_to_crime() -> void:
	if state == State.FLEEING or state == State.COWERING:
		return
	# 60 % chance to flee, 40 % to cower
	if randf() < 0.6:
		_start_flee()
	else:
		set_state(State.COWERING)

func react_to_gunfire() -> void:
	# Gunfire almost always triggers fleeing
	if randf() < 0.85:
		_start_flee()
	else:
		set_state(State.COWERING)

func wander(delta: float) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = wander_interval
		_pick_wander_destination()

# ---------------------------------------------------------------------------
# State tick helpers
# ---------------------------------------------------------------------------
func _tick_idle(delta: float) -> void:
	wander(delta)

func _tick_walking(delta: float) -> void:
	if _nav_agent == null or _nav_agent.is_navigation_finished():
		set_state(State.IDLE)
		return
	_move_along_path(walk_speed)

func _tick_fleeing(delta: float) -> void:
	if _nav_agent == null or _nav_agent.is_navigation_finished():
		# Pick a new far flee point
		_pick_flee_destination()
		return
	_move_along_path(flee_speed)

func _tick_cowering(delta: float) -> void:
	_cower_timer -= delta
	if _cower_timer <= 0.0:
		set_state(State.IDLE)

func _tick_investigating(delta: float) -> void:
	_investigate_timer -= delta
	if _investigate_timer <= 0.0:
		set_state(State.IDLE)
		return
	if _nav_agent != null and not _nav_agent.is_navigation_finished():
		_move_along_path(walk_speed * 1.2)

# ---------------------------------------------------------------------------
# Movement helpers
# ---------------------------------------------------------------------------
func _move_along_path(speed: float) -> void:
	if _nav_agent == null:
		return
	var next_pos: Vector3 = _nav_agent.get_next_path_position()
	var direction: Vector3 = (next_pos - global_position)
	direction.y = 0.0
	direction = direction.normalized()
	velocity = direction * speed

func _pick_wander_destination() -> void:
	var offset: Vector3 = Vector3(
		randf_range(-wander_radius, wander_radius),
		0.0,
		randf_range(-wander_radius, wander_radius)
	)
	var target: Vector3 = _spawn_position + offset
	if _nav_agent != null:
		_nav_agent.target_position = target
	set_state(State.WALKING)

func _start_flee() -> void:
	set_state(State.FLEEING)
	_pick_flee_destination()

func _pick_flee_destination() -> void:
	# Run away from the player
	var player: Node3D = get_tree().get_first_node_in_group("player") as Node3D
	var flee_dir: Vector3
	if player != null:
		flee_dir = (global_position - player.global_position).normalized()
	else:
		flee_dir = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)).normalized()

	var flee_target: Vector3 = global_position + flee_dir * (flee_speed * 8.0)
	if _nav_agent != null:
		_nav_agent.target_position = flee_target

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
