extends CanvasLayer
class_name DialogueUI

# --- Node References ---
@onready var label_name = $SafeAreaRoot/DialoguePanel/VBoxContainer/HBoxContainer/LabelName
@onready var label_text = $SafeAreaRoot/DialoguePanel/VBoxContainer/LabelText
@onready var portrait = $SafeAreaRoot/DialoguePanel/VBoxContainer/HBoxContainer/Portrait
@onready var choices_container = $SafeAreaRoot/DialoguePanel/VBoxContainer/ChoicesContainer
@onready var btn_next = $SafeAreaRoot/DialoguePanel/VBoxContainer/ButtonNext
@onready var anim = $AnimationPlayer

# --- Dialogue State ---
var dialogue_map: Dictionary = {}
var current_id: String = ""

# --- Swipe/Gesture State ---
@export var swipe_threshold: float = 100.0
var swipe_start := Vector2.ZERO
var is_dragging: bool = false 

# --- INITIALIZATION ---

func _ready():
	visible = false
	if btn_next:
		btn_next.pressed.connect(_on_next_pressed)

func load_dialogue_from_json(path: String) -> Array:
	if not FileAccess.file_exists(path):
		push_error("Dialogue file not found: %s" % path)
		return []

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open dialogue file: %s" % path)
		return []

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_text)
	
	if error == OK:
		if typeof(json.data) == TYPE_ARRAY:
			return json.data
	
	push_error("Dialogue JSON invalid: %s" % path)
	return []

func start_dialogue(json_data: Array, start_id: String = "intro"):
	dialogue_map.clear()
	for entry in json_data:
		if entry.has("id") and typeof(entry["id"]) == TYPE_STRING:
			dialogue_map[entry["id"]] = entry
		else:
			push_error("Dialogue entry missing 'id'")
			
	current_id = start_id
	visible = true
	
	# FIX: Match Autoload name from project.godot (QuestTrackerHud)
	if is_instance_valid(QuestTrackerHud):
		QuestTrackerHud.collapse_temporarily()
		
	_show_line()

func _show_line():
	var line = dialogue_map.get(current_id, null)
	if line == null:
		_end_dialogue()
		return
		
	if not _conditions_met(line):
		_end_dialogue()
		return

	_apply_consequences(line)

	label_name.text = line.get("name", "")
	label_text.text = line.get("text", "")
	
	var portrait_path = line.get("portrait", "")
	if portrait_path != "":
		var tex = load(portrait_path)
		if tex: portrait.texture = tex

	var has_choices = line.has("choices")
	btn_next.visible = not has_choices
	choices_container.visible = has_choices
	
	for child in choices_container.get_children():
		child.queue_free()

	if has_choices:
		for choice in line["choices"]:
			if not _conditions_met(choice):
				continue
			var btn = Button.new()
			btn.text = choice.get("text", "...")
			btn.pressed.connect(Callable(self, "_on_choice_selected").bind(choice.get("next", ""), choice))
			choices_container.add_child(btn)

	if anim and anim.has_animation("fade_in"):
		anim.play("fade_in")

func _on_next_pressed():
	var line = dialogue_map.get(current_id, {})
	current_id = line.get("next", "")
	if current_id.is_empty():
		_end_dialogue()
		return
	_show_line()

func _on_choice_selected(next_id: String, choice: Dictionary):
	_apply_consequences(choice)
	current_id = next_id
	if current_id.is_empty():
		_end_dialogue()
		return
	_show_line()

func _input(event):
	if not visible or (is_instance_valid(GameState) and not GameState.are_gestures_enabled()):
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			swipe_start = event.position
			is_dragging = false
		elif not event.pressed:
			if is_dragging and (event.position.y - swipe_start.y) > swipe_threshold:
				_end_dialogue()
			is_dragging = false
	elif event is InputEventScreenDrag:
		is_dragging = true

func _end_dialogue():
	visible = false
	# FIX: Match Autoload name from project.godot
	if is_instance_valid(QuestTrackerHud):
		QuestTrackerHud.restore_tracker()

func _conditions_met(data: Dictionary) -> bool:
	if not is_instance_valid(GameState): return false
	var cond = data.get("conditions", {})
	
	if cond.has("inventory_has") and not GameState.has_item(cond["inventory_has"]):
		return false
	if cond.has("flags"):
		for flag in cond["flags"]:
			if not GameState.has_flag(flag):
				return false
	return true

func _apply_consequences(data: Dictionary):
	if not is_instance_valid(GameState) or not is_instance_valid(QuestManager): return
	
	var cons = data.get("consequences", {})
	if cons.has("add_item"): GameState.add_item(cons["add_item"])
	if cons.has("set_flag"): GameState.add_flag(cons["set_flag"])
	if cons.has("start_quest"): QuestManager.start_quest(cons["start_quest"])
	if cons.has("complete_quest"): QuestManager.complete_quest(cons["complete_quest"])
