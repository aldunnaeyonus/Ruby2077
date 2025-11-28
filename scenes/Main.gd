extends Node
class_name MainMenuManager

# --- NODES ---
@onready var startup_video = $StartupVideo
@onready var ruby_intro = $RubyIntroVideo
@onready var safe_area = $SafeAreaRoot
@onready var start_menu = $SafeAreaRoot/StartMenu
@onready var settings_menu = $SettingsMenu

@onready var btn_start = $SafeAreaRoot/StartMenu/VBoxContainer/ButtonStart
@onready var btn_continue = $SafeAreaRoot/StartMenu/VBoxContainer/ButtonContinue
@onready var btn_settings = $SafeAreaRoot/StartMenu/VBoxContainer/ButtonSettings

# CRITICAL: Always use user:// for saves
var save_file_path := "user://savegame.json" 

func _ready():
	if is_instance_valid(ConfigManager):
		ConfigManager.apply_settings()
	
	if safe_area and safe_area.has_method("update_safe_area"):
		safe_area.update_safe_area()

	# Hide menus initially
	if start_menu: start_menu.visible = false
	if ruby_intro: ruby_intro.visible = false
	if settings_menu: settings_menu.visible = false

	# Setup Buttons
	if btn_start: btn_start.pressed.connect(_on_start_pressed)
	if btn_continue: btn_continue.pressed.connect(_on_continue_pressed)
	if btn_settings: btn_settings.pressed.connect(_on_settings_pressed)

	# Start Video
	if startup_video:
		if not startup_video.finished.is_connected(_on_startup_video_finished):
			startup_video.finished.connect(_on_startup_video_finished)
		startup_video.play()
	else:
		# Fallback if no video
		_on_startup_video_finished()

func _on_startup_video_finished():
	TransitionManager.play("fade_out")
	if startup_video: startup_video.visible = false
	
	# Enable/Disable Continue based on save file
	if btn_continue:
		btn_continue.disabled = not FileAccess.file_exists(save_file_path)
	
	if start_menu: start_menu.visible = true
	TransitionManager.play("fade_in")

func _on_start_pressed():
	# Logic: Start -> New Game (Overwrite warning could be added here)
	# For now, just starts a fresh game logic
	_play_intro_sequence()

func _play_intro_sequence():
	TransitionManager.play("fade_out")
	if start_menu: start_menu.visible = false
	
	if ruby_intro:
		ruby_intro.visible = true
		if not ruby_intro.finished.is_connected(_on_ruby_intro_finished):
			ruby_intro.finished.connect(_on_ruby_intro_finished)
		# Allow skipping
		if not ruby_intro.gui_input.is_connected(_on_intro_input):
			ruby_intro.gui_input.connect(_on_intro_input)
			
		ruby_intro.play()
		TransitionManager.play("fade_in")

	else:
		_go_to_level(1)

func _on_intro_input(event):
	if event is InputEventMouseButton and event.pressed:
		_on_ruby_intro_finished()

func _on_ruby_intro_finished():
	if ruby_intro: ruby_intro.stop()
	_go_to_level(1)

func _on_continue_pressed():
	if FileAccess.file_exists(save_file_path):
		# Load global state first
		if is_instance_valid(GameState):
			GameState.load_game()
		
		# Assuming GameState or a generic level loader handles the scene switch,
		# but if we store just the level index:
		# _go_to_level(GameState.current_level_index) 
		_go_to_level(1) # Default for now

func _on_settings_pressed():
	if start_menu: start_menu.visible = false
	if settings_menu: settings_menu.visible = true

func _go_to_level(level: int):
	TransitionManager.play("fade_in")
	var path = "res://levels/Level%d.tscn" % level
	if ResourceLoader.exists(path):
		get_tree().change_scene_to_file(path)
	else:
		push_error("Level scene not found: %s" % path)
		
