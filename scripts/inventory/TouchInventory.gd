extends Node

# --- SIGNALS ---
signal item_added(id: String, count: int)
signal item_removed(id: String, count: int)
signal flag_set(flag: String)
signal flag_removed(flag: String)
signal xp_changed(new_xp: int)
signal ui_state_changed(key: String, state: bool)
signal inventory_full_warning # Optional: For UI feedback

# --- CORE STATE VARIABLES ---
var inventory: Dictionary = {}
var flags: Array = []
var xp: int = 0

# CONFIGURATION
const MAX_SLOTS = 12 # Set your limit here

# UI State variables
var inventory_open: bool = false
var tracker_collapsed: bool = false
var gestures_enabled: bool = true

# --- INVENTORY METHODS ---

## Adds an item. Returns TRUE if successful, FALSE if inventory is full.
func add_item(id: String, count: int = 1) -> bool:
	# 1. Check if we already have the item (Stacking)
	if inventory.has(id):
		inventory[id] += count
		item_added.emit(id, inventory[id])
		return true # Successfully stacked
	
	# 2. Check if we have room for a NEW item
	if inventory.size() >= MAX_SLOTS:
		# Inventory is full!
		inventory_full_warning.emit()
		print("Cannot pick up %s: Inventory Full!" % id)
		return false # Failed to add
		
	# 3. Add the new item
	inventory[id] = count
	item_added.emit(id, count)
	return true
