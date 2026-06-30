extends Node3D

# Hidden scrimshaw artifact — walk into the glow to collect (+$120).

const REWARD: int = 120
const RADIUS: float = 3.0

var index: int = 0
var player: Node3D = null

var _mesh: MeshInstance3D
var _spin: float = 0.0


func setup(p_index: int, pos: Vector3, p_player: Node3D) -> void :
    index = p_index
    player = p_player
    global_position = pos


func _ready() -> void :
    if GameManager and GameManager.is_scrimshaw_collected(index):
        queue_free()
        return
    _build_visual()


func _build_visual() -> void :
    var mesh: = MeshInstance3D.new()
    var oct: = SphereMesh.new()
    oct.radius = 0.45
    oct.height = 0.9
    mesh.mesh = oct
    var mat: = StandardMaterial3D.new()
    mat.albedo_color = Color(0.95, 0.92, 0.82)
    mat.emission_enabled = true
    mat.emission = Color(0.79, 0.64, 0.29)
    mat.emission_energy_multiplier = 1.4
    mat.roughness = 0.4
    mat.metallic = 0.3
    mesh.material_override = mat
    mesh.position.y = 1.2
    add_child(mesh)
    _mesh = mesh

    var light: = OmniLight3D.new()
    light.light_color = Color(1.0, 0.85, 0.45)
    light.light_energy = 1.2
    light.omni_range = 6.0
    light.position.y = 1.2
    add_child(light)


func _process(delta: float) -> void :
    if _mesh == null or player == null or not is_instance_valid(player):
        return
    _spin += delta * 2.0
    _mesh.rotation.y = _spin
    _mesh.position.y = 1.2 + sin(_spin * 1.4) * 0.15
    if player.global_position.distance_to(global_position) > RADIUS:
        return
    if GameManager == null or not GameManager.collect_scrimshaw(index):
        return
    GameManager.add_cash(REWARD)
    GameManager.save_game()
    if AudioManager:
        var snd: = load("res://assets/audio/sfx/pickup/pickup_cash_reward.mp3")
        if snd:
            AudioManager.play_sfx(snd, -2.0)
    var n: int = GameManager.scrimshaw_found()
    var total: int = GameManager.SCRIMSHAW_TOTAL
    GameManager.show_message("Scrimshaw %d/%d — +$%d" % [n, total, REWARD])
    queue_free()
