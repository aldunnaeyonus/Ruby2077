extends CanvasLayer
class_name SceneTransitionManager

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var fade_rect: ColorRect = $FadeRect 
var audio_tween: Tween

func _ready():
	if fade_rect:
		fade_rect.visible = true
		fade_rect.modulate.a = 0.0 

func play(title: String, fade_audio := true, duration := 1.0) -> void:
	if not anim.has_animation(title):
		push_error("AnimationPlayer does not contain animation: %s" % title)
		return
		
	if fade_audio:
		_fade_audio_out(duration)
		
	anim.play(title)
	await anim.animation_finished
	
	if fade_audio:
		_fade_audio_in(duration)

func _fade_audio_out(duration: float) -> void:
	var bus: int = AudioServer.get_bus_index("Master")
	var current_db: float = AudioServer.get_bus_volume_db(bus)
	
	if is_instance_valid(audio_tween):
		audio_tween.kill()
	audio_tween = create_tween()
	
	# CRITICAL FIX: Use a lambda to pass arguments in the correct order
	# 'val' is the changing number from the tween (current_db -> -40.0)
	audio_tween.tween_method(
		func(val): AudioServer.set_bus_volume_db(bus, val),
		current_db, -40.0, duration
	)

func _fade_audio_in(duration: float) -> Tween:
	var bus: int = AudioServer.get_bus_index("Master")
	
	var saved_linear = ConfigManager.get_setting("volume")
	if saved_linear == null:
		saved_linear = 1.0
		
	var target_db = linear_to_db(float(saved_linear))
		
	if is_instance_valid(audio_tween):
		audio_tween.kill()
	audio_tween = create_tween()
	
	# CRITICAL FIX: Use a lambda here too
	audio_tween.tween_method(
		func(val): AudioServer.set_bus_volume_db(bus, val),
		-40.0, target_db, duration
	)
	
	return audio_tween
