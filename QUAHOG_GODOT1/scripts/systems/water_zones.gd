extends RefCounted
class_name WaterZones

# Open harbor / river polygons from the map overlay. Driving or walking into
# these zones triggers the water hazard (sink + recover onto last dry ground).

static var _polys: Array[PackedVector2Array] = []
static var _loaded: bool = false


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


static func is_blocked(world_x: float, world_z: float) -> bool:
    _ensure()
    var pt: = Vector2(world_x, world_z)
    for poly in _polys:
        if Geometry2D.is_point_in_polygon(pt, poly):
            return true
    return false
