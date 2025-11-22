# scripts/DialogueUI.gd
extends CanvasLayer
class_name DialogueUI # Added class_name for potential global access

# --- Node References (using @export for better editor linking is a good alternative) ---
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
# New flag to prevent accidental re-ending dialogue during drag
var is_dragging: bool = false 

# --- INITIALIZATION ---

func _ready():
	visible = false
	# Connect signal using the modern Godot 4 syntax
	btn_next.pressed.connect(_on_next_pressed)

## Loads dialogue data from a JSON file path.
func load_dialogue_from_json(path: String) -> Array:
	if not FileAccess.file_exists(path):
		push_error("Dialogue file not found: %s" % path)
		return []

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	# FileAccess.open should not return null if file_exists is checked, 
	# but it's good practice to ensure it's open.
	if file == null:
		push_error("Could not open dialogue file: %s" % path)
		return []

	var json_text: String = file.get_as_text()
	file.close() # Always close the file handle

	var parsed = JSON.parse_string(json_text)
	
	if typeof(parsed) == TYPE_ARRAY:
		return parsed
	
	push_error("Dialogue JSON invalid or malformed: %s" % path)
	return []

## Starts the dialogue sequence.
func start_dialogue(json_data: Array, start_id: String = "intro"):
	dialogue_map.clear()
	for entry in json_data:
		# Check for "id" key to prevent runtime errors
		if entry.has("id") and typeof(entry["id"]) == TYPE_STRING:
			dialogue_map[entry["id"]] = entry
		else:
			push_error("Dialogue entry missing or invalid 'id': %s" % entry)
			
	current_id = start_id
	visible = true
	# Assume QuestTrackerHud is a global Autoload/Singleton
	if is_instance_valid(QuestTrackerHud):
		QuestTrackerHud.collapse_temporarily()
		
	_show_line()

# --- DIALOGUE DISPLAY ---

## Displays the current line of dialogue.
func _show_line():
	var line = dialogue_map.get(current_id, null)
	if line == null:
		_end_dialogue()
		return
		
	# Check conditions before processing or displaying
	if not _conditions_met(line):
		_end_dialogue()
		return

	# Apply consequences before updating UI (e.g., in case an item grants a condition)
	_apply_consequences(line)

	# Update UI elements
	label_name.text = line.get("name", "")
	label_text.text = line.get("text", "")
	
	var portrait_path: String = line.get("portrait", "")
	if portrait_path != "":
		# Use Godot's built-in resource loading
		var texture_resource: Texture2D = load(portrait_path)
		if texture_resource:
			portrait.texture = texture_resource
		else:
			push_warning("Could not load portrait texture: %s" % portrait_path)

	# Handle choices vs. next button visibility
	var has_choices: bool = line.has("choices")
	btn_next.visible = not has_choices
	choices_container.visible = has_choices
	
	# Clear previous choices
	for child in choices_container.get_children():
		child.queue_free()

	if has_choices:
		for choice in line["choices"]:
			# Check choice conditions
			if not _conditions_met(choice):
				continue
				
			var btn := Button.new()
			btn.text = choice.get("text", "...")
			# Use Callable for connection instead of func() for slightly better performance/readability
			btn.pressed.connect(Callable(self, "_on_choice_selected").bind(choice.get("next", ""), choice))
			choices_container.add_child(btn)

	# Play animation if available
	if anim and anim.has_animation("fade_in"):
		anim.play("fade_in")

# --- INPUT AND NAVIGATION ---

func _on_next_pressed():
	var line = dialogue_map.get(current_id, {})
	current_id = line.get("next", "")
	
	if current_id.is_empty(): # Check against empty string
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

# CRITICAL FIX: Robust gesture handling using ScreenTouch (lift) and is_dragging flag
func _input(event):
	# Assume GameState is a global Autoload/Singleton
	if not visible or not GameState.are_gestures_enabled():
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			swipe_start = event.position
			is_dragging = false
		elif not event.pressed:
			# Check gesture completion on lift
			if is_dragging and (event.position.y - swipe_start.y) > swipe_threshold:
				_end_dialogue()
			# Reset state
			is_dragging = false
			
	elif event is InputEventScreenDrag:
		# Set dragging flag
		is_dragging = true

func _end_dialogue():
	visible = false
	# Assume QuestTrackerHud is a global Autoload/Singleton
	if is_instance_valid(QuestTrackerHud):
		QuestTrackerHud.restore_tracker()

# --- GAME STATE INTERACTION (ASSUMES SINGLETONS) ---

## Checks if the required conditions in the data dictionary are met.
func _conditions_met(data: Dictionary) -> bool:
	# Assume GameState is a global Autoload/Singleton with required methods
	if not is_instance_valid(GameState):
		push_error("GameState singleton not available for condition checking.")
		return false
		
	var cond = data.get("conditions", {})
	
	# Check inventory
	if cond.has("inventory_has"):
		if not GameState.has_item(cond["inventory_has"]):
			return false
			
	# Check flags
	if cond.has("flags"):
		# Ensure flags is an array (Godot is weakly typed)
		if typeof(cond["flags"]) == TYPE_ARRAY:
			for flag in cond["flags"]:
				if not GameState.has_flag(flag):
					return false
		else:
			push_warning("Dialogue condition 'flags' is not an array.")
			
	return true

## Applies the consequences defined in the data dictionary.
func _apply_consequences(data: Dictionary):
	# Assume GameState, QuestManager are global Autoloads/Singletons
	if not is_instance_valid(GameState) or not is_instance_valid(QuestManager):
		push_error("Required singletons (GameState/QuestManager) not available for consequences.")
		return
		
	var cons = data.get("consequences", {})
	
	if cons.has("add_item"):
		GameState.add_item(cons["add_item"])
		
	if cons.has("set_flag"):
		GameState.add_flag(cons["set_flag"])
		
	if cons.has("start_quest"):
		QuestManager.start_quest(cons["start_quest"])
		
	if cons.has("complete_quest"):
		QuestManager.complete_quest(cons["complete_quest"])
