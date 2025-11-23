extends CanvasLayer

@onready var attack_button = $BottomRightContainer/AttackButton
@onready var jump_button = $BottomRightContainer/JumpButton
@onready var pause_button = $CornerPause
var player: Node = null

func set_player(p):
	player = p
	
func _ready():
	# REDUNDANT CONNECTIONS REMOVED
	# The connections are already handled in the .tscn file.
	pass

func _on_attack_pressed():
	print("Attack triggered")
	if player and player.has_method("attack"):
		player.attack()

func _on_jump_pressed():
	print("Jump triggered")
	if player and player.has_method("jump"):
		player.jump()

func _on_pause_pressed():
	print("Game paused")
	get_tree().paused = not get_tree().paused