extends Node2D

# Core level system - never rewrite this logic
signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal level_completed
signal game_over

# Level configuration - to be overridden by child levels
var level_config: Dictionary

# Game state
var current_wave: int = 0
var wave_timer: float = 0.0
var is_wave_active: bool = false
var level_active: bool = false

# References
var player: CharacterBody2D
var food_objects: Array[Node] = []
var enemy_spawner: Node
var ui_manager: Node

# Wave management
var spawn_timer: float = 0.0
var current_wave_timer: Timer
var current_spawn_timer: Timer

# Intelligent spawn rate system
var base_spawn_rate: float = 1.0
var current_spawn_rate: float = 1.0
var player_hits_this_wave: int = 0
var enemies_killed_this_wave: int = 0
var last_performance_check_time: float = 0.0
const PERFORMANCE_CHECK_INTERVAL: float = 5.0  # Check performance every 5 seconds
const SPAWN_RATE_ADJUSTMENT_FACTOR: float = 0.2  # 20% adjustment per check
const MIN_SPAWN_RATE_MULTIPLIER: float = 0.5  # Never go below 50% of base rate
const MAX_SPAWN_RATE_MULTIPLIER: float = 2.0  # Never go above 200% of base rate

# Health-based performance tracking
var initial_player_health: int = 100
var initial_food_health: int = 0
var current_player_health: int = 100
var current_food_health: int = 0
const FOOD_HEALTH_WEIGHT: float = 0.5  # Weight of food health in performance calculation
const PLAYER_HEALTH_WEIGHT: float = 0.3  # Weight of player health in performance calculation
const COMBAT_WEIGHT: float = 0.2  # Weight of combat performance in calculation

# Progressive spawn range system
var current_spawn_range: Array[int] = [1, 1]  # [min, max] enemies per spawn
var base_spawn_range: Array[int] = [1, 1]  # Original range from level config
var wave_start_time: float = 0.0
var wave_duration: float = 60.0
const SPAWN_RANGE_ADJUSTMENT_FACTOR: float = 0.3  # 30% adjustment per check
const MIN_SPAWN_RANGE_MULTIPLIER: float = 0.5  # Never go below 50% of base range
const MAX_SPAWN_RANGE_MULTIPLIER: float = 1.5  # Never go above 150% of base range

func _ready():
	# Initialize level configuration
	level_config = create_level_config()
	
	# Find essential game objects
	_setup_references()
	
	# Connect to game events
	_connect_signals()
	
	# Start the level
	start_level()

func _setup_references():
	player = get_tree().get_first_node_in_group("player")
	enemy_spawner = get_tree().get_first_node_in_group("enemy_spawner")
	ui_manager = get_tree().get_first_node_in_group("ui")
	
	# Find all food objects
	food_objects = get_tree().get_nodes_in_group("food")

func _connect_signals():
	# Connect to food destruction signals
	for food in food_objects:
		if food.has_signal("health_depleted"):
			food.health_depleted.connect(_on_food_destroyed)
		# Also connect to food health changes for performance tracking
		if food.has_signal("health_changed"):
			food.health_changed.connect(_on_food_health_changed)
		elif food.has_method("get_health_component"):
			var health_comp = food.get_health_component()
			if health_comp and health_comp.has_signal("health_changed"):
				health_comp.health_changed.connect(_on_food_health_changed)
	
	# Connect to enemy spawner signals
	if enemy_spawner and enemy_spawner.has_signal("enemy_killed"):
		enemy_spawner.enemy_killed.connect(_on_enemy_killed)
	
	# Connect to player damage signal for intelligent spawn rate adjustment
	if player and player.has_signal("damage_taken"):
		player.damage_taken.connect(_on_player_damaged)
	
	# Connect to player health changes for health-based performance tracking
	if player and player.has_signal("health_changed"):
		player.health_changed.connect(_on_player_health_changed)
	elif player and player.has_method("get_health_component"):
		var health_comp = player.get_health_component()
		if health_comp and health_comp.has_signal("health_changed"):
			health_comp.health_changed.connect(_on_player_health_changed)

func start_level():
	level_active = true
	current_wave = 0
	start_next_wave()

func start_next_wave():
	if current_wave >= level_config.waves.size():
		# All waves completed - level won!
		_complete_level()
		return
	
	current_wave += 1
	is_wave_active = true
	
	# Reset performance tracking for new wave
	player_hits_this_wave = 0
	enemies_killed_this_wave = 0
	last_performance_check_time = 0.0
	wave_start_time = Time.get_ticks_msec() / 1000.0
	
	# Initialize health tracking
	if player:
		initial_player_health = player.MAX_HEALTH
		current_player_health = initial_player_health
	else:
		initial_player_health = 100
		current_player_health = 100
	
	# Initialize food health tracking (only one food object)
	if food_objects.size() > 0:
		var food = food_objects[0]  # Get the single food object
		if food.has_method("get_max_health"):
			initial_food_health = food.get_max_health()
			current_food_health = initial_food_health
		elif food.has_method("get_health_component"):
			var health_comp = food.get_health_component()
			if health_comp and health_comp.has_method("get_max_health"):
				initial_food_health = health_comp.get_max_health()
				current_food_health = initial_food_health
		else:
			initial_food_health = 100  # Default fallback
			current_food_health = 100
	else:
		initial_food_health = 100  # Default fallback
		current_food_health = 100
	
	var wave_data = level_config.waves[current_wave - 1]
	base_spawn_rate = wave_data.spawn_rate
	current_spawn_rate = base_spawn_rate  # Start with base rate
	wave_duration = level_config.wave_duration
	
	# Set spawn range from wave config
	if wave_data.has("spawn_range"):
		var range_array = wave_data.spawn_range
		base_spawn_range = [int(range_array[0]), int(range_array[1])]
		current_spawn_range = [int(range_array[0]), int(range_array[1])]
	else:
		base_spawn_range = [1, 1]  # Default to 1 if not specified
		current_spawn_range = [1, 1]
	
	print("Starting Wave ", current_wave, " - Max enemies: ", wave_data.max_enemies, 
		  ", Base spawn rate: ", base_spawn_rate, ", Spawn range: ", current_spawn_range[0], "-", current_spawn_range[1])
	
	# Show wave UI
	if ui_manager and ui_manager.has_method("show_wave_start"):
		ui_manager.show_wave_start(current_wave, level_config.wave_duration)
	
	# Configure spawner for this wave
	_configure_wave_spawner(wave_data)
	
	# Start wave timer
	_start_wave_timer(level_config.wave_duration)
	
	# Start enemy spawning
	_start_enemy_spawning(wave_data)
	
	emit_signal("wave_started", current_wave)

func _configure_wave_spawner(wave_data: Dictionary):
	if not enemy_spawner:
		return
	
	# Convert spawn points to typed array
	var spawn_points: Array[Vector2] = []
	for point in level_config.spawn_points:
		spawn_points.append(Vector2(point.x, point.y))
	
	# Convert enemy pool to typed array
	var enemy_pool: Array[PackedScene] = []
	for enemy in wave_data.allowed_enemies:
		enemy_pool.append(enemy)
	
	# Configure spawner with current (adjusted) spawn rate
	if enemy_spawner.has_method("set_spawn_points"):
		enemy_spawner.set_spawn_points(spawn_points)
	if enemy_spawner.has_method("set_enemy_pool"):
		enemy_spawner.set_enemy_pool(enemy_pool)
	if enemy_spawner.has_method("set_spawn_rate"):
		enemy_spawner.set_spawn_rate(current_spawn_rate)
	if enemy_spawner.has_method("set_max_enemies"):
		enemy_spawner.set_max_enemies(wave_data.max_enemies)
	if enemy_spawner.has_method("set_spawn_range"):
		enemy_spawner.set_spawn_range(current_spawn_range)

func _start_wave_timer(duration: float):
	# Clean up previous timer
	if current_wave_timer:
		current_wave_timer.queue_free()
	
	current_wave_timer = Timer.new()
	current_wave_timer.wait_time = duration
	current_wave_timer.timeout.connect(_complete_wave)
	add_child(current_wave_timer)
	current_wave_timer.start()

func _start_enemy_spawning(wave_data: Dictionary):
	# Clean up previous timer
	if current_spawn_timer:
		current_spawn_timer.queue_free()
	
	current_spawn_timer = Timer.new()
	_update_spawn_timer()  # Use intelligent spawn rate
	current_spawn_timer.timeout.connect(_attempt_spawn_enemy)
	add_child(current_spawn_timer)
	current_spawn_timer.start()

func _update_spawn_timer():
	# Update timer with current spawn rate
	if current_spawn_timer:
		var spawn_interval = 1.0 / current_spawn_rate
		current_spawn_timer.wait_time = spawn_interval

func _adjust_spawn_rate_based_on_performance():
	# Calculate combat performance ratio (hits vs kills)
	var combat_ratio = 0.0
	if enemies_killed_this_wave > 0:
		combat_ratio = float(player_hits_this_wave) / float(enemies_killed_this_wave)
	elif player_hits_this_wave > 0:
		# Player is getting hit but not killing enemies - struggling
		combat_ratio = 2.0  # High ratio indicates difficulty
	else:
		# No hits, no kills - neutral
		combat_ratio = 0.5  # Slightly favoring player
	
	# Calculate health performance ratio
	var health_ratio = 0.0
	if initial_player_health > 0:
		var health_percentage = float(current_player_health) / float(initial_player_health)
		# Invert so that lower health = higher ratio (more difficulty needed)
		health_ratio = 1.0 - health_percentage
	else:
		health_ratio = 0.5  # Neutral if no health data
	
	# Calculate food health ratio
	var food_health_ratio = 0.0
	if initial_food_health > 0:
		var food_health_percentage = float(current_food_health) / float(initial_food_health)
		# Invert so that lower food health = higher ratio (more difficulty needed)
		food_health_ratio = 1.0 - food_health_percentage
	else:
		food_health_ratio = 0.5  # Neutral if no food health data
	
	# Combine all performance factors with updated weights
	var combined_performance = (combat_ratio * COMBAT_WEIGHT) + (health_ratio * PLAYER_HEALTH_WEIGHT) + (food_health_ratio * FOOD_HEALTH_WEIGHT)
	
	# Adjust spawn rate based on combined performance
	var spawn_rate_adjustment = 0.0
	var spawn_range_adjustment = 0.0
	
	if combined_performance > 1.5:
		# Player struggling - reduce difficulty
		spawn_rate_adjustment = -SPAWN_RATE_ADJUSTMENT_FACTOR
		spawn_range_adjustment = -SPAWN_RANGE_ADJUSTMENT_FACTOR
	elif combined_performance < 0.5:
		# Player doing well - increase difficulty
		spawn_rate_adjustment = SPAWN_RATE_ADJUSTMENT_FACTOR
		spawn_range_adjustment = SPAWN_RANGE_ADJUSTMENT_FACTOR
	else:
		# Balanced performance - minor adjustment toward center
		if current_spawn_rate > base_spawn_rate:
			spawn_rate_adjustment = -SPAWN_RATE_ADJUSTMENT_FACTOR * 0.5
			spawn_range_adjustment = -SPAWN_RANGE_ADJUSTMENT_FACTOR * 0.5
		else:
			spawn_rate_adjustment = SPAWN_RATE_ADJUSTMENT_FACTOR * 0.5
			spawn_range_adjustment = SPAWN_RANGE_ADJUSTMENT_FACTOR * 0.5
	
	# Apply spawn rate adjustment with bounds
	var new_rate = current_spawn_rate + (base_spawn_rate * spawn_rate_adjustment)
	var min_rate = base_spawn_rate * MIN_SPAWN_RATE_MULTIPLIER
	var max_rate = base_spawn_rate * MAX_SPAWN_RATE_MULTIPLIER
	current_spawn_rate = clamp(new_rate, min_rate, max_rate)
	
	# Apply spawn range adjustment with bounds
	var base_min = base_spawn_range[0]
	var base_max = base_spawn_range[1]
	
	var new_min = int(base_min + (base_min * spawn_range_adjustment))
	var new_max = int(base_max + (base_max * spawn_range_adjustment))
	
	var range_min = int(base_min * MIN_SPAWN_RANGE_MULTIPLIER)
	var range_max = int(base_max * MAX_SPAWN_RANGE_MULTIPLIER)
	
	# Ensure minimum of 1 enemy
	range_min = max(range_min, 1)
	range_max = max(range_max, 1)
	
	current_spawn_range[0] = clamp(new_min, range_min, range_max)
	current_spawn_range[1] = clamp(new_max, range_min, range_max)
	
	# Ensure max >= min
	if current_spawn_range[1] < current_spawn_range[0]:
		current_spawn_range[1] = current_spawn_range[0]
	
	# Update spawner and timer
	if enemy_spawner and enemy_spawner.has_method("set_spawn_rate"):
		enemy_spawner.set_spawn_rate(current_spawn_rate)
	_update_spawn_timer()
	
	print("Performance check - Combat: ", combat_ratio, ", Player Health: ", health_ratio, ", Food Health: ", food_health_ratio,
		  ", Combined: ", combined_performance, ", New spawn rate: ", current_spawn_rate, 
		  ", New spawn range: ", current_spawn_range[0], "-", current_spawn_range[1])

func _get_current_spawn_count() -> int:
	# Calculate progress through wave (0.0 to 1.0)
	var current_time = Time.get_ticks_msec() / 1000.0
	var wave_progress = clamp((current_time - wave_start_time) / wave_duration, 0.0, 1.0)
	
	# Interpolate between min and max spawn count
	var min_count = current_spawn_range[0]
	var max_count = current_spawn_range[1]
	var current_count = int(min_count + (max_count - min_count) * wave_progress)
	
	return current_count

func _update_spawner_spawn_count():
	if not enemy_spawner or not enemy_spawner.has_method("set_enemies_per_spawn"):
		return
	
	var current_count = _get_current_spawn_count()
	enemy_spawner.set_enemies_per_spawn(current_count)

func _attempt_spawn_enemy():
	if not enemy_spawner:
		return
	
	# Update spawn count based on wave progress before spawning
	_update_spawner_spawn_count()
	
	var success = enemy_spawner.spawn_enemy()
	if success:
		print("Enemy spawned successfully")
	else:
		print("Enemy spawn blocked - max enemies reached")

func _complete_wave():
	is_wave_active = false
	
	# Clean up timers
	if current_wave_timer:
		current_wave_timer.queue_free()
		current_wave_timer = null
	if current_spawn_timer:
		current_spawn_timer.queue_free()
		current_spawn_timer = null
	
	# Spawn circular wave to clean up remaining enemies
	_spawn_cleanup_wave()
	
	# Hide wave UI temporarily
	if ui_manager and ui_manager.has_method("hide_wave_ui"):
		ui_manager.hide_wave_ui()
	
	print("Wave completed! Cleanup wave released. Starting next wave in 2 seconds...")
	
	emit_signal("wave_completed", current_wave)
	
	# Start next wave after delay
	await get_tree().create_timer(2.0).timeout
	start_next_wave()

func _spawn_cleanup_wave():
	# Spawn circular wave to clean up remaining enemies
	if enemy_spawner and enemy_spawner.has_method("spawn_circular_wave"):
		print("Spawning cleanup wave to clear remaining enemies...")
		enemy_spawner.spawn_circular_wave()
	else:
		print("Warning: Could not spawn cleanup wave - enemy_spawner not found or missing method")

func _complete_level():
	level_active = false
	
	# Hide wave UI
	if ui_manager and ui_manager.has_method("hide_wave_ui"):
		ui_manager.hide_wave_ui()
	
	print("LEVEL COMPLETE!")
	emit_signal("level_completed")

func _on_food_destroyed():
	# Update current food health to 0 since food is destroyed
	current_food_health = 0
	# Check performance periodically
	_check_performance_if_needed()
	# Lose condition: any food destroyed
	_trigger_game_over()

func _on_food_health_changed(current: int, max: int):
	current_food_health = current
	# Check performance periodically
	_check_performance_if_needed()

func _on_enemy_killed():
	enemies_killed_this_wave += 1
	# Check performance periodically
	_check_performance_if_needed()

func _on_player_damaged(amount: int):
	player_hits_this_wave += 1
	# Update current player health if possible
	_update_current_health()
	# Check performance periodically
	_check_performance_if_needed()

func _on_player_health_changed(current: int, max: int):
	current_player_health = current
	# Check performance periodically
	_check_performance_if_needed()

func _update_current_health():
	if player and player.has_method("get_health_component"):
		var health_comp = player.get_health_component()
		if health_comp and health_comp.has_method("get_current_health"):
			current_player_health = health_comp.get_current_health()

func _check_performance_if_needed():
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_performance_check_time >= PERFORMANCE_CHECK_INTERVAL:
		_adjust_spawn_rate_based_on_performance()
		last_performance_check_time = current_time

func _trigger_game_over():
	level_active = false
	
	# Clean up timers
	if current_wave_timer:
		current_wave_timer.queue_free()
	if current_spawn_timer:
		current_spawn_timer.queue_free()
	
	# Hide wave UI
	if ui_manager and ui_manager.has_method("hide_wave_ui"):
		ui_manager.hide_wave_ui()
	
	print("GAME OVER!")
	emit_signal("game_over")
	
	# Directly call the game over message to ensure it shows
	_show_game_over_message()

# Virtual method to be overridden by child levels
func create_level_config() -> Dictionary:
	# Default configuration - should be overridden
	return {
		"wave_duration": 60.0,
		"spawn_points": [],
		"enemy_pool": [],
		"waves": []
	}

func get_wave_progress() -> float:
	if not is_wave_active or level_config.wave_duration <= 0:
		return 0.0
	return 1.0 - (wave_timer / level_config.wave_duration)

func get_level_progress() -> float:
	if level_config.waves.size() == 0:
		return 0.0
	return float(current_wave) / float(level_config.waves.size())

func _show_wave_start_message():
	if ui_manager and ui_manager.has_method("show_wave_message"):
		ui_manager.show_wave_message("Wave " + str(current_wave) + " Started!")

func _show_wave_complete_message():
	if ui_manager and ui_manager.has_method("show_wave_message"):
		ui_manager.show_wave_message("Wave " + str(current_wave) + " Complete!")

func _show_level_complete_message():
	if ui_manager and ui_manager.has_method("show_level_message"):
		ui_manager.show_level_message("Level Complete!")

func _show_game_over_message():
	if ui_manager and ui_manager.has_method("show_game_over_message"):
		ui_manager.show_game_over_message("Game Over!")
