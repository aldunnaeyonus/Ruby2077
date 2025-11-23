extends CanvasLayer
class_name SceneTransitionManager

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var fade_rect: ColorRect = $FadeRect 
var audio_tween: Tween

func _ready():
	if fade_rect:
		fade_rect.visible = true
		# CRITICAL FIX 1: Start transparent so we don't block the Startup Video
		fade_rect.modulate.a = 0.0 

func play(name: String, fade_audio := true, duration := 1.0) -> void:
	if not anim.has_animation(name):
		push_error("AnimationPlayer does not contain animation: %s" % name)
		return
		
	if fade_audio:
		_fade_audio_out(duration)
		
	anim.play(name)
	await anim.animation_finished
	
	if fade_audio:
		await _fade_audio_in(duration)

func _fade_audio_out(duration: float) -> void:
	var bus: int = AudioServer.get_bus_index("Master")
	var current_db: float = AudioServer.get_bus_volume_db(bus)
	
	if is_instance_valid(audio_tween):
		audio_tween.kill()
	audio_tween = create_tween()
	
	audio_tween.tween_method(
		Callable(AudioServer, "set_bus_volume_db").bind(bus), 
		current_db, -40.0, duration
	)

func _fade_audio_in(duration: float) -> Tween:
	var bus: int = AudioServer.get_bus_index("Master")
	
	# CRITICAL FIX 2: Match the key used in SettingsMenu ("volume")
	# and convert the linear 0-1 value to Decibels.
	var saved_linear = ConfigManager.get_setting("volume")
	
	if saved_linear == null:
		saved_linear = 1.0 # Default to Max (Linear 1.0 = 0dB)
		
	var target_db = linear_to_db(float(saved_linear))
		
	if is_instance_valid(audio_tween):
		audio_tween.kill()
	audio_tween = create_tween()
	
	audio_tween.tween_method(
		Callable(AudioServer, "set_bus_volume_db").bind(bus), 
		-40.0, target_db, duration
	)
	
	return audio_tween
