# scripts/TouchInventory.gd
extends CanvasLayer
class_name TouchInventory

# --- Node References ---
@onready var grid = $SafeArea/InventoryPanel/GridContainer
@onready var preview = $ItemPreview
@onready var confirm_delete = $ConfirmDelete
@onready var base = $SafeArea/InventoryPanel

# --- State and Configuration ---
# Use the same multi-touch fix state as the joystick
var touch_index := -1 
var dragging := false 
var swipe_start := Vector2.ZERO
@export var swipe_threshold: float = 100.0

var last_selected_id: String = ""

func _ready():
	# Initial visibility set by GameState
	visible = GameState.is_inventory_open()
	
	# Connect delete confirmation
	confirm_delete.confirmed.connect(_on_confirm_delete)
	
	# Connect to GameState signals for automatic updates (Issue 4 Fix)
	if is_instance_valid(GameState):
		GameState.item_added.connect(Callable(self, "_populate_inventory"))
		GameState.item_removed.connect(Callable(self, "_populate_inventory"))
		GameState.ui_state_changed.connect(Callable(self, "_on_game_state_ui_changed"))
		
	# CRITICAL FIX 2: Connect slot signals ONLY ONCE
	for slot in grid.get_children():
		# Assuming slots are LevelSlot or similar TextureButtons
		if slot is Control:
			slot.gui_input.connect(Callable(self, "_on_slot_input").bind(slot))
	
	_populate_inventory()

## Handles visibility change broadcasted from GameState
func _on_game_state_ui_changed(key: String, state: bool) -> void:
	if key == "inventory_open":
		visible = state

## Fills the inventory grid with current item data.
func _populate_inventory():
	var idx := 0
	# Get all active item IDs from the GameState dictionary (Issue 1 Fix)
	var current_item_ids: Array = GameState.inventory.keys()

	# 1. Clear all slots
	for slot in grid.get_children():
		if slot.has_method("_update_display"): # Assuming LevelSlot or similar
			slot.item_data = {}
			slot._update_display()

	# 2. Populate slots with items
	for item_id in current_item_ids:
		if idx >= grid.get_child_count():
			break
			
		var slot = grid.get_child(idx)
		# NOTE: We only store the ID here. Displaying stacks would require a Label on the slot.
		slot.item_data = {"id": item_id, "count": GameState.get_item_count(item_id)}
		
		if slot.has_method("_update_display"):
			# The slot's internal update function should handle loading the icon
			slot._update_display()
		else:
			# Fallback for generic TextureButton
			slot.texture_normal = _get_icon(item_id)
			
		idx += 1
		
	# If an item was deleted, clear the preview
	if not GameState.has_item(last_selected_id):
		hide_item_preview()

## Gets the icon for an item.
func _get_icon(item_id: String) -> Texture2D:
	# Assume ItemDatabase is an Autoload Singleton
	var item_info = ItemDatabase.get_item(item_id)
	var icon_path = item_info.get("icon", "res://assets/icons/unknown.png")
	
	if ResourceLoader.exists(icon_path):
		return load(icon_path)
	
	push_warning("Icon not found for item ID: %s at %s" % [item_id, icon_path])
	return load("res://assets/icons/unknown.png") # Fallback icon

## Handles input on the individual slot control.
func _on_slot_input(slot: Node, event: InputEvent):
	# Only respond to left-click (primary) presses
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var id = slot.item_data.get("id", "")
		if id != "":
			last_selected_id = id
			show_item_preview(id)

func show_item_preview(item_id: String):
	# Assume ItemPreview is a TextureRect or similar
	preview.texture = _get_icon(item_id)
	
	# Add item details (assuming ItemDatabase)
	var item_details = ItemDatabase.get_item(item_id)
	# You would update labels here: preview_name.text = item_details.get("name", "...")
	# You would connect a "Use" button and a "Delete" button here
	
	preview.visible = true

func hide_item_preview():
	preview.visible = false

# This function is usually connected to a dedicated button on the ItemPreview panel
func request_delete():
	if last_selected_id != "":
		var item_info = ItemDatabase.get_item(last_selected_id)
		confirm_delete.dialog_text = "Delete one %s?" % item_info.get("name", last_selected_id)
		confirm_delete.popup_centered()

func _on_confirm_delete():
	if last_selected_id != "":
		# CRITICAL FIX: Use the count argument for stackable items
		GameState.remove_item(last_selected_id, 1) # Remove 1 item
		# The _populate_inventory will be called via the GameState signal
		# last_selected_id will be reset in _populate_inventory if the item is gone.

## CRITICAL FIX 3: Multi-touch and gesture control for inventory closing.
func _input(event):
	if not visible or not GameState.are_gestures_enabled():
		return

	if event is InputEventScreenTouch:
		if event.pressed and not dragging:
			# Start drag only if we touch the background, not an interactive element
			if not base.get_global_rect().has_point(event.position):
				touch_index = event.index
				swipe_start = event.position
				dragging = true
		
		elif not event.pressed and dragging and event.index == touch_index:
			# End touch: Check for swipe down
			if (event.position.y - swipe_start.y) > swipe_threshold:
				_hide_inventory()
			
			dragging = false
			touch_index = -1
			
	elif event is InputEventScreenDrag and dragging and event.index == touch_index:
		# Drag event updates the position for the eventual check on lift
		pass # Logic moved to lift (ScreenTouch not pressed)

func _hide_inventory():
	# Use the setter method to update the state and emit the signal
	GameState.set_inventory_open(false)
