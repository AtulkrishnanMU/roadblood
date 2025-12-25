extends Node2D

const BLOOD_DROPLET_SCENE := preload("res://scenes/blood/blood_droplet.tscn")
const BLOOD_FLOATING_DECAL_SCENE := preload("res://scenes/blood/blood_floating_decal.tscn")
const RandomCacheScript = preload("res://scenes/utility-scripts/utils/random_cache.gd")

const DROPLET_COUNT := 12
const FLOATING_DECAL_COUNT := 12  # Increased from 4 to 12 (3x more floating particles)
const DEAD_ENEMY_DROPLET_COUNT := 3  # Reduced blood for dead enemies
const DEAD_ENEMY_FLOATING_DECAL_COUNT := 6  # Increased from 2 to 6 (3x more for dead enemies)

var direction: Vector2 = Vector2.RIGHT  # Default direction, can be set from outside
var is_dead_enemy: bool = false  # Flag to reduce blood amount

func _ready() -> void:
	call_deferred("_spawn_blood_droplets")

func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()

func set_dead_enemy(dead: bool) -> void:
	is_dead_enemy = dead

func _spawn_blood_droplets() -> void:
	var droplet_count = DEAD_ENEMY_DROPLET_COUNT if is_dead_enemy else DROPLET_COUNT
	var floating_decal_count = DEAD_ENEMY_FLOATING_DECAL_COUNT if is_dead_enemy else FLOATING_DECAL_COUNT
	
	# Spawn regular falling droplets in circular burst
	for i in range(droplet_count):
		var droplet = BLOOD_DROPLET_SCENE.instantiate()
		if droplet:
			add_child(droplet)
			# Create circular burst effect - particles spread in all directions
			var cache_index = RandomCacheScript.get_random_index()
			# Full 360-degree spread for circular burst
			var angle = RandomCacheScript.get_rotation(cache_index)  # 0 to 2*PI
			# Use cached speed values
			var speed = RandomCacheScript.get_speed_dead(cache_index) if is_dead_enemy else RandomCacheScript.get_speed_normal(cache_index)
			var velocity_dir = Vector2.RIGHT.rotated(angle)
			
			# Start from center position
			droplet.position = RandomCacheScript.get_position_8(cache_index)
			droplet.velocity = velocity_dir * speed
			droplet.lifetime = RandomCacheScript.get_scale(cache_index) * 0.67 + 1.5  # Adjust to 1.5-2.5 range
			# Add random rotation using cached values
			droplet.rotation = RandomCacheScript.get_rotation(cache_index)
	
	# Spawn floating blood decals in circular burst
	for i in range(floating_decal_count):
		var floating_decal = BLOOD_FLOATING_DECAL_SCENE.instantiate()
		if floating_decal:
			add_child(floating_decal)
			# Create circular burst effect - particles spread in all directions
			var cache_index = RandomCacheScript.get_random_index()
			# Full 360-degree spread for circular burst
			var angle = RandomCacheScript.get_rotation(cache_index)  # 0 to 2*PI
			
			# Use cached speed values
			var speed = RandomCacheScript.get_speed_dead(cache_index) if is_dead_enemy else RandomCacheScript.get_speed_normal(cache_index)
			var velocity_dir = Vector2.RIGHT.rotated(angle)
			
			floating_decal.position = RandomCacheScript.get_position_6(cache_index)
			floating_decal.velocity = velocity_dir * speed
			# Add random rotation using cached values
			floating_decal.rotation = RandomCacheScript.get_rotation(cache_index)
