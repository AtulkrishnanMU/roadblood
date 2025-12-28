extends RefCounted
class_name BloodEffectsPool

# Object pooling system for blood effects to handle mass enemy deaths efficiently
# Reduces instantiation overhead and manages particle count

const BLOOD_SPLASH_SCENE = preload("res://scenes/blood/blood_splash.tscn")
const BLOOD_DROPLET_SCENE = preload("res://scenes/blood/blood_droplet.tscn")
const BLOOD_FLOATING_DECAL_SCENE = preload("res://scenes/blood/blood_floating_decal.tscn")

# Pool configuration
static var MAX_POOL_SIZE = 100  # Maximum number of blood effects to keep in pool
static var MASS_DEATH_THRESHOLD = 50  # Number of enemies killed in short time to trigger reduced effects

# Object pools
static var splash_pool: Array[Node2D] = []
static var droplet_pool: Array[Node2D] = []
static var floating_decal_pool: Array[Node2D] = []

# Mass death tracking
static var recent_deaths: int = 0
static var mass_death_timer: float = 0.0
static var mass_death_window: float = 2.0  # Time window to track mass deaths
static var reduced_effects_mode: bool = false

# Get blood splash from pool or create new one
static func get_blood_splash() -> Node2D:
	if splash_pool.size() > 0:
		var splash = splash_pool.pop_back()
		splash.visible = true
		splash.modulate.a = 1.0
		return splash
	
	# Create new splash if pool is empty
	return BLOOD_SPLASH_SCENE.instantiate()

# Return blood splash to pool
static func return_blood_splash(splash: Node2D):
	if splash_pool.size() < MAX_POOL_SIZE:
		# Reset splash state
		splash.visible = false
		splash.modulate.a = 1.0
		
		# Remove all children (droplets and decals)
		for child in splash.get_children():
			child.queue_free()
		
		# Remove from scene and return to pool
		if splash.get_parent():
			splash.get_parent().remove_child(splash)
		splash_pool.append(splash)
	else:
		splash.queue_free()

# Track enemy deaths for mass death detection
static func track_enemy_death():
	recent_deaths += 1
	mass_death_timer = 0.0
	
	# Check if we should enable reduced effects
	if recent_deaths >= MASS_DEATH_THRESHOLD:
		reduced_effects_mode = true

# Update mass death tracking (call this every frame from a central manager)
static func update_mass_death_tracking(delta: float):
	mass_death_timer += delta
	
	# Reset counter after window expires
	if mass_death_timer >= mass_death_window:
		recent_deaths = 0
		reduced_effects_mode = false

# Get adjusted particle counts based on mass death situation
static func get_adjusted_droplet_count(base_count: int) -> int:
	if reduced_effects_mode:
		return max(1, base_count / 4)  # Reduce to 25% during mass deaths
	return base_count

static func get_adjusted_floating_decal_count(base_count: int) -> int:
	if reduced_effects_mode:
		return max(1, base_count / 3)  # Reduce to 33% during mass deaths
	return base_count

# Optimized blood spawning with pooling
static func spawn_optimized_blood_splash(position: Vector2, hit_direction: Vector2 = Vector2.ZERO, is_dead_enemy: bool = false, source_node: Node = null) -> void:
	if not source_node:
		return
	
	# Get adjusted particle counts
	var base_droplet_count = 3 if is_dead_enemy else 12
	var base_floating_decal_count = 6 if is_dead_enemy else 12
	
	var droplet_count = get_adjusted_droplet_count(base_droplet_count)
	var floating_decal_count = get_adjusted_floating_decal_count(base_floating_decal_count)
	
	# Get blood splash from pool
	var blood_splash = get_blood_splash()
	if blood_splash:
		var scene = source_node.get_tree().current_scene
		if scene:
			scene.add_child(blood_splash)
			scene.move_child(blood_splash, 0)
			blood_splash.global_position = position
			
			# Set direction
			if hit_direction != Vector2.ZERO:
				blood_splash.set_direction(hit_direction)
			else:
				blood_splash.set_direction(Vector2.from_angle(randf() * TAU))
			
			# Set dead enemy flag
			blood_splash.set_dead_enemy(is_dead_enemy)
			
			# Override particle counts for optimization
			blood_splash.set_particle_counts(droplet_count, floating_decal_count)

# Clean up all pools (call when changing levels)
static func cleanup_pools():
	# Clear all pools
	for splash in splash_pool:
		splash.queue_free()
	splash_pool.clear()
	
	for droplet in droplet_pool:
		droplet.queue_free()
	droplet_pool.clear()
	
	for floating_decal in floating_decal_pool:
		floating_decal.queue_free()
	floating_decal_pool.clear()
	
	# Reset tracking
	recent_deaths = 0
	mass_death_timer = 0.0
	reduced_effects_mode = false

# Get pool statistics for debugging
static func get_pool_stats() -> Dictionary:
	return {
		"splash_pool_size": splash_pool.size(),
		"droplet_pool_size": droplet_pool.size(),
		"floating_decal_pool_size": floating_decal_pool.size(),
		"recent_deaths": recent_deaths,
		"reduced_effects_mode": reduced_effects_mode
	}
