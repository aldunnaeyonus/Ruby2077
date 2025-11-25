extends Node

const CONFIG_PATH := "user://config.cfg"
const SECTION := "preferences"

var settings := {
	"resolution": Vector2i(1920, 1080),
	"fullscreen": false,
	"volume": 0.8,
	"gestures_enabled": true,
	"difficulty": "normal"
}

# Internal cache
var volume_db: float = -2.0

func _ready():
	load_config()

func load_config():
	var config = ConfigFile.new()
	if config.load(CONFIG_PATH) == OK:
		for key in settings:
			if config.has_section_key(SECTION, key):
				var loaded_value = config.get_value(SECTION, key)
				# Ensure Vector2i type safety
				if typeof(settings[key]) == TYPE_VECTOR2I and typeof(loaded_value) == TYPE_STRING:
					pass # ConfigFile usually handles this, but explicit parsing can be added if needed
				settings[key] = loaded_value
	apply_settings()

func save_config():
	var config = ConfigFile.new()
	for key in settings:
		config.set_value(SECTION, key, settings[key])
	config.save(CONFIG_PATH)

func apply_settings():
	# Audio
	var volume = settings["volume"]
	volume_db = linear_to_db(volume)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), volume_db)

	# Video
	var resolution = settings["resolution"]
	var fullscreen = settings["fullscreen"]
	DisplayServer.window_set_size(resolution)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)

	# Gameplay
	ProjectSettings.set_setting("application/config/difficulty", settings["difficulty"])

func set_setting(key: String, value):
	if settings.has(key):
		settings[key] = value
		save_config()
		apply_settings()

func get_setting(key: String):
	# FIX: Allow retrieving the calculated volume_db
	if key == "volume_db":
		return volume_db
	return settings.get(key, null)
