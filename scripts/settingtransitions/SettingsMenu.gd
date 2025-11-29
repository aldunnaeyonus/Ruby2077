extends Control
class_name SettingsMenuUI

# --- Nodes ---
@onready var container = $CenterContainer/PanelContainer/InternalPadding/VBoxContainer
@onready var volume_slider = container.get_node("HBoxContainer/VolumeSlider")
@onready var resolution_opt = container.get_node("HBoxContainer2/ResolutionOption")
@onready var fullscreen_chk = container.get_node("CheckBoxFullscreen")
@onready var diff_opt = container.get_node("HBoxContainer3/DifficultyOption")
@onready var btn_back = container.get_node("Header/ButtonBack")
@onready var sfx_player = $VolumeTestSFX

# --- Configuration ---
# Assign a sound file here in the Inspector!
@export var test_sound: AudioStream 

const RESOLUTIONS = ["640x360", "1280x720", "1920x1080", "2560x1440"]
const DIFFICULTIES = ["Easy", "Normal", "Hard"]

# --- State ---
var last_sound_time: int = 0
const SOUND_COOLDOWN_MS: int = 100 # Prevents sound spamming

func _ready():
	# Assign the stream if one was set in Inspector
	if test_sound:
		sfx_player.stream = test_sound
		
	if not is_instance_valid(ConfigManager): return

	# 1. Volume
	var vol = ConfigManager.get_setting("volume")
	# Don't trigger sound on init
	volume_slider.set_value_no_signal((vol if vol != null else 0.8) * 100.0)
	
	# 2. Resolution (PC Only)
	if not OS.has_feature("mobile") and not OS.has_feature("web"):
		for res in RESOLUTIONS: resolution_opt.add_item(res)
		
		var curr = ConfigManager.get_setting("resolution")
		if curr:
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

	# Connect Signals
	volume_slider.value_changed.connect(_on_volume)
	resolution_opt.item_selected.connect(_on_resolution)
	fullscreen_chk.toggled.connect(_on_fullscreen)
	diff_opt.item_selected.connect(_on_difficulty)
	btn_back.pressed.connect(_on_back)

func _on_volume(val):
	var linear = val / 100.0
	
	# Apply the same 2x Boost
	var db = linear_to_db(linear * 24.0)
	
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)
	ConfigManager.set_setting("volume", linear)
	
	# Play Test Sound (With Cooldown)
	var now = Time.get_ticks_msec()
	if sfx_player.stream and (now - last_sound_time > SOUND_COOLDOWN_MS):
		sfx_player.play()
		last_sound_time = now

func _on_resolution(idx):
	var parts = resolution_opt.get_item_text(idx).split("x")
	var sizes = Vector2i(int(parts[0]), int(parts[1]))
	DisplayServer.window_set_size(sizes)
	ConfigManager.set_setting("resolution", sizes)

func _on_fullscreen(toggled):
	# Don't change DisplayServer directly here. 
	# Let ConfigManager handle it so it saves AND applies correctly.
	ConfigManager.set_setting("fullscreen", toggled)

func _on_difficulty(idx):
	ConfigManager.set_setting("difficulty", diff_opt.get_item_text(idx))

func _on_back():
	ConfigManager.save_config()
	visible = false
	
	var start = get_node_or_null("/root/Main/SafeAreaRoot/StartMenu")
	if start: start.visible = true
	
