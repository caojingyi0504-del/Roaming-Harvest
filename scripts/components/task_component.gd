extends Node
class_name TaskComponent

signal quest_available(quest: Resource)
signal quest_started(quest_id: StringName)
signal quest_progress_changed(quest_id: StringName, progress: Dictionary)
signal quest_completed(quest_id: StringName)

@export var quests: Array[Resource] = []

var progress_by_quest_id: Dictionary = {}

func _ready() -> void:
	add_to_group("quest_components")
	for quest in quests:
		if quest != null:
			progress_by_quest_id[String(quest.get("id"))] = quest.call("create_progress")
			quest_available.emit(quest)

func start_quest(quest_id: StringName) -> bool:
	var key := String(quest_id)
	if not progress_by_quest_id.has(key):
		return false
	progress_by_quest_id[key]["accepted"] = true
	quest_started.emit(quest_id)
	return true

func add_progress(quest_id: StringName, objective_id: StringName, amount: int = 1) -> void:
	var key := String(quest_id)
	if not progress_by_quest_id.has(key):
		return
	var progress: Dictionary = progress_by_quest_id[key]
	var objectives: Array = progress.get("objectives", [])
	for objective in objectives:
		if str(objective.get("id", "")) == String(objective_id):
			objective["current"] = int(objective.get("current", 0)) + amount
			objective["completed"] = int(objective["current"]) >= int(objective.get("required", 1))
	progress["completed"] = _are_objectives_complete(objectives)
	quest_progress_changed.emit(quest_id, progress)
	if bool(progress["completed"]):
		quest_completed.emit(quest_id)

func collect_save_data() -> Dictionary:
	return progress_by_quest_id.duplicate(true)

func apply_save_data(data: Dictionary) -> void:
	progress_by_quest_id = data.duplicate(true)

func _are_objectives_complete(objectives: Array) -> bool:
	if objectives.is_empty():
		return false
	for objective in objectives:
		if not bool(objective.get("completed", false)):
			return false
	return true
