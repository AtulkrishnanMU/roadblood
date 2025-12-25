extends Node2D

const BASIC_RAT_SCENE = preload("res://scenes/characters/enemy/basic_rat.tscn")
const BIG_RAT_SCENE = preload("res://scenes/characters/enemy/big_rat.tscn")
const CIRCULAR_WAVE_SCENE = preload("res://scenes/effects/circular_wave.tscn")
const BASE_SPAWN_INTERVAL = 3.0  # base seconds between spawns
const SPAWN_RADIUS = 1200.0  # distance from player to spawn enemies (increased from 800)
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
	print("EnemySpawner: Initial player found: ", player != null)
	
	# Add to enemy_spawner group for bullet communication
	add_to_group("enemy_spawner")
	print("EnemySpawner: Added to enemy_spawner group")

func _process(delta):
	# Try to find player if not already found
	if not player:
		player = get_tree().get_first_node_in_group("player")
		if player:
			print("EnemySpawner: Player found during runtime!")
	
	spawn_timer += delta
	
	# Handle wave spawning if enabled
	if waves_enabled:
		wave_timer += delta
		if wave_timer >= WAVE_INTERVAL:
			call_deferred("spawn_circular_wave")  # Use call_deferred to avoid physics error
			wave_timer = 0.0
	
	if spawn_timer >= current_spawn_interval:
		print("EnemySpawner: Attempting to spawn enemies")
		spawn_enemies()
		spawn_timer = 0.0

func spawn_enemies():
	if not player:
		print("EnemySpawner: No player found!")
		return
	
	# Calculate how many enemies to spawn based on kill count
	var enemies_to_spawn = 1  # Always spawn at least 1
	
	if kill_count >= 5:
		# Every 5 kills after 5, add one more enemy (max 3 total)
		var kill_thresholds = floor((kill_count - 5) / float(KILLS_PER_EXTRA_ENEMY)) + 1
		enemies_to_spawn = min(kill_thresholds + 1, 3)  # +1 for the base enemy, max 3
	
	print("EnemySpawner: Kill count: ", kill_count, ", Spawning ", enemies_to_spawn, " enemies")
	
	# Spawn the calculated number of enemies
	for i in range(enemies_to_spawn):
		spawn_single_enemy()

func spawn_single_enemy():
	print("EnemySpawner: Spawning enemy at player position: ", player.global_position)
	
	# Determine enemy type based on kill count
	var enemy_scene: PackedScene
	if kill_count >= KILLS_PER_BIG_RAT and randf() < 0.3:  # 30% chance for big rat after threshold
		enemy_scene = BIG_RAT_SCENE
		print("EnemySpawner: Spawning Big Rat")
	else:
		enemy_scene = BASIC_RAT_SCENE
		print("EnemySpawner: Spawning Basic Rat")
	
	# Generate random angle around player
	var random_angle = randf() * 2.0 * PI
	
	# Calculate spawn position at radius from player
	var spawn_position = player.global_position + Vector2(
		cos(random_angle) * SPAWN_RADIUS,
		sin(random_angle) * SPAWN_RADIUS
	)
	
	print("EnemySpawner: Spawn position calculated: ", spawn_position)
	
	# Spawn the enemy
	var enemy = enemy_scene.instantiate()
	get_parent().add_child(enemy)
	enemy.global_position = spawn_position
	
	print("EnemySpawner: Enemy spawned successfully")
	
	# Add fade-in effect
	_fade_in_enemy(enemy)

func increment_kill_count():
	kill_count += 1
	print("EnemySpawner: Kill count increased to: ", kill_count)
	
	# Update kill counter in UI
	var health_bar = get_tree().get_first_node_in_group("health_bar")
	if health_bar:
		health_bar.update_kill_counter(kill_count)
	else:
		print("EnemySpawner: Health bar not found for kill counter update")
	
	# Check if we should enable wave spawning
	if kill_count >= WAVE_TRIGGER_KILLS and not waves_enabled:
		waves_enabled = true
		print("EnemySpawner: Wave spawning enabled at ", kill_count, " kills!")
		# Spawn first wave immediately using call_deferred to avoid physics error
		call_deferred("spawn_circular_wave")
		wave_timer = 0.0  # Reset timer for next wave
	
	# Calculate new spawn interval based on kills (capped at MAX_SPEED_INCREASES)
	var speed_increases = min(kill_count / float(KILLS_PER_SPEED_UP), MAX_SPEED_INCREASES)
	var reduction = speed_increases * 0.3  # Reduce interval by 0.3s per speed increase
	current_spawn_interval = max(MIN_SPAWN_INTERVAL, BASE_SPAWN_INTERVAL - reduction)
	
	print("EnemySpawner: New spawn interval: ", current_spawn_interval, " seconds (speed increases: ", speed_increases, "/", MAX_SPEED_INCREASES, ")")

func spawn_circular_wave():
	if not player:
		print("EnemySpawner: No player found for wave!")
		return
	
	print("EnemySpawner: Spawning circular wave at player position")
	
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
