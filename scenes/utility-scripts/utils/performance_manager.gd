extends Node
class_name PerformanceManager

# Central performance management system for handling 1000+ enemies
# Monitors performance and adjusts quality settings dynamically

signal performance_critical(fps: float)
signal performance_warning(fps: float)

# Performance thresholds
const CRITICAL_FPS = 30.0
const WARNING_FPS = 45.0
const TARGET_FPS = 60.0

# Performance tracking
var fps_history: Array[float] = []
var fps_history_size: int = 60  # Track last 60 frames
var current_fps: float = 60.0
var frame_time_accumulator: float = 0.0
var frame_count: int = 0

# Dynamic quality settings
var current_quality_level: int = 3  # 0=Low, 1=Medium, 2=High, 3=Ultra
var quality_update_timer: float = 0.0
var quality_update_interval: float = 2.0  # Check quality every 2 seconds

# Performance metrics
var enemy_count: int = 0
var blood_effect_count: int = 0
var audio_player_count: int = 0

# Singleton instance
static var instance: PerformanceManager

func _ready():
	# Set up singleton
	if instance == null:
		instance = self
	else:
		queue_free()
		return

func _process(delta):
	# Track FPS
	frame_time_accumulator += delta
	frame_count += 1
	
	# Update FPS every second
	if frame_time_accumulator >= 1.0:
		current_fps = frame_count / frame_time_accumulator
		fps_history.append(current_fps)
		
		# Keep history size limited
		if fps_history.size() > fps_history_size:
			fps_history.pop_front()
		
		frame_time_accumulator = 0.0
		frame_count = 0
		
		# Check performance and adjust quality
		_check_performance_and_adjust_quality()
	
	# Update quality settings periodically
	quality_update_timer += delta
	if quality_update_timer >= quality_update_interval:
		quality_update_timer = 0.0
		_update_quality_settings()
	
	# Update blood effects pool tracking
	_update_blood_effects_tracking(delta)

func _check_performance_and_adjust_quality():
	if current_fps < CRITICAL_FPS:
		emit_signal("performance_critical", current_fps)
		_emergency_performance_mode()
	elif current_fps < WARNING_FPS:
		emit_signal("performance_warning", current_fps)
		_reduce_quality()

func _emergency_performance_mode():
	# Emergency mode for critical performance
	current_quality_level = 0  # Lowest quality
	_apply_quality_settings_immediately()

func _reduce_quality():
	if current_quality_level > 0:
		current_quality_level -= 1
		print("PerformanceManager: Reducing quality to level ", current_quality_level, " (FPS: ", current_fps, ")")

func _increase_quality():
	if current_quality_level < 3 and current_fps >= TARGET_FPS + 10:
		current_quality_level += 1
		print("PerformanceManager: Increasing quality to level ", current_quality_level, " (FPS: ", current_fps, ")")

func _apply_quality_settings_immediately():
	match current_quality_level:
		0:  # Low - Emergency mode
			_apply_low_quality_settings()
		1:  # Medium
			_apply_medium_quality_settings()
		2:  # High
			_apply_high_quality_settings()
		3:  # Ultra
			_apply_ultra_quality_settings()

func _update_quality_settings():
	# Gradually increase quality if performance is good
	if current_fps >= TARGET_FPS + 10:
		_increase_quality()
	
	_apply_quality_settings_immediately()

func _apply_low_quality_settings():
	# Emergency low quality settings
	Engine.max_fps = 45  # Cap FPS to reduce load
	
	# Reduce blood effects significantly
	if get_tree().get_first_node_in_group("blood_effects_manager"):
		# Force reduced blood effects
		pass
	
	# Reduce audio pool
	if AudioUtils._FIXED_POOL_SIZE > 20:
		AudioUtils._FIXED_POOL_SIZE = 20

func _apply_medium_quality_settings():
	Engine.max_fps = 60
	if AudioUtils._FIXED_POOL_SIZE > 30:
		AudioUtils._FIXED_POOL_SIZE = 30

func _apply_high_quality_settings():
	Engine.max_fps = 60
	if AudioUtils._FIXED_POOL_SIZE > 40:
		AudioUtils._FIXED_POOL_SIZE = 40

func _apply_ultra_quality_settings():
	Engine.max_fps = 0  # Unlimited FPS
	AudioUtils._FIXED_POOL_SIZE = 50

func _update_blood_effects_tracking(delta):
	# Update blood effects pool tracking
	if has_method("update_blood_effects_tracking"):
		BloodEffectsPool.update_mass_death_tracking(delta)

func get_performance_stats() -> Dictionary:
	return {
		"current_fps": current_fps,
		"quality_level": current_quality_level,
		"enemy_count": enemy_count,
		"blood_effect_count": blood_effect_count,
		"audio_player_count": audio_player_count,
		"fps_history": fps_history.duplicate()
	}

func force_quality_level(level: int):
	current_quality_level = clamp(level, 0, 3)
	_apply_quality_settings_immediately()

func reset_performance_tracking():
	fps_history.clear()
	frame_time_accumulator = 0.0
	frame_count = 0
	current_quality_level = 3
	quality_update_timer = 0.0
