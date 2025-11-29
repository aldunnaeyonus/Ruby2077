extends Node

# --- SIGNALS ---
# Inventory Signals
signal item_added(id: String, count: int)
signal item_removed(id: String, count: int)
signal inventory_full_warning
signal time_changed(is_night: bool)
# Stat Signals
signal coins_changed(new_amount: int)
signal health_changed(current: int, max_hp: int)
signal ammo_changed(current: int, max_val: int)
signal xp_changed(new_xp: int)

# Logic Signals
signal flag_set(flag: String)
signal flag_removed(flag: String)
signal ui_state_changed(key: String, state: bool)

# --- CONFIGURATION ---
const MAX_SLOTS = 12
const SAVE_PATH = "user://savegame.json"

# --- SESSION STATE (Not Saved) ---
var app_launched: bool = false # Tracks if we've seen the startup video this session

# --- CORE SAVED VARIABLES (With Automatic Setters) ---
#GameState.toggle_day_night()
var is_night: bool = false:
	set(value):
		is_night = value
		time_changed.emit(is_night)

# Helper to toggle time (Call this from a debug button or timer)
func toggle_day_night():
	is_night = !is_night
	
var coins: int = 10:
	set(value):
		coins = max(0, value)
		coins_changed.emit(coins)

var health: int = 100:
	set(value):
		health = clamp(value, 0, max_health)
		health_changed.emit(health, max_health)
		if health == 0:
			print("GAME OVER: Player Died")
			# You can emit a 'player_died' signal here if you have one

var max_health: int = 100:
	set(value):
		max_health = value
		health_changed.emit(health, max_health)

var current_ammo: int = 10:
	set(value):
		current_ammo = max(0, value)
		# NOTE: Player.gd also tracks this locally for speed, 
		# but this ensures it saves/loads correctly.
		ammo_changed.emit(current_ammo, 10) # Assuming 10 is max for now

var xp: int = 0:
	set(value):
		xp = value
		xp_changed.emit(xp)

# --- COMPLEX DATA ---
var inventory: Dictionary = {} # { "item_id": count }
var flags: Array = []

# --- UI STATE (With Setters & Accessors) ---

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

# --- ACCESSOR FUNCTIONS (For compatibility with other scripts) ---

func is_inventory_open() -> bool: return inventory_open
func set_inventory_open(val: bool): inventory_open = val

func is_tracker_collapsed() -> bool: return tracker_collapsed
func set_tracker_collapsed(val: bool): tracker_collapsed = val

func are_gestures_enabled() -> bool: return gestures_enabled
func set_gestures_enabled(val: bool): gestures_enabled = val

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
		print("Inventory Full. Cannot add: %s" % id)
		return false
		
	# 3. Add new item
	inventory[id] = count
	item_added.emit(id, count)
	return true

func remove_item(id: String, count: int = 1) -> void:
	if not inventory.has(id): return
	
	var current_count = inventory[id]
	
	if current_count > count:
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

# --- STAT METHODS ---

func add_coins(amount: int) -> void:
	coins += amount

func remove_coins(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		return true
	return false

func take_damage(amount: int) -> void:
	health -= amount

func heal(amount: int) -> void:
	health += amount

func add_xp(amount: int) -> void:
	xp += amount

# --- FLAG METHODS ---

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

# --- SAVE / LOAD SYSTEM ---

func save_game() -> void:
	var save_data = {
		"inventory": inventory,
		"flags": flags,
		"xp": xp,
		"coins": coins,
		"health": health,
		"max_health": max_health,
		"current_ammo": current_ammo,
		"active_quests": QuestManager.active_quests
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		print("Game Saved Successfully.")
	else:
		push_error("Failed to save game to %s" % SAVE_PATH)

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found.")
		return
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("Failed to open save file.")
		return
		
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	
	if error == OK:
		_apply_save_data(json.get_data())
		print("Game Loaded Successfully.")
	else:
		push_error("Save file corrupted: %s" % json.get_error_message())

func _apply_save_data(data: Dictionary) -> void:
	# Load complex data
	inventory = data.get("inventory", {})
	flags = data.get("flags", [])
	
	# Load Quests
	if data.has("active_quests"):
		QuestManager.active_quests = data["active_quests"]
		# Refresh quest UI
		for q_id in QuestManager.active_quests:
			QuestManager.quest_updated.emit(q_id)

	# Load Stats (Setters will trigger UI updates)
	xp = data.get("xp", 0)
	coins = data.get("coins", 0)
	max_health = data.get("max_health", 100)
	health = data.get("health", 100)
	current_ammo = data.get("current_ammo", 10)
	
	# Trigger inventory refresh for UI
	for item_id in inventory:
		item_added.emit(item_id, inventory[item_id])
		
