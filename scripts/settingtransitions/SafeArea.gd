extends MarginContainer
class_name SafeAreaContainer

func _ready():
	call_deferred("_update_safe_area")

func _update_safe_area():
	var safe: Rect2 = DisplayServer.get_display_safe_area()
	var transform: Transform2D = get_viewport().get_final_transform()
	var safe_viewport: Rect2 = safe * transform.affine_inverse()
	var full_viewport: Rect2 = get_viewport().get_visible_rect()

	var margin_left: float = safe_viewport.position.x
	var margin_top: float = safe_viewport.position.y
	
	# FIX: Robust margin calculation
	var margin_right: float = full_viewport.size.x - (safe_viewport.position.x + safe_viewport.size.x)
	var margin_bottom: float = full_viewport.size.y - (safe_viewport.position.y + safe_viewport.size.y)

	add_theme_constant_override("margin_left", int(margin_left))
	add_theme_constant_override("margin_top", int(margin_top))
	add_theme_constant_override("margin_right", int(max(0.0, margin_right)))
	add_theme_constant_override("margin_bottom", int(max(0.0, margin_bottom)))
