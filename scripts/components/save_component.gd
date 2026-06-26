extends Node
class_name SaveComponent

signal save_requested(save_id: StringName)
signal loaded(data: Dictionary)

@export var save_id: StringName
@export var include_parent_transform: bool = true
@export var custom_data: Dictionary = {}

func _ready() -> void:
	add_to_group("saveable")

func collect_save_data() -> Dictionary:
	var data := custom_data.duplicate(true)
	data["save_id"] = String(save_id)
	if include_parent_transform and get_parent() is Node3D:
		var parent_3d := get_parent() as Node3D
		data["position"] = _vector3_to_array(parent_3d.global_position)
		data["rotation"] = _vector3_to_array(parent_3d.global_rotation)
	return data

func apply_save_data(data: Dictionary) -> void:
	custom_data = data.duplicate(true)
	if include_parent_transform and get_parent() is Node3D and data.has("position"):
		var parent_3d := get_parent() as Node3D
		parent_3d.global_position = _array_to_vector3(data.get("position", []))
		if data.has("rotation"):
			parent_3d.global_rotation = _array_to_vector3(data.get("rotation", []))
	loaded.emit(data)

func request_save() -> void:
	save_requested.emit(save_id)

func _vector3_to_array(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]

func _array_to_vector3(value: Array) -> Vector3:
	if value.size() < 3:
		return Vector3.ZERO
	return Vector3(float(value[0]), float(value[1]), float(value[2]))
