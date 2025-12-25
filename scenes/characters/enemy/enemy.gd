extends CharacterBody2D

const SPEED = 800.0  # Increased from 600 to be much higher than player (400)
const DAMAGE = 15  # Increased from 10
const ATTACK_COOLDOWN = 0.8  # Reduced from 1.0 for faster attacks
const KNOCKBACK_FORCE = 300.0  # knockback force when taking damage (increased from 200)
const MAX_HEALTH = 10
const DEATH_ANIMATION_DURATION = 1.5  # seconds for death animation

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
const TimeUtils = preload("res://scripts/utils/time_utils.gd")

var player: CharacterBody2D
var attack_timer = 0.0
var knockback_velocity = Vector2.ZERO
var health: int = MAX_HEALTH
var is_dying = false
var death_timer = 0.0
var rotation_speed = 0.0
var fall_velocity = 0.0

func _ready():
	add_to_group("enemies")
	# Find the player reference
	player = get_tree().get_first_node_in_group("player")

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

func _physics_process(delta):
	# Skip all processing if dying
	if is_dying:
		return
	
	# Update attack cooldown
	if attack_timer > 0:
		attack_timer -= delta
	
	# Apply knockback decay (slower decay to allow proper knockback)
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 100.0 * delta)
	
	# Apply knockback to movement
	if knockback_velocity.length() > 1.0:
		velocity = knockback_velocity
		move_and_slide()
		return  # Skip normal movement when being knocked back
	
	# Follow player if available
	if player:
		var direction = (player.global_position - global_position).normalized()
		
		# Move towards player
		velocity = direction * SPEED
		move_and_slide()
		
		# Check collision with player
		for i in range(get_slide_collision_count()):
			var collision = get_slide_collision(i)
			if collision.get_collider() == player:
				_attack_player()
				# Add a new line here to make the enemy stop moving when attacking the player
				velocity = Vector2.ZERO

func _attack_player():
	# Only attack if cooldown is ready
	if attack_timer <= 0:
		# Calculate knockback direction (from enemy to player)
		var knockback_direction = (player.global_position - global_position).normalized()
		player.take_damage(DAMAGE, knockback_direction)
		attack_timer = ATTACK_COOLDOWN

func take_damage(damage: int, knockback_direction: Vector2):
	# Apply knockback
	knockback_velocity = knockback_direction * KNOCKBACK_FORCE
	
	# Take damage
	health = max(health - damage, 0)
	
	# Spawn blood splash effect
	_spawn_blood_splash(knockback_direction)
	
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
