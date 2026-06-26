extends Node

signal inventory_changed(snapshot: Dictionary)
signal item_added(item_id: StringName, amount: int)
signal item_removed(item_id: StringName, amount: int)

var items: Dictionary = {}
var unlocked_slot_count: int = 12

func add_item(item_id: StringName, amount: int = 1) -> void:
	if amount <= 0 or item_id == StringName():
		return
	var key := String(item_id)
	items[key] = int(items.get(key, 0)) + amount
	item_added.emit(item_id, amount)
	inventory_changed.emit(get_inventory_snapshot())

func remove_item(item_id: StringName, amount: int = 1) -> bool:
	var key := String(item_id)
	if amount <= 0 or int(items.get(key, 0)) < amount:
		return false
	items[key] = int(items[key]) - amount
	if int(items[key]) <= 0:
		items.erase(key)
	item_removed.emit(item_id, amount)
	inventory_changed.emit(get_inventory_snapshot())
	return true

func has_item(item_id: StringName, amount: int = 1) -> bool:
	return int(items.get(String(item_id), 0)) >= amount

func clear() -> void:
	items.clear()
	inventory_changed.emit(get_inventory_snapshot())

func get_inventory_snapshot() -> Dictionary:
	return {
		"items": items.duplicate(true),
		"unlocked_slot_count": unlocked_slot_count,
	}

func apply_inventory_snapshot(snapshot: Dictionary) -> void:
	items = snapshot.get("items", {}).duplicate(true)
	unlocked_slot_count = int(snapshot.get("unlocked_slot_count", unlocked_slot_count))
	inventory_changed.emit(get_inventory_snapshot())
