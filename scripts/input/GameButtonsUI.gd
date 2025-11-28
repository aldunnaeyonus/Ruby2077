extends CanvasLayer

# --- Signals ---
signal attack_requested
signal jump_requested
signal pause_requested
signal inventory_requested
signal swap_requested
signal journal_requested
signal reload_requested # <--- NEW

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
@onready var btn_journal = $BottomRightContainer/JournalButton
# Weapon Buttons
@onready var btn_knife = $BottomCenterContainer/SwapKnifeButton
@onready var btn_gun = $BottomCenterContainer/SwapGunButton
@onready var ammo_label = $BottomCenterContainer/SwapGunButton/AmmoLabel

# --- State ---
var current_weapon_state = "knife" # Keeps track of UI state
var current_ammo = 10

func _on_knife_pressed():
	if current_weapon_state != "knife":
		current_weapon_state = "knife"
		update_weapon_visuals("knife")
		swap_requested.emit()

# NEW: Specific handler for Gun Button
func _on_gun_pressed():
	# If we are ALREADY holding the gun AND it is empty -> RELOAD
	if current_weapon_state == "gun" and current_ammo <= 0:
		reload_requested.emit()
		return

	# Otherwise, just switch to gun
	if current_weapon_state != "gun":
		current_weapon_state = "gun"
		update_weapon_visuals("gun")
		swap_requested.emit()

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

func _on_journal_pressed():
	journal_requested.emit()
	
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
func update_ammo_display(val: int, max_val: int):
	current_ammo = val
	if ammo_label:
		ammo_label.text = str(val)
	
	# Refresh visuals to apply Red color if needed
	update_weapon_visuals(current_weapon_state)
	
func update_weapon_visuals(active_weapon: String):
	# Base Colors (Red if empty, White if fine)
	var gun_color = Color.WHITE
	if current_ammo <= 0:
		gun_color = Color(1, 0, 0) # Red
	
	# 1. Update Opacity (Alpha)
	# Knife
	btn_knife.modulate = Color.WHITE
	btn_knife.modulate.a = 1.0 if active_weapon == "knife" else 0.5
	
	# Gun (Combine Red tint with Opacity)
	btn_gun.modulate = gun_color
	btn_gun.modulate.a = 1.0 if active_weapon == "gun" else 0.5
	
	# 2. Swap Attack Icons
	if active_weapon == "knife":
		if icon_knife: btn_attack.texture_normal = icon_knife
		if icon_knife_pressed: btn_attack.texture_pressed = icon_knife_pressed
	elif active_weapon == "gun":
		if icon_gun: btn_attack.texture_normal = icon_gun
		if icon_gun_pressed: btn_attack.texture_pressed = icon_gun_pressed
