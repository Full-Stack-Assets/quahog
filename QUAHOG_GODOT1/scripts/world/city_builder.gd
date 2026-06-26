extends RefCounted
class_name CityBuilder













const ROAD_HALF: = 4.5
const GRID: = [-116.0, -58.0, 0.0, 58.0, 116.0]
const EXTENT: = 132.0
const FRONT: = 11.0
const STEP: = 15.0
const CLEAR: = 9.0
const PLAZA: = 34.0
const SW: = 7.0
const FLOOR_W: = 3.4
const FLOOR_H: = 3.4
const BOUND: = 150.0
const Y_ROAD: = 0.03
const Y_PAD: = 0.06


const LANDMARKS: = [
    ["res://assets/environment/buildings/diner.glb", 5.5], 
    ["res://assets/environment/buildings/corner_store.glb", 8.0], 
    ["res://assets/environment/buildings/pawn_shop.glb", 7.5], 
    ["res://assets/environment/buildings/brick_mill.glb", 14.0], 
    ["res://assets/environment/buildings/civic_building.glb", 10.0], 
    ["res://assets/environment/buildings/triple_decker.glb", 10.5], 
]

var _parent: Node3D
var _rng: = RandomNumberGenerator.new()
var _tex: = {}


var _st_brick: SurfaceTool
var _st_concrete: SurfaceTool
var _st_store: SurfaceTool


var npc_waypoints: = PackedVector3Array()
var npc_spawns: Array[Vector3] = []
var car_slots: Array = []
var light_slots: Array[Vector3] = []
var player_spawn: = Vector3(8.0, 0.6, 8.0)
var mission_giver_pos: = Vector3(12.0, 0.0, 14.0)
var mission_giver_rot: = 200.0


func build(parent: Node3D, textures: Dictionary) -> void :
    _parent = parent
    _tex = textures
    _rng.seed = 99173

    _build_roads_and_pads()
    _begin_facades()
    _build_terraces()
    _commit_facades()
    _place_landmarks()
    _make_bounds()
    _make_backdrop()
    _collect_actor_slots()



func _build_roads_and_pads() -> void :
    var st_road: = SurfaceTool.new()
    st_road.begin(Mesh.PRIMITIVE_TRIANGLES)
    var rlen: = (EXTENT + 20.0) * 2.0
    for g in GRID:
        var gz: float = g
        _flat_quad(st_road, Vector3(0, Y_ROAD, gz), rlen, ROAD_HALF * 2.0, 6.0)
        var gx: float = g
        _flat_quad(st_road, Vector3(gx, Y_ROAD, 0), ROAD_HALF * 2.0, rlen, 6.0)
    _finish_mesh(st_road, _tex.get("asphalt"), Vector3(0.22, 0.23, 0.25), 0.4, 0.15, "Roads")

    var st_pad: = SurfaceTool.new()
    st_pad.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(GRID.size() - 1):
        for j in range(GRID.size() - 1):
            var cx: float = (GRID[i] + GRID[i + 1]) * 0.5
            var cz: float = (GRID[j] + GRID[j + 1]) * 0.5
            var sx: float = (GRID[i + 1] - GRID[i]) - ROAD_HALF * 2.0
            var sz: float = (GRID[j + 1] - GRID[j]) - ROAD_HALF * 2.0
            _flat_quad(st_pad, Vector3(cx, Y_PAD, cz), sx, sz, 3.0)
    _finish_mesh(st_pad, _tex.get("concrete"), Vector3(0.42, 0.42, 0.44), 0.9, 0.0, "Sidewalks")



func _begin_facades() -> void :
    _st_brick = SurfaceTool.new()
    _st_brick.begin(Mesh.PRIMITIVE_TRIANGLES)
    _st_concrete = SurfaceTool.new()
    _st_concrete.begin(Mesh.PRIMITIVE_TRIANGLES)
    _st_store = SurfaceTool.new()
    _st_store.begin(Mesh.PRIMITIVE_TRIANGLES)


func _commit_facades() -> void :
    _finish_mesh(_st_brick, _tex.get("brick"), Vector3(1, 1, 1), 0.9, 0.0, "BrickBuildings", true, _tex.get("brick"), 0.16)
    _finish_mesh(_st_concrete, _tex.get("concrete_office"), Vector3(1, 1, 1), 0.8, 0.05, "ConcreteBuildings", true, _tex.get("concrete_office"), 0.1)
    _finish_mesh(_st_store, _tex.get("storefront"), Vector3(1, 1, 1), 0.7, 0.0, "Storefronts", true, _tex.get("storefront"), 0.55)


func _build_terraces() -> void :


    for g in GRID:
        var line: float = g

        for s in [1.0, -1.0]:
            _terrace_row(true, line, s)

        for s2 in [1.0, -1.0]:
            _terrace_row(false, line, s2)


func _terrace_row(horizontal: bool, line: float, side: float) -> void :
    var along: float = - EXTENT
    while along <= EXTENT:

        var width: float = _rng.randf_range(9.0, 15.0)
        var pos_along: = along + width * 0.5
        along += width + _rng.randf_range(0.6, 2.0)
        if absf(pos_along) > EXTENT:
            continue

        var skip: = false
        for cg in GRID:
            if absf(pos_along - cg) < CLEAR:
                skip = true
                break
        if skip:
            continue

        var depth: float = _rng.randf_range(9.0, 13.0)
        var face_off: float = FRONT + depth * 0.5
        var center: Vector3
        var face_dir: Vector3
        if horizontal:
            center = Vector3(pos_along, 0, line + side * face_off)
            face_dir = Vector3(0, 0, - side)
        else:
            center = Vector3(line + side * face_off, 0, pos_along)
            face_dir = Vector3( - side, 0, 0)

        if center.length() < PLAZA:
            continue

        if absf(center.x) > BOUND - 6.0 or absf(center.z) > BOUND - 6.0:
            continue

        _emit_building(center, width, depth, face_dir)


func _emit_building(center: Vector3, width: float, depth: float, face_dir: Vector3) -> void :

    var dist: float = center.length()
    var tall: float = clampf(1.0 - dist / 150.0, 0.0, 1.0)
    var height: float = _rng.randf_range(8.0, 12.0) + tall * _rng.randf_range(4.0, 20.0)
    var office: bool = height > 17.0 or _rng.randf() < 0.25
    var st: = _st_concrete if office else _st_brick

    var tint: Color
    if office:
        var g: float = _rng.randf_range(0.55, 0.8)
        tint = Color(g, g, g * 1.02)
    else:
        tint = Color(_rng.randf_range(0.6, 0.95), _rng.randf_range(0.4, 0.62), _rng.randf_range(0.32, 0.5))

    _add_box(st, center, Vector3(width, height, depth), tint, face_dir, not office)
    _add_collider(center, Vector3(width, height, depth))



func _add_box(st: SurfaceTool, base: Vector3, size: Vector3, col: Color, face_dir: Vector3, shopfront: bool) -> void :
    var hw: float = size.x * 0.5
    var hd: float = size.z * 0.5
    var h: float = size.y
    var corners: = [
        base + Vector3( - hw, 0, - hd), 
        base + Vector3(hw, 0, - hd), 
        base + Vector3(hw, 0, hd), 
        base + Vector3( - hw, 0, hd), 
    ]
    for i in 4:
        var a: Vector3 = corners[i]
        var b: Vector3 = corners[(i + 1) % 4]
        var n: Vector3 = Vector3.UP.cross(b - a).normalized()
        _wall(st, a, b, h, col, 0.0)
        if shopfront and n.dot(face_dir) > 0.6:
            _wall(_st_store, a + n * 0.02, b + n * 0.02, 3.2, Color(1, 1, 1), -1.0)

    var y1: float = base.y + h
    var r0: Vector3 = base + Vector3( - hw, h, - hd)
    var r1: Vector3 = base + Vector3(hw, h, - hd)
    var r2: Vector3 = base + Vector3(hw, h, hd)
    var r3: Vector3 = base + Vector3( - hw, h, hd)
    var roof: = Color(0.12, 0.12, 0.14)
    _tri(st, r0, r2, r1, Vector3.UP, Vector2(0, 0), Vector2(1, 1), Vector2(1, 0), roof)
    _tri(st, r0, r3, r2, Vector3.UP, Vector2(0, 0), Vector2(0, 1), Vector2(1, 1), roof)


func _wall(st: SurfaceTool, a: Vector3, b: Vector3, h: float, col: Color, vmode: float) -> void :

    var length: float = a.distance_to(b)
    var u: float = length / FLOOR_W
    var v: float = (1.0 if vmode < 0.0 else h / FLOOR_H)
    var n: Vector3 = Vector3.UP.cross(b - a).normalized()
    var a0: Vector3 = a
    var b0: Vector3 = b
    var a1: Vector3 = a + Vector3.UP * h
    var b1: Vector3 = b + Vector3.UP * h
    _tri(st, a0, b1, b0, n, Vector2(0, v), Vector2(u, 0), Vector2(u, v), col)
    _tri(st, a0, a1, b1, n, Vector2(0, v), Vector2(0, 0), Vector2(u, 0), col)


func _tri(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, n: Vector3, uv0: Vector2, uv1: Vector2, uv2: Vector2, col: Color) -> void :
    st.set_normal(n)
    st.set_color(col)
    st.set_uv(uv0);st.add_vertex(p0)
    st.set_uv(uv1);st.add_vertex(p1)
    st.set_uv(uv2);st.add_vertex(p2)


func _flat_quad(st: SurfaceTool, center: Vector3, sx: float, sz: float, uv_div: float) -> void :
    var hx: float = sx * 0.5
    var hz: float = sz * 0.5
    var u: float = sx / uv_div
    var v: float = sz / uv_div
    var p0: Vector3 = center + Vector3( - hx, 0, - hz)
    var p1: Vector3 = center + Vector3(hx, 0, - hz)
    var p2: Vector3 = center + Vector3(hx, 0, hz)
    var p3: Vector3 = center + Vector3( - hx, 0, hz)
    var w: = Color(1, 1, 1)
    _tri(st, p0, p2, p1, Vector3.UP, Vector2(0, 0), Vector2(u, v), Vector2(u, 0), w)
    _tri(st, p0, p3, p2, Vector3.UP, Vector2(0, 0), Vector2(0, v), Vector2(u, v), w)


func _finish_mesh(st: SurfaceTool, tex, base_col: Vector3, rough: float, metal: float, name: String, vcol: = false, emit_tex = null, emit_energy: = 0.0) -> void :
    var mat: = StandardMaterial3D.new()
    mat.albedo_color = Color(base_col.x, base_col.y, base_col.z)
    if tex:
        mat.albedo_texture = tex
    mat.roughness = rough
    mat.metallic = metal
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    if vcol:
        mat.vertex_color_use_as_albedo = true
    if emit_tex and emit_energy > 0.0:
        mat.emission_enabled = true
        mat.emission_texture = emit_tex
        mat.emission_energy_multiplier = emit_energy
    st.set_material(mat)
    var mesh: = st.commit()
    var mi: = MeshInstance3D.new()
    mi.name = name
    mi.mesh = mesh
    mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    _parent.add_child(mi)


func _add_collider(center: Vector3, size: Vector3) -> void :
    var body: = StaticBody3D.new()
    body.collision_layer = 1
    body.collision_mask = 0
    body.position = center + Vector3(0, size.y * 0.5, 0)
    _parent.add_child(body)
    var col: = CollisionShape3D.new()
    var shape: = BoxShape3D.new()
    shape.size = size
    col.shape = shape
    body.add_child(col)



func _place_landmarks() -> void :

    var ring: = PLAZA + 8.0
    var slots: = [
        [Vector3(ring, 0, 0), -90.0, 0], 
        [Vector3( - ring, 0, 0), 90.0, 1], 
        [Vector3(0, 0, ring), 180.0, 2], 
        [Vector3(0, 0, - ring), 0.0, 3], 
        [Vector3(ring * 0.72, 0, ring * 0.72), -135.0, 4], 
        [Vector3( - ring * 0.72, 0, - ring * 0.72), 45.0, 5], 
    ]
    for s in slots:
        var spec = LANDMARKS[int(s[2])]
        var scene: = load(spec[0]) as PackedScene
        if scene == null:
            continue
        var inst: = scene.instantiate()
        _parent.add_child(inst)
        inst.position = s[0]
        inst.rotation_degrees.y = s[1]
        ModelUtils.scale_to_height(inst, spec[1])
        ModelUtils.ground_model(inst, 0.0)
        ModelUtils.add_per_part_convex_collision(inst, 1)



func _make_bounds() -> void :
    var walls: = [
        [Vector3(0, 6, BOUND), Vector3(BOUND * 2.0, 12, 1)], 
        [Vector3(0, 6, - BOUND), Vector3(BOUND * 2.0, 12, 1)], 
        [Vector3(BOUND, 6, 0), Vector3(1, 12, BOUND * 2.0)], 
        [Vector3( - BOUND, 6, 0), Vector3(1, 12, BOUND * 2.0)], 
    ]
    for w in walls:
        var body: = StaticBody3D.new()
        body.collision_layer = 1
        body.collision_mask = 0
        body.position = w[0]
        _parent.add_child(body)
        var col: = CollisionShape3D.new()
        var shape: = BoxShape3D.new()
        shape.size = w[1]
        col.shape = shape
        body.add_child(col)


func _make_backdrop() -> void :
    var mm: = MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    var box: = BoxMesh.new()
    box.size = Vector3(1, 1, 1)
    mm.mesh = box
    var transforms: Array[Transform3D] = []
    for ring in [0, 1, 2]:
        var off: float = BOUND + 18.0 + float(ring) * 26.0
        var step: = 22.0
        var x: float = - off
        while x <= off:
            _backdrop_at(transforms, Vector3(x, 0, off))
            _backdrop_at(transforms, Vector3(x, 0, - off))
            x += step
        var z: float = - off
        while z <= off:
            _backdrop_at(transforms, Vector3(off, 0, z))
            _backdrop_at(transforms, Vector3( - off, 0, z))
            z += step
    mm.instance_count = transforms.size()
    for i in transforms.size():
        mm.set_instance_transform(i, transforms[i])
    var mmi: = MultiMeshInstance3D.new()
    mmi.name = "Backdrop"
    mmi.multimesh = mm
    mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    var mat: = StandardMaterial3D.new()
    mat.albedo_color = Color(0.11, 0.12, 0.16)
    mat.roughness = 1.0
    mmi.material_override = mat
    _parent.add_child(mmi)


func _backdrop_at(arr: Array[Transform3D], base: Vector3) -> void :
    var h: float = _rng.randf_range(14.0, 40.0)
    var w: float = _rng.randf_range(10.0, 22.0)
    var d: float = _rng.randf_range(10.0, 22.0)
    var jitter: = Vector3(_rng.randf_range(-7, 7), 0, _rng.randf_range(-7, 7))
    arr.append(Transform3D(Basis().scaled(Vector3(w, h, d)), base + jitter + Vector3(0, h * 0.5, 0)))



func _collect_actor_slots() -> void :

    var inner: = [GRID[1], GRID[2], GRID[3]]
    for g in inner:
        var line: float = g
        for s in [SW, - SW]:
            npc_waypoints.append(Vector3( - EXTENT * 0.6, 0.2, line + s))
            npc_waypoints.append(Vector3(EXTENT * 0.6, 0.2, line + s))
            npc_waypoints.append(Vector3(line + s, 0.2, - EXTENT * 0.6))
            npc_waypoints.append(Vector3(line + s, 0.2, EXTENT * 0.6))
    var sp: = [
        Vector3(GRID[2] + SW, 0.4, -22), Vector3(GRID[2] - SW, 0.4, 26), 
        Vector3(-20, 0.4, GRID[2] + SW), Vector3(28, 0.4, GRID[2] - SW), 
        Vector3(GRID[1] + SW, 0.4, 14), Vector3(GRID[3] - SW, 0.4, -16), 
        Vector3(-44, 0.4, GRID[1] + SW), Vector3(48, 0.4, GRID[3] - SW), 
    ]
    for v in sp:
        npc_spawns.append(v)


    var curb: float = ROAD_HALF + 1.6
    var car_lines: = [GRID[1], GRID[2], GRID[3]]
    var xs: = [-86.0, -42.0, 42.0, 86.0]
    for g in car_lines:
        var line: float = g
        for x in xs:
            if absf(x) < PLAZA:
                continue
            car_slots.append([Vector3(x, 0, line - curb), 90.0])
            car_slots.append([Vector3(line + curb, 0, x), 0.0])


    for gx in [GRID[1], GRID[2], GRID[3]]:
        for gz in [GRID[1], GRID[2], GRID[3]]:
            light_slots.append(Vector3(gx + SW, 0, gz + SW))
