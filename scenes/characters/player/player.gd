extends CharacterBody2D

signal combo_streak_changed(current: int)

@onready var color_rect = $ColorRect

# Static utility references - cached at class level for better performance
static var _TimeUtils: Resource = preload("res://scenes/utility-scripts/utils/time_utils.gd")
static var _AudioUtilsScript: Resource = preload("res://scenes/utility-scripts/utils/audio_utils.gd")
static var _BloodEffectsManager: Resource = preload("res://scenes/utility-scripts/utils/blood_effects_manager.gd")
static var _HealthComponent: Resource = preload("res://scenes/utility-scripts/utils/health_component.gd")
static var _CacheManager: Resource = preload("res://scenes/utility-scripts/utils/cache_manager.gd")
static var _UIEventManager: Resource = preload("res://scenes/utility-scripts/utils/ui_event_manager.gd")

# Game constants
const ROTATION_SPEED = 4.0  # radians per second
const BULLET_SCENE = preload("res://scenes/objects/bullet/bullet.tscn")
const KNOCKBACK_FORCE = 50.0  # knockback force when shooting (made very subtle)
const BARREL_LENGTH = 50  # length of the barrel rectangle
const BARREL_WIDTH = 20
const HIT_SOUND = preload("res://sounds/hit.mp3")  # hit sound effect
const HEALTH_GAIN_SOUND = preload("res://sounds/health-gain.mp3")  # health gain sound effect
const GUNSHOT_SOUND = preload("res://sounds/gunshot.mp3")  # gunshot sound effect
const SCREEN_SHAKE_INTENSITY = 0.5  # screen shake intensity (very subtle)
const SCREEN_SHAKE_DURATION = 0.1  # screen shake duration in seconds (very short)
const MOVEMENT_SPEED = 1000.0  # player movement speed with arrow keys
const MULTI_BULLET_KILLS = 30  # kills needed to enable multi-bullet shooting
const BULLET_SPREAD_ANGLE = 15.0  # spread angle for multi-bullets (degrees)

# Helper function to get PopupManager instance (cached)
var _popup_manager_cache: Node
func get_popup_manager():
	if _popup_manager_cache == null or not is_instance_valid(_popup_manager_cache):
		_popup_manager_cache = get_tree().get_first_node_in_group("popup_manager")
		if _popup_manager_cache == null:
						return null
	return _popup_manager_cache

# Multi-bullet system
var multi_bullet_enabled = false
var current_gun_width = BARREL_WIDTH

# Player stats
var MAX_HEALTH = 100
var SPEED = 300.0

# Player signals
signal damage_taken(amount: int)  # For intelligent spawn rate system

# Health management
var health_component

# Combo system constants
const COMBO_DURATION = 1.0  # Seconds before combo expires

# Combo system variables
var combo_streak: int = 0
var combo_active: bool = false
var combo_timer: Timer = null
var current_combo_popup: Node2D = null  # Track persistent combo popup
var combo_popup_label: Label = null   # Track the label for text updates

var time = 0.0
var shoot_angle = 0.0
var knockback_velocity = Vector2.ZERO
var screen_shake_time = 0.0
var camera: Camera2D
var ui: CanvasLayer
var ui_script: Node
var slow_mo_shoot_counter = 0  # Counter for slow-time shooting limitation
var was_mouse_pressed = false  # Track previous mouse state
var shoot_timer = 0.0  # Timer for fire rate control
const FIRE_RATE = 0.2  # Seconds between shots (5 shots per second)
const TRIPLE_BULLET_FIRE_RATE = 0.4  # Seconds between triple bullet shots (2.5 shots per second)

# Cached references for performance
var _nearest_enemy_cache: Node = null
var _nearest_enemy_distance: float = INF
var _enemy_cache_update_timer: float = 0.0
const ENEMY_CACHE_UPDATE_INTERVAL = 0.1  # Update nearest enemy every 100ms (reduced from 250ms for faster reaction)
var _ui_event_manager_cache: Node = null
var _time_utils_cache: Node = null

# Single optimized muzzle flash texture for performance
static var muzzle_flash_texture: ImageTexture = null

static func _initialize_muzzle_flash_texture():
	if muzzle_flash_texture != null:
		return
	
	# Create single optimized texture
	muzzle_flash_texture = _create_optimized_muzzle_flash()

static func _create_optimized_muzzle_flash() -> ImageTexture:
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Create a simple, efficient circular gradient pattern
	var center = Vector2(16, 16)
	var max_radius = 12.0
	
	for x in range(32):
		for y in range(32):
			var pos = Vector2(x, y)
			var distance = pos.distance_to(center)
			
			if distance <= max_radius:
				# Create smooth gradient from center to edge
				var alpha = 1.0 - (distance / max_radius)
				alpha = alpha * alpha  # Quadratic falloff for smoother look
				
				if alpha > 0.1:  # Optimization: skip very transparent pixels
					var brightness = 0.9 + alpha * 0.1
					image.set_pixel(x, y, Color(brightness, brightness * 0.7, 0.0, alpha))
	
	var texture := ImageTexture.new()
	texture.set_image(image)
	return texture

func _ready():
	# Find the main camera
	camera = get_viewport().get_camera_2d()
	if camera == null:
		# Try to find camera in the scene tree
		camera = get_tree().get_first_node_in_group("camera")
	
	# Add player to group for enemy detection
	add_to_group("player")
	
	# Initialize health component
	_setup_health_component()
	
	# Setup combo timer
	_setup_combo_timer()
	
	# Initialize single muzzle flash texture
	_initialize_muzzle_flash_texture()
	
	# Initialize cached references
	_initialize_cached_references()

func _initialize_cached_references():
	# Cache frequently accessed nodes (popup_manager_cache already exists)
	_ui_event_manager_cache = get_tree().get_first_node_in_group("ui_event_manager")
	_time_utils_cache = get_tree().get_first_node_in_group("time_utils")
	_nearest_enemy_cache = null
	_nearest_enemy_distance = INF
	_enemy_cache_update_timer = 0.0
	
	# CRITICAL: Connect to enemy spawn events for zero reaction time
	var enemy_spawner = get_tree().get_first_node_in_group("enemy_spawner")
	if enemy_spawner and enemy_spawner.has_signal("enemy_spawned"):
		enemy_spawner.enemy_spawned.connect(_on_enemy_spawned)

func _setup_health_component():
	# Find the UI CanvasLayer
	var scene_root = get_tree().current_scene
	ui = scene_root.get_node_or_null("UI")
	
	# Get the actual UI Control node from within the CanvasLayer
	var ui_control = ui.get_node_or_null("UI") if ui else null
	
	# Manually load and attach the UI script if not already attached
	if ui_control and ui_control.get_script() == null:
		var ui_script_resource = load("res://scenes/ui/ui.gd")
		ui_control.set_script(ui_script_resource)
	
	ui_script = ui_control
	
	# Initialize health component
	health_component = _HealthComponent.new(self, MAX_HEALTH)
	
	# Connect health component signals
	health_component.health_changed.connect(_on_health_changed)
	health_component.health_depleted.connect(_on_health_depleted)
	health_component.damage_taken.connect(_on_damage_taken)

func _on_health_changed(current: int, max_hp: int):
	# Use cached UI event manager for health updates
	if _ui_event_manager_cache == null or not is_instance_valid(_ui_event_manager_cache):
		_ui_event_manager_cache = _CacheManager.get_first_node_in_group_cached("ui_event_manager", get_tree())
	if _ui_event_manager_cache:
		_ui_event_manager_cache.update_player_health(current, max_hp)

func _on_health_depleted():
	_die()

func _on_damage_taken(amount: int):
	# Emit damage_taken signal for intelligent spawn rate system
	damage_taken.emit(amount)
	
	# Play hit sound when damaged
	_play_hit_sound()

func _setup_combo_timer():
	combo_timer = Timer.new()
	combo_timer.set_wait_time(COMBO_DURATION)
	combo_timer.connect("timeout",Callable(self,"_on_combo_timer_timeout"))
	add_child(combo_timer)

func _create_or_update_combo_popup():
	# Use popup manager for combo popup
	if current_combo_popup == null:
		var popup_mgr = get_popup_manager()
		if popup_mgr:
			current_combo_popup = popup_mgr.spawn_combo_popup(self, combo_streak)
		else:
			# Fallback: create simple combo popup manually
						return
		if current_combo_popup:
			combo_popup_label = current_combo_popup.get_child(0) if current_combo_popup.get_child_count() > 0 else null
	else:
		# Update existing popup
		var popup_mgr = get_popup_manager()
		if popup_mgr:
			popup_mgr.update_combo_popup(current_combo_popup, self, combo_streak)

func _fade_out_combo_popup():
	# Use popup manager to fade out combo popup
	var popup_mgr = get_popup_manager()
	if popup_mgr and current_combo_popup:
		popup_mgr.fade_out_combo_popup(current_combo_popup)
	current_combo_popup = null
	combo_popup_label = null

func _on_combo_timer_timeout():
	# Apply score before resetting the combo
	apply_combo_score()
	# Reset combo streak
	reset_combo_streak()

func increment_combo_streak():
	combo_streak += 1
	combo_active = true
	
	# Refresh combo timer
	if combo_timer:
		combo_timer.stop()
		combo_timer.start()
	
	# Update persistent combo popup
	_create_or_update_combo_popup()
	
	emit_signal("combo_streak_changed", combo_streak)

func reset_combo_streak():
	combo_streak = 0
	combo_active = false
	
	# Stop combo timer
	if combo_timer:
		combo_timer.stop()
	
	# Fade out combo popup
	_fade_out_combo_popup()
	
	emit_signal("combo_streak_changed", 0)
	
func apply_combo_score():
	if combo_streak > 0:
		# Calculate score using triangular formula: n(n+1)/2
		var score_potential = combo_streak * (combo_streak + 1) / 2.0
		var actual_score = int(score_potential)
		
		if actual_score > 0:
			# Add score using cached UI event manager
			if _ui_event_manager_cache == null or not is_instance_valid(_ui_event_manager_cache):
				_ui_event_manager_cache = _CacheManager.get_first_node_in_group_cached("ui_event_manager", get_tree())
			if _ui_event_manager_cache:
				_ui_event_manager_cache.add_score(actual_score)
			
			# Show score popup when combo is applied
			var popup_mgr = get_popup_manager()
			if popup_mgr:
				popup_mgr.spawn_floating_popup(self, "+" + str(actual_score), Color.YELLOW, Vector2(0, -50), 64)

func _spawn_score_popup(amount: int):
	# Use popup manager for score popup
	var popup_mgr = get_popup_manager()
	if popup_mgr:
		popup_mgr.spawn_floating_popup(self, "+" + str(amount), Color.YELLOW, Vector2(0, -50), 64)

func _play_health_gain_sound():
	# Use AudioUtils pool for health gain sound
	_AudioUtilsScript.play_positioned_sound(HEALTH_GAIN_SOUND, global_position, 0.9, 1.1)

func _spawn_blood_splash(hit_direction: Vector2 = Vector2.ZERO):
	# Use centralized blood effects manager
	_BloodEffectsManager.spawn_player_blood_splash(global_position, hit_direction, self)

func _physics_process(delta):
	time += delta
	
	# Update shoot timer
	shoot_timer += delta
	
	# Handle WASD and arrow key movement
	var movement_input = Vector2.ZERO
	
	# Vertical movement (W/S or Up/Down)
	if Input.is_key_pressed(KEY_W) or Input.is_action_pressed("ui_up"):
		movement_input.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_action_pressed("ui_down"):
		movement_input.y += 1
	
	# Horizontal movement (A/D or Left/Right)
	if Input.is_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"):
		movement_input.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"):
		movement_input.x += 1
	
	# Apply movement if there's input
	if movement_input.length() > 0:
		movement_input = movement_input.normalized()
		velocity = movement_input * MOVEMENT_SPEED
	else:
		velocity = Vector2.ZERO
	
	# Simple movement
	move_and_slide()
	
	# Update combo popup position to follow player
	if current_combo_popup:
		var popup_mgr = get_popup_manager()
		if popup_mgr:
			popup_mgr.update_combo_popup(current_combo_popup, self, combo_streak)
	
	# Update screen shake
	if screen_shake_time > 0:
		screen_shake_time -= delta
		var shake_offset = Vector2(
			randf_range(-1, 1) * SCREEN_SHAKE_INTENSITY,
			randf_range(-1, 1) * SCREEN_SHAKE_INTENSITY
		)
		if camera:
			camera.offset = shake_offset
	else:
		if camera:
			camera.offset = Vector2.ZERO
	
	# Auto-aim towards nearest enemy - immediate face
	if camera:
		var nearest_enemy = _find_nearest_enemy(delta)
		if nearest_enemy:
			# IMMEDIATELY face the enemy - no smooth rotation
			shoot_angle = (nearest_enemy.global_position - global_position).angle()
			
			# Auto-shoot at nearest enemy
			_auto_shoot()
		else:
			# No enemies found, don't shoot
			slow_mo_shoot_counter = 0
	
	# Draw shooting direction indicator (optional visual feedback)
	queue_redraw()

func _find_nearest_enemy(delta: float):
	# Use cached nearest enemy with periodic updates (use delta parameter instead of expensive call)
	_enemy_cache_update_timer += delta
	
	# Smart cache invalidation based on multiple factors
	var should_update = false
	
	# Update if interval passed
	if _enemy_cache_update_timer >= ENEMY_CACHE_UPDATE_INTERVAL:
		should_update = true
	
	# Update if cache is invalid
	elif _nearest_enemy_cache == null or not is_instance_valid(_nearest_enemy_cache):
		should_update = true
	
	# Update if player moved significantly from cached enemy position
	elif _nearest_enemy_cache and _nearest_enemy_distance != INF:
		var current_distance = global_position.distance_to(_nearest_enemy_cache.global_position)
		var distance_change = abs(current_distance - _nearest_enemy_distance)
		# Update if distance changed by more than 20% or 50 pixels
		if distance_change > max(_nearest_enemy_distance * 0.2, 50.0):
			should_update = true
	
	if should_update:
		var new_enemy = _CacheManager.get_nearest_enemy_cached(global_position, get_tree())
		
		# FALLBACK: If cache manager returns null but we have a valid cached enemy, keep it
		if new_enemy == null and _nearest_enemy_cache != null and is_instance_valid(_nearest_enemy_cache):
			# Don't update cache, just reset timer
			_enemy_cache_update_timer = 0.0
		else:
			_nearest_enemy_cache = new_enemy
			if _nearest_enemy_cache:
				_nearest_enemy_distance = global_position.distance_to(_nearest_enemy_cache.global_position)
			else:
				_nearest_enemy_distance = INF
			_enemy_cache_update_timer = 0.0
	
	return _nearest_enemy_cache

func _auto_shoot():
	# Check fire rate - use slower rate for triple bullets
	var current_fire_rate = TRIPLE_BULLET_FIRE_RATE if multi_bullet_enabled else FIRE_RATE
	if shoot_timer < current_fire_rate:
		return
	
	# Reset shoot timer
	shoot_timer = 0.0
	
	# Check if we're in slow-time by using cached time utils
	var is_slow_time = false
	if _time_utils_cache == null or not is_instance_valid(_time_utils_cache):
		_time_utils_cache = _CacheManager.get_first_node_in_group_cached("time_utils", get_tree())
	if _time_utils_cache:
		is_slow_time = _time_utils_cache.is_slow_time_active
	
	if is_slow_time:
		# Increment counter during slow-time
		slow_mo_shoot_counter += 1
		# Only shoot every 3 presses (counter % 3 == 1)
		if slow_mo_shoot_counter % 3 == 1:
			shoot_bullet()
	else:
		# Auto-shoot continuously when not in slow-time
		shoot_bullet()
		slow_mo_shoot_counter = 0  # Reset counter when not in slow-time

func _on_enemy_spawned(enemy: Node):
	# IMMEDIATE response to new enemy spawn - zero reaction time
	_handle_new_enemy(enemy)

func _handle_new_enemy(enemy: Node):
	# Check if this enemy is closer than current target
	if not is_instance_valid(enemy):
		return
	
	var enemy_distance = global_position.distance_to(enemy.global_position)
	
	# Update cache immediately if:
	# - No current target, OR
	# - New enemy is closer than current target, OR  
	# - Current target is invalid
	if (_nearest_enemy_cache == null or 
		not is_instance_valid(_nearest_enemy_cache) or
		enemy_distance < _nearest_enemy_distance):
		
		# IMMEDIATE cache update - no delays
		_nearest_enemy_cache = enemy
		_nearest_enemy_distance = enemy_distance
		_enemy_cache_update_timer = 0.0
		
		# IMMEDIATELY face the enemy - no smooth rotation delay
		shoot_angle = (enemy.global_position - global_position).angle()
		
		# IMMEDIATE continuous shooting - reset timer to 0 to allow instant shooting
		shoot_timer = 0.0

func shoot_bullet():
	# Check if multi-bullet mode is enabled
	if multi_bullet_enabled:
		# Shoot 3 bullets in a spread pattern
		for i in range(3):
			var angle_offset = (i - 1) * deg_to_rad(BULLET_SPREAD_ANGLE)  # -15°, 0°, +15°
			_create_bullet_at_angle(shoot_angle + angle_offset)
	else:
		# Single bullet shot
		_create_bullet_at_angle(shoot_angle)

func _create_bullet_at_angle(angle: float):
	var bullet = BULLET_SCENE.instantiate()
	get_parent().add_child(bullet)
	
	# Calculate barrel tip position
	var barrel_tip = Vector2(cos(angle), sin(angle)) * BARREL_LENGTH
	var spawn_position = global_position + barrel_tip
	bullet.global_position = spawn_position
	
	# Calculate shooting direction
	var shoot_direction = Vector2(cos(angle), sin(angle))
	bullet.setup(shoot_direction)
	
	# Trigger screen shake (only for center bullet)
	if abs(angle - shoot_angle) < 0.1:  # Only apply effects for center bullet
		screen_shake_time = SCREEN_SHAKE_DURATION
		
		# Create muzzle flash effect slightly in front of barrel tip
		var flash_position = spawn_position + shoot_direction * 35.0  # 20 pixels in front of barrel
		_create_muzzle_flash(flash_position, shoot_direction)
		
		# Play gunshot sound
		_play_gunshot_sound()

func check_multi_bullet_unlock(total_kills: int):
	# Enable multi-bullet mode after 30 kills
	if total_kills >= MULTI_BULLET_KILLS and not multi_bullet_enabled:
		multi_bullet_enabled = true
		current_gun_width = BARREL_WIDTH * 2  # Double the gun width
				# Visual feedback could be added here

# Health management functions (using centralized HealthComponent)
func take_damage(amount: int, knockback_direction: Vector2 = Vector2.ZERO):
	# Apply combo score before taking damage if combo is active
	apply_combo_score()
	
	# Reset combo streak when taking damage
	reset_combo_streak()
	
	# Use health component to handle damage
	var was_depleted = health_component.take_damage(amount, knockback_direction, true)
	
	# Health component handles UI updates and effects via signals

func _play_hit_sound():
	# Use AudioUtils pool for hit sound
	_AudioUtilsScript.play_positioned_sound(HIT_SOUND, global_position, 0.9, 1.1)

func heal(amount: int):
	# Use health component to handle healing
	health_component.heal(amount)

func _create_muzzle_flash(flash_position: Vector2, shoot_direction: Vector2):
		
	# Get the main scene to add muzzle flash to world space
	var scene: Node = Engine.get_main_loop().current_scene
	if scene == null:
		return
	
	# Create muzzle flash container
	var flash_root := Node2D.new()
	flash_root.position = flash_position
	flash_root.rotation = shoot_direction.angle()
	scene.add_child(flash_root)
	
	# Create multiple flash particles for burst effect
	var flash_count = 4
	for i in range(flash_count):
		var flash := Sprite2D.new()
		# Use single optimized texture
		flash.texture = get_muzzle_flash_texture()
		
		# Random positioning within small radius
		var spread_angle = randf_range(-0.3, 0.3)  # Small spread in radians
		var distance = randf_range(2.0, 8.0)
		flash.position = Vector2.RIGHT.rotated(spread_angle) * distance
		
		# Random size variation (uniform scale for square shape)
		var scale = randf_range(3.0, 5.0)  # Increased size for better visibility
		flash.scale = Vector2(scale, scale)  # Keep square aspect ratio
		
		# Bright yellow-orange color with maximum opacity
		flash.modulate = Color(1.0, randf_range(0.6, 0.9), 0.0, 1.0)  # Maximum opacity
		
		flash_root.add_child(flash)
		
		# Animate flash: quick fade out and scale down
		var tween := flash_root.create_tween()
		tween.set_parallel(true)
		tween.tween_property(flash, "modulate:a", 0.0, 0.1)  # Much shorter duration
		tween.tween_property(flash, "scale", Vector2.ZERO, 0.1)  # Much shorter duration
		tween.finished.connect(flash.queue_free)
	
	# Remove the container after all flashes are done
	var cleanup_tween := flash_root.create_tween()
	cleanup_tween.tween_callback(flash_root.queue_free).set_delay(0.15)  # Shorter cleanup delay


static func get_muzzle_flash_texture() -> ImageTexture:
	if muzzle_flash_texture == null:
		_initialize_muzzle_flash_texture()
	return muzzle_flash_texture

func _play_gunshot_sound():
	# Use AudioUtils pool for gunshot sound with lower volume and random pitch
	_AudioUtilsScript.play_positioned_sound(GUNSHOT_SOUND, global_position, 0.8, 1.2)

func _die():
	# Player death logic - for now just respawn
	health_component.reset_health()
	position = Vector2.ZERO  # Reset position

func _draw():
	# Draw barrel as rectangle
	var barrel_start = Vector2.ZERO
	var barrel_end = Vector2(cos(shoot_angle), sin(shoot_angle)) * BARREL_LENGTH
	
	# Calculate perpendicular direction for rectangle width
	var perp_dir = Vector2(-sin(shoot_angle), cos(shoot_angle)) * (BARREL_WIDTH * 0.5)
	
	# Define rectangle corners
	var corner1 = barrel_start + perp_dir
	var corner2 = barrel_start - perp_dir
	var corner3 = barrel_end - perp_dir
	var corner4 = barrel_end + perp_dir
	
	# Draw the barrel rectangle
	var points = PackedVector2Array([corner1, corner2, corner3, corner4])
	draw_colored_polygon(points, Color.GRAY)
