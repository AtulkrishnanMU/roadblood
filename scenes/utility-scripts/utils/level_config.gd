extends Resource

# Configuration structure for data-driven levels
@export var spawn_points: Array[Vector2] = []
@export var wave_definitions: Array[Resource] = []
@export var enemy_pool: Array[PackedScene] = []
@export var wave_duration: float = 60.0  # 1 minute per wave
@export var difficulty_scale: float = 1.0
@export var environment_rules: Dictionary = {}
@export var rewards: Dictionary = {}

func _init():
	# Initialize with default values
	pass

# Add a spawn point
func add_spawn_point(position: Vector2):
	spawn_points.append(position)

# Add a wave definition
func add_wave_definition(wave_def: WaveDefinition):
	wave_definitions.append(wave_def)

# Add enemy to pool
func add_enemy_to_pool(enemy_scene: PackedScene):
	enemy_pool.append(enemy_scene)

# Set difficulty scaling
func set_difficulty_scale(scale: float):
	difficulty_scale = scale

# Add environment rule
func add_environment_rule(key: String, value):
	environment_rules[key] = value

# Add reward
func add_reward(key: String, value):
	rewards[key] = value
