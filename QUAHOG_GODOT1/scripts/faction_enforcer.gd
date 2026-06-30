extends CharacterBody3D
class_name FactionEnforcer

# Street muscle that hunts the player when faction heat is up.

const MODEL: = "res://assets/characters/pedestrian_male/pedestrian_male.glb"
const ANIMS: = "res://assets/characters/pedestrian_male/pedestrian_male_animations.tres"

var run_speed: float = 5.8
var gravity: float = 20.0
var health: int = 4
var dead: bool = false

var target: Node3D = null
var wanted_system: Node = null

const FIRE_RANGE: float = 20.0
const FIRE_DAMAGE: int = 5
const FIRE_INTERVAL: float = 0.95
const MELEE_DAMAGE: int = 8

var mesh_root: Node3D
var anim_player: AnimationPlayer
var anim_tree: AnimationTree
var _playback: AnimationNodeStateMachinePlayback
var _hit_timer: float = 0.0
var _fire_cooldown: float = 0.0
var _melee_cooldown: float = 0.0


func setup(p_target: Node3D, p_wanted: Node) -> void :
    target = p_target
    wanted_system = p_wanted


func _ready() -> void :
    collision_layer = 4
    collision_mask = 1

    var col: = CollisionShape3D.new()
    var capsule: = CapsuleShape3D.new()
    capsule.height = 1.7
    capsule.radius = 0.32
    col.shape = capsule
    col.position.y = 0.85
    add_child(col)

    mesh_root = Node3D.new()
    mesh_root.name = "CharacterMesh"
    add_child(mesh_root)

    var scene: = load(MODEL) as PackedScene
    if scene:
        var model: = scene.instantiate()
        mesh_root.add_child(model)
        ModelUtils.setup_character_for_movement(model, 1.72)
        _tint_enforcer(model)
        anim_player = AnimationPlayer.new()
        anim_player.name = "AnimationPlayer"
        model.add_child(anim_player)
        var lib: = load(ANIMS) as AnimationLibrary
        if lib:
            anim_player.add_animation_library("", lib)
            ModelUtils.set_animation_loops(anim_player)
            _setup_anim_tree()
        var clamp: = GroundClampNode.new()
        clamp.target_node = self
        clamp.character_mesh = mesh_root
        add_child(clamp)


func _tint_enforcer(root: Node) -> void :
    for mi in root.find_children("*", "MeshInstance3D", true):
        if mi is MeshInstance3D and mi.mesh:
            var mat: = StandardMaterial3D.new()
            mat.albedo_color = Color(0.18, 0.12, 0.14)
            mat.emission_enabled = true
            mat.emission = Color(0.55, 0.12, 0.1)
            mat.emission_energy_multiplier = 0.15
            mi.material_override = mat


func _setup_anim_tree() -> void :
    var sm: = AnimationNodeStateMachine.new()
    for state in [["idle", "ual1_Idle"], ["run", "ual1_Walk"]]:
        var node: = AnimationNodeAnimation.new()
        node.animation = state[1]
        sm.add_node(state[0], node)
    for pair in [["idle", "run"], ["run", "idle"]]:
        var t: = AnimationNodeStateMachineTransition.new()
        t.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_IMMEDIATE
        t.xfade_time = 0.15
        sm.add_transition(pair[0], pair[1], t)
    anim_tree = AnimationTree.new()
    anim_tree.anim_player = anim_player.get_path()
    anim_tree.tree_root = sm
    add_child(anim_tree)
    anim_tree.active = true
    _playback = anim_tree["parameters/playback"]


func take_damage(amount: int) -> void :
    if dead:
        return
    health -= amount
    _hit_timer = 0.35
    if health <= 0:
        _die()


func _die() -> void :
    dead = true
    collision_layer = 0
    if wanted_system and wanted_system.has_method("add_heat"):
        wanted_system.add_heat(1)
    var tw: = create_tween()
    tw.tween_interval(2.0)
    tw.tween_callback(queue_free)


func _shoot_at_player() -> void :
    if target == null or not is_instance_valid(target):
        return
    _fire_cooldown = FIRE_INTERVAL
    var muzzle: Vector3 = global_position + Vector3(0, 1.35, 0)
    var aim: Vector3 = (target.global_position + Vector3(0, 1.1, 0)) - muzzle
    var dir: = aim.normalized()
    if AudioManager:
        var snd: = load("res://assets/audio/sfx/weapon/weapon_pistol_shot.mp3")
        if snd:
            AudioManager.play_sfx(snd, -10.0, 0.1)
    if VFX:
        VFX.spawn_muzzle(muzzle + dir * 0.35, dir, 0.25)
    if target.has_method("take_damage"):
        target.take_damage(FIRE_DAMAGE)


func _physics_process(delta: float) -> void :
    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = 0.0

    if dead:
        move_and_slide()
        return

    _hit_timer = max(0.0, _hit_timer - delta)
    _fire_cooldown = max(0.0, _fire_cooldown - delta)
    _melee_cooldown = max(0.0, _melee_cooldown - delta)

    var moving: = false
    if target and is_instance_valid(target):
        var to_t: = target.global_position - global_position
        to_t.y = 0.0
        var dist: = to_t.length()
        if dist > 1.8:
            var dir: = to_t.normalized()
            velocity.x = dir.x * run_speed
            velocity.z = dir.z * run_speed
            mesh_root.rotation.y = lerp_angle(mesh_root.rotation.y, atan2( - dir.x, - dir.z), 10.0 * delta)
            moving = true
            if dist <= FIRE_RANGE and _fire_cooldown <= 0.0:
                _shoot_at_player()
        else:
            velocity = Vector3.ZERO
            if _melee_cooldown <= 0.0 and target.has_method("take_damage"):
                _melee_cooldown = 1.1
                target.take_damage(MELEE_DAMAGE)
    move_and_slide()

    if _playback and _hit_timer <= 0.0:
        _playback.travel("run" if moving else "idle")
