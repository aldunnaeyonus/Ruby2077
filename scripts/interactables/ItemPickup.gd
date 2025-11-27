extends Area2D

@export var item_id: String = "health_potion"
@export var quantity: int = 1

@onready var prompt = $PromptLabel
@onready var sprite = $Sprite2D

func _ready():
	prompt.visible = false
	
	# Auto-load icon if not manually set
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

# Called by Player.gd
func on_interact():
	var ui = get_tree().get_first_node_in_group("inspection_ui")
	
	if ui:
		# Pass texture to UI to avoid reloading
		ui.open_inspection(item_id, quantity, self, sprite.texture)
	else:
		# Instant pickup fallback
		var success = GameState.add_item(item_id, quantity)
		if success:
			queue_free()
		else:
			# Optional: Play "Error" sound
			pass
			