# BuoyancyEffector.gd
# Applies upward buoyancy forces to a RigidBody3D vessel by raycasting
# each buoyancy point downward and checking if it is below the water surface.
# Attach as a child of a RigidBody3D (boat, debris, barrel, etc.).
extends Node

# ── Exports ────────────────────────────────────────────────────────────────
@export var buoyancy_force: float = 10.0
@export var water_drag: float = 2.0
@export var water_angular_drag: float = 1.0
@export var buoyancy_points: Array[NodePath] = []  # NodePaths to marker Node3Ds
@export var water_layer: int = 4                   # physics collision layer for water
@export var raycast_distance: float = 50.0         # ray length cast downward

# ── State ──────────────────────────────────────────────────────────────────
var _body: RigidBody3D = null
var _default_linear_damp: float = 0.0
var _default_angular_damp: float = 0.0
var _in_water: bool = false
var _resolved_points: Array[Node3D] = []

# ── Lifecycle ──────────────────────────────────────────────────────────────
func _ready() -> void:
	_body = get_parent() as RigidBody3D
	if _body == null:
		push_warning("BuoyancyEffector '%s': parent must be a RigidBody3D." % name)
		return
	_default_linear_damp = _body.linear_damp
	_default_angular_damp = _body.angular_damp

	# Resolve NodePaths once at startup.
	for np in buoyancy_points:
		var node := get_node_or_null(np) as Node3D
		if node != null:
			_resolved_points.append(node)
		else:
			push_warning("BuoyancyEffector: could not resolve buoyancy point NodePath '%s'." % str(np))

func _physics_process(_delta: float) -> void:
	if _body == null:
		return
	if _resolved_points.is_empty():
		push_warning("BuoyancyEffector '%s': no valid buoyancy points." % name)
		return

	var space_state := _body.get_world_3d().direct_space_state
	var submerged_count: int = 0

	for point in _resolved_points:
		if point == null or not is_instance_valid(point):
			continue

		var ray_origin: Vector3 = point.global_position
		# Cast ray downward to find the water surface above the point,
		# then upward to check submersion — actually we cast upward from the
		# point to find the water surface if the point is already underwater.
		# Strategy: cast DOWN from well above the point to find water-surface Y,
		# then compare with point Y to get submersion depth.
		var query := PhysicsRayQueryParameters3D.create(
			ray_origin + Vector3.UP * raycast_distance,
			ray_origin,
			1 << (water_layer - 1)  # layer bitmask (water_layer is 1-indexed)
		)
		query.collide_with_areas = true
		query.collide_with_bodies = true
		# Exclude the vessel itself.
		query.exclude = [_body]

		var result := space_state.intersect_ray(query)
		if result.is_empty():
			# No water surface found above — the point may already be submerged
			# with no surface in range, or simply not in water. Try casting upward.
			var query_up := PhysicsRayQueryParameters3D.create(
				ray_origin,
				ray_origin + Vector3.UP * raycast_distance,
				1 << (water_layer - 1)
			)
			query_up.collide_with_areas = true
			query_up.collide_with_bodies = true
			query_up.exclude = [_body]
			var result_up := space_state.intersect_ray(query_up)
			if result_up.is_empty():
				continue  # not in water
			# Point is submerged; surface is above.
			var water_surface_y: float = result_up["position"].y
			var submersion_depth: float = water_surface_y - ray_origin.y
			_apply_buoyancy_at_point(point, submersion_depth)
			submerged_count += 1
		else:
			# Surface found between the high point and ray_origin.
			var water_surface_y: float = result["position"].y
			if water_surface_y > ray_origin.y:
				# Point is submerged.
				var submersion_depth: float = water_surface_y - ray_origin.y
				_apply_buoyancy_at_point(point, submersion_depth)
				submerged_count += 1

	# Adjust drag when in water.
	var currently_in_water: bool = submerged_count > 0
	if currently_in_water != _in_water:
		_in_water = currently_in_water
		if _in_water:
			_body.linear_damp = water_drag
			_body.angular_damp = water_angular_drag
		else:
			_body.linear_damp = _default_linear_damp
			_body.angular_damp = _default_angular_damp

# ── Private ────────────────────────────────────────────────────────────────
func _apply_buoyancy_at_point(point: Node3D, submersion_depth: float) -> void:
	# Force scales with submersion depth so it's gentle near the surface.
	var force_magnitude: float = buoyancy_force * clampf(submersion_depth, 0.0, 1.0)
	var force: Vector3 = Vector3.UP * force_magnitude
	# apply_force takes a force and a local position offset from the body's origin.
	var offset: Vector3 = point.global_position - _body.global_position
	_body.apply_force(force, offset)
