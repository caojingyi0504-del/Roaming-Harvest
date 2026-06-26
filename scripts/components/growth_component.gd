extends Node
class_name GrowthComponent

signal stage_changed(stage: int)
signal growth_completed()

@export var total_growth_minutes: int = 1440
@export var stage_count: int = 3
@export var auto_register_with_time: bool = true

var elapsed_minutes: int = 0
var current_stage: int = 0
var paused: bool = false

func _ready() -> void:
	if auto_register_with_time and get_node_or_null("/root/TimeManager") != null:
		get_node("/root/TimeManager").minute_passed.connect(_on_minute_passed)

func advance(minutes: int) -> void:
	if paused or minutes <= 0 or is_complete():
		return
	elapsed_minutes = mini(elapsed_minutes + minutes, total_growth_minutes)
	var next_stage := get_stage()
	if next_stage != current_stage:
		current_stage = next_stage
		stage_changed.emit(current_stage)
	if is_complete():
		growth_completed.emit()

func get_progress() -> float:
	if total_growth_minutes <= 0:
		return 1.0
	return clampf(float(elapsed_minutes) / float(total_growth_minutes), 0.0, 1.0)

func get_stage() -> int:
	if stage_count <= 1:
		return 0
	return clampi(floori(get_progress() * float(stage_count)), 0, stage_count - 1)

func is_complete() -> bool:
	return elapsed_minutes >= total_growth_minutes

func collect_save_data() -> Dictionary:
	return {
		"elapsed_minutes": elapsed_minutes,
		"current_stage": current_stage,
		"paused": paused,
	}

func apply_save_data(data: Dictionary) -> void:
	elapsed_minutes = int(data.get("elapsed_minutes", 0))
	current_stage = int(data.get("current_stage", get_stage()))
	paused = bool(data.get("paused", false))
	stage_changed.emit(current_stage)

func _on_minute_passed(_day: int, _hour: int, _minute: int) -> void:
	advance(1)
