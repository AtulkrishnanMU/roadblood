extends CharacterBody2D

const SPEED = 500.0
const DAMAGE = 10
const ATTACK_COOLDOWN = 1.0  # seconds between attacks
const KNOCKBACK_FORCE = 200.0  # knockback force when taking damage
const MAX_HEALTH = 10
const DEATH_ANIMATION_DURATION = 1.5  # seconds for death animation

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

func _physics_process(delta):
	if is_dying:
		_process_death_animation(delta)
		return
	
	# Update attack cooldown
	if attack_timer > 0:
		attack_timer -= delta
	
	# Apply knockback decay
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 300.0 * delta)
	
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

func _process_death_animation(delta):
	death_timer += delta
	
	# Rotate the enemy
	rotation += rotation_speed * delta
	
	# Fall down
	fall_velocity += 500.0 * delta  # Gravity
	position.y += fall_velocity * delta
	
	# Fade out
	var fade_progress = death_timer / DEATH_ANIMATION_DURATION
	modulate.a = 1.0 - fade_progress
	
	# Remove after animation completes
	if death_timer >= DEATH_ANIMATION_DURATION:
		queue_free()

func _attack_player():
	# Only attack if cooldown is ready
	if attack_timer <= 0:
		player.take_damage(DAMAGE)
		attack_timer = ATTACK_COOLDOWN

func take_damage(damage: int, knockback_direction: Vector2):
	# Apply knockback
	knockback_velocity = knockback_direction * KNOCKBACK_FORCE
	
	# Take damage
	health = max(health - damage, 0)
	
	# Check if enemy should die
	if health <= 0:
		_start_death_animation()
		return true  # Enemy was killed
	
	return false  # Enemy survived

func _start_death_animation():
	is_dying = true
	death_timer = 0.0
	rotation_speed = randf_range(5.0, 10.0)  # Random rotation speed
	fall_velocity = randf_range(-50.0, 50.0)  # Random initial fall velocity
	
	# Stop normal movement
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	
	# Disable collision
	collision_layer = 0
	collision_mask = 0
