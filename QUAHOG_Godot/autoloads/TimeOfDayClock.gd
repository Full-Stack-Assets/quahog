## TimeOfDayClock.gd
## Autoload singleton — registered in project.godot as "TimeOfDayClock"
## Tracks in-game time (0.0–24.0 hours) and emits signals on hour/day boundaries.
## Converted from TimeOfDayClock.cs (Unity C#) for Project QUAHOG / Godot 4

extends Node

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------

## Real-world seconds that correspond to one in-game hour.
@export var seconds_per_game_hour: float = 60.0

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal hour_changed(hour: int)
signal midnight()
signal day_changed(day: int)

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

## Current game time in fractional hours, range [0.0, 24.0).
var current_time: float = 0.0

## Current in-game day (1-indexed).
var current_day: int = 1

# Private tracking of the last whole hour so we only fire once per hour.
var _last_hour: int = 0

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
	_last_hour = int(current_time)

func _process(delta: float) -> void:
	# Convert real seconds to fractional in-game hours
	var hours_per_second: float = 1.0 / seconds_per_game_hour
	current_time += delta * hours_per_second

	# Hour boundary check
	var new_hour: int = int(current_time) % 24
	if new_hour != _last_hour:
		_last_hour = new_hour
		hour_changed.emit(new_hour)

	# Day rollover
	if current_time >= 24.0:
		current_time = fmod(current_time, 24.0)
		current_day += 1
		midnight.emit()
		day_changed.emit(current_day)

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Jump the clock to a specific hour (0–23).
func set_time(hour: int) -> void:
	current_time = clampf(float(hour), 0.0, 23.9999)
	_last_hour = int(current_time)
	hour_changed.emit(_last_hour)

## Override the current day counter.
func set_day(day: int) -> void:
	current_day = maxi(1, day)
	day_changed.emit(current_day)

## Advance the clock by a whole number of in-game hours.
## Handles midnight rollovers correctly.
func advance_hours(hours: int) -> void:
	current_time += float(hours)
	while current_time >= 24.0:
		current_time -= 24.0
		current_day += 1
		midnight.emit()
		day_changed.emit(current_day)
	_last_hour = int(current_time)
	hour_changed.emit(_last_hour)

## Returns current time as a formatted string "HH:MM".
func get_time_string() -> String:
	var h: int = int(current_time) % 24
	var m: int = int((current_time - int(current_time)) * 60.0)
	return "%02d:%02d" % [h, m]
