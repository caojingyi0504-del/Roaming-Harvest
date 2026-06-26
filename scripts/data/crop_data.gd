extends Resource
class_name CropData

@export var id: StringName
@export var display_name: String = ""
@export var seed_item_id: StringName
@export var harvest_item_id: StringName
@export var growth_minutes: int = 1440
@export var growth_stage_count: int = 3
@export var needs_water_each_day: bool = true
@export var harvest_amount_min: int = 1
@export var harvest_amount_max: int = 1
@export var stage_meshes: Array[PackedScene] = []

func get_stage_for_progress(progress: float) -> int:
	var clamped := clampf(progress, 0.0, 1.0)
	return clampi(floori(clamped * float(growth_stage_count)), 0, maxi(growth_stage_count - 1, 0))
