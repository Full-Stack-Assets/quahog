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

# Cars everywhere: every parked car is a real, takeable drivable car (parked
# cars are frozen/dormant in car.gd, so a full map costs almost nothing until you
# get in one). TRAFFIC_CARS are the moving ambient cars.
# Parked cars stream around the player: a pool of CAR_POOL takeable cars is kept
# within CAR_NEAR of you, and any that drift past CAR_FAR are relocated to a fresh
# road point nearby — so there are always cars wherever you are on the big map.
# ~200 cars/km^2: CAR_NEAR is a 560 m radius (~0.98 km^2), so a 200-car pool
# fills it at roughly that density. Parked cars are dormant (see car.gd), so the
# cost of a couple hundred of them is near-zero until one is entered.
const CAR_POOL: = 200
const CAR_NEAR: = 560.0
const CAR_FAR: = 900.0
const TRAFFIC_CARS: = 16
# How many 500 m tiles out from the New Bedford core to build at once. The web
# build streams tiles; here we load a fixed core radius (P2 = streaming).
const MAP_RADIUS: = 2

# Curated South Coast hero landmarks (real OSM coords, world XZ where z = -north).
# Each gets an emissive dusk beacon + a billboard name so the corridor towns are
# recognizable the moment you fast-travel in — not anonymous streamed blocks.
const HERO_LANDMARKS: Array = [
    {"name": "Whaling Museum", "pos": Vector2(-219, 107)},
    {"name": "Seamen's Bethel", "pos": Vector2(-272, 106)},
    {"name": "New Bedford City Hall", "pos": Vector2(-582, 60)},
    {"name": "Fort Taber", "pos": Vector2(1495, 4560)},
    {"name": "Clark's Point Light", "pos": Vector2(1598, 4764)},
    {"name": "Fairhaven", "pos": Vector2(1539, 32)},
    {"name": "Dartmouth Town Hall", "pos": Vector2(-3744, 806)},
    {"name": "UMass Dartmouth", "pos": Vector2(-7190, 767)},
    {"name": "Westport", "pos": Vector2(-11897, 1521)},
    {"name": "Fall River City Hall", "pos": Vector2(-19475, -7216)},
    {"name": "Battleship Cove", "pos": Vector2(-20180, -7882)},
    {"name": "St. Mary's Cathedral", "pos": Vector2(-19696, -6969)},
    {"name": "Notre Dame Cathedral", "pos": Vector2(-17596, -6054)},
    {"name": "Narrows Center", "pos": Vector2(-20164, -7470)},
    {"name": "Green Monstah Mural", "pos": Vector2(-19570, -9192)},
    {"name": "Middleborough", "pos": Vector2(791, -28609)},
    {"name": "Taunton Green", "pos": Vector2(-14085, -29389)},
    {"name": "Bridgewater", "pos": Vector2(-4113, -39407)},
    {"name": "Brockton", "pos": Vector2(-8100, -49768)},
    {"name": "Stoughton", "pos": Vector2(-14916, -54435)},
    {"name": "Braintree", "pos": Vector2(-6951, -63664)},
    {"name": "Quincy", "pos": Vector2(-6809, -68672)},
]

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
var _last_stream_tile: Vector2i = Vector2i(999999, 999999)
var _contacts: Array = []
var _job_manager: Node = null
var _wanted_system: Node = null


func _ready() -> void :
    # Cheat: global slow-mo / fast-forward (clamped to a sane range).
    if GameManager:
        Engine.time_scale = clampf(GameManager.cheat_time_scale, 0.1, 4.0)

    _tex_asphalt = load("res://assets/textures/floors/wet_asphalt.png")
    _tex_concrete = load("res://assets/textures/floors/concrete_sidewalk.png")

    _setup_environment()
    _build_city()
    _place_cars()
    _spawn_traffic()
    _place_streetlights()
    _place_landmark_beacons()
    _spawn_contacts()
    _spawn_npcs()
    _spawn_player()
    for tc in _traffic:
        if is_instance_valid(tc):
            tc.player = _player
    for npc in _npcs:
        if is_instance_valid(npc):
            npc.player = _player
    if _player.has_signal("shots_fired"):
        _player.shots_fired.connect(_on_shots_fired)
    _build_hud()
    _build_systems()
    _spawn_pickups()
    _spawn_shops()
    _build_shop_menu()
    _start_audio()
    _setup_weather()


# Emissive dusk beacon + billboard name at each curated hero landmark, so the
# corridor towns read as recognizable places from a distance. Cheap (one mesh +
# one Label3D each); placed once at load over the whole region.
func _place_landmark_beacons() -> void :
    var root: = Node3D.new()
    root.name = "Landmarks"
    add_child(root)
    var font: Font = load("res://assets/fonts/noto_serif.ttf")
    for lm in HERO_LANDMARKS:
        var p: Vector2 = lm["pos"]
        var nm: String = str(lm["name"])
        var beacon: = MeshInstance3D.new()
        var cyl: = CylinderMesh.new()
        cyl.top_radius = 0.25
        cyl.bottom_radius = 0.7
        cyl.height = 12.0
        beacon.mesh = cyl
        var m: = StandardMaterial3D.new()
        m.albedo_color = Color(0.95, 0.72, 0.36)
        m.emission_enabled = true
        m.emission = Color(1.0, 0.74, 0.34)
        m.emission_energy_multiplier = 2.4
        beacon.material_override = m
        beacon.position = Vector3(p.x, 11.0, p.y)
        root.add_child(beacon)
        var lbl: = Label3D.new()
        lbl.text = nm
        lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        lbl.modulate = Color(1.0, 0.91, 0.68)
        lbl.outline_modulate = Color(0.0, 0.0, 0.0, 0.85)
        lbl.font_size = 64
        lbl.outline_size = 14
        lbl.pixel_size = 0.03
        lbl.position = Vector3(p.x, 19.0, p.y)
        if font:
            lbl.font = font
        root.add_child(lbl)


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

    # Cheap colour grade (works in the GL Compatibility web renderer, unlike
    # SSAO/SDFGI): a little more contrast + saturation lifts the flat dusk look.
    env.adjustment_enabled = true
    env.adjustment_brightness = 1.12
    env.adjustment_contrast = 1.06
    env.adjustment_saturation = 1.12

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
    sun.shadow_bias = 0.03
    sun.shadow_normal_bias = 1.2
    # Cascaded shadows with a bounded distance so near buildings/cars cast crisp
    # shadows without trying to shadow the whole 80 km map.
    sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
    sun.directional_shadow_max_distance = 220.0
    sun.directional_shadow_split_1 = 0.06
    sun.directional_shadow_split_2 = 0.16
    sun.directional_shadow_split_3 = 0.45
    sun.directional_shadow_blend_splits = true
    sun.rotation_degrees = Vector3(-26.0, 52.0, 0.0)
    add_child(sun)
    _sun = sun
    _apply_day_night()


# Drive the sun + ambient/fog from _day_phase (0=dusk → night → dawn → day →
# back to dusk). Kept warm and gentle so the city keeps its dusk character.
func _process(delta: float) -> void :
    # Cheat: a forced time of day pins the clock; otherwise it advances normally.
    if GameManager and GameManager.cheat_time_phase >= 0.0:
        _day_phase = GameManager.cheat_time_phase
    else:
        _day_phase = fposmod(_day_phase + delta / DAY_LENGTH, 1.0)
    _apply_day_night()
    _update_weather(delta)
    _update_streaming()
    if GameManager:
        GameManager.day_phase = _day_phase
        GameManager.raining = _raining


# Stream building tiles around the player as they cross the 500 m tile grid, so
# the whole South Coast (NB → Westport → Fall River) is explorable without
# loading every tile at once.
func _update_streaming() -> void :
    if _city == null or _player == null or not is_instance_valid(_player):
        return
    var p: Vector3 = _player.global_position
    var tile: = Vector2i(int(floor(p.x / 500.0)), int(floor(-p.z / 500.0)))
    if tile == _last_stream_tile:
        return
    _last_stream_tile = tile
    if _city.has_method("stream_buildings"):
        _city.stream_buildings(p)
    _restream_cars(p)


func _update_weather(delta: float) -> void :
    if _rain == null:
        return
    # Keep the emitter riding above the player.
    if _player != null and is_instance_valid(_player):
        _rain.global_position = _player.global_position + Vector3(0.0, 22.0, 0.0)
    # Cheat: a forced weather state overrides the timer.
    if GameManager and GameManager.cheat_force_rain >= 0:
        var want: bool = GameManager.cheat_force_rain == 1
        if _raining != want:
            _raining = want
            _rain.emitting = want
    else:
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
    # Much brighter floors so dusk/night reads clearly instead of near-black.
    _sun.light_energy = lerp(0.6, 1.4, daylight)
    _env.ambient_light_energy = lerp(0.85, 1.15, daylight)
    _env.background_energy_multiplier = lerp(0.75, 1.1, daylight)
    # Lighter haze overall (it was crushing the foreground to black).
    _env.fog_light_color = Color(0.34, 0.38, 0.46).lerp(Color(0.58, 0.63, 0.67), daylight)
    _env.fog_density = lerp(0.0030, 0.0016, daylight)
    _env.glow_intensity = lerp(0.7, 0.35, daylight) + night * 0.2
    # Time-of-day colour grade: richer, moodier at dusk/night; flatter by day.
    _env.adjustment_saturation = lerp(1.22, 1.10, daylight)
    _env.adjustment_contrast = lerp(1.12, 1.05, daylight)
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
        {"path": "res://assets/props/vehicles/sedan.glb", "h": 1.5, "name": "Sedan", "spd": 11.0, "trq": 95.0, "mass": 1000.0},
        {"path": "res://assets/props/vehicles/taxi.glb", "h": 1.5, "name": "Cab", "spd": 12.5, "trq": 105.0, "mass": 1100.0},
        {"path": "res://assets/props/vehicles/suv.glb", "h": 1.85, "name": "SUV", "spd": 9.5, "trq": 130.0, "mass": 1500.0},
    ]
    # Spawn the pool on road points near where the player starts (dense), not
    # smeared across the whole 80 km region. _restream_cars keeps them near you.
    var slots: Array = _city.car_slots
    if _city.has_method("road_points_near"):
        slots = _city.road_points_near(_city.player_spawn, CAR_NEAR, 800)
    slots.shuffle()
    var count: int = mini(CAR_POOL, slots.size())
    for i in count:
        var slot = slots[i]
        var m: Dictionary = models[i % models.size()]
        var park: Array = _parked_xform(slot)
        _spawn_drivable_car(m, park[0], park[1])


# Park a car at the curb: offset the road-centerline sample sideways by half the
# road width + a margin, aligned to the road heading, so cars line the streets
# instead of sitting in the travel lanes. Side is deterministic per location so a
# car re-streamed to the same spot lands on the same curb.
func _parked_xform(slot: Array) -> Array:
    var pos: Vector3 = slot[0]
    var yaw: float = slot[1]
    var width: float = (float(slot[2]) if slot.size() > 2 else 6.0)
    var rad: float = deg_to_rad(yaw)
    var right: Vector3 = Vector3(cos(rad), 0.0, - sin(rad))
    var side: float = 1.0 if (int(absf(pos.x) + absf(pos.z)) % 2 == 0) else -1.0
    var offset: Vector3 = right * side * (width * 0.5 + 1.5)
    return [pos + offset, yaw]


# Relocate parked cars that have drifted far from the player onto road points
# nearby, so the streamed world always has ~CAR_POOL takeable cars around you.
func _restream_cars(center: Vector3) -> void :
    if _city == null or not _city.has_method("road_points_near"):
        return
    var cand: Array = _city.road_points_near(center, CAR_NEAR, 800)
    if cand.is_empty():
        return
    cand.shuffle()
    var ci: int = 0
    for car in _drivable_cars:
        if not is_instance_valid(car):
            continue
        if _player != null and _player.current_car == car:
            continue
        var cp: Vector3 = car.global_position
        if Vector2(cp.x - center.x, cp.z - center.z).length() <= CAR_FAR:
            continue
        while ci < cand.size():
            var slot = cand[ci]
            ci += 1
            var sp: Vector3 = slot[0]
            if Vector2(sp.x - center.x, sp.z - center.z).length() > 40.0:
                var park: Array = _parked_xform(slot)
                car.place_at(park[0], park[1])
                break


func _spawn_drivable_car(m: Dictionary, pos: Vector3, rot_y: float) -> void :
    var car: = Node3D.new()
    car.set_script(CarScript)
    car.model_path = m["path"]
    car.model_height = m["h"]
    car.display_name = m["name"]
    car.max_throttle = m["spd"]
    car.torque = m["trq"]
    car.mass = m.get("mass", 1000.0)
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
    var want_traffic: int = TRAFFIC_CARS
    if GameManager:
        want_traffic = int(round(float(TRAFFIC_CARS) * GameManager.cheat_traffic_mult))
        # Time-of-day: roughly full traffic by day, ~45% in the small hours.
        var elev: float = sin(GameManager.day_phase * TAU + PI)
        var daylight: float = clampf((elev + 1.0) * 0.5, 0.0, 1.0)
        want_traffic = int(round(want_traffic * lerpf(0.45, 1.0, daylight)))
    var n: int = mini(max(want_traffic, 1), waypoints.size())
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


# Gunfire scatters nearby pedestrians and draws police attention.
func _on_shots_fired(at: Vector3) -> void :
    for npc in _npcs:
        if is_instance_valid(npc) and npc.has_method("panic"):
            npc.panic(at)
    # Firing in public draws the law: first shot earns a star; cops escalate it.
    if _wanted_system and _wanted_system.has_method("add_heat") and GameManager and GameManager.wanted_level < 1:
        _wanted_system.add_heat(1)


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
        if GameManager.has_saved_pos and _player.has_method("set_heading"):
            _player.set_heading(GameManager.saved_yaw)
        # Seed the building stream around the override (e.g. a cheat spawn far from
        # downtown) so you don't drop into an empty area before _process catches up.
        if _city and _city.has_method("stream_buildings"):
            _city.stream_buildings(_player.global_position)


func _build_hud() -> void :
    _hud = HUD_SCRIPT.new()
    add_child(_hud)
    if _player:
        _hud.bind_player(_player)


func _start_audio() -> void :
    # No auto-started background music: the radio (number keys 1-9 / HUD) is the
    # only music source, so the world is quiet until the player tunes a station.
    # The looping exploration theme + coastal-city ambience were removed on
    # request — they played over everything whether or not the radio was on.
    pass
