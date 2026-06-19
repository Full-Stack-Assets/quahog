# MissionManager.gd  (Autoload)
# Full 22-mission story/side system for Project QUAHOG (1986 Massachusetts coast).
# Register via Project → Autoload as "MissionManager".
extends Node

# ── Mission States ─────────────────────────────────────────────────────────
enum MissionState {
	LOCKED     = 0,
	AVAILABLE  = 1,
	ACTIVE     = 2,
	COMPLETED  = 3,
	FAILED     = 4
}

# ── Strand IDs (constants for safety) ─────────────────────────────────────
const STRAND_NEW_SEFTON   := "new_sefton"
const STRAND_DIGHTON      := "dighton"
const STRAND_TAUNTON_HILL := "taunton_hill"
const STRAND_SAWYER       := "sawyer"
const STRAND_EMPIRE       := "empire"
const STRAND_GANG         := "gang"
const STRAND_SIDELINE     := "sideline"

# ── Inner Mission Class ────────────────────────────────────────────────────
class Mission:
	var mission_id: String = ""
	var display_name: String = ""
	var description: String = ""
	var strand_id: String = ""
	var state: int = MissionState.LOCKED
	var prerequisites: Array[String] = []
	var unlocks_mission_id: String = ""
	var linked_property_id: String = ""
	var reward_amount: float = 0.0
	var world_target: Node3D = null

	func _init(
		p_id: String,
		p_name: String,
		p_desc: String,
		p_strand: String,
		p_prereqs: Array[String],
		p_unlocks: String,
		p_property: String,
		p_reward: float
	) -> void:
		mission_id         = p_id
		display_name       = p_name
		description        = p_desc
		strand_id          = p_strand
		prerequisites      = p_prereqs
		unlocks_mission_id = p_unlocks
		linked_property_id = p_property
		reward_amount      = p_reward
		state              = MissionState.LOCKED

# ── Signals ────────────────────────────────────────────────────────────────
signal mission_available(mission)
signal mission_started(mission)
signal mission_completed(mission)
signal mission_failed(mission)

# ── State ──────────────────────────────────────────────────────────────────
var missions: Array = []
var _lookup: Dictionary = {}

# ── Lifecycle ──────────────────────────────────────────────────────────────
func _ready() -> void:
	_register_all_missions()
	# The intro mission is always immediately available.
	unlock_mission("ns_01_intro")

# ── Mission Registration ───────────────────────────────────────────────────
func _register_all_missions() -> void:
	# ── New Sefton strand ──────────────────────────────────────────────────
	_add(Mission.new(
		"ns_01_intro",
		"Welcome to New Sefton",
		"Get your bearings in the port district and meet your contact.",
		STRAND_NEW_SEFTON,
		[] as Array[String],
		"ns_02_docks", "", 500.0
	))
	_add(Mission.new(
		"ns_02_docks",
		"Down at the Docks",
		"Shake down the dock workers and secure the smuggling route.",
		STRAND_NEW_SEFTON,
		["ns_01_intro"] as Array[String],
		"ns_03_waterfront", "", 1200.0
	))
	_add(Mission.new(
		"ns_03_waterfront",
		"Waterfront Takeover",
		"Drive out the rival crew and claim the waterfront for yourself.",
		STRAND_NEW_SEFTON,
		["ns_02_docks"] as Array[String],
		"em_01_connections", "", 2500.0
	))

	# ── Dighton strand ─────────────────────────────────────────────────────
	_add(Mission.new(
		"dt_01_rumors",
		"Rumors in Dighton",
		"Investigate whispers of a corrupt alderman running Dighton.",
		STRAND_DIGHTON,
		[] as Array[String],
		"dt_02_mill", "", 600.0
	))
	_add(Mission.new(
		"dt_02_mill",
		"The Old Mill Job",
		"Use the abandoned mill as cover for a payroll heist.",
		STRAND_DIGHTON,
		["dt_01_rumors"] as Array[String],
		"dt_03_canal", "", 1500.0
	))
	_add(Mission.new(
		"dt_03_canal",
		"Canal Run",
		"Move stolen goods through the canal network before the state police close in.",
		STRAND_DIGHTON,
		["dt_02_mill"] as Array[String],
		"", "", 3000.0
	))

	# ── Taunton Hill strand ────────────────────────────────────────────────
	_add(Mission.new(
		"th_01_hillside",
		"Hillside Hustle",
		"Infiltrate the exclusive Taunton Hill social circle.",
		STRAND_TAUNTON_HILL,
		[] as Array[String],
		"th_02_estate", "", 800.0
	))
	_add(Mission.new(
		"th_02_estate",
		"The Estate Deal",
		"Broker a land deal that will give you a foothold in the hill district.",
		STRAND_TAUNTON_HILL,
		["th_01_hillside"] as Array[String],
		"th_03_prestige", "prop_taunton_estate", 2000.0
	))
	_add(Mission.new(
		"th_03_prestige",
		"Prestige and Power",
		"Host a gala to cement your reputation among the Taunton Hill elite.",
		STRAND_TAUNTON_HILL,
		["th_02_estate"] as Array[String],
		"em_03_rivals", "", 4000.0
	))

	# ── Sawyer strand ──────────────────────────────────────────────────────
	_add(Mission.new(
		"sw_01_outskirts",
		"Outskirts Opportunity",
		"Scout the Sawyer industrial outskirts for expansion.",
		STRAND_SAWYER,
		[] as Array[String],
		"sw_02_foundry", "", 700.0
	))
	_add(Mission.new(
		"sw_02_foundry",
		"The Foundry",
		"Take control of the foundry and its lucrative metal contracts.",
		STRAND_SAWYER,
		["sw_01_outskirts"] as Array[String],
		"sw_03_industry", "prop_sawyer_foundry", 1800.0
	))
	_add(Mission.new(
		"sw_03_industry",
		"Industrial Muscle",
		"Crush union resistance and monopolize Sawyer's industrial belt.",
		STRAND_SAWYER,
		["sw_02_foundry"] as Array[String],
		"em_02_revenue", "", 3500.0
	))

	# ── Empire strand ──────────────────────────────────────────────────────
	_add(Mission.new(
		"em_01_connections",
		"Making Connections",
		"Forge alliances with the regional crime families.",
		STRAND_EMPIRE,
		["ns_03_waterfront"] as Array[String],
		"em_02_revenue", "", 2000.0
	))
	_add(Mission.new(
		"em_02_revenue",
		"Revenue Streams",
		"Establish reliable cash flow across all districts.",
		STRAND_EMPIRE,
		["em_01_connections", "sw_03_industry"] as Array[String],
		"em_03_rivals", "", 5000.0
	))
	_add(Mission.new(
		"em_03_rivals",
		"Rival Reckoning",
		"Eliminate the last organized competition to your empire.",
		STRAND_EMPIRE,
		["em_02_revenue", "th_03_prestige"] as Array[String],
		"em_04_kingpin", "", 8000.0
	))
	_add(Mission.new(
		"em_04_kingpin",
		"Kingpin",
		"Seize total control. The Massachusetts coast is yours.",
		STRAND_EMPIRE,
		["em_03_rivals"] as Array[String],
		"", "", 20000.0
	))

	# ── Gang strand ────────────────────────────────────────────────────────
	_add(Mission.new(
		"gang_01_threat",
		"The Threat",
		"A violent street gang is muscling in on your territory.",
		STRAND_GANG,
		[] as Array[String],
		"gang_02_turf", "", 1000.0
	))
	_add(Mission.new(
		"gang_02_turf",
		"Turf War",
		"Push the gang back block by block in a brutal territorial struggle.",
		STRAND_GANG,
		["gang_01_threat"] as Array[String],
		"gang_03_war", "", 2200.0
	))
	_add(Mission.new(
		"gang_03_war",
		"All-Out War",
		"End the gang threat once and for all — their leader, their stash house, their crew.",
		STRAND_GANG,
		["gang_02_turf"] as Array[String],
		"", "", 5000.0
	))

	# ── Sideline strand ────────────────────────────────────────────────────
	_add(Mission.new(
		"side_01_taxi",
		"Hack Work",
		"Drive a stolen cab and listen in on passenger conversations for intel.",
		STRAND_SIDELINE,
		[] as Array[String],
		"side_02_vigilante", "", 400.0
	))
	_add(Mission.new(
		"side_02_vigilante",
		"Neighborhood Watch",
		"Take out five wanted criminals to build a reputation with the locals.",
		STRAND_SIDELINE,
		["side_01_taxi"] as Array[String],
		"side_03_race", "", 900.0
	))
	_add(Mission.new(
		"side_03_race",
		"Coast Road Race",
		"Win an illegal street race along Route 6 before the state troopers shut it down.",
		STRAND_SIDELINE,
		["side_02_vigilante"] as Array[String],
		"", "", 1500.0
	))

	print("MissionManager: registered %d missions." % missions.size())

# ── Private Helper ─────────────────────────────────────────────────────────
func _add(m: Mission) -> void:
	missions.append(m)
	_lookup[m.mission_id] = m

# ── Public API ─────────────────────────────────────────────────────────────

## Returns the Mission object for the given id, or null.
func get_mission(id: String):
	return _lookup.get(id, null)

## Returns true if all prerequisites for id are COMPLETED and its state is AVAILABLE.
func can_start(id: String) -> bool:
	var m = get_mission(id)
	if m == null:
		return false
	if m.state != MissionState.AVAILABLE:
		return false
	for prereq_id in m.prerequisites:
		var prereq = get_mission(prereq_id)
		if prereq == null or prereq.state != MissionState.COMPLETED:
			return false
	return true

## Sets mission to ACTIVE if it can be started.
func start_mission(id: String) -> void:
	if not can_start(id):
		push_warning("MissionManager.start_mission(): cannot start '%s'." % id)
		return
	var m = get_mission(id)
	m.state = MissionState.ACTIVE
	emit_signal("mission_started", m)
	print("MissionManager: started '%s'" % m.display_name)

## Marks mission COMPLETED, pays reward, and unlocks the next mission in the strand.
func complete_mission(id: String) -> void:
	var m = get_mission(id)
	if m == null:
		push_warning("MissionManager.complete_mission(): unknown id '%s'." % id)
		return
	if m.state != MissionState.ACTIVE:
		push_warning("MissionManager.complete_mission(): '%s' is not ACTIVE." % id)
		return
	m.state = MissionState.COMPLETED

	# Pay the player.
	if m.reward_amount > 0.0 and PlayerWallet.has_method("add_funds"):
		PlayerWallet.add_funds(m.reward_amount)
		print("MissionManager: reward $%.2f for '%s'" % [m.reward_amount, m.display_name])

	emit_signal("mission_completed", m)
	print("MissionManager: completed '%s'" % m.display_name)

	# Auto-unlock the next mission in the chain.
	if m.unlocks_mission_id != "":
		unlock_mission(m.unlocks_mission_id)

## Marks mission FAILED.
func fail_mission(id: String) -> void:
	var m = get_mission(id)
	if m == null:
		push_warning("MissionManager.fail_mission(): unknown id '%s'." % id)
		return
	if m.state != MissionState.ACTIVE:
		return
	m.state = MissionState.FAILED
	emit_signal("mission_failed", m)
	print("MissionManager: failed '%s'" % m.display_name)

## Sets mission to AVAILABLE if it is currently LOCKED.
func unlock_mission(id: String) -> void:
	var m = get_mission(id)
	if m == null:
		push_warning("MissionManager.unlock_mission(): unknown id '%s'." % id)
		return
	if m.state != MissionState.LOCKED:
		return
	m.state = MissionState.AVAILABLE
	emit_signal("mission_available", m)
	print("MissionManager: unlocked '%s'" % m.display_name)
