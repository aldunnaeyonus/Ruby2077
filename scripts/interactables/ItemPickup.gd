# scripts/interactables/ItemPickup.gd
extends Area2D

@export var item_id: String = "health_potion"
@export var quantity: int = 1

@onready var prompt = $PromptLabel
@onready var sprite = $Sprite2D

func _ready():
	prompt.visible = false
	
	# Load default icon from DB if sprite is empty
	if sprite.texture == null:
		var data = ItemDatabase.get_item(item_id)
		var icon_path = data.get("icon", "")
		if icon_path != "" and ResourceLoader.exists(icon_path):
			sprite.texture = load(icon_path)

	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _on_area_entered(area):
	if area.name == "InteractionArea": 
		prompt.visible = true

func _on_area_exited(area):
	if area.name == "InteractionArea":
		prompt.visible = false

func on_interact():
	var ui = get_tree().get_first_node_in_group("inspection_ui")
	
	if ui:
		# PASS THE TEXTURE HERE (sprite.texture)
		ui.open_inspection(item_id, quantity, self, sprite.texture)
	else:
		var added = GameState.add_item(item_id, quantity)
		if added:
			queue_free()
