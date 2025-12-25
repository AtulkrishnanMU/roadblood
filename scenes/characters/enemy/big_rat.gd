extends "res://scenes/characters/enemy/base_enemy.gd"

class_name BigRat

func _ready():
	super._ready()
	targets_food = false  # Big rats target player instead of food
	SPEED = 200.0  # Much slower speed (decreased from 400)
	MAX_HEALTH = 20  # More health than basic_rat (10)
	DAMAGE = 25  # More damage than basic_rat (15)
	SCORE_VALUE = 200  # Big rats give more score than basic rats
	health = MAX_HEALTH
