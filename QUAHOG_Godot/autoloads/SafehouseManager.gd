# SafehouseManager.gd
# Autoload singleton — add to Project > Autoloads as "SafehouseManager"
# res://autoloads/SafehouseManager.gd
extends Node

# ---------------------------------------------------------------------------
# Inner class
# ---------------------------------------------------------------------------
class Safehouse:
	var safehouse_id: String = ""
	var display_name: String = ""
	var position: Vector3 = Vector3.ZERO
	var is_unlocked: bool = false
	var is_discovered: bool = false

	func _init(
		id: String,
		dname: String,
		pos: Vector3,
		unlocked: bool = false,
		discovered: bool = false
	) -> void:
		safehouse_id = id
		display_name = dname
		position = pos
		is_unlocked = unlocked
		is_discovered = discovered

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var safehouses: Array = []          # Array[Safehouse]
var current_safehouse = null        # Safehouse or null

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal safehouse_entered(safehouse)
signal player_slept()

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
	_initialize_safehouses()

# ---------------------------------------------------------------------------
# Initialization
# ---------------------------------------------------------------------------
func _initialize_safehouses() -> void:
	safehouses.clear()

	# 1 – Flour Mill (unlocked + discovered from the start)
	safehouses.append(Safehouse.new(
		"flour_mill",
		"Old Quahog Flour Mill",
		Vector3(120.0, 0.0, -45.0),
		true,
		true
	))

	# 2 – Fisherman's Wharf (locked, undiscovered)
	safehouses.append(Safehouse.new(
		"fishermans_wharf",
		"Fisherman's Wharf Hideout",
		Vector3(-200.0, 0.0, 310.0),
		false,
		false
	))

	# 3 – Lighthouse Keeper's Cottage (locked, undiscovered)
	safehouses.append(Safehouse.new(
		"lighthouse_cottage",
		"Lighthouse Keeper's Cottage",
		Vector3(480.0, 12.0, -90.0),
		false,
		false
	))

	# 4 – Abandoned Cannery (locked, undiscovered)
	safehouses.append(Safehouse.new(
		"cannery",
		"Abandoned Cannery",
		Vector3(-350.0, 0.0, -220.0),
		false,
		false
	))

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------
func unlock_safehouse(id: String) -> void:
	var sh: Safehouse = _find_safehouse(id)
	if sh == null:
		push_warning("SafehouseManager: safehouse '%s' not found." % id)
		return
	sh.is_unlocked = true
	sh.is_discovered = true

func enter_safehouse(id: String) -> void:
	var sh: Safehouse = _find_safehouse(id)
	if sh == null:
		push_warning("SafehouseManager: safehouse '%s' not found." % id)
		return
	if not sh.is_unlocked:
		push_warning("SafehouseManager: safehouse '%s' is locked." % id)
		return
	sh.is_discovered = true
	current_safehouse = sh
	emit_signal("safehouse_entered", sh)

func sleep() -> void:
	# Advance time by 6 hours
	if Engine.has_singleton("TimeOfDayClock"):
		var clock = Engine.get_singleton("TimeOfDayClock")
		clock.advance_hours(6)
	elif get_node_or_null("/root/TimeOfDayClock") != null:
		get_node("/root/TimeOfDayClock").advance_hours(6)

	# Clear wanted heat
	if get_node_or_null("/root/HeatManager") != null:
		HeatManager.clear_heat()

	# Persist game state
	save_game()

	emit_signal("player_slept")

func save_game() -> void:
	if get_node_or_null("/root/SaveLoadManager") != null:
		get_node("/root/SaveLoadManager").save_game()
	else:
		push_warning("SafehouseManager: SaveLoadManager autoload not found; skipping save.")

func load_game() -> void:
	if get_node_or_null("/root/SaveLoadManager") != null:
		get_node("/root/SaveLoadManager").load_game()
	else:
		push_warning("SafehouseManager: SaveLoadManager autoload not found; skipping load.")

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
func _find_safehouse(id: String) -> Safehouse:
	for sh in safehouses:
		if sh.safehouse_id == id:
			return sh
	return null
