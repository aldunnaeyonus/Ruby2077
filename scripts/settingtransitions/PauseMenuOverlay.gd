extends Control
class_name PauseMenuOverlay

# --- Node References ---
# Note: Path updated to match the new VBoxContainer structure
@onready var btn_resume = $BackgroundImage/ContentContainer/ButtonResume
@onready var btn_restart = $BackgroundImage/ContentContainer/ButtonRestart
@onready var btn_save = $BackgroundImage/ContentContainer/ButtonSave
@onready var btn_load = $BackgroundImage/ContentContainer/ButtonLoad
@onready var btn_settings = $BackgroundImage/ContentContainer/ButtonSettings
@onready var btn_quit = $BackgroundImage/ContentContainer/ButtonQuit

# --- Signals ---
signal settings_requested

func _ready():
	visible = false
	
	# Connect Signals
	btn_resume.pressed.connect(_on_resume)
	btn_restart.pressed.connect(_on_restart)
	btn_save.pressed.connect(_on_save)
	btn_load.pressed.connect(_on_load)
	btn_settings.pressed.connect(_on_settings)
	btn_quit.pressed.connect(_on_quit)

# --- Public Methods ---

func show_menu():
	get_tree().paused = true
	visible = true

func hide_menu():
	visible = false
	get_tree().paused = false

# --- Button Handlers ---

func _on_resume():
	hide_menu()

func _on_restart():
	# 1. Unpause first so the scene can actually reload
	get_tree().paused = false
	visible = false
	# 2. Reload the current active scene
	get_tree().reload_current_scene()

func _on_save():
	if is_instance_valid(GameState):
		GameState.save_game()
		# Optional: Give visual feedback (e.g. change button text briefly)
		btn_save.text = "Saved!"
		await get_tree().create_timer(1.0).timeout
		if btn_save: btn_save.text = "Save Game"

func _on_load():
	if is_instance_valid(GameState):
		# Unpause before loading to prevent freezing in the new state
		get_tree().paused = false
		visible = false
		GameState.load_game()
		# Note: load_game() usually handles scene switching, so we don't need extra logic here

func _on_settings():
	# Don't unpause; just emit signal to show settings layer
	settings_requested.emit()
	visible = false

func _on_quit():
	get_tree().paused = false
	# 2. Load the Main Menu scene
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
