extends Area2D

var speed = 1500  # Increased from 600
var direction = Vector2.ZERO
const LIFETIME = 3.0  # seconds before auto-destroy
const FADE_START_TIME = 2.0  # seconds before fade starts
var lifetime_timer = 0.0
var color_rect: ColorRect

func _ready():
	body_entered.connect(_on_body_entered)
	color_rect = $ColorRect

func _physics_process(delta):
	position += direction * speed * delta
	
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

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		# Calculate knockback direction (from enemy to bullet)
		var knockback_direction = (body.global_position - global_position).normalized()
		
		# Damage the enemy with knockback and check if killed
		var was_killed = body.take_damage(10, knockback_direction)
		
		# Trigger slow-time effect only if enemy was killed
		if was_killed:
			const TimeUtils = preload("res://scripts/utils/time_utils.gd")
			TimeUtils.trigger_slow_time()
			
			# Increment player combo streak
			var player = get_tree().get_first_node_in_group("player")
			if player:
				print("Bullet: Found player, incrementing combo")
				player.increment_combo_streak()
			else:
				print("Bullet: Could not find player for combo")
			
			# Notify enemy spawner to increase spawn frequency
			var spawner = get_tree().get_first_node_in_group("enemy_spawner")
			if spawner:
				print("Bullet: Found enemy spawner, incrementing kill count")
				spawner.increment_kill_count()
			else:
				print("Bullet: Enemy spawner not found")
		
		# Destroy bullet
		queue_free()
	elif body.is_in_group("player"):
		# Don't damage player with own bullets
		pass

func setup(dir):
	direction = dir.normalized()
	rotation = direction.angle()
