extends Control
class_name PauseMenuOverlay

# --- Node References ---
@onready var btn_resume = $BackgroundImage/Panel/ButtonResume
@onready var btn_settings = $BackgroundImage/Panel/ButtonSettings
@onready var btn_quit = $BackgroundImage/Panel/ButtonQuit

# --- Signals (For communication with the Settings Menu) ---
# Emitted when the settings button is pressed, telling the parent UI to open settings
signal settings_requested

func _ready():
	# Start hidden (visibility is managed by the parent UI Manager)
	visible = false 
	
	btn_resume.pressed.connect(_on_resume)
	btn_settings.pressed.connect(_on_settings)
	btn_quit.pressed.connect(_on_quit)

## Sets the game state to paused and shows the menu.
func show_menu():
	get_tree().paused = true
	visible = true

## Hides the menu and unpauses the game.
func hide_menu():
	visible = false
	# Unpause the game tree
	get_tree().paused = false

# --- Button Handlers ---

func _on_resume():
	hide_menu()

func _on_settings():
	# ⚠️ CRITICAL FIX 1: DO NOT UNPAUSE THE GAME HERE
	
	# IMPROVEMENT: Emit a signal for the parent UI to handle opening the settings menu.
	settings_requested.emit()
	
	# Since the settings menu is likely opened by the parent UI, 
	# we only need to hide the pause menu itself. The game remains paused.
	visible = false

func _on_quit():
	# A clean quit is preferred
	get_tree().quit()
