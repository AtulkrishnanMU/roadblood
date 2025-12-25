class_name BloodTextureManagerScript
extends Node

# Singleton for managing blood textures to avoid procedural generation
static var instance: BloodTextureManagerScript

# Pre-loaded texture arrays for different blood types
var decal_textures: Array[ImageTexture] = []
var droplet_textures: Array[ImageTexture] = []
var floating_decal_textures: Array[ImageTexture] = []

const TEXTURE_COUNT = 16  # Number of variations per type
const RandomCacheScript = preload("res://scripts/utils/random_cache.gd")

func _ready() -> void:
	if instance == null:
		instance = self
		_generate_textures()
		# Initialize random cache
		RandomCacheScript.new()

func _generate_textures() -> void:
	# Generate all textures at startup instead of runtime
	_generate_decal_textures()
	_generate_droplet_textures()
	_generate_floating_decal_textures()

func _generate_decal_textures() -> void:
	for i in range(TEXTURE_COUNT):
		var texture = _create_decal_texture(i)
		decal_textures.append(texture)

func _generate_droplet_textures() -> void:
	for i in range(TEXTURE_COUNT):
		var texture = _create_droplet_texture(i)
		droplet_textures.append(texture)

func _generate_floating_decal_textures() -> void:
	for i in range(TEXTURE_COUNT):
		var texture = _create_floating_decal_texture(i)
		floating_decal_textures.append(texture)

func _create_decal_texture(index: int) -> ImageTexture:
	var texture = ImageTexture.new()
	var image = Image.create(48, 48, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Use index as seed for consistent random generation
	var seed_value = index * 1000
	seed(seed_value)
	
	# Generate random red shade
	var redness = randf_range(0.4, 0.7)
	
	# Create unique random watery splatter shape
	var center = Vector2(24, 24)
	
	# Random parameters for unique shape
	var base_radius = randf_range(12.0, 18.0)
	var splatter_arms = randi_range(4, 8)
	var wave_frequency = randf_range(0.2, 0.4)
	var wave_amplitude = randf_range(2.0, 4.0)
	var rotation_offset = randf() * PI * 2.0
	var elongation = randf_range(0.7, 1.5)
	
	for x in range(48):
		for y in range(48):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			
			# Create unique irregular splatter shape
			var max_radius = base_radius
			
			# Add organic deformation based on position with random parameters
			var angle = atan2(y - 24, x - 24) + rotation_offset
			var deformation = 0.0
			
			# Create multiple random splatter arms
			for i in range(splatter_arms):
				var arm_angle = (float(i) / splatter_arms) * PI * 2.0 + rotation_offset
				var arm_strength = randf_range(2.0, 5.0)
				var arm_width = randf_range(0.5, 1.2)
				var arm_length = randf_range(0.8, 1.5)
				
				var angle_diff = abs(angle - arm_angle)
				if angle_diff > PI:
					angle_diff = PI * 2.0 - angle_diff
				
				if angle_diff < arm_width:
					var distance_factor = 1.0 - angle_diff / arm_width
					deformation += arm_strength * distance_factor * arm_length
			
			max_radius += deformation
			
			# Add elongation for unique shape
			max_radius *= (1.0 + (cos(angle * 2.0) * 0.2 * elongation))
			
			# Add unique waviness for watery effect
			var wave = sin(x * wave_frequency + randf() * PI) * cos(y * wave_frequency + randf() * PI) * wave_amplitude
			max_radius += wave
			
			if dist < max_radius:
				# Create gradient effect for more watery appearance
				var alpha = 0.7 - (dist / max_radius) * 0.3
				image.set_pixel(x, y, Color(redness, 0.05, 0.05, alpha))
	
	texture.set_image(image)
	return texture

func _create_droplet_texture(index: int) -> ImageTexture:
	var texture = ImageTexture.new()
	var image = Image.create(40, 40, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Use index as seed for consistent random generation
	var seed_value = index * 2000
	seed(seed_value)
	
	# Generate darker red shade
	var red_value = randf_range(0.4, 0.7)
	var green_value = randf_range(0.0, 0.1)
	var blue_value = randf_range(0.0, 0.05)
	
	# Create unique random watery teardrop shape
	var center = Vector2(20, 20)
	
	# Random parameters for unique shape
	var base_radius = randf_range(6.0, 10.0)
	var top_narrowness = randf_range(0.3, 0.7)
	var bottom_width = randf_range(1.2, 1.8)
	var wave_frequency = randf_range(0.2, 0.5)
	var wave_amplitude = randf_range(0.8, 2.0)
	var asymmetry = randf_range(-0.3, 0.3)
	
	for x in range(40):
		for y in range(40):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			
			# Create unique teardrop shape with random parameters
			var normalized_y = (y - 20) / 20.0
			var max_radius = base_radius
			
			# Make it wider at bottom, narrower at top (teardrop shape)
			if normalized_y > 0:  # Bottom half - wider
				max_radius = base_radius * bottom_width - normalized_y * base_radius * 0.3
			else:  # Top half - narrower (pointed)
				max_radius = base_radius * top_narrowness + normalized_y * base_radius * 0.5
			
			# Add asymmetry for unique shape
			max_radius += asymmetry * (x - 20) * 0.1
			
			# Add unique waviness
			var wave = sin(x * wave_frequency + randf() * PI) * cos(y * wave_frequency + randf() * PI) * wave_amplitude
			max_radius += wave
			
			if dist < max_radius:
				# Create gradient effect for more watery appearance
				var alpha = 1.0 - (dist / max_radius) * 0.3
				image.set_pixel(x, y, Color(red_value, green_value, blue_value, alpha))
	
	texture.set_image(image)
	return texture

func _create_floating_decal_texture(index: int) -> ImageTexture:
	var texture = ImageTexture.new()
	var image = Image.create(40, 40, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Use index as seed for consistent random generation
	var seed_value = index * 3000
	seed(seed_value)
	
	# Generate lighter red shade for floating decals
	var red_value = randf_range(0.5, 0.7)
	var green_value = randf_range(0.0, 0.1)
	var blue_value = randf_range(0.0, 0.05)
	
	# Create unique random watery splatter shape
	var center = Vector2(20, 20)
	
	# Random parameters for unique shape
	var base_radius = randf_range(8.0, 12.0)
	var splatter_points = randi_range(3, 6)
	var wave_frequency = randf_range(0.3, 0.6)
	var wave_amplitude = randf_range(1.5, 3.0)
	var rotation_offset = randf() * PI * 2.0
	
	for x in range(40):
		for y in range(40):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			
			# Create unique irregular splatter shape
			var max_radius = base_radius
			
			# Add organic deformation based on position with random parameters
			var angle = atan2(y - 20, x - 20) + rotation_offset
			var deformation = 0.0
			
			# Create multiple random splatter points
			for i in range(splatter_points):
				var point_angle = (float(i) / splatter_points) * PI * 2.0 + rotation_offset
				var point_strength = randf_range(1.5, 3.5)
				var point_width = randf_range(0.8, 1.5)
				
				var angle_diff = abs(angle - point_angle)
				if angle_diff > PI:
					angle_diff = PI * 2.0 - angle_diff
				
				if angle_diff < point_width:
					deformation += point_strength * (1.0 - angle_diff / point_width)
			
			max_radius += deformation
			
			# Add unique waviness for watery effect
			var wave = sin(x * wave_frequency + randf() * PI) * cos(y * wave_frequency + randf() * PI) * wave_amplitude
			max_radius += wave
			
			if dist < max_radius:
				# Create gradient effect for more watery appearance
				var alpha = 0.6 - (dist / max_radius) * 0.4
				image.set_pixel(x, y, Color(red_value, green_value, blue_value, alpha))
	
	texture.set_image(image)
	return texture

# Public API methods
static func get_random_decal_texture() -> ImageTexture:
	if instance and instance.decal_textures.size() > 0:
		return instance.decal_textures[randi() % instance.decal_textures.size()]
	return null

static func get_random_droplet_texture() -> ImageTexture:
	if instance and instance.droplet_textures.size() > 0:
		return instance.droplet_textures[randi() % instance.droplet_textures.size()]
	return null

static func get_random_floating_decal_texture() -> ImageTexture:
	if instance and instance.floating_decal_textures.size() > 0:
		return instance.floating_decal_textures[randi() % instance.floating_decal_textures.size()]
	return null
