extends PanelContainer

@onready var label: Label = %PromptLabel

func show_prompt(text: String) -> void:
	label.text = text
	visible = text.strip_edges() != ""
