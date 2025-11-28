extends CanvasLayer
class_name VirtualJoystick

# --- NODES ---
@onready var base = $JoystickBase
@onready var knob = $JoystickBase/JoystickKnob

# --- CONFIG ---
@export var radius := 80.0
@export var snap_back_speed := 20.0

# --- STATE ---
var dragging := false
var touch_index := -1
var default_knob_pos := Vector2.ZERO

signal joystick_vector_changed(vec: Vector2)

func _ready():
	# Calculate the center relative to the Base node (Local Space)
	default_knob_pos = base.size * 0.5 - knob.size * 0.5
	knob.position = default_knob_pos

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			# Check global rect for touch start
			if base.get_global_rect().has_point(event.position) and not dragging:
				dragging = true
				touch_index = event.index
				_update_knob(event.position)
		
		elif not event.pressed:
			if dragging and event.index == touch_index:
				dragging = false
				touch_index = -1
				_reset_knob()
				
	elif event is InputEventScreenDrag:
		if dragging and event.index == touch_index:
			_update_knob(event.position)

func _update_knob(global_touch_pos: Vector2):
	# 1. Convert Global Touch to Local Space of the Base
	var local_touch = base.get_global_transform().affine_inverse() * global_touch_pos
	
	# 2. Calculate vector from center (Radius check)
	var center = base.size * 0.5
	var dir = local_touch - center
	
	# 3. Clamp
	var clamped_dir = dir.limit_length(radius)
	
	# 4. Apply position (Center + Vector - Half Knob Size)
	knob.position = (center + clamped_dir) - (knob.size * 0.5)
	
	# 5. Emit normalized vector
	joystick_vector_changed.emit(clamped_dir / radius)

func _reset_knob():
	joystick_vector_changed.emit(Vector2.ZERO)
	var tween = create_tween()
	tween.tween_property(knob, "position", default_knob_pos, 1.0 / snap_back_speed)
