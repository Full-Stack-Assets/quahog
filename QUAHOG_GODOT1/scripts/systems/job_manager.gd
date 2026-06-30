extends Node
class_name JobManager




signal job_changed(active: bool, text: String, target: Vector3)

const JobMarkerScript: = preload("res://scripts/world/job_marker.gd")

enum Stage{NONE, PICKUP, DROPOFF}

var player: Node3D = null
var world: Node3D = null
var locations: Array[Vector3] = []

var stage: int = Stage.NONE
var _marker: JobMarker = null
var _pickup_pos: Vector3 = Vector3.ZERO
var _dropoff_pos: Vector3 = Vector3.ZERO
var _reward: int = 0


func setup(p_player: Node3D, p_world: Node3D, p_locations: Array[Vector3]) -> void :
    player = p_player
    world = p_world
    locations = p_locations


func has_active_job() -> bool:
    return stage != Stage.NONE


func get_objective_position() -> Vector3:
    if stage == Stage.PICKUP:
        return _pickup_pos
    elif stage == Stage.DROPOFF:
        return _dropoff_pos
    return Vector3.ZERO


func offer_job() -> bool:

    if stage != Stage.NONE:
        GameManager.show_message("Finish the job you've got first.")
        return false
    if locations.size() < 2 or player == null:
        return false

    _pickup_pos = _pick_far_location(player.global_position)
    _dropoff_pos = _pick_far_location(_pickup_pos)
    var route_m: float = _pickup_pos.distance_to(_dropoff_pos)
    _reward = 70 + int(route_m / 35.0) * 12 + (randi() % 7) * 8
    stage = Stage.PICKUP
    _spawn_marker(_pickup_pos, Color(0.95, 0.78, 0.25))
    if AudioManager:
        var snd: = load("res://assets/audio/sfx/ui/ui_job_accept.mp3")
        if snd:
            AudioManager.play_sfx(snd, -6.0)
    var km: float = route_m / 1000.0
    if km >= 1.0:
        GameManager.show_message("Job accepted — %.1f km run pays $%d." % [km, _reward])
    else:
        GameManager.show_message("Job accepted — %d m run pays $%d." % [int(route_m), _reward])
    _emit()
    return true


func _pick_far_location(from: Vector3) -> Vector3:
    var best: = locations[0]
    var best_d: = -1.0
    for _i in 6:
        var c: Vector3 = locations[randi() % locations.size()]
        var d: float = c.distance_to(from)
        if d > best_d and d > 30.0:
            best_d = d
            best = c
    return best


func _spawn_marker(pos: Vector3, color: Color) -> void :
    if _marker and is_instance_valid(_marker):
        _marker.queue_free()
    _marker = JobMarkerScript.new()
    world.add_child(_marker)
    _marker.setup(pos, 4.5, color, player)
    _marker.reached.connect(_on_marker_reached)


func _on_marker_reached() -> void :
    if stage == Stage.PICKUP:
        stage = Stage.DROPOFF
        _spawn_marker(_dropoff_pos, Color(0.3, 0.85, 0.45))
        GameManager.show_message("Package secured — deliver it to the drop-off.")
        _emit()
    elif stage == Stage.DROPOFF:
        _complete()


func _complete() -> void :
    GameManager.add_cash(_reward)
    GameManager.record_mission_complete()
    if AudioManager:
        var snd: = load("res://assets/audio/sfx/pickup/pickup_cash_reward.mp3")
        if snd:
            AudioManager.play_sfx(snd, -2.0)
    GameManager.show_message("Delivery complete! +$%d" % _reward)
    stage = Stage.NONE
    if _marker and is_instance_valid(_marker):
        _marker.queue_free()
    _marker = null
    _emit()


func _emit() -> void :
    var text: = ""
    if stage == Stage.PICKUP:
        text = "Pick up the package"
    elif stage == Stage.DROPOFF:
        var d: float = player.global_position.distance_to(_dropoff_pos) if player else 0.0
        if d >= 1000.0:
            text = "Deliver the package — %.1f km" % (d / 1000.0)
        else:
            text = "Deliver the package — %d m" % int(d)
    job_changed.emit(stage != Stage.NONE, text, get_objective_position())
