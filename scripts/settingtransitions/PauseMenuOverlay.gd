extends Control
class_name PauseMenuOverlay

# --- NODES ---
@onready var btn_resume = $BackgroundImage/ContentContainer/ButtonResume
@onready var btn_restart = $BackgroundImage/ContentContainer/ButtonRestart
@onready var btn_save = $BackgroundImage/ContentContainer/ButtonSave
@onready var btn_load = $BackgroundImage/ContentContainer/ButtonLoad
@onready var btn_settings = $BackgroundImage/ContentContainer/ButtonSettings
@onready var btn_quit = $BackgroundImage/ContentContainer/ButtonQuit

# Reference the internal SettingsMenu instance you added to the scene
@onready var settings_menu = $SettingsMenu 

func _ready():
	visible = false
	if settings_menu: settings_menu.visible = false
	
	btn_resume.pressed.connect(_on_resume)
	btn_restart.pressed.connect(_on_restart)
	btn_save.pressed.connect(_on_save)
	btn_load.pressed.connect(_on_load)
	btn_settings.pressed.connect(_on_settings)
	btn_quit.pressed.connect(_on_quit)

func show_menu():
	get_tree().paused = true
	visible = true
	# Ensure settings is closed when pause menu opens
	if settings_menu: settings_menu.visible = false

func hide_menu():
	visible = false
	if settings_menu: settings_menu.visible = false
	get_tree().paused = false

func _on_resume():
	hide_menu()

func _on_restart():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_save():
	if is_instance_valid(GameState):
		GameState.save_game()
		btn_save.text = "Saved!"
		await get_tree().create_timer(1.0).timeout
		if is_instance_valid(btn_save): btn_save.text = "Save Game"

func _on_load():
	if is_instance_valid(GameState):
		get_tree().paused = false
		GameState.load_game()
		# Assuming load_game handles scene transition, otherwise reload scene:
		get_tree().reload_current_scene()

func _on_settings():
	# Open the child settings menu
	if settings_menu:
		settings_menu.visible = true
		# Note: We do NOT hide the Pause Menu, we just layer Settings on top.
		# The SettingsMenu 'Back' button script simply does 'visible = false',
		# which reveals this Pause Menu again.

func _on_quit():
	get_tree().paused = false
	# Ensure this path matches your project structure!
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
	
