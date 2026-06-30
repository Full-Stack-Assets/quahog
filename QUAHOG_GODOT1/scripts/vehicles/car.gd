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
var _head_l: SpotLight3D
var _head_r: SpotLight3D
var _tail_l: OmniLight3D
var _tail_r: OmniLight3D
var _light_meshes: Array[MeshInstance3D] = []


var active: bool = false
var _steer: float = 0.0
var _throttle: float = 0.0
var handbrake_on: bool = false


func set_handbrake(on: bool) -> void :
    handbrake_on = on


func honk() -> void :
    if AudioManager:
        AudioManager.play_horn()

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
var mass: float = 1000.0


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
        # The GLB already faces +Z, which is the car's measured travel direction,
        # so no extra rotation — the model faces the way it drives and the chase
        # cam (on the -Z side) sees its rear. (An earlier 180° flip made the car
        # face the camera, which read as "looking at the front / inverted".)


    sphere = RigidBody3D.new()
    sphere.name = "Sphere"
    sphere.mass = mass
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

    set_physics_process(true)
    _set_dormant(true)   # parked cars are frozen + skip _drive until entered, so
                         # the map can be full of takeable cars at near-zero cost


# The camera + engine/screech audio are created lazily on first entry, so the
# hundreds of parked cars on the map don't each carry a Camera3D + 2 audio players.
func _ensure_cabin() -> void :
    if camera == null:
        camera = Camera3D.new()
        camera.name = "CarCamera"
        camera.fov = 64.0
        camera.far = 400.0
        add_child(camera)
        camera.top_level = true
    if engine_sound == null:
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
    if screech_sound == null:
        screech_sound = AudioStreamPlayer3D.new()
        screech_sound.name = "ScreechSound"
        screech_sound.stream = load("res://assets/audio/sfx/vehicle/vehicle_tire_screech.mp3")
        screech_sound.volume_db = -60.0
        screech_sound.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
        if screech_sound.stream is AudioStreamMP3:
            (screech_sound.stream as AudioStreamMP3).loop = true
        vehicle_model.add_child(screech_sound)
    _ensure_lights()


func _ensure_lights() -> void :
    if _head_l != null:
        return
    for side in [-1.0, 1.0]:
        var spot: = SpotLight3D.new()
        spot.light_color = Color(1.0, 0.94, 0.78)
        spot.spot_range = 28.0
        spot.spot_angle = 38.0
        spot.light_energy = 0.0
        spot.shadow_enabled = false
        spot.position = Vector3(0.55 * side, 0.35, 1.05)
        spot.rotation.y = PI
        vehicle_model.add_child(spot)
        if side < 0.0:
            _head_l = spot
        else:
            _head_r = spot
        var hm: = MeshInstance3D.new()
        var hb: = BoxMesh.new()
        hb.size = Vector3(0.22, 0.1, 0.04)
        hm.mesh = hb
        var m: = StandardMaterial3D.new()
        m.albedo_color = Color(0.98, 0.94, 0.78)
        m.emission_enabled = true
        m.emission = Color(1.0, 0.92, 0.65)
        m.emission_energy_multiplier = 0.2
        hm.material_override = m
        hm.position = Vector3(0.55 * side, 0.35, 1.08)
        vehicle_model.add_child(hm)
        _light_meshes.append(hm)
    for side in [-1.0, 1.0]:
        var tail: = OmniLight3D.new()
        tail.light_color = Color(1.0, 0.15, 0.1)
        tail.omni_range = 4.5
        tail.light_energy = 0.0
        tail.position = Vector3(0.5 * side, 0.32, -1.05)
        vehicle_model.add_child(tail)
        if side < 0.0:
            _tail_l = tail
        else:
            _tail_r = tail
        var tm: = MeshInstance3D.new()
        var tb: = BoxMesh.new()
        tb.size = Vector3(0.2, 0.08, 0.04)
        tm.mesh = tb
        var tmat: = StandardMaterial3D.new()
        tmat.albedo_color = Color(0.65, 0.08, 0.08)
        tmat.emission_enabled = true
        tmat.emission = Color(0.9, 0.12, 0.1)
        tmat.emission_energy_multiplier = 0.2
        tm.material_override = tmat
        tm.position = Vector3(0.5 * side, 0.32, -1.08)
        vehicle_model.add_child(tm)
        _light_meshes.append(tm)


# Head/taillight energy from day_phase (0=day, 1=night). Braking flares tails.
func update_vehicle_lights(night: float, braking: bool = false) -> void :
    _ensure_lights()
    var head_e: float = 0.15 + night * 2.4
    var tail_e: float = 0.1 + night * 0.9 + (1.8 if braking else 0.0)
    if _head_l:
        _head_l.light_energy = head_e
    if _head_r:
        _head_r.light_energy = head_e
    if _tail_l:
        _tail_l.light_energy = tail_e
    if _tail_r:
        _tail_r.light_energy = tail_e
    var mesh_e: float = 0.2 + night * 1.4 + (0.8 if braking else 0.0)
    for mi in _light_meshes:
        if is_instance_valid(mi) and mi.material_override is StandardMaterial3D:
            (mi.material_override as StandardMaterial3D).emission_energy_multiplier = mesh_e


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
    _ensure_cabin()       # build camera + audio on first entry
    _set_dormant(false)   # wake the physics body
    _snap_camera()
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
    return linear_velocity.length() * 3.6   # m/s -> km/h


# Seconds the car has been on its side/roof; used to auto-right it.
var _flip_t: float = 0.0


func _physics_process(delta: float) -> void :
    _drive(delta)
    _recover_if_flipped(delta)
    if active:
        _update_camera(delta)


# If the car ends up on its roof/side for more than a moment, flip it upright in
# place so the player is never stranded (keeps yaw, clears spin).
func _recover_if_flipped(delta: float) -> void :
    if not is_instance_valid(vehicle_model) or not is_instance_valid(sphere):
        return
    if vehicle_model.global_basis.y.dot(Vector3.UP) < 0.25:
        _flip_t += delta
    else:
        _flip_t = 0.0
    if _flip_t > 1.5:
        _flip_t = 0.0
        var yaw: float = vehicle_model.rotation.y
        vehicle_model.global_position += Vector3(0, 1.0, 0)
        vehicle_model.rotation = Vector3(0, yaw, 0)
        sphere.global_position = vehicle_model.global_position + Vector3(0, 0.5, 0)
        sphere.linear_velocity = Vector3.ZERO
        sphere.angular_velocity = Vector3.ZERO
        linear_speed = 0.0
        angular_speed = 0.0


func _drive(delta: float) -> void :
    if not is_instance_valid(sphere):
        return
    var grounded: bool = raycast.is_colliding()

    input.x = _steer if (active and grounded) else 0.0
    input.z = (_throttle * max_throttle) if (active and grounded) else 0.0
    if GameManager and GameManager.cheat_car_turbo:
        input.z *= 2.0   # turbo: double top speed / acceleration

    var direction: float = sign(linear_speed)
    if direction == 0.0:
        direction = sign(input.z) if absf(input.z) > 0.1 else 1.0

    var steering_grip: float = clampf(absf(linear_speed) / max_throttle, 0.18, 1.0)
    # Handbrake: break rear grip so the car slides, and turn harder into the slide.
    var turn_gain: float = 4.6 if (handbrake_on and active) else 3.4
    var target_angular: float = - input.x * steering_grip * turn_gain * direction
    angular_speed = lerpf(angular_speed, target_angular, delta * 5.0)
    vehicle_model.rotate_y(angular_speed * delta)

    if grounded:
        normal = raycast.get_collision_normal()
        if normal.dot(vehicle_model.global_basis.y) > 0.5:
            var xform: = _align_with_y(vehicle_model.global_transform, normal)
            vehicle_model.global_transform = vehicle_model.global_transform.interpolate_with(xform, 0.2).orthonormalized()
    colliding = grounded

    var target_speed: float = input.z
    if handbrake_on and active:
        linear_speed = lerpf(linear_speed, 0.0, delta * 6.0)   # hard stop
    elif target_speed < 0.0 and linear_speed > 0.01:
        linear_speed = lerpf(linear_speed, 0.0, delta * 8.0)   # brake before reversing
    elif target_speed < 0.0:
        linear_speed = lerpf(linear_speed, target_speed * 0.5, delta * 3.0)  # reverse, slower
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
    if active and GameManager:
        var ang: float = GameManager.day_phase * TAU
        var daylight: float = clampf(sin(ang + PI), 0.0, 1.0)
        var night: float = clampf(1.0 - daylight, 0.0, 1.0)
        var braking: bool = handbrake_on or (_throttle < -0.05 and linear_speed > 0.5)
        update_vehicle_lights(night, braking)


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


# Camera orbit offset (driver can pan the chase cam around the car).
var cam_yaw: float = 0.0
var cam_pitch: float = 0.0


func set_cam_orbit(yaw: float, pitch: float) -> void :
    cam_yaw = yaw
    cam_pitch = clampf(pitch, -0.35, 0.9)


func _chase_pos(car_pos: Vector3) -> Vector3:
    # Forward throttle rolls toward +basis.z; park the chase cam on the opposite
    # side so push-up on the stick drives the car into the screen, not at you.
    var forward: Vector3 = vehicle_model.global_basis.z.normalized().rotated(Vector3.UP, cam_yaw)
    var dist: float = 9.0
    var height: float = 4.6 + cam_pitch * 5.0
    return car_pos - forward * dist + Vector3(0, height, 0)


# Pull the chase cam in if a building/ground is between it and the car, so it
# never clips through geometry.
func _cam_unobstructed(car_pos: Vector3, want: Vector3) -> Vector3:
    if not is_inside_tree():
        return want
    var space: = get_world_3d().direct_space_state
    if space == null:
        return want
    var eye: = car_pos + Vector3(0, 1.2, 0)
    var q: = PhysicsRayQueryParameters3D.create(eye, want)
    q.collision_mask = 1
    if is_instance_valid(sphere):
        q.exclude = [sphere.get_rid()]
    var hit: = space.intersect_ray(q)
    if hit.is_empty():
        return want
    return (hit.position as Vector3) + (eye - want).normalized() * 0.5


func _update_camera(delta: float) -> void :
    if camera == null:
        return
    var car_pos: Vector3 = vehicle_model.global_position
    var want: = _cam_unobstructed(car_pos, _chase_pos(car_pos))
    camera.global_position = camera.global_position.lerp(want, clampf(delta * 6.0, 0.0, 1.0))
    camera.look_at(car_pos + Vector3(0, 1.2, 0), Vector3.UP)


func _snap_camera() -> void :
    if camera == null or vehicle_model == null:
        return
    var car_pos: Vector3 = vehicle_model.global_position
    camera.global_position = _cam_unobstructed(car_pos, _chase_pos(car_pos))
    camera.look_at(car_pos + Vector3(0, 1.2, 0), Vector3.UP)


func _align_with_y(xform: Transform3D, new_y: Vector3) -> Transform3D:
    xform.basis.y = new_y
    xform.basis.x = - xform.basis.z.cross(new_y)
    xform.basis = xform.basis.orthonormalized()
    return xform
