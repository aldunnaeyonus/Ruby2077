extends MarginContainer
class_name SafeAreaContainer

func _ready():
	# Use deferred calls in case the layout hasn't settled yet
	call_deferred("_update_safe_area")

func _update_safe_area():
	# 1. Get the Safe Area rect (in Display coordinates, usually pixels)
	var safe: Rect2 = DisplayServer.get_display_safe_area()
	
	# 2. Get the transformation matrix from viewport to display space
	var transform: Transform2D = get_viewport().get_final_transform()
	
	# 3. Transform the Safe Area back into Viewport coordinates (where UI lives)
	# safe_viewport: Rect2 in Viewport space
	var safe_viewport: Rect2 = safe * transform.affine_inverse()
	
	# 4. Get the total visible area of the Viewport
	var full_viewport: Rect2 = get_viewport().get_visible_rect()
	
	# --- Margin Calculations ---
	
	# Margin Left: Distance from Viewport Left (0) to Safe Area Left (safe_viewport.position.x)
	var margin_left: float = safe_viewport.position.x
	
	# Margin Top: Distance from Viewport Top (0) to Safe Area Top (safe_viewport.position.y)
	var margin_top: float = safe_viewport.position.y
	
	# Margin Right: Distance from Safe Area Right to Viewport Right
	# = Viewport Width - (Safe Area Left + Safe Area Width)
	var margin_right: float = full_viewport.size.x - (safe_viewport.position.x + safe_viewport.size.x)
	
	# Margin Bottom: Distance from Safe Area Bottom to Viewport Bottom
	# = Viewport Height - (Safe Area Top + Safe Area Height)
	var margin_bottom: float = full_viewport.size.y - (safe_viewport.position.y + safe_viewport.size.y)
	
	# --- Apply Overrides ---
	
	add_theme_constant_override("margin_left", int(margin_left))
	add_theme_constant_override("margin_top", int(margin_top))
	# Clamp to 0 to prevent negative margins if the calculation is slightly off
	add_theme_constant_override("margin_right", int(max(0.0, margin_right)))
	add_theme_constant_override("margin_bottom", int(max(0.0, margin_bottom)))
