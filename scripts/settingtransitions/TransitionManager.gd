extends CanvasLayer
class_name SceneTransitionManager

# --- Node References ---
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var fade_rect: ColorRect = $TransitionRect # Assuming this is used for visual effects
var audio_tween: Tween # Declared, will be initialized in the fade methods

# --- Lifecycle ---

func _ready():
	# If this node handles a screen overlay, initialize its state.
	fade_rect.visible = true
	fade_rect.modulate.a = 1.0
	# Remove audio_tween = create_tween() as it's redundant and immediately overwritten.

## Plays a visual transition animation and handles audio fading.
## @param name: The name of the animation in the AnimationPlayer.
## @param fade_audio: Whether to fade audio down/up during the transition.
## @param duration: The duration for the audio fade.
func play(name: String, fade_audio := true, duration := 1.0) -> void:
	# Ensure the animation player has the requested animation
	if not anim.has_animation(name):
		push_error("AnimationPlayer does not contain animation: %s" % name)
		return
		
	# 1. Start audio fade-out (runs concurrently)
	if fade_audio:
		_fade_audio_out(duration)
		
	# 2. Play the visual animation
	anim.play(name)
	
	# 3. Wait for the animation to finish
	await anim.animation_finished
	
	# 4. Start audio fade-in
	if fade_audio:
		# Wait for the audio fade-in to complete before returning 
		# (ensures audio is back up before the next scene starts playing sound)
		await _fade_audio_in(duration)

## Fades the master audio bus volume down to silence (-40dB).
func _fade_audio_out(duration: float) -> void:
	var bus: int = AudioServer.get_bus_index("Master")
	var current_db: float = AudioServer.get_bus_volume_db(bus)
	
	# Kill existing tween if running
	if is_instance_valid(audio_tween):
		audio_tween.kill()
		
	audio_tween = create_tween()
	
	# Use tween_method to smoothly transition the volume
	audio_tween.tween_method(
		Callable(AudioServer, "set_bus_volume_db").bind(bus), 
		current_db, 
		-40.0, 
		duration
	)

## Fades the master audio bus volume back up to the saved user setting.
func _fade_audio_in(duration: float) -> Tween: # Returns the tween object for awaiting
	var bus: int = AudioServer.get_bus_index("Master")
	
	# ⚠️ CRITICAL FIX 1: Use the flat key "volume_db" from ConfigManager
	var target_db: float = ConfigManager.get_setting("volume_db")
	# Fallback if the setting is not loaded or missing
	if target_db == null:
		target_db = linear_to_db(0.8) # Default volume
		
	# Kill existing tween if running
	if is_instance_valid(audio_tween):
		audio_tween.kill()
		
	audio_tween = create_tween()
	
	# Use tween_method to smoothly transition the volume
	audio_tween.tween_method(
		Callable(AudioServer, "set_bus_volume_db").bind(bus), 
		-40.0, 
		target_db, 
		duration
	)
	
	return audio_tween # Return the tween so the caller can await it
