# RadioStationWidget.gd
# Project QUAHOG — HUD widget displaying the current radio station and song.
# Expects a RadioManager autoload with:
#   - `station_changed(station: int)` signal
#   - `song_changed(title: String)` signal
extends Control

# ──────────────────────────────────────────────
# Exports
# ──────────────────────────────────────────────
@export var station_label: Label
@export var song_label: Label

## Names for each station index — order must match RadioManager's station enum
@export var station_names: Array[String] = [
	"WQHG 98.6 — ROCK",
	"WBAY 103.1 — NEW WAVE",
	"WCOD 107.9 — COUNTRY",
	"WKAZ 88.3 — JAZZ",
	"WQNT 92.5 — TALK RADIO",
]

## How long to show the song title on change before fading
@export var song_display_duration: float = 4.0
@export var fade_duration: float         = 0.8

# ──────────────────────────────────────────────
# Private state
# ──────────────────────────────────────────────
var _song_fade_tween: Tween = null

# ──────────────────────────────────────────────
# Lifecycle
# ──────────────────────────────────────────────
func _ready() -> void:
	if song_label:
		song_label.modulate.a = 0.0

	var rm = get_node_or_null("/root/RadioManager")
	if rm:
		if not rm.station_changed.is_connected(_on_station_changed):
			rm.station_changed.connect(_on_station_changed)
		if not rm.song_changed.is_connected(_on_song_changed):
			rm.song_changed.connect(_on_song_changed)

		# Initialise from current state if available
		if rm.has_method("get_current_station"):
			_on_station_changed(rm.get_current_station())
		if rm.has_method("get_current_song"):
			_on_song_changed(rm.get_current_song())
	else:
		push_warning("RadioStationWidget: RadioManager autoload not found.")


# ──────────────────────────────────────────────
# Signal handlers
# ──────────────────────────────────────────────
func _on_station_changed(station: int) -> void:
	if station_label == null:
		return
	if station >= 0 and station < station_names.size():
		station_label.text = station_names[station]
	else:
		station_label.text = "RADIO OFF"


func _on_song_changed(title: String) -> void:
	if song_label == null:
		return

	# Cancel previous fade
	if _song_fade_tween != null and _song_fade_tween.is_valid():
		_song_fade_tween.kill()

	song_label.text      = title
	song_label.modulate.a = 1.0

	# Auto-fade after display_duration
	_song_fade_tween = create_tween()
	_song_fade_tween.tween_interval(song_display_duration)
	_song_fade_tween.tween_property(song_label, "modulate:a", 0.0, fade_duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)


# ──────────────────────────────────────────────
# Public helpers
# ──────────────────────────────────────────────
func show_song_immediately(title: String) -> void:
	_on_song_changed(title)
