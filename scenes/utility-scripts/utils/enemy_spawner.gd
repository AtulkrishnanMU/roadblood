extends Node2D

const BASIC_RAT_SCENE = preload("res://scenes/characters/enemy/basic_rat.tscn")
const BIG_RAT_SCENE = preload("res://scenes/characters/enemy/big_rat.tscn")
const CIRCULAR_WAVE_SCENE = preload("res://scenes/effects/circular_wave.tscn")
const BASE_SPAWN_INTERVAL = 3.0  # base seconds between spawns
const SPAWN_RADIUS = 1200.0  # distance from player to spawn enemies (increased from 800)
const ROOM_WIDTH = 1200.0  # room width in pixels
const ROOM_HEIGHT = 800.0  # room height in pixels
const ROOM_CENTER_X = 576.0  # room center X position
const ROOM_CENTER_Y = 320.0  # room center Y position (corrected from 400)
const ROOM_SCALE_X = 2.62  # room scale X
const ROOM_SCALE_Y = 2.23  # room scale Y
const FADE_IN_DURATION = 1.0  # duration for fade-in effect
const MIN_SPAWN_INTERVAL = 0.5  # minimum spawn interval (fastest possible)
const MAX_SPEED_INCREASES = 8  # maximum number of speed increases (caps at 8*5=40 kills)
const KILLS_PER_SPEED_UP = 5  # kills needed to increase spawn rate
const KILLS_PER_EXTRA_ENEMY = 5  # kills needed to spawn extra enemy
const KILLS_PER_BIG_RAT = 10  # kills needed to start spawning big rats
const WAVE_TRIGGER_KILLS = 50  # kills needed to start wave spawning
const WAVE_INTERVAL = 10.0  # seconds between waves after trigger

var spawn_timer = 0.0
var player: CharacterBody2D
var kill_count = 0
var current_spawn_interval = BASE_SPAWN_INTERVAL
var wave_timer = 0.0
var waves_enabled = false

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
	
	spawn_timer += delta
	
	# Handle wave spawning if enabled
	if waves_enabled:
		wave_timer += delta
		if wave_timer >= WAVE_INTERVAL:
			call_deferred("spawn_circular_wave")  # Use call_deferred to avoid physics error
			wave_timer = 0.0
	
	if spawn_timer >= current_spawn_interval:
		spawn_enemies()
		spawn_timer = 0.0

func spawn_enemies():
	if not player:
		return
	
	# Calculate how many enemies to spawn based on kill count
	var enemies_to_spawn = 1  # Always spawn at least 1
	
	if kill_count >= 5:
		# Every 5 kills after 5, add one more enemy (max 3 total)
		var kill_thresholds = floor((kill_count - 5) / float(KILLS_PER_EXTRA_ENEMY)) + 1
		enemies_to_spawn = min(kill_thresholds + 1, 3)  # +1 for the base enemy, max 3
	
	
	# Spawn the calculated number of enemies
	for i in range(enemies_to_spawn):
		spawn_single_enemy()

func spawn_single_enemy():
	
	# Determine enemy type based on kill count
	var enemy_scene: PackedScene
	if kill_count >= KILLS_PER_BIG_RAT and randf() < 0.3:  # 30% chance for big rat after threshold
		enemy_scene = BIG_RAT_SCENE
	else:
		enemy_scene = BASIC_RAT_SCENE
	
	# Get random position on room edge
	var spawn_position = _get_random_position_on_room_edge()
	
	
	# Spawn the enemy
	var enemy = enemy_scene.instantiate()
	get_parent().add_child(enemy)
	enemy.global_position = spawn_position
	
	
	# Add fade-in effect
	_fade_in_enemy(enemy)

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

func increment_kill_count():
	kill_count += 1
	
	# Update kill counter in UI
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		ui.update_kill_counter(kill_count)
	else:
		pass  # UI not found
	
	# Check if we should enable wave spawning
	if kill_count >= WAVE_TRIGGER_KILLS and not waves_enabled:
		waves_enabled = true
		# Spawn first wave immediately using call_deferred to avoid physics error
		call_deferred("spawn_circular_wave")
		wave_timer = 0.0  # Reset timer for next wave
	
	# Calculate new spawn interval based on kills (capped at MAX_SPEED_INCREASES)
	var speed_increases = min(kill_count / float(KILLS_PER_SPEED_UP), MAX_SPEED_INCREASES)
	var reduction = speed_increases * 0.3  # Reduce interval by 0.3s per speed increase
	current_spawn_interval = max(MIN_SPAWN_INTERVAL, BASE_SPAWN_INTERVAL - reduction)
	

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
