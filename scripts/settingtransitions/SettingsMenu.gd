extends Control
class_name SettingsMenuUI

# --- Node References ---
@onready var volume_slider = $Panel/VBoxContainer/HBoxContainer/VolumeSlider
# FIX: Updated path to HBoxContainer2
@onready var resolution_option = $Panel/VBoxContainer/HBoxContainer2/ResolutionOption
@onready var fullscreen_toggle = $Panel/VBoxContainer/CheckBoxFullscreen
# FIX: Updated path to HBoxContainer3
@onready var difficulty_option = $Panel/VBoxContainer/HBoxContainer3/DifficultyOption
# FIX: Updated path (Button is now direct child of Panel)
@onready var btn_back = $Panel/ButtonBack

const RESOLUTIONS = [
	"1280x720",
	"1920x1080",
	"2560x1440",
	"3840x2160"
]
const DIFFICULTIES = ["Easy", "Normal", "Hard"]

func _ready():
	# Assume ConfigManager is an Autoload Singleton
	if not is_instance_valid(ConfigManager):
		push_error("ConfigManager Autoload not found.")
		return
		
	# --- Setup and Synchronization ---
	
	# Use flat keys (e.g., "volume")
	var saved_volume = ConfigManager.get_setting("volume")
	if saved_volume != null:
		volume_slider.value = float(saved_volume) * 100.0

	var os_name = OS.get_name()
	var is_mobile = os_name in ["Android", "iOS", "Web"]

	# Resolution Setup
	if not is_mobile:
		for res in RESOLUTIONS:
			resolution_option.add_item(res)
			
		var current_res = ConfigManager.get_setting("resolution")
		if current_res is Vector2i:
			var current_res_str = "%dx%d" % [current_res.x, current_res.y]
			var current_index = RESOLUTIONS.find(current_res_str)
			if current_index != -1:
				resolution_option.select(current_index)
	else:
		resolution_option.add_item("Device Default")
		resolution_option.disabled = true

	# Fullscreen Toggle
	fullscreen_toggle.button_pressed = ConfigManager.get_setting("fullscreen") == true
	
	# Difficulty Setup
	for diff in DIFFICULTIES:
		difficulty_option.add_item(diff)
		
	var saved_difficulty = ConfigManager.get_setting("difficulty")
	var difficulty_index = DIFFICULTIES.find(saved_difficulty)
	if difficulty_index != -1:
		difficulty_option.select(difficulty_index)

	# --- Connect Signals ---
	volume_slider.value_changed.connect(_on_volume_changed)
	resolution_option.item_selected.connect(_on_resolution_selected)
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	difficulty_option.item_selected.connect(_on_difficulty_selected)
	btn_back.pressed.connect(_on_back_pressed)

# --- Signal Handlers ---

func _on_volume_changed(value: float):
	var linear = value / 100.0
	var db = linear_to_db(linear)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)
	ConfigManager.set_setting("volume", linear)

func _on_resolution_selected(index: int):
	var res_text = resolution_option.get_item_text(index)
	var res = res_text.split("x")
	
	if res.size() == 2:
		var size = Vector2i(int(res[0]), int(res[1]))
		DisplayServer.window_set_size(size)
		ConfigManager.set_setting("resolution", size)

func _on_fullscreen_toggled(pressed: bool):
	var mode = DisplayServer.WINDOW_MODE_FULLSCREEN if pressed else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)
	ConfigManager.set_setting("fullscreen", pressed)

func _on_difficulty_selected(index: int):
	var difficulty = difficulty_option.get_item_text(index)
	ConfigManager.set_setting("difficulty", difficulty)

func _on_back_pressed():
	ConfigManager.save_config()
	visible = false
	
	# Return to Start Menu if we are in the Main Menu scene
	var start_menu = get_node_or_null("/root/Main/SafeAreaRoot/StartMenu")
	if start_menu:
		start_menu.visible = true
	
	# If we are in-game (Pause Menu), we just hide settings (handled by overlay logic)
	var pause_menu = get_node_or_null("/root/Level1/UI/PauseMenuOverlay")
	if pause_menu and pause_menu.visible:
		# Ensure pause menu stays visible or re-appears
		pass
