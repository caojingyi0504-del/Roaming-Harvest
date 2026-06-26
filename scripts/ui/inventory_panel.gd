extends PanelContainer

@onready var grid: GridContainer = %InventoryGrid

func set_snapshot(snapshot: Dictionary) -> void:
	for child in grid.get_children():
		child.queue_free()
	var items: Dictionary = snapshot.get("items", {})
	var unlocked_slot_count := int(snapshot.get("unlocked_slot_count", 12))
	var keys := items.keys()
	for index in range(unlocked_slot_count):
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(72.0, 72.0)
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		if index < keys.size():
			var item_id := str(keys[index])
			label.text = "%s\nx%s" % [item_id, items[item_id]]
		slot.add_child(label)
		grid.add_child(slot)
