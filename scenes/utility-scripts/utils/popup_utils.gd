class_name PopupUtils
extends RefCounted

# Constant font size for all popups
const POPUP_FONT_SIZE = 30

# Clean floating popup method (similar to cash popup)
static func spawn_floating_popup(character: Node2D, text: String, color: Color, offset: Vector2 = Vector2(0, -20), font_size: int = FontConfig.DEFAULT_POPUP_FONT_SIZE, height: float = 0.0) -> void:
	var scene := character.get_tree().current_scene
	if scene == null:
		return

	var popup_root := Node2D.new()
	# Use pixel-perfect positioning to prevent blurriness
	# Add height offset to prevent overlapping popups
	popup_root.position = (character.global_position + offset + Vector2(0, -height)).round()
	scene.add_child(popup_root)

	var label := Label.new()
	label.text = text
	label.modulate = color
	# Apply popup font (no outlines) with custom size
	FontConfig.apply_popup_font_with_size(label, font_size)
	print("Popup font size set to: ", font_size)

	popup_root.add_child(label)

	var tween := scene.get_tree().create_tween()
	
	# Check if this is an HP popup (contains "HP" text)
	var is_hp_popup = "HP" in text
	
	if is_hp_popup:
		# Add flicker effect for HP popups
		var flicker_tween := scene.get_tree().create_tween()
		flicker_tween.set_loops(3)  # Flicker 3 times
		flicker_tween.tween_property(label, "modulate:a", 0.3, 0.1)  # Fade to 30% opacity
		flicker_tween.tween_property(label, "modulate:a", 1.0, 0.1)  # Back to full opacity
	
	# Popup: float up and fade over ~1.0 seconds
	tween.tween_property(popup_root, "position:y", popup_root.position.y - 40.0, 1.0)
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	tween.finished.connect(popup_root.queue_free)

# Score popup specific function
static func spawn_score_popup(character: Node2D, score: int) -> void:
	spawn_floating_popup(character, "+" + str(score), Color.YELLOW, Vector2(0, -50), 64)

# Health popup specific function
static func spawn_health_popup(character: Node2D, health: int) -> void:
	spawn_floating_popup(character, "+" + str(health) + " HP", Color.GREEN, Vector2(0, -30), POPUP_FONT_SIZE)

# Combo popup specific function
static func spawn_combo_popup(character: Node2D, combo_text: String) -> void:
	spawn_floating_popup(character, combo_text, Color.ORANGE, Vector2(0, -100), 52)

# Milestone popup specific function
static func spawn_milestone_popup(character: Node2D, score: int) -> void:
	spawn_floating_popup(character, "MILESTONE! +" + str(score), Color.GOLD, Vector2(0, -90), POPUP_FONT_SIZE)

# Damage popup specific function
static func spawn_damage_popup(character: Node2D, damage: int) -> void:
	spawn_floating_popup(character, "-" + str(damage), Color.RED, Vector2(0, -40), POPUP_FONT_SIZE)

# Custom popup with full control
static func spawn_custom_popup(character: Node2D, text: String, color: Color, offset: Vector2, font_size: int, duration: float = 1.0, float_distance: float = 40.0) -> void:
	var scene := character.get_tree().current_scene
	if scene == null:
		return

	var popup_root := Node2D.new()
	popup_root.position = (character.global_position + offset).round()
	scene.add_child(popup_root)

	var label := Label.new()
	label.text = text
	label.modulate = color
	FontConfig.apply_popup_font(label)
	if font_size != 20:
		label.add_theme_font_size_override("font_size", font_size)

	popup_root.add_child(label)

	var tween := scene.get_tree().create_tween()
	tween.tween_property(popup_root, "position:y", popup_root.position.y - float_distance, duration)
	tween.tween_property(label, "modulate:a", 0.0, duration)
	tween.finished.connect(popup_root.queue_free)
