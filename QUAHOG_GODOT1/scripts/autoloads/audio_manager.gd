extends Node

const MAX_SFX: int = 8

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []

var _unlocked: bool = false
var _pending_music: AudioStream = null
var _pending_music_vol: float = -6.0

func _ready() -> void :
    process_mode = Node.PROCESS_MODE_ALWAYS
    if not OS.has_feature("web"):
        _unlocked = true
    _setup_buses()
    _create_players()
    _load_settings()


# Re-apply volumes saved from the in-game Settings panel (user://settings.cfg).
func _load_settings() -> void :
    var cfg: = ConfigFile.new()
    if cfg.load("user://settings.cfg") != OK:
        return
    for bus_name in ["Master", "Music", "SFX"]:
        var idx: int = AudioServer.get_bus_index(bus_name)
        if idx >= 0 and cfg.has_section_key("audio", bus_name):
            AudioServer.set_bus_volume_db(idx, float(cfg.get_value("audio", bus_name)))

func _input(event: InputEvent) -> void :
    if _unlocked:
        return
    if event is InputEventMouseButton or event is InputEventKey or event is InputEventScreenTouch:
        _unlocked = true
        if _pending_music:
            _play_music_now(_pending_music, _pending_music_vol, 1.0)
            _pending_music = null

func _setup_buses() -> void :
    for bus_name in ["Music", "SFX"]:
        if AudioServer.get_bus_index(bus_name) == -1:
            AudioServer.add_bus()
            var idx: = AudioServer.bus_count - 1
            AudioServer.set_bus_name(idx, bus_name)
            AudioServer.set_bus_send(idx, "Master")

func _create_players() -> void :
    music_player = AudioStreamPlayer.new()
    music_player.bus = "Music"
    music_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
    add_child(music_player)
    for i in MAX_SFX:
        var p: = AudioStreamPlayer.new()
        p.bus = "SFX"
        p.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
        add_child(p)
        sfx_players.append(p)

# The radio uses this to silence the background score while a station plays
# (otherwise the explore theme and the radio overlap on the Music bus).
func set_score_muted(muted: bool) -> void :
    if music_player:
        music_player.stream_paused = muted


func play_music(stream: AudioStream, volume_db: float = -6.0, fade_in: float = 0.0) -> void :
    if stream == null:
        return
    if not _unlocked:
        _pending_music = stream
        _pending_music_vol = volume_db
        return
    _play_music_now(stream, volume_db, fade_in)

func _play_music_now(stream: AudioStream, volume_db: float, fade_in: float = 0.0) -> void :
    if music_player.stream == stream and music_player.playing:
        return
    music_player.stream = stream
    if fade_in > 0.0:
        music_player.volume_db = -40.0
        music_player.play()
        create_tween().tween_property(music_player, "volume_db", volume_db, fade_in)
    else:
        music_player.volume_db = volume_db
        music_player.play()

func stop_music() -> void :
    music_player.stop()

func play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch_variation: float = 0.0) -> void :
    if stream == null:
        return
    for p in sfx_players:
        if not p.playing:
            p.stream = stream
            p.volume_db = volume_db
            p.pitch_scale = 1.0
            if pitch_variation > 0.0:
                p.pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
            p.play()
            return


# Short two-tone horn (web parity: square-wave feel via pitched UI blips).
func play_horn() -> void :
    var snd: = load("res://assets/audio/sfx/ui/ui_ui_confirm.mp3")
    if snd == null:
        return
    play_sfx(snd, -4.0, 0.0)
    var t: = create_tween()
    t.tween_interval(0.08)
    t.tween_callback(func() -> void :
        for p in sfx_players:
            if not p.playing:
                p.stream = snd
                p.volume_db = -6.0
                p.pitch_scale = 1.22
                p.play()
                return
    )
