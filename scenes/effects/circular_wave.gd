extends Area2D

const WAVE_SPEED = 300.0  # Speed of wave expansion
const MAX_RADIUS = 800.0  # Maximum radius of the wave
const LIFETIME = 3.0  # How long the wave exists
const DAMAGE = 999  # Instant kill damage

var current_radius = 0.0
var lifetime_timer = 0.0
var player: CharacterBody2D
var wave_sprite: Sprite2D

func _ready():
	# Find the player
	player = get_tree().get_first_node_in_group("player")
	
	# Create visual wave effect
	_create_wave_visual()
	
	# Set up collision detection
	area_entered.connect(_on_area_entered)
	
	# Position at player
	if player:
		global_position = player.global_position

func _create_wave_visual():
	# Create a simple expanding circle sprite
	wave_sprite = Sprite2D.new()
	add_child(wave_sprite)
	
	# Create a texture for the wave
	var texture = ImageTexture.new()
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Draw a circle
	var center = Vector2(32, 32)
	for x in range(64):
		for y in range(64):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			if dist < 30 and dist > 28:  # Ring shape
				image.set_pixel(x, y, Color(1.0, 0.2, 0.2, 0.8))  # Red wave
	
	texture.set_image(image)
	wave_sprite.texture = texture
	wave_sprite.centered = true
	
	# Start small and scale up
	wave_sprite.scale = Vector2(0.1, 0.1)

func _physics_process(delta):
	lifetime_timer += delta
	
	# Expand the wave
	current_radius += WAVE_SPEED * delta
	
	# Update visual scale
	if wave_sprite:
		var scale_factor = current_radius / 50.0  # Base size
		wave_sprite.scale = Vector2(scale_factor, scale_factor)
		# Fade out as it expands
		var alpha = max(0.0, 1.0 - (current_radius / MAX_RADIUS))
		wave_sprite.modulate.a = alpha
	
	# Update collision shape
	_update_collision_shape()
	
	# Remove when max radius reached or lifetime exceeded
	if current_radius >= MAX_RADIUS or lifetime_timer >= LIFETIME:
		queue_free()

func _update_collision_shape():
	# Create or update collision circle
	var collision_shape = get_node_or_null("CollisionShape2D")
	if not collision_shape:
		collision_shape = CollisionShape2D.new()
		add_child(collision_shape)
	
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = current_radius
	collision_shape.shape = circle_shape

func _on_area_entered(area):
	if area.is_in_group("enemies"):
		# Get the parent enemy 
		var enemy = area.get_parent()
		
		# Kill the enemy instantly
		print("CircularWave: Killing enemy: ", enemy)
		var was_killed = enemy.take_damage(DAMAGE, (enemy.global_position - global_position).normalized())
		
		# Increment kill counter and combo only if enemy was killed
		if was_killed:
			# Increment player combo streak
			var player_ref = get_tree().get_first_node_in_group("player")
			if player_ref:
				print("CircularWave: Found player, incrementing combo")
				player_ref.increment_combo_streak()
			else:
				print("CircularWave: Could not find player for combo")
			
			# Notify enemy spawner to increase spawn count
			var spawner = get_tree().get_first_node_in_group("enemy_spawner")
			if spawner:
				print("CircularWave: Found enemy spawner, incrementing kill count")
				spawner.increment_kill_count()
			else:
				print("CircularWave: Enemy spawner not found")
