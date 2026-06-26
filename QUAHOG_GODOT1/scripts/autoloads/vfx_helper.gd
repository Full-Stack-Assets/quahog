extends Node


# Scene paths are loaded at runtime (not preloaded) so the project still
# compiles and runs when the optional VFX assets aren't present in the repo,
# matching how the rest of the codebase loads models/audio/scenes.

const MUZZLE_PATH: = "res://assets/3d_vfx/muzzle_flash/effects/muzzle_flash/muzzle_flash_03.tscn"
const IMPACT_PATH: = "res://assets/3d_vfx/impact_explosions/effects/impact/vfx_impact_02.tscn"

var _muzzle_scene: PackedScene
var _impact_scene: PackedScene


func _ready() -> void :
    if ResourceLoader.exists(MUZZLE_PATH):
        _muzzle_scene = load(MUZZLE_PATH) as PackedScene
    if ResourceLoader.exists(IMPACT_PATH):
        _impact_scene = load(IMPACT_PATH) as PackedScene


func spawn_muzzle(at: Vector3, dir: Vector3, scale_mul: float = 0.5) -> void :
    var inst: = _spawn(_muzzle_scene, at)
    if inst == null:
        return
    inst.scale = Vector3.ONE * scale_mul
    _orient(inst, dir)


func spawn_impact(at: Vector3, scale_mul: float = 0.5) -> void :
    var inst: = _spawn(_impact_scene, at)
    if inst == null:
        return
    inst.scale = Vector3.ONE * scale_mul


func _spawn(scene: PackedScene, at: Vector3) -> Node3D:
    if scene == null:
        return null
    var inst: = scene.instantiate() as Node3D
    if inst == null:
        return null
    if "autoplay" in inst:
        inst.set("autoplay", false)
    if "proximity_fade" in inst:
        inst.set("proximity_fade", false)
    add_child(inst)
    inst.global_position = at
    var anim: = inst.get_node_or_null("AnimationPlayer") as AnimationPlayer
    if anim:
        var clip: = "oneshot" if anim.has_animation("oneshot") else "main"
        if not anim.has_animation(clip):
            var names: = anim.get_animation_list()
            if names.size() > 0:
                clip = names[0]
        anim.animation_finished.connect( func(_n): if is_instance_valid(inst): inst.queue_free(), CONNECT_ONE_SHOT)
        anim.play(clip)
    _restart_particles(inst)

    get_tree().create_timer(3.0).timeout.connect( func(): if is_instance_valid(inst): inst.queue_free())
    return inst


func _orient(inst: Node3D, direction: Vector3) -> void :
    var d: = direction
    d.y = 0.0
    if d.length_squared() < 0.0001:
        return
    d = d.normalized()
    inst.look_at(inst.global_position + d, Vector3.UP)
    inst.rotate_object_local(Vector3.UP, PI * 0.5)


func _restart_particles(root: Node) -> void :
    await get_tree().process_frame
    if not is_instance_valid(root):
        return
    for p in _collect(root):
        if is_instance_valid(p):
            p.restart()


func _collect(n: Node) -> Array:
    var out: Array = []
    if n is GPUParticles3D or n is CPUParticles3D:
        out.append(n)
    for c in n.get_children():
        out.append_array(_collect(c))
    return out
