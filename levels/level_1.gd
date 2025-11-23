extends Node2D

@onready var hud = $UI/MobileHUD
# MAKE SURE YOU ADD A PLAYER NODE TO THE SCENE NAMED "Player"
@onready var player = $Player 

func _ready():
	if hud and player:
		# Connect HUD signals to Player methods
		hud.jump_pressed.connect(player.jump)
		hud.attack_pressed.connect(player.attack)
		hud.joystick_input.connect(player.set_joystick_input)
