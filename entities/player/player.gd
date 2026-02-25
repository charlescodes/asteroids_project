class_name Player # <--- THIS IS THE MAGIC KEY
extends CharacterBody2D

@export var rotation_speed: float = 4.0
@export var acceleration: float = 200.0
@export var friction: float = 1.0 # The "Space Brake" factor

var screen_size: Vector2
# Define the Triangle shape points relative to (0,0)
var shape_points: PackedVector2Array = [
	Vector2(15, 0),   # Nose
	Vector2(-10, 10), # Bottom Right
	Vector2(-10, -10) # Bottom Left
]

func _ready() -> void:
	screen_size = get_viewport_rect().size
	
	# 1. Setup Visuals
	queue_redraw() # Triggers _draw
	
	# 2. Setup Collision
	var collision_shape = CollisionPolygon2D.new()
	collision_shape.polygon = shape_points
	add_child(collision_shape)

func _draw() -> void:
	# Draw the ship as a hollow line or filled shape
	draw_colored_polygon(shape_points, Color.WHITE)
	# Optional: Draw a "cockpit" line to see rotation easily
	draw_line(Vector2(0,0), Vector2(15,0), Color.BLACK, 1.0)

func _physics_process(delta: float) -> void:
	get_input(delta)
	move_and_slide()
	_screen_wrap()

func get_input(delta: float) -> void:
	var rotation_dir = Input.get_axis("ui_left", "ui_right") # A and D
	rotation += rotation_dir * rotation_speed * delta
	
	if Input.is_action_pressed("ui_up"): # W (Thrust)
		velocity += Vector2.RIGHT.rotated(rotation) * acceleration * delta
	
	if Input.is_action_pressed("ui_down"): # S (Brake)
		# Linearly interpolate velocity to zero for a braking effect
		velocity = velocity.lerp(Vector2.ZERO, friction * delta)

	if Input.is_action_just_pressed("ui_accept"): # Spacebar
		shoot()

func _screen_wrap() -> void:
	position.x = wrapf(position.x, 0, screen_size.x)
	position.y = wrapf(position.y, 0, screen_size.y)

func shoot() -> void:
	# Signal to Main to spawn bullet, or spawn locally
	# For simplicity, let's assume a "Bullet" scene exists
	pass