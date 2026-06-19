## SceneBootstrap.gd
## Scene entry-point bootstrapper. Validates that all required autoload
## singletons are present, then initializes the scene state (time of day,
## weather) for the prologue sequence.
## Ported from SceneBootstrap.cs (Unity C#) for Project QUAHOG / Godot 4

extends Node

# ---------------------------------------------------------------------------
# Dependencies
# ---------------------------------------------------------------------------

## Names of the autoload singletons this scene depends on. Each must be
## registered in project.godot under [autoload] and resolvable at /root/<name>.
const REQUIRED_SINGLETONS: Array[String] = [
	"PlayerWallet",
	"GameManager",
	"WeatherController",
	"TimeOfDayClock",
	"RevenueManager",
	"RadioManager",
	"HeatManager",
	"MissionManager",
	"HUDManager",
]

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

## Validates all singleton dependencies before initializing the scene state.
func _ready() -> void:
	validate_singletons()
	initialize_scene()

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Validates that every required autoload singleton has been instantiated.
## Logs an error for each missing singleton so that missing dependencies are
## surfaced immediately.
func validate_singletons() -> void:
	var missing_count: int = 0
	for singleton_name in REQUIRED_SINGLETONS:
		missing_count += _check_singleton(singleton_name)

	if missing_count > 0:
		push_error("[SceneBootstrap] Singleton validation FAILED: %d singleton(s) missing from the scene." % missing_count)
	else:
		print("[SceneBootstrap] All singletons validated successfully.")

## Initializes the scene state for the prologue: locks time to midnight (00:00)
## and forces the weather to DENSE_FOG.
func initialize_scene() -> void:
	var weather: Node = get_node_or_null("/root/WeatherController")

	# Wire the scene's WorldEnvironment into the WeatherController autoload so
	# weather states drive the actual environment visuals.
	var world_env := get_node_or_null("WorldEnvironment") as WorldEnvironment
	if weather != null and world_env != null and world_env.environment != null:
		weather.environment = world_env.environment
		print("[SceneBootstrap] WorldEnvironment wired into WeatherController.")

	# Prologue begins at midnight for atmosphere.
	var clock: Node = get_node_or_null("/root/TimeOfDayClock")
	if clock != null:
		clock.set_time(0)
		print("[SceneBootstrap] Time set to midnight (00:00).")

	# Prologue opens with dense coastal fog.
	if weather != null:
		weather.force_state(weather.WeatherState.DENSE_FOG)
		print("[SceneBootstrap] Weather forced to DENSE_FOG for prologue.")

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

## Checks whether an autoload singleton is present and logs a descriptive error.
## Returns 1 if the singleton is missing, otherwise 0.
func _check_singleton(singleton_name: String) -> int:
	if get_node_or_null("/root/" + singleton_name) == null:
		push_error("[SceneBootstrap] Singleton '%s' is NULL. Ensure a %s autoload is registered in project.godot." % [singleton_name, singleton_name])
		return 1
	return 0
