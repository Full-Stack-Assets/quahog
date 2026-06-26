## GameWorld.gd
## res://scripts/world/GameWorld.gd
## Playable vertical-slice bootstrap, assembled entirely in code so it needs no
## hand-authored node graph. On _ready it builds:
##   - a WorldEnvironment (sky + filmic tonemap), wired into WeatherController
##   - a directional sun with shadows
##   - an infinite ground collider + a large ground plane (so the player can walk)
##   - the real South Coast road mesh (via MapMeshBaker, from southcoast-roads.json)
##   - a spawned PlayerController (capsule body + first-person camera rig)
## then flips GameManager into PLAYING and shows the HUD.
## Map data © OpenStreetMap contributors, ODbL.
## Project QUAHOG / Godot 4

extends Node3D

const ROAD_DATA: String = "res://data/southcoast-roads.json"

func _ready() -> void:
	_setup_environment()
	_setup_sun()
	_setup_ground()
	_setup_roads()
	var spawn: Vector3 = _find_spawn()
	_spawn_player(spawn)
	_init_world_state()
	print("[GameWorld] Ready — player spawned at %s" % spawn)

# ---------------------------------------------------------------------------
# World setup
# ---------------------------------------------------------------------------

func _setup_environment() -> void:
	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = env
	add_child(we)

	# Hand the environment to the WeatherController autoload so weather states
	# drive the real visuals (mirrors SceneBootstrap.gd).
	var weather := get_node_or_null("/root/WeatherController")
	if weather != null:
		weather.set("environment", env)
		# Re-apply CLEAR now that the environment exists (the autoload initialised
		# before this scene, when its environment was still null).
		if weather.has_method("force_state"):
			weather.force_state(weather.WeatherState.CLEAR)

func _setup_sun() -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-50.0, -120.0, 0.0)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	add_child(sun)

func _setup_ground() -> void:
	# Infinite plane collider at y=0 — the player can never fall off the world.
	var body := StaticBody3D.new()
	body.name = "Ground"
	body.collision_layer = 0b0000_0001  # "World" layer
	var col := CollisionShape3D.new()
	col.shape = WorldBoundaryShape3D.new()
	body.add_child(col)
	add_child(body)

	# Large visual ground plane, nudged just below 0 so the flat road ribbons
	# (baked at y=0) read on top without z-fighting.
	var mi := MeshInstance3D.new()
	mi.name = "GroundVisual"
	var pm := PlaneMesh.new()
	pm.size = Vector2(30000.0, 30000.0)
	mi.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.11, 0.12, 0.10)
	mat.roughness = 1.0
	mi.material_override = mat
	mi.position = Vector3(-2695.0, -0.05, -6202.0)  # centre of the map bounds
	add_child(mi)

func _setup_roads() -> void:
	var baker := Node3D.new()
	baker.set_script(load("res://scripts/world/MapMeshBaker.gd"))
	baker.name = "MapMeshBaker"
	add_child(baker)  # bake_on_ready bakes the road graph automatically

# ---------------------------------------------------------------------------
# Spawn
# ---------------------------------------------------------------------------

## Picks a sensible on-road spawn: the first New Bedford road in the graph,
## falling back to the first road, falling back to the origin.
func _find_spawn() -> Vector3:
	if not FileAccess.file_exists(ROAD_DATA):
		return Vector3(0.0, 3.0, 0.0)
	var text := FileAccess.get_file_as_string(ROAD_DATA)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return Vector3(0.0, 3.0, 0.0)
	var roads: Array = parsed.get("roads", [])
	for r in roads:
		if r.get("city") == "New Bedford":
			var pts: Array = r.get("points", [])
			if pts.size() > 0:
				return Vector3(float(pts[0][0]), 3.0, float(pts[0][1]))
	if roads.size() > 0 and roads[0].get("points", []).size() > 0:
		var p0 = roads[0]["points"][0]
		return Vector3(float(p0[0]), 3.0, float(p0[1]))
	return Vector3(0.0, 3.0, 0.0)

func _spawn_player(spawn: Vector3) -> void:
	var player := CharacterBody3D.new()
	player.set_script(load("res://scripts/player/PlayerController.gd"))
	player.name = "Player"
	player.collision_layer = 0b0000_0010  # "Player" layer
	player.collision_mask = 0b0000_0001   # collide with "World"

	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.8
	col.shape = cap
	col.position = Vector3(0.0, 0.9, 0.0)  # feet at y=0
	player.add_child(col)

	var mesh := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.4
	cm.height = 1.8
	mesh.mesh = cm
	mesh.position = Vector3(0.0, 0.9, 0.0)
	player.add_child(mesh)

	var rig := Node3D.new()
	rig.name = "CameraRig"
	rig.position = Vector3(0.0, 1.7, 0.0)  # eye height
	player.add_child(rig)

	var cam := Camera3D.new()
	cam.name = "Camera3D"
	# PlayerController moves the body toward its local +Z; a default Godot camera
	# looks down -Z, so yaw the camera 180° to look where "forward" actually is.
	cam.rotation = Vector3(0.0, PI, 0.0)
	cam.current = true
	rig.add_child(cam)

	# Exported references must be set before the body enters the tree (_ready
	# reads them on the first frame).
	player.set("camera_rig", rig)
	player.set("camera_node", cam)
	player.position = spawn
	add_child(player)

func _init_world_state() -> void:
	var clock := get_node_or_null("/root/TimeOfDayClock")
	if clock != null and clock.has_method("set_time"):
		clock.set_time(9)  # mid-morning so the slice is lit and readable

	var game := get_node_or_null("/root/GameManager")
	if game != null and game.has_method("set_state") and "GameState" in game:
		game.set_state(game.GameState.PLAYING)

	var hud := get_node_or_null("/root/HUDManager")
	if hud != null and hud.has_method("show_hud"):
		hud.show_hud()
