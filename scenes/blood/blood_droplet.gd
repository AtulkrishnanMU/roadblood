extends "res://scenes/particle.gd"

const BLOOD_DECAL_SCENE := preload("res://scenes/blood/blood_decal.tscn")
const BloodTextureManager = preload("res://scripts/utils/blood_texture_manager.gd")
const RandomCache = preload("res://scripts/utils/random_cache.gd")

var fade_start_time: float = 0.0  # Randomized - when fading begins
var fade_duration: float = 0.0  # Randomized - how long fading takes
var rotation_speed: float = 0.0  # Rotation speed for spinning effect

func _ready() -> void:
	# Override particle properties for blood
	particle_gravity = 500.0
	lifetime = 2.0
	fade_alpha_multiplier = 0.8
	
	# Use cached random values instead of generating new ones
	var cache_index = RandomCache.get_random_index()
	# Use cached fade times
	var fade_times = RandomCache.get_fade_times(cache_index)
	fade_start_time = fade_times.x * 0.17 + 0.42  # Adjust to 0.5-1.5 range
	fade_duration = fade_times.y * 0.17 + 0.04  # Adjust to 0.07-0.3 range (much shorter)
	
	# Add random size variation using cached values
	var random_scale = RandomCache.get_scale(cache_index) * 1.28 + 0.72  # Adjust to 0.72-2.0 range (bigger)
	scale = Vector2(random_scale, random_scale)
	
	# Set random rotation speed for spinning effect
	rotation_speed = RandomCache.get_rotation(cache_index) * 5.0  # 0 to 10*PI radians per second
	
	super._ready()

func _setup_particle_appearance() -> void:
	# Set up blood droplet appearance using pre-generated textures
	if sprite:
		var texture = BloodTextureManager.get_random_droplet_texture()
		if texture:
			sprite.texture = texture
			sprite.centered = true
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _physics_process(delta: float) -> void:
	# Handle movement only if not stuck
	if not has_stuck:
		age += delta
		
		# Apply rotation while moving
		rotation += rotation_speed * delta
		
		# Apply gravity
		velocity.y += particle_gravity * delta
		
		# Move and check collision
		global_position += velocity * delta
	else:
		age += delta  # Continue aging even when stuck
	
	# Handle custom stepped fade timing (always execute, even when stuck)
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
	# Blood collides with more surfaces including characters
	return body is TileMap or body.is_in_group("walls") or body.is_in_group("ground") or body.is_in_group("colliders") or body.is_in_group("enemies") or body.is_in_group("player")

func _on_collision(body: Node) -> void:
	# Create blood decal on collision
	_create_blood_decal()
	
	# Start disappearance timer after hitting floor
	if body is TileMap or body.is_in_group("ground") or body.is_in_group("colliders"):
		# Set a short timer to disappear after 0.5 seconds
		var timer = get_tree().create_timer(0.5)
		timer.timeout.connect(queue_free)

func _create_blood_decal() -> void:
	var decal = BLOOD_DECAL_SCENE.instantiate()
	if decal:
		# Add decal to the scene tree at bottom layer (first to be drawn)
		var scene = get_tree().current_scene
		scene.add_child(decal)
		scene.move_child(decal, 0)
		
		decal.global_position = global_position
		
		# Use cached random values for rotation and scale
		var cache_index = RandomCache.get_random_index()
		decal.rotation = RandomCache.get_rotation(cache_index) * 0.5  # Adjust to 0-PI range
		var scale_factor = RandomCache.get_scale(cache_index) * 0.5 + 0.1  # Adjust to 0.2-0.6 range
		decal.scale = Vector2(scale_factor, scale_factor)
