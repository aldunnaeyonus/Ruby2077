extends Area2D

@export var speed: int = 800
@export var damage: int = 25
var direction: Vector2 = Vector2.RIGHT

func _ready():
	# Connect signals for collision and exiting screen
	body_entered.connect(_on_body_entered)
	$VisibleOnScreenNotifier2D.screen_exited.connect(queue_free)

func _physics_process(delta):
	# Move the bullet
	position += direction * speed * delta

func _on_body_entered(body):
	# Ignore the player (so you don't shoot yourself)
	if body is Player: return
	
	if body.has_method("take_damage"):
		body.take_damage(damage)
	
	# Destroy bullet on impact
	queue_free()
