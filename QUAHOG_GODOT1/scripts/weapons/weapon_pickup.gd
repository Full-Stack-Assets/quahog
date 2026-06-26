extends Node3D
class_name WeaponPickup







var kind: String = "weapon"
var weapon_id: String = "pistol"
var amount: int = 0
var target: Node3D = null

var _done: bool = false
var _model: Node3D = null
var _halo: OmniLight3D = null
var _respawn_timer: float = 0.0
var _base_y: float = 1.1


func setup(pos: Vector3, p_target: Node3D, p_kind: String = "weapon", p_weapon_id: String = "pistol", p_amount: int = 0) -> void :
    global_position = pos
    target = p_target
    kind = p_kind
    weapon_id = p_weapon_id
    amount = p_amount


func _ready() -> void :
    _build_visual()


func _build_visual() -> void :
    var model_path: = ""
    var halo_color: = Color(0.5, 0.8, 1.0)
    match kind:
        "weapon", "ammo":
            model_path = WeaponDB.get_def(weapon_id).get("model", "")
            halo_color = Color(1.0, 0.85, 0.35) if kind == "weapon" else Color(0.9, 0.7, 0.3)
        "medkit":
            model_path = "res://assets/props/items/medkit.glb"
            halo_color = Color(0.4, 1.0, 0.5)
        "armor":
            model_path = "res://assets/props/items/armor_vest.glb"
            halo_color = Color(0.4, 0.7, 1.0)

    if model_path != "" and ResourceLoader.exists(model_path):
        var scene: = load(model_path) as PackedScene
        if scene:
            _model = scene.instantiate() as Node3D
            add_child(_model)
            var h: float = 0.6 if (kind == "weapon" or kind == "ammo") else 0.7
            ModelUtils.scale_to_height(_model, h)
            _model.position.y = _base_y
    if _model == null:

        var mi: = MeshInstance3D.new()
        var box: = BoxMesh.new()
        box.size = Vector3(0.5, 0.5, 0.5)
        mi.mesh = box
        var mat: = StandardMaterial3D.new()
        mat.albedo_color = halo_color
        mat.emission_enabled = true
        mat.emission = halo_color
        mat.emission_energy_multiplier = 1.5
        mi.set_surface_override_material(0, mat)
        mi.position.y = _base_y
        add_child(mi)
        _model = mi

    _halo = OmniLight3D.new()
    _halo.light_color = halo_color
    _halo.light_energy = 2.0
    _halo.omni_range = 5.0
    _halo.shadow_enabled = false
    _halo.position.y = _base_y
    add_child(_halo)


func _set_visible(v: bool) -> void :
    if _model and is_instance_valid(_model):
        _model.visible = v
    if _halo and is_instance_valid(_halo):
        _halo.visible = v


func _process(delta: float) -> void :
    if _model and is_instance_valid(_model) and _model.visible:
        _model.rotation.y += delta * 1.8
        _model.position.y = _base_y + sin(float(Time.get_ticks_msec()) * 0.003) * 0.12

    if _done:
        _respawn_timer -= delta
        if _respawn_timer <= 0.0:
            _done = false
            _set_visible(true)
        return

    if target == null or not is_instance_valid(target):
        return
    var to: = target.global_position - global_position
    to.y = 0.0
    if to.length() < 2.2:
        _try_collect()


func _try_collect() -> void :
    var collected: = false
    var sfx: = "res://assets/audio/sfx/pickup/pickup_cash_reward.mp3"
    match kind:
        "weapon":
            if target.has_method("give_weapon"):
                var starter: int = amount if amount > 0 else int(WeaponDB.get_def(weapon_id).get("ammo_buy", 30))
                target.give_weapon(weapon_id, starter)
                collected = true
        "ammo":
            if target.has_method("add_ammo"):
                var a: int = amount if amount > 0 else int(WeaponDB.get_def(weapon_id).get("ammo_buy", 30))
                collected = target.add_ammo(weapon_id, a)
                if not collected and GameManager:
                    GameManager.show_message("You don't own that weapon yet.")
        "medkit":
            if target.has_method("heal") and "health" in target and "max_health" in target:
                if target.health < target.max_health:
                    target.heal(amount if amount > 0 else 50)
                    sfx = "res://assets/audio/sfx/pickup/pickup_heal_use.mp3"
                    collected = true
        "armor":
            if target.has_method("add_armor") and "armor" in target:
                if target.armor < 100:
                    target.add_armor(amount if amount > 0 else 50)
                    sfx = "res://assets/audio/sfx/pickup/pickup_armor_equip.mp3"
                    collected = true

    if not collected:
        return
    if AudioManager:
        var snd: = load(sfx)
        if snd:
            AudioManager.play_sfx(snd, -8.0)
    _done = true
    _respawn_timer = 25.0
    _set_visible(false)
