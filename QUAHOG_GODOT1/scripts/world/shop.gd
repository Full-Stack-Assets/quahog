extends Node3D
class_name Shop




@export var interact_prompt: String = "Shop (weapons & ammo)"

var shop_kind: String = "gun"
var _marker: MeshInstance3D = null


func setup(pos: Vector3, kind: String = "gun") -> void :
    global_position = pos
    shop_kind = kind


func _ready() -> void :

    var area: = Area3D.new()
    area.collision_layer = 32
    area.collision_mask = 0
    var acol: = CollisionShape3D.new()
    var ashape: = SphereShape3D.new()
    ashape.radius = 3.0
    acol.shape = ashape
    acol.position.y = 1.0
    area.add_child(acol)
    add_child(area)


    var kiosk: = MeshInstance3D.new()
    var box: = BoxMesh.new()
    box.size = Vector3(1.6, 2.2, 1.0)
    kiosk.mesh = box
    var kmat: = StandardMaterial3D.new()
    kmat.albedo_color = Color(0.16, 0.13, 0.1)
    kmat.metallic = 0.2
    kmat.roughness = 0.7
    kiosk.set_surface_override_material(0, kmat)
    kiosk.position.y = 1.1
    add_child(kiosk)

    var body: = StaticBody3D.new()
    body.collision_layer = 1
    body.collision_mask = 0
    var bcol: = CollisionShape3D.new()
    var bshape: = BoxShape3D.new()
    bshape.size = Vector3(1.6, 2.2, 1.0)
    bcol.shape = bshape
    bcol.position.y = 1.1
    body.add_child(bcol)
    add_child(body)


    var sign_panel: = MeshInstance3D.new()
    var quad: = QuadMesh.new()
    quad.size = Vector2(1.5, 0.5)
    sign_panel.mesh = quad
    var smat: = StandardMaterial3D.new()
    smat.albedo_color = Color(0.95, 0.2, 0.15)
    smat.emission_enabled = true
    smat.emission = Color(1.0, 0.25, 0.18)
    smat.emission_energy_multiplier = 2.6
    smat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
    sign_panel.material_override = smat
    sign_panel.position.y = 2.7
    add_child(sign_panel)

    var glow: = OmniLight3D.new()
    glow.light_color = Color(1.0, 0.4, 0.3)
    glow.light_energy = 3.0
    glow.omni_range = 8.0
    glow.shadow_enabled = false
    glow.position.y = 2.4
    add_child(glow)


    _marker = MeshInstance3D.new()
    var prism: = PrismMesh.new()
    prism.size = Vector3(0.5, 0.7, 0.5)
    _marker.mesh = prism
    var mat: = StandardMaterial3D.new()
    mat.albedo_color = Color(0.4, 0.95, 0.5)
    mat.emission_enabled = true
    mat.emission = Color(0.45, 1.0, 0.55)
    mat.emission_energy_multiplier = 2.4
    _marker.material_override = mat
    _marker.position = Vector3(0, 3.6, 0)
    add_child(_marker)


func _process(delta: float) -> void :
    if _marker:
        _marker.rotation.y += delta * 1.6


func interact(_player: Node) -> void :
    if GameManager:
        GameManager.open_shop_requested.emit(shop_kind)
