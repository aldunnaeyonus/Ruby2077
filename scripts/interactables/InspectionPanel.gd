extends CanvasLayer

@onready var icon = $CenterContainer/PanelContainer/Padding/VBoxContainer/Icon
@onready var lbl_name = $CenterContainer/PanelContainer/Padding/VBoxContainer/LabelName
@onready var lbl_desc = $CenterContainer/PanelContainer/Padding/VBoxContainer/LabelDesc
@onready var btn_take = $CenterContainer/PanelContainer/Padding/VBoxContainer/HBoxContainer/ButtonTake
@onready var btn_leave = $CenterContainer/PanelContainer/Padding/VBoxContainer/HBoxContainer/ButtonLeave

var target_item_node: Node = null
var current_id: String = ""
var current_qty: int = 1

func _ready():
	visible = false
	add_to_group("inspection_ui")
	btn_take.pressed.connect(_on_take)
	btn_leave.pressed.connect(_close)

func open_inspection(id: String, qty: int, item_node: Node, texture: Texture2D = null):
	current_id = id
	current_qty = qty
	target_item_node = item_node
	
	var data = ItemDatabase.get_item(id)
	lbl_name.text = data.get("name", "Unknown Item")
	lbl_desc.text = data.get("description", "...")
	
	if texture:
		icon.texture = texture
	else:
		var path = data.get("icon", "res://assets/icons/empty.svg")
		icon.texture = load(path)
	
	visible = true

func _on_take():
	# Check if inventory has space
	var success = GameState.add_item(current_id, current_qty)
	if success:
		if is_instance_valid(target_item_node):
			target_item_node.queue_free()
		_close()
	else:
		# Inventory Full Feedback
		btn_take.text = "Full!"
		await get_tree().create_timer(1.0).timeout
		if btn_take: btn_take.text = "Take"

func _close():
	visible = false
	target_item_node = null
	