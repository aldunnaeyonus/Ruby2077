# scripts/global/GameState.gd
extends Node

# --- SIGNALS ---
signal item_added(id: String, count: int)
signal item_removed(id: String, count: int)
signal flag_set(flag: String)
signal flag_removed(flag: String)
signal xp_changed(new_xp: int)
signal ui_state_changed(key: String, state: bool)

# --- CORE STATE VARIABLES ---
var inventory: Dictionary = {}
var flags: Array = []
var xp: int = 0

# UI State variables
var inventory_open: bool = false
var tracker_collapsed: bool = false
var gestures_enabled: bool = true

# --- SAVE/LOAD SYSTEM ---
const SAVE_PATH = "user://savegame.json"

func save_game() -> void:
	var save_data = {
		"inventory": inventory,
		"flags": flags,
		"xp": xp,
		# Grab quest data directly from the QuestManager singleton
		"active_quests": QuestManager.active_quests
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		print("Game Saved Successfully.")
	else:
		push_error("Failed to save game at: %s" % SAVE_PATH)

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found.")
		return
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("Failed to open save file.")
		return
		
	var json_text = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(json_text)
	
	if error == OK:
		var data = json.get_data()
		_apply_save_data(data)
		print("Game Loaded Successfully.")
	else:
		push_error("JSON Parse Error in save file: %s" % json.get_error_message())

func _apply_save_data(data: Dictionary) -> void:
	# Use .get() with defaults to prevent crashes if fields are missing
	inventory = data.get("inventory", {})
	flags = data.get("flags", [])
	xp = data.get("xp", 0)
	
	# Restore Quests
	if data.has("active_quests"):
		QuestManager.active_quests = data["active_quests"]
		# Re-emit signals for UI updates if necessary
		for quest_id in QuestManager.active_quests:
			QuestManager.quest_updated.emit(quest_id)
			
	# Emit updates for UI
	xp_changed.emit(xp)
	# (Optional) Emit item signals if you need to refresh the full inventory UI

# --- INVENTORY METHODS ---
func add_item(id: String, count: int = 1) -> void:
	var current_count = inventory.get(id, 0)
	inventory[id] = current_count + count
	item_added.emit(id, inventory[id])

func remove_item(id: String, count: int = 1) -> void:
	var current_count = inventory.get(id, 0)
	if current_count >= count:
		inventory[id] = current_count - count
		item_removed.emit(id, inventory[id])
		if inventory[id] <= 0:
			inventory.erase(id)
	elif current_count > 0:
		inventory.erase(id)
		item_removed.emit(id, 0)

func has_item(id: String, count: int = 1) -> bool:
	return inventory.get(id, 0) >= count

func get_item_count(id: String) -> int:
	return inventory.get(id, 0)

# --- FLAG METHODS ---
func add_flag(flag: String) -> void:
	if not flags.has(flag):
		flags.append(flag)
		flag_set.emit(flag)

func remove_flag(flag: String) -> void:
	if flags.has(flag):
		flags.erase(flag)
		flag_removed.emit(flag)
		
func has_flag(flag: String) -> bool:
	return flags.has(flag)

# --- XP METHOD ---
func add_xp(amount: int) -> void:
	xp += amount
	xp_changed.emit(xp)

# --- UI STATE METHODS ---
func set_inventory_open(state: bool) -> void:
	inventory_open = state
	ui_state_changed.emit("inventory_open", state)
	
func is_inventory_open() -> bool:
	return inventory_open

func set_tracker_collapsed(state: bool) -> void:
	tracker_collapsed = state
	ui_state_changed.emit("tracker_collapsed", state)
	
func is_tracker_collapsed() -> bool:
	return tracker_collapsed

func set_gestures_enabled(state: bool) -> void:
	gestures_enabled = state
	ui_state_changed.emit("gestures_enabled", state)
	
func are_gestures_enabled() -> bool:
	return gestures_enabled
