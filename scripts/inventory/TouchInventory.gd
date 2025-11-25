extends CanvasLayer
class_name TouchInventory

# --- Node References ---
# Updated path to match the new HBox layout
@onready var grid = $SafeArea/InventoryPanel/MainLayout/GridContainer
@onready var trash_slot = $SafeArea/InventoryPanel/MainLayout/SideBar/TrashSlot
@onready var preview = $ItemPreview
@onready var confirm_delete = $ConfirmDelete
@onready var base = $SafeArea/InventoryPanel

# --- State ---
var touch_index := -1 
var dragging := false 
var swipe_start := Vector2.ZERO
@export var swipe_threshold: float = 100.0

var last_selected_id: String = ""

func _ready():
	visible = GameState.is_inventory_open()
	
	confirm_delete.confirmed.connect(_on_confirm_delete)
	
	if is_instance_valid(GameState):
		GameState.item_added.connect(_populate_inventory)
		GameState.item_removed.connect(_populate_inventory)
		GameState.ui_state_changed.connect(_on_game_state_ui_changed)
	
	# Connect Inventory Slots
	for slot in grid.get_children():
		if slot.has_signal("gui_input"):
			slot.gui_input.connect(_on_slot_input.bind(slot))
			
	# Connect Trash Slot
	if trash_slot:
		trash_slot.gui_input.connect(_on_trash_input)
	
	_populate_inventory()

func _on_game_state_ui_changed(key: String, state: bool) -> void:
	if key == "inventory_open":
		visible = state
		if state:
			_populate_inventory()

func _populate_inventory(item_id: String = "", count: int = 0):
	# Optional arguments allow this to work as a signal callback
	var current_item_ids = GameState.inventory.keys()
	var idx = 0

	for slot in grid.get_children():
		# Reset slot
		if slot.has_method("reset"):
			slot.reset()
		elif "item_data" in slot:
			slot.item_data = {}
			slot.texture_normal = null # Clear icon if using basic buttons

	for id in current_item_ids:
		if idx >= grid.get_child_count():
			break
			
		var slot = grid.get_child(idx)
		var item_count = GameState.get_item_count(id)
		
		# Assign Data
		if "item_data" in slot:
			slot.item_data = {"id": id, "count": item_count}
			
		# Update Visuals
		if slot.has_method("_update_display"):
			slot._update_display()
		else:
			# Fallback
			slot.texture_normal = _get_icon(id)
			
		idx += 1

func _get_icon(item_id: String) -> Texture2D:
	var item_info = ItemDatabase.get_item(item_id)
	var icon_path = item_info.get("icon", "res://assets/icons/empty.svg")
	
	if ResourceLoader.exists(icon_path):
		return load(icon_path)
	return load("res://assets/icons/empty.svg")

# --- Interaction ---

func _on_slot_input(event: InputEvent, slot: Node):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var id = slot.item_data.get("id", "")
		if id != "":
			last_selected_id = id
			show_item_preview(id)
			print("Selected Item: ", id)

func _on_trash_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if last_selected_id != "":
			request_delete()
		else:
			print("No item selected to delete.")

func show_item_preview(item_id: String):
	if preview:
		preview.texture = _get_icon(item_id)
		preview.visible = true

func request_delete():
	var item_info = ItemDatabase.get_item(last_selected_id)
	var item_name = item_info.get("name", last_selected_id)
	confirm_delete.dialog_text = "Delete %s?" % item_name
	confirm_delete.popup_centered()

func _on_confirm_delete():
	if last_selected_id != "":
		GameState.remove_item(last_selected_id, 1)
		# Hide preview if item is completely gone
		if not GameState.has_item(last_selected_id):
			preview.visible = false
			last_selected_id = ""

# --- Gestures (Close on swipe down) ---
func _input(event):
	if not visible: return
	
	if event is InputEventScreenTouch:
		if event.pressed and not dragging:
			# Check if touch is OUTSIDE the inventory panel
			if not base.get_global_rect().has_point(event.position):
				touch_index = event.index
				swipe_start = event.position
				dragging = true
		
		elif not event.pressed and dragging and event.index == touch_index:
			if (event.position.y - swipe_start.y) > swipe_threshold:
				GameState.set_inventory_open(false)
			dragging = false
			touch_index = -1
