# HeatManager.gd
# Autoload singleton — add to Project > Autoloads as "HeatManager"
# res://autoloads/HeatManager.gd
extends Node

# ---------------------------------------------------------------------------
# Inner class
# ---------------------------------------------------------------------------
class FactionAggro:
	var faction_id: String = ""
	var aggro: float = 0.0

	func _init(fid: String, a: float = 0.0) -> void:
		faction_id = fid
		aggro = a

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------
@export var wanted_decay_rate: float = 0.5

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var wanted_level: int = 0
var faction_aggros: Array = []          # Array[FactionAggro]

# Accumulator for sub-level decay
var _decay_accumulator: float = 0.0

# Internal float heat (0.0 – 5.0) for smooth decay
var _heat: float = 0.0

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal wanted_level_changed(level: int)
signal faction_aggro_changed(faction_id: String, aggro: float)
signal heat_cleared()

# ---------------------------------------------------------------------------
# Properties
# ---------------------------------------------------------------------------
var current_heat: float:
	get:
		return _heat
	set(value):
		set_heat(value)

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _process(delta: float) -> void:
	if _heat <= 0.0:
		return

	# Accumulate decay
	_decay_accumulator += wanted_decay_rate * delta

	# Each accumulated point reduces heat by 1 (one wanted level)
	while _decay_accumulator >= 1.0:
		_decay_accumulator -= 1.0
		_heat = maxf(_heat - 1.0, 0.0)

	var new_level: int = int(_heat)
	if new_level != wanted_level:
		wanted_level = new_level
		emit_signal("wanted_level_changed", wanted_level)

	if _heat <= 0.0:
		_heat = 0.0
		_decay_accumulator = 0.0

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------
func add_wanted_level(amount: int) -> void:
	set_wanted_level(wanted_level + amount)

func set_wanted_level(level: int) -> void:
	wanted_level = clampi(level, 0, 5)
	_heat = float(wanted_level)
	_decay_accumulator = 0.0
	emit_signal("wanted_level_changed", wanted_level)

func add_faction_aggro(faction_id: String, amount: float) -> void:
	var entry: FactionAggro = _get_or_create_faction_aggro(faction_id)
	entry.aggro = clampf(entry.aggro + amount, 0.0, 100.0)
	emit_signal("faction_aggro_changed", faction_id, entry.aggro)

func get_faction_aggro(faction_id: String) -> float:
	for entry in faction_aggros:
		if entry.faction_id == faction_id:
			return entry.aggro
	return 0.0

func is_heat_active() -> bool:
	return wanted_level > 0

func clear_heat() -> void:
	wanted_level = 0
	_heat = 0.0
	_decay_accumulator = 0.0
	for entry in faction_aggros:
		entry.aggro = 0.0
	emit_signal("heat_cleared")
	emit_signal("wanted_level_changed", 0)

func set_heat(heat: float) -> void:
	_heat = clampf(heat, 0.0, 5.0)
	_decay_accumulator = 0.0
	var new_level: int = int(_heat)
	if new_level != wanted_level:
		wanted_level = new_level
		emit_signal("wanted_level_changed", wanted_level)

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------
func _get_or_create_faction_aggro(faction_id: String) -> FactionAggro:
	for entry in faction_aggros:
		if entry.faction_id == faction_id:
			return entry
	var new_entry := FactionAggro.new(faction_id, 0.0)
	faction_aggros.append(new_entry)
	return new_entry
