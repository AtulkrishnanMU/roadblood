extends Node
class_name UIStyleCacheNode

# Cache for style variations
static var style_cache: Dictionary = {}
static var cache_initialized = false

# Preload FontConfig for consistent font usage
const FontConfig = preload("res://scenes/utility-scripts/utils/font_config.gd")

# Style variation types
enum StyleType {
	HEALTH_BAR,
	SCORE_LABEL,
	COMBO_LABEL,
	BACKGROUND_PANEL,
	BUTTON_NORMAL,
	BUTTON_HOVER,
	BUTTON_PRESSED
}

# Initialize style cache with pre-created variations
static func initialize_cache():
	if cache_initialized:
		return
	
	# Create health bar styles
	_create_health_bar_styles()
	
	# Create label styles
	_create_label_styles()
	
	# Create panel styles
	_create_panel_styles()
	
	# Create button styles
	_create_button_styles()
	
	cache_initialized = true

# Create health bar style variations
static func _create_health_bar_styles():
	var health_styles = []
	
	# Custom colors for health bar states
	var high_health_color = Color(0.7411765, 0.8117647, 0.23137255, 1)  # BDCF3B
	var medium_health_color = Color(0.95686275, 0.9254902, 0.3647059, 1)  # F4EC5D
	var low_health_color = Color(0.8666667, 0.2470588, 0.0, 1)  # DD3F00
	
	# Different health bar styles for different states
	var colors = [
		low_health_color,           # 0 - Very low health (red)
		low_health_color.lerp(medium_health_color, 0.3),  # 1 - Low health
		medium_health_color,        # 2 - Medium health (yellow)
		medium_health_color.lerp(high_health_color, 0.5),   # 3 - Good health
		high_health_color            # 4 - High health (green)
	]
	
	for i in range(5):  # 5 different health states
		var style = StyleBoxFlat.new()
		style.bg_color = colors[i]
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = colors[i].darkened(0.3)  # Darker border
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		health_styles.append(style)
	
	style_cache[StyleType.HEALTH_BAR] = health_styles

# Create label style variations
static func _create_label_styles():
	# Score label using FontConfig
	var score_style = Label.new()
	FontConfig.apply_ui_font(score_style)
	score_style.add_theme_font_size_override("font_size", 24)
	score_style.add_theme_color_override("font_color", Color.WHITE)
	score_style.add_theme_color_override("font_shadow_color", Color.BLACK)
	score_style.add_theme_constant_override("shadow_offset_x", 1)
	score_style.add_theme_constant_override("shadow_offset_y", 1)
	style_cache[StyleType.SCORE_LABEL] = score_style
	
	# Combo label using FontConfig
	var combo_style = Label.new()
	FontConfig.apply_ui_font(combo_style)
	combo_style.add_theme_font_size_override("font_size", 32)
	combo_style.add_theme_color_override("font_color", Color.ORANGE)
	combo_style.add_theme_color_override("font_shadow_color", Color.BLACK)
	combo_style.add_theme_constant_override("shadow_offset_x", 2)
	combo_style.add_theme_constant_override("shadow_offset_y", 2)
	style_cache[StyleType.COMBO_LABEL] = combo_style

# Create panel style variations
static func _create_panel_styles():
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.5, 0.5, 0.5)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	style_cache[StyleType.BACKGROUND_PANEL] = panel_style

# Create button style variations
static func _create_button_styles():
	# Normal button
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.3, 0.3, 0.3)
	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.border_width_top = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = Color(0.6, 0.6, 0.6)
	normal_style.corner_radius_top_left = 4
	normal_style.corner_radius_top_right = 4
	normal_style.corner_radius_bottom_left = 4
	normal_style.corner_radius_bottom_right = 4
	style_cache[StyleType.BUTTON_NORMAL] = normal_style
	
	# Hover button
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.4, 0.4, 0.4)
	hover_style.border_width_left = 2
	hover_style.border_width_right = 2
	hover_style.border_width_top = 2
	hover_style.border_width_bottom = 2
	hover_style.border_color = Color(0.8, 0.8, 0.8)
	hover_style.corner_radius_top_left = 4
	hover_style.corner_radius_top_right = 4
	hover_style.corner_radius_bottom_left = 4
	hover_style.corner_radius_bottom_right = 4
	style_cache[StyleType.BUTTON_HOVER] = hover_style
	
	# Pressed button
	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.2, 0.2, 0.2)
	pressed_style.border_width_left = 2
	pressed_style.border_width_right = 2
	pressed_style.border_width_top = 2
	pressed_style.border_width_bottom = 2
	pressed_style.border_color = Color(0.4, 0.4, 0.4)
	pressed_style.corner_radius_top_left = 4
	pressed_style.corner_radius_top_right = 4
	pressed_style.corner_radius_bottom_left = 4
	pressed_style.corner_radius_bottom_right = 4
	style_cache[StyleType.BUTTON_PRESSED] = pressed_style

# Get cached style (returns a duplicate for safe modification)
static func get_style(style_type: StyleType, variant: int = 0):
	if not cache_initialized:
		initialize_cache()
	
	var styles = style_cache.get(style_type)
	if styles == null:
		return null
	
	if styles is Array:
		if variant < styles.size():
			return styles[variant].duplicate()
		else:
			return styles[0].duplicate()
	else:
		return styles.duplicate()

# Apply cached style to control
static func apply_style(control: Control, style_type: StyleType, variant: int = 0):
	var style = get_style(style_type, variant)
	if style == null:
		return
	
	match style_type:
		StyleType.HEALTH_BAR:
			if control is ProgressBar:
				control.add_theme_stylebox_override("fill", style)
		StyleType.SCORE_LABEL, StyleType.COMBO_LABEL:
			if control is Label:
				var label_style = style as Label
				control.add_theme_font_size_override("font_size", label_style.get_theme_font_size("font_size"))
				control.add_theme_color_override("font_color", label_style.get_theme_color("font_color"))
				control.add_theme_color_override("font_shadow_color", label_style.get_theme_color("font_shadow_color"))
				control.add_theme_constant_override("shadow_offset_x", label_style.get_theme_constant("shadow_offset_x"))
				control.add_theme_constant_override("shadow_offset_y", label_style.get_theme_constant("shadow_offset_y"))
		StyleType.BACKGROUND_PANEL:
			if control is Panel:
				control.add_theme_stylebox_override("panel", style)
		StyleType.BUTTON_NORMAL, StyleType.BUTTON_HOVER, StyleType.BUTTON_PRESSED:
			if control is Button:
				match style_type:
					StyleType.BUTTON_NORMAL:
						control.add_theme_stylebox_override("normal", style)
					StyleType.BUTTON_HOVER:
						control.add_theme_stylebox_override("hover", style)
					StyleType.BUTTON_PRESSED:
						control.add_theme_stylebox_override("pressed", style)

# Get health bar style based on health percentage
static func get_health_bar_style(health_percent: float):
	if not cache_initialized:
		initialize_cache()
	
	var health_styles = style_cache[StyleType.HEALTH_BAR]
	var index = int((1.0 - health_percent) * 4)  # 0-4 based on health
	index = clamp(index, 0, 4)
	return health_styles[index].duplicate()

# Clear cache (useful for testing)
static func clear_cache():
	style_cache.clear()
	cache_initialized = false
