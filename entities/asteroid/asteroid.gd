class_name Asteroid
extends RigidBody2D

const BASE_VERTEX_COUNT: int = 8
const SHAPE_SUBDIVISION_PASSES: int = 2

var shape_points: PackedVector2Array
var size_radius: float = 30.0
var min_shatter_radius: float = 10.0
var shatter_scatter_force: float = 80.0
var is_shattering: bool = false

func _ready() -> void:
	# 1. PHYSICS SETUP
	gravity_scale = 0
	linear_damp = 0.01
	angular_damp = 0.01
	sleeping = false
	can_sleep = false

	# 2. MASS CALCULATION
	mass = size_radius * 0.1

	# 3. GENERATE SHAPE (only if not already set)
	if shape_points.is_empty():
		shape_points = _generate_shape_points()

	var mat = PhysicsMaterial.new()
	mat.bounce = 0.1
	mat.friction = 0.01
	physics_material_override = mat

	# 4. COLLISION & VISUALS
	var collision = CollisionPolygon2D.new()
	collision.polygon = shape_points
	add_child(collision)
	queue_redraw()


func _generate_shape_points() -> PackedVector2Array:
	var generated_points: PackedVector2Array = []
	for i in range(BASE_VERTEX_COUNT):
		var angle = (TAU / BASE_VERTEX_COUNT) * i
		var radius = size_radius * randf_range(0.6, 1.2)
		generated_points.append(Vector2(cos(angle), sin(angle)) * radius)

	return _subdivide_polygon_edges(generated_points, SHAPE_SUBDIVISION_PASSES)


func _subdivide_polygon_edges(points: PackedVector2Array, passes: int) -> PackedVector2Array:
	var subdivided_points := points

	for _pass in range(passes):
		if subdivided_points.size() < 2:
			return subdivided_points

		var next_points: PackedVector2Array = []
		for i in range(subdivided_points.size()):
			var start := subdivided_points[i]
			var finish := subdivided_points[(i + 1) % subdivided_points.size()]
			next_points.append(start)
			next_points.append(start.lerp(finish, 0.5))
		subdivided_points = next_points

	return subdivided_points


func _draw() -> void:
	var closed_loop = shape_points + PackedVector2Array([shape_points[0]])
	draw_polyline(closed_loop, Color.WHITE, 2.0)

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	# SCREEN WRAP
	var screen_size = get_viewport_rect().size
	var xform = state.transform
	xform.origin.x = wrapf(xform.origin.x, 0, screen_size.x)
	xform.origin.y = wrapf(xform.origin.y, 0, screen_size.y)
	state.transform = xform


func shatter(hit_point: Vector2, impact_velocity: Vector2) -> void:
	if is_shattering:
		return
	is_shattering = true

	if size_radius < min_shatter_radius:
		queue_free()
		return

	var split_dir = (-impact_velocity).normalized()
	if split_dir.length_squared() < 0.001:
		split_dir = hit_point.normalized()
		if split_dir.length_squared() < 0.001:
			split_dir = Vector2.RIGHT

	var shifted_points: PackedVector2Array = []
	for p in shape_points:
		shifted_points.append(p - hit_point)

	var halves_shifted = _split_polygon(shifted_points, split_dir)

	if halves_shifted[0].size() < 3 or halves_shifted[1].size() < 3:
		queue_free()
		return

	var halves: Array[PackedVector2Array] = []
	for half in halves_shifted:
		var shifted_back: PackedVector2Array = []
		for p in half:
			shifted_back.append(p + hit_point)
		halves.append(shifted_back)

	var perpendicular = Vector2(-split_dir.y, split_dir.x)

	for i in range(2):
		var child = Asteroid.new()
		child.shape_points = halves[i]
		child.size_radius = size_radius * 0.65
		child.position = global_position

		child.linear_velocity = linear_velocity
		var scatter_dir = perpendicular if i == 0 else -perpendicular
		child.linear_velocity += scatter_dir * shatter_scatter_force
		child.angular_velocity = angular_velocity + randf_range(-2.0, 2.0)

		child.linear_velocity += impact_velocity.normalized() * 20.0

		get_parent().add_child(child)

	queue_free()


func _split_polygon(points: PackedVector2Array, direction: Vector2) -> Array[PackedVector2Array]:
	# Split a convex polygon along a line through the origin in given direction.
	# Returns two PackedVector2Arrays representing the two halves.
	# Vertices with cross > 0 go to A, cross < 0 go to B.
	# When an edge crosses the split line, the intersection point is added to BOTH.
	var poly_a: PackedVector2Array = []
	var poly_b: PackedVector2Array = []

	var n = points.size()
	for i in range(n):
		var v0 = points[i]
		var v1 = points[(i + 1) % n]

		var cross0 = direction.cross(v0)
		var cross1 = direction.cross(v1)

		# Determine sides (use small epsilon for "on the line")
		var eps = 0.001
		var side0 = 0
		if cross0 > eps: side0 = 1   # "above" the line
		elif cross0 < -eps: side0 = -1  # "below" the line

		var side1 = 0
		if cross1 > eps: side1 = 1
		elif cross1 < -eps: side1 = -1

		# Compute intersection if edge crosses the split line
		var intersection: Vector2 = Vector2.ZERO
		var has_intersection = false

		if side0 != side1:
			var denom = direction.x * (v1.y - v0.y) - direction.y * (v1.x - v0.x)
			if abs(denom) > 0.0001:
				intersection = v0 + (v1 - v0) * (-direction.cross(v0)) / denom
				has_intersection = true

		if has_intersection:
			# Edge crosses the split line
			if side0 > 0: poly_a.append(v0)
			elif side0 < 0: poly_b.append(v0)

			# Intersection point goes to both polygons (closes the cut edge)
			poly_a.append(intersection)
			poly_b.append(intersection)
		else:
			# Edge doesn't cross the line
			if side0 > 0: poly_a.append(v0)
			elif side0 < 0: poly_b.append(v0)

			# Vertices on the line (cross == 0) go to both
			if side0 == 0:
				poly_a.append(v0)
				poly_b.append(v0)

	return [poly_a, poly_b]
