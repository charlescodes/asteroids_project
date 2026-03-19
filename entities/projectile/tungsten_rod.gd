extends RigidBody2D
class_name TungstenRod

func _ready():
	# 1. Physics Properties for a heavy kinetic rod
	mass = 50.0
	gravity_scale = 0.0
	linear_damp = 0.0
	continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY # Stops it from clipping through asteroids at high speeds

	# 2. Build the Collision Shape programmatically
	var collision = CollisionShape2D.new()
	var shape = CapsuleShape2D.new()
	shape.radius = 4.0
	shape.height = 30.0
	collision.shape = shape
	add_child(collision)

	# 3. Build the cleanup notifier programmatically
	var notifier = VisibleOnScreenNotifier2D.new()
	notifier.screen_exited.connect(queue_free)
	add_child(notifier)

func _draw():
	# Draw a thick grey line directly to the canvas (no sprite needed)
	draw_line(Vector2(0, -15), Vector2(0, 15), Color.WEB_GRAY, 8.0)
