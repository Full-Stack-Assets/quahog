class_name GroundClampNode
extends Node




@export var target_node: Node3D
@export var character_mesh: Node3D
@export var enabled: bool = true

@export var smooth_hz: float = 12.0
@export var deadzone: float = 0.003

const GROUND_REF_BONES: Array[String] = [
    "LeftFoot", "RightFoot", "LeftToes", "RightToes", 
    "Hips", "Chest", "LeftHand", "RightHand", "Head", 
]

var _skeleton: Skeleton3D = null
var _ref_bone_indices: Array[int] = []
var _mesh_baseline_y: float = 0.0
var _smoothed_shift: float = 0.0
var _last_mesh: Node3D = null


func _refresh_refs() -> void :
    _ref_bone_indices.clear()
    _skeleton = null
    _smoothed_shift = 0.0
    if character_mesh == null:
        return
    _mesh_baseline_y = character_mesh.position.y
    _last_mesh = character_mesh
    var skels: = character_mesh.find_children("*", "Skeleton3D", true, false)
    if skels.is_empty():
        return
    _skeleton = skels[0] as Skeleton3D
    for n in GROUND_REF_BONES:
        var idx: = _skeleton.find_bone(n)
        if idx >= 0:
            _ref_bone_indices.append(idx)


func _ready() -> void :
    _refresh_refs()


func _process(delta: float) -> void :
    if not enabled or character_mesh == null or target_node == null:
        return
    if character_mesh != _last_mesh or not is_instance_valid(_skeleton):
        _refresh_refs()
    if _skeleton == null or _ref_bone_indices.is_empty():
        return

    character_mesh.position.y = _mesh_baseline_y

    var sk_xform: = _skeleton.global_transform
    var min_y: float = INF
    for idx in _ref_bone_indices:
        var bone_world: Transform3D = sk_xform * _skeleton.get_bone_global_pose(idx)
        if bone_world.origin.y < min_y:
            min_y = bone_world.origin.y
    if min_y == INF:
        character_mesh.position.y = _mesh_baseline_y + _smoothed_shift
        return

    var target_shift: = target_node.global_position.y - min_y

    var shift_to_track: = _smoothed_shift
    if absf(target_shift - _smoothed_shift) > deadzone:
        shift_to_track = target_shift

    var t: = clampf(smooth_hz * delta, 0.0, 1.0)
    _smoothed_shift = lerpf(_smoothed_shift, shift_to_track, t)

    character_mesh.position.y = _mesh_baseline_y + _smoothed_shift
