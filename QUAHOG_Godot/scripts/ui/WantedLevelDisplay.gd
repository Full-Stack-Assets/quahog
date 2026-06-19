# WantedLevelDisplay.gd
# Project QUAHOG — HUD widget that shows 1–5 wanted stars.
# Expects a HeatManager autoload with a `wanted_level_changed(level: int)` signal.
extends Control

# ──────────────────────────────────────────────
# Exports
# ──────────────────────────────────────────────
## Exactly 5 TextureRect nodes ordered star-1 … star-5
@export var star_icons: Array[TextureRect]

@export var filled_texture: Texture2D   ## Lit star
@export var empty_texture: Texture2D    ## Dim star

# ──────────────────────────────────────────────
# Lifecycle
# ──────────────────────────────────────────────
func _ready() -> void:
	# Connect to HeatManager if it's available as an autoload
	if Engine.has_singleton("HeatManager"):
		var hm = Engine.get_singleton("HeatManager")
		if not hm.wanted_level_changed.is_connected(_on_wanted_level_changed):
			hm.wanted_level_changed.connect(_on_wanted_level_changed)
	else:
		# Fallback: try get_node on the autoload tree path
		var hm = get_node_or_null("/root/HeatManager")
		if hm:
			if not hm.wanted_level_changed.is_connected(_on_wanted_level_changed):
				hm.wanted_level_changed.connect(_on_wanted_level_changed)
		else:
			push_warning("WantedLevelDisplay: HeatManager autoload not found.")

	# Start at zero
	_on_wanted_level_changed(0)


# ──────────────────────────────────────────────
# Signal handlers
# ──────────────────────────────────────────────
func _on_wanted_level_changed(level: int) -> void:
	level = clampi(level, 0, star_icons.size())

	for i in star_icons.size():
		var icon: TextureRect = star_icons[i]
		if icon == null:
			continue

		if i < level:
			# Lit star
			icon.texture = filled_texture
			icon.modulate = Color.WHITE
		else:
			# Unlit star — half-opacity dim look
			icon.texture = empty_texture if empty_texture else filled_texture
			icon.modulate = Color(1.0, 1.0, 1.0, 0.35)


# ──────────────────────────────────────────────
# Public helpers
# ──────────────────────────────────────────────
## Force an immediate visual refresh (e.g. after scene load)
func refresh(level: int) -> void:
	_on_wanted_level_changed(level)
