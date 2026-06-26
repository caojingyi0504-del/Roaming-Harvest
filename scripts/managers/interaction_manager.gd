extends Node

signal focused_interactable_changed(interactable: Node)
signal interaction_performed(interactable: Node, interactor: Node)

var candidates: Array[Node] = []
var focused_interactable: Node
var interactor: Node

func register_interactor(node: Node) -> void:
	interactor = node

func register_candidate(interactable: Node) -> void:
	if interactable == null or candidates.has(interactable):
		return
	candidates.append(interactable)
	_refresh_focus()

func unregister_candidate(interactable: Node) -> void:
	candidates.erase(interactable)
	if focused_interactable == interactable:
		focused_interactable = null
	_refresh_focus()

func perform_interaction() -> bool:
	_refresh_focus()
	if focused_interactable == null:
		return false
	var game_manager := get_node_or_null("/root/GameManager")
	var actor: Node = interactor
	if actor == null and game_manager != null:
		actor = game_manager.get("player")
	if not focused_interactable.interact(actor):
		return false
	interaction_performed.emit(focused_interactable, actor)
	return true

func _process(_delta: float) -> void:
	_refresh_focus()

func _refresh_focus() -> void:
	candidates = candidates.filter(func(candidate: Node) -> bool:
		return is_instance_valid(candidate) and candidate.has_method("can_interact") and candidate.can_interact(interactor)
	)
	candidates.sort_custom(func(a: Node, b: Node) -> bool:
		return int(a.get("interaction_priority")) > int(b.get("interaction_priority"))
	)
	var next_focus: Node = candidates[0] if not candidates.is_empty() else null
	if focused_interactable == next_focus:
		return
	focused_interactable = next_focus
	focused_interactable_changed.emit(focused_interactable)
	if get_node_or_null("/root/UIManager") != null:
		if focused_interactable != null:
			get_node("/root/UIManager").call("show_interaction_prompt", str(focused_interactable.call("get_prompt")))
		else:
			get_node("/root/UIManager").call("hide_interaction_prompt")
