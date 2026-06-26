extends Control
class_name Minimap





const GRID: = [-116.0, -58.0, 0.0, 58.0, 116.0]
const WORLD_VIEW: = 240.0

var player: Node3D = null
var job_manager: Node = null
var wanted_system: Node = null
var _font: Font

var _scale: float = 1.0
var _center_px: Vector2 = Vector2.ZERO
var _pulse: float = 0.0


func bind(p_player: Node3D, p_jobs: Node, p_wanted: Node) -> void :
    player = p_player
    job_manager = p_jobs
    wanted_system = p_wanted


func _ready() -> void :
    custom_minimum_size = Vector2(240, 240)
    size = custom_minimum_size
    clip_contents = true
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _font = load("res://assets/fonts/noto_serif.ttf")


func _process(delta: float) -> void :
    _pulse = fmod(_pulse + delta * 3.0, TAU)
    queue_redraw()


func _world_to_map(w: Vector3, center: Vector3) -> Vector2:
    var rel: = w - center
    return _center_px + Vector2(rel.x, rel.z) * _scale


func _district_name(p: Vector3) -> String:
    if p.length() < 36.0:
        return "Mill Plaza"
    var ns: = "North" if p.z < -20.0 else ("South" if p.z > 20.0 else "")
    var ew: = "West" if p.x < -20.0 else ("East" if p.x > 20.0 else "")
    if ns == "" and ew == "":
        return "Downtown"
    var label: = (ns + " " + ew).strip_edges()
    return label + " End"


func _draw() -> void :
    var rect: = Rect2(Vector2.ZERO, size)
    draw_rect(rect, Color(0.06, 0.07, 0.09, 0.82), true)
    if player == null or not is_instance_valid(player):
        draw_rect(rect, Color(0.79, 0.52, 0.16, 0.7), false, 2.0)
        return

    _scale = size.x / WORLD_VIEW
    _center_px = size * 0.5
    var center: Vector3 = player.global_position


    var road_col: = Color(0.32, 0.34, 0.38, 0.9)
    for g in GRID:
        var gx: float = g
        var a: = _world_to_map(Vector3(gx, 0, center.z - WORLD_VIEW), center)
        var b: = _world_to_map(Vector3(gx, 0, center.z + WORLD_VIEW), center)
        draw_line(a, b, road_col, 3.0)
        var gz: float = g
        var c: = _world_to_map(Vector3(center.x - WORLD_VIEW, 0, gz), center)
        var d: = _world_to_map(Vector3(center.x + WORLD_VIEW, 0, gz), center)
        draw_line(c, d, road_col, 3.0)


    if job_manager and job_manager.has_method("has_active_job") and job_manager.has_active_job():
        var obj: Vector3 = job_manager.get_objective_position()
        var col: = Color(0.4, 0.9, 0.5) if (job_manager.get("stage") == 2) else Color(0.97, 0.8, 0.3)
        _draw_blip(obj, center, col, 6.0 + sin(_pulse) * 2.0)


    if wanted_system and wanted_system.has_method("get_cops"):
        for cop in wanted_system.get_cops():
            if is_instance_valid(cop):
                _draw_blip(cop.global_position, center, Color(0.95, 0.3, 0.3), 4.0)


    var yaw: float = 0.0
    if player.has_method("get_map_heading"):
        yaw = player.get_map_heading()
    _draw_player(yaw)


    draw_rect(rect, Color(0.79, 0.52, 0.16, 0.85), false, 2.0)
    if _font:
        var dn: = _district_name(center)
        draw_string(_font, Vector2(8, size.y - 10), dn, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.95, 0.86, 0.6))


func _draw_blip(world: Vector3, center: Vector3, color: Color, r: float) -> void :
    var p: = _world_to_map(world, center)
    var margin: = 10.0
    p.x = clampf(p.x, margin, size.x - margin)
    p.y = clampf(p.y, margin, size.y - margin)
    draw_circle(p, r + 2.0, Color(0, 0, 0, 0.5))
    draw_circle(p, r, color)


func _draw_player(yaw: float) -> void :
    var c: = _center_px

    var fwd: = Vector2(sin(yaw), - cos(yaw))
    var right: = Vector2( - fwd.y, fwd.x)
    var p1: = c + fwd * 9.0
    var p2: = c - fwd * 6.0 + right * 6.0
    var p3: = c - fwd * 6.0 - right * 6.0
    draw_colored_polygon(PackedVector2Array([p1, p2, p3]), Color(0.45, 0.8, 1.0))
    draw_circle(c, 2.5, Color(1, 1, 1))
