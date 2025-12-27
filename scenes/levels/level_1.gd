extends "res://scenes/utility-scripts/utils/base_level.gd"

# Override the create_level_config method to provide Level 1 specific configuration
func create_level_config() -> Dictionary:
	return {
		"wave_duration": 60.0,
		"spawn_points": [
			Vector2(50, 50),
			Vector2(1100, 50),
			Vector2(50, 750),
			Vector2(1100, 750)
		],
		"enemy_pool": [
			preload("res://scenes/characters/enemy/basic_rat.tscn"),
			preload("res://scenes/characters/enemy/big_rat.tscn")
		],
		"waves": [
			{
				"spawn_rate": 1.0,
				"allowed_enemies": [preload("res://scenes/characters/enemy/basic_rat.tscn")],
				"max_enemies": 15,
				"spawn_range": [1, 2]  # Start with 1, increase to 2 by wave end
			},
			{
				"spawn_rate": 1.5,
				"allowed_enemies": [
					preload("res://scenes/characters/enemy/basic_rat.tscn"),
					preload("res://scenes/characters/enemy/big_rat.tscn")
				],
				"max_enemies": 20,
				"spawn_range": [1, 3]  # Start with 1, increase to 3 by wave end
			},
			{
				"spawn_rate": 2.0,
				"allowed_enemies": [
					preload("res://scenes/characters/enemy/basic_rat.tscn"),
					preload("res://scenes/characters/enemy/big_rat.tscn")
				],
				"max_enemies": 25,
				"spawn_range": [2, 4]  # Start with 2, increase to 4 by wave end
			},
			{
				"spawn_rate": 2.5,
				"allowed_enemies": [
					preload("res://scenes/characters/enemy/basic_rat.tscn"),
					preload("res://scenes/characters/enemy/big_rat.tscn")
				],
				"max_enemies": 30,
				"spawn_range": [2, 5]  # Start with 2, increase to 5 by wave end
			}
		]
	}
