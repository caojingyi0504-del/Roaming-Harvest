extends Node
class_name ShopComponent

signal shop_opened(shop: ShopComponent)
signal transaction_completed(item_id: StringName, amount: int, total_price: int)
signal transaction_failed(reason: String)

@export var shop_id: StringName
@export var stock: Array[Dictionary] = []
@export var accepts_selling: bool = true

func open_shop() -> void:
	shop_opened.emit(self)

func buy(item_id: StringName, amount: int = 1) -> bool:
	var entry := _find_stock(item_id)
	if entry.is_empty():
		transaction_failed.emit("item_not_in_stock")
		return false
	var total_price := int(entry.get("buy_price", 0)) * amount
	if get_node_or_null("/root/InventoryManager") != null:
		get_node("/root/InventoryManager").call("add_item", item_id, amount)
	transaction_completed.emit(item_id, amount, total_price)
	return true

func sell(item_id: StringName, amount: int = 1) -> bool:
	if not accepts_selling:
		transaction_failed.emit("selling_disabled")
		return false
	if get_node_or_null("/root/InventoryManager") != null and not bool(get_node("/root/InventoryManager").call("remove_item", item_id, amount)):
		transaction_failed.emit("missing_item")
		return false
	var entry := _find_stock(item_id)
	var total_price := int(entry.get("sell_price", 0)) * amount
	transaction_completed.emit(item_id, amount, total_price)
	return true

func _find_stock(item_id: StringName) -> Dictionary:
	for entry in stock:
		if StringName(str(entry.get("item_id", ""))) == item_id:
			return entry
	return {}
