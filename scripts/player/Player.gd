extends CharacterBody2D
class_name Player

# --- Configuration ---
const SPEED = 400.0
const JUMP_VELOCITY = -600.0
const ACCELERATION = 1200.0
const FRICTION = 1000.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# State
var input_direction: Vector2 = Vector2.ZERO

func _physics_process(delta):
	# 1. Apply Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. Handle Movement (Left/Right) based on Joystick Input
	# We only use the X component of the joystick for a platformer
	if input_direction.x != 0:
		# Accelerate towards the input direction
		velocity.x = move_toward(velocity.x, input_direction.x * SPEED, ACCELERATION * delta)
	else:
		# Decelerate (Friction) when no input
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

	# 3. Apply Movement
	move_and_slide()

# --- Input Receivers (Connected via Level1.gd) ---

## Called when the HUD Joystick moves
func set_joystick_input(vec: Vector2):
	input_direction = vec
	
	# Optional: Flip sprite based on direction
	if vec.x < 0:
		$Sprite2D.flip_h = true
	elif vec.x > 0:
		$Sprite2D.flip_h = false

## Called when the HUD Jump button is pressed
func jump():
	if is_on_floor():
		velocity.y = JUMP_VELOCITY

## Called when the HUD Attack button is pressed
func attack():
	print("Player Attack Initiated!")
	# Here you would play an animation, e.g.:
	# $AnimationPlayer.play("attack")