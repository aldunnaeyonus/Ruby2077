extends Node2D

@onready var mobile_hud = $UI/MobileHUD
@onready var player = $Player # Make sure your player node is named exactly "Player"
@onready var pause_menu = $UI/PauseMenuOverlay
@onready var quest_journal =  $UI/QuestJournalUI # <--- Reference your Journal Node

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
	mobile_hud.swap_pressed.connect(player.swap_weapon)
	
	# 3. Pause Menu
	mobile_hud.pause_requested.connect(func():
		if pause_menu: pause_menu.show_menu()
	)

	if mobile_hud.has_signal("journal_pressed"):
		mobile_hud.journal_pressed.connect(quest_journal.toggle)
	
	if mobile_hud.has_signal("reload_pressed"):
		mobile_hud.reload_pressed.connect(player.reload)
	
	# 2. Connect Player Ammo Signal -> HUD Display
	if player.has_signal("ammo_changed"):
		player.ammo_changed.connect(mobile_hud.on_player_ammo_changed)
		
		# Force initial update
		mobile_hud.on_player_ammo_changed(player.current_ammo, player.max_ammo)
