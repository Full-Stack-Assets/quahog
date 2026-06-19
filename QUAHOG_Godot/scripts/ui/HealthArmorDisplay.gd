# HealthArmorDisplay.gd
# Project QUAHOG — Dual progress-bar display for health and armor.
extends Control

# ──────────────────────────────────────────────
# Exports
# ──────────────────────────────────────────────
@export var health_bar: ProgressBar
@export var armor_bar: ProgressBar
@export var health_label: Label
@export var armor_label: Label

## Flash the health bar red when hit
@export var low_health_threshold: float = 25.0
@export var low_health_color: Color     = Color(1.0, 0.15, 0.15)
@export var normal_health_color: Color  = Color(0.18, 0.78, 0.25)

# ──────────────────────────────────────────────
# Private state
# ──────────────────────────────────────────────
var _health_tween: Tween = null
var _armor_tween: Tween  = null

# ──────────────────────────────────────────────
# Lifecycle
# ──────────────────────────────────────────────
func _ready() -> void:
	# Safe defaults so bars are not empty on first frame
	if health_bar:
		health_bar.min_value = 0.0
		health_bar.max_value = 100.0
		health_bar.value     = 100.0

	if armor_bar:
		armor_bar.min_value = 0.0
		armor_bar.max_value = 100.0
		armor_bar.value     = 0.0

	_update_health_label(100.0, 100.0)
	_update_armor_label(0.0, 100.0)


# ──────────────────────────────────────────────
# Public setters
# ──────────────────────────────────────────────
func set_health(value: float, max_val: float) -> void:
	value   = clampf(value, 0.0, max_val)
	max_val = maxf(max_val, 1.0)

	if health_bar:
		health_bar.max_value = max_val
		_animate_bar(health_bar, value, _health_tween, func(t: Tween) -> void:
			_health_tween = t
		)
		# Color the bar based on health level
		var fill_color: Color = low_health_color if (value / max_val) * 100.0 < low_health_threshold else normal_health_color
		_set_bar_color(health_bar, fill_color)

	_update_health_label(value, max_val)


func set_armor(value: float, max_val: float) -> void:
	value   = clampf(value, 0.0, max_val)
	max_val = maxf(max_val, 1.0)

	if armor_bar:
		armor_bar.max_value = max_val
		_animate_bar(armor_bar, value, _armor_tween, func(t: Tween) -> void:
			_armor_tween = t
		)

	_update_armor_label(value, max_val)


# ──────────────────────────────────────────────
# Private helpers
# ──────────────────────────────────────────────
func _animate_bar(bar: ProgressBar, target: float, _tween_ref: Tween, set_fn: Callable) -> void:
	if _tween_ref != null and _tween_ref.is_valid():
		_tween_ref.kill()
	var t: Tween = create_tween()
	t.tween_property(bar, "value", target, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	set_fn.call(t)


func _set_bar_color(bar: ProgressBar, color: Color) -> void:
	var style: StyleBoxFlat = bar.get_theme_stylebox("fill") as StyleBoxFlat
	if style:
		# Clone so we don't mutate a shared resource
		var clone: StyleBoxFlat = style.duplicate()
		clone.bg_color = color
		bar.add_theme_stylebox_override("fill", clone)


func _update_health_label(value: float, max_val: float) -> void:
	if health_label:
		health_label.text = "%d / %d" % [int(value), int(max_val)]


func _update_armor_label(value: float, max_val: float) -> void:
	if armor_label:
		armor_label.text = "%d / %d" % [int(value), int(max_val)]
