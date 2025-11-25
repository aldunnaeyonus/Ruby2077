extends Node

var items := {}

func _ready():
	# FIX: Automatically load items on startup
	load_items("res://data/items.json") # Ensure this file exists!

func load_items(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_error("Item database file not found: %s" % path)
		return

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open item database: %s" % path)
		return

	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	
	if error == OK:
		if typeof(json.data) == TYPE_DICTIONARY:
			items = json.data
		else:
			push_error("Item database root must be a Dictionary.")
	else:
		push_error("JSON Error in %s: %s at line %d" % [path, json.get_error_message(), json.get_error_line()])

func get_item(id: String) -> Dictionary:
	return items.get(id, {})
