# DistrictNameDisplay.gd
# Project QUAHOG — Displays a district name when the player enters a new zone,
# then fades out after `display_duration` seconds.
extends Control

# ──────────────────────────────────────────────
# Exports
# ──────────────────────────────────────────────
@export var label: Label
@export var display_duration: float = 3.0   ## How long the label stays fully visible
@export var fade_duration: float    = 0.8   ## Fade-out duration

# ──────────────────────────────────────────────
# Private state
# ──────────────────────────────────────────────
var _tween: Tween = null

# ──────────────────────────────────────────────
# Lifecycle
# ──────────────────────────────────────────────
func _ready() -> void:
	modulate.a = 0.0
	visible = false


# ──────────────────────────────────────────────
# Public API
# ──────────────────────────────────────────────
## Call this when the player crosses into a new district.
func show_district(district_name: String) -> void:
	if label == null:
		push_warning("DistrictNameDisplay: label node is null")
		return

	# Cancel any ongoing animation
	if _tween != null and _tween.is_valid():
		_tween.kill()
		_tween = null

	label.text = district_name
	visible    = true
	modulate.a = 1.0

	_tween = create_tween()
	# Hold fully visible for display_duration
	_tween.tween_interval(display_duration)
	# Fade out
	_tween.tween_property(self, "modulate:a", 0.0, fade_duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)
	# Then hide completely so it doesn't intercept input
	_tween.tween_callback(func() -> void:
		visible = false
	)


func hide_immediately() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
		_tween = null
	modulate.a = 0.0
	visible = false
