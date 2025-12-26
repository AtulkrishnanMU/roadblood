extends Node2D

class_name HealthSpawner

const HEALTH_PICKUP_SCENE = preload("res://scenes/objects/health/health_pickup.tscn")
const SPAWN_INTERVAL = 15.0  # Spawn health every 15 seconds
const MAX_HEALTH_PICKUPS = 3  # Maximum health pickups at once
const SPAWN_MARGIN = 50  # Distance from room edges

var spawn_timer: Timer
var room_bounds: Rect2

func _ready():
	# Set up spawn timer
	spawn_timer = Timer.new()
	spawn_timer.wait_time = SPAWN_INTERVAL
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	spawn_timer.start()
	
	# Get room bounds from the room object
	_find_room_bounds()

func _find_room_bounds():
	# Try to find the room in the scene
	var room = get_tree().get_first_node_in_group("room")
	if room and room.has_method("get_bounds"):
		room_bounds = room.get_bounds()
	else:
		# Fallback: use a default room size
		room_bounds = Rect2(100, 100, 1000, 600)
		print("HealthSpawner: Using default room bounds")

func _on_spawn_timer_timeout():
	# Check if we can spawn more health pickups
	var current_health_pickups = get_tree().get_nodes_in_group("health_pickups").size()
	if current_health_pickups >= MAX_HEALTH_PICKUPS:
		return
	
	# Spawn a health pickup at a random position
	_spawn_health_pickup()

func _spawn_health_pickup():
	# Generate random position within room bounds
	var random_x = randf_range(room_bounds.position.x + SPAWN_MARGIN, room_bounds.position.x + room_bounds.size.x - SPAWN_MARGIN)
	var random_y = randf_range(room_bounds.position.y + SPAWN_MARGIN, room_bounds.position.y + room_bounds.size.y - SPAWN_MARGIN)
	var spawn_position = Vector2(random_x, random_y)
	
	# Create health pickup
	var health_pickup = HEALTH_PICKUP_SCENE.instantiate()
	if health_pickup:
		health_pickup.position = spawn_position
		get_tree().current_scene.add_child(health_pickup)
		print("Health pickup spawned at: ", spawn_position)

func stop_spawning():
	# Stop the spawn timer
	if spawn_timer:
		spawn_timer.stop()

func start_spawning():
	# Start the spawn timer
	if spawn_timer:
		spawn_timer.start()
