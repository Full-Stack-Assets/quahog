extends Node

# Radio milestone barks — hosts react to wanted level, missions, and weather.

const WANTED_LINES: Array[String] = [
    "Scanner's lightin' up downtown — somebody's havin' an exciting evening.",
    "Lotta blue lights on the waterfront tonight. Ease off the gas, huh?",
    "Police all over the South End. If that's you listenin', knock it off.",
    "Cruisers headed over the Fairhaven bridge in a hurry. Bad day gettin' longer.",
]

const MISSION_LINES: Array[String] = [
    "Word on the street: Sully's crew just wrapped another job. Money's movin'.",
    "Harbor's buzzin' — somebody made a play and lived to tell about it.",
    "The docks are talkin'. Whatever you pulled off, the whole city's gonna hear.",
]

const RAIN_LINES: Array[String] = [
    "Wipers on, comin' down steady off the bay.",
    "Roads are slick as a politician's promise — easy out there.",
    "Rain comin' sideways off Buzzards Bay. Both hands on the wheel.",
]

var _was_raining: bool = false
var _last_wanted: int = 0


func _ready() -> void :
    if GameManager:
        GameManager.wanted_changed.connect(_on_wanted)
        _last_wanted = GameManager.wanted_level


func _process(_delta: float) -> void :
    if GameManager == null:
        return
    if GameManager.raining and not _was_raining:
        if Radio and Radio.current >= 0:
            _flash(RAIN_LINES.pick_random())
    _was_raining = GameManager.raining


func _on_wanted(level: int) -> void :
    if level > _last_wanted and level >= 1 and Radio and Radio.current >= 0:
        _flash(WANTED_LINES.pick_random())
    _last_wanted = level


func on_mission_completed(_title: String) -> void :
    if Radio and Radio.current >= 0:
        _flash(MISSION_LINES.pick_random())


func _flash(line: String) -> void :
    var host: String = "Radio"
    if Radio and Radio.current >= 0:
        host = Radio.station_name(Radio.current)
    GameManager.show_message("📻 %s: %s" % [host, line])
