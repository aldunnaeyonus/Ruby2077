extends CanvasLayer # <--- CHANGED FROM Control
class_name PauseMenuOverlay

# --- Node References ---
# Updated path: We added a 'Control' wrapper in the scene (see below)
@onready var btn_resume = $Control/BackgroundImage/ContentContainer/ButtonResume
@onready var btn_restart = $Control/BackgroundImage/ContentContainer/ButtonRestart
@onready var btn_save = $Control/BackgroundImage/ContentContainer/ButtonSave
@onready var btn_load = $Control/BackgroundImage/ContentContainer/ButtonLoad
@onready var btn_settings = $Control/BackgroundImage/ContentContainer/ButtonSettings
@onready var btn_quit = $Control/BackgroundImage/ContentContainer/ButtonQuit

@onready var settings_menu = $SettingsMenu 

func _ready():
	# CRITICAL FIX: Allow this menu to run while the game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
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
		# Check validity in case scene changed
		if is_instance_valid(btn_save): btn_save.text = "Save Game"

func _on_load():
	if is_instance_valid(GameState):
		get_tree().paused = false
		GameState.load_game()
		get_tree().reload_current_scene()

func _on_settings():
	if settings_menu:
		settings_menu.visible = true

func _on_quit():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
