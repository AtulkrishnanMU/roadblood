class_name PopupUtils
extends RefCounted

# Constant font size for all popups
const POPUP_FONT_SIZE = 30

# Clean floating popup method (now uses PopupManager)
static func spawn_floating_popup(character: Node2D, text: String, color: Color, offset: Vector2 = Vector2(0, -20), font_size: int = FontConfig.DEFAULT_POPUP_FONT_SIZE, height: float = 0.0) -> void:
	# Use PopupManager for object pooling
	PopupManager.spawn_floating_popup(character, text, color, offset, font_size, height)

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

# Custom popup with full control (now uses PopupManager)
static func spawn_custom_popup(character: Node2D, text: String, color: Color, offset: Vector2, font_size: int, duration: float = 1.0, float_distance: float = 40.0) -> void:
	spawn_floating_popup(character, text, color, offset, font_size, 0.0)
