class_name Projectile
extends Area2D

var velocity: Vector2 = Vector2.ZERO
var speed: float = 800.0
var lifespan: float = 1.0 # Destroys itself after 1 second
var shape_points: PackedVector2Array = [
	Vector2(-2, -2), Vector2(2, -2), 
	Vector2(2, 2), Vector2(-2, 2)
]

func _ready() -> void:
	var collision = CollisionPolygon2D.new()
	collision.polygon = shape_points
	add_child(collision)
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _draw() -> void:
	# Drawing a small yellow/white square
	draw_colored_polygon(shape_points, Color.LIGHT_YELLOW)

func _physics_process(delta: float) -> void:
	# 1. Move
	position += velocity * delta
	
	# 2. Screen Wrap
	var screen_size = get_viewport_rect().size
	position.x = wrapf(position.x, 0, screen_size.x)
	position.y = wrapf(position.y, 0, screen_size.y)
	
	# 3. Age and Die
	lifespan -= delta
	if lifespan <= 0.0:
		queue_free() # The Godot garbage collector

func _on_body_entered(body: Node2D) -> void:
	if body is Asteroid:
		# Convert global hit point to asteroid's local coordinates
		var local_hit_point = body.to_local(global_position)
		body.shatter(local_hit_point, velocity)
		queue_free()
