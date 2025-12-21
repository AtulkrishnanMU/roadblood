extends ProgressBar

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
var total_kills: int = 0

func _ready():
	show_percentage = false
	# Find the health label
	health_label = get_node_or_null("HealthLabel")
	# Find the kill counter label
	kill_counter_label = get_node_or_null("KillCounterLabel")
	# Initialize kill counter display
	update_kill_counter(0)
	# Add to health_bar group for enemy spawner communication
	add_to_group("health_bar")

func update_health(current: int, max_value: int):
	max_value = max_value
	
	# Update health label text
	if health_label:
		health_label.text = str(current) + "/" + str(max_value) + " HP"
	
	# Create smooth transition
	if health_tween and health_tween.is_valid():
		health_tween.kill()
	
	health_tween = create_tween()
	health_tween.set_ease(Tween.EASE_IN_OUT)
	health_tween.set_trans(Tween.TRANS_SINE)
	health_tween.tween_property(self, "value", current, TRANSITION_DURATION)
	
	_update_color(current, max_value)

func _update_color(current: int, max_value: int):
	var health_percentage = float(current) / float(max_value)
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
		health_tween.parallel().tween_method(_update_fill_color, get_theme_stylebox("fill").bg_color, target_color, TRANSITION_DURATION)
		health_tween.parallel().tween_method(_update_outline_color, get_theme_stylebox("background").border_color, target_outline, TRANSITION_DURATION)
	else:
		_update_fill_color(target_color)
		_update_outline_color(target_outline)

func _update_fill_color(color: Color):
	var fill_style = get_theme_stylebox("fill").duplicate()
	if fill_style is StyleBoxFlat:
		fill_style.bg_color = color
		fill_style.border_color = color  # Update fill border color to match fill
		add_theme_stylebox_override("fill", fill_style)

func _update_outline_color(color: Color):
	var bg_style = get_theme_stylebox("background").duplicate()
	if bg_style is StyleBoxFlat:
		bg_style.border_color = color
		add_theme_stylebox_override("background", bg_style)

func update_kill_counter(kills: int):
	total_kills = kills
	if kill_counter_label:
		kill_counter_label.text = "KILLS: " + str(total_kills)
	
	# Check for multi-bullet unlock
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.check_multi_bullet_unlock(total_kills)
