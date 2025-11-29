extends CanvasLayer
class_name MobileHUD

# --- Node References ---
@onready var safe_area = $SafeArea
@onready var coin_label = $SafeArea/HUDFrame/LabelCoins
@onready var health_bar = $SafeArea/HUDFrame/HealthBar

# Instances
@onready var joystick = $TouchJoystick
@onready var game_buttons = $GameButtonsUi

# --- Signals ---
signal jump_pressed
signal attack_pressed
signal pause_requested
signal joystick_input(vector: Vector2)
# RESTORED SIGNALS:
signal weapon_change_pressed(weapon_name: String)
signal reload_pressed
signal journal_pressed

func _ready():
	# 1. Determine Visibility
	var is_mobile = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
	var is_editor = OS.has_feature("editor")
	visible = is_mobile or is_editor
	# 2. Connect GameState Signals
	if is_instance_valid(GameState):
		GameState.coins_changed.connect(update_coin_display)
		GameState.health_changed.connect(update_health_display)
		update_coin_display(GameState.coins)
		update_health_display(GameState.health, GameState.max_health)

	# 3. Connect Inputs
	if joystick and joystick.has_signal("joystick_vector_changed"):
		joystick.joystick_vector_changed.connect(_on_joystick_input)
	
	if game_buttons:
		game_buttons.jump_requested.connect(func(): jump_pressed.emit())
		game_buttons.attack_requested.connect(func(): attack_pressed.emit())
		game_buttons.pause_requested.connect(func(): pause_requested.emit())
		
		# --- RESTORED CONNECTIONS ---
		if game_buttons.has_signal("change_weapon_requested"):
			game_buttons.change_weapon_requested.connect(func(name): weapon_change_pressed.emit(name))
					
		if game_buttons.has_signal("reload_requested"):
			game_buttons.reload_requested.connect(func(): reload_pressed.emit())
			
		if game_buttons.has_signal("inventory_requested"):
			game_buttons.inventory_requested.connect(func(): 
				if is_instance_valid(GameState):
					GameState.set_inventory_open(not GameState.is_inventory_open())
			)
			
		if game_buttons.has_signal("journal_requested"):
			game_buttons.journal_requested.connect(func(): journal_pressed.emit())
		# ---------------------------
		
	get_tree().root.size_changed.connect(update_safe_area)
	update_safe_area()

func _on_joystick_input(vec: Vector2):
	joystick_input.emit(vec)

# --- RESTORED AMMO RELAY ---
func on_player_ammo_changed(current: int, max_val: int):
	if game_buttons:
		game_buttons.update_ammo_display(current, max_val)

# --- UI Updates ---
func update_coin_display(coins: int) -> void:
	if coin_label: coin_label.text = "%d" % coins

func update_health_display(current: int, max_val: int) -> void:
	if health_bar:
		health_bar.max_value = max_val
		health_bar.value = current

func update_safe_area():
	if not safe_area: return
	var safe = DisplayServer.get_display_safe_area()
	var full = get_viewport().get_visible_rect()
	var margin_top = safe.position.y + 20
	var margin_left = safe.position.x + 20
	var margin_right = full.size.x - (safe.position.x + safe.size.x)
	var margin_bottom = full.size.y - (safe.position.y + safe.size.y)
	
	safe_area.add_theme_constant_override("margin_top", int(margin_top))
	safe_area.add_theme_constant_override("margin_left", int(margin_left))
	safe_area.add_theme_constant_override("margin_right", int(margin_right))
	safe_area.add_theme_constant_override("margin_bottom", int(margin_bottom))
