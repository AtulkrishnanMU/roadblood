extends Node2D

const BLOOD_DROPLET_SCENE := preload("res://scenes/blood/blood_droplet.tscn")
const BLOOD_FLOATING_DECAL_SCENE := preload("res://scenes/blood/blood_floating_decal.tscn")
const RandomCacheScript = preload("res://scenes/utility-scripts/utils/random_cache.gd")

# Default particle counts (can be overridden by BloodEffectsPool)
const DROPLET_COUNT := 12
const FLOATING_DECAL_COUNT := 12
const DEAD_ENEMY_DROPLET_COUNT := 3
const DEAD_ENEMY_FLOATING_DECAL_COUNT := 6

var direction: Vector2 = Vector2.RIGHT
var is_dead_enemy: bool = false
var custom_droplet_count: int = -1  # -1 means use default
var custom_floating_decal_count: int = -1  # -1 means use default

func _ready() -> void:
	call_deferred("_spawn_blood_droplets")

func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()

func set_dead_enemy(dead: bool) -> void:
	is_dead_enemy = dead

# Allow BloodEffectsPool to override particle counts for optimization
func set_particle_counts(droplet_count: int, floating_decal_count: int) -> void:
	custom_droplet_count = droplet_count
	custom_floating_decal_count = floating_decal_count

func _spawn_blood_droplets() -> void:
	# Use custom counts if set, otherwise use defaults
	var droplet_count = custom_droplet_count if custom_droplet_count > 0 else (DEAD_ENEMY_DROPLET_COUNT if is_dead_enemy else DROPLET_COUNT)
	var floating_decal_count = custom_floating_decal_count if custom_floating_decal_count > 0 else (DEAD_ENEMY_FLOATING_DECAL_COUNT if is_dead_enemy else FLOATING_DECAL_COUNT)
	
	# Spawn regular falling droplets in directional burst
	for i in range(droplet_count):
		var droplet = BLOOD_DROPLET_SCENE.instantiate()
		if droplet:
			add_child(droplet)
			# Create directional burst effect - particles spread in attack direction
			var cache_index = RandomCacheScript.get_random_index()
			# Spread around the attack direction (±60 degrees cone)
			var base_angle = direction.angle()
			var spread_angle = randf_range(-PI/3, PI/3)  # ±60 degrees
			var angle = base_angle + spread_angle
			
			# Use cached speed values
			var speed = RandomCacheScript.get_speed_dead(cache_index) if is_dead_enemy else RandomCacheScript.get_speed_normal(cache_index)
			var velocity_dir = Vector2.RIGHT.rotated(angle)
			
			# Start from center position
			droplet.position = RandomCacheScript.get_position_8(cache_index)
			droplet.velocity = velocity_dir * speed
			droplet.lifetime = RandomCacheScript.get_scale(cache_index) * 0.67 + 1.5  # Adjust to 1.5-2.5 range
			# Add random rotation using cached values
			droplet.rotation = RandomCacheScript.get_rotation(cache_index)
	
	# Spawn floating blood decals in directional burst
	for i in range(floating_decal_count):
		var floating_decal = BLOOD_FLOATING_DECAL_SCENE.instantiate()
		if floating_decal:
			add_child(floating_decal)
			# Create directional burst effect - particles spread in attack direction
			var cache_index = RandomCacheScript.get_random_index()
			# Spread around the attack direction (±60 degrees cone)
			var base_angle = direction.angle()
			var spread_angle = randf_range(-PI/3, PI/3)  # ±60 degrees
			var angle = base_angle + spread_angle
			
			# Use cached speed values
			var speed = RandomCacheScript.get_speed_dead(cache_index) if is_dead_enemy else RandomCacheScript.get_speed_normal(cache_index)
			var velocity_dir = Vector2.RIGHT.rotated(angle)
			
			floating_decal.position = RandomCacheScript.get_position_6(cache_index)
			floating_decal.velocity = velocity_dir * speed
			# Add random rotation using cached values
			floating_decal.rotation = RandomCacheScript.get_rotation(cache_index)
