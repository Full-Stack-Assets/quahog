extends RefCounted
class_name WaterZones

# Open harbor / river polygons from the map overlay. Driving or walking into
# these zones triggers the water hazard (sink + recover onto last dry ground).
# Bridge corridors are carved out so Braga, Fairhaven, and the hurricane barrier
# stay drivable.

static var _polys: Array[PackedVector2Array] = []
static var _loaded: bool = false

# World XZ endpoints + half-width (m). Points within half-width of the segment
# are treated as dry bridge deck even inside a water polygon.
const BRIDGE_CORRIDORS: Array = [
    {"a": Vector2(-20701.0, -8078.0), "b": Vector2(-20044.0, -7582.0), "half": 20.0},   # Braga I-195
    {"a": Vector2(380.0, 2000.0), "b": Vector2(1520.0, 2000.0), "half": 14.0},          # Hurricane barrier
    {"a": Vector2(1080.0, 8.0), "b": Vector2(2120.0, 52.0), "half": 12.0},             # NB–Fairhaven
]


static func _ensure() -> void :
    if _loaded:
        return
    _loaded = true
    var data: Variant = MapLoader.read_json_any("res://data/map/overlays/water.json")
    if not (data is Array):
        return
    for ring in data:
        if not (ring is Array) or ring.size() < 3:
            continue
        var poly: = PackedVector2Array()
        for p in ring:
            if not (p is Array) or p.size() < 2:
                continue
            # Slice coords: x = east, y = north → world XZ is (east, -north).
            poly.append(Vector2(float(p[0]), -float(p[1])))
        if poly.size() >= 3:
            _polys.append(poly)


static func _on_bridge(world_x: float, world_z: float) -> bool:
    var pt: = Vector2(world_x, world_z)
    for seg in BRIDGE_CORRIDORS:
        var a: Vector2 = seg["a"]
        var b: Vector2 = seg["b"]
        var half: float = float(seg["half"])
        if _dist_to_segment(pt, a, b) <= half:
            return true
    return false


static func _dist_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
    var ab: Vector2 = b - a
    var len_sq: float = ab.length_squared()
    if len_sq < 0.0001:
        return p.distance_to(a)
    var t: float = clampf((p - a).dot(ab) / len_sq, 0.0, 1.0)
    return p.distance_to(a + ab * t)


static func is_blocked(world_x: float, world_z: float) -> bool:
    if _on_bridge(world_x, world_z):
        return false
    _ensure()
    var pt: = Vector2(world_x, world_z)
    for poly in _polys:
        if Geometry2D.is_point_in_polygon(pt, poly):
            return true
    return false
