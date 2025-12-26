extends Object
class_name AudioUtils

# Centralized audio management system
# - All audio should go through AudioUtils for consistency
# - Uses object pooling for one-shot sounds to optimize performance
# - Standardized pitch and volume ranges across the game
# - Supports both positioned (2D) and non-positioned audio

# Simple fixed-size object pool for audio players
static var _audio_pool: Array[AudioStreamPlayer2D] = []
static var _pool_initialized: bool = false
static var _FIXED_POOL_SIZE: int = 12  # Fixed pool size for optimal performance

static func play_random_pitch(audio, min_pitch: float = 0.9, max_pitch: float = 1.1) -> void:
	if audio == null:
		return
	audio.pitch_scale = randf_range(min_pitch, max_pitch)
	audio.play()

# Simple pool management with fixed size
static func _get_audio_player() -> AudioStreamPlayer2D:
	# Initialize pool if needed
	if not _pool_initialized:
		_initialize_pool()
	
	if _audio_pool.size() > 0:
		var audio_player = _audio_pool.pop_back()
		# Remove from current parent if it has one
		if audio_player.get_parent():
			audio_player.get_parent().remove_child(audio_player)
		return audio_player
	
	# Pool exhausted - create new player (overflow handling)
	var audio = AudioStreamPlayer2D.new()
	audio.finished.connect(_return_audio_player.bind(audio))
	return audio

static func _initialize_pool():
	# Pre-create fixed number of audio players
	for i in range(_FIXED_POOL_SIZE):
		var audio = AudioStreamPlayer2D.new()
		_audio_pool.append(audio)
	_pool_initialized = true

static func _return_audio_player(audio: AudioStreamPlayer2D):
	# Stop the audio and remove from parent before returning to pool
	audio.stop()
	if audio.get_parent():
		audio.get_parent().remove_child(audio)
	
	# Return to pool if under fixed size
	if _audio_pool.size() < _FIXED_POOL_SIZE:
		_audio_pool.append(audio)
	else:
		# Pool at capacity - free excess players
		audio.queue_free()


# Plays a one-shot sound at a specific position
static func play_positioned_sound(sound_stream: AudioStream, position: Vector2, min_pitch: float = 0.9, max_pitch: float = 1.1, volume_db: float = 0.0) -> void:
	if sound_stream == null:
		return
	var scene: Node = Engine.get_main_loop().current_scene
	if scene == null:
		return
	
	var audio := _get_audio_player()
	audio.stream = sound_stream
	audio.position = position
	audio.volume_db = volume_db  # Set custom volume
	scene.add_child(audio)
	play_random_pitch(audio, min_pitch, max_pitch)

# Plays running sound using existing audio player
static func play_running_sound(running_player: AudioStreamPlayer2D, running_sound: AudioStream) -> void:
	if running_sound == null or running_player == null:
		return
	if not running_player.playing:
		# Create a looping version of the audio stream
		var looping_stream = running_sound.duplicate()
		if looping_stream is AudioStreamMP3:
			looping_stream.loop = true
		elif looping_stream is AudioStreamWAV:
			looping_stream.loop = true
		elif looping_stream is AudioStreamOggVorbis:
			looping_stream.loop = true
		
		running_player.stream = looping_stream
		play_random_pitch(running_player, 0.9, 1.1)

# Stops running sound
static func stop_running_sound(running_player: AudioStreamPlayer2D) -> void:
	if running_player and running_player.playing:
		running_player.stop()

# Plays blood splat sound at position
static func play_blood_splat_sound(blood_splat_sound: AudioStream, position: Vector2) -> void:
	play_positioned_sound(blood_splat_sound, position, 0.8, 1.2)

# Plays death sound with random selection from array of sounds
static func play_death_sound(death_sounds: Array[AudioStream], position: Vector2) -> void:
	if death_sounds.is_empty():
		return
	
	# Randomly select one death sound from the array
	var sound_to_play = death_sounds[randi() % death_sounds.size()]
	
	# Create non-positional audio player for consistent full volume
	var scene: Node = Engine.get_main_loop().current_scene
	if scene == null:
		return
	
	var audio := AudioStreamPlayer.new()  # Non-positional for consistent volume
	audio.stream = sound_to_play
	audio.volume_db = -1.0  # Reduced volume for death sounds
	audio.pitch_scale = randf_range(1.4, 2.0)  # Keep the high pitch variation
	scene.add_child(audio)
	audio.play()
	
	# Remove after sound finishes
	audio.finished.connect(audio.queue_free)

# Plays hurt sound at position
static func play_hurt_sound(hurt_sound: AudioStream, position: Vector2) -> void:
	play_positioned_sound(hurt_sound, position, 0.9, 1.1)

# Simple pool statistics
static func get_pool_stats() -> Dictionary:
	return {
		"pool_size": _audio_pool.size(),
		"fixed_size": _FIXED_POOL_SIZE,
		"initialized": _pool_initialized
	}

# Simple pool cleanup - reset to fixed size
static func cleanup_pool():
	# Clear pool and reinitialize
	_audio_pool.clear()
	_pool_initialized = false
	_initialize_pool()
