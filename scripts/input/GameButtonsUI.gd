extends CanvasLayer

signal attack_requested
signal jump_requested
signal pause_requested
signal swap_requested


@onready var btn_attack = $BottomRightContainer/AttackButton
@onready var btn_jump = $BottomRightContainer/JumpButton
@onready var btn_pause = $CornerPause
@onready var btn_swap = $BottomCenterContainer/AttackButton

func _ready():
	# Connect if nodes exist (Safety check)
	if btn_attack: btn_attack.pressed.connect(func(): attack_requested.emit())
	if btn_jump: btn_jump.pressed.connect(func(): jump_requested.emit())
	if btn_pause: btn_pause.pressed.connect(func(): pause_requested.emit())
	if btn_swap: btn_swap.pressed.connect(func(): swap_requested.emit())
