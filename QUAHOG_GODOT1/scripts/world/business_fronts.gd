extends Node3D

# Buyable business fronts — gold rings downtown, green when owned; rest heals + bleeds heat.

const RADIUS: float = 7.0

var _rings: Array[MeshInstance3D] = []
var _resting_index: int = -1
var _player: Node = null


func setup(player: Node) -> void:
	_player = player
	_build_fronts()


func _build_fronts() -> void:
	if BusinessManager == null:
		return
	for i in BusinessManager.BUSINESSES.size():
		var b: Dictionary = BusinessManager.BUSINESSES[i]
		var pos: Vector3 = b["pos"]
		var root: = Node3D.new()
		root.position = pos
		add_child(root)

		var ring: = MeshInstance3D.new()
		var torus: = TorusMesh.new()
		torus.inner_radius = RADIUS - 0.6
		torus.outer_radius = RADIUS
		ring.mesh = torus
		ring.rotation.x = PI / 2.0
		ring.position.y = 0.15
		var mat: = StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(1.0, 0.81, 0.29, 0.5)
		ring.material_override = mat
		root.add_child(ring)
		_rings.append(ring)

		var pole: = MeshInstance3D.new()
		var box: = BoxMesh.new()
		box.size = Vector3(0.2, 6.0, 0.2)
		pole.mesh = box
		pole.position = Vector3(0.0, 3.2, 0.0)
		var pole_mat: = StandardMaterial3D.new()
		pole_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		pole_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		pole_mat.albedo_color = Color(1.0, 0.81, 0.29, 0.25)
		pole.material_override = pole_mat
		root.add_child(pole)

		var lbl: = Label3D.new()
		lbl.text = str(b["name"])
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.modulate = Color(1.0, 1.0, 1.0)
		lbl.font_size = 36
		lbl.pixel_size = 0.022
		lbl.position = Vector3(0.0, 6.6, 0.0)
		root.add_child(lbl)

	_update_ring_colors()


func _physics_process(delta: float) -> void:
	if BusinessManager == null or _player == null or not is_instance_valid(_player):
		return
	if "_driving" in _player and _player._driving:
		BusinessManager.set_near_buy(-1)
		_resting_index = -1
		return

	var pp: Vector3 = _player.global_position
	var near_buy: int = -1
	var near_rest: int = -1
	for i in BusinessManager.BUSINESSES.size():
		var b: Dictionary = BusinessManager.BUSINESSES[i]
		var pos: Vector3 = b["pos"]
		if Vector2(pp.x - pos.x, pp.z - pos.z).length() > RADIUS:
			continue
		if BusinessManager.is_owned(i):
			near_rest = i
		else:
			near_buy = i

	BusinessManager.set_near_buy(near_buy)

	if near_rest >= 0:
		if _resting_index != near_rest:
			_resting_index = near_rest
			var nm: String = str(BusinessManager.BUSINESSES[near_rest]["name"])
			GameManager.show_message("Resting at %s — patching up" % nm)
		if "health" in _player and "max_health" in _player:
			_player.health = minf(_player.max_health, _player.health + delta * 12.0)
		if GameManager.wanted_level > 0 and randf() < delta * 0.25:
			GameManager.set_wanted(GameManager.wanted_level - 1)
		if GameManager.faction_level > 0 and randf() < delta * 0.25:
			GameManager.set_faction(GameManager.faction_level - 1)
	else:
		_resting_index = -1

	if near_buy >= 0 and Input.is_action_just_pressed("buy_business"):
		BusinessManager.try_buy(near_buy)
		_update_ring_colors()


func _update_ring_colors() -> void:
	if BusinessManager == null:
		return
	for i in _rings.size():
		var ring: MeshInstance3D = _rings[i]
		if ring == null:
			continue
		var mat: StandardMaterial3D = ring.material_override as StandardMaterial3D
		if mat == null:
			continue
		if BusinessManager.is_owned(i):
			mat.albedo_color = Color(0.29, 0.84, 0.43, 0.5)
		else:
			mat.albedo_color = Color(1.0, 0.81, 0.29, 0.5)


func on_owned_changed(_count: int) -> void:
	_update_ring_colors()
