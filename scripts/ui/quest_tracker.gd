extends PanelContainer

@onready var list: VBoxContainer = %QuestList

func set_entries(entries: Array[Dictionary]) -> void:
	for child in list.get_children():
		child.queue_free()
	for entry in entries:
		var label := Label.new()
		label.text = str(entry.get("title", ""))
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list.add_child(label)
	visible = not entries.is_empty()
