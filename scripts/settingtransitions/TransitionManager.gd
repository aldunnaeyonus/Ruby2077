extends CanvasLayer
class_name SceneTransitionManager

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var fade_rect: ColorRect = $FadeRect 
var audio_tween: Tween

func _ready():
	if fade_rect:
		fade_rect.visible = true
		fade_rect.modulate.a = 1.0

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
	
	# FIX: Safe fallback if ConfigManager returns null
	var target_db = ConfigManager.get_setting("volume_db")
	if target_db == null:
		target_db = 0.0 # Default to 0dB (Max volume)
		
	if is_instance_valid(audio_tween):
		audio_tween.kill()
	audio_tween = create_tween()
	
	audio_tween.tween_method(
		Callable(AudioServer, "set_bus_volume_db").bind(bus), 
		-40.0, float(target_db), duration
	)
	
	return audio_tween