extends CanvasLayer
class_name ShopMenu





var _player: Node = null
var _root: Control
var _panel: PanelContainer
var _list: VBoxContainer
var _cash_label: Label
var _font: Font
var _open: bool = false


func _ready() -> void :
    layer = 12
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
    dim.color = Color(0.02, 0.03, 0.04, 0.82)
    dim.mouse_filter = Control.MOUSE_FILTER_STOP
    _root.add_child(dim)
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var center: = CenterContainer.new()
    _root.add_child(center)
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    _panel = PanelContainer.new()
    _panel.theme_type_variation = "DialogPanel"
    _panel.custom_minimum_size = Vector2(760, 620)
    center.add_child(_panel)

    var margin: = MarginContainer.new()
    for m in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
        margin.add_theme_constant_override(m, 28)
    _panel.add_child(margin)

    var vbox: = VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 14)
    margin.add_child(vbox)


    var header: = HBoxContainer.new()
    header.add_theme_constant_override("separation", 16)
    vbox.add_child(header)
    var title: = Label.new()
    title.text = "AMMU-NATION"
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _apply_font(title, 44, Color(0.96, 0.81, 0.45))
    header.add_child(title)
    _cash_label = Label.new()
    _cash_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _apply_font(_cash_label, 32, Color(0.6, 0.95, 0.55))
    header.add_child(_cash_label)

    var sub: = Label.new()
    sub.text = "Spend your hard-earned cash. Tap a Buy button."
    _apply_font(sub, 22, Color(0.8, 0.78, 0.72))
    vbox.add_child(sub)


    var scroll: = ScrollContainer.new()
    scroll.custom_minimum_size = Vector2(700, 400)
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    vbox.add_child(scroll)
    _list = VBoxContainer.new()
    _list.add_theme_constant_override("separation", 10)
    _list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(_list)


    var close: = Button.new()
    close.text = "Leave Store"
    close.custom_minimum_size = Vector2(280, 64)
    close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    _apply_font(close, 28, Color(0.98, 0.96, 0.92))
    close.pressed.connect(close_shop)
    vbox.add_child(close)

    _root.visible = false

    if GameManager:
        GameManager.open_shop_requested.connect(_on_open_requested)
        GameManager.cash_changed.connect(_update_cash)


func bind_player(player: Node) -> void :
    _player = player


func _on_open_requested(_kind: String) -> void :
    open_shop()


func open_shop() -> void :
    if _open:
        return
    _open = true
    _root.visible = true
    get_tree().paused = true
    _update_cash(GameManager.cash if GameManager else 0)
    _rebuild_offers()


func close_shop() -> void :
    if not _open:
        return
    _open = false
    _root.visible = false
    get_tree().paused = false


func _update_cash(value: int) -> void :
    if _cash_label:
        _cash_label.text = "$" + str(value)
    if _open:
        _rebuild_offers()


func _rebuild_offers() -> void :
    for c in _list.get_children():
        c.queue_free()


    for id in WeaponDB.ORDER:
        if id == "fists":
            continue
        var def: Dictionary = WeaponDB.get_def(id)
        var owned: bool = _player and _player.has_method("owns_weapon") and _player.owns_weapon(id)
        var price: int = int(def.get("price", 0))
        if owned:
            continue
        var label: = "%s" % def["name"]
        if def.get("melee", false):
            label += "  (melee)"
        _add_row(label, price, func(): _buy_weapon(id, price))


    for id in WeaponDB.ORDER:
        var def: Dictionary = WeaponDB.get_def(id)
        if def.get("melee", false):
            continue
        var owned: bool = _player and _player.has_method("owns_weapon") and _player.owns_weapon(id)
        if not owned:
            continue
        var amount: int = int(def.get("ammo_buy", 30))
        var price: int = int(def.get("ammo_price", 25))
        _add_row("%s Ammo  (+%d)" % [def["name"], amount], price, func(): _buy_ammo(id, amount, price))


    _add_row("Body Armor  (+50)", 150, func(): _buy_armor(50, 150))
    _add_row("Patch Up  (full health)", 80, func(): _buy_health(80))


func _add_row(text: String, price: int, on_buy: Callable) -> void :
    var row: = PanelContainer.new()
    row.theme_type_variation = "HudPanel"
    row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _list.add_child(row)

    var hb: = HBoxContainer.new()
    hb.add_theme_constant_override("separation", 14)
    var mc: = MarginContainer.new()
    for m in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
        mc.add_theme_constant_override(m, 8)
    mc.add_child(hb)
    row.add_child(mc)

    var name_lbl: = Label.new()
    name_lbl.text = text
    name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _apply_font(name_lbl, 26, Color(0.95, 0.92, 0.85))
    hb.add_child(name_lbl)

    var price_lbl: = Label.new()
    price_lbl.text = ("FREE" if price <= 0 else "$" + str(price))
    price_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    price_lbl.custom_minimum_size = Vector2(110, 0)
    price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    _apply_font(price_lbl, 26, Color(0.6, 0.95, 0.55))
    hb.add_child(price_lbl)

    var buy: = Button.new()
    buy.text = "Buy"
    buy.custom_minimum_size = Vector2(130, 56)
    _apply_font(buy, 24, Color(0.98, 0.96, 0.92))
    var affordable: bool = GameManager and GameManager.can_afford(price)
    buy.disabled = not affordable
    buy.pressed.connect(on_buy)
    hb.add_child(buy)



func _can_pay(price: int) -> bool:
    if price <= 0:
        return true
    if GameManager and GameManager.spend_cash(price):
        return true
    _deny()
    return false

func _deny() -> void :
    if AudioManager:
        var snd: = load("res://assets/audio/sfx/ui/ui_shop_denied.mp3")
        if snd:
            AudioManager.play_sfx(snd, -6.0)

func _confirm() -> void :
    if AudioManager:
        var snd: = load("res://assets/audio/sfx/ui/ui_shop_buy.mp3")
        if snd:
            AudioManager.play_sfx(snd, -5.0)

func _buy_weapon(id: String, price: int) -> void :
    if _player == null or not _player.has_method("give_weapon"):
        return
    if _player.has_method("owns_weapon") and _player.owns_weapon(id):
        return
    if not _can_pay(price):
        return
    var starter: int = int(WeaponDB.get_def(id).get("ammo_buy", 0))
    _player.give_weapon(id, starter)
    _confirm()

func _buy_ammo(id: String, amount: int, price: int) -> void :
    if _player == null or not _player.has_method("add_ammo"):
        return
    if not _can_pay(price):
        return
    _player.add_ammo(id, amount)
    _confirm()

func _buy_armor(amount: int, price: int) -> void :
    if _player == null or not _player.has_method("add_armor"):
        return
    if "armor" in _player and _player.armor >= 100:
        if GameManager:
            GameManager.show_message("Armor already full.")
        return
    if not _can_pay(price):
        return
    _player.add_armor(amount)
    _confirm()

func _buy_health(price: int) -> void :
    if _player == null or not _player.has_method("heal"):
        return
    if "health" in _player and "max_health" in _player and _player.health >= _player.max_health:
        if GameManager:
            GameManager.show_message("You're already at full health.")
        return
    if not _can_pay(price):
        return
    _player.heal(9999)
    _confirm()


func _apply_font(ctrl: Control, fsize: int, color: Color) -> void :
    if _font:
        ctrl.add_theme_font_override("font", _font)
    ctrl.add_theme_font_size_override("font_size", fsize)
    ctrl.add_theme_color_override("font_color", color)
