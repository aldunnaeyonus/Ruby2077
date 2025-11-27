extends Node

signal quest_started(id: String)
signal quest_updated(id: String)
signal quest_completed(id: String)

var quest_definitions := {}
var active_quests := {}

func _ready():
	load_quests_from_json("res://data/quests.json")

func load_quests_from_json(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_error("Quest file missing: %s" % path)
		return
		
	var file = FileAccess.open(path, FileAccess.READ)
	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	
	if err == OK and typeof(json.get_data()) == TYPE_DICTIONARY:
		quest_definitions = json.get_data()
	else:
		push_error("Failed to parse quest JSON at %s" % path)

func get_quest_status(id: String) -> String:
	if active_quests.has(id):
		return active_quests[id]["status"]
	return "none"

func start_quest(id: String) -> void:
	if active_quests.has(id): return
	
	var def = quest_definitions.get(id)
	if not def:
		push_warning("Quest ID not found: %s" % id)
		return
		
	# Check Prereqs
	for req in def.get("requires", []):
		if get_quest_status(req) != "completed":
			return # Prereq not met
			
	active_quests[id] = {
		"status": "active",
		"progress": 0,
		"xp": def.get("xp", 0),
		"rewards": def.get("rewards", [])
	}
	
	quest_started.emit(id)
	quest_updated.emit(id)

func complete_quest(id: String) -> void:
	if not active_quests.has(id): return
	if active_quests[id]["status"] == "completed": return
	
	active_quests[id]["status"] = "completed"
	
	# Rewards
	if is_instance_valid(GameState):
		GameState.add_xp(active_quests[id]["xp"])
		for item in active_quests[id]["rewards"]:
			GameState.add_item(item)
			
	quest_completed.emit(id)
	quest_updated.emit(id)