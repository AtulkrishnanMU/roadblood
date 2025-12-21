extends CharacterBody2D

@onready var color_rect = $ColorRect

const FLOAT_SPEED = 50.0
const FLOAT_HEIGHT = 20.0
const ROTATION_SPEED = 2.0  # radians per second
const BULLET_SCENE = preload("res://scenes/objects/bullet/bullet.tscn")
const CASING_SCENE = preload("res://scenes/objects/bullet_casing/bullet_casing.tscn")
const GUNSHOT_SOUND_PATH = "res://sounds/gunshot.mp3"
const KNOCKBACK_FORCE = 500.0  # knockback force when shooting
const BARREL_LENGTH = 40  # length of the barrel rectangle
const BARREL_WIDTH = 24   # width of the barrel rectangle (much larger)
const SCREEN_SHAKE_INTENSITY = 2.5  # screen shake intensity (reduced for subtlety)
const SCREEN_SHAKE_DURATION = 0.5  # screen shake duration in seconds (reduced for subtlety)
const MOVEMENT_SPEED = 400.0  # player movement speed with arrow keys

# Health system (based on ashbreaker)
const MAX_HEALTH := 200
var health: int = MAX_HEALTH
const HEALTH_BAR_SCENE = preload("res://scenes/ui/health_bar.tscn")
var health_bar: ProgressBar

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
	
	# Create and setup health bar
	_setup_health_bar()

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
	var bullet = BULLET_SCENE.instantiate()
	get_parent().add_child(bullet)
	
	# Calculate barrel tip position
	var barrel_tip = Vector2(cos(shoot_angle), sin(shoot_angle)) * BARREL_LENGTH
	var spawn_position = global_position + barrel_tip
	bullet.global_position = spawn_position
	
	# Calculate shooting direction
	var shoot_dir = Vector2(cos(shoot_angle), sin(shoot_angle))
	bullet.setup(shoot_dir)
	
	# Apply knockback to player (opposite direction of shooting)
	knockback_velocity = -shoot_dir * KNOCKBACK_FORCE
	
	# Trigger screen shake
	screen_shake_time = SCREEN_SHAKE_DURATION
	
	# Create muzzle flash effect at barrel tip
	const GunUtils = preload("res://scripts/utils/gun_utils.gd")
	GunUtils.create_muzzle_flash(spawn_position, shoot_dir)
	
	# Play gunshot sound
	const AudioUtils = preload("res://scripts/utils/audio_utils.gd")
	var gunshot_sound = load(GUNSHOT_SOUND_PATH)
	if gunshot_sound:
		var audio_player = AudioStreamPlayer2D.new()
		audio_player.stream = gunshot_sound
		audio_player.position = spawn_position
		get_parent().add_child(audio_player)
		AudioUtils.play_random_pitch(audio_player, 0.8, 1.2)
		audio_player.finished.connect(audio_player.queue_free)
	
	# Eject bullet casing
	eject_casing(shoot_dir)

func eject_casing(shoot_dir: Vector2):
	var casing = CASING_SCENE.instantiate()
	get_parent().add_child(casing)
	
	# Calculate ejection position (near the gun base, opposite side of barrel)
	var eject_offset = Vector2(-sin(shoot_angle), cos(shoot_angle)) * 15  # Perpendicular to barrel
	var eject_position = global_position + eject_offset
	
	# Eject in opposite direction of shooting with some randomness
	var eject_direction = -shoot_dir.rotated(randf_range(-0.3, 0.3))
	casing.setup(eject_position, eject_direction)

# Health management functions (based on ashbreaker)
func take_damage(amount: int):
	health = max(health - amount, 0)
	_update_health_bar()
	
	if health <= 0:
		_die()

func heal(amount: int):
	health = min(health + amount, MAX_HEALTH)
	_update_health_bar()

func _update_health_bar():
	if health_bar:
		health_bar.update_health(health, MAX_HEALTH)

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
