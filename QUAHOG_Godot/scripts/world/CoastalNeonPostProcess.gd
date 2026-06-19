## CoastalNeonPostProcess.gd
## res://scripts/world/CoastalNeonPostProcess.gd
## Applies per-district neon color grading by tweening the Environment's
## ambient_light_color.  Attach to a Node inside your post-process scene.
## Converted from CoastalNeonPostProcess.cs (Unity C#) for Project QUAHOG / Godot 4

extends Node

# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------
enum District {
	NEW_SEFTON,
	DIGHTON,
	TAUNTON_HILL,
	SAWYER
}

# ---------------------------------------------------------------------------
# Exports — Environment reference
# ---------------------------------------------------------------------------

## The Environment resource from the scene's WorldEnvironment node.
@export var environment: Environment

# ---------------------------------------------------------------------------
# Exports — Per-district ambient colors
# ---------------------------------------------------------------------------

## New Sefton — cool harbour blue-white neon.
@export var new_sefton_color: Color = Color(0.35, 0.45, 0.85, 1.0)

## Dighton — warm amber/copper neon strip.
@export var dighton_color: Color = Color(0.85, 0.50, 0.20, 1.0)

## Taunton Hill — cold cyan industrial glow.
@export var taunton_hill_color: Color = Color(0.20, 0.75, 0.80, 1.0)

## Sawyer — deep violet underground neon.
@export var sawyer_color: Color = Color(0.55, 0.20, 0.80, 1.0)

# ---------------------------------------------------------------------------
# Exports — Grade parameters
# ---------------------------------------------------------------------------

## Master intensity multiplier applied to all district colors.
@export var grade_intensity: float = 0.45

## Seconds for the ambient color to blend from one district to the next.
@export var blend_duration: float = 1.5

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal district_grade_changed(grade: int)

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var current_grade: int = District.NEW_SEFTON
var _active_tween: Tween = null

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
	if environment == null:
		push_warning("CoastalNeonPostProcess: No Environment resource assigned.")
		return
	# Snap to the initial district without animation.
	environment.ambient_light_color = _color_for_grade(current_grade)

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Transition the color grade to the given district enum value.
func set_district_grade(grade: int) -> void:
	if environment == null:
		push_warning("CoastalNeonPostProcess: Cannot set grade — Environment is null.")
		return

	if grade == current_grade:
		return

	current_grade = grade
	var target_color: Color = _color_for_grade(grade)

	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()

	_active_tween = create_tween()
	_active_tween.set_ease(Tween.EASE_IN_OUT)
	_active_tween.set_trans(Tween.TRANS_SINE)
	_active_tween.tween_property(
		environment,
		"ambient_light_color",
		target_color,
		blend_duration
	)

	district_grade_changed.emit(grade)

## Returns the name string for a given District enum value.
func get_district_name(grade: int) -> String:
	match grade:
		District.NEW_SEFTON:   return "New Sefton"
		District.DIGHTON:      return "Dighton"
		District.TAUNTON_HILL: return "Taunton Hill"
		District.SAWYER:       return "Sawyer"
	return "Unknown"

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------
func _color_for_grade(grade: int) -> Color:
	var base_color: Color
	match grade:
		District.NEW_SEFTON:
			base_color = new_sefton_color
		District.DIGHTON:
			base_color = dighton_color
		District.TAUNTON_HILL:
			base_color = taunton_hill_color
		District.SAWYER:
			base_color = sawyer_color
		_:
			push_warning("CoastalNeonPostProcess: Unknown grade %d." % grade)
			base_color = new_sefton_color

	# Apply grade_intensity as a linear scale on the RGB channels.
	return Color(
		base_color.r * grade_intensity,
		base_color.g * grade_intensity,
		base_color.b * grade_intensity,
		base_color.a
	)
