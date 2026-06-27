extends CharacterBody3D
class_name TrafficCar

# Lightweight ambient traffic: a kinematic car that cruises between road-derived
# waypoints, orienting to its travel direction. Not drivable (that's car.gd) —
# this exists purely to make the streets feel alive, mirroring the web build's
# ambient traffic. Collides with buildings/player via move_and_slide.

const GRAVITY: float = 18.0
const ARRIVE_DIST: float = 3.0
const TURN_RATE: float = 6.0       # rad/s yaw smoothing toward travel heading

var model_path: String = "res://assets/props/vehicles/sedan.glb"
var model_height: float = 1.5
var speed: float = 8.0
var waypoints: PackedVector3Array = PackedVector3Array()

var mesh_root: Node3D
var _target: Vector3 = Vector3.ZERO
var _has_target: bool = false
var _yaw: float = 0.0


func setup(p_path: String, p_height: float, p_speed: float, p_waypoints: PackedVector3Array) -> void :
    model_path = p_path
    model_height = p_height
    speed = p_speed
    waypoints = p_waypoints


func _ready() -> void :
    collision_layer = 4
    collision_mask = 1

    var col: = CollisionShape3D.new()
    var box: = BoxShape3D.new()
    box.size = Vector3(2.0, 1.4, 4.4)
    col.shape = box
    col.position.y = 0.7
    add_child(col)

    mesh_root = Node3D.new()
    mesh_root.name = "CarMesh"
    add_child(mesh_root)

    if model_path != "":
        var scene: = load(model_path) as PackedScene
        if scene:
            var model: = scene.instantiate()
            mesh_root.add_child(model)
            ModelUtils.scale_to_height(model, model_height)
            ModelUtils.ground_model(model, 0.0)

    _pick_target()


func _pick_target() -> void :
    if waypoints.size() == 0:
        _has_target = false
        return
    _target = waypoints[randi() % waypoints.size()]
    _has_target = true


func _physics_process(delta: float) -> void :
    if not is_on_floor():
        velocity.y -= GRAVITY * delta
    else:
        velocity.y = 0.0

    if _has_target:
        var to_target: Vector3 = _target - global_position
        to_target.y = 0.0
        var dist: float = to_target.length()
        if dist < ARRIVE_DIST:
            _pick_target()
        else:
            var dir: Vector3 = to_target / dist
            velocity.x = dir.x * speed
            velocity.z = dir.z * speed
            var desired_yaw: float = atan2(dir.x, dir.z)
            _yaw = lerp_angle(_yaw, desired_yaw, clampf(TURN_RATE * delta, 0.0, 1.0))
            if mesh_root:
                mesh_root.rotation.y = _yaw
    else:
        velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)

    move_and_slide()
