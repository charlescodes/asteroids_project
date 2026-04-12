class_name Asteroid
extends RigidBody2D

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
		for i in range(8):
			var angle = (TAU / 8) * i
			var radius = size_radius * randf_range(0.6, 1.2)
			shape_points.append(Vector2(cos(angle), sin(angle)) * radius)

	var mat = PhysicsMaterial.new()
	mat.bounce = 0.1
	mat.friction = 0.01
	physics_material_override = mat

	# 4. COLLISION & VISUALS
	var collision = CollisionPolygon2D.new()
	collision.polygon = shape_points
	add_child(collision)
	queue_redraw()


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

	# Too small to split further - just destroy
	if size_radius < min_shatter_radius:
		queue_free()
		return

	# Split line direction: from center through hit point
	var direction = hit_point.normalized()
	if direction.length_squared() < 0.001:
		direction = impact_velocity.normalized()

	# Split the polygon into two halves
	var halves = _split_polygon(shape_points, direction)

	# Validate both halves are real polygons (at least 3 vertices each)
	if halves[0].size() < 3 or halves[1].size() < 3:
		queue_free()
		return

	# Calculate scatter directions (perpendicular to split line, outward)
	var perpendicular = Vector2(-direction.y, direction.x)

	# Spawn both halves as new asteroids
	for i in range(2):
		var child = Asteroid.new()
		child.shape_points = halves[i]
		child.size_radius = size_radius * 0.65
		child.position = global_position

		# Inherit parent velocity + outward scatter from split point
		child.linear_velocity = linear_velocity
		var scatter_dir = perpendicular if i == 0 else -perpendicular
		child.linear_velocity += scatter_dir * shatter_scatter_force
		child.angular_velocity = angular_velocity + randf_range(-2.0, 2.0)

		# Fade scatter with impact velocity
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
