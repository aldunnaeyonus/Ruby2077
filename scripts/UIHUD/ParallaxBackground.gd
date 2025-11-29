extends ParallaxBackground
class_name DynamicBackground

# --- Configuration: DAY ---
@export_group("Day Textures")
@export var day_farthest: Texture2D
@export var day_middle: Texture2D
@export var day_closest: Texture2D
@export var day_sky: Texture2D

# --- Configuration: NIGHT ---
@export_group("Night Textures")
@export var night_farthest: Texture2D
@export var night_middle: Texture2D
@export var night_closest: Texture2D
@export var night_sky: Texture2D

# --- Nodes ---
# Uses get_node_or_null so the game doesn't crash if you haven't added the Sky layer yet
@onready var tex_0 = $Layer0_Farthest/Texture0
@onready var tex_1 = $Layer1_Middle/Texture1
@onready var tex_2 = $Layer2_Closest/Texture2
@onready var tex_sky = get_node_or_null("LayerSky/Sky") 

func _ready():
	# 1. Connect to Global Time System
	if is_instance_valid(GameState):
		GameState.time_changed.connect(_on_time_changed)
		# Apply correct look immediately on load
		_on_time_changed(GameState.is_night)
	else:
		# Fallback if no GameState (Default to Day)
		_on_time_changed(false)

func _on_time_changed(is_night: bool):
	if is_night:
		_apply_textures(night_farthest, night_middle, night_closest, night_sky)
	else:
		_apply_textures(day_farthest, day_middle, day_closest, day_sky)

func _apply_textures(far, mid, close, sky):
	# Only update if the texture is assigned in Inspector to prevent blank screens
	if far: tex_0.texture = far
	if mid: tex_1.texture = mid
	if close: tex_2.texture = close
	if sky and tex_sky: tex_sky.texture = sky
