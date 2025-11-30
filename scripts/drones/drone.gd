extends CharacterBody2D

# --- CONFIGURATION ---
@export var speed: float = 100.0
@export var leave_speed: float = 250.0 
@export var roam_range: float = 150.0 
@export var behavior_cycles_before_leaving: int = 5 
@export var return_delay: float = 5.0
@export var depth_scale: float = 0.6 
@export var depth_color: Color = Color(0.5, 0.5, 0.5, 1.0) # <--- NEW: Dark Grey for background

# --- STATE MANAGEMENT ---
enum State { IDLE, ROAM, LEAVING, OFF_SCREEN, RETURNING }
var current_state: State = State.IDLE
var cycles_completed: int = 0
var move_direction: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO
var start_position: Vector2 = Vector2.ZERO 

# --- NODES ---
@onready var sprite = $AnimatedSprite2D
@onready var timer = $DecisionTimer
@onready var screen_notifier = $VisibleOnScreenNotifier2D

func _ready():
	randomize()
	start_position = global_position
	
	timer.timeout.connect(_on_decision_timer_timeout)
	screen_notifier.screen_exited.connect(_on_screen_exited)
	
	_enter_idle_state()

func _physics_process(delta):
	match current_state:
		State.IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, 10.0)
			_constrain_height()
			
		State.ROAM:
			var direction = (target_position - global_position).normalized()
			velocity = direction * speed
			
			if velocity.x != 0: sprite.flip_h = velocity.x < 0
				
			if global_position.distance_to(target_position) < 5.0:
				_enter_idle_state()

		State.LEAVING:
			velocity = move_direction * leave_speed
			if velocity.x != 0: sprite.flip_h = velocity.x < 0

		State.OFF_SCREEN:
			velocity = Vector2.ZERO

		State.RETURNING:
			var direction = (start_position - global_position).normalized()
			velocity = direction * leave_speed
			if velocity.x != 0: sprite.flip_h = velocity.x < 0
			
			if global_position.distance_to(start_position) < 10.0:
				cycles_completed = 0
				_enter_idle_state()

	move_and_slide()

# --- HELPER: Height Constraint ---
func _constrain_height():
	var cam = get_viewport().get_camera_2d()
	if cam:
		var screen_center_y = cam.get_screen_center_position().y
		if global_position.y > screen_center_y:
			velocity.y = -50 
			
func _get_valid_roam_target() -> Vector2:
	for i in range(10):
		var random_offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * roam_range
		var potential_target = start_position + random_offset
		
		var cam = get_viewport().get_camera_2d()
		if cam:
			var screen_center_y = cam.get_screen_center_position().y
			if potential_target.y < screen_center_y:
				return potential_target 
		else:
			return potential_target 
			
	return start_position 

# --- STATE LOGIC ---

func _on_decision_timer_timeout():
	if current_state == State.OFF_SCREEN:
		_enter_returning_state()
		return

	if current_state in [State.LEAVING, State.RETURNING]:
		return

	cycles_completed += 1
	
	if cycles_completed >= behavior_cycles_before_leaving:
		_enter_leave_state()
	else:
		if randf() > 0.5:
			_enter_roam_state()
		else:
			_enter_idle_state()

func _enter_idle_state():
	current_state = State.IDLE
	sprite.play("idle")
	timer.wait_time = randf_range(1.0, 3.0)
	timer.start()

func _enter_roam_state():
	current_state = State.ROAM
	sprite.play("walk")
	target_position = _get_valid_roam_target() 
	timer.wait_time = randf_range(2.0, 4.0)
	timer.start()

func _enter_leave_state():
	current_state = State.LEAVING
	sprite.play("walk")
	
	# Create a tween that runs actions in PARALLEL (at the same time)
	var tween = create_tween()
	tween.set_parallel(true)
	
	# 1. Shrink Size
	tween.tween_property(self, "scale", Vector2(depth_scale, depth_scale), 1.0)
	
	# 2. Darken Color (Simulate distance/fog)
	tween.tween_property(self, "modulate", depth_color, 1.0)
	
	var exit_dirs = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2(-1, -1), Vector2(1, -1)]
	move_direction = exit_dirs.pick_random()
	
	timer.stop() 

func _on_screen_exited():
	if current_state == State.LEAVING:
		current_state = State.OFF_SCREEN
		timer.wait_time = return_delay
		timer.start()

func _enter_returning_state():
	print("Drone coming back!")
	current_state = State.RETURNING
	sprite.play("walk")
	# We do NOT reset scale or modulate here, so it stays "in the background"
	timer.stop()
	
