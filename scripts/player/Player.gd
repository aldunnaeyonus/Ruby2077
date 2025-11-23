# scripts/player/Player.gd
extends CharacterBody2D
class_name Player

# --- Configuration ---
const SPEED = 400.0
const JUMP_VELOCITY = -600.0
const ACCELERATION = 1200.0
const FRICTION = 1000.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# --- State ---
var joystick_direction: Vector2 = Vector2.ZERO

# --- Nodes ---
# Ensure you add an Area2D named "InteractionArea" to your Player scene
# and give it a CollisionShape2D (e.g., a circle around the player).
@onready var interaction_area: Area2D = $InteractionArea 
@onready var sprite: Sprite2D = $Sprite2D

func _physics_process(delta):
	# 1. Apply Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. Handle Movement
	# Combine Keyboard (for testing) and Joystick (mobile)
	var input_x = joystick_direction.x
	if input_x == 0:
		input_x = Input.get_axis("ui_left", "ui_right")

	if input_x != 0:
		velocity.x = move_toward(velocity.x, input_x * SPEED, ACCELERATION * delta)
		# Flip Sprite
		sprite.flip_h = input_x < 0
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

	move_and_slide()
	
	# Keyboard Jump/Interact for debugging
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		jump()
	if Input.is_action_just_pressed("ui_focus_next"): # Map 'E' or similar to this
		interact()

# --- Public Actions (Called by HUD) ---

func set_joystick_input(vec: Vector2):
	joystick_direction = vec

func jump():
	if is_on_floor():
		velocity.y = JUMP_VELOCITY

func attack():
	print("Player Attack Initiated!")
	# $AnimationPlayer.play("attack")

func interact():
	if not interaction_area:
		return
		
	# Get all overlapping areas (NPCs, Chests, Items)
	var areas = interaction_area.get_overlapping_areas()
	
	for area in areas:
		# Check if the object has an interaction method
		if area.has_method("on_interact"):
			area.on_interact()
			return # Only interact with one object at a time
		
		# Alternatively, check parent if the Area2D is just a detector
		var parent = area.get_parent()
		if parent.has_method("on_interact"):
			parent.on_interact()
			return