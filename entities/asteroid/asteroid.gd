class_name Asteroid
extends RigidBody2D

var shape_points: PackedVector2Array
var size_radius: float = 30.0

func _ready() -> void:
	

	# 1. PHYSICS SETUP
	# TODO: What are these dimensions or units are these based about
	gravity_scale = 0
	linear_damp = 0.01   # No air resistance in space!
	angular_damp = 0.01  # Keep spinning forever
	sleeping = false    # Never let the physics engine "turn off" this rock
	can_sleep = false   # Explicitly forbid sleeping
	
	# 2. MASS CALCULATION
	# Default mass is 1.0. Let's make it proportional to size.
	# A radius 30 rock will be mass 3.0, a radius 10 rock will be mass 1.0
	mass = size_radius * 0.1 

	# 3. GENERATE SHAPE
	for i in range(8):
		var angle = (TAU / 8) * i
		var radius = size_radius * randf_range(0.6, 1.2)
		shape_points.append(Vector2(cos(angle), sin(angle)) * radius)

	var mat = PhysicsMaterial.new()
	mat.bounce = 0.1 # 1.0 = Perfect energy conservation (Super Ball)
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
