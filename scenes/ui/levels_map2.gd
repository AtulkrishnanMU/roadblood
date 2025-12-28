extends Control

# Preload utilities
const ButtonUtils = preload("res://scenes/utility-scripts/utils/button_utils.gd")
const FontConfig = preload("res://scenes/utility-scripts/utils/font_config.gd")

func _ready():
	# Apply font config to all buttons
	_apply_fonts_to_buttons()
	
	# Connect button signals
	$VBoxContainer/Level1Button.pressed.connect(_on_level1_pressed)
	$VBoxContainer/Level2Button.pressed.connect(_on_level2_pressed)
	$VBoxContainer/BackButton.pressed.connect(_on_back_pressed)
	
	# Add sound effects to all buttons (including back button)
	var buttons = [
		$VBoxContainer/Level1Button,
		$VBoxContainer/Level2Button,
		$VBoxContainer/BackButton
	]
	ButtonUtils.add_sound_effects_to_buttons(buttons, $AudioStreamPlayer)

func _on_level1_pressed():
	await get_tree().create_timer(0.1).timeout
	# Load the actual level 1 scene - using template for now
	get_tree().change_scene_to_file("res://scenes/levels/level_template.tscn")

func _on_level2_pressed():
	await get_tree().create_timer(0.1).timeout
	# Load the actual level 2 scene - using template for now
	get_tree().change_scene_to_file("res://scenes/levels/level_template.tscn")

func _on_back_pressed():
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://scenes/ui/maps.tscn")

func _apply_fonts_to_buttons():
	# Apply FontConfig to all buttons for consistent styling
	var buttons = [
		$VBoxContainer/Level1Button,
		$VBoxContainer/Level2Button,
		$VBoxContainer/BackButton
	]
	for button in buttons:
		if button:
			FontConfig.apply_default_font_button(button)
