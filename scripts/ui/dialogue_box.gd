extends PanelContainer

signal option_selected(index: int)
signal advanced()

@onready var speaker_label: Label = %SpeakerLabel
@onready var body_label: Label = %BodyLabel
@onready var options_box: HBoxContainer = %OptionsBox

func show_dialogue(speaker: String, body: String, options: Array = []) -> void:
	speaker_label.text = speaker
	body_label.text = body
	_clear_options()
	for index in range(options.size()):
		var button := Button.new()
		button.text = str(options[index])
		button.pressed.connect(func() -> void:
			option_selected.emit(index)
		)
		options_box.add_child(button)
	visible = true

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advanced.emit()

func _clear_options() -> void:
	for child in options_box.get_children():
		child.queue_free()
