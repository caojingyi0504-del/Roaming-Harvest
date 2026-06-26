extends CanvasLayer

signal fade_finished()

const InteractionPromptScene := preload("res://scenes/ui/InteractionPrompt.tscn")
const DialogueBoxScene := preload("res://scenes/ui/DialogueBox.tscn")
const QuestTrackerScene := preload("res://scenes/ui/QuestTracker.tscn")
const InventoryPanelScene := preload("res://scenes/ui/InventoryPanel.tscn")
const FadeScene := preload("res://scenes/ui/FadeOverlay.tscn")

var interaction_prompt: Control
var dialogue_box: Control
var quest_tracker: Control
var inventory_panel: Control
var fade_overlay: ColorRect

func _ready() -> void:
	layer = 50
	_build_ui()

func show_interaction_prompt(text: String) -> void:
	if interaction_prompt != null and interaction_prompt.has_method("show_prompt"):
		interaction_prompt.show_prompt(text)

func hide_interaction_prompt() -> void:
	if interaction_prompt != null:
		interaction_prompt.visible = false

func show_dialogue(speaker: String, body: String, options: Array = []) -> void:
	if dialogue_box != null and dialogue_box.has_method("show_dialogue"):
		dialogue_box.show_dialogue(speaker, body, options)

func hide_dialogue() -> void:
	if dialogue_box != null:
		dialogue_box.visible = false

func set_quest_entries(entries: Array[Dictionary]) -> void:
	if quest_tracker != null and quest_tracker.has_method("set_entries"):
		quest_tracker.set_entries(entries)

func set_inventory_snapshot(snapshot: Dictionary) -> void:
	if inventory_panel != null and inventory_panel.has_method("set_snapshot"):
		inventory_panel.set_snapshot(snapshot)

func show_inventory(visible: bool = true) -> void:
	if inventory_panel != null:
		inventory_panel.visible = visible

func fade_to(alpha: float, seconds: float = 0.25) -> void:
	if fade_overlay == null:
		return
	var tween := create_tween()
	tween.tween_property(fade_overlay, "color:a", clampf(alpha, 0.0, 1.0), seconds)
	tween.finished.connect(func() -> void:
		fade_finished.emit()
	)

func _build_ui() -> void:
	interaction_prompt = InteractionPromptScene.instantiate() as Control
	dialogue_box = DialogueBoxScene.instantiate() as Control
	quest_tracker = QuestTrackerScene.instantiate() as Control
	inventory_panel = InventoryPanelScene.instantiate() as Control
	fade_overlay = FadeScene.instantiate() as ColorRect
	add_child(interaction_prompt)
	add_child(dialogue_box)
	add_child(quest_tracker)
	add_child(inventory_panel)
	add_child(fade_overlay)
	interaction_prompt.visible = false
	dialogue_box.visible = false
	quest_tracker.visible = false
	inventory_panel.visible = false
	if get_node_or_null("/root/InventoryManager") != null:
		get_node("/root/InventoryManager").inventory_changed.connect(set_inventory_snapshot)
