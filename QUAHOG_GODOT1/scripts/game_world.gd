extends Node3D





const PLAYER_SCENE: = preload("res://scenes/player.tscn")
const NPC_SCRIPT: = preload("res://scripts/npc.gd")
const MISSION_GIVER_SCRIPT: = preload("res://scripts/mission_giver.gd")
const HUD_SCRIPT: = preload("res://scripts/ui/hud.gd")
const CityBuilderScript: = preload("res://scripts/world/city_builder.gd")
const MapLoaderScript: = preload("res://scripts/world/map_loader.gd")
const CarScript: = preload("res://scripts/vehicles/car.gd")
const TrafficCarScript: = preload("res://scripts/vehicles/traffic_car.gd")
const JobManagerScript: = preload("res://scripts/systems/job_manager.gd")
const WantedSystemScript: = preload("res://scripts/systems/wanted_system.gd")
const WeaponPickupScript: = preload("res://scripts/weapons/weapon_pickup.gd")
const ShopScript: = preload("res://scripts/world/shop.gd")
const ShopMenuScript: = preload("res://scripts/ui/shop_menu.gd")

const MAX_STATIC_CARS: = 12
const DRIVABLE_CARS: = 8
const TRAFFIC_CARS: = 10
# How many 500 m tiles out from the New Bedford core to build at once. The web
# build streams tiles; here we load a fixed core radius (P2 = streaming).
const MAP_RADIUS: = 2

var _tex_asphalt: Texture2D
var _tex_concrete: Texture2D

# Day/night: a slow clock (phase 0..1 over DAY_LENGTH seconds) drives the sun
# angle + ambient/fog. Anchored so dusk — the game's signature look — sits at
# the start and recurs each cycle.
const DAY_LENGTH: float = 600.0     # seconds for a full day→night→day loop
var _sun: DirectionalLight3D = null
var _env: Environment = null
var _day_phase: float = 0.0

# Weather: rain drifts in and out. The emitter rides above the player; when it's
# raining the fog thickens a touch on top of the day/night base.
var _rain: CPUParticles3D = null
var _weather_t: float = 25.0
var _raining: bool = false
# Real-map builder (MapLoader). Untyped because it replaces the old CityBuilder
# but exposes the same spawn fields (player_spawn, car_slots, light_slots,
# npc_waypoints, npc_spawns, mission_giver_pos/rot, job_points).
var _city
var _player: CharacterBody3D
var _hud: CanvasLayer
var _drivable_cars: Array = []
var _traffic: Array = []
var _npcs: Array = []
var _street_lights: Array = []
var _contacts: Array = []
var _job_manager: Node = null
var _wanted_system: Node = null


func _ready() -> void :
    _tex_asphalt = load("res://assets/textures/floors/wet_asphalt.png")
    _tex_concrete = load("res://assets/textures/floors/concrete_sidewalk.png")

    _setup_environment()
    _build_city()
    _place_cars()
    _spawn_traffic()
    _place_streetlights()
    _spawn_contacts()
    _spawn_npcs()
    _spawn_player()
    for tc in _traffic:
        if is_instance_valid(tc):
            tc.player = _player
    for npc in _npcs:
        if is_instance_valid(npc):
            npc.player = _player
    _build_hud()
    _build_systems()
    _spawn_pickups()
    _spawn_shops()
    _build_shop_menu()
    _start_audio()
    _setup_weather()


func _setup_weather() -> void :
    var rain: = CPUParticles3D.new()
    rain.name = "Rain"
    rain.amount = 700
    rain.lifetime = 1.1
    rain.local_coords = false
    rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
    rain.emission_box_extents = Vector3(26.0, 0.5, 26.0)
    rain.direction = Vector3(0.05, -1.0, 0.0)
    rain.spread = 2.0
    rain.gravity = Vector3(0.0, -32.0, 0.0)
    rain.initial_velocity_min = 16.0
    rain.initial_velocity_max = 22.0
    var streak: = BoxMesh.new()
    streak.size = Vector3(0.015, 0.5, 0.015)
    rain.mesh = streak
    var mat: = StandardMaterial3D.new()
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.albedo_color = Color(0.7, 0.78, 0.9, 0.5)
    rain.material_override = mat
    rain.emitting = false
    add_child(rain)
    _rain = rain



func _setup_environment() -> void :
    var env: = Environment.new()
    env.background_mode = Environment.BG_SKY
    var sky: = load("res://assets/textures/skyboxes/south_coast_dusk_sky.tres") as Sky
    if sky:
        env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
    env.ambient_light_energy = 0.55
    env.background_energy_multiplier = 0.9

    env.tonemap_mode = Environment.TONE_MAPPER_ACES
    env.tonemap_exposure = 1.0

    env.glow_enabled = true
    env.glow_intensity = 0.4
    env.glow_bloom = 0.1

    # Lighter depth haze: the previous density (0.011) washed the whole city to
    # flat grey. Pull it well back so streets/buildings read with contrast, keep
    # just enough aerial perspective for distance.
    env.fog_enabled = true
    env.fog_light_color = Color(0.55, 0.60, 0.64)
    env.fog_density = 0.0035
    env.fog_sky_affect = 0.25
    env.fog_aerial_perspective = 0.25

    var we: = WorldEnvironment.new()
    we.name = "WorldEnvironment"
    we.environment = env
    add_child(we)
    _env = env

    var sun: = DirectionalLight3D.new()
    sun.name = "Sun"
    sun.light_color = Color(1.0, 0.86, 0.72)
    sun.light_energy = 0.8
    sun.shadow_enabled = true
    sun.shadow_bias = 0.05
    sun.rotation_degrees = Vector3(-26.0, 52.0, 0.0)
    add_child(sun)
    _sun = sun
    _apply_day_night()


# Drive the sun + ambient/fog from _day_phase (0=dusk → night → dawn → day →
# back to dusk). Kept warm and gentle so the city keeps its dusk character.
func _process(delta: float) -> void :
    _day_phase = fposmod(_day_phase + delta / DAY_LENGTH, 1.0)
    _apply_day_night()
    _update_weather(delta)
    if GameManager:
        GameManager.day_phase = _day_phase
        GameManager.raining = _raining


func _update_weather(delta: float) -> void :
    if _rain == null:
        return
    # Keep the emitter riding above the player.
    if _player != null and is_instance_valid(_player):
        _rain.global_position = _player.global_position + Vector3(0.0, 22.0, 0.0)
    # Flip weather on a long-ish timer (rain spells ~40s, dry ~90s).
    _weather_t -= delta
    if _weather_t <= 0.0:
        _raining = not _raining
        _rain.emitting = _raining
        _weather_t = 40.0 if _raining else 90.0
    # Rain thickens the haze on top of the day/night base.
    if _raining and _env != null:
        _env.fog_density += 0.004


func _apply_day_night() -> void :
    if _sun == null or _env == null:
        return
    # Sun elevation: high at midday, below horizon at night. phase 0 = dusk.
    var ang: float = _day_phase * TAU
    var elevation: float = sin(ang + PI)        # +1 midday, -1 midnight; 0 at dusk/dawn
    _sun.rotation_degrees = Vector3(lerp(-2.0, -62.0, clampf((elevation + 1.0) * 0.5, 0.0, 1.0)), 52.0, 0.0)
    var daylight: float = clampf(elevation, 0.0, 1.0)        # 0 at/below horizon, 1 midday
    var night: float = clampf( - elevation, 0.0, 1.0)
    # Warm low sun, cooler bright midday; sun fades out at night.
    var warm: = Color(1.0, 0.66, 0.42)
    var noon: = Color(1.0, 0.93, 0.82)
    _sun.light_color = warm.lerp(noon, daylight)
    _sun.light_energy = lerp(0.18, 1.05, daylight)
    _env.ambient_light_energy = lerp(0.28, 0.7, daylight)
    _env.background_energy_multiplier = lerp(0.45, 1.0, daylight)
    # Heavier blue haze at night, light warm haze by day.
    _env.fog_light_color = Color(0.30, 0.34, 0.42).lerp(Color(0.55, 0.60, 0.64), daylight)
    _env.fog_density = lerp(0.0065, 0.0030, daylight)
    _env.glow_intensity = lerp(0.7, 0.35, daylight) + night * 0.2
    # Streetlights warm up at dusk and glow through the night.
    var lamp_e: float = clampf(1.0 - daylight, 0.0, 1.0) * 3.0
    for lamp in _street_lights:
        if is_instance_valid(lamp):
            lamp.light_energy = lamp_e


func _make_ground() -> void :
    var body: = StaticBody3D.new()
    body.name = "Ground"
    body.collision_layer = 1
    body.collision_mask = 0
    add_child(body)

    var col: = CollisionShape3D.new()
    var box: = BoxShape3D.new()
    box.size = Vector3(900, 1.0, 900)
    col.shape = box
    col.position.y = -0.5
    body.add_child(col)

    var mesh: = MeshInstance3D.new()
    var plane: = PlaneMesh.new()
    plane.size = Vector2(900, 900)
    mesh.mesh = plane
    var mat: = StandardMaterial3D.new()
    mat.albedo_color = Color(0.15, 0.16, 0.17)
    if _tex_concrete:
        mat.albedo_texture = _tex_concrete
        mat.uv1_scale = Vector3(150, 150, 1)
    mat.roughness = 0.95
    mesh.set_surface_override_material(0, mat)
    body.add_child(mesh)



func _build_city() -> void :
    # Build the real New Bedford map (OSM footprints + roads + land use) instead
    # of the procedural grid. MapLoader also lays a ground plane + collider and
    # derives all the spawn fields game_world relies on.
    _city = MapLoaderScript.new()
    _city.build_region(self, Vector2i.ZERO, MAP_RADIUS)



func _place_cars() -> void :
    if _city == null:
        return

    var models: = [
        {"path": "res://assets/props/vehicles/sedan.glb", "h": 1.5, "name": "Sedan", "spd": 11.0, "trq": 95.0}, 
        {"path": "res://assets/props/vehicles/taxi.glb", "h": 1.5, "name": "Cab", "spd": 12.5, "trq": 105.0}, 
        {"path": "res://assets/props/vehicles/suv.glb", "h": 1.85, "name": "SUV", "spd": 9.5, "trq": 130.0}, 
    ]
    var slots: Array = _city.car_slots

    var drivable: int = min(DRIVABLE_CARS, slots.size())
    for i in drivable:
        var slot = slots[i]
        var m: Dictionary = models[i % models.size()]
        _spawn_drivable_car(m, slot[0], slot[1])

    var placed: = 0
    var idx: = drivable
    while idx < slots.size() and placed < MAX_STATIC_CARS:
        var slot2 = slots[idx]
        var m2: Dictionary = models[(placed + 1) % models.size()]
        _place_car(m2["path"], slot2[0], slot2[1], m2["h"])
        placed += 1
        idx += 2


func _spawn_drivable_car(m: Dictionary, pos: Vector3, rot_y: float) -> void :
    var car: = Node3D.new()
    car.set_script(CarScript)
    car.model_path = m["path"]
    car.model_height = m["h"]
    car.display_name = m["name"]
    car.max_throttle = m["spd"]
    car.torque = m["trq"]
    add_child(car)
    car.place_at(pos, rot_y)
    _drivable_cars.append(car)


func _place_car(path: String, pos: Vector3, rot_y: float, height: float) -> void :
    var scene: = load(path) as PackedScene
    if scene == null:
        return
    var inst: = scene.instantiate()
    add_child(inst)
    inst.position = pos
    inst.rotation_degrees.y = rot_y
    ModelUtils.scale_to_height(inst, height)
    ModelUtils.ground_model(inst, 0.0)
    ModelUtils.add_per_part_convex_collision(inst, 1)


# Ambient moving traffic — kinematic cars cruising the road-derived waypoints.
func _spawn_traffic() -> void :
    if _city == null:
        return
    var waypoints: PackedVector3Array = _city.npc_waypoints
    if waypoints.size() < 2:
        return
    var models: = [
        ["res://assets/props/vehicles/sedan.glb", 1.5, 8.5],
        ["res://assets/props/vehicles/taxi.glb", 1.5, 9.5],
        ["res://assets/props/vehicles/suv.glb", 1.85, 7.5],
    ]
    var n: int = mini(TRAFFIC_CARS, waypoints.size())
    for i in n:
        var m: Array = models[i % models.size()]
        var tc: = CharacterBody3D.new()
        tc.set_script(TrafficCarScript)
        tc.setup(m[0], m[1], m[2], waypoints)
        add_child(tc)
        var wp: Vector3 = waypoints[(i * 7) % waypoints.size()]
        tc.global_position = Vector3(wp.x, 0.6, wp.z)
        _traffic.append(tc)


func _place_streetlights() -> void :
    if _city == null:
        return
    var light_path: = "res://assets/props/decorations/streetlight.glb"
    var scene: = load(light_path) as PackedScene
    for pos in _city.light_slots:
        if scene:
            var inst: = scene.instantiate() as Node3D
            add_child(inst)
            inst.position = pos
            ModelUtils.scale_to_height(inst, 6.0)
            ModelUtils.ground_model(inst, 0.0)
            ModelUtils.add_per_part_convex_collision(inst, 1)
        var light: = OmniLight3D.new()
        light.light_color = Color(1.0, 0.74, 0.42)
        light.light_energy = 0.0      # day/night drives this (on at night)
        light.omni_range = 18.0
        light.shadow_enabled = false
        light.position = pos + Vector3(0, 5.4, 0)
        add_child(light)
        _street_lights.append(light)



func _spawn_contacts() -> void :

    var spots: = [
        [_city.mission_giver_pos if _city else Vector3(12, 0, 14), _city.mission_giver_rot if _city else 200.0], 
        [Vector3(58.0, 0, 50.0), 220.0], 
        [Vector3(-54.0, 0, -46.0), 30.0], 
    ]
    for s in spots:
        var contact: = Node3D.new()
        contact.set_script(MISSION_GIVER_SCRIPT)
        add_child(contact)
        contact.global_position = s[0]
        contact.rotation_degrees.y = s[1]
        _contacts.append(contact)


func _build_systems() -> void :
    if _player == null:
        return
    _wanted_system = Node.new()
    _wanted_system.set_script(WantedSystemScript)
    add_child(_wanted_system)
    _wanted_system.setup(_player, self)

    _job_manager = Node.new()
    _job_manager.set_script(JobManagerScript)
    add_child(_job_manager)
    _job_manager.setup(_player, self, _job_locations())


    for c in _contacts:
        if is_instance_valid(c):
            c.job_manager = _job_manager


    var spawn: Vector3 = _city.player_spawn if _city else Vector3(8, 0.6, 8)
    if _player.has_method("register_systems"):
        _player.register_systems(_wanted_system, spawn)
    if _player.has_method("register_cars"):
        _player.register_cars(_drivable_cars)
    if _hud and _hud.has_method("bind_systems"):
        _hud.bind_systems(_job_manager, _wanted_system)


func _job_locations() -> Array[Vector3]:
    var pts: Array[Vector3] = []
    if _city:
        for p in _city.job_points:
            pts.append(p)
    return pts


func _spawn_pickups() -> void :
    if _player == null:
        return
    var spawn: Vector3 = _city.player_spawn if _city else Vector3(8, 0.6, 8)

    var specs: = [
        ["weapon", "pistol", spawn + Vector3(6.0, 0, -8.0)], 
        ["weapon", "bat", Vector3(68.0, 0.5, 10.0)], 
        ["weapon", "shotgun", Vector3(-48.0, 0.5, 66.0)], 
        ["weapon", "rifle", Vector3(-100.0, 0.5, -98.0)], 
        ["medkit", "", Vector3(12.0, 0.5, 64.0)], 
        ["medkit", "", Vector3(64.0, 0.5, -64.0)], 
        ["armor", "", Vector3(-64.0, 0.5, -8.0)], 
        ["armor", "", Vector3(104.0, 0.5, 100.0)], 
    ]
    for s in specs:
        var pickup: = Node3D.new()
        pickup.set_script(WeaponPickupScript)
        add_child(pickup)
        pickup.setup(s[2], _player, s[0], s[1], 0)


func _spawn_shops() -> void :
    var spots: = [
        Vector3(50.0, 0.0, 6.0), 
        Vector3(-52.0, 0.0, -12.0), 
        Vector3(6.0, 0.0, -110.0), 
    ]
    for p in spots:
        var shop: = Node3D.new()
        shop.set_script(ShopScript)
        add_child(shop)
        shop.setup(p, "gun")


func _build_shop_menu() -> void :
    var shop_menu: = CanvasLayer.new()
    shop_menu.set_script(ShopMenuScript)
    add_child(shop_menu)
    if _player:
        shop_menu.bind_player(_player)


func _spawn_npcs() -> void :
    if _city == null:
        return
    var waypoints: PackedVector3Array = _city.npc_waypoints
    var peds: = [
        ["res://assets/characters/pedestrian_male/pedestrian_male.glb", "res://assets/characters/pedestrian_male/pedestrian_male_animations.tres"], 
        ["res://assets/characters/pedestrian_female/pedestrian_female.glb", "res://assets/characters/pedestrian_female/pedestrian_female_animations.tres"], 
    ]
    for i in _city.npc_spawns.size():
        var npc: = CharacterBody3D.new()
        npc.set_script(NPC_SCRIPT)
        var ped = peds[i % peds.size()]
        npc.setup(ped[0], ped[1], waypoints)
        add_child(npc)
        npc.global_position = _city.npc_spawns[i]
        _npcs.append(npc)


func _spawn_player() -> void :
    _player = PLAYER_SCENE.instantiate()
    add_child(_player)
    _player.global_position = _city.player_spawn if _city else Vector3(8, 0.6, 8)
    if GameManager and GameManager.has_spawn_override:
        _player.global_position = GameManager.player_spawn_override


func _build_hud() -> void :
    _hud = HUD_SCRIPT.new()
    add_child(_hud)
    if _player:
        _hud.bind_player(_player)


func _start_audio() -> void :
    if not AudioManager:
        return
    var music: = load("res://assets/audio/music/music_exploration_explore_theme.mp3")
    if music:
        if music is AudioStreamMP3:
            (music as AudioStreamMP3).loop = true
        AudioManager.play_music(music, -10.0, 1.5)
    var ambient: = load("res://assets/audio/ambient/ambient_coastal_city_coastal_city.mp3")
    if ambient:
        var amb: = AudioStreamPlayer.new()
        amb.stream = ambient
        amb.bus = "SFX"
        amb.volume_db = -16.0
        amb.autoplay = false
        amb.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
        if ambient is AudioStreamMP3:
            (ambient as AudioStreamMP3).loop = true
        add_child(amb)
        amb.play()
