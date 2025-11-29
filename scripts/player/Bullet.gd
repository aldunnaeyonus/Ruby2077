extends Area2D

@export var speed: int = 800
@export var damage: int = 25
var direction: Vector2 = Vector2.RIGHT

func _ready():
	# Delete when off screen
	if $VisibleOnScreenNotifier2D:
		$VisibleOnScreenNotifier2D.screen_exited.connect(queue_free)
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body is Player: return # Don't hit self
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
