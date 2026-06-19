# FactionHostilityDisplay.gd
# Project QUAHOG — Shows per-faction aggro bars.
# Expects a HeatManager autoload with a `faction_aggro_changed(faction_id: String, aggro: float)` signal.
extends Control

# ──────────────────────────────────────────────
# Exports
# ──────────────────────────────────────────────
## Parallel arrays: index 0 is the first faction, etc.
@export var faction_bars:   Array[ProgressBar]
@export var faction_labels: Array[Label]

## Maps faction_id strings to bar indices (set via the Inspector or code)
## e.g. { "providence_mob": 0, "coast_guard": 1, "biker_club": 2, ... }
@export var faction_index_map: Dictionary = {}

# ──────────────────────────────────────────────
# Private state
# ──────────────────────────────────────────────
## Stores Tween per bar so animations don't pile up
var _tweens: Array = []

# ──────────────────────────────────────────────
# Lifecycle
# ──────────────────────────────────────────────
func _ready() -> void:
	# Initialise tween slots
	_tweens.resize(faction_bars.size())

	# Set bar ranges
	for bar in faction_bars:
		if bar:
			bar.min_value = 0.0
			bar.max_value = 100.0
			bar.value     = 0.0

	# Connect HeatManager
	var hm = get_node_or_null("/root/HeatManager")
	if hm:
		if not hm.faction_aggro_changed.is_connected(_on_faction_aggro_changed):
			hm.faction_aggro_changed.connect(_on_faction_aggro_changed)
	else:
		push_warning("FactionHostilityDisplay: HeatManager autoload not found.")


# ──────────────────────────────────────────────
# Signal handler
# ──────────────────────────────────────────────
func _on_faction_aggro_changed(faction_id: String, aggro: float) -> void:
	update_faction(faction_id, aggro)


# ──────────────────────────────────────────────
# Public API
# ──────────────────────────────────────────────
func update_faction(faction_id: String, aggro: float) -> void:
	var idx: int = _get_faction_index(faction_id)
	if idx < 0:
		return

	aggro = clampf(aggro, 0.0, 100.0)

	if idx < faction_bars.size() and faction_bars[idx] != null:
		_animate_bar(idx, aggro)

	if idx < faction_labels.size() and faction_labels[idx] != null:
		faction_labels[idx].text = "%s: %d%%" % [faction_id.capitalize(), int(aggro)]


## Register (or overwrite) the bar index for a faction id at runtime.
func register_faction(faction_id: String, index: int) -> void:
	faction_index_map[faction_id] = index


# ──────────────────────────────────────────────
# Private helpers
# ──────────────────────────────────────────────
func _get_faction_index(faction_id: String) -> int:
	if faction_index_map.has(faction_id):
		return faction_index_map[faction_id]
	# Fallback: try matching label text
	for i in faction_labels.size():
		if faction_labels[i] and faction_labels[i].text.to_lower().begins_with(faction_id.to_lower()):
			return i
	push_warning("FactionHostilityDisplay: unknown faction id '%s'" % faction_id)
	return -1


func _animate_bar(idx: int, target: float) -> void:
	var existing = _tweens[idx]
	if existing != null and (existing as Tween).is_valid():
		(existing as Tween).kill()

	var t: Tween = create_tween()
	t.tween_property(faction_bars[idx], "value", target, 0.4)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	_tweens[idx] = t
