extends CharacterBody2D

var speed = 1500  # Increased from 600
var direction = Vector2.ZERO
const LIFETIME = 3.0  # seconds before auto-destroy
const FADE_START_TIME = 2.0  # seconds before fade starts
var lifetime_timer = 0.0
var color_rect: ColorRect

func _ready():
	color_rect = $ColorRect
	add_to_group("bullets")

func _physics_process(delta):
	# Move and check collisions
	velocity = direction * speed
	move_and_slide()
	
	# Update lifetime timer
	lifetime_timer += delta
	
	# Start fading after 4 seconds
	if lifetime_timer >= FADE_START_TIME:
		var fade_progress = (lifetime_timer - FADE_START_TIME) / (LIFETIME - FADE_START_TIME)
		var alpha = 1.0 - fade_progress
		color_rect.modulate.a = clamp(alpha, 0.0, 1.0)
	
	# Auto-destroy after lifetime
	if lifetime_timer >= LIFETIME:
		queue_free()
	
	# Check collision with enemies
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.is_in_group("enemies"):
			_on_enemy_hit(collider)
			# Destroy bullet after hit
			queue_free()
			return

func _on_enemy_hit(enemy):
	# Calculate knockback direction (from enemy to bullet)
	var knockback_direction = (enemy.global_position - global_position).normalized()
	
	# Damage enemy with knockback and check if killed
	var was_killed = enemy.take_damage(10, knockback_direction)
	
	# Trigger slow-time effect only if enemy was killed
	if was_killed:
		const TimeUtils = preload("res://scenes/utility-scripts/utils/time_utils.gd")
		TimeUtils.trigger_slow_time()

func setup(dir):
	direction = dir.normalized()
	rotation = direction.angle()
