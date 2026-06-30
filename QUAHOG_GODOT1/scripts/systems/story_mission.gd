extends Node
class_name StoryMission

# Campaign driver: opener + Act I (Auction Rules, Linguiça Run, Harbor Heat).
# Steps mirror the web mission chain (world x, z = -north).

signal mission_changed(active: bool, text: String, target: Vector3)
signal mission_completed(title: String)

const JobMarkerScript: = preload("res://scripts/world/job_marker.gd")

const SAFEHOUSE: = Vector3(-188.0, 0.0, -40.0)
const BETHEL: = Vector3(-272.0, 0.0, -106.0)
const PIER: = Vector3(-310.0, 0.0, -88.0)
const OPENER_SAFE: = Vector3(-240.0, 0.0, -130.0)
const QUOHOG_REPUBLIC: = Vector3(-240.0, 0.0, -122.0)
const ANVIL_GARAGE: = Vector3(-320.0, 0.0, -60.0)
const LONG_ISLAND_BAR: = Vector3(6092.0, 0.0, -4485.0)

const MISSIONS: Array = [
    {
        "title": "Off the Boat",
        "steps": [
            {"text": "Go to Seamen's Bethel", "pos": BETHEL, "radius": 10.0},
            {"text": "Reach the fish pier", "pos": PIER, "radius": 12.0},
            {"text": "Steal a car", "need_car": true},
            {"text": "Reach the safehouse", "pos": OPENER_SAFE, "radius": 14.0, "need_car": true},
        ],
        "reward": 150,
        "sets_opener": true,
    },
    {
        "title": "Auction Rules",
        "steps": [
            {"text": "Grab a car — Sully's collectors are on the docks", "need_car": true},
            {"text": "Lean on the collectors at the Quohog Republic", "pos": QUOHOG_REPUBLIC, "radius": 16.0, "need_car": true},
            {"text": "Cool the car at Reggie's Anvil Garage", "pos": ANVIL_GARAGE, "radius": 14.0, "no_heat": true, "reward": 700},
        ],
        "reward": 0,
    },
    {
        "title": "The Linguiça Run",
        "steps": [
            {"text": "Grab a car", "need_car": true},
            {"text": "Pick up the package at Off the Hook (Long Island)", "pos": LONG_ISLAND_BAR, "radius": 18.0, "need_car": true},
            {"text": "Run it downtown to the Quohog Republic", "pos": QUOHOG_REPUBLIC, "radius": 16.0, "reward": 900},
        ],
        "reward": 0,
    },
    {
        "title": "Harbor Heat",
        "steps": [
            {"text": "Hit Sully's count house — grab a fast car", "need_car": true},
            {"text": "Lose the cops, then go to ground at the safehouse", "pos": SAFEHOUSE, "radius": 12.0, "no_heat": true, "reward": 1200},
        ],
        "reward": 0,
    },
]

var player: Node3D = null
var world: Node3D = null
var _marker: JobMarker = null


func setup(p_player: Node3D, p_world: Node3D) -> void :
    player = p_player
    world = p_world


func try_start_opener() -> void :
    try_resume_campaign()


func try_resume_campaign() -> void :
    if GameManager == null or GameManager.campaign_done:
        return
    var mi: int = GameManager.campaign_mi
    if mi < 0:
        mi = 0
    if mi == 0 and GameManager.opener_complete:
        mi = 1
        GameManager.campaign_mi = mi
        GameManager.campaign_step = 0
    if mi >= MISSIONS.size():
        GameManager.campaign_done = true
        return
    _begin_mission(mi)


func has_active_mission() -> bool:
    if GameManager == null or GameManager.campaign_done:
        return false
    var mi: int = GameManager.campaign_mi
    return mi >= 0 and mi < MISSIONS.size()


func get_objective_position() -> Vector3:
    var step: Dictionary = _current_step()
    if step.is_empty():
        return Vector3.ZERO
    if step.has("pos"):
        return step["pos"]
    return Vector3.ZERO


func _current_step() -> Dictionary:
    if not has_active_mission():
        return {}
    var mi: int = GameManager.campaign_mi
    var si: int = GameManager.campaign_step
    var steps: Array = MISSIONS[mi]["steps"]
    if si < 0 or si >= steps.size():
        return {}
    return steps[si]


func _process(_delta: float) -> void :
    if player == null or not is_instance_valid(player):
        return
    if not has_active_mission():
        return
    if _step_complete():
        _advance_step()


func _step_complete() -> bool:
    var step: Dictionary = _current_step()
    if step.is_empty():
        return false
    if bool(step.get("need_car", false)):
        if not ("_driving" in player and player._driving):
            return false
    if bool(step.get("no_heat", false)):
        if GameManager and GameManager.wanted_level >= 1:
            return false
    if step.has("pos"):
        var pos: Vector3 = step["pos"]
        var radius: float = float(step.get("radius", 10.0))
        if player.global_position.distance_to(pos) > radius:
            if "_driving" in player and player._driving and player.current_car:
                var car = player.current_car
                if "vehicle_model" in car and car.vehicle_model:
                    if car.vehicle_model.global_position.distance_to(pos) <= radius:
                        return true
            return false
    return true


func _advance_step() -> void :
    var mi: int = GameManager.campaign_mi
    var step: Dictionary = _current_step()
    var si: int = GameManager.campaign_step
    # Opener: fish-pier ambush raises heat before the car-jack step.
    if mi == 0 and si == 1:
        GameManager.show_message("Ambush! Jack a car and get out of here.")
        if world and world.has_method("get_wanted_system"):
            var ws: Variant = world.get_wanted_system()
            if ws and ws.has_method("add_heat"):
                ws.add_heat(1)
    var step_reward: int = int(step.get("reward", 0))
    if step_reward > 0:
        GameManager.add_cash(step_reward)
        if AudioManager:
            var snd: = load("res://assets/audio/sfx/pickup/pickup_cash_reward.mp3")
            if snd:
                AudioManager.play_sfx(snd, -2.0)
        GameManager.show_message("+$%d" % step_reward)

    GameManager.campaign_step += 1
    var steps: Array = MISSIONS[mi]["steps"]
    if GameManager.campaign_step >= steps.size():
        _finish_mission(mi)
        return
    _sync_marker()
    _emit()


func _finish_mission(mi: int) -> void :
    var mission: Dictionary = MISSIONS[mi]
    var title: String = str(mission["title"])
    var reward: int = int(mission.get("reward", 0))
    if bool(mission.get("sets_opener", false)):
        GameManager.opener_complete = true
    if reward > 0:
        GameManager.add_cash(reward)
    GameManager.record_mission_complete()
    GameManager.save_game()
    mission_completed.emit(title)

    if mi == 0:
        GameManager.show_message("Safehouse reached. Welcome to the Narrows. +$%d" % maxi(reward, 150))
    else:
        GameManager.show_message("%s complete." % title)

    GameManager.campaign_mi = mi + 1
    GameManager.campaign_step = 0
    if GameManager.campaign_mi >= MISSIONS.size():
        GameManager.campaign_done = true
        _clear_marker()
        mission_changed.emit(false, "Act I complete", Vector3.ZERO)
        GameManager.show_message("Act I wrapped — the harbor's yours. Check the radio.")
        return
    var nxt: String = str(MISSIONS[GameManager.campaign_mi]["title"])
    GameManager.show_message("Next job: %s" % nxt)
    _begin_mission(GameManager.campaign_mi)


func _begin_mission(mi: int) -> void :
    GameManager.campaign_mi = mi
    GameManager.campaign_step = 0
    GameManager.save_game()
    var title: String = str(MISSIONS[mi]["title"])
    if mi == 0 and not GameManager.opener_complete:
        GameManager.show_message("Off the Boat: head to Seamen's Bethel.")
    else:
        GameManager.show_message(title + " — " + str(MISSIONS[mi]["steps"][0]["text"]))
    _sync_marker()
    _emit()


func _sync_marker() -> void :
    var step: Dictionary = _current_step()
    if step.is_empty() or not step.has("pos"):
        _clear_marker()
        return
    _spawn_marker(step["pos"], Color(0.95, 0.78, 0.25))


func _spawn_marker(pos: Vector3, color: Color) -> void :
    if _marker and is_instance_valid(_marker):
        _marker.queue_free()
    _marker = JobMarkerScript.new()
    world.add_child(_marker)
    _marker.setup(pos, 5.0, color, player)


func _clear_marker() -> void :
    if _marker and is_instance_valid(_marker):
        _marker.queue_free()
    _marker = null


func _emit() -> void :
    var step: Dictionary = _current_step()
    var text: String = str(step.get("text", ""))
    mission_changed.emit(has_active_mission(), text, get_objective_position())
