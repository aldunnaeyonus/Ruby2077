extends MarginContainer
class_name MobileHUD

# --- Node References ---
@onready var score_label = $HUDRoot/TopBar/LabelScore
@onready var time_label = $HUDRoot/TopBar/LabelTime

# Reference the instances we added in the scene
@onready var joystick = $HUDRoot/TouchJoystick
@onready var game_buttons = $HUDRoot/GameButtonsUi

# --- Signals (Output to Level) ---
signal jump_pressed
signal attack_pressed
signal pause_requested
signal joystick_input(vector: Vector2)

func _ready():
	update_safe_area()
	
	# 1. Connect Joystick
	if joystick:
		joystick.joystick_vector_changed.connect(_on_joystick_input)
	
	# 2. Connect Game Buttons (Bubbling up signals)
	if game_buttons:
		game_buttons.jump_requested.connect(func(): jump_pressed.emit())
		game_buttons.attack_requested.connect(func(): attack_pressed.emit())
		game_buttons.pause_requested.connect(func(): pause_requested.emit())

# Forward joystick vector
func _on_joystick_input(vec: Vector2):
	joystick_input.emit(vec)

# --- UI Updates ---
func update_safe_area():
	var safe = DisplayServer.get_display_safe_area()
	var full = get_viewport().get_visible_rect()
	var margin_left = safe.position.x
	var margin_top = safe.position.y
	var margin_right = full.size.x - (safe.position.x + safe.size.x)
	var margin_bottom = full.size.y - (safe.position.y + safe.size.y)
	
	add_theme_constant_override("margin_left", int(margin_left))
	add_theme_constant_override("margin_top", int(margin_top))
	add_theme_constant_override("margin_right", int(max(0.0, margin_right)))
	add_theme_constant_override("margin_bottom", int(max(0.0, margin_bottom)))

func update_score_display(score: int) -> void:
	score_label.text = "SCORE: %d" % score

func update_time_display(time_seconds: int) -> void:
	var minutes = time_seconds / 60
	var seconds = time_seconds % 60
	time_label.text = "TIME: %02d:%02d" % [minutes, seconds]