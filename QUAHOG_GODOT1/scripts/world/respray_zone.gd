extends Node3D

# Pay-n-Spray: drive in with heat, pay $200, wanted level clears.

const FEE: int = 200
const RADIUS: float = 6.0
const COOLDOWN: float = 6.0

var _cooldown: float = 0.0
var _ring: MeshInstance3D


func _ready() -> void :
    var ring: = MeshInstance3D.new()
    var torus: = TorusMesh.new()
    torus.inner_radius = RADIUS - 0.8
    torus.outer_radius = RADIUS
    ring.mesh = torus
    ring.rotation.x = PI / 2.0
    ring.position.y = 0.18
    var mat: = StandardMaterial3D.new()
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.albedo_color = Color(0.35, 0.82, 1.0, 0.45)
    ring.material_override = mat
    add_child(ring)
    _ring = ring

    var lbl: = Label3D.new()
    lbl.text = "PAY-N-SPRAY"
    lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    lbl.modulate = Color(0.74, 0.91, 1.0)
    lbl.font_size = 48
    lbl.pixel_size = 0.028
    lbl.position = Vector3(0, 4.5, 0)
    add_child(lbl)


func _physics_process(delta: float) -> void :
    _cooldown = max(0.0, _cooldown - delta)
    if _cooldown > 0.0:
        return
    var world: = get_tree().get_first_node_in_group("game_world")
    if world == null:
        return
    var player: Variant = world.get("_player")
    if player == null or not is_instance_valid(player):
        return
    if not ("_driving" in player and player._driving):
        return
    if player.current_car == null or not is_instance_valid(player.current_car):
        return
    var cp: Vector3 = player.current_car.vehicle_model.global_position if "vehicle_model" in player.current_car else player.global_position
    if Vector2(cp.x - global_position.x, cp.z - global_position.z).length() > RADIUS:
        return
    if GameManager.wanted_level <= 0 and GameManager.faction_level <= 0:
        return
    if not GameManager.spend_cash(FEE):
        GameManager.show_message("Can't afford a respray ($%d)." % FEE)
        _cooldown = 4.0
        return
    GameManager.set_wanted(0)
    GameManager.set_faction(0)
    if AudioManager:
        var snd: = load("res://assets/audio/sfx/ui/ui_shop_buy.mp3")
        if snd:
            AudioManager.play_sfx(snd, -4.0)
    GameManager.show_message("Resprayed — heat cleared (−$%d)." % FEE)
    _cooldown = COOLDOWN
