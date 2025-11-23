extends TextureRect
class_name TrashCan

# FIX: Don't rely on absolute paths. Find the dialog dynamically or via export.
# Since this slot is inside TouchInventory, we can search up.
@onready var inventory_ui = find_parent("TouchInventory")
var confirm_dialog: AcceptDialog

var pending_slot: Node = null
var pending_item_id: String = ""

func _ready():
	if inventory_ui and inventory_ui.has_node("ConfirmDelete"):
		confirm_dialog = inventory_ui.get_node("ConfirmDelete")
		# Connect specifically to the dialog's confirmed signal
		if not confirm_dialog.confirmed.is_connected(_on_confirm_confirmed):
			confirm_dialog.confirmed.connect(_on_confirm_confirmed)

func can_drop_data(_pos, data) -> bool:
	return data is Dictionary and data.has("item_data")

func drop_data(_pos, data) -> void:
	if not confirm_dialog: return
	
	pending_slot = data["source_slot"]
	pending_item_id = data["item_data"].get("id", "")
	
	var item_name = ItemDatabase.get_item(pending_item_id).get("name", pending_item_id)
	confirm_dialog.dialog_text = "Permanently delete %s?" % item_name
	confirm_dialog.popup_centered()

func _on_confirm_confirmed():
	if pending_item_id != "":
		GameState.remove_item(pending_item_id, 1)
		pending_item_id = ""
		pending_slot = null