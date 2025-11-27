extends CanvasLayer
class_name TouchInventory

# --- NODES ---
@onready var grid = $CenterContainer/InventoryBase/Padding/MainLayout/GridContainer
@onready var trash_slot = $CenterContainer/InventoryBase/Padding/MainLayout/SideBar/TrashSlot
@onready var preview = $ItemPreview
@onready var confirm_delete = $ConfirmDelete
@onready var base_rect = $CenterContainer/InventoryBase

# --- STATE ---
var selected_item_id: String = ""
var swipe_start: Vector2 = Vector2.ZERO
var dragging: bool = false
const SWIPE_THRESHOLD = 100.0

func _ready():
	# Initial state
	visible = GameState.is_inventory_open()
	
	# Global Signals
	if is_instance_valid(GameState):
		GameState.item_added.connect(_refresh_inventory)
		GameState.item_removed.connect(_refresh_inventory)
		GameState.ui_state_changed.connect(_on_ui_state_changed)
	
	confirm_delete.confirmed.connect(_on_delete_confirmed)
	
	# Setup Slots
	_connect_slots()
	_refresh_inventory()

func _on_ui_state_changed(key: String, state: bool):
	if key == "inventory_open":
		visible = state
		if state:
			_refresh_inventory()

func _connect_slots():
	# Connect existing slots in the scene
	for slot in grid.get_children():
		if not slot.gui_input.is_connected(_on_slot_input):
			slot.gui_input.connect(_on_slot_input.bind(slot))
	
	if trash_slot and not trash_slot.gui_input.is_connected(_on_trash_input):
		trash_slot.gui_input.connect(_on_trash_input)

func _refresh_inventory(_a = null, _b = null):
	# Args _a and _b catch the signal arguments from GameState (id, count) which we don't need directly here
	var items = GameState.inventory.keys()
	var slots = grid.get_children()
	
	for i in range(slots.size()):
		var slot = slots[i]
		if i < items.size():
			var item_id = items[i]
			var count = GameState.get_item_count(item_id)
			_update_slot_visuals(slot, item_id, count)
		else:
			_clear_slot(slot)

func _update_slot_visuals(slot: Control, id: String, count: int):
	slot.set_meta("item_id", id) # Store ID in metadata
	
	# Load Icon
	var data = ItemDatabase.get_item(id)
	var icon_path = data.get("icon", "res://assets/icons/empty.svg")
	
	if slot.has_method("set_item"): # Assuming InventorySlot.gd has this
		slot.set_item(load(icon_path), count)
	elif slot is TextureButton or slot is TextureRect:
		slot.texture_normal = load(icon_path)

func _clear_slot(slot: Control):
	slot.set_meta("item_id", "")
	if slot.has_method("clear"):
		slot.clear()
	elif slot is TextureButton:
		slot.texture_normal = null

# --- INPUT HANDLING ---

func _on_slot_input(event: InputEvent, slot: Control):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var id = slot.get_meta("item_id", "")
		if id != "":
			selected_item_id = id
			_show_preview(id)

func _on_trash_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if selected_item_id != "":
			var data = ItemDatabase.get_item(selected_item_id)
			confirm_delete.dialog_text = "Delete %s?" % data.get("name", "Item")
			confirm_delete.popup_centered()

func _show_preview(id: String):
	var data = ItemDatabase.get_item(id)
	if preview:
		preview.texture = load(data.get("icon", ""))
		preview.visible = true

func _on_delete_confirmed():
	if selected_item_id != "":
		GameState.remove_item(selected_item_id, 1)
		# Check if we removed the last one
		if not GameState.has_item(selected_item_id):
			preview.visible = false
			selected_item_id = ""

# --- GESTURES (Swipe Down to Close) ---
func _input(event):
	if not visible: return
	
	if event is InputEventScreenTouch:
		if event.pressed:
			# If touching outside the inventory panel
			if not base_rect.get_global_rect().has_point(event.position):
				dragging = true
				swipe_start = event.position
		elif not event.pressed and dragging:
			dragging = false
			if event.position.y - swipe_start.y > SWIPE_THRESHOLD:
				GameState.set_inventory_open(false)