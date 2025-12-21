extends Node

# Singleton-like time manipulation utility
static var instance: Node

const SLOW_TIME_DURATION = 0.3  # seconds for slow time effect
const SLOW_TIME_SCALE = 0.2  # time scale during slow motion (20% speed)
const SLOW_TIME_CHANCE = 0.3  # 30% chance to trigger slow time on enemy kill

var slow_time_timer = 0.0
var is_slow_time_active = false
var original_time_scale = 1.0
var original_audio_pitch = 1.0

func _ready():
	# Set up singleton reference
	instance = self
	original_time_scale = Engine.time_scale
	add_to_group("time_utils")  # Add to group for player to find

func _process(delta):
	if is_slow_time_active:
		slow_time_timer -= delta
		if slow_time_timer <= 0:
			_disable_slow_time()

static func trigger_slow_time():
	if instance and not instance.is_slow_time_active and randf() <= SLOW_TIME_CHANCE:
		instance._enable_slow_time()

func _enable_slow_time():
	is_slow_time_active = true
	slow_time_timer = SLOW_TIME_DURATION
	Engine.time_scale = SLOW_TIME_SCALE
	
	# Slow down all audio in the scene
	_apply_audio_slowdown(SLOW_TIME_SCALE)

func _disable_slow_time():
	is_slow_time_active = false
	Engine.time_scale = original_time_scale
	
	# Restore normal audio speed
	_apply_audio_slowdown(1.0)

func _apply_audio_slowdown(pitch_scale: float):
	# Apply pitch scale to all AudioStreamPlayer nodes in the scene
	var audio_players = get_tree().get_nodes_in_group("audio")
	for audio_player in audio_players:
		if audio_player.has_method("set_pitch_scale"):
			audio_player.pitch_scale = pitch_scale
	
	# For Godot 4, we need to use AudioEffectPitchShift on the master bus
	var master_bus_index = AudioServer.get_bus_index("Master")
	var bus_effect = null
	
	# Check if there are any effects on the bus
	if AudioServer.get_bus_effect_count(master_bus_index) > 0:
		bus_effect = AudioServer.get_bus_effect(master_bus_index, 0)
	
	# If no pitch shift effect exists, add one
	if not bus_effect or not bus_effect is AudioEffectPitchShift:
		var pitch_effect = AudioEffectPitchShift.new()
		AudioServer.add_bus_effect(master_bus_index, pitch_effect, 0)
		bus_effect = pitch_effect
	
	# Set the pitch scale
	if bus_effect is AudioEffectPitchShift:
		bus_effect.pitch_scale = pitch_scale
