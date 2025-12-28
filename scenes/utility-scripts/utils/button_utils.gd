extends Node
class_name ButtonUtility

# Sound effect paths
const HOVER_SOUND_PATH = "res://sounds/menu/menu-hover.mp3"
const SELECT_SOUND_PATH = "res://sounds/menu/menu-select.mp3"

# Static method to add sound effects to a button
static func add_sound_effects(button: Button, audio_player: AudioStreamPlayer):
	if not button or not audio_player:
		print("ButtonUtils: Missing button or audio_player")
		return
	
	# Load sound effects
	var hover_sound = load(HOVER_SOUND_PATH)
	var select_sound = load(SELECT_SOUND_PATH)
	
	print("ButtonUtils: Loaded sounds - hover: ", hover_sound != null, " select: ", select_sound != null)
	
	# Connect hover signal
	button.mouse_entered.connect(func():
		print("ButtonUtils: Hover triggered for: ", button.name)
		if hover_sound and audio_player.is_inside_tree():
			audio_player.stream = hover_sound
			audio_player.play()
			print("ButtonUtils: Playing hover sound")
		else:
			print("ButtonUtils: Cannot play hover - sound: ", hover_sound != null, " in_tree: ", audio_player.is_inside_tree())
	)
	
	# Connect pressed signal
	button.pressed.connect(func():
		print("ButtonUtils: Press triggered for: ", button.name)
		if select_sound and audio_player.is_inside_tree():
			audio_player.stream = select_sound
			audio_player.play()
			print("ButtonUtils: Playing select sound")
		else:
			print("ButtonUtils: Cannot play select - sound: ", select_sound != null, " in_tree: ", audio_player.is_inside_tree())
	)

# Static method to add sound effects to multiple buttons
static func add_sound_effects_to_buttons(buttons: Array, audio_player: AudioStreamPlayer):
	print("ButtonUtils: Setting up sounds for ", buttons.size(), " buttons")
	for button in buttons:
		if button is Button:
			add_sound_effects(button, audio_player)
		else:
			print("ButtonUtils: Skipping non-button: ", button)
