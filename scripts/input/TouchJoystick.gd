extends CanvasLayer
class_name VirtualJoystick # Good practice to give it a class_name

# --- Node References ---
@onready var base = $JoystickBase
@onready var knob = $JoystickBase/JoystickKnob

# --- Configuration ---
@export var radius := 80.0
@export var snap_back_speed := 15.0 # For smooth return (optional, but nice)

# --- Internal State ---
var dragging := false
var touch_index := -1 # Stores the index of the finger controlling the joystick
var origin := Vector2.ZERO
var current_vector := Vector2.ZERO

# --- Signals ---
signal joystick_vector_changed(vec: Vector2) # Emits a normalized vector (magnitude 0 to 1)

# --- Lifecycle ---

func _ready():
	# Calculate the center point of the base control node
	origin = base.position + base.size * 0.5
	# Initial knob position to center
	knob.position = origin - knob.size * 0.5


# --- Input Handling (Multi-Touch Fix) ---

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			# Start of Touch: Check if touch is within the base control's area
			if base.get_global_rect().has_point(event.position) and not dragging:
				dragging = true
				touch_index = event.index # Store the touch index
				_update_knob(event.position)
		
		elif not event.pressed:
			# End of Touch: Check if this is the finger that was dragging the joystick
			if dragging and event.index == touch_index:
				dragging = false
				touch_index = -1
				
				# Reset state immediately or use a tween for smooth return
				_reset_knob()
				
	elif event is InputEventScreenDrag:
		# Drag Event: Only respond if we are currently dragging AND the touch index matches
		if dragging and event.index == touch_index:
			_update_knob(event.position)


# --- Core Logic ---

func _update_knob(pos: Vector2):
	# Calculate the direction vector from the origin to the touch position
	var dir = pos - origin
	
	# Clamp the vector length by the defined radius
	var clamped_dir = dir.limit_length(radius)
	
	# Set the knob position relative to the origin
	knob.position = origin + clamped_dir - knob.size * 0.5
	
	# Calculate the normalized vector (0.0 to 1.0)
	current_vector = clamped_dir / radius
	
	joystick_vector_changed.emit(current_vector)

func _reset_knob():
	current_vector = Vector2.ZERO
	# Use a Tween for a smooth snap-back effect (Better UI/UX)
	var tween = create_tween()
	tween.tween_property(knob, "position", origin - knob.size * 0.5, 1.0 / snap_back_speed)
	
	# Ensure the signal is emitted when the reset movement starts/ends
	joystick_vector_changed.emit(current_vector)
