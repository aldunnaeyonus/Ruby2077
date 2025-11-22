# scripts/QuestPopupUI.gd
extends CanvasLayer
class_name QuestPopupUI

# --- Node References ---
@onready var label_title: Label = $PopupPanel/VBoxContainer/LabelTitle
@onready var label_name: Label = $PopupPanel/VBoxContainer/LabelQuestName
@onready var label_xp: Label = $PopupPanel/VBoxContainer/RewardsContainer/LabelXP
@onready var label_items: Label = $PopupPanel/VBoxContainer/RewardsContainer/LabelItems
@onready var anim: AnimationPlayer = $AnimationPlayer

# --- State ---
var popup_queue: Array = [] # Stores reward dictionaries
var showing: bool = false

func _ready():
	visible = false
	
	# CRITICAL FIX 2: Connect to QuestManager's completion signal
	if is_instance_valid(QuestManager):
		QuestManager.quest_completed.connect(Callable(self, "_on_quest_completed_data_received"))
	
## Public method called by external systems (or directly by QuestManager signal)
## @param id: The unique quest ID.
## @param xp: XP awarded.
## @param items: Array of item IDs awarded (e.g., ["sword", "potion"]).
func queue_popup(quest_id: String, xp: int, items: Array) -> void:
	# Store the data required for display
	popup_queue.append({
		"id": quest_id,
		"xp": xp,
		"items": items
	})
	if not showing:
		_show_next()

## Internal method to handle the queue and sequential display.
func _show_next() -> void:
	if popup_queue.is_empty():
		showing = false
		return
		
	showing = true
	var data: Dictionary = popup_queue.pop_front()
	
	# --- Prepare Data ---
	var def: Dictionary = QuestManager.get_quest_info(data["id"])
	var item_ids: Array = data["items"]
	
	# ⚠️ CRITICAL FIX 1: Look up user-friendly item names
	var item_names: Array = []
	for item_id in item_ids:
		# Assume ItemDatabase is an Autoload Singleton
		var item_info: Dictionary = ItemDatabase.get_item(item_id)
		item_names.append(item_info.get("name", item_id)) # Use name or fallback to ID
		
	# --- Update UI ---
	label_title.text = "Quest Completed! 🎉"
	label_name.text = def.get("title", data["id"])
	label_xp.text = "XP Gained: %d" % data["xp"]
	
	if item_names.is_empty():
		label_items.text = "Items: None"
	else:
		# Correct: Call .join() on the separator string (", ")
		label_items.text = "Items: %s" % (", ".join(item_names)) 
		
	visible = true
	
	# --- Animate In ---
	if anim and anim.has_animation("popup_in"):
		anim.play("popup_in")
		await anim.animation_finished
		
	# --- Hold Timer ---
	await get_tree().create_timer(2.0).timeout
	
	# --- Animate Out ---
	if anim and anim.has_animation("popup_out"):
		anim.play("popup_out")
		await anim.animation_finished
		
	# Clean up visibility
	visible = false 
	
	# Process the next item in the queue
	_show_next()

# --- Signal Handler (CRITICAL FIX 2) ---

## This function is the callback for QuestManager.quest_completed signal.
## It assumes QuestManager emits the required data.
## NOTE: QuestManager.complete_quest needs to be updated to emit XP and items.
func _on_quest_completed_data_received(quest_id: String) -> void:
	# Since QuestManager only emits the ID, we need to look up the rewards from the definition.
	# IMPROVEMENT: It's better design if QuestManager emitted the rewards directly.
	
	var def: Dictionary = QuestManager.get_quest_info(quest_id)
	var xp: int = def.get("xp", 0)
	var items: Array = def.get("rewards", [])

	queue_popup(quest_id, xp, items)
