extends RefCounted
class_name BloodEffectsManager

# Centralized blood effects management with pooling support
const BLOOD_SPLASH_SCENE = preload("res://scenes/blood/blood_splash.tscn")
const BloodEffectsPool = preload("res://scenes/utility-scripts/utils/blood_effects_pool.gd")

# Spawn blood splash effect at specified position
# @param position: Global position where blood should spawn
# @param hit_direction: Direction of the hit (for splash direction)
# @param is_dead_enemy: Whether this is for a dead enemy (reduces blood amount)
# @param source_node: Node calling this function (for scene tree access)
static func spawn_blood_splash(position: Vector2, hit_direction: Vector2 = Vector2.ZERO, is_dead_enemy: bool = false, source_node: Node = null) -> void:
	# Track enemy death for mass death detection
	BloodEffectsPool.track_enemy_death()
	
	# Use optimized spawning with pooling
	BloodEffectsPool.spawn_optimized_blood_splash(position, hit_direction, is_dead_enemy, source_node)

# Convenience method for player damage (no dead enemy flag)
static func spawn_player_blood_splash(position: Vector2, hit_direction: Vector2 = Vector2.ZERO, source_node: Node = null) -> void:
	spawn_blood_splash(position, hit_direction, false, source_node)

# Convenience method for enemy damage/death
static func spawn_enemy_blood_splash(position: Vector2, hit_direction: Vector2 = Vector2.ZERO, is_dying: bool = false, source_node: Node = null) -> void:
	spawn_blood_splash(position, hit_direction, is_dying, source_node)
