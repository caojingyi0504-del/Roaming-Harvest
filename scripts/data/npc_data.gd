extends Resource
class_name NpcData

@export var id: StringName
@export var display_name: String = ""
@export var portrait: Texture2D
@export var default_dialogue_id: StringName
@export var shop_id: StringName
@export var quest_ids: Array[StringName] = []
@export var schedule: Dictionary = {}
