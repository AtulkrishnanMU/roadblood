extends "res://scenes/utility-scripts/utils/base_level.gd"

# Override the create_level_config method to provide Level 2 specific configuration
func create_level_config() -> Dictionary:
	return {
		"wave_duration": 60.0,
		"spawn_points": [
			Vector2(30, 30),
			Vector2(1200, 30),
			Vector2(30, 800),
			Vector2(1200, 800),
			Vector2(615, 30),
			Vector2(615, 800)
		],
		"enemy_pool": [
			preload("res://scenes/characters/enemy/basic_rat.tscn"),
			preload("res://scenes/characters/enemy/big_rat.tscn")
		],
		"waves": [
			{
				"spawn_rate": 2.0,
				"allowed_enemies": [
					preload("res://scenes/characters/enemy/basic_rat.tscn"),
					preload("res://scenes/characters/enemy/big_rat.tscn")
				],
				"max_enemies": 25
			},
			{
				"spawn_rate": 2.5,
				"allowed_enemies": [
					preload("res://scenes/characters/enemy/basic_rat.tscn"),
					preload("res://scenes/characters/enemy/big_rat.tscn")
				],
				"max_enemies": 30
			},
			{
				"spawn_rate": 3.0,
				"allowed_enemies": [
					preload("res://scenes/characters/enemy/basic_rat.tscn"),
					preload("res://scenes/characters/enemy/big_rat.tscn")
				],
				"max_enemies": 35
			},
			{
				"spawn_rate": 3.5,
				"allowed_enemies": [
					preload("res://scenes/characters/enemy/basic_rat.tscn"),
					preload("res://scenes/characters/enemy/big_rat.tscn")
				],
				"max_enemies": 40
			}
		]
	}
