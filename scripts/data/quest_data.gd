extends Resource
class_name QuestData

@export var id: StringName
@export var title: String = ""
@export_multiline var description: String = ""
@export var objectives: Array[Dictionary] = []
@export var rewards: Array[Dictionary] = []
@export var prerequisite_quest_ids: Array[StringName] = []
@export var repeatable: bool = false

func create_progress() -> Dictionary:
	var objective_progress: Array[Dictionary] = []
	for objective in objectives:
		objective_progress.append({
			"id": objective.get("id", ""),
			"current": 0,
			"required": int(objective.get("required", 1)),
			"completed": false,
		})
	return {
		"quest_id": String(id),
		"accepted": false,
		"completed": false,
		"objectives": objective_progress,
	}
