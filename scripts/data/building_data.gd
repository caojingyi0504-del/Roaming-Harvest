extends Resource
class_name BuildingData

@export var id: StringName
@export var display_name: String = ""
@export var exterior_scene: PackedScene
@export var interior_scene: PackedScene
@export var exterior_spawn_id: StringName
@export var interior_spawn_id: StringName
@export var unlock_requirements: Array[Dictionary] = []
