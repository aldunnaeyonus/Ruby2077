extends Node

# --- SIGNALS ---
# Use the modern signal syntax
signal quest_started(id: String)
signal quest_updated(id: String)
signal quest_completed(id: String)

# --- DATA STRUCTURES ---
# Definitions: { "quest_id": { "title": "...", "requires": [], ... } }
var quest_definitions := {} 
# Active Quests: { "quest_id": { "status": "active", "progress": 50, "xp": 100, "rewards": ["item_id"] } }
var active_quests := {}

# --- LOADING ---

## Loads quest definitions from a JSON file.
func load_quests_from_json(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_error("Quest definition file not found: %s" % path)
		return
		
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	
	if file == null:
		push_error("Failed to open quest definition file: %s" % path)
		return

	var json_text: String = file.get_as_text()
	file.close() # Close the file handle
	
	# --- CRITICAL FIX: Use a JSON instance for robust error checking ---
	var json_parser := JSON.new()
	var parse_error: int = json_parser.parse(json_text)
	
	if parse_error != OK:
		push_error("JSON parsing error in quest file: %s" % path)
		# Now we can safely call non-static methods on the instance:
		push_error("Error: %s (Line: %d)" % [json_parser.get_error_message(), json_parser.get_error_line()])
		return
		
	var parsed_data = json_parser.get_data()
	# --- END CRITICAL FIX ---
		
	if typeof(parsed_data) == TYPE_DICTIONARY:
		quest_definitions = parsed_data
	else:
		push_error("Quest database is malformed. Expected a Dictionary at the root.")

## Gets the definition data for a quest.
func get_quest_info(id: String) -> Dictionary:
	return quest_definitions.get(id, {})

## Gets the active state data for a quest.
func get_active_quest_data(id: String) -> Dictionary:
	return active_quests.get(id, {})

## Gets the current status of a quest (active, completed, or none).
func get_quest_status(id: String) -> String:
	if active_quests.has(id):
		return active_quests[id]["status"]
	# Default status if not active/completed (assuming we only track active/completed in one dict)
	return "none" 


# --- CORE LOGIC ---

## Attempts to start a quest, checking prerequisites.
func start_quest(id: String) -> void:
	if active_quests.has(id):
		return # Already active or completed
		
	var def: Dictionary = get_quest_info(id)
	if def.is_empty():
		push_warning("Attempted to start non-existent quest ID: %s" % id)
		return
		
	# Check Prerequisites
	for req_id in def.get("requires", []):
		# Prereq must exist and be explicitly "completed"
		if get_quest_status(req_id) != "completed":
			push_warning("Quest %s failed prerequisite check for %s." % [id, req_id])
			return
			
	# Start Quest
	var xp_reward: int = def.get("xp", 100)
	var rewards_list: Array = def.get("rewards", [])
	
	active_quests[id] = {
		"status": "active",
		"progress": 0,
		"xp": xp_reward,
		"rewards": rewards_list
	}
	
	quest_started.emit(id) # Emit signal for systems that need to react immediately
	quest_updated.emit(id)

## Updates the percentage progress of an active quest.
func update_progress(id: String, percent: int) -> void:
	if not active_quests.has(id) or active_quests[id]["status"] != "active": 
		return
		
	var clamped_percent: int = clamp(percent, 0, 100)
	
	if active_quests[id]["progress"] != clamped_percent:
		active_quests[id]["progress"] = clamped_percent
		quest_updated.emit(id)
		
		# Auto-complete if progress reaches 100%
		if clamped_percent == 100:
			complete_quest(id)

## Finalizes a quest, granting rewards and XP.
func complete_quest(id: String) -> void:
	if not active_quests.has(id) or active_quests[id]["status"] == "completed": 
		return
		
	var quest_data: Dictionary = active_quests[id]
	quest_data["status"] = "completed"
	
	# Apply rewards (Assumes GameState is an Autoload Singleton)
	if is_instance_valid(GameState):
		# Grant XP
		var xp_gain: int = quest_data.get("xp", 0)
		if xp_gain > 0:
			GameState.add_xp(xp_gain)
			
		# Grant Items
		for item_id in quest_data.get("rewards", []):
			GameState.add_item(item_id)
	else:
		push_error("GameState Autoload is not available to grant rewards for quest: %s" % id)

	quest_completed.emit(id)
	quest_updated.emit(id)
