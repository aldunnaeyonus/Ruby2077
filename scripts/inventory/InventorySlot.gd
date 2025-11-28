extends TextureButton
class_name LevelSlot

# --- CONSTANTS ---
# Ensure this path matches your actual file (you mentioned trash.svg earlier, maybe this should be empty.svg or empty.png)
const EMPTY_ICON_PATH = "res://assets/icons/empty.svg"
const EMPTY_ICON: Texture2D = preload(EMPTY_ICON_PATH)
const DRAG_PREVIEW_SIZE = Vector2(64, 64)

# --- VARIABLES ---
var item_data: Dictionary = {}
var drag_preview: TextureRect

# --- LIFECYCLE ---

func _ready():
	# REMOVED: drag_forwarding = self (This does not exist in Godot 4 like this)
	# Initialize the drag preview node
	drag_preview = TextureRect.new()
	drag_preview.custom_minimum_size = DRAG_PREVIEW_SIZE
	drag_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	_update_display()

# --- CUSTOM FUNCTIONS ---

func _update_display() -> void:
	var new_texture: Texture2D
	
	if item_data.is_empty():
		new_texture = EMPTY_ICON
	else:
		new_texture = item_data.get("icon", EMPTY_ICON)
	
	texture_normal = new_texture
	
	if drag_preview:
		drag_preview.texture = new_texture
	
	queue_redraw()

# --- DRAG AND DROP HANDLERS (Godot 4) ---

# Note the underscore (_) prefix!
func _get_drag_data(at_position: Vector2):
	if item_data.is_empty():
		return null
	
	drag_preview.texture = texture_normal
	
	var drag_data = {
		"item_data": item_data,
		"source_slot": self
	}
	
	set_drag_preview(drag_preview)
	
	return drag_data

# Note the underscore (_) prefix!
func _can_drop_data(at_position: Vector2, data) -> bool:
	return data is Dictionary and data.has("item_data") and data.has("source_slot")

# Note the underscore (_) prefix!
func _drop_data(at_position: Vector2, data) -> void:
	var source_slot = data["source_slot"]
	
	if source_slot == self:
		return
		
	var current_item_temp: Dictionary = item_data
	item_data = data["item_data"]
	
	# Handle the swap
	# If the source slot is a TrashCan (TextureRect), it might not have 'item_data'
	# Check if the source has the property before assigning
	if "item_data" in source_slot:
		source_slot.item_data = current_item_temp
		if source_slot.has_method("_update_display"):
			source_slot._update_display()
	
	_update_display()
