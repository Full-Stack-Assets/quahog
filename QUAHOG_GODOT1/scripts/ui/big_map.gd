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


func toggle() -> void :
    visible = not visible
    if visible:
        move_to_front()
    queue_redraw()


func _process(_delta: float) -> void :
    if visible:
        queue_redraw()


func _gui_input(event: InputEvent) -> void :
    if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
        var mb: = event as InputEventMouseButton
        # Tap a spot to fast-travel there. If the tap lands near a named
        # destination label, snap to that exact spot; otherwise free-travel.
        if player != null and is_instance_valid(player):
            var scale: float = minf(size.x, size.y) / VIEW_M
            var cpx: Vector2 = size * 0.5
            var center: Vector3 = player.global_position
            # Default: free-travel to the tapped point. If the tap lands near a
            # named destination, snap to that exact spot instead.
            var rel: Vector2 = (mb.position - cpx) / scale
            var target: = Vector3(center.x + rel.x, center.y, center.z + rel.y)
            for d in DESTINATIONS:
                var dp: Vector2 = d["pos"]
                var screen: Vector2 = cpx + (dp - Vector2(center.x, center.z)) * scale
                if mb.position.distance_to(screen) <= SNAP_PX:
                    target = Vector3(dp.x, center.y, dp.y)
                    break
            if player.has_method("fast_travel_to"):
                player.fast_travel_to(target)
            else:
                player.global_position = target
        visible = false


func _load_roads() -> void :
    _loaded = true
    if not FileAccess.file_exists(SLICE):
        return
    var f: = FileAccess.open(SLICE, FileAccess.READ)
    if f == null:
        return
    var data: Variant = JSON.parse_string(f.get_as_text())
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

    draw_circle(cpx, 7.0, Color(0.45, 0.8, 1.0))
    draw_circle(cpx, 7.0, Color(1, 1, 1), false, 2.0)

    if _font:
        draw_string(_font, Vector2(40, 64), "MOUNT HOPE — MAP", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color(0.96, 0.86, 0.6))
        draw_string(_font, Vector2(40, size.y - 36), "Tap anywhere to fast-travel (names snap exactly) · M to close", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.82, 0.82, 0.82))
