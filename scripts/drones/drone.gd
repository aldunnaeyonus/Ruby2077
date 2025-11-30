extends CharacterBody2D

# --- CONFIGURATION ---
@export var speed: float = 100.0
@export var leave_speed: float = 250.0 # Faster when flying away
@export var roam_range: float = 150.0 # How far it moves in one roam step
@export var behavior_cycles_before_leaving: int = 5 # How many times it roams/waits before leaving

# --- STATE MANAGEMENT ---
enum State { IDLE, ROAM, LEAVING }
var current_state: State = State.IDLE
var cycles_completed: int = 0
var move_direction: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO

# --- NODES ---
@onready var sprite = $AnimatedSprite2D
@onready var timer = $DecisionTimer
@onready var screen_notifier = $VisibleOnScreenNotifier2D

func _ready():
	# Randomize the random number generator so drones behave differently
	randomize()
	
	# Connect Timer
	timer.timeout.connect(_on_decision_timer_timeout)
	
	# Connect Screen Exiter (to delete drone when it leaves)
	screen_notifier.screen_exited.connect(queue_free)
	
	# Start in Idle
	_enter_idle_state()

func _physics_process(delta):
	match current_state:
		State.IDLE:
			# Just hover (add floating effect here if desired)
			velocity = velocity.move_toward(Vector2.ZERO, 10.0)
			
		State.ROAM:
			# Move towards random target
			var direction = (target_position - global_position).normalized()
			velocity = direction * speed
			
			# Flip sprite based on direction
			if velocity.x != 0:
				sprite.flip_h = velocity.x < 0
				
			# If we are close enough to target, switch to idle early
			if global_position.distance_to(target_position) < 5.0:
				_enter_idle_state()

		State.LEAVING:
			# Fly straight in the exit direction
			velocity = move_direction * leave_speed
			if velocity.x != 0:
				sprite.flip_h = velocity.x < 0

	move_and_slide()

# --- STATE TRANSITIONS ---

func _on_decision_timer_timeout():
	# If we are already leaving, ignore the timer
	if current_state == State.LEAVING:
		return

	cycles_completed += 1
	
	# Check if it's time to fly away
	if cycles_completed >= behavior_cycles_before_leaving:
		_enter_leave_state()
	else:
		# 50/50 Chance to Roam or Idle
		if randf() > 0.5:
			_enter_roam_state()
		else:
			_enter_idle_state()

func _enter_idle_state():
	current_state = State.IDLE
	sprite.play("idle")
	# Wait 1 to 3 seconds
	timer.wait_time = randf_range(1.0, 3.0)
	timer.start()

func _enter_roam_state():
	current_state = State.ROAM
	sprite.play("walk")
	
	# Pick a random point nearby
	var random_offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * roam_range
	target_position = global_position + random_offset
	
	# Move for 2 to 4 seconds (or until reached)
	timer.wait_time = randf_range(2.0, 4.0)
	timer.start()

func _enter_leave_state():
	current_state = State.LEAVING
	sprite.play("walk")
	print("Drone flying away!")
	
	# Pick a random direction (Left, Right, or Up)
	# Vector2.UP is (0, -1), Vector2.LEFT is (-1, 0), etc.
	var exit_dirs = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2(-1, -1), Vector2(1, -1)]
	move_direction = exit_dirs.pick_random()
	
	# No need for timer anymore, it will fly until ScreenNotifier kills it
	timer.stop()
	
