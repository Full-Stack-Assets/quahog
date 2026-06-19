## GameManager.gd
## Autoload singleton — manages global game state, scene transitions, and auto-save.
## Ported from GameManager.cs (Unity) to Godot 4 GDScript.
## Access via: GameManager.<method_or_property>
extends Node

# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------
enum GameState {
	BOOT,
	MAIN_MENU,
	PLAYING,
	PAUSED,
	CUTSCENE,
}

# ---------------------------------------------------------------------------
# Signals  (replaces C# Action<T> events)
# ---------------------------------------------------------------------------
signal state_changed(new_state: int)   ## Emitted whenever the game state changes.
signal auto_save()                     ## Emitted when an automatic save should occur.

# ---------------------------------------------------------------------------
# Exports / serialised fields
# ---------------------------------------------------------------------------
@export var auto_save_interval: float = 300.0  ## Seconds between auto-saves (default 5 min).

# ---------------------------------------------------------------------------
# Private state
# ---------------------------------------------------------------------------
var _current_state: GameState = GameState.BOOT
var _auto_save_timer: float = 0.0
var _is_auto_save_running: bool = false

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
	print("[GameManager] Initialised. State: BOOT")
	_start_auto_save_loop()


func _process(delta: float) -> void:
	_tick_auto_save(delta)

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Returns the current game state.
func get_state() -> GameState:
	return _current_state


## Transitions to a new game state. Emits state_changed signal.
func set_state(new_state: GameState) -> void:
	if new_state == _current_state:
		return
	var old_state: GameState = _current_state
	_current_state = new_state
	print("[GameManager] State: %s → %s" % [GameState.keys()[old_state], GameState.keys()[new_state]])
	emit_signal("state_changed", new_state)

	# Handle pause tree scaling
	match new_state:
		GameState.PAUSED:
			get_tree().paused = true
		GameState.PLAYING, GameState.CUTSCENE, GameState.MAIN_MENU, GameState.BOOT:
			get_tree().paused = false


## Loads a scene by its resource path. Transitions state to PLAYING after load.
## Example: GameManager.load_scene("res://scenes/world/SouthCoast.tscn")
func load_scene(scene_path: String) -> void:
	print("[GameManager] Loading scene: %s" % scene_path)
	get_tree().change_scene_to_file(scene_path)
	# State transitions are handled by the scene itself calling set_state(),
	# but we leave Playing as the default expectation for world scenes.


## Manually triggers an auto-save and resets the auto-save countdown.
func trigger_auto_save() -> void:
	if _current_state != GameState.PLAYING:
		print("[GameManager] Auto-save skipped — not in PLAYING state.")
		return
	print("[GameManager] Auto-save triggered.")
	_auto_save_timer = 0.0
	emit_signal("auto_save")
	# SaveLoadManager will listen to this signal and perform the actual save.

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

func _start_auto_save_loop() -> void:
	_auto_save_timer = 0.0
	_is_auto_save_running = true


func _tick_auto_save(delta: float) -> void:
	if not _is_auto_save_running:
		return
	if _current_state != GameState.PLAYING:
		return

	_auto_save_timer += delta
	if _auto_save_timer >= auto_save_interval:
		trigger_auto_save()
