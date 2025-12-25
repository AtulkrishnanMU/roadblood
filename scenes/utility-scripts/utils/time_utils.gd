extends Node

# Singleton instance
static var instance: Node

# Time scale constants
const SLOW_TIME_SCALE = 0.3  # Slow-motion time scale (30% speed)
const SLOW_TIME_DURATION = 1.0  # Duration in seconds
const SLOW_TIME_CHANCE = 0.1  # 10% chance to trigger slow-time (once every 10 kills on average)

# Time tracking variables
var original_time_scale: float
var is_slow_time_active: bool = false
var slow_time_timer: float = 0.0

func _ready():
	# Set up singleton reference
	instance = self
	original_time_scale = Engine.time_scale
	add_to_group("time_utils")  # Add to group for player to find

func _process(delta):
	if is_slow_time_active:
		slow_time_timer -= delta
		if slow_time_timer <= 0:
			_disable_slow_time()

static func trigger_slow_time():
	if instance and not instance.is_slow_time_active:
		# Get current enemy count
		var enemy_count = 0
		var enemies = instance.get_tree().get_nodes_in_group("enemies")
		enemy_count = enemies.size()
		
		# Calculate slow-time chance inversely proportional to enemy count
		# Base chance is 10% for 1 enemy, decreases as more enemies spawn
		var base_chance = 0.1
		var calculated_chance = base_chance / max(enemy_count, 1)
		
		# Ensure minimum chance of 2% and maximum of 20%
		calculated_chance = clamp(calculated_chance, 0.02, 0.2)
		
		if randf() <= calculated_chance:
			instance._enable_slow_time()

func _enable_slow_time():
	is_slow_time_active = true
	slow_time_timer = SLOW_TIME_DURATION
	Engine.time_scale = SLOW_TIME_SCALE

func _disable_slow_time():
	is_slow_time_active = false
	Engine.time_scale = original_time_scale
