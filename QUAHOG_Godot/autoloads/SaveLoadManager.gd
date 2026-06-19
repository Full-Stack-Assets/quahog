## SaveLoadManager.gd
## Autoload singleton — handles save/load/delete for up to MAX_SAVE_SLOTS slots.
## Uses SHA-256 checksums for save-file integrity validation.
## Ported from SaveLoadManager.cs (Unity) to Godot 4 GDScript.
## Access via: SaveLoadManager.<method>
extends Node

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
const MAX_SAVE_SLOTS: int = 5
const SAVE_VERSION: String = "1.0.0"
const SAVE_DIR_SUFFIX: String = "/saves/"

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal save_started(slot: int)
signal save_completed(slot: int, success: bool)
signal load_started(slot: int)
signal load_completed(slot: int, success: bool)
signal save_deleted(slot: int)

# ---------------------------------------------------------------------------
# Private state
# ---------------------------------------------------------------------------
var _save_dir: String = ""

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
	_save_dir = OS.get_user_data_dir() + SAVE_DIR_SUFFIX
	_ensure_save_dir()
	# Listen for GameManager auto-save trigger
	GameManager.auto_save.connect(_on_auto_save)
	print("[SaveLoadManager] Initialised. Save dir: %s" % _save_dir)


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Saves the current game state to the given slot (0-indexed).
## Returns true on success.
func save_game(slot: int) -> bool:
	if not _is_valid_slot(slot):
		push_error("[SaveLoadManager] Invalid slot: %d" % slot)
		return false

	emit_signal("save_started", slot)

	# Gather data from all relevant autoloads
	var data: Dictionary = _collect_save_data()
	var json_string: String = JSON.stringify(data, "\t")

	# Compute SHA-256 checksum
	var checksum: String = _compute_sha256(json_string)

	# Wrap with envelope
	var envelope: Dictionary = {
		"checksum": checksum,
		"data": data,
	}
	var final_json: String = JSON.stringify(envelope, "\t")

	# Write to disk
	var path: String = _slot_path(slot)
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("[SaveLoadManager] Cannot open file for writing: %s (error %d)" % [path, FileAccess.get_open_error()])
		emit_signal("save_completed", slot, false)
		return false

	file.store_string(final_json)
	file.close()

	print("[SaveLoadManager] Game saved to slot %d (%s)." % [slot, path])
	emit_signal("save_completed", slot, true)
	return true


## Loads a save from the given slot into all relevant autoloads.
## Returns true on success.
func load_game(slot: int) -> bool:
	if not _is_valid_slot(slot):
		push_error("[SaveLoadManager] Invalid slot: %d" % slot)
		return false
	if not has_save(slot):
		push_error("[SaveLoadManager] No save found in slot %d." % slot)
		return false

	emit_signal("load_started", slot)

	var path: String = _slot_path(slot)
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[SaveLoadManager] Cannot open file for reading: %s (error %d)" % [path, FileAccess.get_open_error()])
		emit_signal("load_completed", slot, false)
		return false

	var raw: String = file.get_as_text()
	file.close()

	# Parse envelope
	var envelope = JSON.parse_string(raw)
	if envelope == null or not envelope is Dictionary:
		push_error("[SaveLoadManager] Failed to parse save file in slot %d." % slot)
		emit_signal("load_completed", slot, false)
		return false

	# Validate checksum
	var stored_checksum: String = envelope.get("checksum", "")
	var data: Dictionary = envelope.get("data", {})
	var recomputed_checksum: String = _compute_sha256(JSON.stringify(data, "\t"))

	if stored_checksum != recomputed_checksum:
		push_error("[SaveLoadManager] Checksum mismatch in slot %d — save may be corrupted or tampered." % slot)
		emit_signal("load_completed", slot, false)
		return false

	# Check version compatibility
	var save_version: String = data.get("save_version", "")
	if save_version != SAVE_VERSION:
		push_warning("[SaveLoadManager] Save version mismatch: file=%s, expected=%s. Attempting load anyway." % [save_version, SAVE_VERSION])

	# Restore state to autoloads
	_apply_save_data(data)

	print("[SaveLoadManager] Loaded slot %d successfully." % slot)
	emit_signal("load_completed", slot, true)
	return true


## Deletes the save file in the given slot.
func delete_save(slot: int) -> void:
	if not _is_valid_slot(slot):
		push_error("[SaveLoadManager] Invalid slot: %d" % slot)
		return
	var path: String = _slot_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		print("[SaveLoadManager] Deleted save in slot %d." % slot)
		emit_signal("save_deleted", slot)
	else:
		print("[SaveLoadManager] No file to delete in slot %d." % slot)


## Returns true if a save file exists in the given slot.
func has_save(slot: int) -> bool:
	if not _is_valid_slot(slot):
		return false
	return FileAccess.file_exists(_slot_path(slot))


## Returns metadata dictionary for the given slot, or empty dict if no save.
## Keys: slot, save_version, current_day, current_time, wallet_balance, wanted_level, timestamp
func get_save_metadata(slot: int) -> Dictionary:
	if not has_save(slot):
		return {}

	var path: String = _slot_path(slot)
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}

	var raw: String = file.get_as_text()
	file.close()

	var envelope = JSON.parse_string(raw)
	if envelope == null or not envelope is Dictionary:
		return {}

	var data: Dictionary = envelope.get("data", {})
	return {
		"slot": slot,
		"save_version": data.get("save_version", ""),
		"current_day": data.get("current_day", 0),
		"current_time": data.get("current_time", 0.0),
		"wallet_balance": data.get("wallet_balance", 0.0),
		"wanted_level": data.get("wanted_level", 0),
		"timestamp": data.get("timestamp", ""),
	}


## Returns metadata for all slots as an Array of Dictionaries (empties for missing slots).
func get_all_save_metadata() -> Array:
	var result: Array = []
	for i in range(MAX_SAVE_SLOTS):
		result.append(get_save_metadata(i))
	return result

# ---------------------------------------------------------------------------
# Internal — data collection / application
# ---------------------------------------------------------------------------

func _collect_save_data() -> Dictionary:
	# Player position / rotation — the PlayerController autoload or node may
	# not exist in all scenes; use ServiceLocator as fallback.
	var player_position: Vector3 = Vector3.ZERO
	var player_rotation: Vector3 = Vector3.ZERO

	if ServiceLocator.has_service("PlayerController"):
		var pc = ServiceLocator.get_service("PlayerController")
		player_position = pc.global_position
		player_rotation = pc.rotation

	# Time of day — TimeOfDayClock autoload (expected on tree by play time)
	var current_time: float = 0.0
	var current_day: int = 0
	if Engine.has_singleton("TimeOfDayClock"):
		var clock = Engine.get_singleton("TimeOfDayClock")
		current_time = clock.current_time
		current_day = clock.current_day
	elif has_node("/root/TimeOfDayClock"):
		var clock = get_node("/root/TimeOfDayClock")
		current_time = clock.current_time
		current_day = clock.current_day

	# Heat / wanted level
	var wanted_level: int = 0
	if has_node("/root/HeatManager"):
		wanted_level = get_node("/root/HeatManager").wanted_level

	# Properties
	var properties_data: Array = []
	if has_node("/root/EmpireDatabaseManager"):
		var empire_db = get_node("/root/EmpireDatabaseManager")
		for prop in empire_db.get_all_properties():
			properties_data.append({
				"property_id": prop.property_id,
				"is_owned": prop.is_owned,
				"upgrade_level": prop.upgrade_level,
			})

	# Missions
	var missions_data: Array = []
	if has_node("/root/MissionManager"):
		var mission_mgr = get_node("/root/MissionManager")
		for mission in mission_mgr.get_all_mission_states():
			missions_data.append({
				"mission_id": mission.mission_id,
				"status": mission.status,
				"completion_time": mission.completion_time,
			})

	return {
		"save_version": SAVE_VERSION,
		"timestamp": Time.get_datetime_string_from_system(),
		"wallet_balance": PlayerWallet.get_balance(),
		"current_time": current_time,
		"current_day": current_day,
		"wanted_level": wanted_level,
		"player_position": {
			"x": player_position.x,
			"y": player_position.y,
			"z": player_position.z,
		},
		"player_rotation": {
			"x": player_rotation.x,
			"y": player_rotation.y,
			"z": player_rotation.z,
		},
		"properties": properties_data,
		"missions": missions_data,
	}


func _apply_save_data(data: Dictionary) -> void:
	# Wallet
	PlayerWallet.set_balance(float(data.get("wallet_balance", 0.0)))

	# Time of day
	if has_node("/root/TimeOfDayClock"):
		var clock = get_node("/root/TimeOfDayClock")
		clock.current_time = float(data.get("current_time", 0.0))
		clock.current_day = int(data.get("current_day", 0))

	# Heat
	if has_node("/root/HeatManager"):
		get_node("/root/HeatManager").set_wanted_level(int(data.get("wanted_level", 0)))

	# Player position / rotation
	var pos_dict: Dictionary = data.get("player_position", {})
	var rot_dict: Dictionary = data.get("player_rotation", {})
	if pos_dict and ServiceLocator.has_service("PlayerController"):
		var pc = ServiceLocator.get_service("PlayerController")
		pc.global_position = Vector3(
			float(pos_dict.get("x", 0.0)),
			float(pos_dict.get("y", 0.0)),
			float(pos_dict.get("z", 0.0))
		)
		pc.rotation = Vector3(
			float(rot_dict.get("x", 0.0)),
			float(rot_dict.get("y", 0.0)),
			float(rot_dict.get("z", 0.0))
		)

	# Properties
	if has_node("/root/EmpireDatabaseManager"):
		var empire_db = get_node("/root/EmpireDatabaseManager")
		for prop_data in data.get("properties", []):
			empire_db.restore_property(prop_data)

	# Missions
	if has_node("/root/MissionManager"):
		var mission_mgr = get_node("/root/MissionManager")
		for mission_data in data.get("missions", []):
			mission_mgr.restore_mission_state(mission_data)

	print("[SaveLoadManager] Save data applied to all systems.")

# ---------------------------------------------------------------------------
# Internal — utility
# ---------------------------------------------------------------------------

func _ensure_save_dir() -> void:
	if not DirAccess.dir_exists_absolute(_save_dir):
		var err: int = DirAccess.make_dir_recursive_absolute(_save_dir)
		if err != OK:
			push_error("[SaveLoadManager] Failed to create save directory: %s (error %d)" % [_save_dir, err])
		else:
			print("[SaveLoadManager] Created save directory: %s" % _save_dir)


func _is_valid_slot(slot: int) -> bool:
	return slot >= 0 and slot < MAX_SAVE_SLOTS


func _slot_path(slot: int) -> String:
	return _save_dir + ("save_%02d.json" % slot)


func _compute_sha256(input: String) -> String:
	var ctx: HashingContext = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(input.to_utf8_buffer())
	var result: PackedByteArray = ctx.finish()
	return result.hex_encode()

# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------

func _on_auto_save() -> void:
	# Auto-save always goes to slot 0 (slot 0 is reserved for quick/auto saves).
	save_game(0)
