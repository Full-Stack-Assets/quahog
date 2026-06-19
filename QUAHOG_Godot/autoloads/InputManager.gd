## InputManager.gd
## Autoload singleton — wraps Godot's Input singleton with dead-zone handling
## and input-device detection (keyboard/mouse vs. gamepad).
## Ported from InputManager.cs (Unity) to Godot 4 GDScript.
## Access via: InputManager.<method>
extends Node

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
## Emitted when the active input device changes. device is "keyboard_mouse" or "gamepad".
signal input_device_changed(device: String)

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
@export var move_dead_zone: float = 0.15
@export var look_dead_zone: float = 0.15

# ---------------------------------------------------------------------------
# Private state
# ---------------------------------------------------------------------------
var _current_device: String = "keyboard_mouse"

# Cached actions checked each frame for device switching
const _GAMEPAD_AXES: Array[int] = [
	JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y,
	JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y,
	JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT,
]

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	print("[InputManager] Initialised. Device: %s" % _current_device)


func _input(event: InputEvent) -> void:
	_detect_device_switch(event)

# ---------------------------------------------------------------------------
# Movement
# ---------------------------------------------------------------------------

## Returns normalised 2-D movement vector from WASD or left joystick.
## x = strafe (-1 left, +1 right), y = forward/back (-1 back, +1 forward)
func get_move_vector() -> Vector2:
	var raw: Vector2 = Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	return _apply_dead_zone(raw, move_dead_zone)


## Returns 2-D look/aim vector from mouse motion or right joystick.
## Caller is responsible for accumulating mouse delta per frame.
func get_look_vector() -> Vector2:
	var raw: Vector2 = Input.get_vector(
		"look_left", "look_right", "look_up", "look_down"
	)
	# Keyboard/mouse: look actions are driven externally via mouse delta;
	# for gamepad they come from the right stick axes mapped to look_* actions.
	return _apply_dead_zone(raw, look_dead_zone)

# ---------------------------------------------------------------------------
# Actions — held
# ---------------------------------------------------------------------------

## True while the sprint button is held.
func get_sprint() -> bool:
	return Input.is_action_pressed("sprint")


## True while fire is held (held trigger / mouse button held).
func get_fire() -> bool:
	return Input.is_action_pressed("fire")


## True while aim is held.
func get_aim() -> bool:
	return Input.is_action_pressed("aim")

# ---------------------------------------------------------------------------
# Actions — just-pressed (single frame)
# ---------------------------------------------------------------------------

## True on the first frame jump is pressed.
func get_jump_down() -> bool:
	return Input.is_action_just_pressed("jump")


## True while jump is held (for variable jump height).
func get_jump() -> bool:
	return Input.is_action_pressed("jump")


## True on the first frame interact is pressed.
func get_interact_down() -> bool:
	return Input.is_action_just_pressed("interact")


## True on the first frame fire is pressed.
func get_fire_down() -> bool:
	return Input.is_action_just_pressed("fire")


## True on the first frame reload is pressed.
func get_reload_down() -> bool:
	return Input.is_action_just_pressed("reload")


## Returns +1 for next weapon, -1 for previous weapon, 0 for no switch.
func get_weapon_switch() -> int:
	if Input.is_action_just_pressed("weapon_next"):
		return 1
	if Input.is_action_just_pressed("weapon_prev"):
		return -1
	return 0


## True on the first frame pause is pressed.
func get_pause_down() -> bool:
	return Input.is_action_just_pressed("pause")


## True on the first frame map is pressed.
func get_map_down() -> bool:
	return Input.is_action_just_pressed("map")


## True on the first frame radio is pressed.
func get_radio_down() -> bool:
	return Input.is_action_just_pressed("radio")


## True on the first frame crouch is pressed.
func get_crouch_down() -> bool:
	return Input.is_action_just_pressed("crouch")


## True on the first frame enter_vehicle is pressed.
func get_enter_vehicle_down() -> bool:
	return Input.is_action_just_pressed("enter_vehicle")

# ---------------------------------------------------------------------------
# Device info
# ---------------------------------------------------------------------------

## Returns the currently active input device string: "keyboard_mouse" or "gamepad".
func get_current_device() -> String:
	return _current_device


## Returns true if the active device is a gamepad.
func is_using_gamepad() -> bool:
	return _current_device == "gamepad"

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

func _apply_dead_zone(vec: Vector2, dead_zone: float) -> Vector2:
	if vec.length() < dead_zone:
		return Vector2.ZERO
	# Re-map the remaining range to [0, 1] to avoid a snap on dead-zone edge.
	var scaled: Vector2 = (vec - vec.normalized() * dead_zone) / (1.0 - dead_zone)
	return scaled.limit_length(1.0)


func _detect_device_switch(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if _current_device != "gamepad":
			_current_device = "gamepad"
			print("[InputManager] Device switched to: gamepad")
			emit_signal("input_device_changed", _current_device)
	elif event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		if _current_device != "keyboard_mouse":
			_current_device = "keyboard_mouse"
			print("[InputManager] Device switched to: keyboard_mouse")
			emit_signal("input_device_changed", _current_device)


func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
	if connected:
		print("[InputManager] Gamepad connected (device %d)." % device_id)
	else:
		print("[InputManager] Gamepad disconnected (device %d). Falling back to keyboard/mouse." % device_id)
		if Input.get_connected_joypads().is_empty():
			_current_device = "keyboard_mouse"
			emit_signal("input_device_changed", _current_device)
