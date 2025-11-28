extends MarginContainer
class_name MobileHUD

# --- Node References ---
@onready var hud_root = $HUDRoot 
@onready var hud_frame = $HUDRoot/HUDFrame
@onready var coin_label = $HUDRoot/HUDFrame/LabelCoins
# Changed from Label to TextureProgressBar
@onready var health_bar = $HUDRoot/HUDFrame/HealthBar

# Instances
@onready var joystick = $HUDRoot/TouchJoystick
@onready var game_buttons = $HUDRoot/GameButtonsUi

# --- Signals ---
signal jump_pressed
signal attack_pressed
signal pause_requested
signal joystick_input(vector: Vector2)
signal swap_pressed # <--- ADD THIS

func _ready():
	# 1. Determine Visibility
	var is_mobile = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
	var is_editor = OS.has_feature("editor")
	var should_show = is_mobile or is_editor
	
	visible = should_show 
	if hud_root: hud_root.visible = should_show
	
	# 2. Connect GameState Signals
	if is_instance_valid(GameState):
		GameState.coins_changed.connect(update_coin_display)
		GameState.health_changed.connect(update_health_display)
		
		# Initialize
		update_coin_display(GameState.coins)
		update_health_display(GameState.health, GameState.max_health)

	# 3. Connect Inputs
	if joystick and joystick.has_signal("joystick_vector_changed"):
		joystick.joystick_vector_changed.connect(_on_joystick_input)
	
	if game_buttons:
		game_buttons.jump_requested.connect(func(): jump_pressed.emit())
		game_buttons.attack_requested.connect(func(): attack_pressed.emit())
		game_buttons.pause_requested.connect(func(): pause_requested.emit())
		game_buttons.swap_requested.connect(func(): swap_pressed.emit())
		
	# 4. Safe Area
	get_tree().root.size_changed.connect(update_safe_area)
	update_safe_area()

func _on_joystick_input(vec: Vector2):
	joystick_input.emit(vec)

# --- UI Updates ---

func update_coin_display(coins: int) -> void:
	if coin_label:
		coin_label.text = "%d" % coins

func update_health_display(current: int, max_val: int) -> void:
	if health_bar:
		health_bar.max_value = max_val
		health_bar.value = current

func update_safe_area():
	if not hud_frame: return
	var safe = DisplayServer.get_display_safe_area()
	
	# Only adjust top-left position, no need to stretch margins for this fixed HUD
	var margin_top = safe.position.y + 20 # Add 20px padding
	var margin_left = safe.position.x + 20
	
	hud_frame.position = Vector2(margin_left, margin_top)
