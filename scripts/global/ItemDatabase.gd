extends Node

# Dictionary to hold all item data: { "item_id": { "name": "Sword", "icon": "res://...", ... } }
var items := {}

## Loads item data from a JSON file into the 'items' dictionary.
func load_items(path: String) -> void:
	# 1. Check if the file exists first (Best Practice)
	if not FileAccess.file_exists(path):
		push_error("Item database file not found at path: %s" % path)
		return

	# 2. Open the file
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	
	if file == null:
		push_error("Failed to open item database file: %s" % path)
		return

	var json_text: String = file.get_as_text()
	file.close() # Close the file handle
	
	# ⚠️ CRITICAL FIX: Use a JSON instance for robust error checking
	var json_parser := JSON.new()
	var parse_error: int = json_parser.parse(json_text)
	
	# 3. Check for JSON parsing errors
	if parse_error != OK:
		push_error("JSON parsing error in file: %s" % path)
		# Now we can safely call non-static methods on the instance:
		push_error("Error: %s (Line: %d)" % [json_parser.get_error_message(), json_parser.get_error_line()])
		return
	
	var parsed_data = json_parser.get_data()
	
	# 4. Check that the parsed data is the expected type (Dictionary)
	if typeof(parsed_data) == TYPE_DICTIONARY:
		items = parsed_data
	else:
		push_error("Item database is malformed. Expected a Dictionary at the root.")

## Retrieves a single item's data by ID. Returns an empty Dictionary if the ID is not found.
func get_item(id: String) -> Dictionary:
	# Returns the item dictionary or an empty dictionary (safe fallback)
	return items.get(id, {})

# Example of how you might use this (if this node is an Autoload Singleton):
# func _ready():
# 	load_items("res://data/items.json")
