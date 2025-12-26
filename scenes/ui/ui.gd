extends Control

# Preload UI style cache
const UIStyleCache = preload("res://scenes/utility-scripts/utils/ui_style_cache.gd")

const HEALTH_HIGH_COLOR = Color(0.2, 0.8, 0.2, 1)  # Green for high health (>50%)
const HEALTH_MEDIUM_COLOR = Color(0.8, 0.8, 0.2, 1)  # Yellow for medium health (<50%)
const HEALTH_LOW_COLOR = Color(0.8, 0.2, 0.2, 1)   # Red for low health (<20%)
const HEALTH_HIGH_OUTLINE = Color(0.1, 0.6, 0.1, 1)  # Darker green outline
const HEALTH_MEDIUM_OUTLINE = Color(0.6, 0.6, 0.1, 1)  # Darker yellow outline
const HEALTH_LOW_OUTLINE = Color(0.6, 0.1, 0.1, 1)   # Darker red outline
const HEALTH_MEDIUM_THRESHOLD = 0.5  # Below this percentage = yellow
const HEALTH_LOW_THRESHOLD = 0.2   # Below this percentage = red
const TRANSITION_DURATION = 0.5  # Duration for smooth transitions

var health_tween: Tween
var health_label: Label
var kill_counter_label: Label
var score_label: Label
var total_kills: int = 0
var total_score: int = 0

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
	
	# Find the health bar and labels
	var health_bar = get_node_or_null("HealthBar")
	if health_bar:
		health_bar.show_percentage = false
		health_label = health_bar.get_node_or_null("HealthLabel")
		# Apply default font to health label
		if health_label:
			FontConfig.apply_ui_font(health_label)
	
	# Find other labels
	kill_counter_label = get_node_or_null("HealthBar/KillCounterLabel")
	score_label = get_node_or_null("ScoreLabel")
	
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
		
	# Use cached style instead of duplicating
	var fill_style = UIStyleCache.get_style(UIStyleCache.StyleType.HEALTH_BAR, 0)
	if fill_style and fill_style is StyleBoxFlat:
		fill_style.bg_color = color
		fill_style.border_color = color  # Update fill border color to match fill
		health_bar.add_theme_stylebox_override("fill", fill_style)

func _update_outline_color(color: Color):
	var health_bar = get_node_or_null("HealthBar")
	if not health_bar:
		return
		
	# Use cached style instead of duplicating
	var bg_style = UIStyleCache.get_style(UIStyleCache.StyleType.BACKGROUND_PANEL)
	if bg_style and bg_style is StyleBoxFlat:
		bg_style.border_color = color
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
		score_label.text = str(total_score)

func add_to_score(points: int):
	total_score += points
	if score_label:
		score_label.text = str(total_score)
