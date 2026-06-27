extends RefCounted
class_name MapLoader

# Builds the real New Bedford map (the same data the web build ships) into Godot.
# Data lives under res://data/map: slice-newbedford.json (roads), tiles/b_X_Y.json
# (building footprints), overlays/*.json (land use). Coordinates are meters with
# x = east, y = north in the 2D arrays; in 3D we use x = east, z = -north, y = up
# (matching the web build's convention).

const MAP_DIR: = "res://data/map"
const TILE_M: = 500.0
const Y_GROUND: = 0.0
const Y_ROAD: = 0.04
const Y_OVERLAY: = 0.02
# Façade window texture tiled onto building walls (one repeat per ~4 m wide /
# ~3.2 m floor) so the real map reads as a windowed city, not flat boxes.
const FACADE_PATH: = "res://assets/textures/walls/facade_windows_dusk.png"
const WALL_TILE_U: = 4.0
const WALL_TILE_V: = 3.2
const ASPHALT_PATH: = "res://assets/textures/floors/wet_asphalt.png"
const ROAD_TILE: = 8.0  # metres per asphalt texture repeat (planar UV)

# Road half-widths and colors are derived from the OSM class.
const ROAD_COLORS: = {
    "motorway": Color(0.16, 0.16, 0.18), "trunk": Color(0.16, 0.16, 0.18),
    "primary": Color(0.20, 0.20, 0.22), "secondary": Color(0.22, 0.22, 0.24),
    "tertiary": Color(0.24, 0.24, 0.26), "residential": Color(0.26, 0.26, 0.28),
    "service": Color(0.28, 0.28, 0.30), "footway": Color(0.40, 0.37, 0.33),
}
const OVERLAY_COLORS: = {
    "parks": Color(0.22, 0.40, 0.20), "wood": Color(0.18, 0.34, 0.18),
    "cemetery": Color(0.26, 0.40, 0.26), "parking": Color(0.30, 0.30, 0.32),
    "beach": Color(0.78, 0.72, 0.52), "pier": Color(0.45, 0.36, 0.27),
}

# Stats for verification/logging.
var buildings_built: int = 0
var roads_built: int = 0
var overlays_built: int = 0
var named_places: Array = []  # [{name, pos}] from footprints that carry a name

# Spawn scaffolding derived from the road network so game_world can drive the
# real map the same way it drove the procedural CityBuilder (drop-in fields).
var player_spawn: Vector3 = Vector3(0, 0.6, 0)
var mission_giver_pos: Vector3 = Vector3(6, 0, 6)
var mission_giver_rot: float = 0.0
var car_slots: Array = []                  # [[Vector3 pos, float rot_y_deg], ...]
var light_slots: Array[Vector3] = []
var npc_waypoints: = PackedVector3Array()
var npc_spawns: Array[Vector3] = []
var job_points: Array[Vector3] = []
var _road_samples: Array = []              # [[Vector3 pos, float rot_y_deg], ...]
var _facade_tex: Texture2D = null
var _asphalt_tex: Texture2D = null


static func to_world(x_east: float, y_north: float, y_up: float = 0.0) -> Vector3:
    return Vector3(x_east, y_up, -y_north)


func _read_json(path: String) -> Variant:
    if not FileAccess.file_exists(path):
        return null
    var f: = FileAccess.open(path, FileAccess.READ)
    if f == null:
        return null
    var parsed: Variant = JSON.parse_string(f.get_as_text())
    return parsed


# Build the map for a square block of tiles around center_tile (in tile indices).
# radius_tiles = 3 → a 7x7 = up to 49-tile core around New Bedford's center.
func build_region(parent: Node3D, center_tile: Vector2i = Vector2i.ZERO, radius_tiles: int = 4) -> void :
    var bbox: = Rect2(
        (center_tile.x - radius_tiles) * TILE_M,
        (center_tile.y - radius_tiles) * TILE_M,
        (radius_tiles * 2 + 1) * TILE_M,
        (radius_tiles * 2 + 1) * TILE_M)
    if _facade_tex == null and ResourceLoader.exists(FACADE_PATH):
        _facade_tex = load(FACADE_PATH)
    if _asphalt_tex == null and ResourceLoader.exists(ASPHALT_PATH):
        _asphalt_tex = load(ASPHALT_PATH)
    _build_ground(parent, bbox)
    _build_overlays(parent, bbox)
    _build_roads(parent, bbox)
    _build_buildings(parent, center_tile, radius_tiles)
    _derive_spawns()


func _build_ground(parent: Node3D, bbox: Rect2) -> void :
    var plane: = PlaneMesh.new()
    plane.size = Vector2(bbox.size.x, bbox.size.y)
    var mat: = StandardMaterial3D.new()
    mat.albedo_color = Color(0.13, 0.14, 0.13)
    mat.roughness = 1.0
    plane.material = mat
    var mi: = MeshInstance3D.new()
    mi.name = "Ground"
    mi.mesh = plane
    var center: = to_world(bbox.position.x + bbox.size.x * 0.5, bbox.position.y + bbox.size.y * 0.5, Y_GROUND)
    mi.position = center
    parent.add_child(mi)
    # Flat collider so the player/cars stand on the world.
    var body: = StaticBody3D.new()
    body.name = "GroundBody"
    var col: = CollisionShape3D.new()
    var shape: = WorldBoundaryShape3D.new()
    shape.plane = Plane(Vector3.UP, Y_GROUND)
    col.shape = shape
    body.add_child(col)
    parent.add_child(body)


func _build_buildings(parent: Node3D, center_tile: Vector2i, radius_tiles: int) -> void :
    var root: = Node3D.new()
    root.name = "Buildings"
    parent.add_child(root)
    for tx in range(center_tile.x - radius_tiles, center_tile.x + radius_tiles + 1):
        for ty in range(center_tile.y - radius_tiles, center_tile.y + radius_tiles + 1):
            var path: = "%s/tiles/b_%d_%d.json" % [MAP_DIR, tx, ty]
            var data: Variant = _read_json(path)
            if data == null or not (data is Array):
                continue
            _build_tile(root, data, tx, ty)


func _build_tile(root: Node3D, buildings: Array, tx: int, ty: int) -> void :
    var st: = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var faces: = PackedVector3Array()
    var any: = false
    for b in buildings:
        if not (b is Dictionary):
            continue
        var fp: Variant = b.get("footprint")
        if not (fp is Array) or fp.size() < 3:
            continue
        var h: float = float(b.get("height", 8.0))
        _emit_building(st, faces, fp, h)
        buildings_built += 1
        any = true
        if b.has("name"):
            var c: = _centroid(fp)
            named_places.append({"name": b["name"], "pos": to_world(c.x, c.y, h)})
    if not any:
        return
    st.generate_normals()
    var mat: = StandardMaterial3D.new()
    mat.vertex_color_use_as_albedo = true
    mat.roughness = 0.92
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    if _facade_tex:
        mat.albedo_texture = _facade_tex
        mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    st.set_material(mat)
    var mi: = MeshInstance3D.new()
    mi.name = "Tile_%d_%d" % [tx, ty]
    mi.mesh = st.commit()
    root.add_child(mi)
    # Trimesh collider for the whole tile's walls/roofs.
    var body: = StaticBody3D.new()
    var col: = CollisionShape3D.new()
    var shape: = ConcavePolygonShape3D.new()
    shape.set_faces(faces)
    col.shape = shape
    body.add_child(col)
    mi.add_child(body)


func _emit_building(st: SurfaceTool, faces: PackedVector3Array, fp: Array, h: float) -> void :
    # Per-building tint by height tier, with deterministic variety inside each tier
    # so the streetscape reads as mixed eras (granite civic / brick mills / painted
    # triple-deckers) instead of three flat tones. Seed from the footprint so a
    # given building always paints the same colour (no flicker).
    var seed_i: int = int(absf(float(fp[0][0]) * 73856.0 + float(fp[0][1]) * 19349.0))
    var palette: Array
    if h >= 24.0:
        palette = [Color(0.52, 0.53, 0.55), Color(0.49, 0.50, 0.52), Color(0.56, 0.56, 0.55), Color(0.47, 0.48, 0.50)]
    elif h >= 13.0:
        palette = [Color(0.45, 0.27, 0.22), Color(0.50, 0.26, 0.20), Color(0.39, 0.28, 0.25), Color(0.55, 0.43, 0.33), Color(0.44, 0.40, 0.40)]
    else:
        palette = [Color(0.58, 0.50, 0.42), Color(0.80, 0.78, 0.72), Color(0.55, 0.60, 0.62), Color(0.46, 0.53, 0.44), Color(0.74, 0.68, 0.47), Color(0.57, 0.34, 0.30), Color(0.60, 0.60, 0.58)]
    var col: Color = palette[seed_i % palette.size()]

    var n: = fp.size()
    var poly2: = PackedVector2Array()
    for p in fp:
        poly2.append(Vector2(float(p[0]), float(p[1])))

    # Roof cap (triangulated footprint at y = h). UV pinned to a single texel so
    # the roof reads as a flat tone (no window grid up top).
    var tri: = Geometry2D.triangulate_polygon(poly2)
    var roof_col: = col.lightened(0.08)
    for i in range(0, tri.size(), 3):
        for k in range(3):
            var v2: = poly2[tri[i + k]]
            var v: = to_world(v2.x, v2.y, h)
            st.set_color(roof_col)
            st.set_uv(Vector2(0.05, 0.05))
            st.add_vertex(v)
            faces.append(v)

    # Walls (extrude each edge from ground to roof) with window-grid UVs that
    # tile by wall length and floor height.
    var vmax: = h / WALL_TILE_V
    for i in range(n):
        var a2: = poly2[i]
        var b2: = poly2[(i + 1) % n]
        var umax: = a2.distance_to(b2) / WALL_TILE_U
        var a0: = to_world(a2.x, a2.y, Y_GROUND)
        var b0: = to_world(b2.x, b2.y, Y_GROUND)
        var a1: = to_world(a2.x, a2.y, h)
        var b1: = to_world(b2.x, b2.y, h)
        # Two triangles: a0,b0,b1 and a0,b1,a1
        var verts: = [a0, b0, b1, a0, b1, a1]
        var uvs: = [
            Vector2(0.0, vmax), Vector2(umax, vmax), Vector2(umax, 0.0),
            Vector2(0.0, vmax), Vector2(umax, 0.0), Vector2(0.0, 0.0),
        ]
        for j in verts.size():
            st.set_color(col)
            st.set_uv(uvs[j])
            st.add_vertex(verts[j])
            faces.append(verts[j])


func _build_roads(parent: Node3D, bbox: Rect2) -> void :
    var slice: Variant = _read_json("%s/slice-newbedford.json" % MAP_DIR)
    if slice == null or not (slice is Dictionary):
        return
    var roads: Variant = slice.get("roads", [])
    if not (roads is Array):
        return
    var st: = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for r in roads:
        if not (r is Dictionary):
            continue
        var pts: Variant = r.get("points")
        if not (pts is Array) or pts.size() < 2:
            continue
        # Cull by bbox using the first point (roads are short relative to the region).
        var p0: Vector2 = Vector2(float(pts[0][0]), float(pts[0][1]))
        if not bbox.has_point(p0):
            continue
        var hw: String = str(r.get("highway", "residential"))
        var width: float = float(r.get("width", 6.0))
        var rcol: Color = ROAD_COLORS.get(hw, Color(0.27, 0.27, 0.29))
        _emit_road(st, pts, width * 0.5, rcol)
        roads_built += 1
        # Sample the first segment for spawn scaffolding (pos + heading).
        var a0: = Vector2(float(pts[0][0]), float(pts[0][1]))
        var b0: = Vector2(float(pts[1][0]), float(pts[1][1]))
        var mid: = (a0 + b0) * 0.5
        var wdir: = Vector3(b0.x - a0.x, 0.0, -(b0.y - a0.y))
        var roty: = 0.0
        if wdir.length_squared() > 0.0001:
            roty = rad_to_deg(atan2(wdir.x, wdir.z))
        _road_samples.append([to_world(mid.x, mid.y, 0.0), roty])
    st.generate_normals()
    var mat: = StandardMaterial3D.new()
    mat.vertex_color_use_as_albedo = true
    mat.roughness = 0.95
    if _asphalt_tex:
        mat.albedo_texture = _asphalt_tex
        mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    st.set_material(mat)
    var mi: = MeshInstance3D.new()
    mi.name = "Roads"
    mi.mesh = st.commit()
    parent.add_child(mi)


func _emit_road(st: SurfaceTool, pts: Array, half: float, col: Color) -> void :
    for i in range(pts.size() - 1):
        var a: = Vector2(float(pts[i][0]), float(pts[i][1]))
        var b: = Vector2(float(pts[i + 1][0]), float(pts[i + 1][1]))
        var dir: = (b - a)
        if dir.length_squared() < 0.0001:
            continue
        dir = dir.normalized()
        var perp: = Vector2(-dir.y, dir.x) * half
        var a_l: = a + perp
        var a_r: = a - perp
        var b_l: = b + perp
        var b_r: = b - perp
        var va_l: = to_world(a_l.x, a_l.y, Y_ROAD)
        var va_r: = to_world(a_r.x, a_r.y, Y_ROAD)
        var vb_l: = to_world(b_l.x, b_l.y, Y_ROAD)
        var vb_r: = to_world(b_r.x, b_r.y, Y_ROAD)
        for v in [va_l, va_r, vb_r, va_l, vb_r, vb_l]:
            st.set_color(col)
            st.set_uv(Vector2(v.x / ROAD_TILE, v.z / ROAD_TILE))
            st.add_vertex(v)


func _build_overlays(parent: Node3D, bbox: Rect2) -> void :
    var root: = Node3D.new()
    root.name = "LandUse"
    parent.add_child(root)
    for key in OVERLAY_COLORS.keys():
        var path: = "%s/overlays/%s.json" % [MAP_DIR, key]
        var data: Variant = _read_json(path)
        if data == null or not (data is Array):
            continue
        var st: = SurfaceTool.new()
        st.begin(Mesh.PRIMITIVE_TRIANGLES)
        var col: Color = OVERLAY_COLORS[key]
        var any: = false
        for ring in data:
            if not (ring is Array) or ring.size() < 3:
                continue
            var poly2: = PackedVector2Array()
            for p in ring:
                poly2.append(Vector2(float(p[0]), float(p[1])))
            if not bbox.has_point(poly2[0]):
                continue
            var tri: = Geometry2D.triangulate_polygon(poly2)
            if tri.is_empty():
                continue
            for i in tri:
                st.set_color(col)
                st.add_vertex(to_world(poly2[i].x, poly2[i].y, Y_OVERLAY))
            any = true
            overlays_built += 1
        if not any:
            continue
        st.generate_normals()
        var mat: = StandardMaterial3D.new()
        mat.vertex_color_use_as_albedo = true
        mat.roughness = 1.0
        st.set_material(mat)
        var mi: = MeshInstance3D.new()
        mi.name = "Overlay_%s" % key
        mi.mesh = st.commit()
        root.add_child(mi)


# Derive player/NPC/car/light spawn points from the sampled road network so the
# real map is a drop-in for the procedural CityBuilder's spawn fields.
func _derive_spawns() -> void :
    if _road_samples.is_empty():
        return
    # Player spawns on the road nearest the map origin (the NB core).
    var best: = 0
    var best_d: = INF
    for i in _road_samples.size():
        var p: Vector3 = _road_samples[i][0]
        var d: = p.x * p.x + p.z * p.z
        if d < best_d:
            best_d = d
            best = i
    var sp: Vector3 = _road_samples[best][0]
    player_spawn = Vector3(sp.x, 0.6, sp.z)
    mission_giver_pos = player_spawn + Vector3(6, 0, 6)
    mission_giver_rot = _road_samples[best][1]

    var n: = _road_samples.size()
    var step: int = max(1, int(n / 240.0))
    var i2: = 0
    while i2 < n:
        var s: Array = _road_samples[i2]
        var pos: Vector3 = s[0]
        npc_waypoints.append(pos)
        if car_slots.size() < 40:
            car_slots.append([Vector3(pos.x, 0.0, pos.z), float(s[1])])
        if light_slots.size() < 60:
            light_slots.append(Vector3(pos.x, 0.0, pos.z))
        if npc_spawns.size() < 30:
            npc_spawns.append(Vector3(pos.x, 0.6, pos.z))
        i2 += step

    for pl in named_places:
        if job_points.size() >= 30:
            break
        var pp: Vector3 = pl["pos"]
        job_points.append(Vector3(pp.x, 0.5, pp.z))
    if job_points.is_empty():
        for s2 in _road_samples:
            if job_points.size() >= 20:
                break
            var p3: Vector3 = s2[0]
            job_points.append(Vector3(p3.x, 0.5, p3.z))


func _centroid(fp: Array) -> Vector2:
    var c: = Vector2.ZERO
    for p in fp:
        c += Vector2(float(p[0]), float(p[1]))
    return c / float(fp.size())
