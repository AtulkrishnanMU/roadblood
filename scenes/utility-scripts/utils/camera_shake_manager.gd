extends Node
class_name CameraShakeController

# Camera shake management for global access
static var instance: CameraShakeController = null
var player_node: Node2D = null

func _ready():
	# Set up singleton instance
	if instance == null:
		instance = self
		add_to_group("camera_shake_manager")
	
	# Find the player node
	player_node = get_tree().get_first_node_in_group("player")
	print("CameraShakeManager: Player found: ", player_node != null)

# Trigger camera shake for enemy damage
# @param intensity: Shake intensity (default: 0.3 for subtle effect)
# @param duration: Shake duration in seconds (default: 0.08 for quick shake)
static func shake_enemy_damage(intensity: float = 0.3, duration: float = 0.08):
	print("CameraShakeManager: Enemy damage shake called")
	if instance and instance.player_node:
		# Use player's existing camera shake system
		instance.player_node.screen_shake_time = duration
		instance.player_node.current_shake_intensity = intensity
		print("CameraShakeManager: Shake initiated - intensity: ", intensity, " duration: ", duration)
	else:
		print("CameraShakeManager: No player available")

# Trigger camera shake for player actions (gunshot, etc.)
# @param intensity: Shake intensity (default: 0.5 for player actions)
# @param duration: Shake duration in seconds (default: 0.1 for player actions)
static func shake_player_action(intensity: float = 0.5, duration: float = 0.1):
	print("CameraShakeManager: Player action shake called")
	if instance and instance.player_node:
		# Use player's existing camera shake system
		instance.player_node.screen_shake_time = duration
		instance.player_node.current_shake_intensity = intensity
		print("CameraShakeManager: Shake initiated - intensity: ", intensity, " duration: ", duration)
	else:
		print("CameraShakeManager: No player available")
