extends CanvasLayer

# Define signals to bubble up to the main HUD
signal attack_requested
signal jump_requested
signal pause_requested

@onready var attack_button = $BottomRightContainer/AttackButton
@onready var jump_button = $BottomRightContainer/JumpButton
@onready var pause_button = $CornerPause

func _ready():
	# Connections are handled in the .tscn, we just need the callback functions
	pass

func _on_attack_pressed():
	attack_requested.emit()

func _on_jump_pressed():
	jump_requested.emit()

func _on_pause_pressed():
	pause_requested.emit()