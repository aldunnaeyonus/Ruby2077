# scripts/ConfigManager.gd
extends Node

const CONFIG_PATH := "user://config.cfg"
const SECTION := "preferences"

# --- Flat Settings Structure for reliable ConfigFile serialization ---
var settings := {
	"resolution": Vector2i(1920, 1080),
	"fullscreen": false,           # Video fullscreen state
	"volume": 0.8,                 # Linear volume (0.0 to 1.0)
	"gestures_enabled": true,
	"difficulty": "normal",        # Added "difficulty" to match apply_settings
}

# --- Internal Variables ---
var volume_db: float = -2.0 # Internal cache for volume in dB

func _ready():
	load_config()

## Loads settings from the config file and updates the internal dictionary.
func load_config():
	var config = ConfigFile.new()
	# Check if loading the file was successful
	if config.load(CONFIG_PATH) == OK:
		for key in settings:
			if config.has_section_key(SECTION, key):
				# Load value, maintaining type safety where possible (e.g., Vector2i)
				var loaded_value = config.get_value(SECTION, key)
				
				# Godot saves Vector2i as a String in ConfigFile.
				# We must convert it back if the default type is Vector2i.
				if typeof(settings[key]) == TYPE_VECTOR2I and typeof(loaded_value) == TYPE_STRING:
					# Simple parsing logic (e.g., "(1920, 1080)")
					# ConfigFile usually handles simple types, but we guard this.
					pass # ConfigFile usually converts complex types (like Vector2i) automatically upon get_value, 
						 # but if not, custom parsing would be required here. We rely on ConfigFile's built-in type handling.
						 
				settings[key] = loaded_value
				
	apply_settings()

## Saves the current settings dictionary to the config file.
func save_config():
	var config = ConfigFile.new()
	for key in settings:
		# ConfigFile handles basic types, Vector2i, and arrays automatically.
		config.set_value(SECTION, key, settings[key])
	
	# The ConfigFile.save() function returns an error code (OK on success)
	var error = config.save(CONFIG_PATH)
	if error != OK:
		push_error("Failed to save configuration file: %s" % error)

## Applies the current settings to Godot's engine and subsystems.
func apply_settings():
	# --- Audio ---
	var volume = settings["volume"]
	# Use the globally available linear_to_db function (or Math.linear_to_db)
	volume_db = linear_to_db(volume) 
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), volume_db)

	# --- Video ---
	var resolution = settings["resolution"]
	var fullscreen = settings["fullscreen"]
	
	DisplayServer.window_set_size(resolution)
	
	# CRITICAL FIX: Correctly check the boolean and assign the Godot constant
	var window_mode = DisplayServer.WINDOW_MODE_WINDOWED
	if fullscreen:
		window_mode = DisplayServer.WINDOW_MODE_FULLSCREEN
	
	DisplayServer.window_set_mode(window_mode)

	# --- Gameplay (optional) ---
	var difficulty = settings["difficulty"]
	# Note: Changing ProjectSettings at runtime is often unnecessary for simple settings
	# and is better suited for global access via this Singleton.
	# If needed, this line updates a ProjectSetting value.
	ProjectSettings.set_setting("application/config/difficulty", difficulty)
	
## Sets a single setting, saves the config, and applies changes.
func set_setting(key: String, value):
	if settings.has(key):
		settings[key] = value
		save_config()
		apply_settings()
	else:
		push_error("Attempted to set non-existent setting key: %s" % key)

## Gets the value of a setting.
func get_setting(key: String):
	return settings.get(key, null)
