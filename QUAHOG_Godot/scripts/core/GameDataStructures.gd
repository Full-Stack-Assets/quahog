## GameDataStructures.gd
## Data-transfer objects and value types for Project QUAHOG.
## All classes are plain data containers — no game logic here.
##
## Ported from SaveData, PropertySaveData, MissionSaveData, SaveMetadata
## in GameDataStructures.cs (Unity) to Godot 4 GDScript inner classes.
##
## Usage example:
##   var data := GameDataStructures.SaveData.new()
##   data.wallet_balance = PlayerWallet.get_balance()
##   var json := JSON.stringify(data.to_dict())

class_name GameDataStructures

# ===========================================================================
# SaveData — the top-level save-file payload
# ===========================================================================
class SaveData:
	## Semantic version of the save format.  Bump when fields change.
	var save_version: String = "1.0.0"

	## ISO-8601 timestamp of when this save was written.
	var timestamp: String = ""

	## Player cash balance at the time of saving.
	var wallet_balance: float = 0.0

	## In-game time of day (0.0 – 24.0 hours).
	var current_time: float = 0.0

	## In-game day counter (starts at 0).
	var current_day: int = 0

	## Wanted / heat level (0–5).
	var wanted_level: int = 0

	## Player world position.
	var player_position: Vector3 = Vector3.ZERO

	## Player Euler rotation (radians).
	var player_rotation: Vector3 = Vector3.ZERO

	## Serialised list of empire properties.
	var properties: Array = []   # Array[PropertySaveData]

	## Serialised list of mission states.
	var missions: Array = []     # Array[MissionSaveData]

	## Convenience: serialise to a plain Dictionary for JSON.stringify().
	func to_dict() -> Dictionary:
		var props_raw: Array = []
		for p in properties:
			props_raw.append(p.to_dict() if p is PropertySaveData else p)
		var missions_raw: Array = []
		for m in missions:
			missions_raw.append(m.to_dict() if m is MissionSaveData else m)
		return {
			"save_version": save_version,
			"timestamp": timestamp,
			"wallet_balance": wallet_balance,
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
			"properties": props_raw,
			"missions": missions_raw,
		}

	## Convenience: populate from a Dictionary produced by JSON.parse_string().
	static func from_dict(d: Dictionary) -> SaveData:
		var sd := SaveData.new()
		sd.save_version = str(d.get("save_version", "1.0.0"))
		sd.timestamp = str(d.get("timestamp", ""))
		sd.wallet_balance = float(d.get("wallet_balance", 0.0))
		sd.current_time = float(d.get("current_time", 0.0))
		sd.current_day = int(d.get("current_day", 0))
		sd.wanted_level = int(d.get("wanted_level", 0))

		var pos_d: Dictionary = d.get("player_position", {})
		sd.player_position = Vector3(
			float(pos_d.get("x", 0.0)),
			float(pos_d.get("y", 0.0)),
			float(pos_d.get("z", 0.0))
		)
		var rot_d: Dictionary = d.get("player_rotation", {})
		sd.player_rotation = Vector3(
			float(rot_d.get("x", 0.0)),
			float(rot_d.get("y", 0.0)),
			float(rot_d.get("z", 0.0))
		)

		for pd in d.get("properties", []):
			sd.properties.append(PropertySaveData.from_dict(pd))
		for md in d.get("missions", []):
			sd.missions.append(MissionSaveData.from_dict(md))
		return sd


# ===========================================================================
# PropertySaveData — state for a single empire property/business
# ===========================================================================
class PropertySaveData:
	## Canonical property ID (matches GameConstants.SAFEHOUSE_* or empire DB).
	var property_id: String = ""

	## Whether the player has purchased this property.
	var is_owned: bool = false

	## Upgrade tier (0 = base, higher = upgraded).
	var upgrade_level: int = 0

	## Per-property flags / custom data (e.g. stash contents).
	var metadata: Dictionary = {}

	func to_dict() -> Dictionary:
		return {
			"property_id": property_id,
			"is_owned": is_owned,
			"upgrade_level": upgrade_level,
			"metadata": metadata,
		}

	static func from_dict(d: Dictionary) -> PropertySaveData:
		var psd := PropertySaveData.new()
		psd.property_id = str(d.get("property_id", ""))
		psd.is_owned = bool(d.get("is_owned", false))
		psd.upgrade_level = int(d.get("upgrade_level", 0))
		psd.metadata = d.get("metadata", {})
		return psd


# ===========================================================================
# MissionSaveData — state for a single mission
# ===========================================================================
class MissionSaveData:
	## Canonical mission ID — matches GameConstants.MISSION_* constants.
	var mission_id: String = ""

	## Status string: "locked" | "available" | "active" | "completed" | "failed"
	var status: String = "locked"

	## In-game timestamp when the mission was completed (0.0 if not complete).
	var completion_time: float = 0.0

	## Optional per-mission checkpoint / objective state.
	var checkpoint: int = 0

	## Extra key/value pairs for mission-specific state (e.g. hostage_saved: true).
	var extra: Dictionary = {}

	func to_dict() -> Dictionary:
		return {
			"mission_id": mission_id,
			"status": status,
			"completion_time": completion_time,
			"checkpoint": checkpoint,
			"extra": extra,
		}

	static func from_dict(d: Dictionary) -> MissionSaveData:
		var msd := MissionSaveData.new()
		msd.mission_id = str(d.get("mission_id", ""))
		msd.status = str(d.get("status", "locked"))
		msd.completion_time = float(d.get("completion_time", 0.0))
		msd.checkpoint = int(d.get("checkpoint", 0))
		msd.extra = d.get("extra", {})
		return msd


# ===========================================================================
# SaveMetadata — lightweight slot summary shown in the Load/Save UI
# ===========================================================================
class SaveMetadata:
	## Slot index (0 = auto-save, 1–4 = manual).
	var slot: int = 0

	## Save version string.
	var save_version: String = "1.0.0"

	## In-game day number.
	var current_day: int = 0

	## In-game time of day.
	var current_time: float = 0.0

	## Player wallet balance at save time.
	var wallet_balance: float = 0.0

	## Wanted level at save time.
	var wanted_level: int = 0

	## Wall-clock ISO timestamp.
	var timestamp: String = ""

	## Returns true if this metadata represents a populated slot.
	func is_valid() -> bool:
		return save_version != "" and timestamp != ""

	## Human-readable summary for the save-slot UI button label.
	func get_display_label() -> String:
		if not is_valid():
			return "Empty Slot"
		var hour: int = int(current_time)
		var minute: int = int(fmod(current_time, 1.0) * 60.0)
		var ampm: String = "AM" if hour < 12 else "PM"
		var h12: int = hour % 12
		if h12 == 0:
			h12 = 12
		return "Day %d  %02d:%02d %s  $%s" % [
			current_day + 1,
			h12, minute, ampm,
			_format_dollars(wallet_balance),
		]

	func to_dict() -> Dictionary:
		return {
			"slot": slot,
			"save_version": save_version,
			"current_day": current_day,
			"current_time": current_time,
			"wallet_balance": wallet_balance,
			"wanted_level": wanted_level,
			"timestamp": timestamp,
		}

	static func from_dict(d: Dictionary) -> SaveMetadata:
		var sm := SaveMetadata.new()
		sm.slot = int(d.get("slot", 0))
		sm.save_version = str(d.get("save_version", ""))
		sm.current_day = int(d.get("current_day", 0))
		sm.current_time = float(d.get("current_time", 0.0))
		sm.wallet_balance = float(d.get("wallet_balance", 0.0))
		sm.wanted_level = int(d.get("wanted_level", 0))
		sm.timestamp = str(d.get("timestamp", ""))
		return sm

	## Static factory: build SaveMetadata from a full SaveData instance.
	static func from_save_data(save_data: SaveData, slot_index: int) -> SaveMetadata:
		var sm := SaveMetadata.new()
		sm.slot = slot_index
		sm.save_version = save_data.save_version
		sm.current_day = save_data.current_day
		sm.current_time = save_data.current_time
		sm.wallet_balance = save_data.wallet_balance
		sm.wanted_level = save_data.wanted_level
		sm.timestamp = save_data.timestamp
		return sm

	static func _format_dollars(amount: float) -> String:
		# Simple comma-thousands formatter for the slot label.
		var s: String = "%d" % int(amount)
		var result: String = ""
		var count: int = 0
		for i in range(s.length() - 1, -1, -1):
			if count > 0 and count % 3 == 0:
				result = "," + result
			result = s[i] + result
			count += 1
		return result
