extends Node3D
class_name CropPlotComponent

signal planted(plot: Node, crop: Resource)
signal watered(plot: Node)
signal harvested(plot: Node, item_id: StringName, amount: int)
signal state_changed(plot: Node)

@export var plot_id: StringName
@export var crop_data: Resource
@export var watered_today: bool = false

const GrowthComponentScript := preload("res://scripts/components/growth_component.gd")

@onready var growth: Node = get_node_or_null("GrowthComponent")

func _ready() -> void:
	add_to_group("crop_plots")
	if growth == null:
		growth = GrowthComponentScript.new()
		growth.name = "GrowthComponent"
		add_child(growth)
	if crop_data != null:
		_configure_growth()
	if get_node_or_null("/root/CropManager") != null:
		get_node("/root/CropManager").call("register_plot", self)

func plant(new_crop: Resource) -> bool:
	if crop_data != null or new_crop == null:
		return false
	crop_data = new_crop
	watered_today = false
	_configure_growth()
	planted.emit(self, crop_data)
	state_changed.emit(self)
	return true

func water() -> void:
	watered_today = true
	watered.emit(self)
	state_changed.emit(self)

func can_harvest() -> bool:
	return crop_data != null and growth != null and bool(growth.call("is_complete"))

func harvest() -> Dictionary:
	if not can_harvest():
		return {}
	var amount := randi_range(crop_data.harvest_amount_min, crop_data.harvest_amount_max)
	var item_id: StringName = crop_data.get("harvest_item_id")
	crop_data = null
	watered_today = false
	if growth != null:
		growth.set("elapsed_minutes", 0)
		growth.set("current_stage", 0)
	harvested.emit(self, item_id, amount)
	state_changed.emit(self)
	return {"item_id": String(item_id), "amount": amount}

func collect_save_data() -> Dictionary:
	return {
		"plot_id": String(plot_id),
		"crop_id": String(crop_data.get("id")) if crop_data != null else "",
		"watered_today": watered_today,
		"growth": growth.call("collect_save_data") if growth != null else {},
		"position": [global_position.x, global_position.y, global_position.z],
	}

func apply_save_data(data: Dictionary) -> void:
	watered_today = bool(data.get("watered_today", false))
	if growth != null:
		growth.call("apply_save_data", data.get("growth", {}))
	state_changed.emit(self)

func _configure_growth() -> void:
	if crop_data == null or growth == null:
		return
	growth.set("total_growth_minutes", crop_data.get("growth_minutes"))
	growth.set("stage_count", crop_data.get("growth_stage_count"))
