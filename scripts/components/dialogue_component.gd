extends Node
class_name DialogueComponent

signal dialogue_requested(npc_data: Resource, dialogue_id: StringName)

@export var npc_data: Resource
@export var dialogue_id: StringName

func start_dialogue() -> void:
	var resolved_dialogue_id := dialogue_id
	if resolved_dialogue_id == StringName() and npc_data != null:
		resolved_dialogue_id = npc_data.get("default_dialogue_id")
	dialogue_requested.emit(npc_data, resolved_dialogue_id)
	if get_node_or_null("/root/UIManager") != null:
		var speaker: String = str(npc_data.get("display_name")) if npc_data != null else ""
		get_node("/root/UIManager").call("show_dialogue", speaker, "", [])
