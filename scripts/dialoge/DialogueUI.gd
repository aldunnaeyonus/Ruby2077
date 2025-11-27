extends CanvasLayer
class_name DialogueUI

# --- NODES ---
@onready var label_name = $SafeAreaRoot/DialoguePanel/VBoxContainer/HBoxContainer/LabelName
@onready var label_text = $SafeAreaRoot/DialoguePanel/VBoxContainer/LabelText
@onready var portrait = $SafeAreaRoot/DialoguePanel/VBoxContainer/HBoxContainer/Portrait
@onready var choices_container = $SafeAreaRoot/DialoguePanel/VBoxContainer/ChoicesContainer
@onready var btn_next = $SafeAreaRoot/DialoguePanel/VBoxContainer/ButtonNext
@onready var anim = $AnimationPlayer

# --- STATE ---
var dialogue_map: Dictionary = {}
var current_id: String = ""
var swipe_start := Vector2.ZERO
var dragging := false
const SWIPE_THRESHOLD = 100.0

func _ready():
	visible = false
	if btn_next: btn_next.pressed.connect(_on_next_pressed)

func start_dialogue(json_data: Array, start_id: String = "intro"):
	dialogue_map.clear()
	for entry in json_data:
		if entry.has("id"): dialogue_map[entry["id"]] = entry
			
	current_id = start_id
	visible = true
	
	# Hide Quest Tracker if it exists
	if is_instance_valid(QuestTrackerHud):
		QuestTrackerHud.collapse_temporarily()
		
	_show_line()

func _show_line():
	var line = dialogue_map.get(current_id)
	if not line or not _check_conditions(line):
		_end_dialogue()
		return

	_apply_consequences(line)

	# Update UI
	label_name.text = line.get("name", "Unknown")
	label_text.text = line.get("text", "...")
	
	if line.has("portrait"):
		var tex = load(line["portrait"])
		if tex: portrait.texture = tex

	# Handle Choices vs Next Button
	var choices = line.get("choices", [])
	var valid_choices = []
	
	for c in choices:
		if _check_conditions(c): valid_choices.append(c)
	
	btn_next.visible = valid_choices.is_empty()
	choices_container.visible = not valid_choices.is_empty()
	
	# Clear old choices
	for child in choices_container.get_children():
		child.queue_free()
		
	# Create new choices
	for c in valid_choices:
		var btn = Button.new()
		btn.text = c.get("text", "Option")
		btn.pressed.connect(_on_choice_selected.bind(c.get("next", ""), c))
		choices_container.add_child(btn)

	if anim and anim.has_animation("fade_in"):
		anim.play("fade_in")

func _on_next_pressed():
	var line = dialogue_map.get(current_id, {})
	current_id = line.get("next", "")
	if current_id.is_empty():
		_end_dialogue()
	else:
		_show_line()

func _on_choice_selected(next_id: String, choice_data: Dictionary):
	_apply_consequences(choice_data)
	current_id = next_id
	if current_id.is_empty():
		_end_dialogue()
	else:
		_show_line()

func _end_dialogue():
	visible = false
	if is_instance_valid(QuestTrackerHud):
		QuestTrackerHud.restore_tracker()

# --- LOGIC HELPERS ---

func _check_conditions(data: Dictionary) -> bool:
	if not is_instance_valid(GameState): return true
	
	var cond = data.get("conditions", {})
	if cond.has("inventory_has") and not GameState.has_item(cond["inventory_has"]):
		return false
	if cond.has("flag") and not GameState.has_flag(cond["flag"]):
		return false
	return true

func _apply_consequences(data: Dictionary):
	if not is_instance_valid(GameState): return
	
	var cons = data.get("consequences", {})
	if cons.has("add_item"): GameState.add_item(cons["add_item"])
	if cons.has("set_flag"): GameState.add_flag(cons["set_flag"])
	if cons.has("start_quest"): QuestManager.start_quest(cons["start_quest"])
	if cons.has("complete_quest"): QuestManager.complete_quest(cons["complete_quest"])

# --- GESTURES ---
func _input(event):
	if not visible: return
	if event is InputEventScreenTouch:
		if event.pressed:
			swipe_start = event.position
			dragging = false
		elif not event.pressed:
			if dragging and (event.position.y - swipe_start.y) > SWIPE_THRESHOLD:
				_end_dialogue()
			dragging = false
	elif event is InputEventScreenDrag:
		dragging = true
		