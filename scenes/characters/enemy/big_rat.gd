extends "res://scenes/characters/enemy/base_enemy.gd"

class_name BigRat

func _ready():
	# Set stats BEFORE calling super._ready() so health component uses correct values
	targets_food = false  # Big rats target player instead of food
	SPEED = 200.0  # Much slower speed (decreased from 400)
	MAX_HEALTH = 20  # More health than basic_rat (10)
	DAMAGE = 10  # Reduced damage to match basic rat
	SCORE_VALUE = 200  # Big rats give more score than basic rats
	
	super._ready()  # Call after setting stats so health component uses MAX_HEALTH = 20
