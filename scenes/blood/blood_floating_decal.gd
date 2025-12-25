extends "res://scenes/particle.gd"

const BloodTextureManager = preload("res://scripts/utils/blood_texture_manager.gd")
const RandomCacheScript = preload("res://scripts/utils/random_cache.gd")

var float_duration: float = 0.0  # How long to move before sticking
var float_age: float = 0.0
var is_floating: bool = true
var float_drift: Vector2 = Vector2.ZERO
var has_stuck_in_air: bool = false
var fade_start_time: float = 0.0  # Randomized - when fading begins
var fade_duration: float = 0.0  # Randomized - how long fading takes
var rotation_speed: float = 0.0  # Rotation speed for spinning effect

func _ready() -> void:
	# Override particle properties for floating blood decal
	particle_gravity = 0.0  # No gravity - stays in air
	lifetime = 8.0  # Longer lifetime for decals
	fade_alpha_multiplier = 0.6  # Slower fade for decals
	
	# Use cached random values instead of generating new ones
	var cache_index = RandomCacheScript.get_random_index()
	float_duration = RandomCacheScript.get_scale(cache_index) * 0.02  # Adjust to 0.03-0.05 range (extremely short)
	
	# Use cached fade times
	var fade_times = RandomCacheScript.get_fade_times(cache_index)
	fade_start_time = fade_times.x * 0.56 + 1.56  # Adjust to 3.0-5.0 range
	fade_duration = fade_times.y * 0.75 + 0.25  # Adjust to 0.4-1.38 range (much shorter)
	
	# Set random drift for floating effect using cached values
	float_drift = RandomCacheScript.get_drift(cache_index)
	
	# Add random size variation using cached values
	var random_scale = RandomCacheScript.get_scale(cache_index) * 0.96 + 0.84  # Adjust to 0.84-1.8 range (bigger)
	scale = Vector2(random_scale, random_scale)
	
	# Set random rotation speed for spinning effect
	rotation_speed = RandomCacheScript.get_rotation(cache_index) * 5.0  # 0 to 10*PI radians per second
	
	super._ready()

func _setup_particle_appearance() -> void:
	# Set up floating blood decal appearance using pre-generated textures
	if sprite:
		var texture = BloodTextureManager.get_random_floating_decal_texture()
		if texture:
			sprite.texture = texture
			sprite.centered = true
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _physics_process(delta: float) -> void:
	age += delta
	
	# Handle movement only if not stuck
	if not has_stuck and not has_stuck_in_air:
		if is_floating:
			float_age += delta
			
			# Apply rotation while floating (before sticking)
			rotation += rotation_speed * delta
			
			# Apply drift while floating
			global_position += float_drift * delta
			
			# Apply slight upward bias while floating
			velocity.y += -20.0 * delta
			global_position += velocity * delta
			
			# Check if floating duration is over - then stick in air
			if float_age >= float_duration:
				is_floating = false
				has_stuck_in_air = true
				velocity = Vector2.ZERO  # Stop all movement
				float_drift = Vector2.ZERO
				rotation_speed = 0.0  # Stop rotation when stuck
		# Should not reach here anymore since decals stick in air
	
	# Handle stepped fading (always execute, even when stuck)
	if sprite:
		var alpha = 1.0
		
		if age >= fade_start_time:
			# Start stepped fading out
			var fade_progress = (age - fade_start_time) / fade_duration
			
			# Create stepped opacity levels (5 distinct levels)
			if fade_progress < 0.2:
				alpha = 1.0
			elif fade_progress < 0.4:
				alpha = 0.75
			elif fade_progress < 0.6:
				alpha = 0.5
			elif fade_progress < 0.8:
				alpha = 0.25
			else:
				alpha = 0.0
		
		sprite.modulate.a = alpha * fade_alpha_multiplier
	
	# Remove if lifetime exceeded or fully faded
	if age >= lifetime or (age >= fade_start_time + fade_duration):
		queue_free()

func _should_collide_with(body: Node) -> bool:
	# Floating blood decals only collide if they haven't stuck in air yet
	if has_stuck_in_air:
		return false
	return body is TileMap or body.is_in_group("walls") or body.is_in_group("ground") or body.is_in_group("colliders") or body.is_in_group("enemies") or body.is_in_group("player")

func _on_collision(_body: Node) -> void:
	# Floating decals don't create additional decals on collision
	# They just stick to whatever they hit
	if not has_stuck_in_air:
		is_floating = false
		has_stuck_in_air = true
		velocity = Vector2.ZERO
		float_drift = Vector2.ZERO
