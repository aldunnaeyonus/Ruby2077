extends CharacterBody2D
class_name Player

# --- CONFIGURATION ---
const SPEED = 300.0
const JUMP_VELOCITY = -450.0 # Increased slightly for snappier feel
const ACCELERATION = 1500.0
const FRICTION = 1200.0
const MAX_JUMPS = 2

# Game Feel Settings
const COYOTE_TIME = 0.1
const JUMP_BUFFER_TIME = 0.1

enum GameMode { PLATFORMER, TOP_DOWN }
@export var current_mode: GameMode = GameMode.PLATFORMER

# --- NODES ---
@onready var sprite = $AnimatedSprite2D 
@onready var interaction_area = $InteractionArea 

# --- STATE ---
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var joystick_direction: Vector2 = Vector2.ZERO
var jump_count: int = 0

# Timers (floats for efficiency)
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

func _physics_process(delta):
	# Handle Jump Buffer (decrements every frame)
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
		
	match current_mode:
		GameMode.PLATFORMER:
			_handle_platformer_movement(delta)
		GameMode.TOP_DOWN:
			_handle_top_down_movement(delta)

	move_and_slide()
	
	# PC/Manual Input Checks
	if Input.is_action_just_pressed("ui_accept"): # Map Spacebar/Button A
		jump()
	if Input.is_action_just_pressed("ui_focus_next"): # Map E/Button X
		interact()

# --- PLATFORMER LOGIC ---

func _handle_platformer_movement(delta):
	# 1. Gravity & Coyote Time
	if not is_on_floor():
		velocity.y += gravity * delta
		coyote_timer -= delta
	else:
		jump_count = 0
		coyote_timer = COYOTE_TIME # Reset coyote time when on floor

	# 2. Handle Jump Buffer Execution
	if jump_buffer_timer > 0 and (is_on_floor() or (coyote_timer > 0 and jump_count == 0) or jump_count < MAX_JUMPS):
		_perform_jump()

	# 3. Horizontal Movement
	# Prioritize Joystick, fallback to Keyboard
	var input_x = joystick_direction.x
	if input_x == 0:
		input_x = Input.get_axis("ui_left", "ui_right")

	if input_x != 0:
		velocity.x = move_toward(velocity.x, input_x * SPEED, ACCELERATION * delta)
		if sprite: 
			sprite.flip_h = input_x < 0
			if is_on_floor(): _play_anim("run")
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		if is_on_floor(): _play_anim("idle")
		
	if not is_on_floor():
		_play_anim("jump" if velocity.y < 0 else "fall")

# --- TOP-DOWN LOGIC ---

func _handle_top_down_movement(delta):
	var input_vector = joystick_direction
	if input_vector == Vector2.ZERO:
		input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# Normalize vector to prevent fast diagonal movement
	if input_vector.length() > 0:
		velocity = velocity.move_toward(input_vector.normalized() * SPEED, ACCELERATION * delta)
		if sprite: 
			sprite.flip_h = input_vector.x < 0
			_play_anim("run")
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		_play_anim("idle")

# --- ACTIONS ---

func set_joystick_input(vec: Vector2):
	joystick_direction = vec

func jump():
	# Instead of jumping immediately, we set the buffer.
	# The physics process handles the actual jump if conditions are met.
	if current_mode == GameMode.PLATFORMER:
		jump_buffer_timer = JUMP_BUFFER_TIME

func _perform_jump():
	velocity.y = JUMP_VELOCITY
	jump_buffer_timer = 0.0 # Consume buffer
	
	# If utilizing coyote time, treat it as the first jump
	if not is_on_floor() and jump_count == 0:
		jump_count = 1 
	else:
		jump_count += 1

func interact():
	if interaction_area:
		var areas = interaction_area.get_overlapping_areas()
		for area in areas:
			if area.has_method("on_interact"):
				area.on_interact()
				return

func _play_anim(anim_name: String):
	if sprite and sprite.animation != anim_name:
		sprite.play(anim_name)