extends Node

# Busted / Wasted blackout loop (web Consequence.tsx parity).

const DELAY: float = 2.6
const HOSPITAL: = Vector3(-264.0, 0.0, -106.0)
const POLICE_STATION: = Vector3(-513.0, 0.0, -147.0)

var _active: bool = false
var _kind: String = ""
var _timer: float = 0.0
var _layer: CanvasLayer
var _shade: ColorRect
var _title: Label


func _ready() -> void :
    _build_overlay()


func is_active() -> bool:
    return _active


func start(kind: String) -> void :
    if _active:
        return
    _active = true
    _kind = kind
    _timer = 0.0
    _layer.visible = true
    _shade.color = Color(0.0, 0.0, 0.0, 0.0)
    _title.text = "WASTED" if kind == "wasted" else "BUSTED"
    _title.modulate.a = 0.0
    if kind == "busted" and AudioManager:
        var snd: = load("res://assets/audio/sfx/ui/ui_busted.mp3")
        if snd:
            AudioManager.play_sfx(snd, -2.0)
    var tw: = create_tween()
    tw.tween_property(_shade, "color", Color(0.02, 0.02, 0.04, 0.92), 0.45)
    tw.parallel().tween_property(_title, "modulate:a", 1.0, 0.55)


func _process(delta: float) -> void :
    if not _active:
        return
    _timer += delta
    if _timer >= DELAY:
        _finish()


func _finish() -> void :
    _active = false
    _layer.visible = false
    var penalty: int = 200 if _kind == "wasted" else 150
    if GameManager:
        var lost: int = mini(GameManager.cash, penalty)
        if lost > 0:
            GameManager.add_cash( - lost)
        GameManager.set_wanted(0)
        GameManager.set_faction(0)
        var where: String = "the hospital" if _kind == "wasted" else "downtown booking"
        GameManager.show_message("%s — −$%d, released from %s." % [_title.text, lost, where])

    var spot: Vector3 = HOSPITAL if _kind == "wasted" else POLICE_STATION
    var world: = get_tree().get_first_node_in_group("game_world")
    if world:
        if world.has_method("get_wanted_system"):
            var ws: Variant = world.get_wanted_system()
            if ws and ws.has_method("clear_pursuit"):
                ws.clear_pursuit()
        var player: Variant = world.get("_player")
        if player and is_instance_valid(player):
            if "_driving" in player and player._driving and player.has_method("exit_car"):
                player.exit_car()
            if player.has_method("heal_full"):
                player.heal_full()
            elif "health" in player and "max_health" in player:
                player.health = player.max_health
            player.global_position = spot + Vector3(0.0, 1.2, 0.0)
            player.velocity = Vector3.ZERO
            if "dead" in player:
                player.dead = false


func _build_overlay() -> void :
    _layer = CanvasLayer.new()
    _layer.layer = 90
    _layer.visible = false
    add_child(_layer)

    _shade = ColorRect.new()
    _shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _layer.add_child(_shade)

    _title = Label.new()
    _title.text = "BUSTED"
    _title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var font: Font = load("res://assets/fonts/noto_serif.ttf")
    if font:
        _title.add_theme_font_override("font", font)
    _title.add_theme_font_size_override("font_size", 120)
    _title.add_theme_color_override("font_color", Color(0.95, 0.22, 0.18))
    _title.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
    _title.add_theme_constant_override("outline_size", 12)
    _layer.add_child(_title)
