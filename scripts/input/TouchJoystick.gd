extends CanvasLayer
class_name VirtualJoystick

@onready var base = $JoystickBase
@onready var knob = $JoystickBase/JoystickKnob

@export var radius := 80.0
@export var snap_back_speed := 15.0

var dragging := false
var touch_index := -1
var default_knob_pos := Vector2.ZERO

signal joystick_vector_changed(vec: Vector2)

func _ready():
	# Calculate the center in LOCAL coordinates of the base
	# If knob is a child of base, the center is simply half the base size
	default_knob_pos = base.size * 0.5 - knob.size * 0.5
	knob.position = default_knob_pos

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			# Check if touch is inside the base rect (Global check is safer for UI)
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
	# 1. Convert global touch to local space of the Base node
	var local_touch_pos = base.get_global_transform().affine_inverse() * global_touch_pos
	
	# 2. Calculate vector from center (base.size / 2)
	var center = base.size * 0.5
	var dir = local_touch_pos - center
	
	# 3. Clamp
	var clamped_dir = dir.limit_length(radius)
	
	# 4. Apply to Knob (centering the knob sprite)
	knob.position = (center + clamped_dir) - (knob.size * 0.5)
	
	# 5. Emit normalized vector
	joystick_vector_changed.emit(clamped_dir / radius)

func _reset_knob():
	joystick_vector_changed.emit(Vector2.ZERO)
	
	var tween = create_tween()
	# Return to the calculated default local position
	tween.tween_property(knob, "position", default_knob_pos, 1.0 / snap_back_speed)