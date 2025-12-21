extends Node2D

var player: CharacterBody2D
var health_bar: ProgressBar
var combo_text_label: Label
var combo_total_label: Label

func _ready():
	# Find the player
	player = get_tree().get_first_node_in_group("player")
	
	# Find UI elements
	health_bar = get_node_or_null("UI/HealthBar")
	if health_bar:
		combo_text_label = health_bar.get_node_or_null("ComboTextLabel")
		combo_total_label = health_bar.get_node_or_null("ComboTotalLabel")
	
	# Connect player signals
	if player and player.has_signal("combo_streak_changed"):
		player.combo_streak_changed.connect(_on_combo_streak_changed)

func _on_combo_streak_changed(current: int) -> void:
	if current > 0:
		# Update combo text label
		if combo_text_label:
			combo_text_label.text = str(current) + " COMBO"
			combo_text_label.visible = true
			_fade_in_combo_element(combo_text_label)
		
		# Update combo total label with calculated HP
		if combo_total_label:
			var total_hp = current * (current + 1) / 2
			combo_total_label.text = "HP: +" + str(total_hp)
			combo_total_label.visible = true
			_fade_in_combo_element(combo_total_label)
	else:
		# Hide combo labels when combo ends
		if combo_text_label:
			combo_text_label.visible = false
		if combo_total_label:
			combo_total_label.visible = false

func _fade_in_combo_element(element: Label) -> void:
	# Simple fade-in animation
	element.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(element, "modulate:a", 1.0, 0.3)
