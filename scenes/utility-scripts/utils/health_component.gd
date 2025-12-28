extends RefCounted
class_name HealthComponent

# Centralized health management component
var max_health: int
var health: int
var health_bar: ProgressBar = null
var owner_node: Node2D

# Health management signals
signal health_changed(current: int, max_health: int)
signal health_depleted
signal damage_taken(amount: int)
signal health_healed(amount: int)

# Initialize health component
# @param owner: The node that owns this health component
# @param max_hp: Maximum health value
# @param health_bar_node: Optional health bar ProgressBar node
func _init(owner: Node2D, max_hp: int, health_bar_node: ProgressBar = null):
	owner_node = owner
	max_health = max_hp
	health = max_hp
	health_bar = health_bar_node
	
	# Setup health bar if provided
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health

# Take damage with optional knockback and effects
# @param amount: Amount of damage to take
# @param knockback_direction: Direction for knockback (optional)
# @param spawn_blood: Whether to spawn blood effects (default: true)
# @return: True if health was depleted, false otherwise
func take_damage(amount: int, knockback_direction: Vector2 = Vector2.ZERO, spawn_blood: bool = true) -> bool:
	var old_health = health
	health = max(health - amount, 0)
	
	# Emit damage taken signal
	damage_taken.emit(amount)
	
	# Spawn blood effects if requested and owner has the method
	if spawn_blood and owner_node and health < old_health:
		if owner_node.has_method("_spawn_blood_splash"):
			owner_node._spawn_blood_splash(knockback_direction)
	
	# Update health bar
	_update_health_bar()
	
	# Emit health changed signal
	health_changed.emit(health, max_health)
	
	# Check if depleted
	if health <= 0:
		health_depleted.emit()
		return true
	
	return false

# Heal health amount
# @param amount: Amount of health to restore
# @return: Actual amount healed (may be less if at max health)
func heal(amount: int) -> int:
	var old_health = health
	health = min(health + amount, max_health)
	var actual_healed = health - old_health
	
	if actual_healed > 0:
		health_healed.emit(actual_healed)
		_update_health_bar()
		health_changed.emit(health, max_health)
	
	return actual_healed

# Set health to specific value
# @param new_health: New health value
func set_health(new_health: int):
	health = clamp(new_health, 0, max_health)
	_update_health_bar()
	health_changed.emit(health, max_health)
	
	if health <= 0:
		health_depleted.emit()

# Get current health value
func get_current_health() -> int:
	return health

# Get current health percentage (0.0 to 1.0)
func get_health_percentage() -> float:
	return float(health) / float(max_health)

# Check if at full health
func is_at_full_health() -> bool:
	return health >= max_health

# Check if health is depleted
func is_depleted() -> bool:
	return health <= 0

# Update health bar display
func _update_health_bar():
	if health_bar:
		health_bar.value = health

# Setup health bar styling (optional)
func setup_health_bar_style(fill_color: Color = Color.RED, border_color: Color = Color.BLACK):
	if not health_bar:
		return
	
	# Style the fill
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = fill_color
	style_box.border_width_left = 1
	style_box.border_width_right = 1
	style_box.border_width_top = 1
	style_box.border_width_bottom = 1
	style_box.border_color = border_color
	style_box.corner_radius_top_left = 2
	style_box.corner_radius_top_right = 2
	style_box.corner_radius_bottom_left = 2
	style_box.corner_radius_bottom_right = 2
	
	health_bar.add_theme_stylebox_override("fill", style_box)
	
	# Create background style
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color.DARK_GRAY
	bg_style.corner_radius_top_left = 2
	bg_style.corner_radius_top_right = 2
	bg_style.corner_radius_bottom_left = 2
	bg_style.corner_radius_bottom_right = 2
	
	health_bar.add_theme_stylebox_override("background", bg_style)

# Reset health to maximum
func reset_health():
	health = max_health
	_update_health_bar()
	health_changed.emit(health, max_health)
