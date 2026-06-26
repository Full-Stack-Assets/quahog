extends CharacterBody3D


@export var walk_speed: float = 1.5
@export var gravity: float = 20.0

var model_path: String = ""
var lib_path: String = ""
var waypoints: PackedVector3Array = PackedVector3Array()

var mesh_root: Node3D
var anim_player: AnimationPlayer
var anim_tree: AnimationTree
var _playback: AnimationNodeStateMachinePlayback

var _target: Vector3 = Vector3.ZERO
var _idle_timer: float = 0.0
var _has_target: bool = false


func setup(p_model: String, p_lib: String, p_waypoints: PackedVector3Array) -> void :
    model_path = p_model
    lib_path = p_lib
    waypoints = p_waypoints


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

    if model_path != "":
        var scene: = load(model_path) as PackedScene
        if scene:
            var model: = scene.instantiate()
            mesh_root.add_child(model)
            ModelUtils.setup_character_for_movement(model, 1.72)
            var meshes: Array = model.find_children("*", "MeshInstance3D", true)
            if meshes.size() > 0:
                var first: = meshes[0] as MeshInstance3D
                if first and not ModelUtils.has_vertex_normals(first):
                    ModelUtils.generate_normals_for_all(model)
            anim_player = AnimationPlayer.new()
            anim_player.name = "AnimationPlayer"
            model.add_child(anim_player)
            var lib: = load(lib_path) as AnimationLibrary
            if lib:
                anim_player.add_animation_library("", lib)
                ModelUtils.set_animation_loops(anim_player)
                _setup_anim_tree()
            var clamp: = GroundClampNode.new()
            clamp.target_node = self
            clamp.character_mesh = mesh_root
            add_child(clamp)

    _idle_timer = randf_range(0.5, 2.0)
    _pick_target()


func _setup_anim_tree() -> void :
    var sm: = AnimationNodeStateMachine.new()
    for state in [["idle", "ual1_Idle"], ["walk", "ual1_Walk"]]:
        var node: = AnimationNodeAnimation.new()
        node.animation = state[1]
        sm.add_node(state[0], node)
    for pair in [["idle", "walk"], ["walk", "idle"]]:
        var t: = AnimationNodeStateMachineTransition.new()
        t.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_IMMEDIATE
        t.xfade_time = 0.2
        sm.add_transition(pair[0], pair[1], t)
    anim_tree = AnimationTree.new()
    anim_tree.anim_player = anim_player.get_path()
    anim_tree.tree_root = sm
    add_child(anim_tree)
    anim_tree.active = true
    _playback = anim_tree["parameters/playback"]


func _pick_target() -> void :
    if waypoints.size() == 0:
        _has_target = false
        return
    _target = waypoints[randi() % waypoints.size()]
    _has_target = true


func _physics_process(delta: float) -> void :
    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = 0.0

    var moving: = false
    if _idle_timer > 0.0:
        _idle_timer -= delta
        velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
    elif _has_target:
        var to_target: = _target - global_position
        to_target.y = 0.0
        if to_target.length() < 1.0:
            _idle_timer = randf_range(1.5, 4.0)
            _pick_target()
        else:
            var dir: = to_target.normalized()
            velocity.x = dir.x * walk_speed
            velocity.z = dir.z * walk_speed
            mesh_root.rotation.y = lerp_angle(mesh_root.rotation.y, atan2( - dir.x, - dir.z), 8.0 * delta)
            moving = true
    else:
        _pick_target()

    move_and_slide()

    if _playback:
        _playback.travel("walk" if moving and velocity.length() > 0.3 else "idle")
