extends CharacterBody2D

class_name BaseEnemy

# Base stats that can be overridden by child classes
var SPEED = 800.0
var DAMAGE = 15
var ATTACK_COOLDOWN = 0.8
var KNOCKBACK_FORCE = 300.0
var MAX_HEALTH = 10
var DEATH_ANIMATION_DURATION = 1.5
var SCORE_VALUE = 100  # Base score value for killing this enemy

# Target behavior - to be overridden by child classes
var targets_food = false  # false = targets player, true = targets food

# Audio constants
const MIN_PITCH = 1.5
const MAX_PITCH = 3.0

# Eating sound constants
const EATING_SOUND = preload("res://sounds/eating.mp3")

# Sound arrays
var hurt_sounds: Array[AudioStream] = [
	preload("res://sounds/enemy_hurt/hurt.mp3"),
	preload("res://sounds/enemy_hurt/hurt2.mp3"),
	preload("res://sounds/enemy_hurt/hurt3.mp3")
]

var death_sounds: Array[AudioStream] = [
	preload("res://sounds/enemy_death/enemy-death.mp3"),
	preload("res://sounds/enemy_death/enemy-death2.mp3"),
	preload("res://sounds/enemy_death/enemy-death3.mp3"),
	preload("res://sounds/enemy_death/enemy-death4.mp3"),
	preload("res://sounds/enemy_death/enemy-death5.mp3"),
	preload("res://sounds/enemy_death/enemy-death6.mp3"),
	preload("res://sounds/enemy_death/wilhelm-scream.mp3")
]

const KO_SOUND = preload("res://sounds/hit-KO.mp3")

# Utility references
const TimeUtils = preload("res://scenes/utility-scripts/utils/time_utils.gd")
const AudioUtils = preload("res://scenes/utility-scripts/utils/audio_utils.gd")
const PopupUtils = preload("res://scenes/utility-scripts/utils/popup_utils.gd")
const BloodEffectsManager = preload("res://scenes/utility-scripts/utils/blood_effects_manager.gd")
const HealthComponent = preload("res://scenes/utility-scripts/utils/health_component.gd")
const CacheManager = preload("res://scenes/utility-scripts/utils/cache_manager.gd")
const UIEventManager = preload("res://scenes/utility-scripts/utils/ui_event_manager.gd")

var player: CharacterBody2D
var current_target: Node
var attack_timer = 0.0
var knockback_velocity = Vector2.ZERO
var health_component: HealthComponent
var is_dying = false
var death_timer = 0.0
var rotation_speed = 0.0
var fall_velocity = 0.0

# Cached references for performance
var _player_cache: CharacterBody2D = null
var _target_update_timer: float = 0.0
const TARGET_UPDATE_INTERVAL = 0.2  # Update target every 200ms
var _spawner_cache: Node = null
var _ui_cache: Node = null
var _popup_manager_cache: Node = null
var _ui_event_manager_cache: Node = null
var _cache_cleanup_timer: float = 0.0
const CACHE_CLEANUP_INTERVAL = 2.0  # Clean cache every 2 seconds

# Continuous attack variables
var is_attacking_food = false
var current_food_target: Node
var continuous_attack_timer = 0.0
var CONTINUOUS_ATTACK_INTERVAL = 2.0  # Attack every 2 seconds while in contact

# Eating sound variables
var eating_sound_player: AudioStreamPlayer2D

func _ready():
	add_to_group("enemies")
	# Find the player reference
	player = get_tree().get_first_node_in_group("player")
	
	# Initialize health component
	health_component = HealthComponent.new(self, MAX_HEALTH)
	
	# Connect health component signals
	health_component.health_depleted.connect(_on_health_depleted)
	health_component.damage_taken.connect(_on_damage_taken)
	
	# Initialize eating sound player for AudioUtils running sound system
	eating_sound_player = AudioStreamPlayer2D.new()
	add_child(eating_sound_player)
	
	# Set up bullet detection Area2D
	var bullet_detector = $BulletDetector
	if bullet_detector:
		bullet_detector.body_entered.connect(_on_bullet_hit)
		bullet_detector.add_to_group("enemies")  # Add Area2D to enemies group for wave detection
	
	# Initialize cached references
	_initialize_cached_references()
	
	# Set up food detection Area2D
	var food_detector = $FoodDetector
	if food_detector:
		food_detector.area_entered.connect(_on_food_collision)
		food_detector.area_exited.connect(_on_food_exit)

func _initialize_cached_references():
	# Cache frequently accessed nodes
	_refresh_all_caches()
	_target_update_timer = 0.0

func _refresh_all_caches():
	# Centralized cache refresh for all frequently accessed nodes
	_player_cache = CacheManager.get_first_node_in_group_cached("player", get_tree())
	player = _player_cache  # Update reference
	_spawner_cache = CacheManager.get_first_node_in_group_cached("enemy_spawner", get_tree())
	_ui_cache = CacheManager.get_first_node_in_group_cached("ui", get_tree())
	_popup_manager_cache = CacheManager.get_first_node_in_group_cached("popup_manager", get_tree())
	_ui_event_manager_cache = CacheManager.get_first_node_in_group_cached("ui_event_manager", get_tree())

func _ensure_valid_cache(cache_var: Node, group_name: String) -> Node:
	# Consolidated cache validation with fallback
	if cache_var == null or not is_instance_valid(cache_var):
		return CacheManager.get_first_node_in_group_cached(group_name, get_tree())
	return cache_var

func _on_health_depleted():
	_start_death_animation()

func _on_damage_taken(amount: int):
	# Increment player combo streak immediately for feedback (consolidated cache)
	_player_cache = _ensure_valid_cache(_player_cache, "player")
	if _player_cache:
		_player_cache.increment_combo_streak()
	
	# Play hurt sound when damaged (but not when dying)
	if health_component.health > 0:
		_play_hurt_sound()

func _on_food_collision(body):
	if body.is_in_group("food"):
		# Check if this enemy targets food
		if targets_food:
			_start_continuous_food_attack(body)

func _start_continuous_food_attack(food_object):
	is_attacking_food = true
	current_food_target = food_object
	continuous_attack_timer = 0.0
	
	# Start eating sound on loop
	_start_eating_sound()
	
	# Deal immediate damage on first contact
	var knockback_direction = (current_food_target.global_position - global_position).normalized()
	current_food_target.take_damage(DAMAGE, knockback_direction)

func _stop_continuous_food_attack():
	is_attacking_food = false
	current_food_target = null
	
	# Stop eating sound
	_stop_eating_sound()

func _update_continuous_food_attack(delta):
	if is_attacking_food and current_food_target:
		continuous_attack_timer += delta
		
		if continuous_attack_timer >= CONTINUOUS_ATTACK_INTERVAL:
			# Calculate knockback direction (from enemy to food)
			var knockback_direction = (current_food_target.global_position - global_position).normalized()
			
			# Food has take_damage method, call it directly
			current_food_target.take_damage(DAMAGE, knockback_direction)
			
			continuous_attack_timer = 0.0

func _on_food_exit(body):
	if body.is_in_group("food"):
		_stop_continuous_food_attack()

func _on_bullet_hit(body):
	if body.is_in_group("bullets"):
		# Calculate knockback direction (from enemy to bullet)
		var knockback_direction = (global_position - body.global_position).normalized()
		
		# Take damage and check if killed
		var was_killed = take_damage(10, knockback_direction)
		
		# Destroy bullet
		body.queue_free()
		
		# Death processing is now centralized in _start_death_animation()
		# which is called automatically when health is depleted via health component signal

func _play_hurt_sound():
	# Use AudioUtils pool for hurt sound
	var random_sound = hurt_sounds[randi() % hurt_sounds.size()]
	AudioUtils.play_positioned_sound(random_sound, global_position, MIN_PITCH, MAX_PITCH)

func _spawn_blood_splash(hit_direction: Vector2 = Vector2.ZERO):
	# Use centralized blood effects manager
	BloodEffectsManager.spawn_enemy_blood_splash(global_position, hit_direction, is_dying, self)

func _find_target():
	# Check if this enemy targets food or player
	if targets_food:
		# Find nearest food (cached)
		var food_objects = CacheManager.get_nodes_in_group_cached("food", get_tree())
		
		if food_objects.size() > 0:
			var new_target = _get_nearest_node(food_objects)
			if new_target and is_instance_valid(new_target):
				current_target = new_target
			else:
				# Force cache refresh and try again
				CacheManager.cleanup_invalid_references()
				food_objects = get_tree().get_nodes_in_group("food")
				if food_objects.size() > 0:
					current_target = _get_nearest_node(food_objects)
				else:
					_fallback_to_player()
		else:
			# If no food available, fall back to cached player
			_fallback_to_player()
	else:
		# Target cached player
		_player_cache = _ensure_valid_cache(_player_cache, "player")
		current_target = _player_cache

func _fallback_to_player():
	_player_cache = _ensure_valid_cache(_player_cache, "player")
	if _player_cache and is_instance_valid(_player_cache):
		current_target = _player_cache
	else:
		# Last resort - find player directly
		current_target = get_tree().get_first_node_in_group("player")

func _get_nearest_node(nodes: Array) -> Node:
	if nodes.is_empty():
		return null
	
	var nearest_node = null
	var nearest_distance = INF
	
	# Filter out invalid nodes and find nearest valid one
	for node in nodes:
		if not is_instance_valid(node):
			continue  # Skip freed nodes
			
		var distance = global_position.distance_to(node.global_position)
		if nearest_node == null or distance < nearest_distance:
			nearest_distance = distance
			nearest_node = node
	
	return nearest_node

func _physics_process(delta):
	# Skip all processing if dying
	if is_dying:
		return
	
	# Update target cache periodically
	_target_update_timer += delta
	if _target_update_timer >= TARGET_UPDATE_INTERVAL:
		_find_target()
		_target_update_timer = 0.0
	
	# Periodic cache cleanup (every 2 seconds)
	_cache_cleanup_timer += delta
	if _cache_cleanup_timer >= CACHE_CLEANUP_INTERVAL:
		CacheManager.cleanup_invalid_references()
		_cache_cleanup_timer = 0.0
	
	# Update attack cooldown
	if attack_timer > 0:
		attack_timer -= delta
	
	# Update continuous food attack
	_update_continuous_food_attack(delta)
	
	# Apply knockback decay (slower decay to allow proper knockback)
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 100.0 * delta)
	
	# Apply knockback to movement
	if knockback_velocity.length() > 1.0:
		velocity = knockback_velocity
		move_and_slide()
		return  # Skip normal movement when being knocked back
	
	# Follow cached target
	if current_target and is_instance_valid(current_target):
		var direction = (current_target.global_position - global_position).normalized()
		
		# Add collision avoidance for other enemies
		var avoidance_vector = _calculate_enemy_avoidance()
		direction = (direction + avoidance_vector).normalized()
		
		# Move towards target with avoidance
		velocity = direction * SPEED
		move_and_slide()
		
		# Check collision with target
		for i in range(get_slide_collision_count()):
			var collision = get_slide_collision(i)
			if collision.get_collider() == current_target:
				_attack_target()
				# Stop moving when attacking
				velocity = Vector2.ZERO

func _calculate_enemy_avoidance() -> Vector2:
	var avoidance = Vector2.ZERO
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	for enemy in enemies:
		if enemy == self or not is_instance_valid(enemy):
			continue
		
		var distance = global_position.distance_to(enemy.global_position)
		if distance < 50.0 and distance > 0:  # Avoid enemies within 50 pixels
			var away_direction = (global_position - enemy.global_position).normalized()
			var strength = 1.0 - (distance / 50.0)  # Stronger avoidance when closer
			avoidance += away_direction * strength
	
	return avoidance

func _attack_food(food_object):
	# Only attack if cooldown is ready
	if attack_timer <= 0:
		# Calculate knockback direction (from enemy to food)
		var knockback_direction = (food_object.global_position - global_position).normalized()
		
		# Food has take_damage method, call it directly
		food_object.take_damage(DAMAGE, knockback_direction)
		
		attack_timer = ATTACK_COOLDOWN

func _attack_target():
	# Only attack if cooldown is ready
	if attack_timer <= 0:
		# Prevent food-targeting enemies from attacking the player
		if targets_food and current_target == player:
			return  # Don't attack the player if we target food
		
		# Calculate knockback direction (from enemy to target)
		var knockback_direction = (current_target.global_position - global_position).normalized()
		
		# Check if target has take_damage method (player, food, etc.)
		if current_target.has_method("take_damage"):
			current_target.take_damage(DAMAGE, knockback_direction)
		
		attack_timer = ATTACK_COOLDOWN

func take_damage(damage: int, knockback_direction: Vector2):
	# Apply knockback
	knockback_velocity = knockback_direction * KNOCKBACK_FORCE
	
	# Use health component to handle damage (signals handle combo, sounds, and effects)
	var was_killed = health_component.take_damage(damage, knockback_direction, true)
	
	return was_killed  # Enemy was killed if health depleted

func _start_death_animation():
	is_dying = true
	
	# Add score using cached UI event manager (consolidated cache)
	_ui_event_manager_cache = _ensure_valid_cache(_ui_event_manager_cache, "ui_event_manager")
	if _ui_event_manager_cache:
		_ui_event_manager_cache.add_score(SCORE_VALUE)
	
	# Use PopupManager for score popup (consolidated cache)
	_popup_manager_cache = _ensure_valid_cache(_popup_manager_cache, "popup_manager")
	if _popup_manager_cache:
		_popup_manager_cache.spawn_floating_popup(self, "+" + str(SCORE_VALUE), Color.YELLOW, Vector2(0, -50), 64)
	
	# Notify enemy spawner to increase spawn frequency and update UI kill counter (consolidated cache)
	_spawner_cache = _ensure_valid_cache(_spawner_cache, "enemy_spawner")
	if _spawner_cache:
		_spawner_cache.increment_kill_count()
	
	# Trigger slow-time effect
	TimeUtils.trigger_slow_time()
	
	# Play KO sound with random pitch
	AudioUtils.play_positioned_sound(KO_SOUND, global_position, 0.8, 1.5)
	
	# Play random death sound with random pitch
	AudioUtils.play_death_sound(death_sounds, global_position)
	
	# Spawn final blood burst
	_spawn_blood_splash(Vector2.ZERO)
	
	# Remove enemy immediately after blood burst
	queue_free()

func _start_eating_sound():
	# Use AudioUtils for consistent eating sound playback
	AudioUtils.play_running_sound(eating_sound_player, EATING_SOUND)

func _stop_eating_sound():
	# Stop the eating sound directly
	if eating_sound_player and eating_sound_player.playing:
		eating_sound_player.stop()
