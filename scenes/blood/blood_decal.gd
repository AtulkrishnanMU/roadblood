extends Node2D

@onready var sprite: Sprite2D = $Sprite

var fade_start_time: float = 0.0  # Randomized - when fading begins
var fade_duration: float = 0.0  # Randomized - how long fading takes
var age: float = 0.0  # Track age for fading

const BloodTextureManager = preload("res://scenes/utility-scripts/utils/blood_texture_manager.gd")
const RandomCacheScript = preload("res://scenes/utility-scripts/utils/random_cache.gd")

func _ready() -> void:
	# Set a unique watery blood texture appearance using pre-generated textures and cached random values
	if sprite:
		# Use cached random values instead of generating new ones
		var cache_index = RandomCacheScript.get_random_index()
		var random_scale = RandomCacheScript.get_scale(cache_index) * 1.7 + 1.3  # Adjust to 1.3-3.0 range (bigger)
		scale = Vector2(random_scale, random_scale)
		
		# Use cached fade times
		var fade_times = RandomCacheScript.get_fade_times(cache_index)
		fade_start_time = fade_times.x * 0.75 + 4.25  # Adjust to 5.0-8.0 range
		fade_duration = fade_times.y * 0.83 + 0.17  # Adjust to 0.37-1.42 range (much shorter)
		
		# Use pre-generated texture instead of procedural generation
		var texture = BloodTextureManager.get_random_decal_texture()
		if texture:
			sprite.texture = texture
			sprite.centered = true
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _physics_process(delta: float) -> void:
	age += delta
	
	# Handle stepped fading after random time
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
		
		sprite.modulate.a = alpha
	
	# Remove if fully faded
	if age >= fade_start_time + fade_duration:
		queue_free()
