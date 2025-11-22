extends MarginContainer
class_name MobileHUD

# --- Node References ---
@onready var score_label = $HUDRoot/TopBar/LabelScore
@onready var time_label = $HUDRoot/TopBar/LabelTime
@onready var btn_jump = $HUDRoot/BottomBar/ButtonJump
@onready var btn_attack = $HUDRoot/BottomBar/ButtonAttack
@onready var btn_pause = $HUDRoot/BottomBar/ButtonPause

# --- Signals (Used to communicate input to the Player/Game Manager) ---
signal jump_pressed
signal attack_pressed
signal pause_requested


func _ready():
	# Update safe area margins
	update_safe_area()
	
	# Connect local buttons to signal emitters
	btn_jump.pressed.connect(_on_jump)
	btn_attack.pressed.connect(_on_attack)
	btn_pause.pressed.connect(_on_pause)
	
	# Assume GameManager or similar Autoload handles score/time updates via signals
	# Example:
	# if is_instance_valid(GameManager):
	#    GameManager.score_changed.connect(update_score_display)

## Applies margins to fit the display's safe area (notches, etc.).
func update_safe_area():
	var safe: Rect2 = DisplayServer.get_display_safe_area()
	var transform: Transform2D = get_viewport().get_final_transform()
	var safe_viewport: Rect2 = safe * transform.affine_inverse()
	var full_viewport: Rect2 = get_viewport().get_visible_rect()

	# Calculate margins
	var margin_left: float = safe_viewport.position.x
	var margin_top: float = safe_viewport.position.y
	
	# ⚠️ CRITICAL FIX: Correct calculation for right and bottom margins
	var margin_right: float = full_viewport.size.x - (safe_viewport.position.x + safe_viewport.size.x)
	var margin_bottom: float = full_viewport.size.y - (safe_viewport.position.y + safe_viewport.size.y)

	# Apply overrides
	add_theme_constant_override("margin_left", int(margin_left))
	add_theme_constant_override("margin_top", int(margin_top))
	add_theme_constant_override("margin_right", int(max(0.0, margin_right)))
	add_theme_constant_override("margin_bottom", int(max(0.0, margin_bottom)))

## Updates the score display.
func update_score_display(score: int) -> void:
	score_label.text = "SCORE: %d" % score

## Updates the time display.
func update_time_display(time_seconds: int) -> void:
	# Convert seconds to M:SS format
	var minutes = time_seconds / 60
	var seconds = time_seconds % 60
	time_label.text = "TIME: %02d:%02d" % [minutes, seconds]

# --- Button Signal Emitters ---

func _on_jump():
	jump_pressed.emit()
	print("Jump pressed (Signal Emitted)")

func _on_attack():
	attack_pressed.emit()
	print("Attack pressed (Signal Emitted)")

func _on_pause():
	# IMPROVEMENT: Emit a signal to the MobileGameplayUI Manager to handle the pause menu display
	pause_requested.emit()
	print("Pause requested (Signal Emitted)")
