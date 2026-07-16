extends Node

var failures: Array[String] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var world_scene := load("res://scenes/GrassWorld.tscn") as PackedScene
	var world := world_scene.instantiate()
	add_child(world)
	await get_tree().process_frame

	world.set("_business_level_stars", {})
	world.call("_update_business_duel_button")
	var prep_button := world.get("_business_duel_button") as Button
	_check(prep_button != null and not prep_button.visible, "第5关未通过时经营准备入口必须隐藏")

	world.set("_business_level_stars", {"5": 1})
	world.call("_update_business_duel_button")
	_check(prep_button != null and prep_button.visible, "第5关历史星级达到1星后入口必须显示")
	world.set("_business_result_data", {"level_id": 5, "flower_garden_unlocked_now": true})
	world.call("_update_business_result_garden_button")
	world.call("_update_business_result_duel_button")
	var result_button := world.get("_business_result_duel_button") as Button
	_check(result_button != null and result_button.visible, "第5关结算必须显示双人竞速入口")
	var result_buttons := world.get("_business_result_buttons") as HBoxContainer
	var result_overlay := world.get("_business_result_overlay") as Control
	result_overlay.visible = true
	result_buttons.visible = true
	await get_tree().process_frame
	var visible_result_buttons: Array[Control] = []
	for child in result_buttons.get_children():
		if child is Control and child.visible:
			visible_result_buttons.append(child)
	_check(visible_result_buttons.size() == 4, "首次通关第5关时结算区必须容纳四个按钮")
	for index in range(1, visible_result_buttons.size()):
		var previous_button := visible_result_buttons[index - 1]
		var current_button := visible_result_buttons[index]
		_check(previous_button.position.x + previous_button.size.x <= current_button.position.x, "结算按钮不能重叠")

	var prep_overlay := world.get("_business_prep_overlay") as Control
	prep_overlay.visible = true
	result_overlay.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	world.call("_open_duel_overlay")
	await get_tree().process_frame
	var duel := get_tree().root.get_node_or_null("DuelSession")
	_check(duel != null, "嵌入联机节点必须挂到SceneTree根节点")
	_check(get_tree().root.get_node_or_null("DuelSession/Endpoint") != null, "RPC端点路径必须为/root/DuelSession/Endpoint")
	_check(get_tree().paused, "进入联机时单人世界必须暂停")
	_check(is_instance_valid(world), "进入联机时不能销毁单人世界")

	if duel != null:
		duel.call("leave_duel")
	await get_tree().process_frame
	_check(not get_tree().paused, "退出联机后必须恢复SceneTree暂停状态")
	_check(is_instance_valid(world), "退出联机后必须复用原单人世界")
	_check(prep_overlay.visible, "退出联机后必须恢复进入前的经营准备界面")
	_check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "退出联机后必须恢复鼠标状态")

	prep_overlay.visible = false
	result_overlay.visible = true
	world.call("_open_duel_overlay")
	await get_tree().process_frame
	duel = get_tree().root.get_node_or_null("DuelSession")
	if duel != null:
		duel.call("leave_duel")
	await get_tree().process_frame
	_check(result_overlay.visible, "从结算入口退出联机后必须恢复原结算界面")

	if failures.is_empty():
		print("DUEL_ENTRY_SMOKE_OK")
		get_tree().quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("DUEL_ENTRY_SMOKE_FAILED count=%d" % failures.size())
	get_tree().quit(1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
