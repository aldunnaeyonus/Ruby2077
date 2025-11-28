extends CanvasLayer

# --- Signals ---
signal attack_requested
signal jump_requested
signal pause_requested
signal inventory_requested
signal swap_requested

# --- Configuration (Assign these in the Inspector!) ---
@export_group("Knife Icons")
@export var icon_knife: Texture2D = preload("res://assets/icons/knife.svg")
@export var icon_knife_pressed: Texture2D = preload("res://assets/icons/knife_pressed.svg")

@export_group("Gun Icons")
@export var icon_gun: Texture2D = preload("res://assets/icons/gun.svg")
@export var icon_gun_pressed: Texture2D = preload("res://assets/icons/gun_pressed.svg") # Assign your gun_pressed.svg here

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
	
	if active_weapon == "knife":
		btn_knife.modulate.a = 1.0
		
		# 2. Swap Attack Textures (Knife)
		if icon_knife: 
			btn_attack.texture_normal = icon_knife
		if icon_knife_pressed:
			btn_attack.texture_pressed = icon_knife_pressed
			
	elif active_weapon == "gun":
		btn_gun.modulate.a = 1.0
		
		# 2. Swap Attack Textures (Gun)
		if icon_gun: 
			btn_attack.texture_normal = icon_gun
		if icon_gun_pressed:
			btn_attack.texture_pressed = icon_gun_pressed
