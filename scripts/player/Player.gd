extends CharacterBody2D
class_name Player

# --- CONFIGURATION ---
const SPEED = 300.0
const JUMP_VELOCITY = -300.0 # Increased for snappier jump
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
@export var sfx_slash: AudioStream 

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
var is_reloading: bool = false
var attempting_mouse_fire: bool = false

# --- OFFSET CONFIG ---
var muzzle_offsets = {
	"gun": Vector2(151.0, -39),
	"run_gun": Vector2(190, -18),
	"default": Vector2(151, -39)
}

# --- NODES ---
@onready var sprite = $AnimatedSprite2D 
@onready var interaction_area = $InteractionArea 
@onready var hitbox_col = $Hitbox/CollisionShape2D
@onready var muzzle = $Muzzle
@onready var sfx_player = $SFXPlayer
@onready var muzzle_flash = $Muzzle/MuzzleFlash

# --- SIGNALS ---
signal ammo_changed(current: int, max_val: int)
signal weapon_switched(weapon_name: String)

func _ready():
	if is_instance_valid(GameState):
		current_ammo = GameState.current_ammo
	ammo_changed.emit(current_ammo, max_ammo)
	sprite.frame_changed.connect(_on_frame_changed)
	if has_node("Hitbox"):
		$Hitbox.body_entered.connect(_on_hitbox_body_entered)

func _unhandled_input(event):
	# Using "attack" action from Input Map is safer than hardcoding Mouse Button
	if event.is_action_pressed("attack"):
		attempting_mouse_fire = true
	elif event.is_action_released("attack"):
		attempting_mouse_fire = false

func _physics_process(delta):
	# 1. Gravity
	if current_mode == GameMode.PLATFORMER and not is_on_floor():
		velocity.y += gravity * delta

	# 2. Block Input States
	if is_dead:
		move_and_slide()
		return

	if is_attacking and equipped_weapon == "knife":
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		move_and_slide()
		return 

	# 3. Timers
	if jump_buffer_timer > 0: jump_buffer_timer -= delta

	# 4. Movement
	match current_mode:
		GameMode.PLATFORMER: _handle_platformer_movement(delta)
		GameMode.TOP_DOWN: _handle_top_down_movement(delta)

	move_and_slide()
	
	# 5. Actions (Using Input Map)
	if Input.is_action_just_pressed("ui_accept"): jump() # Space
	if Input.is_action_just_pressed("ui_focus_next"): interact() # E / Tab
	if Input.is_action_just_pressed("reload"): reload() # R
	if Input.is_action_just_pressed("swap_weapon"): # Q
		equip_weapon("gun" if equipped_weapon == "knife" else "knife")
	
	# Auto-fire logic
	if attempting_mouse_fire:
		attack()

# --- MOVEMENT ---
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
			_update_facing_direction(input_x < 0)
			
			if is_attacking and equipped_weapon == "gun":
				_play_anim("run_gun")
			elif not is_attacking:
				_play_anim("run")
		else:
			velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
			if is_attacking and equipped_weapon == "gun":
				_play_anim("gun")
			elif not is_attacking:
				_play_anim("idle")
	else:
		if not is_attacking:
			_play_anim("jump" if velocity.y < 0 else "fall")

func _handle_top_down_movement(delta):
	var input_vector = joystick_direction
	if input_vector == Vector2.ZERO:
		input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if input_vector.length() > 0:
		velocity = velocity.move_toward(input_vector.normalized() * SPEED, ACCELERATION * delta)
		if input_vector.x != 0: _update_facing_direction(input_vector.x < 0)
		
		if is_attacking and equipped_weapon == "gun": _play_anim("run_gun")
		elif not is_attacking: _play_anim("run")
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		if is_attacking and equipped_weapon == "gun": _play_anim("gun")
		elif not is_attacking: _play_anim("idle")

# --- ACTIONS ---
func attack():
	if is_attacking or is_dead or is_reloading: return
	
	is_attacking = true
	var cooldown = 0.6 
	
	if equipped_weapon == "gun":
		var fired = _fire_bullet()
		if fired:
			cooldown = 0.15 
			if velocity.length() == 0:
				if sprite: sprite.stop(); sprite.play("gun")
		else:
			cooldown = 0.2
	else:
		_play_anim(equipped_weapon)
		if sfx_player and sfx_slash: sfx_player.stream = sfx_slash; sfx_player.play()
	
	get_tree().create_timer(cooldown).timeout.connect(func(): is_attacking = false)

func _fire_bullet() -> bool:
	if current_ammo > 0:
		current_ammo -= 1
		if is_instance_valid(GameState): GameState.current_ammo = current_ammo
		ammo_changed.emit(current_ammo, max_ammo)
		
		# Visuals
		if muzzle_flash:
			muzzle_flash.visible = true
			get_tree().create_timer(0.05).timeout.connect(func(): muzzle_flash.visible = false)

		# Sound
		if sfx_player and sfx_shoot:
			sfx_player.stream = sfx_shoot
			sfx_player.play()
		
		# Spawn Bullet
		if bullet_scene:
			var bullet = bullet_scene.instantiate()
			
			# 1. Add to Scene Root (Not as child of player!)
			get_tree().current_scene.add_child(bullet)
			
			# 2. Set Position: Use Global Position of Muzzle
			bullet.global_position = muzzle.global_position
			
			# 3. Set Direction: Check Sprite Flip manually
			# (We don't rely on muzzle scale/rotation because parent scale can mess it up)
			var is_left = sprite.flip_h
			if is_left:
				bullet.direction = Vector2.LEFT
				bullet.rotation_degrees = 180 
			else:
				bullet.direction = Vector2.RIGHT
				bullet.rotation_degrees = 0
			
		return true
	else:
		if sfx_player and sfx_empty:
			sfx_player.stream = sfx_empty
			sfx_player.play()
		return false

func reload():
	if is_reloading or current_ammo == max_ammo: return
	is_reloading = true
	
	if sfx_player and sfx_reload: sfx_player.stream = sfx_reload; sfx_player.play()
	await get_tree().create_timer(3.0).timeout
	
	current_ammo = max_ammo
	if is_instance_valid(GameState): GameState.current_ammo = current_ammo
	ammo_changed.emit(current_ammo, max_ammo)
	is_reloading = false

func equip_weapon(weapon_name: String):
	if weapon_name in ["knife", "gun"]:
		equipped_weapon = weapon_name
		weapon_switched.emit(weapon_name)

# --- HELPERS ---
func _update_facing_direction(is_left: bool):
	if not sprite: return
	sprite.flip_h = is_left
	_refresh_muzzle_transform()

func _refresh_muzzle_transform():
	if not sprite or not muzzle: return
	var target_pos = muzzle_offsets.get(sprite.animation, muzzle_offsets["default"])
	var is_left = sprite.flip_h
	
	muzzle.position.x = -abs(target_pos.x) if is_left else abs(target_pos.x)
	muzzle.position.y = target_pos.y
	muzzle.scale.x = -1 if is_left else 1

func _play_anim(anim: String):
	if sprite.sprite_frames.has_animation(anim) and sprite.animation != anim:
		sprite.play(anim)
		_refresh_muzzle_transform()

# --- INPUT RECEIVERS ---
func set_joystick_input(vec: Vector2): joystick_direction = vec
func jump(): if not is_dead: jump_buffer_timer = JUMP_BUFFER_TIME
func _perform_jump():
	velocity.y = JUMP_VELOCITY
	jump_buffer_timer = 0.0
	jump_count += 1
func interact():
	if interaction_area:
		for area in interaction_area.get_overlapping_areas():
			if area.has_method("on_interact"): area.on_interact(); return
func _on_frame_changed():
	if sprite.animation == "knife" and sprite.frame == 3: hitbox_col.set_deferred("disabled", false)
	else: hitbox_col.set_deferred("disabled", true)
func _on_hitbox_body_entered(body):
	if body.has_method("take_damage"): body.take_damage(10)
	
