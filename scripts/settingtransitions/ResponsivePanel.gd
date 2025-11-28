extends MarginContainer
class_name ResponsiveUIContainer

# --- Node References ---
@onready var layout_root: VBoxContainer = $LayoutRoot # Explicit type hint is good practice

func _ready():
	# CRITICAL FIX 2: Defer execution of layout logic to ensure the Viewport 
	# and DisplayServer are fully initialized and the final transform is correct.
	call_deferred("_update_and_adjust_layout")

## Deferred entry point for layout adjustments.
func _update_and_adjust_layout():
	update_safe_area()
	adjust_layout_for_screen()

## Applies margins to fit the display's safe area (notches, cutouts).
func update_safe_area():
	var safe_rect: Rect2 = DisplayServer.get_display_safe_area()
	var transform: Transform2D = get_viewport().get_final_transform()
	var safe_viewport: Rect2 = safe_rect * transform.affine_inverse()
	var full_rect: Rect2 = get_viewport().get_visible_rect()

	var margin_left: float = safe_viewport.position.x
	var margin_top: float = safe_viewport.position.y
	
	# ⚠️ CRITICAL FIX 1: Correct calculation for right and bottom margins
	var margin_right: float = full_rect.size.x - (safe_viewport.position.x + safe_viewport.size.x)
	var margin_bottom: float = full_rect.size.y - (safe_viewport.position.y + safe_viewport.size.y)

	# Apply overrides. Clamping to 0 prevents potential negative margins.
	add_theme_constant_override("margin_left", int(margin_left))
	add_theme_constant_override("margin_top", int(margin_top))
	add_theme_constant_override("margin_right", int(max(0.0, margin_right)))
	add_theme_constant_override("margin_bottom", int(max(0.0, margin_bottom)))

## Adjusts layout constants based on the total screen width for basic responsiveness.
func adjust_layout_for_screen():
	# Note: This checks the total viewport size, not the safe area size.
	var screen_width: float = get_viewport().get_visible_rect().size.x
	
	# Ensure layout_root is valid and a Control node
	if not is_instance_valid(layout_root) or not layout_root is Control:
		push_warning("Layout root not found or is not a Control node.")
		return
		
	if screen_width < 800:
		# Small Screen / Mobile Layout
		# Assuming LayoutRoot is a VBoxContainer, HBoxContainer, etc.
		layout_root.add_theme_constant_override("separation", 8)
		layout_root.add_theme_constant_override("margin_top", 16)
	else:
		# Tablet / Desktop Layout
		layout_root.add_theme_constant_override("separation", 24)

## Handle screen size changes dynamically
func _notification(what):
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		# Recalculate and adjust whenever the window/viewport is resized
		call_deferred("_update_and_adjust_layout")
