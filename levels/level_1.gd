extends Node2D

@onready var mobile_hud = $UI/MobileHUD
@onready var player = $Player # Make sure your player node is named exactly "Player"
@onready var pause_menu = $UI/PauseMenuOverlay

func _ready():
	# Check if nodes exist to prevent crashes
	if not mobile_hud or not player:
		push_error("Level1: Missing MobileHUD or Player node!")
		return

	# --- Connect HUD Signals to Player Functions ---
	
	# 1. Movement
	mobile_hud.joystick_input.connect(player.set_joystick_input)
	
	# 2. Actions
	mobile_hud.jump_pressed.connect(player.jump)
	mobile_hud.attack_pressed.connect(player.attack)
	
	# 3. Pause Menu
	mobile_hud.pause_requested.connect(func():
		if pause_menu: pause_menu.show_menu()
	)
