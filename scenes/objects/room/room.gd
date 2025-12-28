extends Node2D

# Reference to the playable area for enemy spawning
@onready var playable_area: Area2D = $PlayableArea

func _ready():
	# Add to room group for easy finding
	add_to_group("room")
	print("Room added to 'room' group: ", name, " at position: ", global_position)

# Get the bounds of the playable area
func get_playable_area_bounds() -> Rect2:
	if playable_area and playable_area.get_child_count() > 0:
		var collision_shape = playable_area.get_child(0) as CollisionShape2D
		if collision_shape and collision_shape.shape is RectangleShape2D:
			var shape = collision_shape.shape as RectangleShape2D
			# Get the global position of the playable area
			var global_pos = playable_area.global_position
			# Get the half size of the rectangle and apply room scale
			var half_size = (shape.size * global_scale) / 2
			# Return the rect centered at the playable area global position
			var bounds = Rect2(global_pos - half_size, shape.size * global_scale)
			print("Room bounds - Position: ", bounds.position, " Size: ", bounds.size, " Global scale: ", global_scale)
			return bounds
	
	# Fallback to default bounds if playable area is not found
	print("WARNING: Using fallback bounds")
	return Rect2(Vector2(-580, -380), Vector2(1160, 760))

# Get random position on the edge of the playable area
func get_random_edge_position() -> Vector2:
	var bounds = get_playable_area_bounds()
	var edge = randi() % 4
	
	match edge:
		0:  # Top edge - spawn just outside the top
			return Vector2(
				bounds.position.x + randf() * bounds.size.x,
				bounds.position.y - 20  # 20 pixels outside the top edge
			)
		1:  # Right edge - spawn just outside the right
			return Vector2(
				bounds.position.x + bounds.size.x + 20,  # 20 pixels outside the right edge
				bounds.position.y + randf() * bounds.size.y
			)
		2:  # Bottom edge - spawn just outside the bottom
			return Vector2(
				bounds.position.x + randf() * bounds.size.x,
				bounds.position.y + bounds.size.y + 20  # 20 pixels outside the bottom edge
			)
		3:  # Left edge - spawn just outside the left
			return Vector2(
				bounds.position.x - 20,  # 20 pixels outside the left edge
				bounds.position.y + randf() * bounds.size.y
			)
		_:
			return bounds.position
