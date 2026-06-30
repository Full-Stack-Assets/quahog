extends Node





signal cash_changed(new_cash: int)
signal notify(message: String)
signal wanted_changed(level: int)
signal open_shop_requested(shop_kind: String)
signal open_diner_requested()
signal graphics_quality_changed(level: int)

const SAVE_PATH: = "user://mount_hope_save.json"
const QUALITY_NAMES: PackedStringArray = ["Low", "Medium", "High"]
const STARTING_CASH: = 40

var cash: int = STARTING_CASH
var missions_completed: int = 0
var wanted_level: int = 0
var opener_complete: bool = false
var campaign_mi: int = 0
var campaign_step: int = 0
var campaign_done: bool = false
var player_spawn_override: = Vector3.ZERO
var has_spawn_override: bool = false

# Cheats (toggled from the main-menu CHEATS panel; persisted with the save).
# no_police suppresses all wanted-heat for testing. Defaults OFF so the crime loop bites.
var cheat_no_police: bool = false
var cheat_godmode: bool = false
# Forced time of day: -1 = normal day/night clock; otherwise a fixed day_phase
# (0=dusk, 0.25=night, 0.5=dawn, 0.75=midday).
var cheat_time_phase: float = -1.0
var cheat_infinite_ammo: bool = false
var cheat_all_weapons: bool = false
var cheat_oneshot: bool = false
var cheat_rapidfire: bool = false
var cheat_super_speed: bool = false
var cheat_super_jump: bool = false
var cheat_infinite_cash: bool = false
var cheat_car_turbo: bool = false
var cheat_force_rain: int = -1     # -1 auto · 0 forced dry · 1 forced rain
var cheat_traffic_mult: float = 1.0
var cheat_time_scale: float = 1.0  # global slow-mo / fast-forward
var cheat_teleport_anywhere: bool = false
# Chase-cam side: false = behind the car, true = flipped to the other side (CAM button).
var cam_flip: bool = false
# Graphics quality: 0=Low (mobile), 1=Medium, 2=High. Affects streaming radius,
# car pool, traffic, rain, and building LOD.
var graphics_quality: int = 1


func stream_radius() -> int:
    return [1, 2, 3][graphics_quality]


func car_pool_size() -> int:
    return [100, 150, 200][graphics_quality]


func traffic_car_count() -> int:
    return [8, 12, 16][graphics_quality]


func stream_tile_budget() -> int:
    return [2, 5, 12][graphics_quality]


func building_lod() -> int:
    return graphics_quality


func rain_particle_count() -> int:
    return [0, 180, 280][graphics_quality]


func car_restream_batch() -> int:
    return [8, 12, 20][graphics_quality]


func set_graphics_quality(level: int) -> void :
    level = clampi(level, 0, 2)
    if level == graphics_quality:
        return
    graphics_quality = level
    graphics_quality_changed.emit(graphics_quality)
    _save_graphics_cfg()


func _load_graphics_cfg() -> void :
    var cfg: = ConfigFile.new()
    if cfg.load("user://settings.cfg") == OK:
        graphics_quality = clampi(int(cfg.get_value("graphics", "quality", 1)), 0, 2)


func _save_graphics_cfg() -> void :
    var cfg: = ConfigFile.new()
    cfg.load("user://settings.cfg")
    cfg.set_value("graphics", "quality", graphics_quality)
    cfg.save("user://settings.cfg")


func toggle_cam_flip() -> void :
    cam_flip = not cam_flip
    save_game()


# All cheat flags, keyed for compact save/load (avoids a giant literal twice).
func _cheat_dict() -> Dictionary:
    return {
        "no_police": cheat_no_police, "godmode": cheat_godmode,
        "time_phase": cheat_time_phase, "inf_ammo": cheat_infinite_ammo,
        "all_weapons": cheat_all_weapons, "oneshot": cheat_oneshot,
        "rapidfire": cheat_rapidfire, "super_speed": cheat_super_speed,
        "super_jump": cheat_super_jump, "inf_cash": cheat_infinite_cash,
        "car_turbo": cheat_car_turbo, "force_rain": cheat_force_rain,
        "traffic_mult": cheat_traffic_mult, "time_scale": cheat_time_scale,
        "tp_anywhere": cheat_teleport_anywhere, "cam_flip": cam_flip,
    }


func _load_cheats(d: Dictionary) -> void :
    cheat_no_police = bool(d.get("no_police", false))
    cheat_godmode = bool(d.get("godmode", false))
    cheat_time_phase = float(d.get("time_phase", -1.0))
    cheat_infinite_ammo = bool(d.get("inf_ammo", false))
    cheat_all_weapons = bool(d.get("all_weapons", false))
    cheat_oneshot = bool(d.get("oneshot", false))
    cheat_rapidfire = bool(d.get("rapidfire", false))
    cheat_super_speed = bool(d.get("super_speed", false))
    cheat_super_jump = bool(d.get("super_jump", false))
    cheat_infinite_cash = bool(d.get("inf_cash", false))
    cheat_car_turbo = bool(d.get("car_turbo", false))
    cheat_force_rain = int(d.get("force_rain", -1))
    cheat_traffic_mult = float(d.get("traffic_mult", 1.0))
    cheat_time_scale = float(d.get("time_scale", 1.0))
    cheat_teleport_anywhere = bool(d.get("tp_anywhere", false))
    cam_flip = bool(d.get("cam_flip", false))

# Last known player position/heading, persisted so the menu can offer Continue.
var saved_pos: = Vector3.ZERO
var saved_yaw: float = 0.0
var has_saved_pos: bool = false

# World clock + weather, written by game_world so the HUD can display them.
# day_phase 0 = dusk; the loop runs dusk→night→dawn→day→dusk.
var day_phase: float = 0.0
var raining: bool = false

func time_string() -> String:
    var hours: float = fmod(day_phase * 24.0 + 18.0, 24.0)
    var h: int = int(hours)
    var m: int = int((hours - h) * 60.0)
    return "%02d:%02d" % [h, m]


func set_wanted(level: int) -> void :
    level = clampi(level, 0, 5)
    if level == wanted_level:
        return
    wanted_level = level
    wanted_changed.emit(wanted_level)

func _ready() -> void :
    _load_graphics_cfg()
    load_game()

func add_cash(amount: int) -> void :
    cash += amount
    cash = max(cash, 0)
    cash_changed.emit(cash)
    save_game()

func spend_cash(amount: int) -> bool:
    if cheat_infinite_cash:
        return true
    if cash < amount:
        notify.emit("Not enough cash.")
        return false
    cash -= amount
    cash_changed.emit(cash)
    save_game()
    return true

func can_afford(amount: int) -> bool:
    return cash >= amount

func record_mission_complete() -> void :
    missions_completed += 1
    save_game()

func show_message(message: String) -> void :
    notify.emit(message)

# Called by the player on a light interval so Continue resumes where you left off.
func save_position(pos: Vector3, yaw: float) -> void :
    saved_pos = pos
    saved_yaw = yaw
    has_saved_pos = true
    save_game()

func has_save() -> bool:
    return has_saved_pos or FileAccess.file_exists(SAVE_PATH)

func save_game() -> void :
    var data: = {
        "cash": cash,
        "missions_completed": missions_completed,
        "wanted_level": wanted_level,
        "opener_complete": opener_complete,
        "campaign_mi": campaign_mi,
        "campaign_step": campaign_step,
        "campaign_done": campaign_done,
        "has_pos": has_saved_pos,
        "px": saved_pos.x, "py": saved_pos.y, "pz": saved_pos.z,
        "yaw": saved_yaw,
        "cheats": _cheat_dict(),
    }
    var f: = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if f:
        f.store_string(JSON.stringify(data))
        f.close()

func load_game() -> void :
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var f: = FileAccess.open(SAVE_PATH, FileAccess.READ)
    if not f:
        return
    var text: = f.get_as_text()
    f.close()
    var parsed: Variant = JSON.parse_string(text)
    if typeof(parsed) != TYPE_DICTIONARY:
        return
    var data: Dictionary = parsed
    cash = int(data.get("cash", STARTING_CASH))
    missions_completed = int(data.get("missions_completed", 0))
    wanted_level = int(data.get("wanted_level", 0))
    opener_complete = bool(data.get("opener_complete", false))
    campaign_mi = int(data.get("campaign_mi", 0 if not opener_complete else 1))
    campaign_step = int(data.get("campaign_step", 0))
    campaign_done = bool(data.get("campaign_done", false))
    var cd: Variant = data.get("cheats", {})
    if cd is Dictionary:
        _load_cheats(cd)
    has_saved_pos = bool(data.get("has_pos", false))
    if has_saved_pos:
        saved_pos = Vector3(float(data.get("px", 0.0)), float(data.get("py", 0.0)), float(data.get("pz", 0.0)))
        saved_yaw = float(data.get("yaw", 0.0))
    cash_changed.emit(cash)

func reset_save() -> void :
    cash = STARTING_CASH
    missions_completed = 0
    wanted_level = 0
    opener_complete = false
    campaign_mi = 0
    campaign_step = 0
    campaign_done = false
    has_saved_pos = false
    saved_pos = Vector3.ZERO
    saved_yaw = 0.0
    cash_changed.emit(cash)
    save_game()
