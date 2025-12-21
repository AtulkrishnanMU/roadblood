extends Node2D

const ENEMY_SCENE = preload("res://scenes/characters/enemy/enemy.tscn")
const SPAWN_INTERVAL = 3.0  # seconds between spawns
const SPAWN_RADIUS = 500.0  # distance from player to spawn enemies
const FADE_IN_DURATION = 1.0  # duration for fade-in effect

var spawn_timer = 0.0
var player: CharacterBody2D

func _ready():
	# Try to find the player initially
	player = get_tree().get_first_node_in_group("player")
	print("EnemySpawner: Initial player found: ", player != null)

func _process(delta):
	# Try to find player if not already found
	if not player:
		player = get_tree().get_first_node_in_group("player")
		if player:
			print("EnemySpawner: Player found during runtime!")
	
	spawn_timer += delta
	
	if spawn_timer >= SPAWN_INTERVAL:
		print("EnemySpawner: Attempting to spawn enemy")
		spawn_enemy()
		spawn_timer = 0.0

func spawn_enemy():
	if not player:
		print("EnemySpawner: No player found!")
		return
	
	print("EnemySpawner: Spawning enemy at player position: ", player.global_position)
	
	# Generate random angle around player
	var random_angle = randf() * 2.0 * PI
	
	# Calculate spawn position at radius from player
	var spawn_position = player.global_position + Vector2(
		cos(random_angle) * SPAWN_RADIUS,
		sin(random_angle) * SPAWN_RADIUS
	)
	
	print("EnemySpawner: Spawn position calculated: ", spawn_position)
	
	# Spawn the enemy
	var enemy = ENEMY_SCENE.instantiate()
	get_parent().add_child(enemy)
	enemy.global_position = spawn_position
	
	print("EnemySpawner: Enemy spawned successfully")
	
	# Add fade-in effect
	_fade_in_enemy(enemy)

func _fade_in_enemy(enemy: CharacterBody2D):
	# Start invisible
	enemy.modulate.a = 0.0
	
	# Create fade-in tween
	var fade_tween = create_tween()
	fade_tween.set_ease(Tween.EASE_IN_OUT)
	fade_tween.set_trans(Tween.TRANS_SINE)
	fade_tween.tween_property(enemy, "modulate:a", 1.0, FADE_IN_DURATION)
