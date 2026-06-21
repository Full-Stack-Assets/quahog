## MapMeshBaker.gd
## res://scripts/world/MapMeshBaker.gd
## Bakes the real-world South Coast street grid (New Bedford + Fall River) into
## an ArrayMesh at runtime from the OpenStreetMap-derived road graph.
## Reads res://data/southcoast-roads.json (origin-relative meters, x=east /
## z=north / y=up) and extrudes each road centerline into a flat ribbon whose
## width comes from its OSM highway class.
## Map data © OpenStreetMap contributors, ODbL.
## Project QUAHOG / Godot 4

@tool
extends Node3D

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------

## Road graph produced by quahog-project-files/mapdata/bake_meshes.py.
@export_file("*.json") var road_graph_path: String = "res://data/southcoast-roads.json"

## Material applied to the baked road mesh. If null, a neon-tinted default is used.
@export var road_material: Material

## Build the mesh as soon as the node enters the tree.
@export var bake_on_ready: bool = true

## Re-bake now (toggle in the inspector while running with @tool).
@export var bake_now: bool = false:
	set(value):
		if value:
			bake()

# ---------------------------------------------------------------------------
# Internals
# ---------------------------------------------------------------------------

var _mesh_instance: MeshInstance3D

func _ready() -> void:
	if bake_on_ready:
		bake()

## Loads the road graph and (re)builds the road ribbon mesh.
func bake() -> void:
	var data := _load_graph()
	if data.is_empty():
		return

	var st := SurfaceTool.new()
	st.begin(Mesh.PrimitiveType.PRIMITIVE_TRIANGLES)

	var roads: Array = data.get("roads", [])
	for road in roads:
		_add_ribbon(st, road)

	st.generate_normals()
	var mesh := st.commit()

	if _mesh_instance == null:
		_mesh_instance = MeshInstance3D.new()
		_mesh_instance.name = "BakedRoads"
		add_child(_mesh_instance)
		if Engine.is_editor_hint() and get_tree() != null:
			_mesh_instance.owner = get_tree().edited_scene_root
	_mesh_instance.mesh = mesh
	_mesh_instance.material_override = road_material if road_material else _default_material()

	print("[MapMeshBaker] baked %d roads (%d vertices)" % [roads.size(), mesh.surface_get_array_len(0)])

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _load_graph() -> Dictionary:
	if not FileAccess.file_exists(road_graph_path):
		push_error("[MapMeshBaker] road graph not found: %s" % road_graph_path)
		return {}
	var text := FileAccess.get_file_as_string(road_graph_path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("[MapMeshBaker] could not parse road graph JSON")
		return {}
	return parsed

## Extrudes one road's centerline into per-segment quads (two triangles each).
func _add_ribbon(st: SurfaceTool, road: Dictionary) -> void:
	var pts: Array = road.get("points", [])
	if pts.size() < 2:
		return
	var half: float = float(road.get("width", 6.0)) * 0.5

	for i in range(pts.size() - 1):
		var a := Vector3(pts[i][0], 0.0, pts[i][1])
		var b := Vector3(pts[i + 1][0], 0.0, pts[i + 1][1])
		var dir := b - a
		var length := dir.length()
		if length < 0.001:
			continue
		dir /= length
		# perpendicular in the ground plane
		var n := Vector3(-dir.z, 0.0, dir.x) * half
		var p1 := a + n
		var p2 := b + n
		var p3 := b - n
		var p4 := a - n
		# two triangles, wound for an upward-facing normal
		_tri(st, p1, p2, p3)
		_tri(st, p1, p3, p4)

func _tri(st: SurfaceTool, x: Vector3, y: Vector3, z: Vector3) -> void:
	st.add_vertex(x)
	st.add_vertex(y)
	st.add_vertex(z)

func _default_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.06, 0.06, 0.10)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.24, 0.66)   # Vice City neon pink
	m.emission_energy_multiplier = 0.15
	m.roughness = 0.7
	return m
