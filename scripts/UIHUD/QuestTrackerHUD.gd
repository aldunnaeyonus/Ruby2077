# scripts/QuestTrackerHUD.gd
extends CanvasLayer

# --- Node References ---
@onready var quest_list: VBoxContainer = $SafeAreaRoot/TrackerPanel/VBoxContainer/QuestList
@onready var btn_toggle: Button = $SafeAreaRoot/TrackerPanel/VBoxContainer/HBoxHeader/ButtonToggle
@onready var anim: AnimationPlayer = $AnimationPlayer

# --- State and Configuration ---
var collapsed := false
var was_collapsed := false # Used for temporary state changes (e.g., during Dialogue)
@export var swipe_threshold: float = 100.0
var swipe_start := Vector2.ZERO
var touch_index: int = -1 # Track touch ID for multi-touch safety

func _ready():
	# Assume GameState is an Autoload Singleton
	if not is_instance_valid(GameState) or not is_instance_valid(QuestManager):
		push_error("GameState or QuestManager Autoload not found.")
		return
	
	# === CRITICAL FIX: Check if quest_list was found ===
	if quest_list == null:
		push_error("FATAL ERROR: QuestTrackerHUD failed to find the 'QuestList' node. Check path!")
		return # Stop execution if a critical node is missing

	# Initialize state from GameState
	collapsed = GameState.is_tracker_collapsed()
	quest_list.visible = not collapsed
	
	# Correct Ternary Syntax for initial rotation
	btn_toggle.rotation_degrees = -90.0 if collapsed else 0.0
	
	btn_toggle.pressed.connect(_toggle_tracker)
	QuestManager.quest_updated.connect(update_tracker)
	
	update_tracker()

## Toggles the tracker between collapsed and expanded states.
func _toggle_tracker():
	if quest_list == null: return
	
	collapsed = !collapsed
	GameState.set_tracker_collapsed(collapsed)
	
	# Play animation or use fallback
	if anim and anim.has_animation("arrow_collapse") and anim.has_animation("arrow_expand"):
		var anim_to_play = "arrow_collapse" if collapsed else "arrow_expand"
		anim.play(anim_to_play)
	else:
		# Fallback: Manual rotation and visibility update
		btn_toggle.rotation_degrees = -90.0 if collapsed else 0.0
		quest_list.visible = not collapsed

## Collapses the tracker without changing the persistent state (e.g., during Dialogue).
func collapse_temporarily():
	if quest_list == null: return

	was_collapsed = collapsed
	collapsed = true
	quest_list.visible = false
	
	if anim and anim.has_animation("arrow_collapse"):
		anim.play("arrow_collapse")
	else:
		btn_toggle.rotation_degrees = -90.0

## Restores the tracker to its state prior to collapse_temporarily().
func restore_tracker():
	if quest_list == null: return
	
	collapsed = was_collapsed
	
	# Update persistent state only if the restored state is different
	GameState.set_tracker_collapsed(collapsed)
	
	# Play animation or use fallback
	if anim and anim.has_animation("arrow_collapse") and anim.has_animation("arrow_expand"):
		var anim_to_play = "arrow_collapse" if collapsed else "arrow_expand"
		anim.play(anim_to_play)
	else:
		# Fallback: Manual rotation and visibility update
		btn_toggle.rotation_degrees = -90.0 if collapsed else 0.0
		quest_list.visible = not collapsed

## Updates the list of active quests currently being tracked.
func update_tracker():
	if quest_list == null: return

	# Standard way to clear children in Godot
	for child in quest_list.get_children():
		child.queue_free()
		
	for id in QuestManager.active_quests.keys():
		var q = QuestManager.active_quests[id]
		# Only display quests with "active" status
		if q.get("status", "active") != "active":
			continue
			
		var label := Label.new()
		var title: String = QuestManager.get_quest_info(id).get("title", id)
		var progress: int = q.get("progress", 0)
		
		# Format the text with color for better readability
		label.text = "[b]%s[/b] ([color=yellow]%d%%[/color])" % [title, progress]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		label.set("theme_override_colors/font_color", Color.WHITE) # Ensure text is visible
		label.set("theme_override_constants/line_spacing", 2)
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.set_h_size_flags(Control.SIZE_EXPAND_FILL)
		label.set_v_size_flags(Control.SIZE_SHRINK_BEGIN)
		
		quest_list.add_child(label)

## Handles input for swipe gestures to expand/collapse the tracker.
func _input(event):
	# Only process input if gestures are enabled
	if not GameState.are_gestures_enabled():
		return
		
	if event is InputEventScreenTouch:
		if event.pressed and touch_index == -1:
			# Start tracking the swipe
			swipe_start = event.position
			touch_index = event.index
		
		elif not event.pressed and event.index == touch_index:
			# End of Touch (Finger lifted): Perform the final swipe check
			var delta: Vector2 = event.position - swipe_start
			
			# Reset touch state regardless of whether a swipe occurred
			touch_index = -1
			
			# Check Swipe Left (Collapse)
			if delta.x < -swipe_threshold and not collapsed:
				_toggle_tracker()
				
			# Check Swipe Right (Expand)
			elif delta.x > swipe_threshold and collapsed:
				_toggle_tracker()
