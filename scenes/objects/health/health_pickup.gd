extends Area2D

class_name HealthPickup

# Import floating behavior
const FloatingBehavior = preload("res://scenes/utility-scripts/utils/floating_behavior.gd")

const HEAL_AMOUNT = 25
const LIFETIME = 10.0  # Health pickups disappear after 10 seconds
const HEALTH_GAIN_SOUND = preload("res://sounds/health-gain.mp3")  # Same as player

# Floating behavior
var floating_behavior: FloatingBehavior

var player: CharacterBody2D
var is_collected = false

# Visual elements
var sprite: Sprite2D
var collision_shape: CollisionShape2D

func _ready():
	# Add to health pickups group
	add_to_group("health_pickups")
	
	# Initialize floating behavior
	floating_behavior = FloatingBehavior.new(self)
	
	# Find player reference
	player = get_tree().get_first_node_in_group("player")
	
	# Create visual elements
	_create_visuals()
	
	# Set up collision detection
	body_entered.connect(_on_body_entered)

func _create_visuals():
	# Create simple colored rectangle instead of procedural texture
	sprite = Sprite2D.new()
	var texture = ImageTexture.new()
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	
	# Fill entire image with solid pink color - much simpler than circle drawing
	image.fill(Color(1.0, 0.7, 0.8, 1.0))  # Solid pink
	
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
	# Update floating animation using centralized behavior
	floating_behavior.update_floating(self, delta)
	
	# Remove after lifetime
	if floating_behavior.time >= LIFETIME:
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
	# Use PopupManager for health popup with flicker effect
	var popup_mgr = get_tree().get_first_node_in_group("popup_manager")
	if popup_mgr:
		popup_mgr.spawn_floating_popup(self, "+" + str(HEAL_AMOUNT) + " HP", Color(1.0, 0.7, 0.8), Vector2(0, -50), 64)

func _play_health_gain_sound():
	# Use AudioUtils pool for health gain sound with increased volume for better feedback
	AudioUtils.play_positioned_sound(HEALTH_GAIN_SOUND, global_position, 0.9, 1.1, 15.0)

func _fade_out_and_remove():
	# Fade out animation before removing
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
