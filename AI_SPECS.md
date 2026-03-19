# Project: Geometric Asteroids (Godot 4.x)
**Context:** A modular, maintainable clone of Asteroids using programmatic 2D drawing.

## Environment Setup
* **OS:** Windows 11 / WSL2 (Fedora)
* **Engine:** Godot 4.4.x
* **IDE:** VS Code (with `.editorconfig` for Tabs)
* **VCS:** Git (Configured with local user identity)

## Architecture Rules
1.  **Component-Based:** Prefer composition over inheritance. Use separate Node scripts for distinct behaviors (e.g., `ScreenWrap.gd` as a child node).
2.  **Programmatic Visuals:** No textures. All visuals are drawn using `_draw()` in GDScript.
3.  **Collision:** `CollisionPolygon2D` shapes must explicitly match the points used in `_draw()`.
4.  **Signal Bus:** Use a global SignalBus singleton for cross-entity communication (e.g., `AsteroidDestroyed` signal) rather than hard dependencies.

## Entity specs
* **Player:** Triangle shape. CharacterBody2D.
	* Controls: WASD (W=Thrust, S=Brake/Reverse, A/D=Rotate). Space=Shoot.
* **Asteroid:** Irregular "Star/Rock" shape. RigidBody2D. Spawns off-screen or off-center.
* **Bullet:** 1x1 Rect. Area2D. High velocity.

## Code Style
* Typed GDScript (e.g., `var health: int = 10`) is mandatory.
* Docstrings at the top of every class explaining its purpose.

## "Script-Only" Architecture (Crucial)
This project uses a **Code-First** approach. We do NOT use `.tscn` (Scene) files for entities like the Player, Asteroids, or Bullets. 
* **Entities are Classes:** All game objects must use `class_name` in their script (e.g., `class_name Player`).
* **Instantiation:** Entities are created via `.new()` and added to the tree dynamically by the Main Game.
* **No Visual Editor:** Nodes (CollisionShape2D, etc.) are created and configured entirely inside `_ready()` or `_init()`.
* **Single Scene:** The only `.tscn` file allowed is `main_game.tscn` (the entry point).
