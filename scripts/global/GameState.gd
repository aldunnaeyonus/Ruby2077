extends Node

# --- SIGNALS ---
signal item_added(id: String, count: int)
signal item_removed(id: String, count: int)
signal flag_set(flag: String)
signal flag_removed(flag: String)
signal xp_changed(new_xp: int)
signal ui_state_changed(key: String, state: bool)
signal inventory_full_warning

# --- CONFIGURATION ---
const MAX_SLOTS = 12
const SAVE_PATH = "user://savegame.json"

# --- STATE VARIABLES ---
var inventory: Dictionary = {} # Format: { "item_id": count }
var flags: Array = []
var xp: int = 0

# --- UI STATE ---
var inventory_open: bool = false:
	set(value):
		inventory_open = value
		ui_state_changed.emit("inventory_open", value)

var tracker_collapsed: bool = false:
	set(value):
		tracker_collapsed = value
		ui_state_changed.emit("tracker_collapsed", value)

var gestures_enabled: bool = true:
	set(value):
		gestures_enabled = value
		ui_state_changed.emit("gestures_enabled", value)

# --- INVENTORY SYSTEM ---

func add_item(id: String, count: int = 1) -> bool:
	# 1. Stack existing item
	if inventory.has(id):
		inventory[id] += count
		item_added.emit(id, inventory[id])
		return true 
	
	# 2. Check capacity for new item
	if inventory.size() >= MAX_SLOTS:
		inventory_full_warning.emit()
		push_warning("Inventory Full. Cannot add: %s" % id)
		return false
		
	# 3. Add new item
	inventory[id] = count
	item_added.emit(id, count)
	return true

func remove_item(id: String, count: int = 1) -> void:
	if not inventory.has(id): return
	
	if inventory[id] > count:
		inventory[id] -= count
		item_removed.emit(id, inventory[id])
	else:
		# Remove entirely if count reaches 0 or less
		inventory.erase(id)
		item_removed.emit(id, 0)

func has_item(id: String, count: int = 1) -> bool:
	return inventory.get(id, 0) >= count

func get_item_count(id: String) -> int:
	return inventory.get(id, 0)

# --- DATA PERSISTENCE --- 
func save_game() -> void:
	var save_data = {
		"inventory": inventory,
		"flags": flags,
		"xp": xp,
		"active_quests": QuestManager.active_quests
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		print("Game Saved.")
	else:
		push_error("Failed to save game to %s" % SAVE_PATH)

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file: return
		
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	
	if error == OK:
		_apply_save_data(json.get_data())
	else:
		push_error("Save file corrupted: %s" % json.get_error_message())

func _apply_save_data(data: Dictionary) -> void:
	inventory = data.get("inventory", {})
	flags = data.get("flags", [])
	xp = data.get("xp", 0)
	
	if data.has("active_quests"):
		QuestManager.active_quests = data["active_quests"]
		# Refresh quest UI
		for q_id in QuestManager.active_quests:
			QuestManager.quest_updated.emit(q_id)
			
	xp_changed.emit(xp)
	# Trigger inventory refresh
	for item_id in inventory:
		item_added.emit(item_id, inventory[item_id])

# --- PROGRESS FLAGS ---

func add_flag(flag: String) -> void:
	if flag not in flags:
		flags.append(flag)
		flag_set.emit(flag)

func remove_flag(flag: String) -> void:
	if flag in flags:
		flags.erase(flag)
		flag_removed.emit(flag)

func has_flag(flag: String) -> bool:
	return flag in flags

func add_xp(amount: int) -> void:
	xp += amount
	xp_changed.emit(xp)