extends Node3D
class_name Car






var model_path: String = "res://assets/props/vehicles/sedan.glb"
var model_height: float = 1.5
var display_name: String = "Sedan"


var sphere: RigidBody3D
var raycast: RayCast3D
var vehicle_model: Node3D
var camera: Camera3D
var engine_sound: AudioStreamPlayer3D
var screech_sound: AudioStreamPlayer3D


var active: bool = false
var _steer: float = 0.0
var _throttle: float = 0.0

var input: Vector3 = Vector3.ZERO
var normal: Vector3 = Vector3.UP
var acceleration: float = 0.0
var angular_speed: float = 0.0
var linear_speed: float = 0.0
var colliding: bool = false
var linear_velocity: Vector3 = Vector3.ZERO
var prev_position: Vector3 = Vector3.ZERO


var max_throttle: float = 11.0
var torque: float = 95.0


func _ready() -> void :

    raycast = RayCast3D.new()
    raycast.name = "Ground"
    raycast.target_position = Vector3(0, -1.0, 0)
    raycast.position = Vector3(0, 0.5, 0)
    add_child(raycast)


    vehicle_model = Node3D.new()
    vehicle_model.name = "Container"
    add_child(vehicle_model)

    var scene: = load(model_path) as PackedScene
    if scene:
        var model: = scene.instantiate()
        model.name = "Model"
        vehicle_model.add_child(model)
        ModelUtils.scale_to_height(model, model_height)
        ModelUtils.ground_model(model, 0.0)


    engine_sound = AudioStreamPlayer3D.new()
    engine_sound.name = "EngineSound"
    engine_sound.stream = load("res://assets/audio/sfx/vehicle/vehicle_car_engine_loop.mp3")
    engine_sound.unit_size = 8.0
    engine_sound.max_db = 0.0
    engine_sound.volume_db = -40.0
    engine_sound.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
    if engine_sound.stream is AudioStreamMP3:
        (engine_sound.stream as AudioStreamMP3).loop = true
    vehicle_model.add_child(engine_sound)

    screech_sound = AudioStreamPlayer3D.new()
    screech_sound.name = "ScreechSound"
    screech_sound.stream = load("res://assets/audio/sfx/vehicle/vehicle_tire_screech.mp3")
    screech_sound.volume_db = -60.0
    screech_sound.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
    if screech_sound.stream is AudioStreamMP3:
        (screech_sound.stream as AudioStreamMP3).loop = true
    vehicle_model.add_child(screech_sound)


    sphere = RigidBody3D.new()
    sphere.name = "Sphere"
    sphere.mass = 1000.0
    sphere.gravity_scale = 1.5
    sphere.linear_damp = 0.2
    sphere.angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
    sphere.angular_damp = 4.0
    sphere.continuous_cd = true
    sphere.contact_monitor = true
    sphere.max_contacts_reported = 2
    sphere.collision_layer = 1
    sphere.collision_mask = 1
    var pm: = PhysicsMaterial.new()
    pm.friction = 4.0
    pm.rough = true
    sphere.physics_material_override = pm
    sphere.position = Vector3(0, 0.5, 0)
    var scol: = CollisionShape3D.new()
    var ssh: = SphereShape3D.new()
    ssh.radius = 0.5
    scol.shape = ssh
    sphere.add_child(scol)
    add_child(sphere)

    prev_position = vehicle_model.position


    camera = Camera3D.new()
    camera.name = "CarCamera"
    camera.fov = 64.0
    camera.far = 400.0
    add_child(camera)
    camera.top_level = true
    _snap_camera()

    set_physics_process(true)
    _set_dormant(true)   # parked cars are frozen + skip _drive until entered, so
                         # the map can be full of takeable cars at near-zero cost


# A parked car freezes its physics body and stops per-frame driving; entering
# wakes it. Lets us scatter many drivable cars without paying for them all.
func _set_dormant(d: bool) -> void :
    if sphere:
        sphere.freeze = d
    set_physics_process(not d)


func place_at(pos: Vector3, yaw_deg: float) -> void :

    global_position = pos
    if sphere:
        sphere.global_position = pos + Vector3(0, 0.5, 0)
        sphere.linear_velocity = Vector3.ZERO
        sphere.angular_velocity = Vector3.ZERO
    if vehicle_model:
        vehicle_model.global_position = pos
        vehicle_model.rotation.y = deg_to_rad(yaw_deg)
        prev_position = vehicle_model.position
    linear_velocity = Vector3.ZERO
    # Park it: clear the drive integrator too, or _drive() keeps applying the
    # retained speed/turn and the car rolls away from where it was placed.
    linear_speed = 0.0
    angular_speed = 0.0
    acceleration = 0.0
    _throttle = 0.0
    _steer = 0.0
    if active:
        _snap_camera()


func enter(_driver: Node) -> void :
    active = true
    _set_dormant(false)   # wake the physics body
    if camera:
        camera.make_current()
    if engine_sound and not engine_sound.playing:
        engine_sound.play()
    if screech_sound and not screech_sound.playing:
        screech_sound.play()
    if AudioManager:
        var snd: = load("res://assets/audio/sfx/vehicle/vehicle_car_enter.mp3")
        if snd:
            AudioManager.play_sfx(snd, -6.0)


func exit() -> Vector3:
    active = false
    _steer = 0.0
    _throttle = 0.0
    if engine_sound:
        engine_sound.stop()
    if screech_sound:
        screech_sound.stop()

    var right: Vector3 = vehicle_model.global_basis.x.normalized()
    var out_pos: = vehicle_model.global_position + right * 2.4 + Vector3(0, 0.6, 0)
    _set_dormant(true)   # re-park: stop paying physics for the car we just left
    return out_pos


func set_drive_input(steer: float, throttle: float) -> void :
    _steer = clampf(steer, -1.0, 1.0)
    _throttle = clampf(throttle, -1.0, 1.0)


func get_speed_kmh() -> float:
    return linear_velocity.length() * 3.0


func _physics_process(delta: float) -> void :
    _drive(delta)
    if active:
        _update_camera(delta)


func _drive(delta: float) -> void :
    if not is_instance_valid(sphere):
        return
    var grounded: bool = raycast.is_colliding()

    input.x = _steer if (active and grounded) else 0.0
    input.z = (_throttle * max_throttle) if (active and grounded) else 0.0

    var direction: float = sign(linear_speed)
    if direction == 0.0:
        direction = sign(input.z) if absf(input.z) > 0.1 else 1.0

    var steering_grip: float = clampf(absf(linear_speed) / max_throttle, 0.18, 1.0)
    var target_angular: float = - input.x * steering_grip * 3.4 * direction
    angular_speed = lerpf(angular_speed, target_angular, delta * 5.0)
    vehicle_model.rotate_y(angular_speed * delta)

    if grounded:
        normal = raycast.get_collision_normal()
        if normal.dot(vehicle_model.global_basis.y) > 0.5:
            var xform: = _align_with_y(vehicle_model.global_transform, normal)
            vehicle_model.global_transform = vehicle_model.global_transform.interpolate_with(xform, 0.2).orthonormalized()
    colliding = grounded

    var target_speed: float = input.z
    if target_speed < 0.0 and linear_speed > 0.01:
        linear_speed = lerpf(linear_speed, 0.0, delta * 8.0)
    elif target_speed < 0.0:
        linear_speed = lerpf(linear_speed, target_speed * 0.5, delta * 3.0)
    else:
        linear_speed = lerpf(linear_speed, target_speed, delta * 5.0)

    acceleration = lerpf(acceleration, linear_speed, delta)

    sphere.angular_velocity += vehicle_model.get_global_transform().basis.x * (linear_speed * torque / max_throttle) * delta

    vehicle_model.position = sphere.position - Vector3(0, 0.5, 0)
    raycast.position = sphere.position
    linear_velocity = (vehicle_model.position - prev_position) / delta
    prev_position = vehicle_model.position

    _effect_engine(delta)
    _effect_skid(delta)


func _effect_engine(delta: float) -> void :
    if engine_sound == null:
        return
    if not active:
        engine_sound.volume_db = lerpf(engine_sound.volume_db, -40.0, delta * 4.0)
        return
    var speed_factor: float = clampf(absf(linear_speed) / max_throttle, 0.0, 1.0)
    var throttle_factor: float = clampf(absf(_throttle), 0.0, 1.0)
    var target_volume: float = remap(speed_factor + throttle_factor * 0.5, 0.0, 1.5, -18.0, -4.0)
    engine_sound.volume_db = lerpf(engine_sound.volume_db, target_volume, delta * 5.0)
    var target_pitch: float = remap(speed_factor, 0.0, 1.0, 0.6, 2.6)
    if throttle_factor > 0.1:
        target_pitch += 0.2
    engine_sound.pitch_scale = lerpf(engine_sound.pitch_scale, target_pitch, delta * 2.0)


func _effect_skid(delta: float) -> void :
    if screech_sound == null:
        return
    var drift: float = absf(angular_speed) * clampf(absf(linear_speed) / max_throttle, 0.0, 1.0)
    var target_volume: float = -60.0
    if active and drift > 0.5:
        target_volume = remap(clampf(drift, 0.5, 2.0), 0.5, 2.0, -16.0, -4.0)
    screech_sound.volume_db = lerpf(screech_sound.volume_db, target_volume, delta * 8.0)


func _update_camera(delta: float) -> void :
    if camera == null:
        return
    var car_pos: Vector3 = vehicle_model.global_position
    var forward: Vector3 = vehicle_model.global_basis.z.normalized()
    var desired: Vector3 = car_pos - forward * 9.0 + Vector3(0, 4.6, 0)
    camera.global_position = camera.global_position.lerp(desired, clampf(delta * 6.0, 0.0, 1.0))
    camera.look_at(car_pos + Vector3(0, 1.2, 0), Vector3.UP)


func _snap_camera() -> void :
    if camera == null or vehicle_model == null:
        return
    var car_pos: Vector3 = vehicle_model.global_position
    var forward: Vector3 = vehicle_model.global_basis.z.normalized()
    camera.global_position = car_pos - forward * 9.0 + Vector3(0, 4.6, 0)
    camera.look_at(car_pos + Vector3(0, 1.2, 0), Vector3.UP)


func _align_with_y(xform: Transform3D, new_y: Vector3) -> Transform3D:
    xform.basis.y = new_y
    xform.basis.x = - xform.basis.z.cross(new_y)
    xform.basis = xform.basis.orthonormalized()
    return xform
