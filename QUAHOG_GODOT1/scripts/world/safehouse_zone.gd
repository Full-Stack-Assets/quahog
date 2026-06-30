extends Node3D

# Maplecroft safehouse: bleed off police + faction heat on foot, autosave, sleep (T).

const RADIUS: float = 9.0
const SLEEP_PHASE: float = 0.52  # ~07:00 on the world clock

var _save_timer: float = 0.0
var _inside: bool = false
var _hinted: bool = false


func _ready() -> void :
    _build_visuals()


func _build_visuals() -> void :
    var house: = MeshInstance3D.new()
    var box: = BoxMesh.new()
    box.size = Vector3(8.0, 4.0, 8.0)
    house.mesh = box
    house.position = Vector3(0.0, 2.0, 0.0)
    var wall: = StandardMaterial3D.new()
    wall.albedo_color = Color(0.28, 0.34, 0.48)
    wall.roughness = 0.88
    house.material_override = wall
    add_child(house)

    var roof: = MeshInstance3D.new()
    var cone: = BoxMesh.new()
    cone.size = Vector3(9.0, 2.2, 9.0)
    roof.mesh = cone
    roof.position = Vector3(0.0, 5.1, 0.0)
    var roof_mat: = StandardMaterial3D.new()
    roof_mat.albedo_color = Color(0.42, 0.28, 0.22)
    roof.material_override = roof_mat
    add_child(roof)

    var ring: = MeshInstance3D.new()
    var torus: = TorusMesh.new()
    torus.inner_radius = RADIUS - 0.7
    torus.outer_radius = RADIUS
    ring.mesh = torus
    ring.rotation.x = PI / 2.0
    ring.position.y = 0.15
    var mat: = StandardMaterial3D.new()
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.albedo_color = Color(0.35, 0.92, 0.55, 0.42)
    ring.material_override = mat
    add_child(ring)

    var lbl: = Label3D.new()
    lbl.text = "SAFEHOUSE"
    lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    lbl.modulate = Color(0.72, 0.98, 0.78)
    lbl.font_size = 44
    lbl.pixel_size = 0.026
    lbl.position = Vector3(0.0, 7.0, 0.0)
    add_child(lbl)


func _physics_process(delta: float) -> void :
    var world: = get_tree().get_first_node_in_group("game_world")
    if world == null:
        return
    var player: Variant = world.get("_player")
    if player == null or not is_instance_valid(player):
        return
    if "_driving" in player and player._driving:
        _inside = false
        _hinted = false
        return

    var pp: Vector3 = player.global_position
    var here: bool = Vector2(pp.x - global_position.x, pp.z - global_position.z).length() <= RADIUS
    if here and not _inside:
        GameManager.show_message("Safehouse — press T to sleep til morning.")
        _hinted = true
    _inside = here

    if not here:
        return

    if GameManager.wanted_level > 0:
        if randf() < delta * 0.35:
            GameManager.set_wanted(GameManager.wanted_level - 1)
    if GameManager.faction_level > 0:
        if randf() < delta * 0.35:
            GameManager.set_faction(GameManager.faction_level - 1)

    _save_timer += delta
    if _save_timer >= 3.0:
        _save_timer = 0.0
        GameManager.save_game()

    if Input.is_action_just_pressed("sleep"):
        _sleep(player)


func _sleep(player: Node) -> void :
    GameManager.set_wanted(0)
    GameManager.set_faction(0)
    GameManager.day_phase = SLEEP_PHASE
    GameManager.save_game()
    if player.has_method("heal_full"):
        player.heal_full()
    elif "health" in player and "max_health" in player:
        player.health = player.max_health
    GameManager.show_message("Slept til morning — heat cleared, game saved.")
    if AudioManager:
        var snd: = load("res://assets/audio/sfx/ui/ui_shop_buy.mp3")
        if snd:
            AudioManager.play_sfx(snd, -8.0)
