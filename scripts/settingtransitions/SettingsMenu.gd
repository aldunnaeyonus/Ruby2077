extends Control
class_name SettingsMenuUI

# --- Node References ---
@onready var volume_slider = $NinePatchRect/VBoxContainer/HBoxContainer/VolumeSlider
@onready var resolution_option = $NinePatchRect/VBoxContainer/HBoxContainer2/ResolutionOption
@onready var fullscreen_toggle = $NinePatchRect/VBoxContainer/CheckBoxFullscreen
@onready var difficulty_option = $NinePatchRect/VBoxContainer/HBoxContainer3/DifficultyOption
@onready var btn_back =  $NinePatchRect/ButtonBack

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
	
	# CRITICAL FIX 1: Use flat keys (e.g., "volume")
	var saved_volume = ConfigManager.get_setting("volume")
	# Slider value is 0-100, ConfigManager value is 0.0-1.0
	volume_slider.value = saved_volume * 100.0

	var os_name = OS.get_name()
	var is_mobile = os_name in ["Android", "iOS", "Web"]

	# Resolution Setup
	if not is_mobile:
		for res in RESOLUTIONS:
			resolution_option.add_item(res)
			
		# CRITICAL FIX 2: Synchronize initial resolution selection
		var current_res: Vector2i = ConfigManager.get_setting("resolution")
		var current_res_str = "%dx%d" % [current_res.x, current_res.y]
		var current_index = RESOLUTIONS.find(current_res_str)
		if current_index != -1:
			resolution_option.select(current_index)
	else:
		resolution_option.add_item("Device Default")
		resolution_option.disabled = true

	# Fullscreen Toggle Synchronization
	fullscreen_toggle.button_pressed = ConfigManager.get_setting("fullscreen")
	
	# Difficulty Setup
	for diff in DIFFICULTIES:
		difficulty_option.add_item(diff)
		
	# CRITICAL FIX 2: Synchronize initial difficulty selection
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

# --- Signal Handlers (Apply Changes) ---

func _on_volume_changed(value: float):
	var linear = value / 100.0
	var db = linear_to_db(linear)
	
	# Update AudioServer immediately
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)
	
	# CRITICAL FIX 1: Use flat key
	ConfigManager.set_setting("volume", linear)

func _on_resolution_selected(index: int):
	var res_text = resolution_option.get_item_text(index)
	var res = res_text.split("x")
	
	if res.size() == 2:
		var size = Vector2i(int(res[0]), int(res[1]))
		
		# Update DisplayServer immediately
		DisplayServer.window_set_size(size)
		
		# CRITICAL FIX 1: Use flat key
		ConfigManager.set_setting("resolution", size)

func _on_fullscreen_toggled(pressed: bool):
	# CRITICAL FIX 3: Correct, readable window mode setting
	var mode = DisplayServer.WINDOW_MODE_WINDOWED
	if pressed:
		mode = DisplayServer.WINDOW_MODE_FULLSCREEN
		
	# Update DisplayServer immediately
	DisplayServer.window_set_mode(mode)
	
	# CRITICAL FIX 1: Use flat key
	ConfigManager.set_setting("fullscreen", pressed)

func _on_difficulty_selected(index: int):
	var difficulty = difficulty_option.get_item_text(index)
	
	# CRITICAL FIX 1: Use flat key
	ConfigManager.set_setting("difficulty", difficulty)

func _on_back_pressed():
	# Ensure the configuration is saved before leaving
	ConfigManager.save_config()
	
	visible = false
	
	# Assuming StartMenu is a sibling node under /root/Main/SafeAreaRoot/
	var start_menu = get_node("/root/Main/SafeAreaRoot/StartMenu")
	if is_instance_valid(start_menu):
		start_menu.visible = true
