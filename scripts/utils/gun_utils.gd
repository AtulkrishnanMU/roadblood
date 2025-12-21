class_name GunUtils
extends RefCounted

# Creates a muzzle flash effect at the specified position and direction
static func create_muzzle_flash(position: Vector2, direction: Vector2) -> void:
	var scene: Node = Engine.get_main_loop().current_scene
	if scene == null:
		return
	
	# Create muzzle flash container
	var flash_root := Node2D.new()
	flash_root.position = position
	flash_root.rotation = direction.angle()
	scene.add_child(flash_root)
	
	# Create multiple flash particles for burst effect
	var flash_count = 4
	for i in range(flash_count):
		var flash := Sprite2D.new()
		# Use procedural texture directly (no external file dependency)
		flash.texture = create_muzzle_flash_texture()
		
		# Random positioning within small radius
		var spread_angle = randf_range(-0.3, 0.3)  # Small spread in radians
		var distance = randf_range(12.0, 30.0)  # Even bigger distance for much larger flash
		flash.position = Vector2.RIGHT.rotated(spread_angle) * distance
		
		# Random size variation
		var scale = randf_range(3.0, 6.0)  # Much larger scale for bigger flash
		flash.scale = Vector2(scale, scale)
		
		# Bright yellow-orange color with reduced opacity
		flash.modulate = Color(1.0, randf_range(0.6, 0.9), 0.0, 0.8)  # Added alpha channel
		
		flash_root.add_child(flash)
		
		# Animate flash: quick fade out and scale down
		var tween := flash_root.create_tween()
		tween.set_parallel(true)
		tween.tween_property(flash, "modulate:a", 0.0, 0.1)  # Reduced duration
		tween.tween_property(flash, "scale", Vector2.ZERO, 0.1)  # Reduced duration
		tween.finished.connect(flash.queue_free)
	
	# Remove the container after all flashes are done
	var cleanup_tween := flash_root.create_tween()
	cleanup_tween.tween_callback(flash_root.queue_free).set_delay(0.15)  # Reduced cleanup delay

# Creates a simple 8x8 muzzle flash texture as fallback (increased size)
static func create_muzzle_flash_texture() -> ImageTexture:
	var image := Image.create(8, 8, false, Image.FORMAT_RGB8)
	image.fill(Color.WHITE)  # White base
	# Make center brighter with larger pattern
	for x in range(2, 6):
		for y in range(2, 6):
			image.set_pixel(x, y, Color.YELLOW)
	# Make very center brightest
	for x in range(3, 5):
		for y in range(3, 5):
			image.set_pixel(x, y, Color.WHITE)
	var texture := ImageTexture.new()
	texture.set_image(image)
	return texture
