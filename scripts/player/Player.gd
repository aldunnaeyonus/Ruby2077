extends CharacterBody2D
class_name Player

# --- CONFIGURATION ---
const SPEED = 300.0
const JUMP_VELOCITY = -300.0
const ACCELERATION = 1500.0
const FRICTION = 3000.0
const MAX_JUMPS = 2
const COYOTE_TIME = 0.1
const JUMP_BUFFER_TIME = 0.1

enum GameMode { PLATFORMER, TOP_DOWN }
@export var current_mode: GameMode = GameMode.PLATFORMER

# --- WEAPON SETTINGS ---
@export_enum("knife", "gun") var equipped_weapon: String = "knife"
@export var bullet_scene: PackedScene = preload("res://scripts/player/Bullet.tscn")

# --- SOUND EFFECTS ---
@export var sfx_shoot: AudioStream
@export var sfx_empty: AudioStream
@export var sfx_reload: AudioStream
@export var sfx_slash: AudioStream # <--- NEW: Knife Swing Sound

# --- STATE ---
var max_ammo: int = 10
var current_ammo: int = 10
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var joystick_direction: Vector2 = Vector2.ZERO
var jump_count: int = 0
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var is_attacking: bool = false
var is_dead: bool = false

# --- NODES ---
@onready var sprite = $AnimatedSprite2D 
@onready var interaction_area = $InteractionArea 
@onready var hitbox_col = $Hitbox/CollisionShape2D
@onready var muzzle = $Muzzle
@onready var sfx_player = $SFXPlayer
@onready var muzzle_flash = $Muzzle/MuzzleFlash

# --- SIGNALS ---
signal ammo_changed(current: int, max_val: int)

func _ready():
	if is_instance_valid(GameState):
		current_ammo = GameState.current_ammo
	
	ammo_changed.emit(current_ammo, max_ammo)
	
	sprite.frame_changed.connect(_on_frame_changed)
	if has_node("Hitbox"):
		$Hitbox.body_entered.connect(_on_hitbox_body_entered)

func _physics_process(delta):
	if current_mode == GameMode.PLATFORMER and not is_on_floor():
		velocity.y += gravity * delta

	if is_dead:
		move_and_slide()
		return

	if is_attacking:
		if equipped_weapon == "knife":
			velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
			move_and_slide()
			return 

	if jump_buffer_timer > 0: jump_buffer_timer -= delta

	match current_mode:
		GameMode.PLATFORMER: _handle_platformer_movement(delta)
		GameMode.TOP_DOWN: _handle_top_down_movement(delta)

	move_and_slide()
	
	if Input.is_action_just_pressed("ui_accept"): jump()
	if Input.is_action_just_pressed("ui_focus_next"): interact()

func _handle_platformer_movement(delta):
	if not is_on_floor():
		coyote_timer -= delta
	else:
		jump_count = 0
		coyote_timer = COYOTE_TIME 

	if jump_buffer_timer > 0 and (is_on_floor() or (coyote_timer > 0 and jump_count == 0) or jump_count < MAX_JUMPS):
		_perform_jump()

	var input_x = joystick_direction.x
	if input_x == 0: input_x = Input.get_axis("ui_left", "ui_right")
	
	if is_on_floor():
		if input_x != 0:
			velocity.x = move_toward(velocity.x, input_x * SPEED, ACCELERATION * delta)
			
			# UPDATE FACING HERE
			_update_facing_direction(input_x < 0)
			
			if not is_attacking: _play_anim("run")
		else:
			velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
			if not is_attacking: _play_anim("idle")
	else:
		if not is_attacking:
			_play_anim("jump" if velocity.y < 0 else "fall")
			
func _update_facing_direction(is_left: bool):
	if not sprite or not muzzle: return
	
	# 1. Flip Sprite
	sprite.flip_h = is_left
	
	# 2. Flip Muzzle Position & Flash
	if is_left:
		muzzle.position.x = -abs(muzzle.position.x) # Move to Left
		muzzle.scale.x = -1 # Flip the flash sprite itself
	else:
		muzzle.position.x = abs(muzzle.position.x) # Move to Right
		muzzle.scale.x = 1 # Normal flash
		
func _handle_top_down_movement(delta):
	var input_vector = joystick_direction
	if input_vector == Vector2.ZERO:
		input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if input_vector.length() > 0:
		velocity = velocity.move_toward(input_vector.normalized() * SPEED, ACCELERATION * delta)
		
		# UPDATE FACING HERE
		if input_vector.x != 0:
			_update_facing_direction(input_vector.x < 0)
			
		if not is_attacking: _play_anim("run")
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		if not is_attacking: _play_anim("idle")

func attack():
	if is_attacking or is_dead: return
	
	is_attacking = true
	
	var cooldown = 0.6 
	
	if equipped_weapon == "gun":
		var fired = _fire_bullet()
		if fired:
			cooldown = 0.15 
			if sprite:
				sprite.stop()
				sprite.play("gun")
		else:
			cooldown = 0.2
	else:
		# KNIFE LOGIC
		_play_anim(equipped_weapon)
		
		# PLAY SLASH SOUND (NEW)
		if sfx_player and sfx_slash:
			sfx_player.stream = sfx_slash
			sfx_player.play()
	
	get_tree().create_timer(cooldown).timeout.connect(func(): is_attacking = false)

func _fire_bullet() -> bool:
	if current_ammo > 0:
		current_ammo -= 1
		if is_instance_valid(GameState): GameState.current_ammo = current_ammo
		ammo_changed.emit(current_ammo, max_ammo)
		
		# Muzzle Flash (Now appears on correct side!)
		if muzzle_flash:
			muzzle_flash.visible = true
			get_tree().create_timer(0.05).timeout.connect(func(): muzzle_flash.visible = false)

		if sfx_player and sfx_shoot:
			sfx_player.stream = sfx_shoot
			sfx_player.play()
		
		if bullet_scene:
			var bullet = bullet_scene.instantiate()
			
			# Calculate direction based on sprite flip
			var is_left = sprite.flip_h
			
			if is_left:
				bullet.direction = Vector2.LEFT
				bullet.rotation_degrees = 180 # ROTATE BULLET LEFT
			else:
				bullet.direction = Vector2.RIGHT
				bullet.rotation_degrees = 0   # ROTATE BULLET RIGHT
			
			# Muzzle position is already updated by our helper, so just use it
			bullet.position = position + muzzle.position
			get_parent().add_child(bullet)
		return true
	else:
		print("Click!")
		if sfx_player and sfx_empty:
			sfx_player.stream = sfx_empty
			sfx_player.play()
		return false

func reload():
	current_ammo = max_ammo
	if is_instance_valid(GameState): GameState.current_ammo = current_ammo
	ammo_changed.emit(current_ammo, max_ammo)
	print("Reloaded!")
	
	if sfx_player and sfx_reload:
		sfx_player.stream = sfx_reload
		sfx_player.play()

func equip_weapon(weapon_name: String):
	if weapon_name in ["knife", "gun"]:
		equipped_weapon = weapon_name
		print("Equipped: ", equipped_weapon)

func set_joystick_input(vec: Vector2): joystick_direction = vec

func jump():
	if current_mode == GameMode.PLATFORMER and not is_dead:
		jump_buffer_timer = JUMP_BUFFER_TIME

func _perform_jump():
	velocity.y = JUMP_VELOCITY
	jump_buffer_timer = 0.0
	jump_count += 1 if (is_on_floor() or coyote_timer > 0) else 1

func interact():
	if interaction_area:
		var areas = interaction_area.get_overlapping_areas()
		for area in areas:
			if area.has_method("on_interact"):
				area.on_interact()
				return

func _on_frame_changed():
	if sprite.animation == "knife":
		if sprite.frame == 3:
			hitbox_col.set_deferred("disabled", false)
		else:
			hitbox_col.set_deferred("disabled", true)

func _on_hitbox_body_entered(body):
	if body.has_method("take_damage"): body.take_damage(10)

func _play_anim(anim_name: String):
	if sprite and sprite.sprite_frames.has_animation(anim_name):
		if sprite.animation != anim_name:
			sprite.play(anim_name)
			
