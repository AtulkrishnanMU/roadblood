extends RefCounted
class_name FloatingBehavior

# Centralized floating animation behavior
const DEFAULT_FLOAT_SPEED = 50.0
const DEFAULT_FLOAT_HEIGHT = 20.0

# Floating animation variables
var time: float = 0.0
var base_y: float = 0.0
var float_speed: float = DEFAULT_FLOAT_SPEED
var float_height: float = DEFAULT_FLOAT_HEIGHT

# Initialize floating behavior
# @param node: The node that will use this floating behavior
# @param speed: Floating speed (uses default if not specified)
# @param height: Floating height (uses default if not specified)
func _init(node: Node2D, speed: float = DEFAULT_FLOAT_SPEED, height: float = DEFAULT_FLOAT_HEIGHT):
	base_y = node.position.y
	float_speed = speed
	float_height = height

# Update floating animation
# @param node: The node to apply floating animation to
# @param delta: Delta time from _physics_process
func update_floating(node: Node2D, delta: float) -> void:
	time += delta
	
	# Floating animation with smooth easing
	var float_phase = time * float_speed * 0.1
	var smooth_float = smoothstep(-1.0, 1.0, sin(float_phase))
	var float_offset = smooth_float * float_height
	node.position.y = base_y + float_offset

# Alternative floating animation with cosine easing (for food objects)
# @param node: The node to apply floating animation to
# @param delta: Delta time from _physics_process
func update_floating_cosine(node: Node2D, delta: float) -> void:
	time += delta
	
	# Floating animation with cosine easing for smooth acceleration/deceleration
	var float_phase = time * float_speed * 0.1
	var ease_factor = 0.5 * (1.0 + cos(float_phase * TAU))  # Cosine gives natural ease in/out
	var float_offset = ease_factor * float_height
	node.position.y = base_y - float_offset  # Negative to float up when ease_factor is high
