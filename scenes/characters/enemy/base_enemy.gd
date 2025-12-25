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
const BLOOD_SPLASH_SCENE = preload("res://scenes/blood/blood_splash.tscn")

# Utility references
const TimeUtils = preload("res://scenes/utility-scripts/utils/time_utils.gd")
const AudioUtils = preload("res://scenes/utility-scripts/utils/audio_utils.gd")
const PopupUtils = preload("res://scenes/utility-scripts/utils/popup_utils.gd")

var player: CharacterBody2D
var current_target: Node
var attack_timer = 0.0
var knockback_velocity = Vector2.ZERO
var health: int = MAX_HEALTH
var is_dying = false
var death_timer = 0.0
var rotation_speed = 0.0
var fall_velocity = 0.0

# Continuous attack variables
var is_attacking_food = false
var current_food_target: Node
var continuous_attack_timer = 0.0
var CONTINUOUS_ATTACK_INTERVAL = 2.0  # Attack every 2 seconds while in contact

func _ready():
	add_to_group("enemies")
	# Find the player reference
	player = get_tree().get_first_node_in_group("player")
	
	# Set up bullet detection Area2D
	var bullet_detector = $BulletDetector
	if bullet_detector:
		bullet_detector.body_entered.connect(_on_bullet_hit)
		bullet_detector.add_to_group("enemies")  # Add Area2D to enemies group for wave detection
	
	# Set up food detection Area2D
	var food_detector = $FoodDetector
	if food_detector:
		food_detector.area_entered.connect(_on_food_collision)
		food_detector.area_exited.connect(_on_food_exit)

func _on_food_collision(body):
	if body.is_in_group("food"):
		# Check if this enemy targets food
		if targets_food:
			_start_continuous_food_attack(body)

func _start_continuous_food_attack(food_object):
	is_attacking_food = true
	current_food_target = food_object
	continuous_attack_timer = 0.0
	
	# Deal immediate damage on first contact
	var knockback_direction = (current_food_target.global_position - global_position).normalized()
	current_food_target.take_damage(DAMAGE, knockback_direction)

func _stop_continuous_food_attack():
	is_attacking_food = false
	current_food_target = null

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
		print("DEBUG: _on_bullet_hit called")
		# Calculate knockback direction (from enemy to bullet)
		var knockback_direction = (global_position - body.global_position).normalized()
		
		# Take damage and check if killed
		var was_killed = take_damage(10, knockback_direction)
		print("DEBUG: Enemy was_killed: ", was_killed)
		
		# Destroy bullet
		body.queue_free()
		
		# Trigger slow-time effect only if enemy was killed
		if was_killed:
			print("DEBUG: Processing enemy death")
			TimeUtils.trigger_slow_time()
			
			# Add score for killing this enemy
			var ui = get_tree().get_first_node_in_group("ui")
			if ui:
				print("DEBUG: Enemy killed, adding ", SCORE_VALUE, " points")
				ui.add_to_score(SCORE_VALUE)
				# Use centralized popup system
				PopupUtils.spawn_score_popup(self, SCORE_VALUE)
			else:
				print("DEBUG: UI not found for score addition")
			
			# Notify enemy spawner to increase spawn frequency
			var spawner = get_tree().get_first_node_in_group("enemy_spawner")
			if spawner:
				print("DEBUG: Enemy death - calling increment_kill_count")
				spawner.increment_kill_count()
			else:
				print("DEBUG: Enemy death - spawner not found")
			
			# Increment individual kill count for milestone tracking
			if ui:
				print("DEBUG: About to call ui.increment_kill_count")
				ui.increment_kill_count()
			else:
				print("DEBUG: UI not found for milestone tracking")

func _play_hurt_sound():
	# Play random hurt sound with random pitch
	var random_sound = hurt_sounds[randi() % hurt_sounds.size()]
	var random_pitch = randf_range(MIN_PITCH, MAX_PITCH)
	
	# Create audio player
	var audio_player = AudioStreamPlayer.new()
	audio_player.stream = random_sound
	audio_player.pitch_scale = random_pitch
	audio_player.volume_db = -5.0  # Slightly quieter for balance
	
	# Add to scene and play
	add_child(audio_player)
	audio_player.play()
	
	# Remove after sound finishes
	audio_player.finished.connect(audio_player.queue_free)

func _spawn_blood_splash(hit_direction: Vector2 = Vector2.ZERO):
	# Create blood splash effect
	var blood_splash = BLOOD_SPLASH_SCENE.instantiate()
	if blood_splash:
		# Add to scene at bottom layer (first to be drawn)
		var scene = get_tree().current_scene
		if scene:
			scene.add_child(blood_splash)
			scene.move_child(blood_splash, 0)
			
			# Position at enemy location
			blood_splash.global_position = global_position
			
			# Set direction based on hit direction or random if none
			if hit_direction != Vector2.ZERO:
				blood_splash.set_direction(-hit_direction)  # Blood splashes opposite to hit direction
			else:
				blood_splash.set_direction(Vector2.from_angle(randf() * TAU))
			
			# Mark as dead enemy for reduced blood if dying
			if is_dying:
				blood_splash.set_dead_enemy(true)

func _find_target():
	# Temporarily disable food targeting to debug player movement issue
	# Override in child classes or use this default logic
	if false:  # targets_food - temporarily disabled
		# Find nearest food
		var food_objects = get_tree().get_nodes_in_group("food")
		if food_objects.size() > 0:
			current_target = _get_nearest_node(food_objects)
	else:
		# Target player
		current_target = player

func _get_nearest_node(nodes: Array) -> Node:
	if nodes.is_empty():
		return null
	
	var nearest_node = nodes[0]
	var nearest_distance = global_position.distance_to(nearest_node.global_position)
	
	for node in nodes:
		var distance = global_position.distance_to(node.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_node = node
	
	return nearest_node

func _physics_process(delta):
	# Skip all processing if dying
	if is_dying:
		return
	
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
	
	# Find and follow target
	_find_target()
	if current_target:
		var direction = (current_target.global_position - global_position).normalized()
		
		# Move towards target
		velocity = direction * SPEED
		move_and_slide()
		
		# Check collision with target
		for i in range(get_slide_collision_count()):
			var collision = get_slide_collision(i)
			if collision.get_collider() == current_target:
				_attack_target()
				# Stop moving when attacking
				velocity = Vector2.ZERO

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
		# Calculate knockback direction (from enemy to target)
		var knockback_direction = (current_target.global_position - global_position).normalized()
		
		# Check if target has take_damage method (player, food, etc.)
		if current_target.has_method("take_damage"):
			current_target.take_damage(DAMAGE, knockback_direction)
		
		attack_timer = ATTACK_COOLDOWN

func take_damage(damage: int, knockback_direction: Vector2):
	# Apply knockback
	knockback_velocity = knockback_direction * KNOCKBACK_FORCE
	
	# Take damage
	health = max(health - damage, 0)
	
	# Spawn blood splash effect
	_spawn_blood_splash(knockback_direction)
	
	# Increment player combo streak immediately for feedback
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.increment_combo_streak()
	
	# Play hurt sound when damaged (but not when dying)
	if health > 0:
		_play_hurt_sound()
	
	# Check if enemy should die
	if health <= 0:
		_start_death_animation()
		return true  # Enemy was killed
	
	return false  # Enemy survived

func _start_death_animation():
	is_dying = true
	# Enemy death logic
	
	print("DEBUG: Processing enemy death")
	
	# Add score for killing this enemy
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		print("DEBUG: Enemy killed, adding ", SCORE_VALUE, " points")
		ui.add_to_score(SCORE_VALUE)
		# Use centralized popup system
		PopupUtils.spawn_score_popup(self, SCORE_VALUE)
	else:
		print("DEBUG: UI not found for score addition")
	
	# Notify enemy spawner to increase spawn frequency
	var spawner = get_tree().get_first_node_in_group("enemy_spawner")
	if spawner:
		spawner.increment_kill_count()
	
	# Trigger slow-time effect with 10% chance on enemy death
	TimeUtils.trigger_slow_time()
	
	# Play KO sound with random pitch
	AudioUtils.play_positioned_sound(KO_SOUND, global_position, 0.8, 1.5)
	
	# Play random death sound with random pitch
	AudioUtils.play_death_sound(death_sounds, global_position)
	
	# Spawn final blood burst
	_spawn_blood_splash(Vector2.ZERO)
	
	# Remove enemy immediately after blood burst
	queue_free()
