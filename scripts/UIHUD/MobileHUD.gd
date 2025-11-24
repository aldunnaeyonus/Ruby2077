extends MarginContainer
class_name MobileHUD

# --- Node References ---
# We need to reference the CanvasLayer explicitly to hide it
@onready var hud_root = $HUDRoot 
@onready var score_label = $HUDRoot/TopBar/LabelScore
@onready var time_label = $HUDRoot/TopBar/LabelTime
@onready var top_bar = $HUDRoot/TopBar

# Instances
@onready var joystick = $HUDRoot/TouchJoystick
@onready var game_buttons = $HUDRoot/GameButtonsUi

# --- Signals ---
signal jump_pressed
signal attack_pressed
signal pause_requested
signal joystick_input(vector: Vector2)

func _ready():
	# 1. Determine Visibility
	var is_mobile = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
	var is_editor = OS.has_feature("editor")
	var should_show = is_mobile or is_editor
	
	# 2. Apply Visibility to ALL CanvasLayers
	# Hiding 'self' isn't enough because CanvasLayers are independent
	visible = should_show 
	if hud_root: hud_root.visible = should_show
	if joystick: joystick.visible = should_show
	if game_buttons: game_buttons.visible = should_show

	# 3. Connect Joystick
	if joystick:
		# Ensure signal name matches TouchJoystick.gd (usually 'joystick_vector_changed')
		if joystick.has_signal("joystick_vector_changed"):
			joystick.joystick_vector_changed.connect(_on_joystick_input)
	
	# 4. Connect Game Buttons
	if game_buttons:
		game_buttons.jump_requested.connect(func(): jump_pressed.emit())
		game_buttons.attack_requested.connect(func(): attack_pressed.emit())
		game_buttons.pause_requested.connect(func(): pause_requested.emit())
		
	# 5. Handle Safe Area
	update_safe_area()
	# Update safe area when screen size changes (rotation)
	get_tree().root.size_changed.connect(update_safe_area)

func _on_joystick_input(vec: Vector2):
	joystick_input.emit(vec)

# --- UI Updates ---

func update_score_display(score: int) -> void:
	if score_label:
		score_label.text = "SCORE: %d" % score

func update_time_display(time_seconds: int) -> void:
	if time_label:
		# Explicitly cast to int to prevent "Integer Division" warnings
		var minutes = int(time_seconds / 60)
		var seconds = time_seconds % 60
		time_label.text = "TIME: %02d:%02d" % [minutes, seconds]

func update_safe_area():
	# CRITICAL FIX: Apply margins to the TopBar directly, 
	# because HUDRoot (CanvasLayer) ignores the MarginContainer.
	var safe = DisplayServer.get_display_safe_area()
	var full = get_viewport().get_visible_rect()
	
	# Calculate margins
	var margin_top = safe.position.y
	var margin_left = safe.position.x
	var margin_right = full.size.x - (safe.position.x + safe.size.x)
	
	# Apply to TopBar (HBoxContainer)
	if top_bar:
		# Use MarginContainer overrides if TopBar is inside one, 
		# or set custom minimum size / position if it's a simple Control.
		# Ideally, TopBar should be inside a MarginContainer, but we can hack it here:
		top_bar.add_theme_constant_override("margin_top", int(margin_top))
		top_bar.add_theme_constant_override("margin_left", int(margin_left))
		top_bar.add_theme_constant_override("margin_right", int(margin_right))
