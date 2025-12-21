extends RigidBody2D

const LIFETIME = 0.5  # seconds before auto-destroy
const FADE_START_TIME = 0.25  # seconds before fade starts

var lifetime_timer = 0.0
var color_rect: ColorRect

func _ready():
	# Get reference to ColorRect
	color_rect = $ColorRect
	
	# Add some random spin for realistic effect
	angular_velocity = randf_range(-10.0, 10.0)
	
	# Set gravity scale for realistic falling
	gravity_scale = 1.0
	# Prevent sleeping to ensure physics continues
	sleeping = false

func _process(delta):
	lifetime_timer += delta
	
	# Start fading after 1 second
	if lifetime_timer >= FADE_START_TIME:
		var fade_progress = (lifetime_timer - FADE_START_TIME) / (LIFETIME - FADE_START_TIME)
		var alpha = 1.0 - fade_progress
		color_rect.modulate.a = clamp(alpha, 0.0, 1.0)
	
	# Auto-destroy after lifetime
	if lifetime_timer >= LIFETIME:
		queue_free()

# Setup initial velocity and position
func setup(eject_position: Vector2, eject_direction: Vector2):
	global_position = eject_position
	
	# Eject with some randomness - much more force for extremely powerful movement
	var eject_force = 800.0  # Increased from 500.0 for MUCH more force
	var random_angle = randf_range(-0.5, 0.5)  # Random spread
	var final_direction = eject_direction.rotated(random_angle)
	
	linear_velocity = final_direction * eject_force + Vector2(0, -150)  # Much higher upward arc
