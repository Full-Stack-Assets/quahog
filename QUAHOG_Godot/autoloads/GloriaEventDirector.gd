# GloriaEventDirector.gd  (Autoload)
# Drives the 5-phase Hurricane Gloria event sequence for Project QUAHOG.
# Phases: INACTIVE → WARNING → PEAK → AFTERMATH → RESOLVED
# Register via Project → Autoload as "GloriaEventDirector".
extends Node

# ── Phase Enum ─────────────────────────────────────────────────────────────
enum GloriaPhase {
	INACTIVE   = 0,
	WARNING    = 1,
	PEAK       = 2,
	AFTERMATH  = 3,
	RESOLVED   = 4
}

# ── Exports ────────────────────────────────────────────────────────────────
@export var warning_duration: float = 120.0
@export var peak_duration: float = 300.0
@export var aftermath_duration: float = 180.0
@export var peak_traction_multiplier: float = 0.45
@export var peak_wind_force: float = 50.0
@export var auto_trigger_randomly: bool = false
@export var random_trigger_chance: float = 0.001

# ── Signals ────────────────────────────────────────────────────────────────
signal gloria_phase_changed(phase: int)

# ── State ──────────────────────────────────────────────────────────────────
var current_phase: int = GloriaPhase.INACTIVE
var _sequence_running: bool = false

# ── Lifecycle ──────────────────────────────────────────────────────────────
func _ready() -> void:
	current_phase = GloriaPhase.INACTIVE

func _process(_delta: float) -> void:
	if auto_trigger_randomly and current_phase == GloriaPhase.INACTIVE and not _sequence_running:
		if randf() < random_trigger_chance:
			start_gloria()

# ── Public API ─────────────────────────────────────────────────────────────

## Begins the full Gloria sequence from WARNING phase.
func start_gloria() -> void:
	if _sequence_running:
		push_warning("GloriaEventDirector: sequence already running.")
		return
	_sequence_running = true
	_run_sequence()

## Jump directly to a specific phase (for testing / scripted triggers).
func skip_to_phase(phase: int) -> void:
	_set_phase(phase)

## Immediately abort the event and return to INACTIVE.
func abort_gloria() -> void:
	_sequence_running = false
	_set_phase(GloriaPhase.INACTIVE)
	print("GloriaEventDirector: aborted.")

# ── Private ────────────────────────────────────────────────────────────────

## Async sequence: Warning → Peak → Aftermath → Resolved
func _run_sequence() -> void:
	# ── WARNING ────────────────────────────────────────────────────────────
	_set_phase(GloriaPhase.WARNING)
	if WeatherController.has_method("force_state"):
		WeatherController.force_state("COASTAL_RAIN")
	await get_tree().create_timer(warning_duration).timeout
	if not _sequence_running:
		return

	# ── PEAK ───────────────────────────────────────────────────────────────
	_set_phase(GloriaPhase.PEAK)
	if WeatherController.has_method("force_state"):
		WeatherController.force_state("NOREASTER")
	await get_tree().create_timer(peak_duration).timeout
	if not _sequence_running:
		return

	# ── AFTERMATH ──────────────────────────────────────────────────────────
	_set_phase(GloriaPhase.AFTERMATH)
	await get_tree().create_timer(aftermath_duration).timeout
	if not _sequence_running:
		return

	# ── RESOLVED ───────────────────────────────────────────────────────────
	_set_phase(GloriaPhase.RESOLVED)
	_sequence_running = false
	print("GloriaEventDirector: sequence complete.")

func _set_phase(phase: int) -> void:
	current_phase = phase
	emit_signal("gloria_phase_changed", phase)
	print("GloriaEventDirector: phase → %s" % GloriaPhase.keys()[phase])
