extends Node

var failures: Array[String] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var world_scene := load("res://scenes/GrassWorld.tscn") as PackedScene
	var world := world_scene.instantiate()
	add_child(world)
	await get_tree().process_frame

	var panel := world.get("_held_crop_quality_panel") as PanelContainer
	var item_label := world.get("_held_crop_quality_label") as Label
	var freshness_label := world.get("_held_crop_freshness_label") as Label
	var pickup_feed := world.get("_pickup_feed") as VBoxContainer
	var day_clock := world.get("_day_clock_panel") as Control
	var resource_hud := world.get("_coin_hud") as Control
	_check(panel != null and item_label != null and freshness_label != null, "手持食材状态卡必须完整创建")

	world.set("_held_crop_item", "carrot")
	world.set("_held_crop_quality", 0)
	world.set("_held_crop_fresh_time", 83.0)
	world.call("_update_held_crop_quality_panel")
	await get_tree().process_frame
	_check(panel.visible, "手持普通作物时状态卡必须显示")
	_check(is_equal_approx(panel.offset_left, 18.0) and is_equal_approx(panel.offset_top, 72.0), "状态卡必须位于顶部资源栏下方")
	_check(is_equal_approx(panel.offset_bottom, 116.0), "状态卡高度必须保持44px")
	_check(item_label.text == "胡萝卜 · 普通品质", "左列必须显示食材名称和品质")
	_check(freshness_label.text == "1:23 后腐烂", "右列必须单独显示腐烂倒计时")
	_check(is_equal_approx(pickup_feed.offset_top, 128.0), "状态卡显示时拾取提示必须向下避让")
	_check(not panel.get_global_rect().intersects(day_clock.get_global_rect()), "状态卡不能与日期时钟重叠")
	_check(not panel.get_global_rect().intersects(resource_hud.get_global_rect()), "状态卡不能与顶部资源栏重叠")

	var stable_position := panel.position
	var stable_size := panel.size
	world.set("_held_crop_fresh_time", 28.0)
	world.call("_update_held_crop_quality_panel")
	await get_tree().process_frame
	_check(panel.position == stable_position and panel.size == stable_size, "倒计时刷新时状态卡不能抖动")

	world.set("_held_crop_item", "")
	world.set("_kitchen_held_item", "washed_pea")
	world.set("_kitchen_held_quality", 1)
	world.set("_kitchen_held_fresh_time", 65.0)
	world.call("_update_held_crop_quality_panel")
	await get_tree().process_frame
	_check(panel.visible, "手持经营加工食材时状态卡必须显示")
	_check(item_label.text == "洗净豌豆 · ⭐", "加工食材必须沿用同一状态卡")
	_check(freshness_label.text == "1:05 后腐烂", "加工食材倒计时必须正确显示")

	world.set("_kitchen_held_item", "")
	world.call("_update_held_crop_quality_panel")
	await get_tree().process_frame
	_check(not panel.visible, "没有手持易腐食材时状态卡必须隐藏")
	_check(is_equal_approx(pickup_feed.offset_top, 92.0), "状态卡隐藏后拾取提示必须恢复原位置")

	if failures.is_empty():
		print("HELD_STATUS_UI_SMOKE_OK window=%s viewport=%s" % [get_window().size, get_viewport().get_visible_rect().size])
		get_tree().quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("HELD_STATUS_UI_SMOKE_FAILED count=%d" % failures.size())
	get_tree().quit(1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
