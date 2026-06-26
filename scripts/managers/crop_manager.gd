extends Node

signal plot_registered(plot: Node)
signal crop_planted(plot_id: StringName, crop_id: StringName)
signal crop_harvested(plot_id: StringName, item_id: StringName, amount: int)

var plots: Dictionary = {}
var crop_catalog: Dictionary = {}

func register_plot(plot: Node) -> void:
	if plot == null:
		return
	var plot_id_value: Variant = plot.get("plot_id")
	var key := String(plot_id_value) if plot_id_value != StringName() else str(plot.get_instance_id())
	plots[key] = plot
	if plot.has_signal("harvested") and not plot.is_connected("harvested", _on_plot_harvested):
		plot.connect("harvested", _on_plot_harvested)
	if plot.has_signal("planted") and not plot.is_connected("planted", _on_plot_planted):
		plot.connect("planted", _on_plot_planted)
	plot_registered.emit(plot)

func unregister_plot(plot: Node) -> void:
	if plot == null:
		return
	plots.erase(String(plot.get("plot_id")))

func register_crop_data(crop: Resource) -> void:
	if crop != null:
		crop_catalog[String(crop.id)] = crop

func plant(plot_id: StringName, crop_id: StringName) -> bool:
	var plot := plots.get(String(plot_id)) as Node
	var crop := crop_catalog.get(String(crop_id)) as Resource
	if plot == null or crop == null:
		return false
	return plot.plant(crop)

func get_crop_snapshot() -> Dictionary:
	var data := {}
	for key in plots.keys():
		var plot := plots[key] as Node
		if plot != null and is_instance_valid(plot):
			data[key] = plot.collect_save_data()
	return data

func apply_crop_snapshot(snapshot: Dictionary) -> void:
	for key in snapshot.keys():
		var plot := plots.get(key) as Node
		if plot != null:
			plot.apply_save_data(snapshot[key])

func _on_plot_planted(plot: Node, crop: Resource) -> void:
	crop_planted.emit(plot.get("plot_id"), crop.get("id"))

func _on_plot_harvested(plot: Node, item_id: StringName, amount: int) -> void:
	if get_node_or_null("/root/InventoryManager") != null:
		get_node("/root/InventoryManager").call("add_item", item_id, amount)
	crop_harvested.emit(plot.get("plot_id"), item_id, amount)
