# HUDManager.gd
# Project QUAHOG — autoload singleton
# Manages the top-level HUD CanvasLayer and all child HUD widgets.
# Register as an autoload in Project Settings: "HUDManager" → res://autoloads/HUDManager.gd
extends CanvasLayer

# ──────────────────────────────────────────────
# Exported widget references (assign in scene or via @onready in a sub-scene)
# ──────────────────────────────────────────────
@export var minimap: Node
@export var wanted_display: Node
@export var faction_display: Node
@export var district_display: Node
@export var cash_counter: Node
@export var health_armor: Node
@export var radio_widget: Node
@export var radar_blips: Node

@export var mission_prompt_label: Label
@export var mission_prompt_panel: Control

# ──────────────────────────────────────────────
# Signals
# ──────────────────────────────────────────────
signal hud_shown()
signal hud_hidden()

# ──────────────────────────────────────────────
# Internal state
# ──────────────────────────────────────────────
var _prompt_tween: Tween = null   # Track running prompt tween so we can cancel it

# ──────────────────────────────────────────────
# Lifecycle
# ──────────────────────────────────────────────
func _ready() -> void:
	# Hide mission prompt by default
	if mission_prompt_panel:
		mission_prompt_panel.visible = false
	if mission_prompt_label:
		mission_prompt_label.text = ""


# ──────────────────────────────────────────────
# Visibility control
# ──────────────────────────────────────────────
func show_hud() -> void:
	visible = true
	emit_signal("hud_shown")


func hide_hud() -> void:
	visible = false
	emit_signal("hud_hidden")


func set_hud_visible(is_visible: bool) -> void:
	if is_visible:
		show_hud()
	else:
		hide_hud()


# ──────────────────────────────────────────────
# Mission prompt
# ──────────────────────────────────────────────
## Shows a mission prompt for `duration` seconds, then hides it.
## Calling this while a prompt is visible cancels the previous one.
func show_mission_prompt(text: String, duration: float) -> void:
	# Cancel any in-flight prompt tween / timer
	if _prompt_tween != null and _prompt_tween.is_valid():
		_prompt_tween.kill()
		_prompt_tween = null

	if mission_prompt_label == null or mission_prompt_panel == null:
		push_warning("HUDManager: mission_prompt_label or mission_prompt_panel is null")
		return

	mission_prompt_label.text = text
	mission_prompt_panel.modulate.a = 1.0
	mission_prompt_panel.visible = true

	# Use a Tween as a timer so we can cancel cleanly
	_prompt_tween = create_tween()
	# Hold for `duration` seconds (animate a dummy property with zero change)
	_prompt_tween.tween_interval(duration)
	# Then fade out over 0.5 s
	_prompt_tween.tween_property(mission_prompt_panel, "modulate:a", 0.0, 0.5)
	# Then hide
	_prompt_tween.tween_callback(func() -> void:
		mission_prompt_panel.visible = false
		mission_prompt_label.text = ""
	)


# ──────────────────────────────────────────────
# Radar blips
# ──────────────────────────────────────────────
func update_radar_blips() -> void:
	if radar_blips != null and radar_blips.has_method("update_blip_positions"):
		radar_blips.update_blip_positions()


# ──────────────────────────────────────────────
# Convenience pass-throughs to child widgets
# ──────────────────────────────────────────────
func set_health(value: float, max_val: float) -> void:
	if health_armor != null and health_armor.has_method("set_health"):
		health_armor.set_health(value, max_val)


func set_armor(value: float, max_val: float) -> void:
	if health_armor != null and health_armor.has_method("set_armor"):
		health_armor.set_armor(value, max_val)


func show_district(district_name: String) -> void:
	if district_display != null and district_display.has_method("show_district"):
		district_display.show_district(district_name)
