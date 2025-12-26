extends RefCounted
class_name CacheManager

# Centralized caching system for expensive operations
# Reduces get_nodes_in_group() calls and provides cached references

# Cache storage
static var _group_cache: Dictionary = {}
static var _node_cache: Dictionary = {}
static var _nearest_enemy_cache: Dictionary = {}
static var _cache_frame_counter: int = 0
static var _cache_invalidation_frames: int = 90  # Invalidate cache every 90 frames (~1.5 seconds at 60 FPS)

# Cache invalidation tracking
static var _last_enemy_count: int = 0
static var _last_player_position: Vector2 = Vector2.INF

# Get cached nodes from group with automatic invalidation
# @param group_name: Name of the group to cache
# @param tree: Scene tree reference
# @return: Array of nodes in the group
static func get_nodes_in_group_cached(group_name: String, tree: SceneTree) -> Array:
	var cache_key = group_name
	var current_frame = Engine.get_process_frames()
	
	# Check if cache exists and is valid
	if _group_cache.has(cache_key):
		var cache_data = _group_cache[cache_key]
		var frame_diff = current_frame - cache_data.frame
		
		# Invalidate cache based on different conditions per group
		var should_invalidate = false
		
		match group_name:
			"enemies":
				# Invalidate if enemy count changed or too many frames passed
				var current_count = cache_data.nodes.size()
				if current_count != _last_enemy_count or frame_diff > _cache_invalidation_frames:
					should_invalidate = true
					_last_enemy_count = current_count
			"player", "enemy_spawner", "ui", "popup_manager":
				# Invalidate much less frequently for static groups (4x base threshold)
				should_invalidate = frame_diff > _cache_invalidation_frames * 4
			_:
				# Default invalidation
				should_invalidate = frame_diff > _cache_invalidation_frames
		
		if not should_invalidate:
			return cache_data.nodes
	
	# Cache miss or invalid - fetch fresh data
	var nodes = tree.get_nodes_in_group(group_name)
	_group_cache[cache_key] = {
		"nodes": nodes,
		"frame": current_frame
	}
	
	return nodes

# Get single cached node from group (first node)
# @param group_name: Name of the group
# @param tree: Scene tree reference
# @return: First node in group or null
static func get_first_node_in_group_cached(group_name: String, tree: SceneTree) -> Node:
	var cache_key = "first_" + group_name
	var current_frame = Engine.get_process_frames()
	
	# Check cache validity
	if _node_cache.has(cache_key):
		var cache_data = _node_cache[cache_key]
		var frame_diff = current_frame - cache_data.frame
		
		# For single nodes, invalidate much less frequently
		if frame_diff <= _cache_invalidation_frames * 6 and is_instance_valid(cache_data.node):
			return cache_data.node
	
	# Cache miss or invalid - fetch fresh data
	var node = tree.get_first_node_in_group(group_name)
	_node_cache[cache_key] = {
		"node": node,
		"frame": current_frame
	}
	
	return node

# Get nearest cached enemy with distance-based invalidation
# @param position: Position to search from
# @param tree: Scene tree reference
# @param max_distance: Maximum distance to consider
# @return: Nearest enemy or null
static func get_nearest_enemy_cached(position: Vector2, tree: SceneTree, max_distance: float = INF) -> Node:
	var cache_key = "nearest_enemy"
	var current_frame = Engine.get_process_frames()
	
	# Check if we have a valid cached result
	if _nearest_enemy_cache.has(cache_key):
		var cache_data = _nearest_enemy_cache[cache_key]
		var frame_diff = current_frame - cache_data.frame
		
		# Invalidate if position changed significantly or cache is old
		var position_changed = _last_player_position.distance_to(position) > 100.0
		var cache_invalid = frame_diff > 10 or position_changed
		
		if not cache_invalid and is_instance_valid(cache_data.enemy):
			# Verify enemy is still within reasonable distance
			var distance = position.distance_to(cache_data.enemy.global_position)
			if distance <= max_distance * 1.5:  # Some tolerance
				return cache_data.enemy
	
	# Cache miss or invalid - find nearest enemy
	var enemies = get_nodes_in_group_cached("enemies", tree)
	var nearest_enemy = null
	var nearest_distance = INF
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
			
		var distance = position.distance_to(enemy.global_position)
		if distance < nearest_distance and distance <= max_distance:
			nearest_distance = distance
			nearest_enemy = enemy
	
	# Update cache
	_nearest_enemy_cache[cache_key] = {
		"enemy": nearest_enemy,
		"frame": current_frame
	}
	_last_player_position = position
	
	return nearest_enemy

# Force cache invalidation (call when significant scene changes occur)
static func invalidate_cache():
	_group_cache.clear()
	_node_cache.clear()
	_nearest_enemy_cache.clear()
	_last_enemy_count = 0
	_last_player_position = Vector2.INF

# Invalidate specific group cache
# @param group_name: Name of group to invalidate
static func invalidate_group_cache(group_name: String):
	_group_cache.erase(group_name)
	_node_cache.erase("first_" + group_name)
	
	# Also invalidate nearest enemy if enemies group changed
	if group_name == "enemies":
		_nearest_enemy_cache.clear()

# Performance monitoring
static func get_cache_stats() -> Dictionary:
	return {
		"group_cache_size": _group_cache.size(),
		"node_cache_size": _node_cache.size(),
		"nearest_enemy_cached": _nearest_enemy_cache.has("nearest_enemy"),
		"current_frame": Engine.get_process_frames()
	}

# Clean up invalid references (call periodically)
static func cleanup_invalid_references():
	# Clean up group cache
	for key in _group_cache.keys():
		var cache_data = _group_cache[key]
		var valid_nodes = []
		for node in cache_data.nodes:
			if is_instance_valid(node):
				valid_nodes.append(node)
		cache_data.nodes = valid_nodes
	
	# Clean up node cache
	for key in _node_cache.keys():
		var cache_data = _node_cache[key]
		if not is_instance_valid(cache_data.node):
			_node_cache.erase(key)
	
	# Clean up nearest enemy cache
	if _nearest_enemy_cache.has("nearest_enemy"):
		var cache_data = _nearest_enemy_cache["nearest_enemy"]
		if not is_instance_valid(cache_data.enemy):
			_nearest_enemy_cache.erase("nearest_enemy")
