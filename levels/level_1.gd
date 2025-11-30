extends Node2D

@onready var mobile_hud = $UI/MobileHUD
@onready var player = $Player
@onready var pause_menu = $UI/PauseMenuOverlay
@onready var quest_journal = $UI/QuestJournalUI

func _ready():
	if not mobile_hud or not player:
		push_error("Level1: Missing MobileHUD or Player node!")
		return

	# --- 1. CINEMATIC INTRO ---
	# Hide HUD so the "Eyelids" are the only thing visible
	if mobile_hud: mobile_hud.visible = false
	
	# Play the Eye-Opening Animation
	if has_node("/root/TransitionManager"):
		# TYPO FIXED: Changed "fase_in" to "wake_up"
		await TransitionManager.play("wake_up") 
	
	# Show HUD after eyes are open
	if mobile_hud: mobile_hud.visible = true

	# --- 2. CONNECT CONTROLS (Only after intro finishes) ---
	mobile_hud.joystick_input.connect(player.set_joystick_input)
	mobile_hud.jump_pressed.connect(player.jump)
	mobile_hud.attack_pressed.connect(player.attack)
	
	if mobile_hud.has_signal("weapon_change_pressed"):
		mobile_hud.weapon_change_pressed.connect(player.equip_weapon)
	
	mobile_hud.pause_requested.connect(func():
		if pause_menu: pause_menu.show_menu()
	)
	
	if player.has_signal("ammo_changed"):
		# This connects the Player's signal to the function we just added above
		player.ammo_changed.connect(mobile_hud.on_player_ammo_changed)
		
		# Force initial update
		mobile_hud.on_player_ammo_changed(player.current_ammo, player.max_ammo)
		
	if mobile_hud.has_signal("journal_pressed") and quest_journal:
		mobile_hud.journal_pressed.connect(quest_journal.toggle)

	# --- 3. CONNECT AMMO & RELOAD ---
	if mobile_hud.has_signal("reload_pressed"):
		mobile_hud.reload_pressed.connect(player.reload)
	
	if player.has_signal("ammo_changed"):
		player.ammo_changed.connect(mobile_hud.on_player_ammo_changed)
		mobile_hud.on_player_ammo_changed(player.current_ammo, player.max_ammo)
