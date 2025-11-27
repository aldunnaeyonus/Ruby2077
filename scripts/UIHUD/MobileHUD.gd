extends MarginContainer
class_name MobileHUD

# --- SIGNALS ---
signal jump_pressed
signal attack_pressed
signal pause_requested
signal joystick_input(vector: Vector2)

# --- NODES ---
@onready var hud_root = $HUDRoot 
@onready var score_label = $HUDRoot/TopBar/LabelScore
@onready var time_label = $HUDRoot/TopBar/LabelTime
@onready var top_bar = $HUDRoot/TopBar
@onready var joystick = $HUDRoot/TouchJoystick
@onready var game_buttons = $HUDRoot/GameButtonsUi

func _ready():
	var is_mobile = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
	var is_editor = OS.has_feature("editor")
	
	# Determine visibility
	var should_show = is_mobile or is_editor
	
	# Optimize: Disable processing if not visible
	visible = should_show
	process_mode = PROCESS_MODE_INHERIT if should_show else PROCESS_MODE_DISABLED
	
	if hud_root: hud_root.visible = should_show
	
	# Connect Components
	if joystick and joystick.has_signal("joystick_vector_changed"):
		joystick.joystick_vector_changed.connect(_on_joystick_input)
	
	if game_buttons:
		game_buttons.jump_requested.connect(func(): jump_pressed.emit())
		game_buttons.attack_requested.connect(func(): attack_pressed.emit())
		game_buttons.pause_requested.connect(func(): pause_requested.emit())
		
	# Handle Safe Area updates dynamically
	get_tree().root.size_changed.connect(update_safe_area)
	update_safe_area()

func _on_joystick_input(vec: Vector2):
	joystick_input.emit(vec)

func update_score_display(score: int) -> void:
	if score_label: score_label.text = "SCORE: %d" % score

func update_time_display(time_seconds: int) -> void:
	if time_label:
		var minutes: int = int(time_seconds / 60)
		var seconds: int = time_seconds % 60
		time_label.text = "TIME: %02d:%02d" % [minutes, seconds]

func update_safe_area():
	if not top_bar: return
	
	var safe = DisplayServer.get_display_safe_area()
	var full = get_viewport().get_visible_rect()
	
	# Apply margins to the top bar container to respect notches/cameras
	var margin_top = safe.position.y
	var margin_left = safe.position.x
	var margin_right = full.size.x - (safe.position.x + safe.size.x)
	
	top_bar.add_theme_constant_override("margin_top", int(margin_top))
	top_bar.add_theme_constant_override("margin_left", int(margin_left))
	top_bar.add_theme_constant_override("margin_right", int(margin_right))