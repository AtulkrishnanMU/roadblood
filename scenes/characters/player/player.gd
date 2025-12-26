extends CharacterBody2D

signal combo_streak_changed(current: int)

@onready var color_rect = $ColorRect

const FLOAT_SPEED = 50.0
const FLOAT_HEIGHT = 20.0
const ROTATION_SPEED = 2.0  # radians per second
const BULLET_SCENE = preload("res://scenes/objects/bullet/bullet.tscn")
const GUNSHOT_SOUND_PATH = "res://sounds/gunshot.mp3"
const KNOCKBACK_FORCE = 50.0  # knockback force when shooting (made very subtle)
const BARREL_LENGTH = 40  # length of the barrel rectangle
const BARREL_WIDTH = 20
const HIT_SOUND = preload("res://sounds/hit.mp3")  # hit sound effect
const HEALTH_GAIN_SOUND = preload("res://sounds/health-gain.mp3")  # health gain sound effect
const BLOOD_SPLASH_SCENE = preload("res://scenes/blood/blood_splash.tscn")  # blood splash effect
const SCREEN_SHAKE_INTENSITY = 0.5  # screen shake intensity (very subtle)
const SCREEN_SHAKE_DURATION = 0.1  # screen shake duration in seconds (very short)
const MOVEMENT_SPEED = 1000.0  # player movement speed with arrow keys
const MULTI_BULLET_KILLS = 30  # kills needed to enable multi-bullet shooting
const BULLET_SPREAD_ANGLE = 15.0  # spread angle for multi-bullets (degrees)

# Utility references
const TimeUtils = preload("res://scenes/utility-scripts/utils/time_utils.gd")
const PopupUtils = preload("res://scenes/utility-scripts/utils/popup_utils.gd")
const AudioUtilsScript = preload("res://scenes/utility-scripts/utils/audio_utils.gd")

# Multi-bullet system
var multi_bullet_enabled = false
var current_gun_width = BARREL_WIDTH

# Health management constants
const MAX_HEALTH = 200
const HEALTH_POPUP_HEIGHT = 50.0

# Health management variables
var health: int = MAX_HEALTH

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
var base_y = 0.0
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

func _ready():
	base_y = position.y
	# Find the main camera
	camera = get_viewport().get_camera_2d()
	if camera == null:
		# Try to find camera in the scene tree
		camera = get_tree().get_first_node_in_group("camera")
	
	# Add player to group for enemy detection
	add_to_group("player")
	
	# Setup combo timer
	_setup_combo_timer()
	
	# Initialize health bar
	_setup_health_bar()

func _setup_combo_timer():
	combo_timer = Timer.new()
	combo_timer.set_wait_time(COMBO_DURATION)
	combo_timer.connect("timeout",Callable(self,"_on_combo_timer_timeout"))
	add_child(combo_timer)

func _create_or_update_combo_popup():
	var scene := get_tree().current_scene
	if scene == null:
		return
	
	if current_combo_popup == null:
		# Create new persistent popup
		current_combo_popup = Node2D.new()
		current_combo_popup.position = (global_position + Vector2(0, -100)).round()
		scene.add_child(current_combo_popup)
		
		combo_popup_label = Label.new()
		combo_popup_label.text = "x" + str(combo_streak)
		combo_popup_label.modulate = Color.ORANGE
		FontConfig.apply_popup_font_with_size(combo_popup_label, 100)
		
		current_combo_popup.add_child(combo_popup_label)
	else:
		# Update existing popup text
		combo_popup_label.text = "x" + str(combo_streak)
		# Update position to follow player
		current_combo_popup.position = (global_position + Vector2(0, -100)).round()

func _fade_out_combo_popup():
	if current_combo_popup and combo_popup_label:
		var tween = get_tree().create_tween()
		tween.tween_property(combo_popup_label, "modulate:a", 0.0, 0.5)
		tween.tween_callback(func(): 
			if current_combo_popup:
				current_combo_popup.queue_free()
				current_combo_popup = null
				combo_popup_label = null
		)

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
	print("Combo streak reset")

func apply_combo_score():
	if combo_streak > 0:
		# Calculate score using triangular formula: n(n+1)/2
		var score_potential = combo_streak * (combo_streak + 1) / 2.0
		var actual_score = int(score_potential)
		
		if actual_score > 0:
			# Add score to UI
			if ui_script:
				ui_script.add_to_score(actual_score)
			
			# Show score popup when combo is applied
			PopupUtils.spawn_score_popup(self, actual_score)

func _spawn_score_popup(amount: int):
	# Play health gain sound
	_play_health_gain_sound()
	
	# Use centralized popup system for health popup
	PopupUtils.spawn_health_popup(self, amount)

func _play_health_gain_sound():
	# Create audio player for health gain sound
	var audio_player = AudioStreamPlayer.new()
	audio_player.stream = HEALTH_GAIN_SOUND
	audio_player.volume_db = -2.0  # Slightly quieter for balance
	
	# Add to scene and play
	add_child(audio_player)
	audio_player.play()
	
	# Remove after sound finishes
	audio_player.finished.connect(audio_player.queue_free)

func _spawn_blood_splash(hit_direction: Vector2 = Vector2.ZERO):
	# Create blood splash effect
	var blood_splash = BLOOD_SPLASH_SCENE.instantiate()
	if blood_splash:
		# Add to scene at bottom layer (first to be drawn)
		var scene = get_tree().current_scene
		if scene:
			scene.add_child(blood_splash)
			scene.move_child(blood_splash, 0)
			
			# Position at player location
			blood_splash.global_position = global_position
			
			# Set direction based on hit direction or random if none
			if hit_direction != Vector2.ZERO:
				blood_splash.set_direction(-hit_direction)  # Blood splashes opposite to hit direction
			else:
				blood_splash.set_direction(Vector2.from_angle(randf() * TAU))
			
			# Player is not a dead enemy, so no reduced blood
			blood_splash.set_dead_enemy(false)

func _setup_health_bar():
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
	
	# Initialize health bar with current health
	if ui_script:
		ui_script.update_health(health, MAX_HEALTH)

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
	
	# Update base_y to follow movement
	base_y = position.y
	
	# Update combo popup position to follow player
	if current_combo_popup:
		current_combo_popup.position = (global_position + Vector2(0, -100)).round()
	
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
	
	# Remove floating behavior to maintain full player control
	# Commented out to prevent unwanted position changes
	# if knockback_velocity.length() < 1.0:  # Player is essentially idle
	#	var float_phase = time * FLOAT_SPEED * 0.1
	#	var smooth_float = smoothstep(-1.0, 1.0, sin(float_phase))  # Ease-in and ease-out
	#	var float_offset = smooth_float * FLOAT_HEIGHT
	#	
	#	# Always update base_y to current position minus current float offset
	#	base_y = position.y - float_offset
	#	
	#	# Smoothly interpolate to floating position
	#	var target_y = base_y + float_offset
	#	position.y = lerp(position.y, target_y, 0.1)  # Smooth transition
	
	# Auto-aim towards nearest enemy with smooth rotation
	if camera:
		var nearest_enemy = _find_nearest_enemy()
		if nearest_enemy:
			var target_angle = (nearest_enemy.global_position - global_position).angle()
			
			# Smoothly rotate towards target angle
			var angle_diff = target_angle - shoot_angle
			# Handle angle wrapping
			if angle_diff > PI:
				angle_diff -= 2 * PI
			elif angle_diff < -PI:
				angle_diff += 2 * PI
			
			# Rotate smoothly (adjust rotation speed as needed)
			var rotation_speed = 5.0  # Radians per second
			shoot_angle += angle_diff * rotation_speed * delta
			
			# Remove camera movement to prevent any interference
			# var camera_offset = Vector2.from_angle(shoot_angle) * 100.0  # 100 pixels offset
			# camera.global_position = lerp(camera.global_position, global_position + camera_offset, 0.1)
			
			# Auto-shoot at nearest enemy
			_auto_shoot()
		else:
			# No enemies found, don't shoot
			slow_mo_shoot_counter = 0
	
	# Draw shooting direction indicator (optional visual feedback)
	queue_redraw()

func _find_nearest_enemy():
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest_enemy = null
	var nearest_distance = INF
	
	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_enemy = enemy
	
	return nearest_enemy

func _auto_shoot():
	# Check fire rate - use slower rate for triple bullets
	var current_fire_rate = TRIPLE_BULLET_FIRE_RATE if multi_bullet_enabled else FIRE_RATE
	if shoot_timer < current_fire_rate:
		return
	
	# Reset shoot timer
	shoot_timer = 0.0
	
	# Check if we're in slow-time by accessing TimeUtils directly
	var time_utils = get_tree().get_first_node_in_group("time_utils")
	var is_slow_time = false
	if time_utils:
		is_slow_time = time_utils.is_slow_time_active
	
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
		
		# Create muzzle flash effect at barrel tip
		_create_muzzle_flash(barrel_tip)
		
		# Play gunshot sound
		_play_gunshot_sound()

func check_multi_bullet_unlock(total_kills: int):
	# Enable multi-bullet mode after 30 kills
	if total_kills >= MULTI_BULLET_KILLS and not multi_bullet_enabled:
		multi_bullet_enabled = true
		current_gun_width = BARREL_WIDTH * 2  # Double the gun width
		print("Multi-bullet mode unlocked at ", total_kills, " kills!")
		# Visual feedback could be added here

# Health management functions (based on ashbreaker)
func take_damage(amount: int, knockback_direction: Vector2 = Vector2.ZERO):
	# Play hit sound
	_play_hit_sound()
	
	# Spawn blood splash effect
	_spawn_blood_splash(knockback_direction)
	
	# No knockback applied - player movement never interrupted
	
	# Apply combo score before taking damage if combo is active
	apply_combo_score()
	
	# Reset combo streak when taking damage
	reset_combo_streak()
	
	health = max(health - amount, 0)
	if ui_script:
		ui_script.update_health(health, MAX_HEALTH)
	
	if health <= 0:
		_die()

func _play_hit_sound():
	# Create audio player for hit sound
	var audio_player = AudioStreamPlayer.new()
	audio_player.stream = HIT_SOUND
	audio_player.volume_db = 0.0  # Normal volume
	
	# Add to scene and play
	add_child(audio_player)
	audio_player.play()
	
	# Remove after sound finishes
	audio_player.finished.connect(audio_player.queue_free)

func heal(amount: int):
	health = min(health + amount, MAX_HEALTH)
	if ui_script:
		ui_script.update_health(health, MAX_HEALTH)

func _create_muzzle_flash(flash_position: Vector2):
	# Create simple muzzle flash effect
	var flash = Sprite2D.new()
	add_child(flash)
	flash.global_position = flash_position
	flash.scale = Vector2(0.5, 0.5)
	
	# Create a simple white/yellow flash texture
	var texture = ImageTexture.new()
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Draw a bright center
	var center = Vector2(16, 16)
	for x in range(32):
		for y in range(32):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			if dist < 8:
				var brightness = 1.0 - (dist / 8.0)
				image.set_pixel(x, y, Color(1.0, 1.0, 0.8 * brightness, brightness))
	
	texture.set_image(image)
	flash.texture = texture
	
	# Fade out quickly
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(flash, "modulate:a", 0.0, 0.1)
	tween.tween_callback(flash.queue_free)

func _play_gunshot_sound():
	# Create audio player for gunshot sound with lower volume and random pitch
	var audio_player = AudioStreamPlayer2D.new()
	var gunshot_sound = load(GUNSHOT_SOUND_PATH)
	if gunshot_sound:
		audio_player.stream = gunshot_sound
		audio_player.volume_db = 0.0  # Full volume for gunshot sounds
		audio_player.position = global_position
		audio_player.pitch_scale = randf_range(0.8, 1.2)  # Random pitch variation
		
		# Add to scene and play
		get_parent().add_child(audio_player)
		audio_player.play()
		
		# Remove after sound finishes
		audio_player.finished.connect(audio_player.queue_free)

func _die():
	# Player death logic - for now just respawn
	health = MAX_HEALTH
	if ui_script:
		ui_script.update_health(health, MAX_HEALTH)
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
	
	# Draw rectangle
	var points = PackedVector2Array([corner1, corner2, corner3, corner4])
	draw_colored_polygon(points, Color.GRAY)
