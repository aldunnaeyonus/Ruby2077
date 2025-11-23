extends CanvasLayer

# Define signals to bubble up to the main HUD
signal attack_requested
signal jump_requested
signal pause_requested

@onready var attack_button = $BottomRightContainer/AttackButton
@onready var jump_button = $BottomRightContainer/JumpButton
@onready var pause_button = $CornerPause

func _ready():
	# Connect the texture buttons to our internal signal emitters
	if attack_button:
		attack_button.pressed.connect(func(): attack_requested.emit())
	if jump_button:
		jump_button.pressed.connect(func(): jump_requested.emit())
	if pause_button:
		pause_button.pressed.connect(func(): pause_requested.emit())
		