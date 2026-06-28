extends Control















const TESANA_QUIT_URL: = "https://tesana.ai/quit"



const PLAY_TARGET_SCENE: = "res://scenes/game_world.tscn"




const BUTTON_IDS: PackedStringArray = ["play"]
const BUTTON_STYLEBOXES: PackedStringArray = ["res://assets/ui/btn_play.tres"]


const BG_CANDIDATES: PackedStringArray = [
    "res://assets/ui/title_poster.webp", 
    "res://assets/ui/title_poster.png", 
    "res://assets/textures/backgrounds/menu_background.png", 
    "res://assets/textures/backgrounds/menu_bg.png", 
    "res://assets/ui/menu_background.png", 
]
const CLICK_SFX_CANDIDATES: PackedStringArray = [
    "res://assets/audio/sfx/ui/ui_menu_click.mp3", 
    "res://assets/audio/sfx/ui/ui_button_click.mp3", 
    "res://assets/audio/sfx/ui/ui_click.mp3", 
    "res://assets/audio/sfx/ui/ui_ui_click.mp3", 
]
const SETTINGS_SCENE_CANDIDATES: PackedStringArray = [
    "res://scenes/ui/settings.tscn", 
    "res://scenes/settings.tscn", 
]
const CREDITS_SCENE_CANDIDATES: PackedStringArray = [
    "res://scenes/ui/credits.tscn", 
    "res://scenes/credits.tscn", 
]

const TIPS: PackedStringArray = [
    "WASD to move · Shift to sprint · F to grab a car.",
    "Heat climbs when you cause trouble. Lay low to cool off.",
    "Tap MAP for the city — tap a place name to fast-travel.",
    "Tap RADIO to cycle the stations: WHALE · The Rage · The Anvil · Maré Alta.",
    "Ram a car to stop it, then jack it on foot.",
    "Take jobs from the contact downtown to earn your first dollars.",
]
const FONT_PATH: = "res://assets/fonts/noto_serif.ttf"

var _click_sfx_stream: AudioStream = null
var _wordmark: TextureRect = null
var _font: Font = null
var _cheats_overlay: Control = null

# Quick-start spawn presets for testing (world XZ; y lifted so you drop onto the
# street). Lets you jump straight into any corner of the South Coast.
const SPAWN_PRESETS: Array = [
    {"name": "Downtown New Bedford", "pos": Vector3(-219, 1.5, 107)},
    {"name": "Fort Taber", "pos": Vector3(1495, 1.5, 4560)},
    {"name": "Fall River (City Hall)", "pos": Vector3(-19475, 1.5, -7216)},
    {"name": "Battleship Cove", "pos": Vector3(-20180, 1.5, -7790)},
    {"name": "Brockton", "pos": Vector3(-8100, 1.5, -49768)},
    {"name": "Stoughton", "pos": Vector3(-14916, 1.5, -54435)},
]


func _ready() -> void :
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    Engine.time_scale = 1.0   # menus always run at normal speed (slow-mo is in-game)
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    if ResourceLoader.exists("res://assets/ui/theme.tres"):
        theme = load("res://assets/ui/theme.tres") as Theme

    var sfx_path: = _first_existing(CLICK_SFX_CANDIDATES)
    if sfx_path != "":
        _click_sfx_stream = load(sfx_path) as AudioStream

    if ResourceLoader.exists(FONT_PATH):
        _font = load(FONT_PATH)

    _build_background()
    _build_wordmark()
    _build_buttons()
    _build_text_overlay()


# Web StartMenu parity: era tag, subtitle, a rotating tip, and the OSM
# attribution footer.
func _build_text_overlay() -> void :
    var era: = _make_label("SOUTH COAST · 1986", 22, Color(1.0, 0.48, 0.85, 0.9))
    era.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    add_child(era)
    era.anchor_left = 0.0
    era.anchor_right = 1.0
    era.anchor_top = 0.0
    era.offset_top = 36
    era.offset_bottom = 70

    var subtitle: = _make_label("New Bedford · the Whaling City", 26, Color(0.9, 0.86, 0.78, 0.85))
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    add_child(subtitle)
    subtitle.anchor_left = 0.0
    subtitle.anchor_right = 1.0
    subtitle.anchor_top = 0.0
    subtitle.offset_top = 396
    subtitle.offset_bottom = 436

    var tip_i: int = int(Time.get_unix_time_from_system()) % TIPS.size()
    var tip: = _make_label("TIP: " + TIPS[tip_i], 22, Color(0.82, 0.82, 0.86, 0.8))
    tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    add_child(tip)
    tip.anchor_left = 0.0
    tip.anchor_right = 1.0
    tip.anchor_bottom = 1.0
    tip.anchor_top = 1.0
    tip.offset_top = -110
    tip.offset_bottom = -64

    var attrib: = _make_label("Map data © OpenStreetMap contributors, ODbL · An original work", 16, Color(0.7, 0.7, 0.74, 0.6))
    attrib.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    add_child(attrib)
    attrib.anchor_left = 0.0
    attrib.anchor_right = 1.0
    attrib.anchor_bottom = 1.0
    attrib.anchor_top = 1.0
    attrib.offset_top = -34
    attrib.offset_bottom = -10


func _make_label(text: String, font_size: int, color: Color) -> Label:
    var lbl: = Label.new()
    lbl.text = text
    lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
    lbl.add_theme_color_override("font_color", color)
    lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
    lbl.add_theme_constant_override("outline_size", 5)
    lbl.add_theme_font_size_override("font_size", font_size)
    if _font:
        lbl.add_theme_font_override("font", _font)
    return lbl


func _first_existing(paths: PackedStringArray) -> String:
    for p in paths:
        if ResourceLoader.exists(p):
            return p
    return ""


func _build_background() -> void :
    var bg_path: = _first_existing(BG_CANDIDATES)
    if bg_path != "":
        var bg: = TextureRect.new()
        bg.texture = load(bg_path)
        bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(bg)
        bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    else:
        var solid: = ColorRect.new()
        solid.color = Color(0.08, 0.08, 0.1, 1.0)
        solid.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(solid)
        solid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


    var vignette: = ColorRect.new()
    vignette.color = Color(0, 0, 0, 0.35)
    vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(vignette)
    vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _build_wordmark() -> void :
    if not ResourceLoader.exists("res://assets/ui/wordmark_title.png"):
        return
    _wordmark = TextureRect.new()
    _wordmark.texture = load("res://assets/ui/wordmark_title.png")
    _wordmark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    _wordmark.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
    _wordmark.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_wordmark)


    _wordmark.anchor_left = 0.5
    _wordmark.anchor_right = 0.5
    _wordmark.anchor_top = 0.0
    _wordmark.anchor_bottom = 0.0
    _wordmark.offset_left = -450
    _wordmark.offset_right = 450
    _wordmark.offset_top = 80
    _wordmark.offset_bottom = 380


func _build_buttons() -> void :




    var center: = CenterContainer.new()
    add_child(center)
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    center.mouse_filter = Control.MOUSE_FILTER_PASS

    var vbox: = VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 18)
    center.add_child(vbox)


    if _wordmark != null:
        var spacer: = Control.new()
        spacer.custom_minimum_size = Vector2(0, 240)
        spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
        vbox.add_child(spacer)

    # Continue (resume the saved spot) appears only when a save exists. The
    # image PLAY button below it starts a fresh game.
    var gm: = get_node_or_null("/root/GameManager")
    if gm and gm.has_method("has_save") and gm.has_save():
        vbox.add_child(_make_text_button("▶ CONTINUE", _on_continue_pressed))

    var n: = BUTTON_IDS.size()
    for i in n:
        var btn: = _make_button(BUTTON_IDS[i], BUTTON_STYLEBOXES[i])
        vbox.add_child(btn)

    vbox.add_child(_make_text_button("⚙ CHEATS", _open_cheats))


func _make_text_button(text: String, cb: Callable) -> Button:
    var b: = Button.new()
    b.text = text
    b.focus_mode = Control.FOCUS_NONE
    b.custom_minimum_size = Vector2(360, 64)
    if _font:
        b.add_theme_font_override("font", _font)
    b.add_theme_font_size_override("font_size", 30)
    b.add_theme_color_override("font_color", Color(1.0, 0.81, 0.28))
    b.pressed.connect(cb)
    return b


func _on_continue_pressed() -> void :
    _play_click_sfx()
    var gm: = get_node_or_null("/root/GameManager")
    if gm and "has_saved_pos" in gm and gm.has_saved_pos:
        gm.player_spawn_override = gm.saved_pos
        gm.has_spawn_override = true
    _go_to_play()


func _make_button(id: String, stylebox_path: String) -> Button:
    var btn: = Button.new()
    btn.custom_minimum_size = Vector2(360, 110)
    btn.text = ""
    btn.focus_mode = Control.FOCUS_NONE
    if ResourceLoader.exists(stylebox_path):
        var sb: = load(stylebox_path) as StyleBox
        if sb:
            btn.add_theme_stylebox_override("normal", sb)
            btn.add_theme_stylebox_override("hover", sb)
            btn.add_theme_stylebox_override("pressed", sb)
            btn.add_theme_stylebox_override("focus", sb)
            btn.add_theme_stylebox_override("disabled", sb)
    btn.mouse_entered.connect(_on_button_hover.bind(btn, true))
    btn.mouse_exited.connect(_on_button_hover.bind(btn, false))
    btn.pressed.connect(_on_button_pressed.bind(id))
    return btn


func _on_button_hover(btn: Button, entering: bool) -> void :
    var target: = Color(1.1, 1.1, 1.1, 1.0) if entering else Color(1.0, 1.0, 1.0, 1.0)
    var tween: = create_tween()
    tween.tween_property(btn, "modulate", target, 0.08)


func _on_button_pressed(id: String) -> void :
    _play_click_sfx()
    match id:
        "play", "new_game":
            _on_new_game()
        "continue":
            _on_continue_pressed()
        "settings", "options":
            _open_settings_or_noop()
        "credits":
            _open_credits_or_noop()
        "back":
            pass
        "quit", "exit":
            _quit_to_tesana()
        _:



            push_warning("Main menu: unknown button id '" + id + "' (no action wired).")


func _on_new_game() -> void :
    var gm: = get_node_or_null("/root/GameManager")
    if gm:
        gm.has_spawn_override = false
        if gm.has_method("reset_save"):
            gm.reset_save()
    _go_to_play()


# --- Cheats / test panel ----------------------------------------------------

func _open_cheats() -> void :
    _play_click_sfx()
    if _cheats_overlay != null and is_instance_valid(_cheats_overlay):
        return

    var overlay: = Control.new()
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(overlay)
    _cheats_overlay = overlay

    var dim: = ColorRect.new()
    dim.color = Color(0, 0, 0, 0.78)
    dim.mouse_filter = Control.MOUSE_FILTER_STOP
    overlay.add_child(dim)
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    # Scrollable so the full cheat list fits any screen.
    var scroll: = ScrollContainer.new()
    scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    scroll.offset_left = 140
    scroll.offset_right = -140
    scroll.offset_top = 64
    scroll.offset_bottom = -56
    overlay.add_child(scroll)

    var box: = VBoxContainer.new()
    box.add_theme_constant_override("separation", 9)
    box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(box)

    var title: = _make_label("CHEATS · TEST TOOLS", 34, Color(1.0, 0.81, 0.28))
    box.add_child(title)

    box.add_child(_make_label("Toggles (saved):", 19, Color(0.8, 0.8, 0.84)))
    _add_bool_cheat(box, "No Police (no heat)", "cheat_no_police")
    _add_bool_cheat(box, "God Mode", "cheat_godmode")
    _add_bool_cheat(box, "Infinite Ammo", "cheat_infinite_ammo")
    _add_bool_cheat(box, "All Weapons (next start)", "cheat_all_weapons")
    _add_bool_cheat(box, "One-Shot Kills", "cheat_oneshot")
    _add_bool_cheat(box, "Rapid Fire", "cheat_rapidfire")
    _add_bool_cheat(box, "Super Speed", "cheat_super_speed")
    _add_bool_cheat(box, "Super Jump", "cheat_super_jump")
    _add_bool_cheat(box, "Infinite Cash", "cheat_infinite_cash")
    _add_bool_cheat(box, "Car Turbo", "cheat_car_turbo")
    _add_bool_cheat(box, "Teleport Anywhere (map)", "cheat_teleport_anywhere")

    box.add_child(_make_label("Settings (next start for traffic/speed):", 19, Color(0.8, 0.8, 0.84)))
    _add_cycle_cheat(box, "Time", "cheat_time_phase", [["Normal", -1.0], ["Dusk", 0.0], ["Day", 0.75], ["Night", 0.25], ["Dawn", 0.5]])
    _add_cycle_cheat(box, "Weather", "cheat_force_rain", [["Auto", -1], ["Rain", 1], ["Dry", 0]])
    _add_cycle_cheat(box, "Traffic", "cheat_traffic_mult", [["Light", 0.5], ["Normal", 1.0], ["Heavy", 2.0], ["Insane", 4.0]])
    _add_cycle_cheat(box, "Game Speed", "cheat_time_scale", [["0.5x", 0.5], ["1x", 1.0], ["2x", 2.0], ["4x", 4.0]])

    box.add_child(_make_text_button("+ ADD $10,000", _add_cash))

    box.add_child(_make_label("Quick start (fresh game):", 19, Color(0.8, 0.8, 0.84)))
    for preset in SPAWN_PRESETS:
        var p: Dictionary = preset
        var pos: Vector3 = p["pos"]
        box.add_child(_make_text_button("▶ " + str(p["name"]), _cheat_spawn.bind(pos)))

    box.add_child(_make_text_button("✕ CLOSE", _close_cheats))


func _noop() -> void :
    pass


# Generic ON/OFF cheat bound to a GameManager bool property.
func _add_bool_cheat(box: VBoxContainer, label: String, flag: String) -> void :
    var b: = _make_text_button("", _noop)
    _refresh_flag_btn(b, label, flag)
    b.pressed.connect(_toggle_flag.bind(b, label, flag))
    box.add_child(b)


func _refresh_flag_btn(btn: Button, label: String, flag: String) -> void :
    var gm: = get_node_or_null("/root/GameManager")
    var on: bool = gm != null and bool(gm.get(flag))
    btn.text = label + ":  " + ("ON" if on else "OFF")
    btn.add_theme_color_override("font_color", Color(0.5, 1.0, 0.55) if on else Color(0.85, 0.72, 0.42))


func _toggle_flag(btn: Button, label: String, flag: String) -> void :
    _play_click_sfx()
    var gm: = get_node_or_null("/root/GameManager")
    if gm:
        gm.set(flag, not bool(gm.get(flag)))
        if gm.has_method("save_game"):
            gm.save_game()
    _refresh_flag_btn(btn, label, flag)


# Generic multi-state cheat: options is [[display, value], ...].
func _add_cycle_cheat(box: VBoxContainer, label: String, flag: String, options: Array) -> void :
    var b: = _make_text_button("", _noop)
    _refresh_cycle_btn(b, label, flag, options)
    b.pressed.connect(_cycle_flag.bind(b, label, flag, options))
    box.add_child(b)


func _refresh_cycle_btn(btn: Button, label: String, flag: String, options: Array) -> void :
    var gm: = get_node_or_null("/root/GameManager")
    var v: float = float(gm.get(flag)) if gm != null else 0.0
    var disp: String = str(options[0][0])
    for opt in options:
        if absf(float(opt[1]) - v) < 0.001:
            disp = str(opt[0])
            break
    btn.text = label + ":  " + disp


func _cycle_flag(btn: Button, label: String, flag: String, options: Array) -> void :
    _play_click_sfx()
    var gm: = get_node_or_null("/root/GameManager")
    if gm == null:
        return
    var v: float = float(gm.get(flag))
    var cur: int = 0
    for i in options.size():
        if absf(float(options[i][1]) - v) < 0.001:
            cur = i
            break
    gm.set(flag, options[(cur + 1) % options.size()][1])
    if gm.has_method("save_game"):
        gm.save_game()
    _refresh_cycle_btn(btn, label, flag, options)


func _add_cash() -> void :
    _play_click_sfx()
    var gm: = get_node_or_null("/root/GameManager")
    if gm and gm.has_method("add_cash"):
        gm.add_cash(10000)


func _cheat_spawn(pos: Vector3) -> void :
    _play_click_sfx()
    var gm: = get_node_or_null("/root/GameManager")
    if gm:
        if gm.has_method("reset_save"):
            gm.reset_save()
        gm.player_spawn_override = pos
        gm.has_spawn_override = true
    _go_to_play()


func _close_cheats() -> void :
    _play_click_sfx()
    if _cheats_overlay != null and is_instance_valid(_cheats_overlay):
        _cheats_overlay.queue_free()
    _cheats_overlay = null


func _go_to_play() -> void :
    var loader: = get_node_or_null("/root/LoadingScreen")
    if loader and loader.has_method("preload_and_change_scene"):
        loader.preload_and_change_scene(PLAY_TARGET_SCENE)
    else:
        get_tree().change_scene_to_file(PLAY_TARGET_SCENE)


func _open_settings_or_noop() -> void :
    var path: = _first_existing(SETTINGS_SCENE_CANDIDATES)
    if path != "":
        get_tree().change_scene_to_file(path)


func _open_credits_or_noop() -> void :
    var path: = _first_existing(CREDITS_SCENE_CANDIDATES)
    if path != "":
        get_tree().change_scene_to_file(path)


func _quit_to_tesana() -> void :








    if OS.has_feature("web"):
        var js: = "try { window.top.location.href = \"" + TESANA_QUIT_URL + "\"; }"\
+ " catch (e) { window.location.href = \"" + TESANA_QUIT_URL + "\"; }"
        JavaScriptBridge.eval(js)
    else:
        get_tree().quit()


func _play_click_sfx() -> void :




    if _click_sfx_stream == null:
        return
    var p: = AudioStreamPlayer.new()
    p.stream = _click_sfx_stream
    p.volume_db = -4.0
    add_child(p)
    p.play()
    p.finished.connect(p.queue_free)
