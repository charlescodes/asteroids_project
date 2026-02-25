extends Node2D

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