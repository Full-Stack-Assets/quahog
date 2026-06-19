# DJChatterSystem.gd
# res://scripts/systems/audio/DJChatterSystem.gd
extends Node

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------
@export var chatter_interval_min: float = 60.0
@export var chatter_interval_max: float = 180.0

## Keyed by context tag (e.g. "rain", "heat_3", "mission_active").
## Value: Array[AudioStream] clips for the DJ to say.
@export var chatter_clips: Dictionary = {}

## Fallback clips when no context match is found
@export var default_chatter_clips: Array[AudioStream] = []

## The AudioStreamPlayer used for DJ voice-over
@export var dj_player: AudioStreamPlayer

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal chatter_started()
signal chatter_ended()

# ---------------------------------------------------------------------------
# Internal state
# ---------------------------------------------------------------------------
var _next_chatter_time: float = 0.0
var _weather_state: String = "clear"
var _heat_level: int = 0
var _mission_active: bool = false
var _is_chattering: bool = false

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
	# Create a default AudioStreamPlayer if none exported
	if dj_player == null:
		dj_player = AudioStreamPlayer.new()
		dj_player.name = "DJPlayer"
		dj_player.bus = "Radio"
		add_child(dj_player)

	_schedule_next_chatter()

	# Connect context signals (graceful: only connect if autoloads exist)
	var weather: Node = get_node_or_null("/root/WeatherController")
	if weather != null and weather.has_signal("weather_changed"):
		weather.weather_changed.connect(_on_weather_changed)

	var heat: Node = get_node_or_null("/root/HeatManager")
	if heat != null and heat.has_signal("wanted_level_changed"):
		heat.wanted_level_changed.connect(_on_wanted_level_changed)

func _process(delta: float) -> void:
	if _is_chattering:
		return
	_next_chatter_time -= delta
	if _next_chatter_time <= 0.0:
		_play_chatter()

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------
func _schedule_next_chatter() -> void:
	_next_chatter_time = randf_range(chatter_interval_min, chatter_interval_max)

func _play_chatter() -> void:
	var clip: AudioStream = _pick_context_clip()
	if clip == null:
		_schedule_next_chatter()
		return

	_is_chattering = true
	emit_signal("chatter_started")

	# Duck the radio music while we speak
	var radio: Node = get_node_or_null("/root/RadioManager")
	var clip_length: float = clip.get_length() if clip.has_method("get_length") else 5.0
	if radio != null:
		radio.duck_audio(clip_length + 1.0)

	dj_player.stream = clip
	dj_player.play()

	await get_tree().create_timer(clip_length).timeout

	_is_chattering = false
	emit_signal("chatter_ended")
	_schedule_next_chatter()

func _pick_context_clip() -> AudioStream:
	# Build a priority-ordered list of context keys to try
	var context_keys: Array[String] = []

	if _mission_active:
		context_keys.append("mission_active")

	if _heat_level >= 4:
		context_keys.append("heat_%d" % _heat_level)
	elif _heat_level >= 2:
		context_keys.append("heat_high")

	if _weather_state != "clear":
		context_keys.append(_weather_state)

	# Try to find a clip from context-aware buckets
	for key in context_keys:
		if chatter_clips.has(key):
			var clips: Array = chatter_clips[key]
			if clips.size() > 0:
				return clips[randi() % clips.size()] as AudioStream

	# Fall back to default clips
	if default_chatter_clips.size() > 0:
		return default_chatter_clips[randi() % default_chatter_clips.size()]

	return null

# ---------------------------------------------------------------------------
# Signal callbacks
# ---------------------------------------------------------------------------
func _on_weather_changed(new_weather: String) -> void:
	_weather_state = new_weather

func _on_wanted_level_changed(level: int) -> void:
	_heat_level = level

## Call this from your mission system to notify the DJ
func set_mission_active(active: bool) -> void:
	_mission_active = active
