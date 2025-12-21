class_name RandomCache
extends RefCounted

# Cache system for random values to reduce CPU overhead during combat
# Pre-generates common random ranges and provides efficient lookup

static var instance: RandomCache

# Pre-generated random value arrays for common ranges
var scale_values: Array[float] = []
var angle_offsets: Array[float] = []
var positions_8: Array[Vector2] = []
var positions_6: Array[Vector2] = []
var rotations: Array[float] = []
var fade_times: Array[Vector2] = []  # x: start_time, y: duration
var speeds_normal: Array[float] = []
var speeds_dead: Array[float] = []
var drift_values: Array[Vector2] = []

const CACHE_SIZE = 128  # Number of pre-generated values per type

func _init() -> void:
	if instance == null:
		instance = self
		_generate_cache()

func _generate_cache() -> void:
	# Pre-generate all random values at startup
	_generate_scale_values()
	_generate_angle_offsets()
	_generate_positions()
	_generate_rotations()
	_generate_fade_times()
	_generate_speeds()
	_generate_drift_values()

func _generate_scale_values() -> void:
	# Different scale ranges for different particle types
	for i in range(CACHE_SIZE):
		scale_values.append(randf_range(0.6, 1.5))  # Combined range for all uses

func _generate_angle_offsets() -> void:
	# Angle offsets for particle spreading
	for i in range(CACHE_SIZE):
		angle_offsets.append(randf_range(-PI/3, PI/3))

func _generate_positions() -> void:
	# Pre-generated position offsets
	for i in range(CACHE_SIZE):
		positions_8.append(Vector2(randf_range(-8, 8), randf_range(-8, 8)))
		positions_6.append(Vector2(randf_range(-6, 6), randf_range(-6, -2)))

func _generate_rotations() -> void:
	# Random rotation values
	for i in range(CACHE_SIZE):
		rotations.append(randf() * TAU)

func _generate_fade_times() -> void:
	# Pre-generated fade start times and durations - reduced for faster fading
	for i in range(CACHE_SIZE):
		var start = randf_range(0.5, 8.0)
		var duration = randf_range(0.2, 1.5)  # Reduced from 0.5-4.0 to 0.2-1.5
		fade_times.append(Vector2(start, duration))

func _generate_speeds() -> void:
	# Speed ranges for normal and dead enemies - increased for more explosive effect
	for i in range(CACHE_SIZE):
		speeds_normal.append(randf_range(720, 3000))  # Doubled from 360-1500 to 720-3000
		speeds_dead.append(randf_range(1080, 3000))  # Doubled from 540-1500 to 1080-3000

func _generate_drift_values() -> void:
	# Drift values for floating particles
	for i in range(CACHE_SIZE):
		drift_values.append(Vector2(randf_range(-25, 25), randf_range(-15, 15)))

# Public API methods with index-based access
static func get_scale(index: int) -> float:
	if instance and index >= 0 and index < instance.scale_values.size():
		return instance.scale_values[index]
	return 1.0

static func get_angle_offset(index: int) -> float:
	if instance and index >= 0 and index < instance.angle_offsets.size():
		return instance.angle_offsets[index]
	return 0.0

static func get_position_8(index: int) -> Vector2:
	if instance and index >= 0 and index < instance.positions_8.size():
		return instance.positions_8[index]
	return Vector2.ZERO

static func get_position_6(index: int) -> Vector2:
	if instance and index >= 0 and index < instance.positions_6.size():
		return instance.positions_6[index]
	return Vector2.ZERO

static func get_rotation(index: int) -> float:
	if instance and index >= 0 and index < instance.rotations.size():
		return instance.rotations[index]
	return 0.0

static func get_fade_times(index: int) -> Vector2:
	if instance and index >= 0 and index < instance.fade_times.size():
		return instance.fade_times[index]
	return Vector2(1.0, 1.0)

static func get_speed_normal(index: int) -> float:
	if instance and index >= 0 and index < instance.speeds_normal.size():
		return instance.speeds_normal[index]
	return 500.0

static func get_speed_dead(index: int) -> float:
	if instance and index >= 0 and index < instance.speeds_dead.size():
		return instance.speeds_dead[index]
	return 500.0

static func get_drift(index: int) -> Vector2:
	if instance and index >= 0 and index < instance.drift_values.size():
		return instance.drift_values[index]
	return Vector2.ZERO

# Helper method to get a random index for cache lookup
static func get_random_index() -> int:
	return randi() % CACHE_SIZE
