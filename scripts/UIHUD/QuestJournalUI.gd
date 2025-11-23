# scripts/UIHUD/QuestJournalUI.gd
extends CanvasLayer
class_name QuestJournalUI

# --- Node References ---
@onready var quest_list: ItemList = $JournalPanel/Scroll/QuestList
# FIX: Type hint changed to RichTextLabel to match the .tscn
@onready var quest_details: RichTextLabel = $JournalPanel/Scroll/QuestList/QuestDetails
@onready var btn_close = $ButtonClose

# --- State and Configuration ---
var swipe_start := Vector2.ZERO
@export var swipe_threshold: float = 100.0
var touch_index: int = -1

func _ready():
	visible = false
	if btn_close:
		btn_close.pressed.connect(_hide)
	
	# Connect to ItemList selection signal
	quest_list.item_selected.connect(_on_quest_selected)
	
	# Connect to QuestManager signals
	if is_instance_valid(QuestManager):
		QuestManager.quest_started.connect(Callable(self, "_populate_quests").call_deferred)
		QuestManager.quest_updated.connect(Callable(self, "_on_quest_data_updated").call_deferred)
		QuestManager.quest_completed.connect(Callable(self, "_populate_quests").call_deferred)
		
	# Ensure the first item is selected on open if exists
	if quest_list.item_count > 0:
		quest_list.select(0) 

func open():
	visible = true
	_populate_quests()

func _populate_quests():
	quest_list.clear()
	var first_id: String = ""
	
	for id in QuestManager.active_quests.keys():
		var info: Dictionary = QuestManager.get_quest_info(id)
		var title: String = info.get("title", id)
		
		var index: int = quest_list.add_item(title)
		quest_list.set_item_metadata(index, id)
		
		if first_id.is_empty():
			first_id = id
			
	if quest_list.item_count > 0:
		quest_list.select(0)
		_display_quest_details(first_id)
	else:
		quest_details.text = "No active quests."

func _on_quest_selected(index: int):
	var id: String = quest_list.get_item_metadata(index)
	_display_quest_details(id)

func _on_quest_data_updated(id: String):
	# FIX: Correct method to get selected items (returns Array)
	var selected_items = quest_list.get_selected_items()
	if selected_items.size() > 0:
		var selected_index = selected_items[0]
		var selected_id = quest_list.get_item_metadata(selected_index)
		
		# Only refresh if the updated quest is the one currently viewing
		if id == selected_id:
			_display_quest_details(id)

func _display_quest_details(id: String):
	var active_data: Dictionary = QuestManager.get_active_quest_data(id)
	var def_data: Dictionary = QuestManager.get_quest_info(id)
	
	var title: String = def_data.get("title", id)
	var description: String = def_data.get("description", "No description available.")
	var status: String = active_data.get("status", "Unknown")
	var progress: int = active_data.get("progress", 0)
	
	# RichTextLabel uses bbcode
	quest_details.text = "[b]%s[/b]\n\n%s\n\nStatus: [color=yellow]%s[/color]\nProgress: %d%%" % [
		title, description, status.capitalize(), progress
	]

func _hide():
	visible = false

func _input(event):
	if not visible or (is_instance_valid(GameState) and not GameState.are_gestures_enabled()):
		return

	if event is InputEventScreenTouch:
		if event.pressed and touch_index == -1:
			swipe_start = event.position
			touch_index = event.index
		elif not event.pressed and event.index == touch_index:
			var delta: Vector2 = event.position - swipe_start
			if delta.y > swipe_threshold:
				_hide()
			touch_index = -1