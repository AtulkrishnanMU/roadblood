extends Node2D

class_name FoodObject

signal health_depleted

# Import health component
const HealthComponent = preload("res://scenes/utility-scripts/utils/health_component.gd")

var health_component: HealthComponent
var health_bar: ProgressBar

func _ready():
	add_to_group("food")
	
	# Initialize health component
	health_component = HealthComponent.new(self, 200)
	
	# Connect health component signal
	health_component.health_depleted.connect(_destroy_food)
	
	# Get the health bar node from the scene instead of creating it programmatically
	health_bar = $HealthBar
	if health_bar:
		health_component.health_bar = health_bar
		health_component._update_health_bar()
		_setup_health_bar_style()

func _physics_process(delta):
	pass

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
		# Food ignores knockback - stays stationary, but use health component for damage
	health_component.take_damage(damage, Vector2.ZERO, false)  # No blood for food
	
func _destroy_food():
	# Emit signal before destroying
	emit_signal("health_depleted")
	
	# Create some visual effect or sound if needed
	queue_free()
