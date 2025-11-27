extends CanvasLayer
class_name QuestTrackerHUD

# --- NODES ---
@onready var quest_list: VBoxContainer = $SafeAreaRoot/TrackerPanel/VBoxContainer/QuestList
@onready var btn_toggle: TextureButton = $SafeAreaRoot/TrackerPanel/VBoxContainer/HBoxHeader/ButtonToggle
@onready var anim: AnimationPlayer = $AnimationPlayer

# --- STATE ---
var collapsed := false
var was_collapsed := false
var swipe_start := Vector2.ZERO
var touch_index: int = -1
@export var swipe_threshold: float = 100.0

func _ready():
	if not is_instance_valid(QuestManager): return
	
	# Initial State
	if is_instance_valid(GameState):
		collapsed = GameState.is_tracker_collapsed()
	
	_update_visibility()
	
	if btn_toggle:
		btn_toggle.pressed.connect(_toggle_tracker)
	
	QuestManager.quest_updated.connect(update_tracker)
	QuestManager.quest_started.connect(func(_id): update_tracker())
	QuestManager.quest_completed.connect(func(_id): update_tracker())
	
	update_tracker()

func _toggle_tracker():
	collapsed = !collapsed
	if is_instance_valid(GameState):
		GameState.set_tracker_collapsed(collapsed)
	
	if anim and anim.has_animation("arrow_collapse"):
		anim.play("arrow_collapse" if collapsed else "arrow_expand")
	else:
		_update_visibility()

func _update_visibility():
	if quest_list: quest_list.visible = not collapsed
	if btn_toggle: btn_toggle.rotation_degrees = -90.0 if collapsed else 0.0

func collapse_temporarily():
	was_collapsed = collapsed
	collapsed = true
	_update_visibility()

func restore_tracker():
	collapsed = was_collapsed
	if is_instance_valid(GameState):
		GameState.set_tracker_collapsed(collapsed)
	_update_visibility()

func update_tracker(_id = ""):
	if not quest_list: return

	# Clear existing (Simple approach for consistency)
	for child in quest_list.get_children():
		child.queue_free()
		
	# Populate Active Quests
	for q_id in QuestManager.active_quests:
		var q_data = QuestManager.active_quests[q_id]
		if q_data.get("status") != "active": continue
			
		var info = QuestManager.get_quest_info(q_id)
		var label = Label.new()
		label.text = "- %s: %d%%" % [info.get("title", "Quest"), q_data.get("progress", 0)]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		quest_list.add_child(label)

func _input(event):
	if is_instance_valid(GameState) and not GameState.are_gestures_enabled(): return

	if event is InputEventScreenTouch:
		if event.pressed and touch_index == -1:
			swipe_start = event.position
			touch_index = event.index
		elif not event.pressed and event.index == touch_index:
			var delta = event.position.x - swipe_start.x
			if abs(delta) > swipe_threshold:
				if (delta < 0 and not collapsed) or (delta > 0 and collapsed):
					_toggle_tracker()
			touch_index = -1
			