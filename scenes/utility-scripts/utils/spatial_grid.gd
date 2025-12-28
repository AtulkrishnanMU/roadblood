extends RefCounted
class_name SpatialGrid

# Spatial grid for efficient enemy collision detection
# Reduces O(n²) complexity to O(n) for nearby enemies

static var grid_size: float = 100.0  # Grid cell size
static var grid: Dictionary = {}
static var enemies_in_grid: Dictionary = {}

# Register enemy in spatial grid
static func register_enemy(enemy: Node):
	var pos = enemy.global_position
	var cell_key = _get_cell_key(pos)
	
	if not grid.has(cell_key):
		grid[cell_key] = []
	
	grid[cell_key].append(enemy)
	enemies_in_grid[enemy] = cell_key

# Unregister enemy from spatial grid
static func unregister_enemy(enemy: Node):
	if not enemies_in_grid.has(enemy):
		return
	
	var cell_key = enemies_in_grid[enemy]
	if grid.has(cell_key):
		grid[cell_key].erase(enemy)
		if grid[cell_key].is_empty():
			grid.erase(cell_key)
	
	enemies_in_grid.erase(enemy)

# Update enemy position in grid
static func update_enemy_position(enemy: Node):
	if not enemies_in_grid.has(enemy):
		register_enemy(enemy)
		return
	
	var old_cell_key = enemies_in_grid[enemy]
	var new_cell_key = _get_cell_key(enemy.global_position)
	
	if old_cell_key != new_cell_key:
		# Remove from old cell
		if grid.has(old_cell_key):
			grid[old_cell_key].erase(enemy)
			if grid[old_cell_key].is_empty():
				grid.erase(old_cell_key)
		
		# Add to new cell
		if not grid.has(new_cell_key):
			grid[new_cell_key] = []
		grid[new_cell_key].append(enemy)
		enemies_in_grid[enemy] = new_cell_key

# Get nearby enemies within radius (O(1) for small radius)
static func get_nearby_enemies(position: Vector2, radius: float) -> Array:
	var nearby_enemies = []
	var cell_radius = ceil(radius / grid_size)
	var center_cell = _get_cell_key(position)
	
	# Check surrounding cells
	for dx in range(-cell_radius, cell_radius + 1):
		for dy in range(-cell_radius, cell_radius + 1):
			var cell_key = Vector2(
				center_cell.x + dx,
				center_cell.y + dy
			)
			
			if grid.has(cell_key):
				for enemy in grid[cell_key]:
					if is_instance_valid(enemy) and enemy.global_position.distance_to(position) <= radius:
						nearby_enemies.append(enemy)
	
	return nearby_enemies

# Get cell key for position
static func _get_cell_key(position: Vector2) -> Vector2:
	return Vector2(
		floor(position.x / grid_size),
		floor(position.y / grid_size)
	)

# Clear grid (call when changing levels)
static func clear():
	grid.clear()
	enemies_in_grid.clear()

# Get grid statistics for debugging
static func get_stats() -> Dictionary:
	return {
		"grid_cells": grid.size(),
		"total_enemies": enemies_in_grid.size(),
		"grid_size": grid_size
	}
