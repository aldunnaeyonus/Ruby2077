# scripts/UIHUD/QuestTrackerHUD.gd
extends CanvasLayer
class_name QuestTrackerHUD

# --- Node References ---
@onready var quest_list: VBoxContainer = $SafeAreaRoot/TrackerPanel/VBoxContainer/QuestList
@onready var btn_toggle: Button = $SafeAreaRoot/TrackerPanel/VBoxContainer/HBoxHeader/ButtonToggle
@onready var anim: AnimationPlayer = $AnimationPlayer

# --- State and Configuration ---
var collapsed := false
var was_collapsed := false
@export var swipe_threshold: float = 100.0
var swipe_start := Vector2.ZERO
var touch_index: int = -1

func _ready():
	# Safety Check: Ensure Autoloads exist
	if not is_instance_valid(QuestManager):
		push_error("QuestManager Autoload not found.")
		return
	
	# Safety Check: Ensure Nodes exist
	if quest_list == null:
		push_error("FATAL: QuestTrackerHUD cannot find 'QuestList' node. Check Scene Tree paths.")
		return

	# Initialize state
	collapsed = GameState.is_tracker_collapsed() if is_instance_valid(GameState) else false
	quest_list.visible = not collapsed
	
	if btn_toggle:
		btn_toggle.rotation_degrees = -90.0 if collapsed else 0.0
		btn_toggle.pressed.connect(_toggle_tracker)
	
	QuestManager.quest_updated.connect(update_tracker)
	update_tracker()

func _toggle_tracker():
	if quest_list == null: return
	
	collapsed = !collapsed
	if is_instance_valid(GameState):
		GameState.set_tracker_collapsed(collapsed)
	
	if anim and anim.has_animation("arrow_collapse") and anim.has_animation("arrow_expand"):
		var anim_to_play = "arrow_collapse" if collapsed else "arrow_expand"
		anim.play(anim_to_play)
	else:
		if btn_toggle: btn_toggle.rotation_degrees = -90.0 if collapsed else 0.0
		quest_list.visible = not collapsed

func collapse_temporarily():
	if quest_list == null: return
	was_collapsed = collapsed
	collapsed = true
	quest_list.visible = false
	if btn_toggle: btn_toggle.rotation_degrees = -90.0

func restore_tracker():
	if quest_list == null: return
	collapsed = was_collapsed
	if is_instance_valid(GameState):
		GameState.set_tracker_collapsed(collapsed)
	
	if btn_toggle: btn_toggle.rotation_degrees = -90.0 if collapsed else 0.0
	quest_list.visible = not collapsed

func update_tracker():
	if quest_list == null: return

	for child in quest_list.get_children():
		child.queue_free()
		
	for id in QuestManager.active_quests.keys():
		var q = QuestManager.active_quests[id]
		if q.get("status", "active") != "active":
			continue
			
		var label := Label.new()
		var title: String = QuestManager.get_quest_info(id).get("title", id)
		var progress: int = q.get("progress", 0)
		
		label.text = "%s (%d%%)" % [title, progress]
		# Optional: Add theme overrides here if needed
		quest_list.add_child(label)

func _input(event):
	if is_instance_valid(GameState) and not GameState.are_gestures_enabled():
		return
		
	if event is InputEventScreenTouch:
		if event.pressed and touch_index == -1:
			swipe_start = event.position
			touch_index = event.index
		elif not event.pressed and event.index == touch_index:
			var delta: Vector2 = event.position - swipe_start
			touch_index = -1
			
			if delta.x < -swipe_threshold and not collapsed:
				_toggle_tracker()
			elif delta.x > swipe_threshold and collapsed:
				_toggle_tracker()