# scripts/interactables/InspectionPanel.gd
extends CanvasLayer

@onready var panel = $CenterContainer/PanelContainer
@onready var icon = $CenterContainer/PanelContainer/Padding/VBoxContainer/Icon
@onready var lbl_name = $CenterContainer/PanelContainer/Padding/VBoxContainer/LabelName
@onready var lbl_desc = $CenterContainer/PanelContainer/Padding/VBoxContainer/LabelDesc
@onready var btn_take = $CenterContainer/PanelContainer/Padding/VBoxContainer/HBoxContainer/ButtonTake
@onready var btn_leave = $CenterContainer/PanelContainer/Padding/VBoxContainer/HBoxContainer/ButtonLeave

var current_item_node: Node = null
var current_item_id: String = ""
var current_quantity: int = 1

func _ready():
	visible = false
	add_to_group("inspection_ui")
	btn_take.pressed.connect(_on_take_pressed)
	btn_leave.pressed.connect(_on_leave_pressed)

# UPDATED SIGNATURE: Added 'texture' parameter with default value null
func open_inspection(id: String, qty: int, item_node: Node, texture: Texture2D = null):
	current_item_id = id
	current_quantity = qty
	current_item_node = item_node
	
	var data = ItemDatabase.get_item(id)
	
	lbl_name.text = data.get("name", "Unknown Item")
	lbl_desc.text = data.get("description", "No description available.")
	
	# LOGIC: Use passed texture if available, otherwise load from DB
	if texture != null:
		icon.texture = texture
	else:
		var icon_path = data.get("icon", "res://assets/icons/empty.svg")
		if ResourceLoader.exists(icon_path):
			icon.texture = load(icon_path)
	
	visible = true

func _on_take_pressed():
	var added = GameState.add_item(current_item_id, current_quantity)
	if added:
		if is_instance_valid(current_item_node):
			current_item_node.queue_free()
		close()
	else:
		print("Inventory Full!")

func _on_leave_pressed():
	close()

func close():
	visible = false
	current_item_node = null
