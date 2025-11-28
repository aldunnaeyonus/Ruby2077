extends CanvasLayer
class_name QuestJournalUI

# --- NODES ---
@onready var quest_list: ItemList = $JournalPanel/Scroll/QuestList
@onready var quest_details: RichTextLabel = $JournalPanel/Scroll/QuestList/QuestDetails
@onready var btn_close = $ButtonClose

# --- STATE ---
var swipe_start := Vector2.ZERO
var touch_index: int = -1
@export var swipe_threshold: float = 100.0

func _ready():
	visible = false
	if btn_close: btn_close.pressed.connect(_hide)
	
	if quest_list:
		quest_list.item_selected.connect(_on_quest_selected)
	
	if is_instance_valid(QuestManager):
		QuestManager.quest_updated.connect(func(_id): _populate_quests.call_deferred())
		QuestManager.quest_started.connect(func(_id): _populate_quests.call_deferred())

func open():
	visible = true
	_populate_quests()

func toggle():
	if visible:
		_hide()
	else:
		open()
		
func _hide():
	visible = false

func _populate_quests():
	if not quest_list: return
	quest_list.clear()
	
	var active_ids = []
	for id in QuestManager.active_quests:
		if QuestManager.active_quests[id].get("status") == "active":
			active_ids.append(id)
	
	if active_ids.is_empty():
		quest_details.text = "[i]No active quests.[/i]"
		return

	for id in active_ids:
		var info = QuestManager.get_quest_info(id)
		var idx = quest_list.add_item(info.get("title", "Unknown Quest"))
		quest_list.set_item_metadata(idx, id)
	
	# Select first by default
	if quest_list.item_count > 0:
		quest_list.select(0)
		_on_quest_selected(0)

func _on_quest_selected(index: int):
	var id = quest_list.get_item_metadata(index)
	var active = QuestManager.get_active_quest_data(id)
	var info = QuestManager.get_quest_info(id)
	
	var text = "[b]%s[/b]\n\n%s\n\n" % [info.get("title"), info.get("description")]
	text += "Progress: %d%%" % active.get("progress", 0)
	
	quest_details.text = text

func _input(event):
	if not visible: return
	
	
	# Close on Swipe Down
	if event is InputEventScreenTouch:
		if event.pressed:
			swipe_start = event.position
		elif not event.pressed:
			if (event.position.y - swipe_start.y) > swipe_threshold:
				_hide()
				
