extends TextureButton
class_name LevelSlot

# --- CONSTANTS ---
const EMPTY_ICON_PATH = "res://assets/icons/empty.svg"
# Preload the default empty icon for efficiency
const EMPTY_ICON: Texture2D = preload(EMPTY_ICON_PATH)
# Define the size for the drag preview, based on typical inventory icons
const DRAG_PREVIEW_SIZE = Vector2(64, 64)

# --- VARIABLES ---
# Dictionary holding the item data (e.g., name, stack_size, icon path, effects)
var item_data: Dictionary = {}
# The TextureRect instance used for the visual feedback during dragging
var drag_preview: TextureRect

# --- LIFECYCLE ---

func _ready():
	# CRITICAL GODOT 4 FIX: Set the drag_forwarding property to self.
	# This tells Godot that this node handles the can_drop_data and drop_data methods.
	drag_forwarding = self
	
	# Initialize the drag preview node
	drag_preview = TextureRect.new()
	drag_preview.custom_minimum_size = DRAG_PREVIEW_SIZE
	drag_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	# Initial display update
	_update_display()

# --- CUSTOM FUNCTIONS ---

## Function to update the visual appearance of the slot based on item_data.
func _update_display() -> void:
	# Determine the texture to display
	var new_texture: Texture2D
	
	if item_data.is_empty():
		new_texture = EMPTY_ICON
	else:
		# Use the icon from item_data, falling back to EMPTY_ICON if not found
		new_texture = item_data.get("icon", EMPTY_ICON)
	
	# Set the texture for the button (using texture_normal for simplicity)
	texture_normal = new_texture
	
	# Update the drag preview's texture to match the item
	if drag_preview:
		drag_preview.texture = new_texture
	
	# Although setting texture_normal usually forces a redraw, this is robust.
	queue_redraw()

# --- DRAG AND DROP HANDLERS ---

## Called when a drag event starts on this slot.
func get_drag_data(position: Vector2):
	# If the slot is empty, we cannot drag anything.
	if item_data.is_empty():
		return null
	
	# Ensure the drag preview texture is current (in case _ready didn't cover it)
	drag_preview.texture = texture_normal
	
	# Data payload: contains the item data and a reference to the source slot
	var drag_data = { 
		"item_data": item_data, 
		"source_slot": self 
	}
	
	# Set the visual feedback for the drag operation
	set_drag_preview(drag_preview)
	
	return drag_data

## Called when an item is being dragged over this slot.
func can_drop_data(position: Vector2, data) -> bool:
	# Can drop if the data is a dictionary and contains the item data and source slot reference
	return data is Dictionary and data.has("item_data") and data.has("source_slot")

## Called when a drag event finishes over this slot.
func drop_data(position: Vector2, data) -> void:
	# The source slot is another instance of this class (LevelSlot)
	var source_slot: LevelSlot = data["source_slot"]
	
	# Optimization: If dropping back onto itself, do nothing
	if source_slot == self:
		return
		
	# 1. Store the item currently in this slot (destination slot)
	var current_item_temp: Dictionary = item_data
	
	# 2. Update the destination slot with the dropped item's data
	item_data = data["item_data"]
	
	# 3. Update the source slot with the item that was in the destination slot (swapping)
	source_slot.item_data = current_item_temp
	
	# 4. CRITICAL: Update the visual display for BOTH slots.
	_update_display() # Update this slot (the destination)
	
	# Update the source slot, ensuring it's an instance of this class
	if source_slot is LevelSlot:
		source_slot._update_display()
