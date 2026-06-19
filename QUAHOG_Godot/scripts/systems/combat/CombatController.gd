# CombatController.gd
# res://scripts/systems/combat/CombatController.gd
extends Node3D

# ---------------------------------------------------------------------------
# Weapon enum
# ---------------------------------------------------------------------------
enum Weapon {
	UNARMED,
	PISTOL,
	SHOTGUN,
	SMG,
	RIFLE
}

# ---------------------------------------------------------------------------
# Ammo exports
# ---------------------------------------------------------------------------
@export var ammo_unarmed: int = 0
@export var ammo_pistol: int = 60
@export var ammo_shotgun: int = 24
@export var ammo_smg: int = 120
@export var ammo_rifle: int = 90

# ---------------------------------------------------------------------------
# Behaviour exports
# ---------------------------------------------------------------------------
@export var reload_duration: float = 1.5
@export var aim_fov: float = 40.0
@export var normal_fov: float = 60.0

# ---------------------------------------------------------------------------
# Raycast / damage parameters
# ---------------------------------------------------------------------------
@export var fire_range: float = 200.0

# Ammo consumed per shot
const AMMO_PER_SHOT: Dictionary = {
	Weapon.UNARMED:  0,
	Weapon.PISTOL:   1,
	Weapon.SHOTGUN:  1,
	Weapon.SMG:      1,
	Weapon.RIFLE:    1,
}

# Max ammo caps
const MAX_AMMO: Dictionary = {
	Weapon.UNARMED:  0,
	Weapon.PISTOL:   120,
	Weapon.SHOTGUN:  48,
	Weapon.SMG:      240,
	Weapon.RIFLE:    180,
}

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var is_aiming: bool = false
var current_weapon: int = Weapon.UNARMED
var is_reloading: bool = false

# Runtime ammo table (mirrored from @export values in _ready)
var _ammo: Dictionary = {}

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal weapon_changed(weapon: int)
signal fired(weapon: int, hit_position: Vector3)
signal ammo_changed(current: int, max_ammo: int)
signal reloaded(weapon: int)

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
	_ammo = {
		Weapon.UNARMED:  ammo_unarmed,
		Weapon.PISTOL:   ammo_pistol,
		Weapon.SHOTGUN:  ammo_shotgun,
		Weapon.SMG:      ammo_smg,
		Weapon.RIFLE:    ammo_rifle,
	}

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------
func equip_weapon(type: int) -> void:
	if is_reloading:
		push_warning("CombatController: cannot switch weapon while reloading.")
		return
	current_weapon = type
	emit_signal("weapon_changed", current_weapon)
	emit_signal("ammo_changed", get_ammo(current_weapon), MAX_AMMO.get(current_weapon, 0))

func fire() -> void:
	if is_reloading:
		return
	if current_weapon == Weapon.UNARMED:
		_melee_fire()
		return

	var current_ammo: int = get_ammo(current_weapon)
	if current_ammo <= 0:
		# Dry-fire: auto-reload
		reload()
		return

	# Spend ammo
	var spent: int = AMMO_PER_SHOT.get(current_weapon, 1)
	set_ammo(current_weapon, current_ammo - spent)

	# Raycast from camera centre
	var hit_pos: Vector3 = _do_raycast()
	emit_signal("fired", current_weapon, hit_pos)

func reload() -> void:
	if is_reloading:
		return
	if current_weapon == Weapon.UNARMED:
		return
	is_reloading = true
	await get_tree().create_timer(reload_duration).timeout
	is_reloading = false
	emit_signal("reloaded", current_weapon)
	emit_signal("ammo_changed", get_ammo(current_weapon), MAX_AMMO.get(current_weapon, 0))

func set_ammo(type: int, amount: int) -> void:
	_ammo[type] = clampi(amount, 0, MAX_AMMO.get(type, 0))
	if type == current_weapon:
		emit_signal("ammo_changed", _ammo[type], MAX_AMMO.get(type, 0))

func get_ammo(type: int) -> int:
	return _ammo.get(type, 0)

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------
func _get_camera() -> Camera3D:
	# Try the primary viewport camera first
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam != null:
		return cam
	# Fallback: search the scene tree
	var cams: Array = get_tree().get_nodes_in_group("camera")
	if cams.size() > 0:
		return cams[0] as Camera3D
	return null

func _do_raycast() -> Vector3:
	var camera: Camera3D = _get_camera()
	if camera == null:
		push_warning("CombatController: no camera found for raycast.")
		return Vector3.ZERO

	var from: Vector3 = camera.global_position
	var to: Vector3   = from + (-camera.global_transform.basis.z * fire_range)

	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_parent()]   # Don't hit the player's own body
	query.collision_mask = 0xFFFFFFFF

	var result: Dictionary = space_state.intersect_ray(query)
	if result.is_empty():
		return to   # No hit — return max range point

	# Apply damage if target has take_damage method
	var collider: Object = result.get("collider")
	if collider != null and collider.has_method("take_damage"):
		collider.take_damage(1, self)

	return result.get("position", to)

func _melee_fire() -> void:
	# Basic melee via overlap sphere at arm's length
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var shape := SphereShape3D.new()
	shape.radius = 1.8

	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.transform = global_transform if get_parent() is Node3D else Transform3D.IDENTITY
	params.collision_mask = 0xFFFFFFFF

	var hits: Array = space_state.intersect_shape(params)
	for hit in hits:
		var collider: Object = hit.get("collider")
		if collider != null and collider != get_parent() and collider.has_method("take_damage"):
			collider.take_damage(1, self)

	emit_signal("fired", Weapon.UNARMED, Vector3.ZERO)
