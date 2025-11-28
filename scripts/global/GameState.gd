extends Node

# --- SIGNALS ---
signal item_added(id: String, count: int)
signal item_removed(id: String, count: int)
signal flag_set(flag: String)
signal flag_removed(flag: String)
signal xp_changed(new_xp: int)
signal ui_state_changed(key: String, state: bool)
signal inventory_full_warning
signal coins_changed(new_amount: int)
signal health_changed(current: int, max_hp: int)

# --- CONFIGURATION ---
const MAX_SLOTS = 12
const SAVE_PATH = "user://savegame.json"

# --- STATE VARIABLES ---
var app_launched: bool = false
var inventory: Dictionary = {} # Format: { "item_id": count }
var flags: Array = []
var xp: int = 0
var coins: int = 0
var health: int = 100
var max_health: int = 100

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

# --- PUBLIC ACCESSORS (Restored to fix errors) ---

func is_inventory_open() -> bool:
	return inventory_open

func is_tracker_collapsed() -> bool:
	return tracker_collapsed

func are_gestures_enabled() -> bool:
	return gestures_enabled

func set_inventory_open(value: bool):
	inventory_open = value

func set_tracker_collapsed(value: bool):
	tracker_collapsed = value

func set_gestures_enabled(value: bool):
	gestures_enabled = value

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

# --- STATS (Coins & Health) ---

func add_coins(amount: int) -> void:
	coins += amount
	coins_changed.emit(coins)

func remove_coins(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		coins_changed.emit(coins)
		return true
	return false

func take_damage(amount: int) -> void:
	health = max(0, health - amount)
	health_changed.emit(health, max_health)
	if health == 0:
		print("Player Died!") # Connect to your Player.die() logic

func heal(amount: int) -> void:
	health = min(max_health, health + amount)
	health_changed.emit(health, max_health)

# --- DATA PERSISTENCE ---

func save_game() -> void:
	var save_data = {
		"inventory": inventory,
		"flags": flags,
		"xp": xp,
		"coins": coins,
		"health": health,
		"max_health": max_health,
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
	coins = data.get("coins", 0)
	health = data.get("health", 100)
	max_health = data.get("max_health", 100)
	
	if data.has("active_quests"):
		QuestManager.active_quests = data["active_quests"]
		for q_id in QuestManager.active_quests:
			QuestManager.quest_updated.emit(q_id)
			
	xp_changed.emit(xp)
	coins_changed.emit(coins)
	health_changed.emit(health, max_health)
	
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
