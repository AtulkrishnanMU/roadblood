extends "res://scenes/characters/enemy/base_enemy.gd"

class_name BasicRat

func _ready():
	super._ready()
	targets_food = true  # Basic rats target food instead of player
	SPEED = 400.0  # Slower speed (decreased from 800)
	DAMAGE = 5  # Food damage per bite (reduced from 15)
	# Keep other default stats from base enemy
