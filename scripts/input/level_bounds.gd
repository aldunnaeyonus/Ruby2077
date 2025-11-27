@tool
@icon("res://assets/icons/level_bounds.svg")
class_name LevelBounds extends Node2D

@export_range(480, 4096, 32, "suffix:px") 
var width : int = 480:
	set(value):
		width = value
		queue_redraw()

@export_range(270, 4096, 32, "suffix:px") 
var height : int = 270:
	set(value):
		height = value
		queue_redraw()

func _ready() -> void:
	if Engine.is_editor_hint():
		z_index = 100 # Draw on top in editor
		return

	# Apply limits to camera
	var camera = get_viewport().get_camera_2d()
	if camera:
		_apply_limits(camera)
	else:
		# Retry once after a frame if camera spawns late
		await get_tree().process_frame
		camera = get_viewport().get_camera_2d()
		if camera: _apply_limits(camera)

func _apply_limits(cam: Camera2D):
	cam.limit_left = int(global_position.x)
	cam.limit_top = int(global_position.y)
	cam.limit_right = int(global_position.x + width)
	cam.limit_bottom = int(global_position.y + height)

func _draw() -> void:
	if Engine.is_editor_hint():
		var r = Rect2(Vector2.ZERO, Vector2(width, height))
		draw_rect(r, Color(0.0, 0.5, 1.0, 0.2), true) # Fill
		draw_rect(r, Color(0.0, 0.5, 1.0, 0.8), false, 2.0) # Border
		