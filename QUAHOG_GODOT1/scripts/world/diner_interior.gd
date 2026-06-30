extends Node3D
class_name DinerInterior

# Linguiça Linq — enterable diner (interior menu overlay).

@export var interact_prompt: String = "Enter Linguiça Linq"


func setup(pos: Vector3) -> void :
    global_position = pos


func _ready() -> void :
    var area: = Area3D.new()
    area.collision_layer = 32
    area.collision_mask = 0
    var acol: = CollisionShape3D.new()
    var ashape: = SphereShape3D.new()
    ashape.radius = 3.2
    acol.shape = ashape
    acol.position.y = 1.0
    area.add_child(acol)
    add_child(area)

    var body: = StaticBody3D.new()
    body.collision_layer = 1
    var col: = CollisionShape3D.new()
    var box: = BoxShape3D.new()
    box.size = Vector3(8.0, 3.2, 6.0)
    col.shape = box
    col.position.y = 1.6
    body.add_child(col)
    add_child(body)

    var facade: = MeshInstance3D.new()
    var bm: = BoxMesh.new()
    bm.size = Vector3(8.0, 3.2, 6.0)
    facade.mesh = bm
    var fm: = StandardMaterial3D.new()
    fm.albedo_color = Color(0.22, 0.18, 0.16)
    fm.roughness = 0.88
    facade.material_override = fm
    facade.position.y = 1.6
    add_child(facade)


func interact(_player: Node) -> void :
    if GameManager:
        GameManager.open_diner_requested.emit()
