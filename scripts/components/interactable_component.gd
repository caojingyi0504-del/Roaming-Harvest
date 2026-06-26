extends Area3D
class_name InteractableComponent

signal focus_entered(interactable: InteractableComponent)
signal focus_exited(interactable: InteractableComponent)
signal interacted(interactor: Node)

@export var prompt_text: String = "Interact"
@export var action_name: StringName = &"interact"
@export var interaction_enabled: bool = true
@export var interaction_priority: int = 0

var _focused_by: Node

func _ready() -> void:
	monitoring = true
	monitorable = true
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	if not area_exited.is_connected(_on_area_exited):
		area_exited.connect(_on_area_exited)

func can_interact(_interactor: Node = null) -> bool:
	return interaction_enabled

func interact(interactor: Node = null) -> bool:
	if not can_interact(interactor):
		return false
	interacted.emit(interactor)
	return true

func get_prompt() -> String:
	return prompt_text

func _on_area_entered(area: Area3D) -> void:
	_focused_by = area
	focus_entered.emit(self)
	if get_node_or_null("/root/InteractionManager") != null:
		get_node("/root/InteractionManager").call("register_candidate", self)

func _on_area_exited(area: Area3D) -> void:
	if _focused_by == area:
		_focused_by = null
	focus_exited.emit(self)
	if get_node_or_null("/root/InteractionManager") != null:
		get_node("/root/InteractionManager").call("unregister_candidate", self)
