extends Control
class_name SettingsMenuUI

# Paths updated to match your latest .tscn structure
@onready var container = $CenterContainer/PanelContainer/InternalPadding/VBoxContainer
@onready var volume_slider = container.get_node("HBoxContainer/VolumeSlider")
@onready var resolution_opt = container.get_node("HBoxContainer2/ResolutionOption")
@onready var fullscreen_chk = container.get_node("CheckBoxFullscreen")
@onready var diff_opt = container.get_node("HBoxContainer3/DifficultyOption")
@onready var btn_back = container.get_node("Header/ButtonBack")

const RESOLUTIONS = ["1280x720", "1920x1080", "2560x1440"]
const DIFFICULTIES = ["Easy", "Normal", "Hard"]

func _ready():
	if not is_instance_valid(ConfigManager): return

	# 1. Volume
	var vol = ConfigManager.get_setting("volume")
	volume_slider.value = (vol if vol != null else 0.8) * 100.0
	
	# 2. Resolution (PC Only)
	if not OS.has_feature("mobile") and not OS.has_feature("web"):
		for res in RESOLUTIONS: resolution_opt.add_item(res)
		
		var curr = ConfigManager.get_setting("resolution")
		var str_res = "%dx%d" % [curr.x, curr.y]
		var idx = RESOLUTIONS.find(str_res)
		if idx != -1: resolution_opt.select(idx)
	else:
		resolution_opt.add_item("Default")
		resolution_opt.disabled = true

	# 3. Fullscreen
	fullscreen_chk.button_pressed = ConfigManager.get_setting("fullscreen") == true
	
	# 4. Difficulty
	for d in DIFFICULTIES: diff_opt.add_item(d)
	var saved_diff = ConfigManager.get_setting("difficulty")
	var diff_idx = DIFFICULTIES.find(saved_diff)
	if diff_idx != -1: diff_opt.select(diff_idx)

	# Connect
	volume_slider.value_changed.connect(_on_volume)
	resolution_opt.item_selected.connect(_on_resolution)
	fullscreen_chk.toggled.connect(_on_fullscreen)
	diff_opt.item_selected.connect(_on_difficulty)
	btn_back.pressed.connect(_on_back)

func _on_volume(val):
	var linear = val / 100.0
	var db = linear_to_db(linear)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)
	ConfigManager.set_setting("volume", linear)

func _on_resolution(idx):
	var parts = resolution_opt.get_item_text(idx).split("x")
	var size1 = Vector2i(int(parts[0]), int(parts[1]))
	DisplayServer.window_set_size(size1)
	ConfigManager.set_setting("resolution", size1)

func _on_fullscreen(toggled):
	var mode = DisplayServer.WINDOW_MODE_FULLSCREEN if toggled else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)
	ConfigManager.set_setting("fullscreen", toggled)

func _on_difficulty(idx):
	ConfigManager.set_setting("difficulty", diff_opt.get_item_text(idx))

func _on_back():
	ConfigManager.save_config()
	visible = false
	
	# If in Main Menu scene, re-show start menu
	var start = get_node_or_null("/root/Main/SafeAreaRoot/StartMenu")
	if start: start.visible = true
	
	# If in-game, trigger pause menu overlay signal if needed (handled by overlay)