extends TextureRect
class_name TrashCan

# --- Node References ---
# Assuming a correct path where ConfirmDelete is reachable. 
# Adjust path if needed, e.g., $ConfirmDelete if it's a child of this TrashCan.
@onready var confirm: AcceptDialog = get_node("/root/MobileGameplayUI/SafeAreaRoot/TouchInventory/ConfirmDelete")

# --- State ---
var pending_slot: Node = null  # Reference to the slot node being deleted from
var pending_item_id: String = "" # ID of the item being deleted

# --- DRAG AND DROP HANDLERS ---

func can_drop_data(position: Vector2, data) -> bool:
	# Only allow dropping if it contains valid item data and a source slot
	return data is Dictionary and data.has("item_data") and data.has("source_slot")

func drop_data(position: Vector2, data) -> void:
	# 1. Store the source slot and item ID
	pending_slot = data["source_slot"]
	pending_item_id = data["item_data"].get("id", "")
	
	if pending_item_id.is_empty():
		push_warning("TrashCan: Item data dropped was empty or missing 'id'.")
		pending_slot = null
		return
		
	# 2. Get the item's display name from the database (Assumes ItemDatabase Autoload)
	var item_info: Dictionary = ItemDatabase.get_item(pending_item_id)
	var item_name: String = item_info.get("name", pending_item_id)
	
	# 3. Update the confirmation dialog text and show it
	confirm.dialog_text = "Permanently delete **%s**?" % item_name
	confirm.popup_centered()

# --- CONFIRMATION HANDLER ---

# This function is connected to the 'confirmed' signal of the AcceptDialog in _ready()
func _on_confirm_confirmed() -> void:
	if pending_slot == null or pending_item_id.is_empty():
		return # Safety check
		
	# ⚠️ CRITICAL FIX: Interact with the GameState to remove the actual data.
	# We remove 1 item. If you want to delete the whole stack, you'd change the logic here.
	GameState.remove_item(pending_item_id, 1)
	
	# NOTE: After calling GameState.remove_item, the GameState signal 
	# (item_removed) will trigger the main UI script (TouchInventory) 
	# to call _populate_inventory(), refreshing all slots.
	
	# Clear pending state
	pending_slot = null
	pending_item_id = ""

# Since the AcceptDialog is a child of the CanvasLayer in your structure, 
# ensure you connect the 'confirmed' signal somewhere, 
# for example, in the main TouchInventory script or directly in the editor.
# If you need to connect it here, you'd do:
# func _ready():
# 	# ... other setup
# 	confirm.confirmed.connect(_on_confirm_confirmed)
