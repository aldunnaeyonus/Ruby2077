# scripts/GameState.gd
extends Node

# --- SIGNALS (For decoupling UI updates) ---
signal item_added(id: String, count: int)
signal item_removed(id: String, count: int)
signal flag_set(flag: String)
signal flag_removed(flag: String)
signal xp_changed(new_xp: int)
signal ui_state_changed(key: String, state: bool)


# --- CORE STATE VARIABLES ---

# Inventory: Dictionary { item_id: count } for stackable items
var inventory: Dictionary = {}
var flags: Array = []
var xp: int = 0

# UI State variables
var inventory_open: bool = false
var tracker_collapsed: bool = false
var gestures_enabled: bool = true


# --- INVENTORY METHODS (Updated for stacking) ---

## Adds an item to the inventory, handling stacks.
func add_item(id: String, count: int = 1) -> void:
	var current_count = inventory.get(id, 0)
	inventory[id] = current_count + count
	item_added.emit(id, inventory[id]) # Emit signal

## Removes an item from the inventory, handling stacks.
func remove_item(id: String, count: int = 1) -> void:
	var current_count = inventory.get(id, 0)
	
	if current_count >= count:
		inventory[id] = current_count - count
		item_removed.emit(id, inventory[id]) # Emit signal
		
		# If count reaches zero, clean up the dictionary entry
		if inventory[id] <= 0:
			inventory.erase(id)
			
	elif current_count > 0:
		# If removing more than available, remove all and erase
		inventory.erase(id)
		item_removed.emit(id, 0)

## Checks if an item (or at least a specific count) is present.
func has_item(id: String, count: int = 1) -> bool:
	return inventory.get(id, 0) >= count

## Returns the count of a specific item.
func get_item_count(id: String) -> int:
	return inventory.get(id, 0)


# --- FLAG METHODS ---

func add_flag(flag: String) -> void:
	if not flags.has(flag):
		flags.append(flag)
		flag_set.emit(flag) # Emit signal

func remove_flag(flag: String) -> void:
	if flags.has(flag):
		flags.erase(flag)
		flag_removed.emit(flag) # Emit signal
		
func has_flag(flag: String) -> bool:
	return flags.has(flag)


# --- XP METHOD ---

func add_xp(amount: int) -> void:
	xp += amount
	xp_changed.emit(xp) # Emit signal


# --- UI STATE METHODS (Using setters to emit signals) ---

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
