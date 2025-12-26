extends Area2D

class_name HealthPickup

const HEAL_AMOUNT = 25
const FLOAT_SPEED = 50.0
const FLOAT_HEIGHT = 20.0
const LIFETIME = 10.0  # Health pickups disappear after 10 seconds
const HEALTH_GAIN_SOUND = preload("res://sounds/health-gain.mp3")  # Same as player

var time = 0.0
var base_y = 0.0
var player: CharacterBody2D
var is_collected = false

# Visual elements
var sprite: Sprite2D
var collision_shape: CollisionShape2D

func _ready():
	# Add to health pickups group
	add_to_group("health_pickups")
	
	# Find player reference
	player = get_tree().get_first_node_in_group("player")
	
	# Create visual elements
	_create_visuals()
	
	# Set up collision detection
	body_entered.connect(_on_body_entered)
	
	# Store initial Y position for floating animation
	base_y = position.y

func _create_visuals():
	# Create sprite (pink circle)
	sprite = Sprite2D.new()
	var texture = ImageTexture.new()
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Draw pink circle
	var center = Vector2(16, 16)
	var radius = 14
	for x in range(32):
		for y in range(32):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			if dist <= radius:
				# Create gradient effect
				var brightness = 1.0 - (dist / radius) * 0.3
				image.set_pixel(x, y, Color(1.0, 0.7, 0.8, brightness))  # Pink with gradient
	
	texture.set_image(image)
	sprite.texture = texture
	add_child(sprite)
	
	# Create collision shape
	collision_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 14
	collision_shape.shape = circle_shape
	add_child(collision_shape)

func _physics_process(delta):
	time += delta
	
	# Floating animation
	var float_phase = time * FLOAT_SPEED * 0.1
	var smooth_float = smoothstep(-1.0, 1.0, sin(float_phase))
	var float_offset = smooth_float * FLOAT_HEIGHT
	position.y = base_y + float_offset
	
	# Remove after lifetime
	if time >= LIFETIME:
		_fade_out_and_remove()

func _on_body_entered(body):
	if body == player and not is_collected:
		is_collected = true
		
		# Heal the player
		if player.has_method("heal"):
			player.heal(HEAL_AMOUNT)
			
			# Play health gain sound
			_play_health_gain_sound()
			
			# Show custom health popup (pink with flicker)
			_spawn_health_popup()
			
			# Hide sprite and disable collision safely using call_deferred
			if sprite:
				sprite.visible = false
			if collision_shape:
				collision_shape.set_deferred("disabled", true)
			
			# Delay destruction to allow sound to play
			var tween = create_tween()
			tween.tween_callback(queue_free).set_delay(1.0)

func _spawn_health_popup():
	const PopupUtils = preload("res://scenes/utility-scripts/utils/popup_utils.gd")
	# Create a custom pink health popup with flicker effect
	PopupUtils.spawn_floating_popup(self, "+" + str(HEAL_AMOUNT) + " HP", Color(1.0, 0.7, 0.8), Vector2(0, -50), 64)

func _play_health_gain_sound():
	# Create non-positional audio player for health gain sound
	var audio_player = AudioStreamPlayer.new()
	audio_player.stream = HEALTH_GAIN_SOUND
	audio_player.volume_db = 3.0  # Louder than full volume for health gain sound
	
	# Add to scene and play
	add_child(audio_player)
	audio_player.play()
	
	# Remove after sound finishes
	audio_player.finished.connect(audio_player.queue_free)

func _fade_out_and_remove():
	# Fade out animation before removing
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
