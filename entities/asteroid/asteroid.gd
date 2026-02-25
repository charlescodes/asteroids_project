class_name Asteroid
extends RigidBody2D

var shape_points: PackedVector2Array
var size_radius: float = 30.0

func _ready() -> void:
	gravity_scale = 0
	# Generate a star/rock shape
	for i in range(8):
		var angle = (TAU / 8) * i
		var radius = size_radius * randf_range(0.6, 1.2)
		shape_points.append(Vector2(cos(angle), sin(angle)) * radius)
	
	var collision = CollisionPolygon2D.new()
	collision.polygon = shape_points
	add_child(collision)
	queue_redraw()

func _draw() -> void:
	# FIX: Explicitly cast the single point to an Array so it can be added
	var closed_loop = shape_points + PackedVector2Array([shape_points[0]])
	draw_polyline(closed_loop, Color.WHITE, 2.0)

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var screen_size = get_viewport_rect().size
	var xform = state.transform
	xform.origin.x = wrapf(xform.origin.x, 0, screen_size.x)
	xform.origin.y = wrapf(xform.origin.y, 0, screen_size.y)
	state.transform = xform
