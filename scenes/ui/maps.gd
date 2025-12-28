extends Control

# Preload utilities
const ButtonUtils = preload("res://scenes/utility-scripts/utils/button_utils.gd")
const FontConfig = preload("res://scenes/utility-scripts/utils/font_config.gd")

func _ready():
	# Apply font config to all buttons
	_apply_fonts_to_buttons()
	
	# Connect button signals
	$VBoxContainer/Map1Button.pressed.connect(_on_map1_pressed)
	$VBoxContainer/Map2Button.pressed.connect(_on_map2_pressed)
	$VBoxContainer/BackButton.pressed.connect(_on_back_pressed)
	
	# Add sound effects to all buttons (including back button)
	var buttons = [
		$VBoxContainer/Map1Button,
		$VBoxContainer/Map2Button,
		$VBoxContainer/BackButton
	]
	ButtonUtils.add_sound_effects_to_buttons(buttons, $AudioStreamPlayer)

func _on_map1_pressed():
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://scenes/ui/levels_map1.tscn")

func _on_map2_pressed():
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://scenes/ui/levels_map2.tscn")

func _on_back_pressed():
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _apply_fonts_to_buttons():
	# Apply FontConfig to all buttons for consistent styling
	var buttons = [
		$VBoxContainer/Map1Button,
		$VBoxContainer/Map2Button,
		$VBoxContainer/BackButton
	]
	for button in buttons:
		if button:
			FontConfig.apply_default_font_button(button)
