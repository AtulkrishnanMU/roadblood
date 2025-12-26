extends Node

# Centralized UI event management system
# - Provides single source of truth for UI updates
# - Uses signals for decoupled communication
# - Handles health updates, score changes, and other UI events

# UI event signals
signal health_updated(current: int, max_health: int)
signal score_added(amount: int)
signal combo_streak_changed(streak: int)
signal kill_count_changed(kills: int)

# Cached references for performance
var _ui_script_cache: Node = null
var _tree_cache: SceneTree = null

func _ready():
	# Cache scene tree reference
	_tree_cache = get_tree()

# Initialize UI event system
# @param ui_script: The main UI script to connect to
func setup(ui_script: Node) -> void:
	# Cache UI script reference
	_ui_script_cache = ui_script
	
	# Connect UI event signals to UI script methods
	health_updated.connect(ui_script.update_health)
	score_added.connect(ui_script.add_to_score)
	combo_streak_changed.connect(_on_combo_streak_changed)  # Handle internally
	kill_count_changed.connect(ui_script.update_kill_counter)

# Internal handler for combo streak changes (UI doesn't have this method)
func _on_combo_streak_changed(streak: int) -> void:
	# Combo streak is handled by the player's combo popup system
	# This can be used for future UI combo display if needed
	pass
	
# Update player health (centralized)
# @param current: Current health value
# @param max_health: Maximum health value
func update_player_health(current: int, max_health: int) -> void:
	health_updated.emit(current, max_health)

# Add score to UI (centralized)
# @param amount: Amount of score to add
func add_score(amount: int) -> void:
	score_added.emit(amount)

# Update combo streak (centralized)
# @param streak: Current combo streak
func update_combo_streak(streak: int) -> void:
	combo_streak_changed.emit(streak)

# Update kill count (centralized)
# @param kills: Current kill count
func update_kill_count(kills: int) -> void:
	kill_count_changed.emit(kills)

# Batch update multiple UI elements (for performance)
# @param health_data: Optional health update [current, max_health]
# @param score_amount: Optional score to add
# @param combo_streak: Optional combo streak update
# @param kill_count: Optional kill count update
func batch_update(health_data: Array[int] = [], score_amount: int = 0, combo_streak: int = -1, kill_count: int = -1) -> void:
	if health_data.size() >= 2:
		health_updated.emit(health_data[0], health_data[1])
	
	if score_amount > 0:
		score_added.emit(score_amount)
	
	if combo_streak >= 0:
		combo_streak_changed.emit(combo_streak)
	
	if kill_count >= 0:
		kill_count_changed.emit(kill_count)

# Convenience method for enemy death events
# @param score_value: Score value of killed enemy
# @param current_kills: Updated kill count
func on_enemy_killed(score_value: int, current_kills: int) -> void:
	score_added.emit(score_value)
	kill_count_changed.emit(current_kills)

# Convenience method for player damage events
# @param current_health: Player's current health
# @param max_health: Player's maximum health
func on_player_damaged(current_health: int, max_health: int) -> void:
	health_updated.emit(current_health, max_health)

# Convenience method for player healing events
# @param current_health: Player's current health after healing
# @param max_health: Player's maximum health
# @param heal_amount: Amount healed
func on_player_healed(current_health: int, max_health: int, heal_amount: int) -> void:
	health_updated.emit(current_health, max_health)
	# Could add heal popup event here if needed
