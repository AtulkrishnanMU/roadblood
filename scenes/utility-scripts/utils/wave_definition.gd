extends Resource

# Wave configuration for data-driven enemy spawning
@export var spawn_rate: float = 1.0  # Enemies per second
@export var allowed_enemies: Array[PackedScene] = []
@export var max_enemies: int = 20  # Maximum enemies for this wave
@export var enemy_weights: Array[float] = []  # Spawn weights for each enemy type
@export var special_rules: Dictionary = {}

func _init():
	# Initialize with default values
	pass

# Set spawn rate (enemies per second)
func set_spawn_rate(rate: float):
	spawn_rate = rate

# Add allowed enemy type
func add_allowed_enemy(enemy_scene: PackedScene, weight: float = 1.0):
	allowed_enemies.append(enemy_scene)
	enemy_weights.append(weight)

# Set maximum enemies
func set_max_enemies(max_count: int):
	max_enemies = max_count

# Add special rule
func add_special_rule(key: String, value):
	special_rules[key] = value

# Get random enemy based on weights
func get_random_enemy() -> PackedScene:
	if allowed_enemies.is_empty():
		return null
		
	# Calculate total weight
	var total_weight = 0.0
	for weight in enemy_weights:
		total_weight += weight
	
	# Random selection based on weights
	var random_value = randf() * total_weight
	var current_weight = 0.0
	
	for i in range(allowed_enemies.size()):
		current_weight += enemy_weights[i]
		if random_value <= current_weight:
			return allowed_enemies[i]
	
	# Fallback to first enemy
	return allowed_enemies[0]
