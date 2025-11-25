extends CharacterBody2D
class_name Player

# --- Configuration ---
const SPEED = 300.0
const JUMP_VELOCITY = -350.0
const ACCELERATION = 1200.0
const FRICTION = 1000.0
const MAX_JUMPS = 2

# Define the Game Modes
enum GameMode { PLATFORMER, TOP_DOWN }

# Export this so you can set it in the Inspector for each Level
@export var current_mode: GameMode = GameMode.PLATFORMER

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# --- Nodes ---
@onready var sprite = $AnimatedSprite2D 
@onready var interaction_area = $InteractionArea 

# --- State ---
var joystick_direction: Vector2 = Vector2.ZERO
var jump_count: int = 0

func _physics_process(delta):
	match current_mode:
		GameMode.PLATFORMER:
			_handle_platformer_movement(delta)
		GameMode.TOP_DOWN:
			_handle_top_down_movement(delta)

	move_and_slide()
	
	# PC Controls
	if Input.is_action_just_pressed("ui_accept"):
		jump()
	if Input.is_action_just_pressed("ui_focus_next"):
		interact()

# --- Movement Logic ---

func _handle_platformer_movement(delta):
	# 1. Apply Gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		jump_count = 0

	# 2. Get Input (X only)
	var input_x = joystick_direction.x
	if input_x == 0:
		input_x = Input.get_axis("ui_left", "ui_right")

	# 3. Move
	if input_x != 0:
		velocity.x = move_toward(velocity.x, input_x * SPEED, ACCELERATION * delta)
		if sprite: sprite.flip_h = input_x < 0
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

func _handle_top_down_movement(delta):
	# 1. Get Input (X and Y)
	var input_vector = joystick_direction
	
	# Fallback to Keyboard if joystick is idle
	if input_vector == Vector2.ZERO:
		input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# 2. Move (No Gravity)
	if input_vector != Vector2.ZERO:
		velocity = velocity.move_toward(input_vector * SPEED, ACCELERATION * delta)
		
		# Handle Sprite Flipping
		if sprite and input_vector.x != 0:
			sprite.flip_h = input_vector.x < 0
			
		# Optional: Add Up/Down animation logic here
		# if input_vector.y < 0: sprite.play("walk_up")
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)

# --- Public Actions ---

func set_joystick_input(vec: Vector2):
	joystick_direction = vec

func jump():
	# Only allow jumping in Platformer Mode
	if current_mode == GameMode.PLATFORMER:
		if is_on_floor() or jump_count < MAX_JUMPS:
			velocity.y = JUMP_VELOCITY
			jump_count += 1

func attack():
	print("Player Attack Initiated!")
	# if sprite: sprite.play("attack")

func interact():
	if interaction_area:
		var areas = interaction_area.get_overlapping_areas()
		for area in areas:
			if area.has_method("on_interact"):
				area.on_interact()
				return
