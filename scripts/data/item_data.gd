extends Resource
class_name ItemData

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var stack_limit: int = 99
@export var sell_price: int = 0
@export var buy_price: int = 0
@export var tags: Array[StringName] = []

func is_valid() -> bool:
	return id != StringName()
