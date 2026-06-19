## GameConstants.gd
## Pure-const file — all game-wide IDs and magic values for Project QUAHOG.
## Ported from GameConstants.cs (Unity) to Godot 4 GDScript.
## No class_name is required; reference as a preloaded resource or via
## ServiceLocator if runtime access is needed.
## Usage:  const GC = preload("res://scripts/core/GameConstants.gd")
##         GC.DISTRICT_NEW_BEDFORD
class_name GameConstants

# ===========================================================================
# DISTRICTS
# South Coast municipalities covered by the game world.
# ===========================================================================
const DISTRICT_NEW_BEDFORD:         String = "new_bedford"
const DISTRICT_FAIRHAVEN:           String = "fairhaven"
const DISTRICT_ACUSHNET:            String = "acushnet"
const DISTRICT_DARTMOUTH:           String = "dartmouth"
const DISTRICT_WESTPORT:            String = "westport"
const DISTRICT_FALL_RIVER:          String = "fall_river"
const DISTRICT_SOMERSET:            String = "somerset"
const DISTRICT_SWANSEA:             String = "swansea"
const DISTRICT_DIGHTON:             String = "dighton"
const DISTRICT_BERKLEY:             String = "berkley"
const DISTRICT_TAUNTON:             String = "taunton"
const DISTRICT_BROCKTON:            String = "brockton"
const DISTRICT_WAREHAM:             String = "wareham"
const DISTRICT_MARION:              String = "marion"
const DISTRICT_MATTAPOISETT:        String = "mattapoisett"
const DISTRICT_ROCHESTER:           String = "rochester"
const DISTRICT_LAKEVILLE:           String = "lakeville"
const DISTRICT_MIDDLEBOROUGH:       String = "middleborough"
const DISTRICT_RAYNHAM:             String = "raynham"
const DISTRICT_NORTON:              String = "norton"
const DISTRICT_ATTLEBORO:           String = "attleboro"
const DISTRICT_NORTH_ATTLEBORO:     String = "north_attleboro"
const DISTRICT_MANSFIELD:           String = "mansfield"

## Ordered list of all district IDs for iteration.
const ALL_DISTRICTS: Array = [
	DISTRICT_NEW_BEDFORD, DISTRICT_FAIRHAVEN, DISTRICT_ACUSHNET,
	DISTRICT_DARTMOUTH, DISTRICT_WESTPORT, DISTRICT_FALL_RIVER,
	DISTRICT_SOMERSET, DISTRICT_SWANSEA, DISTRICT_DIGHTON,
	DISTRICT_BERKLEY, DISTRICT_TAUNTON, DISTRICT_BROCKTON,
	DISTRICT_WAREHAM, DISTRICT_MARION, DISTRICT_MATTAPOISETT,
	DISTRICT_ROCHESTER, DISTRICT_LAKEVILLE, DISTRICT_MIDDLEBOROUGH,
	DISTRICT_RAYNHAM, DISTRICT_NORTON, DISTRICT_ATTLEBORO,
	DISTRICT_NORTH_ATTLEBORO, DISTRICT_MANSFIELD,
]

# ===========================================================================
# FACTIONS
# Criminal organisations and law enforcement present in the game world.
# ===========================================================================
const FACTION_PLAYER:               String = "player"
const FACTION_PORTUGUESE_MAFIA:     String = "portuguese_mafia"
const FACTION_IRISH_MOB:            String = "irish_mob"
const FACTION_CAPE_VERDEAN_GANG:    String = "cape_verdean_gang"
const FACTION_LONGSHOREMEN:         String = "longshoremen"       # dockworker union front
const FACTION_BIKERS:               String = "bikers"             # Southcoast MCs
const FACTION_COLOMBIAN_CARTEL:     String = "colombian_cartel"   # drug supply chain
const FACTION_NYPD_TASK_FORCE:      String = "nypd_task_force"    # federal crossover
const FACTION_NEW_BEDFORD_PD:       String = "new_bedford_pd"
const FACTION_STATE_POLICE:         String = "state_police"
const FACTION_COAST_GUARD:          String = "coast_guard"
const FACTION_FEDS:                 String = "feds"               # DEA / FBI

const ALL_FACTIONS: Array = [
	FACTION_PLAYER, FACTION_PORTUGUESE_MAFIA, FACTION_IRISH_MOB,
	FACTION_CAPE_VERDEAN_GANG, FACTION_LONGSHOREMEN, FACTION_BIKERS,
	FACTION_COLOMBIAN_CARTEL, FACTION_NYPD_TASK_FORCE,
	FACTION_NEW_BEDFORD_PD, FACTION_STATE_POLICE,
	FACTION_COAST_GUARD, FACTION_FEDS,
]

# ===========================================================================
# SAFEHOUSES
# ===========================================================================
const SAFEHOUSE_NORTH_END_APARTMENT: String = "sh_north_end_apartment"
const SAFEHOUSE_FAIRHAVEN_COTTAGE:   String = "sh_fairhaven_cottage"
const SAFEHOUSE_WAREHAM_MOTEL:       String = "sh_wareham_motel"
const SAFEHOUSE_FALL_RIVER_LOFT:     String = "sh_fall_river_loft"
const SAFEHOUSE_DARTMOUTH_RANCH:     String = "sh_dartmouth_ranch"
const SAFEHOUSE_WESTPORT_FARMHOUSE:  String = "sh_westport_farmhouse"

const ALL_SAFEHOUSES: Array = [
	SAFEHOUSE_NORTH_END_APARTMENT, SAFEHOUSE_FAIRHAVEN_COTTAGE,
	SAFEHOUSE_WAREHAM_MOTEL, SAFEHOUSE_FALL_RIVER_LOFT,
	SAFEHOUSE_DARTMOUTH_RANCH, SAFEHOUSE_WESTPORT_FARMHOUSE,
]

# ===========================================================================
# NARRATIVE STRANDS
# Top-level story arcs / quest lines.
# ===========================================================================
const STRAND_MAIN:                  String = "strand_main"
const STRAND_WHALING_LEGACY:        String = "strand_whaling_legacy"
const STRAND_WATERFRONT_WAR:        String = "strand_waterfront_war"
const STRAND_CARTEL_PIPELINE:       String = "strand_cartel_pipeline"
const STRAND_BADGE_AND_GUN:         String = "strand_badge_and_gun"      # corrupt cop sub-plot
const STRAND_OLD_MONEY:             String = "strand_old_money"           # WASPs + inheritance
const STRAND_FISHING_FLEET:         String = "strand_fishing_fleet"
const STRAND_RADIO_EMPIRE:          String = "strand_radio_empire"        # pirate radio side hustle
const STRAND_SIDE_HUSTLES:          String = "strand_side_hustles"

const ALL_STRANDS: Array = [
	STRAND_MAIN, STRAND_WHALING_LEGACY, STRAND_WATERFRONT_WAR,
	STRAND_CARTEL_PIPELINE, STRAND_BADGE_AND_GUN, STRAND_OLD_MONEY,
	STRAND_FISHING_FLEET, STRAND_RADIO_EMPIRE, STRAND_SIDE_HUSTLES,
]

# ===========================================================================
# MISSION IDs
# Canonical mission identifiers — format: <strand_prefix>_<sequence>_<slug>
# ===========================================================================

# --- Main strand ---
const MISSION_MAIN_001_ARRIVAL:             String = "main_001_arrival"
const MISSION_MAIN_002_FIRST_JOB:           String = "main_002_first_job"
const MISSION_MAIN_003_DOCKSIDE_DEAL:       String = "main_003_dockside_deal"
const MISSION_MAIN_004_MEET_FONSECA:        String = "main_004_meet_fonseca"
const MISSION_MAIN_005_HARBOR_RUN:          String = "main_005_harbor_run"
const MISSION_MAIN_006_IRISH_PROBLEM:       String = "main_006_irish_problem"
const MISSION_MAIN_007_TURF_ESCALATION:     String = "main_007_turf_escalation"
const MISSION_MAIN_008_BETRAYAL:            String = "main_008_betrayal"
const MISSION_MAIN_009_THE_LEDGER:          String = "main_009_the_ledger"
const MISSION_MAIN_010_ENDGAME:             String = "main_010_endgame"

# --- Whaling Legacy strand ---
const MISSION_WHALE_001_OLD_SALT:           String = "whale_001_old_salt"
const MISSION_WHALE_002_MUSEUM_JOB:         String = "whale_002_museum_job"
const MISSION_WHALE_003_CAPTAIN_GREAVES:    String = "whale_003_captain_greaves"

# --- Waterfront War strand ---
const MISSION_WF_001_LONGSHOREMEN:          String = "wf_001_longshoremen"
const MISSION_WF_002_DOCK_STRIKE:           String = "wf_002_dock_strike"
const MISSION_WF_003_UNION_BUSTING:         String = "wf_003_union_busting"
const MISSION_WF_004_PORT_TAKEOVER:         String = "wf_004_port_takeover"

# --- Cartel Pipeline strand ---
const MISSION_CARTEL_001_FIRST_CONTACT:     String = "cartel_001_first_contact"
const MISSION_CARTEL_002_SAMPLE_RUN:        String = "cartel_002_sample_run"
const MISSION_CARTEL_003_DISTRIBUTION:      String = "cartel_003_distribution"
const MISSION_CARTEL_004_HEAT:              String = "cartel_004_heat"
const MISSION_CARTEL_005_CUT_OUT:           String = "cartel_005_cut_out"

# --- Badge & Gun (corrupt cop) strand ---
const MISSION_COP_001_SHAKEDOWN:            String = "cop_001_shakedown"
const MISSION_COP_002_EVIDENCE_ROOM:        String = "cop_002_evidence_room"
const MISSION_COP_003_DIRTY_MONEY:          String = "cop_003_dirty_money"

# --- Old Money strand ---
const MISSION_OM_001_THE_WILL:              String = "om_001_the_will"
const MISSION_OM_002_COUNTRY_CLUB:          String = "om_002_country_club"
const MISSION_OM_003_INHERITANCE:           String = "om_003_inheritance"

# --- Fishing Fleet strand ---
const MISSION_FISH_001_CREW_NEEDED:         String = "fish_001_crew_needed"
const MISSION_FISH_002_SMUGGLERS_COVE:      String = "fish_002_smugglers_cove"
const MISSION_FISH_003_CATCH_AND_RELEASE:   String = "fish_003_catch_and_release"

# --- Radio Empire strand ---
const MISSION_RADIO_001_TRANSMITTER:        String = "radio_001_transmitter"
const MISSION_RADIO_002_PLAYLIST:           String = "radio_002_playlist"
const MISSION_RADIO_003_SIGNAL_BOOST:       String = "radio_003_signal_boost"
const MISSION_RADIO_004_EMPIRE:             String = "radio_004_empire"

# --- Side hustles ---
const MISSION_SIDE_TAXI:                    String = "side_taxi"
const MISSION_SIDE_REPO:                    String = "side_repo"
const MISSION_SIDE_NUMBERS_RUNNER:          String = "side_numbers_runner"
const MISSION_SIDE_CHOP_SHOP:               String = "side_chop_shop"
const MISSION_SIDE_LOAN_SHARK:              String = "side_loan_shark"
const MISSION_SIDE_PROTECTION_RACKET:       String = "side_protection_racket"

# ===========================================================================
# WANTED / HEAT LEVELS
# ===========================================================================
const WANTED_NONE:      int = 0
const WANTED_LOW:       int = 1
const WANTED_MEDIUM:    int = 2
const WANTED_HIGH:      int = 3
const WANTED_FEDERAL:   int = 4
const WANTED_MAX:       int = 5

# ===========================================================================
# TIME OF DAY
# In-game hours (0.0 – 24.0). 1 in-game hour ≈ 2 real-time minutes.
# ===========================================================================
const TIME_DAWN:        float = 5.5
const TIME_MORNING:     float = 7.0
const TIME_NOON:        float = 12.0
const TIME_AFTERNOON:   float = 15.0
const TIME_DUSK:        float = 18.5
const TIME_EVENING:     float = 20.0
const TIME_MIDNIGHT:    float = 0.0
const REAL_SECONDS_PER_GAME_HOUR: float = 120.0   # 2 real minutes = 1 game hour

# ===========================================================================
# ECONOMY
# ===========================================================================
const STARTING_BALANCE:            float = 500.0
const SAFEHOUSE_PURCHASE_PRICE:    float = 25000.0
const CHOP_SHOP_BASE_PAYOUT:       float = 800.0
const PROTECTION_RACKET_WEEKLY:    float = 1500.0
const NUMBERS_RUNNER_DAILY:        float = 200.0

# ===========================================================================
# PHYSICS / GAMEPLAY TUNING
# ===========================================================================
const PLAYER_WALK_SPEED:           float = 4.5
const PLAYER_RUN_SPEED:            float = 8.5
const PLAYER_SPRINT_SPEED:         float = 12.0
const PLAYER_CROUCH_SPEED:         float = 2.5
const PLAYER_JUMP_VELOCITY:        float = 5.5
const PLAYER_MAX_HEALTH:           float = 100.0
const PLAYER_MAX_ARMOR:            float = 100.0

# Vehicle categories (used as type tags)
const VEHICLE_TYPE_CAR:            String = "car"
const VEHICLE_TYPE_TRUCK:          String = "truck"
const VEHICLE_TYPE_BOAT:           String = "boat"
const VEHICLE_TYPE_MOTORCYCLE:     String = "motorcycle"

# ===========================================================================
# LAYERS (must match project.godot layer_names)
# ===========================================================================
const LAYER_WORLD:        int = 1
const LAYER_PLAYER:       int = 2
const LAYER_NPC:          int = 3
const LAYER_VEHICLE:      int = 4
const LAYER_PROJECTILE:   int = 5
const LAYER_INTERACTABLE: int = 6
const LAYER_TRIGGER:      int = 7
const LAYER_PICKUP:       int = 8

# ===========================================================================
# SCENE PATHS
# ===========================================================================
const SCENE_BOOTSTRAP:     String = "res://scenes/bootstrap/Bootstrap.tscn"
const SCENE_MAIN_MENU:     String = "res://scenes/ui/MainMenu.tscn"
const SCENE_LOADING:       String = "res://scenes/ui/LoadingScreen.tscn"
const SCENE_WORLD_MAIN:    String = "res://scenes/world/SouthCoast.tscn"
const SCENE_HUD:           String = "res://scenes/ui/HUD.tscn"
const SCENE_PAUSE_MENU:    String = "res://scenes/ui/PauseMenu.tscn"

# ===========================================================================
# TAG STRINGS (used with groups / meta tags)
# ===========================================================================
const TAG_ENEMY:           String = "enemy"
const TAG_ALLY:            String = "ally"
const TAG_CIVILIAN:        String = "civilian"
const TAG_COP:             String = "cop"
const TAG_INTERACTABLE:    String = "interactable"
const TAG_VEHICLE:         String = "vehicle"
const TAG_PICKUP:          String = "pickup"
const TAG_SAVEABLE:        String = "saveable"
