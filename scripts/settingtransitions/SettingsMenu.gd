extends Control
class_name SettingsMenuUI

# --- NODES (Updated for Tab Layout) ---
@onready var tabs = $CenterContainer/PanelContainer/InternalPadding/MainVBox/TabContainer
@onready var general_opts = tabs.get_node("General/OptionsList")
@onready var volume_slider = general_opts.get_node("HBoxVolume/VolumeSlider")
@onready var resolution_opt = general_opts.get_node("HBoxRes/ResolutionOption")
@onready var fullscreen_chk = general_opts.get_node("CheckBoxFullscreen")
@onready var diff_opt = general_opts.get_node("HBoxDiff/DifficultyOption")
@onready var btn_back = $CenterContainer/PanelContainer/InternalPadding/MainVBox/Header/ButtonBack
@onready var sfx_player = $VolumeTestSFX
@onready var controls_container = tabs.get_node("Controls/ScrollContainer/ControlsList")

# --- CONFIG ---
@export var test_sound: AudioStream 

const RESOLUTIONS = ["1280x720", "1920x1080", "2560x1440"]
const DIFFICULTIES = ["Easy", "Normal", "Hard"]

# --- STATE ---
var last_sound_time: int = 0
const SOUND_COOLDOWN_MS: int = 100

func _ready():
	if test_sound: sfx_player.stream = test_sound
	
	if is_instance_valid(ConfigManager):
		# 1. Volume
		var vol = ConfigManager.get_setting("volume")
		volume_slider.set_value_no_signal((vol if vol != null else 0.8) * 100.0)
		
		# 2. Resolution
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

		# 3. Fullscreen & Difficulty
		fullscreen_chk.button_pressed = ConfigManager.get_setting("fullscreen") == true
		
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
	
	# GENERATE CONTROLS LIST
	_populate_controls_list()

func _populate_controls_list():
	if not controls_container: return
	
	for child in controls_container.get_children():
		child.queue_free()
		
	# Define which actions to show user
	var display_map = {
		"ui_left": "Move Left",
		"ui_right": "Move Right",
		"ui_up": "Climb Up",
		"ui_down": "Climb Down",
		"jump": "Jump",
		"attack": "Attack / Fire",
		"reload": "Reload",
		"swap_weapon": "Switch Weapon",
		"ui_focus_next": "Interact",
		"journal_toggle": "Open Journal" # Ensure you add this to Input Map
	}
	
	for action in display_map:
		if InputMap.has_action(action):
			var events = InputMap.action_get_events(action)
			if events.size() > 0:
				# Find the first Keyboard event to display
				var key_text = ""
				for e in events:
					if e is InputEventKey:
						key_text = OS.get_keycode_string(e.physical_keycode)
						break
					if e is InputEventMouseButton:
						key_text = "Mouse Btn " + str(e.button_index)
						break
				
				if key_text == "": key_text = "Not Bound"
				
				# Create Row
				var hbox = HBoxContainer.new()
				var lbl_action = Label.new()
				lbl_action.text = display_map[action]
				lbl_action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				
				var lbl_key = Label.new()
				lbl_key.text = "[ " + key_text + " ]"
				lbl_key.add_theme_color_override("font_color", Color(1, 0.8, 0.4))
				
				hbox.add_child(lbl_action)
				hbox.add_child(lbl_key)
				controls_container.add_child(hbox)

# --- HANDLERS ---

func _on_volume(val):
	var linear = val / 100.0
	var db = linear_to_db(linear * 2.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)
	ConfigManager.set_setting("volume", linear)
	
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
	ConfigManager.set_setting("fullscreen", toggled)

func _on_difficulty(idx):
	ConfigManager.set_setting("difficulty", diff_opt.get_item_text(idx))

func _on_back():
	ConfigManager.save_config()
	visible = false
	var start = get_node_or_null("/root/Main/SafeAreaRoot/StartMenu")
	if start: start.visible = true
	
