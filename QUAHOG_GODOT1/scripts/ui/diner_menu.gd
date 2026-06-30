extends CanvasLayer
class_name DinerMenu

var _player: Node = null
var _root: Control
var _panel: PanelContainer
var _cash_label: Label
var _font: Font
var _open: bool = false


func _ready() -> void :
    layer = 13
    process_mode = Node.PROCESS_MODE_ALWAYS
    _font = load("res://assets/fonts/noto_serif.ttf")

    _root = Control.new()
    _root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var theme: = load("res://assets/ui/theme.tres") as Theme
    if theme:
        _root.theme = theme
    add_child(_root)
    _root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var dim: = ColorRect.new()
    dim.color = Color(0.05, 0.04, 0.08, 0.88)
    dim.mouse_filter = Control.MOUSE_FILTER_STOP
    _root.add_child(dim)
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var center: = CenterContainer.new()
    _root.add_child(center)
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    _panel = PanelContainer.new()
    _panel.theme_type_variation = "DialogPanel"
    _panel.custom_minimum_size = Vector2(720, 560)
    center.add_child(_panel)

    var margin: = MarginContainer.new()
    for m in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
        margin.add_theme_constant_override(m, 28)
    _panel.add_child(margin)

    var vbox: = VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 12)
    margin.add_child(vbox)

    var header: = HBoxContainer.new()
    vbox.add_child(header)
    var title: = Label.new()
    title.text = "LINGUIÇA LINQ"
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _apply_font(title, 44, Color(1.0, 0.45, 0.72))
    header.add_child(title)
    _cash_label = Label.new()
    _apply_font(_cash_label, 30, Color(0.6, 0.95, 0.55))
    header.add_child(_cash_label)

    var sub: = Label.new()
    sub.text = "All-night diner. Neon booths, chouriço on the grill, harbor fog on the glass."
    sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _apply_font(sub, 22, Color(0.82, 0.78, 0.74))
    vbox.add_child(sub)

    _add_buy(vbox, "Coffee", 10, "Wakes you up.", _buy_coffee)
    _add_buy(vbox, "Chowder", 25, "+40 health", _buy_chowder)
    _add_buy(vbox, "Linguiça Plate", 40, "Full health", _buy_plate)

    var close: = Button.new()
    close.text = "Back to the street"
    close.custom_minimum_size = Vector2(280, 64)
    close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    _apply_font(close, 28, Color(0.98, 0.96, 0.92))
    close.pressed.connect(close_diner)
    vbox.add_child(close)

    _root.visible = false

    if GameManager:
        GameManager.open_diner_requested.connect(_on_open)
        GameManager.cash_changed.connect(_update_cash)


func bind_player(player: Node) -> void :
    _player = player


func _on_open() -> void :
    open_diner()


func open_diner() -> void :
    if _open:
        return
    _open = true
    _root.visible = true
    get_tree().paused = true
    _update_cash(GameManager.cash if GameManager else 0)


func close_diner() -> void :
    if not _open:
        return
    _open = false
    _root.visible = false
    get_tree().paused = false


func _update_cash(value: int) -> void :
    if _cash_label:
        _cash_label.text = "$" + str(value)


func _add_buy(parent: VBoxContainer, name: String, price: int, blurb: String, cb: Callable) -> void :
    var row: = HBoxContainer.new()
    row.add_theme_constant_override("separation", 12)
    parent.add_child(row)
    var info: = VBoxContainer.new()
    info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(info)
    var nl: = Label.new()
    nl.text = "%s  —  $%d" % [name, price]
    _apply_font(nl, 26, Color(0.95, 0.9, 0.85))
    info.add_child(nl)
    var bl: = Label.new()
    bl.text = blurb
    _apply_font(bl, 20, Color(0.72, 0.7, 0.66))
    info.add_child(bl)
    var buy: = Button.new()
    buy.text = "Order"
    buy.custom_minimum_size = Vector2(120, 52)
    _apply_font(buy, 24, Color(0.98, 0.96, 0.92))
    buy.disabled = not (GameManager and GameManager.can_afford(price))
    buy.pressed.connect(func() -> void : cb.call(price))
    row.add_child(buy)


func _pay(price: int) -> bool:
    if GameManager and GameManager.spend_cash(price):
        if AudioManager:
            var snd: = load("res://assets/audio/sfx/ui/ui_shop_buy.mp3")
            if snd:
                AudioManager.play_sfx(snd, -5.0)
        _update_cash(GameManager.cash)
        return true
    if AudioManager:
        var deny: = load("res://assets/audio/sfx/ui/ui_shop_denied.mp3")
        if deny:
            AudioManager.play_sfx(deny, -6.0)
    return false


func _buy_coffee(price: int) -> void :
    if not _pay(price):
        return
    GameManager.show_message("Coffee's hot. You're good to go.")


func _buy_chowder(price: int) -> void :
    if _player == null or not _player.has_method("heal"):
        return
    if not _pay(price):
        return
    _player.heal(40)


func _buy_plate(price: int) -> void :
    if _player == null or not _player.has_method("heal"):
        return
    if not _pay(price):
        return
    _player.heal(9999)


func _apply_font(ctrl: Control, fsize: int, color: Color) -> void :
    if _font:
        ctrl.add_theme_font_override("font", _font)
    ctrl.add_theme_font_size_override("font_size", fsize)
    ctrl.add_theme_color_override("font_color", color)
