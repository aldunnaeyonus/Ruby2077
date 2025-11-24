extends CharacterBody2D
class_name Player

# --- Configuration ---
const SPEED = 300.0
const JUMP_VELOCITY = -350.0
const ACCELERATION = 1200.0
const FRICTION = 1000.0
const MAX_JUMPS = 2  # New: Maximum number of jumps allowed

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# --- Nodes ---
@onready var sprite = $AnimatedSprite2D 
@onready var interaction_area = $InteractionArea 

# --- State ---
var joystick_direction: Vector2 = Vector2.ZERO
var jump_count: int = 0  # New: Tracks current jumps

func _physics_process(delta):
	# 1. Apply Gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		# Reset jump count when we touch the ground
		jump_count = 0

	# 2. Handle Movement
	var input_x = joystick_direction.x
	
	if input_x == 0:
		input_x = Input.get_axis("ui_left", "ui_right")

	if input_x != 0:
		velocity.x = move_toward(velocity.x, input_x * SPEED, ACCELERATION * delta)
		if sprite:
			sprite.flip_h = input_x < 0
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

	move_and_slide()
	
	# PC Controls
	if Input.is_action_just_pressed("ui_accept"):
		jump()
	if Input.is_action_just_pressed("ui_focus_next"):
		interact()

# --- Public Actions ---

func set_joystick_input(vec: Vector2):
	joystick_direction = vec

func jump():
	# Allow jumping if we are on the floor OR have jumps remaining
	if is_on_floor() or jump_count < MAX_JUMPS:
		velocity.y = JUMP_VELOCITY
		jump_count += 1
		
		# Optional: Play jump sound or animation here
		# if sprite: sprite.play("jump")

func attack():
	print("Player Attack Initiated!")

func interact():
	if interaction_area:
		var areas = interaction_area.get_overlapping_areas()
		for area in areas:
			if area.has_method("on_interact"):
				area.on_interact()
				return
