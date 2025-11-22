@tool
@icon("res://assets/icons/level_bounds.svg")
class_name LevelBounds extends Node2D

# Use a setter function for the exported variable to automatically redraw.
@export_range(480, 2048, 32, "suffix:px") 
var width : int = 480:
	set(value):
		width = value
		queue_redraw()

# Use a setter function for the exported variable to automatically redraw.
@export_range(270, 2048, 32, "suffix:px") 
var height : int = 270:
	set(value):
		height = value
		queue_redraw()

func _ready() -> void:
	# Set a high z_index to ensure the bounds are drawn on top in the editor.
	z_index = 256
	
	if Engine.is_editor_hint():
		return

	# Declare the camera variable outside the loop so it's accessible afterwards.
	var camera : Camera2D = null
	
	# Wait until the camera is available, which is necessary if this node loads before the camera.
	# Using 'ready' is usually sufficient for a Camera2D that is a child of the Player or a main Scene.
	while not camera:
		# Use 'NOTIFICATION_WM_ABOUT_TO_EXIT' instead of 'process_game' for better clarity/robustness.
		# A simpler 'yield' or 'await' is usually sufficient for initial setup.
		await get_tree().process_frame # Wait one frame
		camera = get_viewport().get_camera_2d()
		
		# Added a check in case the game is running without a Camera2D
		if camera == null:
			print("LevelBounds: Could not find a Camera2D in the Viewport.")
			return

	# CRITICAL FIX: Corrected limit assignment logic (x for left/right, y for top/bottom)
	camera.limit_left = int(global_position.x)
	camera.limit_right = int(global_position.x) + width
	camera.limit_top = int(global_position.y)
	camera.limit_bottom = int(global_position.y) + height


func _draw() -> void:
	if Engine.is_editor_hint():
		# Define the rectangle based on the exported properties
		var r : Rect2 = Rect2(Vector2.ZERO, Vector2(width, height))
		
		# Draw the main, slightly transparent blue border
		draw_rect(r, Color(0.0, 0.45, 1.0, 0.6), false, 3)
		
		# Draw a thinner, brighter inner border
		draw_rect(r, Color(0.0, 0.75, 1.0), false, 1)
