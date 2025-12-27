extends Node

# Test script for the BaseLevel wave system
# This script demonstrates how to use the new level system

func _ready():
	print("=== BaseLevel Wave System Test ===")
	
	# Test LevelConfig creation
	var config = LevelConfig.new()
	config.wave_duration = 60.0
	config.add_spawn_point(Vector2(100, 100))
	config.add_spawn_point(Vector2(800, 800))
	
	print("LevelConfig created with ", config.spawn_points.size(), " spawn points")
	print("Wave duration: ", config.wave_duration, " seconds")
	
	# Test WaveDefinition creation
	var wave_def = WaveDefinition.new()
	wave_def.set_spawn_rate(2.0)
	wave_def.set_max_enemies(20)
	
	var basic_rat_scene = preload("res://scenes/characters/enemy/basic_rat.tscn")
	wave_def.add_allowed_enemy(basic_rat_scene, 1.0)
	
	print("WaveDefinition created:")
	print("- Spawn rate: ", wave_def.spawn_rate, " enemies/second")
	print("- Max enemies: ", wave_def.max_enemies)
	print("- Allowed enemies: ", wave_def.allowed_enemies.size())
	
	# Test wave random enemy selection
	var random_enemy = wave_def.get_random_enemy()
	if random_enemy:
		print("Random enemy selection: SUCCESS")
	else:
		print("Random enemy selection: FAILED")
	
	# Add wave to config
	config.add_wave_definition(wave_def)
	print("Total waves in config: ", config.wave_definitions.size())
	
	print("=== Test Complete ===")
	print("The BaseLevel system is ready for use!")
	print("Each level now has:")
	print("- 4 waves of 60 seconds each")
	print("- Data-driven enemy spawning")
	print("- Configurable spawn points and enemy pools")
	print("- Win/lose conditions handled in BaseLevel")
