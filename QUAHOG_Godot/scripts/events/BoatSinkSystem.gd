# BoatSinkSystem.gd
# Manages the 3-stage sinking animation for boats during the Gloria flood event.
# Stages: FLOATING → SINKING → SUBMERGED
# Attach to the boat's root Node3D (or as a child). The node itself is moved/tilted.
extends Node3D

# ── Stage Enum ─────────────────────────────────────────────────────────────
enum SinkStage {
	FLOATING   = 0,
	SINKING    = 1,
	SUBMERGED  = 2
}

# ── Exports ────────────────────────────────────────────────────────────────
@export var sink_duration: float = 10.0  # total time from tilt to submerged
@export var sink_depth: float = -8.0     # final Y offset relative to start

# ── Signals ────────────────────────────────────────────────────────────────
signal stage_changed(stage: int)
signal sinking_started()
signal boat_submerged()

# ── State ──────────────────────────────────────────────────────────────────
var _current_stage: int = SinkStage.FLOATING
var _is_sinking: bool = false
var _start_y: float = 0.0
var _target_y: float = 0.0
var _elapsed: float = 0.0
var _start_rotation: Basis = Basis.IDENTITY
var _tilt_rotation: Basis = Basis.IDENTITY

# ── Lifecycle ──────────────────────────────────────────────────────────────
func _ready() -> void:
	_start_y = global_position.y
	_target_y = _start_y + sink_depth
	_start_rotation = global_transform.basis

func _process(delta: float) -> void:
	if not _is_sinking:
		return

	_elapsed += delta
	var t: float = clampf(_elapsed / sink_duration, 0.0, 1.0)

	# Smoothly move downward.
	var new_y: float = lerpf(_start_y, _target_y, t)
	global_position.y = new_y

	# Gradually tilt the boat (rotate ~25° on Z axis as it sinks).
	global_transform.basis = _start_rotation.slerp(_tilt_rotation, t)

	if t >= 1.0:
		_is_sinking = false
		_set_stage(SinkStage.SUBMERGED)
		emit_signal("boat_submerged")
		print("BoatSinkSystem: '%s' is now submerged." % name)

# ── Public API ─────────────────────────────────────────────────────────────

## Begins the async sink sequence: tilt → descend → submerge.
func start_sinking() -> void:
	if _current_stage != SinkStage.FLOATING:
		push_warning("BoatSinkSystem '%s': already sinking or submerged." % name)
		return

	_set_stage(SinkStage.SINKING)
	emit_signal("sinking_started")
	print("BoatSinkSystem: '%s' is sinking." % name)

	_start_y = global_position.y
	_target_y = _start_y + sink_depth
	_start_rotation = global_transform.basis
	# Tilt about 25 degrees on the local Z axis (list to starboard).
	_tilt_rotation = _start_rotation * Basis(Vector3.FORWARD, deg_to_rad(25.0))
	_elapsed = 0.0
	_is_sinking = true

## Returns the current SinkStage integer.
func get_stage() -> int:
	return _current_stage

# ── Private ────────────────────────────────────────────────────────────────
func _set_stage(stage: int) -> void:
	_current_stage = stage
	emit_signal("stage_changed", stage)
