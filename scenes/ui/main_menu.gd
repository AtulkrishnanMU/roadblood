extends Control

# Preload utilities
const ButtonUtils = preload("res://scenes/utility-scripts/utils/button_utils.gd")
const FontConfig = preload("res://scenes/utility-scripts/utils/font_config.gd")

func _ready():
	# Apply font config to all buttons
	_apply_fonts_to_buttons()
	
	# Connect button signals
	$VBoxContainer/PlayButton.pressed.connect(_on_play_pressed)
	$VBoxContainer/CharactersButton.pressed.connect(_on_characters_pressed)
	$VBoxContainer/SoundButton.pressed.connect(_on_sound_pressed)
	$VBoxContainer/CreditsButton.pressed.connect(_on_credits_pressed)
	$VBoxContainer/ExitButton.pressed.connect(_on_exit_pressed)
	
	# Add sound effects to all buttons
	var buttons = [
		$VBoxContainer/PlayButton,
		$VBoxContainer/CharactersButton,
		$VBoxContainer/SoundButton,
		$VBoxContainer/CreditsButton,
		$VBoxContainer/ExitButton
	]
	ButtonUtils.add_sound_effects_to_buttons(buttons, $AudioStreamPlayer)

func _on_play_pressed():
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://scenes/ui/maps.tscn")

func _on_characters_pressed():
	# Placeholder - no functionality for now
	print("Characters button pressed (placeholder)")

func _on_sound_pressed():
	# Placeholder - no functionality for now
	print("Sound button pressed (placeholder)")

func _on_credits_pressed():
	# Placeholder - no functionality for now
	print("Credits button pressed (placeholder)")

func _on_exit_pressed():
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()

func _apply_fonts_to_buttons():
	# Apply FontConfig to all buttons for consistent styling
	var buttons = [
		$VBoxContainer/PlayButton,
		$VBoxContainer/CharactersButton,
		$VBoxContainer/SoundButton,
		$VBoxContainer/CreditsButton,
		$VBoxContainer/ExitButton
	]
	for button in buttons:
		if button:
			FontConfig.apply_default_font_button(button)
