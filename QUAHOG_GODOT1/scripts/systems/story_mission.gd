extends Node
class_name StoryMission

# "Off the Boat" opener — walk Bethel → pier trouble → steal a car → safehouse.

signal mission_changed(active: bool, text: String, target: Vector3)

const JobMarkerScript: = preload("res://scripts/world/job_marker.gd")

enum Stage{NONE, BETHEL, PIER, GET_CAR, SAFEHOUSE, DONE}

var player: Node3D = null
var world: Node3D = null
var stage: int = Stage.NONE
var _marker: JobMarker = null

# Real-ish South Coast coords (world x, z = -north).
const BETHEL: = Vector3(-272.0, 0.0, -106.0)
const PIER: = Vector3(-310.0, 0.0, -88.0)
const SAFEHOUSE: = Vector3(-240.0, 0.0, -130.0)


func setup(p_player: Node3D, p_world: Node3D) -> void :
    player = p_player
    world = p_world


func try_start_opener() -> void :
    if stage != Stage.NONE:
        return
    if GameManager == null or GameManager.opener_complete:
        return
    stage = Stage.BETHEL
    GameManager.show_message("Off the Boat: head to Seamen's Bethel.")
    _spawn_marker(BETHEL, Color(0.95, 0.78, 0.25))
    _emit()


func has_active_mission() -> bool:
    return stage != Stage.NONE and stage != Stage.DONE


func get_objective_position() -> Vector3:
    match stage:
        Stage.BETHEL:
            return BETHEL
        Stage.PIER:
            return PIER
        Stage.GET_CAR, Stage.SAFEHOUSE:
            return SAFEHOUSE
    return Vector3.ZERO


func _process(_delta: float) -> void :
    if player == null or not is_instance_valid(player):
        return
    match stage:
        Stage.BETHEL:
            if _near(BETHEL, 10.0):
                stage = Stage.PIER
                GameManager.show_message("Deacon Mealy sent you to the fish pier — move.")
                _spawn_marker(PIER, Color(0.95, 0.55, 0.25))
                _emit()
        Stage.PIER:
            if _near(PIER, 12.0):
                stage = Stage.GET_CAR
                GameManager.show_message("Ambush! Jack a car and get out of here.")
                if world.has_method("get_wanted_system"):
                    var ws: Variant = world.get_wanted_system()
                    if ws and ws.has_method("add_heat"):
                        ws.add_heat(1)
                _spawn_marker(SAFEHOUSE, Color(0.35, 0.85, 0.55))
                _emit()
        Stage.GET_CAR:
            if "_driving" in player and player._driving:
                stage = Stage.SAFEHOUSE
                GameManager.show_message("Lose the heat — reach the safehouse.")
                _emit()
        Stage.SAFEHOUSE:
            if "_driving" in player and player._driving and _near(SAFEHOUSE, 14.0):
                _complete()


func _near(target: Vector3, radius: float) -> bool:
    return player.global_position.distance_to(target) <= radius


func _spawn_marker(pos: Vector3, color: Color) -> void :
    if _marker and is_instance_valid(_marker):
        _marker.queue_free()
    _marker = JobMarkerScript.new()
    world.add_child(_marker)
    _marker.setup(pos, 5.0, color, player)


func _complete() -> void :
    stage = Stage.DONE
    GameManager.opener_complete = true
    GameManager.add_cash(150)
    GameManager.record_mission_complete()
    GameManager.set_wanted(0)
    if AudioManager:
        var snd: = load("res://assets/audio/sfx/pickup/pickup_cash_reward.mp3")
        if snd:
            AudioManager.play_sfx(snd, -2.0)
    GameManager.show_message("Safehouse reached. Welcome to Mount Hope. +$150")
    if _marker and is_instance_valid(_marker):
        _marker.queue_free()
    _marker = null
    _emit()


func _emit() -> void :
    var text: = ""
    match stage:
        Stage.BETHEL:
            text = "Go to Seamen's Bethel"
        Stage.PIER:
            text = "Reach the fish pier"
        Stage.GET_CAR:
            text = "Steal a car"
        Stage.SAFEHOUSE:
            text = "Reach the safehouse"
    mission_changed.emit(has_active_mission(), text, get_objective_position())
