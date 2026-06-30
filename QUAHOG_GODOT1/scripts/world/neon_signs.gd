extends RefCounted
class_name NeonSigns

# Coastal-neon business signs (web NeonSigns.tsx parity).

const SIGNS: Array = [
    {"name": "THE ANVIL GARAGE", "pos": Vector3(-320.0, 0.0, -60.0), "color": Color(0.35, 0.82, 1.0)},
    {"name": "QUOHOG REPUBLIC", "pos": Vector3(-240.0, 0.0, -122.0), "color": Color(1.0, 0.31, 0.64)},
    {"name": "LINGUIÇA LINQ", "pos": Vector3(-300.0, 0.0, -92.0), "color": Color(0.35, 0.99, 1.0)},
    {"name": "MARÉ ALTA RECORDS", "pos": Vector3(-262.0, 0.0, -60.0), "color": Color(0.75, 0.55, 1.0)},
    {"name": "WHALE 92.1", "pos": Vector3(-200.0, 0.0, -95.0), "color": Color(1.0, 0.81, 0.29)},
    {"name": "WHALING CITY CAB", "pos": Vector3(-220.0, 0.0, -176.0), "color": Color(0.49, 0.99, 0.0)},
]


static func build(parent: Node3D) -> void :
    var root: = Node3D.new()
    root.name = "NeonSigns"
    parent.add_child(root)
    for spec in SIGNS:
        var pos: Vector3 = spec["pos"]
        var col: Color = spec["color"]
        var nm: String = str(spec["name"])
        var sign: = MeshInstance3D.new()
        var box: = BoxMesh.new()
        box.size = Vector3(5.0, 1.1, 0.3)
        sign.mesh = box
        var mat: = StandardMaterial3D.new()
        mat.albedo_color = col
        mat.emission_enabled = true
        mat.emission = col
        mat.emission_energy_multiplier = 0.25
        sign.material_override = mat
        sign.position = pos + Vector3(0, 4.6, 0)
        sign.add_to_group("neon_sign")
        root.add_child(sign)
        var lbl: = Label3D.new()
        lbl.text = nm
        lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        lbl.modulate = Color(0.1, 0.06, 0.12)
        lbl.font_size = 42
        lbl.pixel_size = 0.022
        lbl.position = pos + Vector3(0, 4.6, 0.2)
        root.add_child(lbl)
        var lamp: = OmniLight3D.new()
        lamp.light_color = col
        lamp.light_energy = 0.0
        lamp.omni_range = 20.0
        lamp.position = pos + Vector3(0, 4.2, 1.5)
        lamp.add_to_group("neon_light")
        root.add_child(lamp)
