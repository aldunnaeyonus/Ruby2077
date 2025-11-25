extends Node
class_name MainMenuManager

# --- Node References ---
@onready var startup_video = $StartupVideo
@onready var ruby_intro = $RubyIntroVideo
@onready var safe_area = $SafeAreaRoot
@onready var start_menu = $SafeAreaRoot/StartMenu
@onready var settings_menu = $SettingsMenu
@onready var transition = $TransitionLayer

@onready var btn_start = $SafeAreaRoot/StartMenu/VBoxContainer/ButtonStart
@onready var btn_continue = $SafeAreaRoot/StartMenu/VBoxContainer/ButtonContinue
@onready var btn_settings = $SafeAreaRoot/StartMenu/VBoxContainer/ButtonSettings

var save_file_path := "user://savegame.json" # Best practice: use user:// for saves

func _ready():
	# Apply Settings
	if is_instance_valid(ConfigManager):
		ConfigManager.apply_settings()
	
	if safe_area and safe_area.has_method("update_safe_area"):
		safe_area.update_safe_area()

	# --- 1. Reset Visibility ---
	if start_menu:
		start_menu.visible = false
	if ruby_intro:
		ruby_intro.visible = false
	if settings_menu:
		settings_menu.visible = false

	# --- 2. Setup Startup Video ---
	if startup_video:
		# Safety Check: Connect only if not already connected
		if not startup_video.finished.is_connected(_on_startup_video_finished):
			startup_video.finished.connect(_on_startup_video_finished)
		startup_video.play()
	
	# --- REMOVED BUTTON CONNECTIONS ---
	# These are already connected in Main.tscn (Green signal icon in Editor).
	# Re-connecting them here caused the error.
	
	# --- 3. Setup Intro Video ---
	if ruby_intro:
		if not ruby_intro.finished.is_connected(_on_ruby_intro_finished):
			ruby_intro.finished.connect(_on_ruby_intro_finished)
		if not ruby_intro.gui_input.is_connected(_on_ruby_intro_skip):
			ruby_intro.gui_input.connect(_on_ruby_intro_skip)

func _on_startup_video_finished():
	if transition:
		await transition.play("fade_out")
	
	if startup_video:
		startup_video.visible = false
	
	# Handle "Continue" button state
	if btn_continue:
		btn_continue.disabled = not FileAccess.file_exists(save_file_path)
	
	if start_menu:
		start_menu.visible = true
	
	if transition:
		await transition.play("fade_in")

func _on_start_pressed():
	if not FileAccess.file_exists(save_file_path):
		# New Game Flow
		if transition:
			await transition.play("fade_out")
		
		if start_menu:
			start_menu.visible = false
			
		if ruby_intro:
			ruby_intro.visible = true
			ruby_intro.play()
			
		if transition:
			await transition.play("fade_in")
	else:
		# Load Existing Game
		_go_to_level(load_saved_level())

func _on_ruby_intro_finished():
	if ruby_intro:
		ruby_intro.stop()
		_go_to_level(1)

func _on_ruby_intro_skip(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		if ruby_intro:
			ruby_intro.stop()
		_go_to_level(1)

func _on_continue_pressed():
	if FileAccess.file_exists(save_file_path):
		_go_to_level(load_saved_level())

func _on_settings_pressed():
	if start_menu:
		start_menu.visible = false
	if settings_menu: 
		settings_menu.visible = true

func _go_to_level(level: int):
	if transition:
		await transition.play("fade_out")
		
	var scene_path = "res://levels/Level%d.tscn" % level
	get_tree().change_scene_to_file(scene_path)

func load_saved_level() -> int:
	if not FileAccess.file_exists(save_file_path):
		return 1 
		
	var file = FileAccess.open(save_file_path, FileAccess.READ)
	if file == null:
		return 1 
		
	var json_text = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(json_text)
	
	if error == OK:
		var data = json.get_data()
		# Assuming your save data has a "level" key, or you save just the number
		if typeof(data) == TYPE_DICTIONARY:
			return data.get("current_level", 1)
		elif typeof(data) == TYPE_FLOAT or typeof(data) == TYPE_INT:
			return int(data)
			
	return 1
