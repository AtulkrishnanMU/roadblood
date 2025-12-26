extends Node2D

class_name FoodObject

var health: int
var max_health: int
var health_bar: ProgressBar

# Floating animation variables
var time = 0.0
var base_y = 0.0
const FLOAT_SPEED = 80.0  # Much faster float speed
const FLOAT_HEIGHT = 20.0  # Slightly larger float height

func _ready():
	add_to_group("food")
	max_health = 200
	health = max_health
	# Get the health bar node from the scene instead of creating it programmatically
	health_bar = $HealthBar
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health
		_setup_health_bar_style()
	
	# Store initial Y position for floating animation
	base_y = position.y

func _physics_process(delta):
	time += delta
	
	# Floating animation with ease in/out using cubic interpolation
	var float_phase = time * FLOAT_SPEED * 0.1
	# Use ease in/out with cubic interpolation for smooth acceleration/deceleration
	var ease_factor = 0.5 * (1.0 + cos(float_phase * TAU))  # Cosine gives natural ease in/out
	var float_offset = ease_factor * FLOAT_HEIGHT
	position.y = base_y - float_offset  # Negative to float up when ease_factor is high

func _setup_health_bar_style():
	# Style the health bar
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color.RED
	style_box.border_width_left = 1
	style_box.border_width_right = 1
	style_box.border_width_top = 1
	style_box.border_width_bottom = 1
	style_box.border_color = Color.BLACK
	style_box.corner_radius_top_left = 2
	style_box.corner_radius_top_right = 2
	style_box.corner_radius_bottom_left = 2
	style_box.corner_radius_bottom_right = 2
	
	health_bar.add_theme_stylebox_override("fill", style_box)
	
	# Create background style
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color.DARK_GRAY
	bg_style.corner_radius_top_left = 2
	bg_style.corner_radius_top_right = 2
	bg_style.corner_radius_bottom_left = 2
	bg_style.corner_radius_bottom_right = 2
	
	health_bar.add_theme_stylebox_override("background", bg_style)

func take_damage(damage: int, knockback_direction: Vector2):
	print("Food taking damage: ", damage, " current health: ", health)
	# Food ignores knockback - stays stationary
	health = max(health - damage, 0)
	print("Food health after damage: ", health)
	_update_health_bar()
	
	if health <= 0:
		_destroy_food()

func _update_health_bar():
	if health_bar:
		health_bar.value = health

func _destroy_food():
	# Create some visual effect or sound if needed
	queue_free()
