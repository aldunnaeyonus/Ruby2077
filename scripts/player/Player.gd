extends CharacterBody2D
class_name Player

# --- CONFIGURATION ---
const SPEED = 300.0
const JUMP_VELOCITY = -450.0
const ACCELERATION = 1500.0
const FRICTION = 1200.0
const MAX_JUMPS = 2

# Game Feel
const COYOTE_TIME = 0.1
const JUMP_BUFFER_TIME = 0.1

enum GameMode { PLATFORMER, TOP_DOWN }
@export var current_mode: GameMode = GameMode.PLATFORMER

# New: Choose your default weapon (matches animation names: "gun" or "knife")
@export_enum("knife", "gun") var equipped_weapon: String = "knife"

# --- NODES ---
@onready var sprite = $AnimatedSprite2D 
@onready var interaction_area = $InteractionArea 

# --- STATE ---
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var joystick_direction: Vector2 = Vector2.ZERO
var jump_count: int = 0

# Timers
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

# Actions Flags
var is_attacking: bool = false
var is_dead: bool = false

func _physics_process(delta):
	# 1. ALWAYS Apply Gravity in Platformer Mode (even if dead/attacking)
	if current_mode == GameMode.PLATFORMER and not is_on_floor():
		velocity.y += gravity * delta

	# 2. Dead State: Disable all input and movement logic
	if is_dead:
		move_and_slide()
		return

	# 3. Attack State: Lock movement inputs while attacking
	if is_attacking:
		# Apply friction so player slides to a stop while attacking
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		move_and_slide()
		return

	# 4. Handle Timers
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta

	# 5. Normal Movement Logic
	match current_mode:
		GameMode.PLATFORMER:
			_handle_platformer_movement(delta)
		GameMode.TOP_DOWN:
			_handle_top_down_movement(delta)

	move_and_slide()
	
	# PC Inputs
	if Input.is_action_just_pressed("ui_accept"):
		jump()
	if Input.is_action_just_pressed("ui_focus_next"):
		interact()
	if Input.is_key_pressed(KEY_Q): 
		# Use is_key_pressed with a debouncer or is_action_just_pressed if you map it
		if not is_attacking: # Don't swap mid-attack!
			swap_weapon()
			
# --- MOVEMENT HANDLERS ---

func _handle_platformer_movement(delta):
	# Coyote Time Logic
	if not is_on_floor():
		coyote_timer -= delta
	else:
		jump_count = 0
		coyote_timer = COYOTE_TIME 

	# Jump Buffer Execution
	if jump_buffer_timer > 0 and (is_on_floor() or (coyote_timer > 0 and jump_count == 0) or jump_count < MAX_JUMPS):
		_perform_jump()

	# Horizontal Movement
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
		
	# Vertical Animations
	if not is_on_floor():
		_play_anim("jump" if velocity.y < 0 else "fall")

func _handle_top_down_movement(delta):
	var input_vector = joystick_direction
	if input_vector == Vector2.ZERO:
		input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if input_vector.length() > 0:
		velocity = velocity.move_toward(input_vector.normalized() * SPEED, ACCELERATION * delta)
		if sprite:
			sprite.flip_h = input_vector.x < 0
			_play_anim("run")
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		_play_anim("idle")

# --- ACTION METHODS ---

func set_joystick_input(vec: Vector2):
	joystick_direction = vec

func jump():
	if current_mode == GameMode.PLATFORMER and not is_dead and not is_attacking:
		jump_buffer_timer = JUMP_BUFFER_TIME

func _perform_jump():
	velocity.y = JUMP_VELOCITY
	jump_buffer_timer = 0.0
	
	if not is_on_floor() and jump_count == 0:
		jump_count = 1 
	else:
		jump_count += 1

func attack():
	# Prevent spamming or attacking while dead
	if is_attacking or is_dead:
		return
		
	is_attacking = true
	
	# Play the animation for the current weapon ("knife" or "gun")
	_play_anim(equipped_weapon)
	
	# Wait for animation to finish before returning control
	if sprite:
		await sprite.animation_finished
		
	is_attacking = false
	# The physics process will automatically pick up 'idle' or 'run' next frame

func die():
	if is_dead: return
	
	is_dead = true
	velocity = Vector2.ZERO # Stop immediately
	_play_anim("die")
	
	# Optional: Emit signal to GameState or Level to handle game over
	print("Player Died")

func interact():
	if is_dead or is_attacking: return
	
	if interaction_area:
		var areas = interaction_area.get_overlapping_areas()
		for area in areas:
			if area.has_method("on_interact"):
				area.on_interact()
				return

# --- HELPER ---

func _play_anim(anim_name: String):
	if sprite and sprite.animation != anim_name:
		# Safety check: Ensure the animation exists in the SpriteFrames
		if sprite.sprite_frames.has_animation(anim_name):
			sprite.play(anim_name)
		else:
			push_warning("Missing animation: %s" % anim_name)
			
func swap_weapon():
	if equipped_weapon == "knife":
		equipped_weapon = "gun"
	else:
		equipped_weapon = "knife"
	
	print("Switched weapon to: %s" % equipped_weapon)
	
