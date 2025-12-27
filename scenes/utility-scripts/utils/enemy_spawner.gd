extends Node2D

const BASIC_RAT_SCENE = preload("res://scenes/characters/enemy/basic_rat.tscn")
const BIG_RAT_SCENE = preload("res://scenes/characters/enemy/big_rat.tscn")
const CIRCULAR_WAVE_SCENE = preload("res://scenes/effects/circular_wave.tscn")
const SPAWN_RADIUS = 1200.0  # distance from player to spawn enemies (increased from 800)
const MIN_SPAWN_DISTANCE = 400.0  # minimum distance from player for wave spawning
const MAX_SPAWN_ATTEMPTS = 10  # maximum attempts to find a valid spawn position
const ROOM_WIDTH = 1200.0  # room width in pixels
const ROOM_HEIGHT = 800.0  # room height in pixels
const ROOM_CENTER_X = 576.0  # room center X position
const ROOM_CENTER_Y = 320.0  # room center Y position (corrected from 400)
const ROOM_SCALE_X = 2.62  # room scale X
const ROOM_SCALE_Y = 2.23  # room scale Y
const FADE_IN_DURATION = 0.3  # duration for fade-in effect (reduced from 1.0 for faster reaction)

signal enemy_killed
signal enemy_spawned(enemy: Node)  # Immediate notification when enemy spawns

var player: CharacterBody2D
var kill_count = 0

# New wave system variables
var current_spawn_points: Array[Vector2] = []
var current_enemy_pool: Array[PackedScene] = []
var current_spawn_rate: float = 1.0
var current_max_enemies: int = 20
var current_enemies_per_spawn: int = 1  # New: number of enemies per spawn event
var wave_controlled: bool = false  # Flag to indicate if BaseLevel is controlling spawning
var enemies_alive_count: int = 0

func _ready():
	# Try to find the player initially
	player = get_tree().get_first_node_in_group("player")
		
	# Add to enemy_spawner group for bullet communication
	add_to_group("enemy_spawner")
	
func _process(delta):
	# Try to find player if not already found
	if not player:
		player = get_tree().get_first_node_in_group("player")
		if player:
			pass  # Player found

# New methods for BaseLevel integration
func set_spawn_points(points: Array[Vector2]):
	current_spawn_points = points

func set_enemy_pool(enemies: Array[PackedScene]):
	current_enemy_pool = enemies

func set_spawn_rate(rate: float):
	current_spawn_rate = rate
	wave_controlled = true  # Mark as wave-controlled

func set_max_enemies(max_enemies: int):
	current_max_enemies = max_enemies

func set_spawn_range(spawn_range: Array[int]):
	# This is handled by set_enemies_per_spawn which is called dynamically
	pass

func set_enemies_per_spawn(count: int):
	current_enemies_per_spawn = count

func spawn_enemy():
	# Spawn multiple enemies based on current_enemies_per_spawn
	var enemies_spawned = 0
	
	for i in range(current_enemies_per_spawn):
		# Check if we've reached the max enemy limit
		if enemies_alive_count >= current_max_enemies:
			break  # Cannot spawn more, max reached
		
		# Check if enemy pool is available
		if current_enemy_pool.is_empty():
			break  # No enemies to spawn
		
		# Get random enemy from current pool
		var enemy_scene = current_enemy_pool[randi() % current_enemy_pool.size()]
		
		# Get spawn position
		var spawn_position = _get_spawn_position()
		
		# Spawn the enemy
		var enemy = enemy_scene.instantiate()
		get_parent().add_child(enemy)
		enemy.global_position = spawn_position
		
		# Track this enemy
		enemies_alive_count += 1
		enemies_spawned += 1
		
		# Connect to enemy death signal
		if enemy.has_signal("tree_exiting"):
			enemy.tree_exiting.connect(_on_enemy_exited)
		
		# Add fade-in effect
		_fade_in_enemy(enemy)
		
		# CRITICAL: Emit signal immediately after spawn for zero reaction time
		emit_signal("enemy_spawned", enemy)
	
	return enemies_spawned > 0  # Return true if at least one enemy was spawned

func _on_enemy_exited():
	enemies_alive_count -= 1
	emit_signal("enemy_killed")

func increment_kill_count():
	kill_count += 1
	
	# Emit signal for BaseLevel to track
	emit_signal("enemy_killed")
	
	# Update kill counter in UI
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		ui.update_kill_counter(kill_count)
	else:
		pass  # UI not found

func _get_random_position_on_room_edge() -> Vector2:
	# Calculate actual room boundaries with scale
	var actual_room_width = ROOM_WIDTH * ROOM_SCALE_X
	var actual_room_height = ROOM_HEIGHT * ROOM_SCALE_Y
	
	var room_left = ROOM_CENTER_X - actual_room_width / 2
	var room_right = ROOM_CENTER_X + actual_room_width / 2
	var room_top = ROOM_CENTER_Y - actual_room_height / 2
	var room_bottom = ROOM_CENTER_Y + actual_room_height / 2
	
	# Add margin to ensure enemies spawn INSIDE the room
	var spawn_margin = 50.0
	room_left += spawn_margin
	room_right -= spawn_margin
	room_top += spawn_margin
	room_bottom -= spawn_margin
	
	# Choose random wall (0: top, 1: right, 2: bottom, 3: left)
	var wall_choice = randi() % 4
	
	var spawn_position: Vector2
	
	match wall_choice:
		0:  # Top wall (spawn just inside top edge)
			spawn_position = Vector2(
				randf_range(room_left, room_right),
				room_top + 10  # Small buffer from exact edge
			)
		1:  # Right wall (spawn just inside right edge)
			spawn_position = Vector2(
				room_right - 10,  # Small buffer from exact edge
				randf_range(room_top, room_bottom)
			)
		2:  # Bottom wall (spawn just inside bottom edge)
			spawn_position = Vector2(
				randf_range(room_left, room_right),
				room_bottom - 10  # Small buffer from exact edge
			)
		3:  # Left wall (spawn just inside left edge)
			spawn_position = Vector2(
				room_left + 10,  # Small buffer from exact edge
				randf_range(room_top, room_bottom)
			)
		_:
			spawn_position = Vector2(room_left + 50, room_top + 50)  # Fallback
	
	return spawn_position

func spawn_circular_wave():
	if not player:
		return
	
	# Spawn the circular wave
	var wave = CIRCULAR_WAVE_SCENE.instantiate()
	get_parent().add_child(wave)
	wave.global_position = player.global_position

func _fade_in_enemy(enemy: CharacterBody2D):
	# Start invisible
	enemy.modulate.a = 0.0
	
	# Create fade-in tween
	var fade_tween = create_tween()
	fade_tween.set_ease(Tween.EASE_IN_OUT)
	fade_tween.set_trans(Tween.TRANS_SINE)
	fade_tween.tween_property(enemy, "modulate:a", 1.0, FADE_IN_DURATION)

func _get_spawn_position() -> Vector2:
	# Use configured spawn points if available, but ensure minimum distance from player
	if not current_spawn_points.is_empty():
		return _get_valid_spawn_point_from_list()
	
	# Fallback to original room edge spawning
	return _get_random_position_on_room_edge()

func _get_valid_spawn_point_from_list() -> Vector2:
	# Try to find a spawn point that's far enough from the player
	for attempt in range(MAX_SPAWN_ATTEMPTS):
		var spawn_point = current_spawn_points[randi() % current_spawn_points.size()]
		
		if player and spawn_point.distance_to(player.global_position) >= MIN_SPAWN_DISTANCE:
			return spawn_point
	
	# If no valid point found, return the farthest one
	var farthest_point = current_spawn_points[0]
	var max_distance = 0.0
	
	for point in current_spawn_points:
		if player:
			var distance = point.distance_to(player.global_position)
			if distance > max_distance:
				max_distance = distance
				farthest_point = point
	
	return farthest_point
