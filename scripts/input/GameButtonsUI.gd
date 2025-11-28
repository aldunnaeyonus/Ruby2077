extends CanvasLayer

# --- Signals ---
signal attack_requested
signal jump_requested
signal pause_requested
signal inventory_requested
signal swap_requested

# --- Nodes ---
@onready var btn_attack = $BottomRightContainer/AttackButton
@onready var btn_jump = $BottomRightContainer/JumpButton
@onready var btn_menu = $BottomRightContainer/MenuButton
@onready var btn_pause = $CornerPause

# Weapon Buttons
@onready var btn_knife = $BottomCenterContainer/SwapKnifeButton
@onready var btn_gun = $BottomCenterContainer/SwapGunButton

# --- State ---
var current_weapon_state = "knife" # Keeps track of UI state

func _ready():
	# 1. Initialize Visuals (Knife Active by default)
	update_weapon_visuals("knife")

# --- Signal Connections (from .tscn) ---

func _on_attack_pressed():
	attack_requested.emit()

func _on_jump_pressed():
	jump_requested.emit()

func _on_pause_pressed():
	pause_requested.emit()

func _on_menu_pressed():
	inventory_requested.emit()

func _on_swap_pressed():
	# 1. Toggle local state
	if current_weapon_state == "knife":
		current_weapon_state = "gun"
	else:
		current_weapon_state = "knife"
	
	# 2. Update the UI highlights immediately
	update_weapon_visuals(current_weapon_state)
	
	# 3. Tell the game/player to swap
	swap_requested.emit()

# --- Visual Logic ---

func update_weapon_visuals(active_weapon: String):
	# Dim both first (0.5 alpha)
	btn_knife.modulate.a = 0.5
	btn_gun.modulate.a = 0.5
	
	# Highlight the active one (1.0 alpha)
	if active_weapon == "knife":
		btn_knife.modulate.a = 1.0
	elif active_weapon == "gun":
		btn_gun.modulate.a = 1.0
