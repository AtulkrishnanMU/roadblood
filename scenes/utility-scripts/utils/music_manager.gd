extends Node

class_name MusicManager

const BG_TRACK = preload("res://music/bg-track.mp3")

var music_player: AudioStreamPlayer
var is_playing = false

func _ready():
	# Create audio player for background music
	music_player = AudioStreamPlayer.new()
	
	# Create a mutable copy of the audio stream for looping
	var bg_stream = BG_TRACK.duplicate()
	if bg_stream is AudioStreamMP3:
		bg_stream.loop = true
	
	music_player.stream = bg_stream
	music_player.volume_db = 0.0  # Full volume for background music
	music_player.autoplay = false  # We'll control playback manually
	
	add_child(music_player)
	
	# Start playing background music
	play_background_music()

func play_background_music():
	if not is_playing and music_player:
		music_player.play()
		is_playing = true
		print("Background music started")

func stop_background_music():
	if is_playing and music_player:
		music_player.stop()
		is_playing = false
		print("Background music stopped")

func set_volume(volume_db: float):
	if music_player:
		music_player.volume_db = volume_db

func fade_out(duration: float = 2.0):
	if music_player and is_playing:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80.0, duration)
		tween.tween_callback(stop_background_music)

func fade_in(duration: float = 2.0, target_volume: float = 0.0):
	if music_player and not is_playing:
		music_player.volume_db = -80.0  # Start silent
		play_background_music()
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", target_volume, duration)
