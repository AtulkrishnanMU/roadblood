extends RefCounted
class_name BloodEffectsManager

# Centralized blood effects management
const BLOOD_SPLASH_SCENE = preload("res://scenes/blood/blood_splash.tscn")

# Spawn blood splash effect at specified position
# @param position: Global position where blood should spawn
# @param hit_direction: Direction of the hit (for splash direction)
# @param is_dead_enemy: Whether this is for a dead enemy (reduces blood amount)
# @param source_node: Node calling this function (for scene tree access)
static func spawn_blood_splash(position: Vector2, hit_direction: Vector2 = Vector2.ZERO, is_dead_enemy: bool = false, source_node: Node = null) -> void:
	# Create blood splash effect
	var blood_splash = BLOOD_SPLASH_SCENE.instantiate()
	if blood_splash and source_node:
		# Get the current scene
		var scene = source_node.get_tree().current_scene
		if scene:
			scene.add_child(blood_splash)
			# Add to bottom layer (first to be drawn)
			scene.move_child(blood_splash, 0)
			
			# Position at specified location
			blood_splash.global_position = position
			
			# Set direction based on hit direction or random if none
			if hit_direction != Vector2.ZERO:
				blood_splash.set_direction(hit_direction)  # Blood splashes in same direction as hit
			else:
				blood_splash.set_direction(Vector2.from_angle(randf() * TAU))
			
			# Mark as dead enemy for reduced blood if specified
			blood_splash.set_dead_enemy(is_dead_enemy)

# Convenience method for player damage (no dead enemy flag)
static func spawn_player_blood_splash(position: Vector2, hit_direction: Vector2 = Vector2.ZERO, source_node: Node = null) -> void:
	spawn_blood_splash(position, hit_direction, false, source_node)

# Convenience method for enemy damage/death
static func spawn_enemy_blood_splash(position: Vector2, hit_direction: Vector2 = Vector2.ZERO, is_dying: bool = false, source_node: Node = null) -> void:
	spawn_blood_splash(position, hit_direction, is_dying, source_node)
