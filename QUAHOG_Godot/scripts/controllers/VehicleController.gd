# VehicleController.gd
# Player/AI vehicle controller using Godot's VehicleBody3D physics.
# Attach as the root node of a vehicle scene; add VehicleWheel3D children.
# Autoload referenced: WeatherController (for friction changes).
extends VehicleBody3D

# ── Exports ────────────────────────────────────────────────────────────────
@export var motor_force: float = 1500.0       # max engine torque
@export var brake_force: float = 3000.0       # max brake force
@export var max_steer_angle: float = 0.5      # radians

# Per-weather friction multipliers.
@export var clear_friction: float = 1.0
@export var fog_friction: float = 0.85
@export var rain_friction: float = 0.6
@export var noreaster_friction: float = 0.45

# ── Signals ────────────────────────────────────────────────────────────────
signal speed_changed(speed: float)
signal wheel_slip(slipping: bool)

# ── State ──────────────────────────────────────────────────────────────────
var _current_friction_multiplier: float = 1.0
var _prev_speed: float = 0.0
var _was_slipping: bool = false

# ── Lifecycle ──────────────────────────────────────────────────────────────
func _ready() -> void:
	# Connect to weather changes so friction updates in real-time.
	if has_node("/root/WeatherController"):
		if WeatherController.has_signal("weather_changed"):
			WeatherController.weather_changed.connect(_on_weather_changed)
	# Also connect to Gloria peak phase for extreme weather traction loss.
	if has_node("/root/GloriaEventDirector"):
		if GloriaEventDirector.has_signal("gloria_phase_changed"):
			GloriaEventDirector.gloria_phase_changed.connect(_on_gloria_phase_changed)

func _physics_process(_delta: float) -> void:
	_handle_input()
	_emit_speed_signal()
	_check_wheel_slip()

# ── Input Handling ─────────────────────────────────────────────────────────
func _handle_input() -> void:
	var throttle_input: float = Input.get_axis("ui_down", "ui_up")  # -1 reverse, +1 forward
	var steer_input: float    = Input.get_axis("ui_right", "ui_left") # -1 right, +1 left
	var brake_input: float    = 1.0 if Input.is_action_pressed("ui_select") else 0.0

	# Apply friction multiplier to effective engine force.
	engine_force = throttle_input * motor_force * _current_friction_multiplier
	steering     = steer_input * max_steer_angle
	brake        = brake_input * brake_force

# ── Signal Helpers ─────────────────────────────────────────────────────────
func _emit_speed_signal() -> void:
	# Speed in km/h (linear_velocity is m/s).
	var spd: float = linear_velocity.length() * 3.6
	if not is_equal_approx(spd, _prev_speed):
		emit_signal("speed_changed", spd)
		_prev_speed = spd

func _check_wheel_slip() -> void:
	# Simple heuristic: if friction multiplier is low and we're accelerating, flag slip.
	var slipping: bool = _current_friction_multiplier < 0.6 and absf(engine_force) > motor_force * 0.3
	if slipping != _was_slipping:
		emit_signal("wheel_slip", slipping)
		_was_slipping = slipping

# ── Weather Response ────────────────────────────────────────────────────────
func _on_weather_changed(state: String) -> void:
	match state:
		"CLEAR":
			_current_friction_multiplier = clear_friction
		"FOG":
			_current_friction_multiplier = fog_friction
		"RAIN", "COASTAL_RAIN":
			_current_friction_multiplier = rain_friction
		"NOREASTER":
			_current_friction_multiplier = noreaster_friction
		_:
			_current_friction_multiplier = clear_friction
	print("VehicleController: friction multiplier → %.2f (%s)" % [_current_friction_multiplier, state])

func _on_gloria_phase_changed(phase: int) -> void:
	# During Gloria PEAK, override friction to the configured peak traction multiplier.
	if has_node("/root/GloriaEventDirector"):
		var peak: int = GloriaEventDirector.GloriaPhase.PEAK
		if phase == peak:
			_current_friction_multiplier = GloriaEventDirector.peak_traction_multiplier
			print("VehicleController: Gloria PEAK traction = %.2f" % _current_friction_multiplier)
		elif phase == GloriaEventDirector.GloriaPhase.RESOLVED or phase == GloriaEventDirector.GloriaPhase.INACTIVE:
			# Return to clear-weather friction once storm ends.
			_current_friction_multiplier = clear_friction
