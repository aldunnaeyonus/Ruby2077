extends MarginContainer
class_name MobileHUD

# --- Node References ---
@onready var score_label = $HUDRoot/TopBar/LabelScore
@onready var time_label = $HUDRoot/TopBar/LabelTime

# Update these paths to match your MobileHUD.tscn structure
@onready var joystick = $HUDRoot/TouchJoystick
@onready var game_buttons = $HUDRoot/GameButtonsUi

# --- Signals ---
signal jump_pressed
signal attack_pressed
signal pause_requested
signal joystick_input(vector: Vector2)

func _ready():
	update_safe_area()
	
	# Connect Joystick Signal
	if joystick:
		joystick.joystick_vector_changed.connect(_on_joystick_input)
	
	# Connect GameButtons Signals
	if game_buttons:
		game_buttons.jump_requested.connect(_on_jump)
		game_buttons.attack_requested.connect(_on_attack)
		game_buttons.pause_requested.connect(_on_pause)

# --- Signal Relay Functions ---

func _on_jump():
	jump_pressed.emit()

func _on_attack():
	attack_pressed.emit()

func _on_pause():
	pause_requested.emit()

func _on_joystick_input(vec: Vector2):
	joystick_input.emit(vec)

# --- Safe Area Logic (Kept from your previous file) ---
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