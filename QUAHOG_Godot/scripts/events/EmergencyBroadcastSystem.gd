# EmergencyBroadcastSystem.gd
# Triggers the Emergency Alert System (EAS) tone and overrides in-game radio
# during the Gloria hurricane event or any scripted emergency.
# Requires an AudioStreamPlayer assigned to eas_player.
# Autoload referenced: RadioManager (optional).
extends Node

class_name EmergencyBroadcastSystem

# ── Exports ────────────────────────────────────────────────────────────────
@export var broadcast_audio: AudioStream       # EAS tone / message audio clip
@export var eas_player: AudioStreamPlayer      # dedicated AudioStreamPlayer node

# ── Signals ────────────────────────────────────────────────────────────────
signal broadcast_started()
signal broadcast_ended()

# ── State ──────────────────────────────────────────────────────────────────
var _is_broadcasting: bool = false
var _current_message: String = ""

# ── Lifecycle ──────────────────────────────────────────────────────────────
func _ready() -> void:
	if eas_player == null:
		push_warning("EmergencyBroadcastSystem: eas_player not assigned.")

# ── Public API ─────────────────────────────────────────────────────────────

## Triggers an emergency broadcast for `duration` seconds.
## message  — text shown on the HUD / passed to any UI listener.
## duration — how long the broadcast overrides the radio (seconds).
func trigger_broadcast(message: String, duration: float) -> void:
	if _is_broadcasting:
		push_warning("EmergencyBroadcastSystem: broadcast already active.")
		return
	_run_broadcast(message, duration)

## Returns true if a broadcast is currently active.
func is_broadcasting() -> bool:
	return _is_broadcasting

# ── Private ────────────────────────────────────────────────────────────────
func _run_broadcast(message: String, duration: float) -> void:
	_is_broadcasting = true
	_current_message = message

	# Override in-game radio.
	if has_node("/root/RadioManager") and RadioManager.has_method("duck_audio"):
		RadioManager.duck_audio(true)

	# Play the EAS tone / audio.
	if eas_player != null and broadcast_audio != null:
		eas_player.stream = broadcast_audio
		eas_player.play()

	emit_signal("broadcast_started")
	print("EmergencyBroadcastSystem: broadcast started — '%s'" % message)

	await get_tree().create_timer(duration).timeout

	# Restore radio.
	if has_node("/root/RadioManager") and RadioManager.has_method("duck_audio"):
		RadioManager.duck_audio(false)

	if eas_player != null and eas_player.playing:
		eas_player.stop()

	_is_broadcasting = false
	_current_message = ""
	emit_signal("broadcast_ended")
	print("EmergencyBroadcastSystem: broadcast ended.")
