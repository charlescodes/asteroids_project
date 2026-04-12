extends Node2D

var projectile_count: int = 0

func _process(_delta: float) -> void:
	projectile_count = 0
	for child in get_children():
		if child is Projectile:
			projectile_count += 1
	for node in get_tree().root.get_children():
		if node is TungstenRod:
			projectile_count += 1
	queue_redraw()

func _draw() -> void:
	var font = ThemeDB.fallback_font
	var screen_size = get_viewport_rect().size
	draw_string(font, Vector2(10, screen_size.y - 10), "Projectiles: " + str(projectile_count),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)

func _ready() -> void:
	var screen_size = get_viewport_rect().size
	
	# Spawn Player
	var player = Player.new()
	player.position = screen_size / 2
	add_child(player)
	
	# Spawn 5 random Asteroids
	for i in range(5):
		var rock = Asteroid.new()
		rock.position = Vector2(randf() * screen_size.x, randf() * screen_size.y)
		rock.linear_velocity = Vector2.RIGHT.rotated(randf() * TAU) * 100
		add_child(rock)