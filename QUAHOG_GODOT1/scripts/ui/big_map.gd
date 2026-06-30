extends Control
class_name BigMap

# Full-screen map (web BigMap parity): draws the real street network zoomed out,
# centered on the player, with the objective + player marker. Toggle with the
# HUD MAP button; tap anywhere to close.

const SLICE: = "res://data/map/slice-newbedford.json"
const CELL: = 200.0
const VIEW_M: = 1800.0  # metres shown across the shorter screen axis

# Named fast-travel destinations, in world XZ (x=east, z=south). Only points
# inside the current New Bedford OSM slice — the RT18 / I-195 / Fall River
# corridor is a planned slice expansion (see plans/mount-hope.md §GR).
const DESTINATIONS: Array = [
    {"name": "Downtown", "pos": Vector2(0, 0)},
    {"name": "Whaling Museum", "pos": Vector2(-219, 107)},
    {"name": "State Pier", "pos": Vector2(120, -40)},
    {"name": "North End", "pos": Vector2(-200, -3000)},
    {"name": "South End", "pos": Vector2(-500, 2600)},
    {"name": "Fort Taber", "pos": Vector2(1300, 4750)},
    {"name": "Fairhaven", "pos": Vector2(1381, 178)},
    {"name": "Clark's Cove", "pos": Vector2(-1400, 2200)},
]

# Region fast-travel: the whole South Coast, reachable from a button column
# (the zoomed map can't show towns 20 km away, so these are always available).
const REGIONS: Array = [
    {"name": "New Bedford", "pos": Vector2(0, 0)},
    {"name": "Fort Taber", "pos": Vector2(1300, 4750)},
    {"name": "Fairhaven", "pos": Vector2(1381, 178)},
    {"name": "Dartmouth Mall", "pos": Vector2(-3921, -378)},
    {"name": "Westport", "pos": Vector2(-12046, -2216)},
    {"name": "Fall River", "pos": Vector2(-19475, -7216)},
    {"name": "Braga Bridge", "pos": Vector2(-20372, -7829)},
    {"name": "Battleship Cove", "pos": Vector2(-20180, -7882)},
    {"name": "Freetown", "pos": Vector2(-6606, -14917)},
    {"name": "Middleborough", "pos": Vector2(791, -28609)},
    {"name": "Taunton", "pos": Vector2(-14085, -29389)},
    {"name": "Bridgewater", "pos": Vector2(-4113, -39407)},
    {"name": "Brockton", "pos": Vector2(-8100, -49768)},
    {"name": "Cape Cod Canal", "pos": Vector2(-11050, -47600)},
    {"name": "Dartmouth", "pos": Vector2(-3744, 806)},
    {"name": "Stoughton", "pos": Vector2(-14916, -54435)},
    {"name": "Braintree", "pos": Vector2(-6951, -63664)},
    {"name": "Weymouth", "pos": Vector2(-1607, -64800)},
    {"name": "Quincy", "pos": Vector2(-6809, -68672)},
]
const SNAP_PX: = 34.0  # tap within this many pixels of a label snaps to it

var player: Node3D = null
var job_manager: Node = null

var _font: Font
var _road_cells: Dictionary = {}
var _landmarks: Array = []          # [{name:String, pos:Vector2(x,z), hero:bool}]
var _loaded: bool = false


func bind(p_player: Node3D, p_jobs: Node) -> void :
    player = p_player
    job_manager = p_jobs


func _ready() -> void :
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    visible = false
    mouse_filter = Control.MOUSE_FILTER_STOP
    _font = load("res://assets/fonts/noto_serif.ttf")

    var close_btn: = Button.new()
    close_btn.text = "✕ CLOSE"
    close_btn.focus_mode = Control.FOCUS_NONE
    close_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
    close_btn.offset_left = -168
    close_btn.offset_right = -28
    close_btn.offset_top = 40
    close_btn.offset_bottom = 96
    close_btn.custom_minimum_size = Vector2(140, 56)
    if _font:
        close_btn.add_theme_font_override("font", _font)
    close_btn.add_theme_font_size_override("font_size", 26)
    close_btn.pressed.connect(func(): visible = false)
    add_child(close_btn)

    # In-game CHEATS / test-tools, left of CLOSE.
    var cheats_btn: = Button.new()
    cheats_btn.text = "⚙ CHEATS"
    cheats_btn.focus_mode = Control.FOCUS_NONE
    cheats_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
    cheats_btn.offset_left = -340
    cheats_btn.offset_right = -184
    cheats_btn.offset_top = 40
    cheats_btn.offset_bottom = 96
    cheats_btn.custom_minimum_size = Vector2(156, 56)
    if _font:
        cheats_btn.add_theme_font_override("font", _font)
    cheats_btn.add_theme_font_size_override("font_size", 24)
    cheats_btn.pressed.connect(_open_cheats)
    add_child(cheats_btn)

    # Region fast-travel column (top-left): jump anywhere on the South Coast.
    var col: = VBoxContainer.new()
    col.add_theme_constant_override("separation", 8)
    col.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    col.offset_left = 36
    col.offset_top = 96
    add_child(col)
    var hdr: = Label.new()
    hdr.text = "TRAVEL"
    if _font:
        hdr.add_theme_font_override("font", _font)
    hdr.add_theme_font_size_override("font_size", 22)
    hdr.add_theme_color_override("font_color", Color(0.96, 0.86, 0.6))
    col.add_child(hdr)
    for d in REGIONS:
        var dp: Vector2 = d["pos"]
        var btn: = Button.new()
        btn.text = str(d["name"])
        btn.focus_mode = Control.FOCUS_NONE
        btn.custom_minimum_size = Vector2(300, 60)
        if _font:
            btn.add_theme_font_override("font", _font)
        btn.add_theme_font_size_override("font_size", 22)
        btn.pressed.connect(_travel_to.bind(dp))
        col.add_child(btn)


func _open_cheats() -> void :
    var panel: = CheatsPanel.new()
    panel.menu_mode = false   # in-game: toggles apply live, no fresh-game spawns
    add_child(panel)


func _travel_to(dp: Vector2) -> void :
    if player != null and is_instance_valid(player):
        var target: = Vector3(dp.x, player.global_position.y, dp.y)
        if player.has_method("fast_travel_to"):
            player.fast_travel_to(target)
        else:
            player.global_position = target
    visible = false


func toggle() -> void :
    visible = not visible
    if visible:
        move_to_front()
    queue_redraw()


func _process(_delta: float) -> void :
    if visible:
        queue_redraw()


func _gui_input(event: InputEvent) -> void :
    if not (event is InputEventMouseButton and (event as InputEventMouseButton).pressed):
        return
    var mb: = event as InputEventMouseButton
    if player == null or not is_instance_valid(player):
        return
    # Fast-travel ONLY when a tap lands on a named destination — empty taps do
    # nothing (so you can read the map without it closing or flinging you into
    # the harbour). Close with the X button or the M key.
    var scale: float = minf(size.x, size.y) / VIEW_M
    var cpx: Vector2 = size * 0.5
    var center: Vector3 = player.global_position
    for d in DESTINATIONS:
        var dp: Vector2 = d["pos"]
        var screen: Vector2 = cpx + (dp - Vector2(center.x, center.z)) * scale
        if mb.position.distance_to(screen) <= SNAP_PX:
            var target: = Vector3(dp.x, center.y, dp.y)
            if player.has_method("fast_travel_to"):
                player.fast_travel_to(target)
            else:
                player.global_position = target
            visible = false
            return
    # Region area pins (clamped to the map edges when far off-view) are tappable
    # too, so you can fast-travel anywhere on the South Coast straight from the map.
    for rd in REGIONS:
        var rp: Vector2 = rd["pos"]
        if mb.position.distance_to(_region_screen(rp, center, scale, cpx)) <= SNAP_PX + 8.0:
            _travel_to(rp)
            return
    # Cheat: teleport to wherever you tap (not just named areas).
    if GameManager and GameManager.cheat_teleport_anywhere:
        var wx: float = center.x + (mb.position.x - cpx.x) / scale
        var wz: float = center.z + (mb.position.y - cpx.y) / scale
        _travel_to(Vector2(wx, wz))


# Screen position of a region area marker, clamped to the map edges so far towns
# still show (spread along the edge by their real direction from the player).
func _region_screen(rp: Vector2, center: Vector3, scale: float, cpx: Vector2) -> Vector2:
    var raw: = cpx + (rp - Vector2(center.x, center.z)) * scale
    var m: = 30.0
    return Vector2(clampf(raw.x, m, size.x - m), clampf(raw.y, m, size.y - m))


func _load_roads() -> void :
    _loaded = true
    var data: Variant = MapLoader.read_json_any(SLICE)
    if not (data is Dictionary):
        return
    var roads: Variant = data.get("roads", [])
    if not (roads is Array):
        return
    for r in roads:
        if not (r is Dictionary):
            continue
        var pts: Variant = r.get("points")
        if not (pts is Array) or pts.size() < 2:
            continue
        for i in range(pts.size() - 1):
            var a: = Vector2(float(pts[i][0]), - float(pts[i][1]))
            var b: = Vector2(float(pts[i + 1][0]), - float(pts[i + 1][1]))
            var key: = Vector2i(int(floor(((a.x + b.x) * 0.5) / CELL)), int(floor(((a.y + b.y) * 0.5) / CELL)))
            if not _road_cells.has(key):
                _road_cells[key] = []
            var arr: Array = _road_cells[key]
            arr.append(a)
            arr.append(b)

    var lms: Variant = data.get("landmarks", [])
    if lms is Array:
        for l in lms:
            if not (l is Dictionary):
                continue
            var p: Variant = l.get("pos")
            if not (p is Array) or p.size() < 2:
                continue
            _landmarks.append({
                "name": str(l.get("name", "")),
                "pos": Vector2(float(p[0]), - float(p[1])),
                "hero": bool(l.get("hero", false)),
            })


func _draw() -> void :
    if not visible:
        return
    if not _loaded:
        _load_roads()
    draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.06, 0.08, 0.96), true)
    if player == null or not is_instance_valid(player):
        return
    var center: Vector3 = player.global_position
    var scale: float = minf(size.x, size.y) / VIEW_M
    var cpx: Vector2 = size * 0.5
    var rng: int = int(ceil((VIEW_M * 0.5) / CELL)) + 1
    var ccx: int = int(floor(center.x / CELL))
    var ccz: int = int(floor(center.z / CELL))
    var road_col: = Color(0.6, 0.62, 0.55, 0.9)
    for dx in range(-rng, rng + 1):
        for dz in range(-rng, rng + 1):
            var segs: Array = _road_cells.get(Vector2i(ccx + dx, ccz + dz), [])
            var i: = 0
            while i + 1 < segs.size():
                var aw: Vector2 = segs[i]
                var bw: Vector2 = segs[i + 1]
                var a: = cpx + Vector2(aw.x - center.x, aw.y - center.z) * scale
                var b: = cpx + Vector2(bw.x - center.x, bw.y - center.z) * scale
                draw_line(a, b, road_col, 1.5)
                i += 2

    if job_manager and job_manager.has_method("has_active_job") and job_manager.has_active_job():
        var obj: Vector3 = job_manager.get_objective_position()
        var op: = cpx + Vector2(obj.x - center.x, obj.z - center.z) * scale
        draw_circle(op, 9.0, Color(0.97, 0.8, 0.3))

    # Real New Bedford landmarks (reference only). Hero landmarks get a label;
    # the rest are small dots so the map stays readable.
    for lm in _landmarks:
        var lp: Vector2 = lm["pos"]
        var sp2: Vector2 = cpx + (lp - Vector2(center.x, center.z)) * scale
        if sp2.x < 0 or sp2.y < 0 or sp2.x > size.x or sp2.y > size.y:
            continue
        var is_hero: bool = lm["hero"]
        draw_circle(sp2, 3.0 if is_hero else 2.0, Color(0.55, 0.78, 0.85, 0.9 if is_hero else 0.55))
        if is_hero and _font:
            draw_string(_font, sp2 + Vector2(6, 4), str(lm["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.66, 0.84, 0.9, 0.85))

    # Named fast-travel destinations.
    for d in DESTINATIONS:
        var dp: Vector2 = d["pos"]
        var sp: Vector2 = cpx + (dp - Vector2(center.x, center.z)) * scale
        if sp.x < 0 or sp.y < 0 or sp.x > size.x or sp.y > size.y:
            continue
        draw_circle(sp, 4.0, Color(0.95, 0.9, 0.8))
        if _font:
            draw_string(_font, sp + Vector2(8, 5), str(d["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.92, 0.88, 0.78))

    # Region areas — always shown (clamped to the map edge if off-view) and
    # tappable to fast-travel across the whole South Coast.
    var region_col: = Color(0.45, 0.85, 0.98)
    for rd in REGIONS:
        var rp: Vector2 = rd["pos"]
        var rs: = _region_screen(rp, center, scale, cpx)
        draw_circle(rs, 6.0, region_col)
        draw_circle(rs, 6.0, Color(0, 0, 0, 0.6), false, 1.5)
        if _font:
            draw_string(_font, rs + Vector2(9, 5), str(rd["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, region_col)

    draw_circle(cpx, 7.0, Color(0.45, 0.8, 1.0))
    draw_circle(cpx, 7.0, Color(1, 1, 1), false, 2.0)

    if _font:
        draw_string(_font, Vector2(40, 64), "MOUNT HOPE — MAP", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color(0.96, 0.86, 0.6))
        draw_string(_font, Vector2(40, size.y - 36), "Tap a place name (gold = nearby · blue = area) to fast-travel · ✕ or M to close", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.82, 0.82, 0.82))
