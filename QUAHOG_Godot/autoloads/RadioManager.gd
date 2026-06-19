# RadioManager.gd
# Autoload singleton — add to Project > Autoloads as "RadioManager"
# res://autoloads/RadioManager.gd
extends Node

# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------
enum RadioStation {
	OFF,
	WMILL_ROCK,
	RADIO_ATLANTICO,
	WRGE_TALK,
	WYAC_YACHT
}

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------
@export var crossfade_duration: float = 2.0
@export var source_a: AudioStreamPlayer
@export var source_b: AudioStreamPlayer

# ---------------------------------------------------------------------------
# Station metadata  (keyed by RadioStation enum value)
# Each entry: { "name": String, "stream_path": String, "songs": Array[String] }
# ---------------------------------------------------------------------------
const STATION_DATA: Dictionary = {
	RadioStation.OFF:             { "name": "Off",              "stream_path": "",                                    "songs": [] },
	RadioStation.WMILL_ROCK:      { "name": "WMILL Rock",       "stream_path": "res://audio/radio/wmill_rock.ogg",    "songs": ["Dirty Water", "More Than a Feeling"] },
	RadioStation.RADIO_ATLANTICO: { "name": "Radio Atlântico",  "stream_path": "res://audio/radio/radio_atlantico.ogg","songs": ["Balada do Mar", "Ondas de Lisboa"] },
	RadioStation.WRGE_TALK:       { "name": "WRGE Talk Radio",  "stream_path": "res://audio/radio/wrge_talk.ogg",     "songs": ["Evening Edition", "Sports Wrap"] },
	RadioStation.WYAC_YACHT:      { "name": "WYAC Yacht Rock",  "stream_path": "res://audio/radio/wyac_yacht.ogg",    "songs": ["Sailing", "What a Fool Believes"] },
}

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var current_station: int = RadioStation.OFF
var _normal_volume_db: float = 0.0
var _is_ducked: bool = false

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal station_changed(station: int)
signal song_changed(title: String)

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
	# Sources may be set via @export; if not, create them programmatically.
	if source_a == null:
		source_a = AudioStreamPlayer.new()
		source_a.name = "RadioSourceA"
		add_child(source_a)
	if source_b == null:
		source_b = AudioStreamPlayer.new()
		source_b.name = "RadioSourceB"
		add_child(source_b)

	source_a.bus = "Radio"
	source_b.bus = "Radio"
	source_b.volume_db = -80.0  # start silent

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------
func tune_to(station: int) -> void:
	if station == current_station:
		return

	var prev_station: int = current_station
	current_station = station

	if station == RadioStation.OFF:
		_crossfade_to_silence()
	else:
		var data: Dictionary = STATION_DATA.get(station, {})
		var path: String = data.get("stream_path", "")
		var stream: AudioStream = null
		if path != "" and ResourceLoader.exists(path):
			stream = load(path)

		_crossfade_to(stream)

		# Announce first song
		var songs: Array = data.get("songs", [])
		if songs.size() > 0:
			emit_signal("song_changed", songs[0])

	emit_signal("station_changed", current_station)

func next_station() -> void:
	var next: int = (current_station + 1) % (RadioStation.WYAC_YACHT + 1)
	tune_to(next)

func set_volume(vol: float) -> void:
	# vol: 0.0 – 1.0  linear
	_normal_volume_db = linear_to_db(clampf(vol, 0.0001, 1.0))
	if not _is_ducked:
		source_a.volume_db = _normal_volume_db

func duck_audio(duration: float) -> void:
	if _is_ducked:
		return
	_is_ducked = true
	var tween: Tween = create_tween()
	tween.tween_property(source_a, "volume_db", _normal_volume_db - 20.0, 0.3)
	await get_tree().create_timer(duration).timeout
	restore_audio()

func restore_audio() -> void:
	_is_ducked = false
	var tween: Tween = create_tween()
	tween.tween_property(source_a, "volume_db", _normal_volume_db, 0.5)

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------
func _crossfade_to(stream: AudioStream) -> void:
	# Load stream into source_b, fade source_a out, source_b in, then swap
	source_b.stream = stream
	source_b.volume_db = -80.0
	if stream != null:
		source_b.play()

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(source_a, "volume_db", -80.0, crossfade_duration)
	tween.tween_property(source_b, "volume_db", _normal_volume_db, crossfade_duration)

	await tween.finished

	source_a.stop()
	# Swap references so source_a is always the "active" player
	var tmp: AudioStreamPlayer = source_a
	source_a = source_b
	source_b = tmp
	source_b.volume_db = -80.0

func _crossfade_to_silence() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(source_a, "volume_db", -80.0, crossfade_duration)
	await tween.finished
	source_a.stop()
