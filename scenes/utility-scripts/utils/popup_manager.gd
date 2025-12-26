extends Node

# Object pool for popup nodes
var popup_pool: Array[Node2D] = []
var label_pool: Array[Label] = []
var max_pool_size: int = 20
var active_popups: Array[Node2D] = []

# Singleton instance
static var instance

func _ready():
	# Set up singleton
	if instance == null:
		instance = self
	else:
		queue_free()  # Remove duplicate instances
	
	# Add to group for easy access
	add_to_group("popup_manager")

# Get or create a popup from pool
func get_pooled_popup() -> Node2D:
	if popup_pool.size() > 0:
		var popup = popup_pool.pop_back()
		popup.visible = true
		# Ensure popup is properly removed from any parent
		if popup.get_parent():
			popup.get_parent().remove_child(popup)
		return popup
	
	# Create new popup if pool is empty
	var popup = Node2D.new()
	return popup

# Get or create a label from pool
func get_pooled_label() -> Label:
	if label_pool.size() > 0:
		var label = label_pool.pop_back()
		label.visible = true
		# Ensure label is properly removed from any parent
		if label.get_parent():
			label.get_parent().remove_child(label)
		return label
	
	# Create new label if pool is empty
	var label = Label.new()
	return label

# Return popup to pool
func return_popup(popup: Node2D):
	if popup_pool.size() < max_pool_size:
		# Remove all children first
		for child in popup.get_children():
			if child is Label:
				return_label(child)
			else:
				child.queue_free()
		
		popup.visible = false
		popup.get_parent().remove_child(popup)
		popup_pool.append(popup)
	else:
		popup.queue_free()

# Return label to pool
func return_label(label: Label):
	if label_pool.size() < max_pool_size:
		label.visible = false
		if label.get_parent():
			label.get_parent().remove_child(label)
		label_pool.append(label)
	else:
		label.queue_free()

# Spawn floating popup using pooled objects
func spawn_floating_popup(character: Node2D, text: String, color: Color, offset: Vector2 = Vector2(0, -20), font_size: int = 30, height: float = 0.0) -> void:
	var scene := character.get_tree().current_scene
	if scene == null:
		return

	var popup_root := get_pooled_popup()
	popup_root.position = (character.global_position + offset + Vector2(0, -height)).round()
	scene.add_child(popup_root)
	active_popups.append(popup_root)

	var label := get_pooled_label()
	label.text = text
	label.modulate = color
	FontConfig.apply_popup_font_with_size(label, font_size)

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
	tween.finished.connect(_cleanup_popup.bind(popup_root))

# Cleanup popup and return to pool
func _cleanup_popup(popup: Node2D):
	active_popups.erase(popup)
	return_popup(popup)

# Spawn combo popup (persistent)
func spawn_combo_popup(character: Node2D, combo_streak: int) -> Node2D:
	var scene := character.get_tree().current_scene
	if scene == null:
		return null

	var popup_root := get_pooled_popup()
	popup_root.position = (character.global_position + Vector2(0, -140)).round()
	scene.add_child(popup_root)

	var label := get_pooled_label()
	label.text = "x" + str(combo_streak)
	label.modulate = Color.ORANGE
	FontConfig.apply_popup_font_with_size(label, 100)

	popup_root.add_child(label)
	return popup_root

# Update existing combo popup
func update_combo_popup(popup: Node2D, character: Node2D, combo_streak: int):
	if popup == null:
		return
	
	popup.position = (character.global_position + Vector2(0, -140)).round()
	
	var label = popup.get_child(0) if popup.get_child_count() > 0 else null
	if label and label is Label:
		label.text = "x" + str(combo_streak)

# Fade out and cleanup combo popup
func fade_out_combo_popup(popup: Node2D):
	if popup == null:
		return
	
	var label = popup.get_child(0) if popup.get_child_count() > 0 else null
	if label and label is Label:
		var tween = get_tree().create_tween()
		tween.tween_property(label, "modulate:a", 0.0, 0.5)
		tween.tween_callback(_cleanup_popup.bind(popup))

# Cleanup all active popups (useful for scene changes)
func cleanup_all_popups():
	for popup in active_popups.duplicate():
		_cleanup_popup(popup)
