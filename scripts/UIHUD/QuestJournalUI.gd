# scripts/QuestJournalUI.gd
extends CanvasLayer
class_name QuestJournalUI

# --- Node References ---
@onready var quest_list: ItemList = $JournalPanel/Scroll/QuestList
@onready var quest_details: Label = $JournalPanel/Scroll/QuestList/QuestDetails
@onready var btn_close = $ButtonClose

# --- State and Configuration ---
var swipe_start := Vector2.ZERO
@export var swipe_threshold: float = 100.0
var touch_index: int = -1 # Track touch ID for multi-touch safety

func _ready():
	visible = false
	btn_close.pressed.connect(_hide)
	
	# Connect to ItemList selection signal
	quest_list.item_selected.connect(_on_quest_selected)
	
	# CRITICAL FIX 3: Connect to QuestManager signals for dynamic updates
	if is_instance_valid(QuestManager):
		QuestManager.quest_started.connect(Callable(self, "_populate_quests").call_deferred)
		QuestManager.quest_updated.connect(Callable(self, "_on_quest_data_updated").call_deferred)
		QuestManager.quest_completed.connect(Callable(self, "_populate_quests").call_deferred)
		
	# Ensure the first item is selected on open
	quest_list.select(0) 

## Opens the journal and refreshes the content.
func open():
	visible = true
	_populate_quests()

## Refreshes the list of active quests.
func _populate_quests():
	quest_list.clear()
	var first_id: String = ""
	
	for id in QuestManager.active_quests.keys():
		var info: Dictionary = QuestManager.get_quest_info(id)
		var title: String = info.get("title", id)
		
		var index: int = quest_list.add_item(title)
		# CRITICAL FIX 2: Store the unique quest ID in the item's metadata
		quest_list.set_item_metadata(index, id)
		
		if first_id.is_empty():
			first_id = id
			
	# Select the first item if the list isn't empty
	if not quest_list.is_empty():
		quest_list.select(0)
		# Manually show details for the first item
		_display_quest_details(first_id)
	else:
		quest_details.text = "No active quests."

## Called when a quest is selected in the list.
func _on_quest_selected(index: int):
	# CRITICAL FIX 2: Retrieve the ID directly from metadata (fast and reliable)
	var id: String = quest_list.get_item_metadata(index)
	_display_quest_details(id)

## Called when QuestManager signals an update (to refresh details without refreshing the list).
func _on_quest_data_updated(id: String):
	# If the updated quest is the currently selected one, refresh its details.
	if not quest_list.is_empty():
		var selected_index: int = quest_list.get_current()
		var selected_id: String = quest_list.get_item_metadata(selected_index)
		
		if id == selected_id:
			_display_quest_details(id)

## Helper function to format and display quest details.
func _display_quest_details(id: String):
	var active_data: Dictionary = QuestManager.get_active_quest_data(id)
	var def_data: Dictionary = QuestManager.get_quest_info(id)
	
	var title: String = def_data.get("title", id)
	var description: String = def_data.get("description", "No description available.")
	var status: String = active_data.get("status", "Unknown")
	var progress: int = active_data.get("progress", 0)
	
	quest_details.text = "[b]%s[/b]\n\n%s\n\nStatus: [color=yellow]%s[/color]\nProgress: %d%%" % [
		title, description, status.capitalize(), progress
	]

## Hides the journal.
func _hide():
	visible = false

## Handles input, specifically the swipe-down-to-close gesture.
func _input(event):
	if not visible or not GameState.are_gestures_enabled():
		return

	if event is InputEventScreenTouch:
		if event.pressed and touch_index == -1:
			swipe_start = event.position
			touch_index = event.index
			
		elif not event.pressed and event.index == touch_index:
			# End of Touch (Finger lifted): Perform the final swipe check
			var delta: Vector2 = event.position - swipe_start
			
			# CRITICAL FIX 1: Check threshold only on finger lift
			if delta.y > swipe_threshold:
				_hide()
			
			# Reset touch state
			touch_index = -1
