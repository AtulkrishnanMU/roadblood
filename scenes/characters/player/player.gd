extends CharacterBody2D

signal combo_streak_changed(current: int)

@onready var color_rect = $ColorRect

const FLOAT_SPEED = 50.0
const FLOAT_HEIGHT = 20.0
const ROTATION_SPEED = 2.0  # radians per second
const BULLET_SCENE = preload("res://scenes/objects/bullet/bullet.tscn")
const GUNSHOT_SOUND_PATH = "res://sounds/gunshot.mp3"
const KNOCKBACK_FORCE = 800.0  # knockback force when shooting (increased from 500)
const BARREL_LENGTH = 40  # length of the barrel rectangle
const BARREL_WIDTH = 20
const HIT_SOUND = preload("res://sounds/hit.mp3")  # hit sound effect
const HEALTH_GAIN_SOUND = preload("res://sounds/health-gain.mp3")  # health gain sound effect
const BLOOD_SPLASH_SCENE = preload("res://scenes/blood/blood_splash.tscn")  # blood splash effect
const SCREEN_SHAKE_INTENSITY = 2.5  # screen shake intensity (reduced for subtlety)
const SCREEN_SHAKE_DURATION = 0.5  # screen shake duration in seconds (reduced for subtlety)
const MOVEMENT_SPEED = 400.0  # player movement speed with arrow keys
const MULTI_BULLET_KILLS = 30  # kills needed to enable multi-bullet shooting
const BULLET_SPREAD_ANGLE = 15.0  # spread angle for multi-bullets (degrees)

# Utility references
const TimeUtils = preload("res://scripts/utils/time_utils.gd")
const AudioUtils = preload("res://scripts/utils/audio_utils.gd")

# Multi-bullet system
var multi_bullet_enabled = false
var current_gun_width = BARREL_WIDTH

# Health system (based on ashbreaker)
const MAX_HEALTH := 200
var health: int = MAX_HEALTH
const HEALTH_BAR_SCENE = preload("res://scenes/ui/health_bar.tscn")
var health_bar: ProgressBar

# Combo system constants
const COMBO_DURATION = 5.0  # Seconds before combo expires
const HEALTH_POPUP_HEIGHT = 15.0  # Height for health gain popups

# Combo system variables
var combo_streak: int = 0
var combo_active: bool = false
var combo_timer: Timer = null

var time = 0.0
var shoot_angle = 0.0
var base_y = 0.0
var knockback_velocity = Vector2.ZERO
var screen_shake_time = 0.0
var camera: Camera2D
var slow_mo_shoot_counter = 0  # Counter for slow-time shooting limitation
var was_mouse_pressed = false  # Track previous mouse state

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

func _on_combo_timer_timeout():
	# Apply healing before resetting the combo
	apply_combo_healing()
	# Reset combo streak
	reset_combo_streak()

func increment_combo_streak():
	combo_streak += 1
	combo_active = true
	
	# Refresh combo timer
	if combo_timer:
		combo_timer.stop()
		combo_timer.start()
	
	emit_signal("combo_streak_changed", combo_streak)
	print("Combo streak increased to: ", combo_streak)

func reset_combo_streak():
	combo_streak = 0
	combo_active = false
	
	# Stop combo timer
	if combo_timer:
		combo_timer.stop()
	
	emit_signal("combo_streak_changed", 0)
	print("Combo streak reset")

func apply_combo_healing():
	print("Applying combo healing for streak: ", combo_streak)
	if combo_streak > 0:
		# Calculate heal potential using triangular formula: n(n+1)/2
		var heal_potential = combo_streak * (combo_streak + 1) / 2
		var actual_heal = heal_potential
		
		print("Heal potential: ", actual_heal)
		
		if actual_heal > 0:
			var old_health = health
			health = min(health + actual_heal, MAX_HEALTH)
			
			print("Health increased from ", old_health, " to ", health)
			
			# Update health bar
			if health_bar:
				health_bar.update_health(health, MAX_HEALTH)
				print("Health bar updated")
			
			# Show healing popup
			_spawn_health_popup(actual_heal)
			print("Health popup spawned")
			
			print("Healed for ", actual_heal, " HP from combo of ", combo_streak)
		else:
			print("No healing needed")
		
		# Reset combo streak after healing is applied
		reset_combo_streak()

func _spawn_health_popup(amount: int):
	# Play health gain sound
	_play_health_gain_sound()
	
	# Create a simple floating text popup for healing
	var popup_label = Label.new()
	popup_label.text = "+" + str(amount) + " HP"
	popup_label.modulate = Color.GREEN
	popup_label.position = global_position + Vector2(-20, -HEALTH_POPUP_HEIGHT - 30)  # Position 30 pixels higher
	
	# Increase font size even more for better visibility
	popup_label.add_theme_font_size_override("font_size", 36)
	
	# Add outline for better readability
	popup_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	popup_label.add_theme_constant_override("shadow_offset_x", 3)
	popup_label.add_theme_constant_override("shadow_offset_y", 3)
	
	# Add to scene
	get_tree().current_scene.add_child(popup_label)
	
	# Animate the popup with flicker effect
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Flicker effect - alternate between bright green and normal green
	var flicker_tween = create_tween()
	flicker_tween.set_loops(3)  # Flicker 3 times
	for i in range(3):
		flicker_tween.tween_property(popup_label, "modulate", Color.WHITE, 0.1)
		flicker_tween.tween_property(popup_label, "modulate", Color.GREEN, 0.1)
	
	# Float up and fade out with larger movement
	tween.tween_property(popup_label, "position:y", popup_label.position.y - 70, 1.5)
	tween.tween_property(popup_label, "modulate:a", 0.0, 1.5)
	
	# Remove after animation
	tween.tween_callback(popup_label.queue_free).set_delay(1.5)

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
	# Find existing health bar in UI layer
	var scene_root = get_tree().current_scene
	health_bar = scene_root.get_node_or_null("UI/HealthBar")
	
	# Initialize health bar with current health
	if health_bar:
		health_bar.update_health(health, MAX_HEALTH)

func _physics_process(delta):
	time += delta
	
	# Apply knockback decay with ease-out
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 200.0 * delta)
	
	# Handle arrow key movement
	var movement_input = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		movement_input.x += 1
	if Input.is_action_pressed("ui_left"):
		movement_input.x -= 1
	if Input.is_action_pressed("ui_down"):
		movement_input.y += 1
	if Input.is_action_pressed("ui_up"):
		movement_input.y -= 1
	
	# Apply movement if there's input
	if movement_input.length() > 0:
		movement_input = movement_input.normalized()
		position += movement_input * MOVEMENT_SPEED * delta
		# Update base_y to follow movement
		base_y = position.y
	
	# Apply knockback to position
	position += knockback_velocity * delta
	
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
	
	# Floating behavior only when idle (no knockback)
	if knockback_velocity.length() < 1.0:  # Player is essentially idle
		var float_phase = time * FLOAT_SPEED * 0.1
		var smooth_float = smoothstep(-1.0, 1.0, sin(float_phase))  # Ease-in and ease-out
		var float_offset = smooth_float * FLOAT_HEIGHT
		
		# Always update base_y to current position minus current float offset
		base_y = position.y - float_offset
		
		# Smoothly interpolate to floating position
		var target_y = base_y + float_offset
		position.y = lerp(position.y, target_y, 0.1)  # Smooth transition
	
	# Update gun rotation to follow mouse cursor
	if camera:
		var mouse_pos = get_global_mouse_position()
		shoot_angle = (mouse_pos - global_position).angle()
	
	# Shoot on left mouse click (single click detection)
	var is_mouse_pressed = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if is_mouse_pressed and not was_mouse_pressed:  # Only on initial press
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
			# Normal shooting when not in slow-time
			shoot_bullet()
			slow_mo_shoot_counter = 0  # Reset counter when not in slow-time
	
	# Update mouse state for next frame
	was_mouse_pressed = is_mouse_pressed
	
	# Draw shooting direction indicator (optional visual feedback)
	queue_redraw()

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
	
	# Apply knockback to player (opposite direction of shooting) - only for center bullet
	if abs(angle - shoot_angle) < 0.1:  # Only apply knockback for center bullet
		knockback_velocity = -shoot_direction * KNOCKBACK_FORCE
		
		# Trigger screen shake
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
	
	# Apply knockback to player
	if knockback_direction != Vector2.ZERO:
		knockback_velocity = knockback_direction * 900.0  # Increased from 600 for more impact
	
	# Apply combo healing before taking damage if combo is active
	apply_combo_healing()
	
	health = max(health - amount, 0)
	_update_health_bar()
	
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
	_update_health_bar()

func _update_health_bar():
	if health_bar:
		health_bar.update_health(health, MAX_HEALTH)

func _create_muzzle_flash(position: Vector2):
	# Create simple muzzle flash effect
	var flash = Sprite2D.new()
	add_child(flash)
	flash.global_position = position
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
	# Create audio player for gunshot sound
	var audio_player = AudioStreamPlayer2D.new()
	var gunshot_sound = load(GUNSHOT_SOUND_PATH)
	if gunshot_sound:
		audio_player.stream = gunshot_sound
		audio_player.volume_db = -5.0  # Slightly quieter
		audio_player.position = global_position
		
		# Add to scene and play
		get_parent().add_child(audio_player)
		audio_player.play()
		
		# Remove after sound finishes
		audio_player.finished.connect(audio_player.queue_free)

func _die():
	# Player death logic - for now just respawn
	health = MAX_HEALTH
	_update_health_bar()
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
