extends Control

# Preload UI style cache
const UIStyleCache = preload("res://scenes/utility-scripts/utils/ui_style_cache.gd")

const HEALTH_HIGH_COLOR = Color(0.7411765, 0.8117647, 0.23137255, 1)  # BDCF3B - Green for high health (>50%)
const HEALTH_MEDIUM_COLOR = Color(0.95686275, 0.9254902, 0.3647059, 1)  # F4EC5D - Yellow for medium health (<50%)
const HEALTH_LOW_COLOR = Color(0.8666667, 0.2470588, 0.0, 1)  # DD3F00 - Red for low health (<20%)
const HEALTH_HIGH_OUTLINE = Color(0.5411765, 0.6117647, 0.03137255, 1)  # Darker BDCF3B outline
const HEALTH_MEDIUM_OUTLINE = Color(0.75686275, 0.7254902, 0.1647059, 1)  # Darker F4EC5D outline
const HEALTH_LOW_OUTLINE = Color(0.6666667, 0.0470588, 0.0, 1)  # Darker DD3F00 outline
const HEALTH_MEDIUM_THRESHOLD = 0.5  # Below this percentage = yellow
const HEALTH_LOW_THRESHOLD = 0.2   # Below this percentage = red
const TRANSITION_DURATION = 0.5  # Duration for smooth transitions

var health_tween: Tween
var health_label: Label
var kill_counter_label: Label
var score_label: Label
var total_kills: int = 0
var total_score: int = 0
var best_combo_streak: int = 0

# Game over screen variables
var game_over_panel: Panel
var game_over_title: Label
var game_over_score: Label
var game_over_kills: Label
var game_over_combo: Label
var game_over_restart_button: Button

# Wave system UI elements
var wave_label: Label
var wave_timer_label: Label
var current_wave: int = 0
var wave_time_remaining: float = 0.0

func _ready():
	# Initialize UI style cache
	UIStyleCache.initialize_cache()
	
	# Create and setup UI event manager
	var ui_event_manager_script = preload("res://scenes/utility-scripts/utils/ui_event_manager.gd")
	var ui_event_manager = ui_event_manager_script.new()
	add_child(ui_event_manager)
	ui_event_manager.add_to_group("ui_event_manager")
	
	# Setup UI event manager connections
	ui_event_manager.setup(self)
	
	# Create game over screen
	_create_game_over_screen()
	
	# Find the health bar and labels
	var health_bar = get_node_or_null("HealthBar")
	if health_bar:
		health_bar.show_percentage = false
		health_label = health_bar.get_node_or_null("HealthLabel")
		# Apply default font to health label
		if health_label:
			FontConfig.apply_ui_font(health_label)
		
		# Set initial health bar color to high health color
		_update_fill_color(HEALTH_HIGH_COLOR)
		_update_outline_color(HEALTH_HIGH_OUTLINE)
	
	# Find other labels
	kill_counter_label = get_node_or_null("HealthBar/KillCounterLabel")
	score_label = get_node_or_null("ScoreLabel")
	
	# Find wave UI elements from the scene
	wave_label = get_node_or_null("WaveLabel")
	wave_timer_label = get_node_or_null("WaveTimerLabel")
	
	# Apply font config and styling to wave labels
	if wave_label:
		FontConfig.apply_ui_font(wave_label)
		wave_label.add_theme_font_size_override("font_size", 32)
		wave_label.add_theme_color_override("font_color", Color.YELLOW)
		wave_label.visible = false  # Initially hidden
	
	if wave_timer_label:
		FontConfig.apply_ui_font(wave_timer_label)
		wave_timer_label.add_theme_font_size_override("font_size", 24)
		wave_timer_label.add_theme_color_override("font_color", Color.WHITE)
		wave_timer_label.visible = false  # Initially hidden
	
	# Apply font config first, then cached styles to UI labels
	if kill_counter_label:
		FontConfig.apply_ui_font(kill_counter_label)
		UIStyleCache.apply_style(kill_counter_label, UIStyleCache.StyleType.SCORE_LABEL)
	if score_label:
		FontConfig.apply_ui_font(score_label)
		UIStyleCache.apply_style(score_label, UIStyleCache.StyleType.SCORE_LABEL)
	
	# Initialize displays
	update_kill_counter(0)
	update_score(0)
	
	# Add to ui group for enemy spawner communication
	add_to_group("ui")

func _process(delta):
	# Update wave timer if active
	if wave_time_remaining > 0.0:
		wave_time_remaining -= delta
		if wave_time_remaining < 0.0:
			wave_time_remaining = 0.0
		_update_wave_timer_display()

func _update_wave_timer_display():
	if wave_timer_label:
		var minutes = int(wave_time_remaining) / 60
		var seconds = int(wave_time_remaining) % 60
		var milliseconds = int((wave_time_remaining - int(wave_time_remaining)) * 100)
		wave_timer_label.text = "%02d:%02d.%02d" % [minutes, seconds, milliseconds]

# Wave system functions
func show_wave_start(wave_number: int, duration: float):
	current_wave = wave_number
	wave_time_remaining = duration
	
	if wave_label:
		wave_label.text = "WAVE %d" % wave_number
		wave_label.visible = true
	
	if wave_timer_label:
		wave_timer_label.visible = true
	
	_update_wave_timer_display()

func hide_wave_ui():
	if wave_label:
		wave_label.visible = false
	if wave_timer_label:
		wave_timer_label.visible = false
	
	current_wave = 0
	wave_time_remaining = 0.0

func update_health(current: int, max_health: int):
	var health_bar = get_node_or_null("HealthBar")
	if health_bar:
		health_bar.max_value = max_health
		
		# Update health label text
		if health_label:
			health_label.text = str(current) + "/" + str(max_health) + " HP"
		
		# Create smooth transition
		if health_tween and health_tween.is_valid():
			health_tween.kill()
		
		health_tween = create_tween()
		health_tween.set_ease(Tween.EASE_IN_OUT)
		health_tween.set_trans(Tween.TRANS_SINE)
		health_tween.tween_property(health_bar, "value", current, TRANSITION_DURATION)
		
		_update_color(current, max_health)

func _update_color(current: int, max_health: int):
	var health_bar = get_node_or_null("HealthBar")
	if not health_bar:
		return
		
	var health_percentage = float(current) / float(max_health)
	var target_color = HEALTH_HIGH_COLOR
	var target_outline = HEALTH_HIGH_OUTLINE
	
	if health_percentage <= HEALTH_LOW_THRESHOLD:
		target_color = HEALTH_LOW_COLOR
		target_outline = HEALTH_LOW_OUTLINE
	elif health_percentage <= HEALTH_MEDIUM_THRESHOLD:
		target_color = HEALTH_MEDIUM_COLOR
		target_outline = HEALTH_MEDIUM_OUTLINE
	
	# Smooth color transition for both fill and outline
	if health_tween and health_tween.is_valid():
		health_tween.parallel().tween_method(_update_fill_color, health_bar.get_theme_stylebox("fill").bg_color, target_color, TRANSITION_DURATION)
		health_tween.parallel().tween_method(_update_outline_color, health_bar.get_theme_stylebox("background").border_color, target_outline, TRANSITION_DURATION)
	else:
		_update_fill_color(target_color)
		_update_outline_color(target_outline)

func _update_fill_color(color: Color):
	var health_bar = get_node_or_null("HealthBar")
	if not health_bar:
		return
		
	# Create fresh style for fill with thicker border
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = color
	fill_style.border_color = Color.BLACK  # Black border for fill too
	fill_style.border_width_left = 3
	fill_style.border_width_right = 3
	fill_style.border_width_top = 3
	fill_style.border_width_bottom = 3
	fill_style.corner_radius_top_left = 4
	fill_style.corner_radius_top_right = 4
	fill_style.corner_radius_bottom_left = 4
	fill_style.corner_radius_bottom_right = 4
	fill_style.expand_margin_left = 1
	fill_style.expand_margin_right = 1
	fill_style.expand_margin_top = 1
	fill_style.expand_margin_bottom = 1
	health_bar.add_theme_stylebox_override("fill", fill_style)

func _update_outline_color(color: Color):
	var health_bar = get_node_or_null("HealthBar")
	if not health_bar:
		return
		
	# Create fresh style for background with very thick black border
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.1, 1)  # Darker background
	bg_style.border_color = Color.BLACK  # Always black outline
	bg_style.border_width_left = 6  # Much thicker border
	bg_style.border_width_right = 6
	bg_style.border_width_top = 6
	bg_style.border_width_bottom = 6
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	health_bar.add_theme_stylebox_override("background", bg_style)

func update_kill_counter(kills: int):
	total_kills = kills
	if kill_counter_label:
		kill_counter_label.text = "💀" + str(total_kills)
	
	# Check for multi-bullet unlock
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.check_multi_bullet_unlock(total_kills)

func update_score(score: int):
	total_score = score
	if score_label:
		score_label.text = "SCORE: " + str(total_score)

func add_to_score(points: int):
	total_score += points
	if score_label:
		score_label.text = "SCORE: " + str(total_score)

func _create_game_over_screen():
	# Create game over panel
	game_over_panel = Panel.new()
	game_over_panel.name = "GameOverPanel"
	game_over_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_panel.visible = false
	add_child(game_over_panel)
	
	# Style the panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.0, 0.0, 0.0, 0.9)  # Dark semi-transparent background
	panel_style.border_width_left = 4
	panel_style.border_width_right = 4
	panel_style.border_width_top = 4
	panel_style.border_width_bottom = 4
	panel_style.border_color = Color.RED
	panel_style.corner_radius_top_left = 20
	panel_style.corner_radius_top_right = 20
	panel_style.corner_radius_bottom_left = 20
	panel_style.corner_radius_bottom_right = 20
	game_over_panel.add_theme_stylebox_override("panel", panel_style)
	
	# Create main container
	var main_container = VBoxContainer.new()
	main_container.name = "MainContainer"
	main_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_container.add_theme_constant_override("separation", 30)
	game_over_panel.add_child(main_container)
	
	# Add spacer at top
	var top_spacer = Control.new()
	top_spacer.custom_minimum_size.y = 100
	main_container.add_child(top_spacer)
	
	# Game Over Title
	game_over_title = Label.new()
	game_over_title.text = "GAME OVER"
	game_over_title.add_theme_font_size_override("font_size", 64)
	game_over_title.add_theme_color_override("font_color", Color.RED)
	game_over_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontConfig.apply_ui_font(game_over_title)
	main_container.add_child(game_over_title)
	
	# Score Label
	game_over_score = Label.new()
	game_over_score.add_theme_font_size_override("font_size", 32)
	game_over_score.add_theme_color_override("font_color", Color.YELLOW)
	game_over_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontConfig.apply_ui_font(game_over_score)
	main_container.add_child(game_over_score)
	
	# Kills Label
	game_over_kills = Label.new()
	game_over_kills.add_theme_font_size_override("font_size", 32)
	game_over_kills.add_theme_color_override("font_color", Color.WHITE)
	game_over_kills.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontConfig.apply_ui_font(game_over_kills)
	main_container.add_child(game_over_kills)
	
	# Combo Label
	game_over_combo = Label.new()
	game_over_combo.add_theme_font_size_override("font_size", 32)
	game_over_combo.add_theme_color_override("font_color", Color.CYAN)
	game_over_combo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontConfig.apply_ui_font(game_over_combo)
	main_container.add_child(game_over_combo)
	
	# Restart Button
	game_over_restart_button = Button.new()
	game_over_restart_button.text = "RESTART"
	game_over_restart_button.custom_minimum_size = Vector2(200, 60)
	game_over_restart_button.add_theme_font_size_override("font_size", 28)
	game_over_restart_button.add_theme_color_override("font_color", Color.WHITE)
	
	# Style the button
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	button_style.border_width_left = 2
	button_style.border_width_right = 2
	button_style.border_width_top = 2
	button_style.border_width_bottom = 2
	button_style.border_color = Color.WHITE
	button_style.corner_radius_top_left = 10
	button_style.corner_radius_top_right = 10
	button_style.corner_radius_bottom_left = 10
	button_style.corner_radius_bottom_right = 10
	game_over_restart_button.add_theme_stylebox_override("normal", button_style)
	
	var button_hover_style = StyleBoxFlat.new()
	button_hover_style.bg_color = Color(0.4, 0.4, 0.4, 0.8)
	button_hover_style.border_width_left = 2
	button_hover_style.border_width_right = 2
	button_hover_style.border_width_top = 2
	button_hover_style.border_width_bottom = 2
	button_hover_style.border_color = Color.YELLOW
	button_hover_style.corner_radius_top_left = 10
	button_hover_style.corner_radius_top_right = 10
	button_hover_style.corner_radius_bottom_left = 10
	button_hover_style.corner_radius_bottom_right = 10
	game_over_restart_button.add_theme_stylebox_override("hover", button_hover_style)
	
	game_over_restart_button.pressed.connect(_on_restart_pressed)
	main_container.add_child(game_over_restart_button)

func show_game_over_message(message: String):
	print("show_game_over_message called with: ", message)
	
	# Get final stats from player
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.has_method("get_best_combo_streak"):
			best_combo_streak = player.get_best_combo_streak()
		elif "combo_streak" in player:
			best_combo_streak = player.combo_streak
	
	# Update game over labels
	if game_over_title:
		game_over_title.text = message
	if game_over_score:
		game_over_score.text = "SCORE: " + str(total_score)
	if game_over_kills:
		game_over_kills.text = "KILLS: " + str(total_kills)
	if game_over_combo:
		game_over_combo.text = "BEST COMBO: " + str(best_combo_streak)
	
	# Show the game over screen
	if game_over_panel:
		game_over_panel.visible = true
		print("Game over panel made visible")
		
		# Pause the game
		get_tree().paused = true
	else:
		print("ERROR: game_over_panel is null!")

func _on_restart_pressed():
	# Hide game over screen
	if game_over_panel:
		game_over_panel.visible = false
	
	# Unpause the game
	get_tree().paused = false
	
	# Restart the current scene
	get_tree().reload_current_scene()

func update_best_combo_streak(combo: int):
	if combo > best_combo_streak:
		best_combo_streak = combo
