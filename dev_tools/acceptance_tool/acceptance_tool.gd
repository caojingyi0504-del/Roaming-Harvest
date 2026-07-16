extends Node

## Runtime-only acceptance helper. This file deliberately talks to GrassWorld through
## dynamic property/method access so the production gameplay script stays untouched.

const KitchenUpgradeCatalog = preload("res://scripts/kitchen_upgrade_catalog.gd")
const LocalEventCatalog = preload("res://scripts/local_event_catalog.gd")

const CROP_IDS: Array[String] = ["carrot", "pea", "eggplant", "tomato", "bell_pepper", "pumpkin", "strawberry", "sweet_corn", "moon_mushroom", "marshmallow"]
const CROP_NAMES: Array[String] = ["胡萝卜", "豌豆", "茄子", "番茄", "甜椒", "南瓜", "草莓", "甜玉米", "月光蘑菇", "棉花糖"]
const EQUIPMENT_IDS: Array[String] = ["sink", "cutting_table", "pot", "grill", "prep_shelf"]
const EQUIPMENT_NAMES: Array[String] = ["洗菜池", "简易料理台", "煮锅", "烧烤架", "备菜架"]
const FEATURE_IDS: Array[String] = ["wind", "sifter", "camper", "traveler", "opening_sign"]
const FEATURE_NAMES: Array[String] = ["逐风", "奥提筛种", "房车驾驶", "旅人", "开业木牌"]
const FEATURE_STATES: Array[String] = ["未解锁", "已解锁·未看引导", "已完成"]
const TELEPORT_NAMES: Array[String] = ["房车", "农田/妈妈", "奥提筛种", "逐风区域", "旅人", "瑞巴斯商店", "兔子聚会", "候鸟集市", "树精菌市", "篝火故事会"]
const TELEPORT_POSITIONS: Array[Vector3] = [
	Vector3(15.8, 0.0, 8.8),
	Vector3(-0.8, 0.0, 2.0),
	Vector3(-31.4, 0.0, 21.9),
	Vector3(-15.0, 0.0, -7.0),
	Vector3(5.7, 0.0, 12.8),
	Vector3(-32.784, 0.0, 11.879),
	Vector3(49.0, 0.0, -22.0),
	Vector3(35.0, 0.0, 31.0),
	Vector3(-43.0, 0.0, -28.0),
	Vector3(-24.0, 0.0, 36.0),
]

var _enabled := false
var _world: Node
var _world_properties: Dictionary = {}
var _layer: CanvasLayer
var _root: Control
var _launcher: Button
var _panel: PanelContainer
var _status_label: Label
var _panel_open := false
var _session_hidden := false
var _previous_tree_paused := false
var _previous_mouse_mode := Input.MOUSE_MODE_CAPTURED
var _scene_poll_elapsed := 0.0
var _status_poll_elapsed := 0.0

var _seed_crop_index := 0
var _seed_quality := 0
var _food_crop_index := 0
var _food_quality := 0
var _selected_level := 1
var _selected_equipment := 0
var _selected_upgrade_index := 0
var _selected_village_index := 0
var _selected_teleport := 0
var _feature_states: Dictionary = {}

var _seed_crop_button: Button
var _seed_quality_button: Button
var _seed_amount: SpinBox
var _seed_current_label: Label
var _food_crop_button: Button
var _food_quality_button: Button
var _food_amount: SpinBox
var _food_current_label: Label
var _coins_amount: SpinBox
var _coop_coins_amount: SpinBox
var _stamina_amount: SpinBox
var _popularity_amount: SpinBox
var _level_button: Button
var _level_button_secondary: Button
var _level_star_amount: SpinBox
var _auto_fill_check: CheckBox
var _business_served_amount: SpinBox
var _business_state_label: Label
var _teleport_button: Button
var _equipment_button: Button
var _equipment_level_amount: SpinBox
var _upgrade_button: Button
var _upgrade_state_label: Label
var _village_button: Button
var _village_state_label: Label
var _feature_buttons: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_enabled = OS.is_debug_build()
	if not _enabled:
		return
	set_process(true)
	set_process_unhandled_key_input(true)
	call_deferred("_sync_scene")


func _exit_tree() -> void:
	if _panel_open and is_inside_tree():
		_restore_game_input()


func _process(delta: float) -> void:
	if not _enabled:
		return
	_scene_poll_elapsed += delta
	_status_poll_elapsed += delta
	if _scene_poll_elapsed >= 0.25:
		_scene_poll_elapsed = 0.0
		_sync_scene()
	if _panel_open and _status_poll_elapsed >= 0.25:
		_status_poll_elapsed = 0.0
		_refresh_live_labels()


func _unhandled_key_input(event: InputEvent) -> void:
	if not _enabled or not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_F10:
		if _session_hidden:
			_session_hidden = false
			if _layer != null:
				_layer.visible = true
		_toggle_panel()
		get_viewport().set_input_as_handled()
	elif key_event.keycode == KEY_ESCAPE and _panel_open:
		_close_panel()
		get_viewport().set_input_as_handled()


func _sync_scene() -> void:
	var current := get_tree().current_scene
	var valid_world := _is_grass_world(current)
	if not valid_world:
		if _panel_open:
			_close_panel()
		_world = null
		_world_properties.clear()
		_destroy_ui()
		return
	if current != _world:
		if _panel_open:
			_close_panel()
		_world = current
		_cache_world_properties()
		_destroy_ui()
		_build_ui()
	elif _layer == null or not is_instance_valid(_layer):
		_cache_world_properties()
		_build_ui()
	if _layer != null:
		_layer.visible = not _session_hidden


func _is_grass_world(node: Node) -> bool:
	if node == null:
		return false
	if node.name == "GrassWorld":
		return true
	var script := node.get_script() as Script
	return script != null and str(script.resource_path).ends_with("/grass_world.gd")


func _cache_world_properties() -> void:
	_world_properties.clear()
	if _world == null:
		return
	for property_data in _world.get_property_list():
		_world_properties[str(property_data.get("name", ""))] = true


func _has_world_property(property_name: String) -> bool:
	return _world != null and is_instance_valid(_world) and _world_properties.has(property_name)


func _get_world(property_name: String, fallback: Variant = null) -> Variant:
	if not _has_world_property(property_name):
		return fallback
	return _world.get(property_name)


func _set_world(property_name: String, value: Variant) -> bool:
	if not _has_world_property(property_name):
		return false
	_world.set(property_name, value)
	return true


func _call_world(method_name: String, args: Array = [], fallback: Variant = null) -> Variant:
	if _world == null or not is_instance_valid(_world) or not _world.has_method(method_name):
		return fallback
	return _world.callv(method_name, args)


func _sync_feature_states_from_world() -> void:
	_feature_states["wind"] = 2 if bool(_get_world("_wind_chase_completed", false)) else (1 if bool(_get_world("_wind_chase_unlocked", false)) else 0)
	_feature_states["sifter"] = 2 if bool(_get_world("_sifter_intro_completed", false)) else (1 if bool(_get_world("_sifter_unlocked", false)) else 0)
	_feature_states["camper"] = 2 if bool(_get_world("_camper_drive_note_seen", false)) and bool(_get_world("_camper_drive_unlocked", false)) else (1 if bool(_get_world("_camper_drive_unlocked", false)) else 0)
	var traveler_exists := _get_world("_young_traveler") is Node
	_feature_states["traveler"] = 2 if bool(_get_world("_traveler_intro_completed", false)) else (1 if traveler_exists else 0)
	var warehouse: Dictionary = _get_world("_warehouse_items", {}) as Dictionary
	_feature_states["opening_sign"] = 2 if bool(_get_world("_opening_sign_placed", false)) else (1 if int(warehouse.get("rv_open_sign", 0)) > 0 else 0)


func _destroy_ui() -> void:
	if _layer != null and is_instance_valid(_layer):
		_layer.queue_free()
	_layer = null
	_root = null
	_launcher = null
	_panel = null
	_status_label = null
	_panel_open = false
	_feature_buttons.clear()


func _build_ui() -> void:
	_sync_feature_states_from_world()
	_layer = CanvasLayer.new()
	_layer.name = "AcceptanceToolLayer"
	_layer.layer = 240
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_layer)

	_root = Control.new()
	_root.name = "AcceptanceToolRoot"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.process_mode = Node.PROCESS_MODE_ALWAYS
	_layer.add_child(_root)

	_launcher = Button.new()
	_launcher.name = "AcceptanceLauncher"
	_launcher.text = "验"
	_launcher.tooltip_text = "验收工具（F10）"
	_launcher.anchor_left = 1.0
	_launcher.anchor_top = 1.0
	_launcher.anchor_right = 1.0
	_launcher.anchor_bottom = 1.0
	_launcher.offset_left = -54.0
	_launcher.offset_top = -54.0
	_launcher.offset_right = -12.0
	_launcher.offset_bottom = -12.0
	_launcher.focus_mode = Control.FOCUS_NONE
	_launcher.mouse_filter = Control.MOUSE_FILTER_STOP
	_launcher.add_theme_font_size_override("font_size", 16)
	_launcher.add_theme_stylebox_override("normal", _style_box(Color(0.19, 0.12, 0.06, 0.58), Color(0.50, 0.35, 0.16, 0.72), 2, 8))
	_launcher.add_theme_stylebox_override("hover", _style_box(Color(0.32, 0.20, 0.08, 0.94), Color(0.86, 0.66, 0.28, 0.95), 2, 8))
	_launcher.add_theme_stylebox_override("pressed", _style_box(Color(0.12, 0.08, 0.04, 0.96), Color(0.92, 0.72, 0.34, 1.0), 2, 8))
	_launcher.add_theme_color_override("font_color", Color(0.95, 0.85, 0.61, 0.82))
	_launcher.pressed.connect(_toggle_panel)
	_root.add_child(_launcher)

	_panel = PanelContainer.new()
	_panel.name = "AcceptancePanel"
	_panel.anchor_left = 1.0
	_panel.anchor_top = 1.0
	_panel.anchor_right = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = -574.0
	_panel.offset_top = -692.0
	_panel.offset_right = -12.0
	_panel.offset_bottom = -64.0
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	_panel.visible = false
	_panel.add_theme_stylebox_override("panel", _style_box(Color(0.12, 0.075, 0.035, 0.985), Color(0.62, 0.42, 0.18, 1.0), 3, 12))
	_root.add_child(_panel)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 7)
	_panel.add_child(outer)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	outer.add_child(header)
	var title := Label.new()
	title.text = "验收工具  ·  仅当前运行"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.56))
	header.add_child(title)
	var hide_button := _make_button("隐藏", _hide_for_session, 64.0)
	header.add_child(hide_button)
	var close_button := _make_button("×", _close_panel, 40.0)
	close_button.add_theme_font_size_override("font_size", 20)
	header.add_child(close_button)

	var tabs := TabContainer.new()
	tabs.name = "AcceptanceTabs"
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.custom_minimum_size = Vector2(0.0, 510.0)
	tabs.mouse_filter = Control.MOUSE_FILTER_STOP
	outer.add_child(tabs)
	_build_quick_page(tabs)
	_build_resources_page(tabs)
	_build_progress_page(tabs)
	_build_business_page(tabs)
	_build_world_page(tabs)
	_build_upgrades_page(tabs)

	_status_label = Label.new()
	_status_label.text = "准备就绪"
	_status_label.custom_minimum_size = Vector2(0.0, 25.0)
	_status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_status_label.add_theme_font_size_override("font_size", 13)
	_status_label.add_theme_color_override("font_color", Color(0.80, 0.92, 0.67))
	outer.add_child(_status_label)
	_refresh_cycle_button_texts()


func _build_quick_page(tabs: TabContainer) -> void:
	var box := _make_tab(tabs, "快捷预设")
	var intro := _make_section(box, "教程与基础状态")
	_add_wrapped_note(intro, "跳过教程会进入第一章大世界，补齐基础工具与厨房入口，但不会自动通关经营关卡。")
	_add_button_row(intro, [
		_make_button("完成基础教程", _skip_basic_tutorial, 154.0),
		_make_button("全功能解锁", _unlock_everything, 132.0),
	])
	_add_button_row(intro, [
		_make_button("恢复新档并重载", _reload_clean_world, 154.0),
		_make_button("刷新所有界面", _refresh_world_ui, 132.0),
	])

	var level := _make_section(box, "关卡快速验收")
	var level_row := HBoxContainer.new()
	level.add_child(level_row)
	level_row.add_child(_small_label("目标关卡"))
	_level_button = _make_button("第1关", _cycle_level, 96.0)
	level_row.add_child(_level_button)
	_auto_fill_check = CheckBox.new()
	_auto_fill_check.text = "自动补食材、体力和设备"
	_auto_fill_check.button_pressed = true
	_auto_fill_check.focus_mode = Control.FOCUS_NONE
	level_row.add_child(_auto_fill_check)
	_add_button_row(level, [
		_make_button("准备并打开关卡页", _prepare_and_open_level, 180.0),
		_make_button("准备并立即开始", _prepare_and_start_level, 170.0),
	])
	_add_wrapped_note(level, "目标关卡之前的关卡自动设为至少1星；只补齐门槛，不扣除资源。")

	var convenience := _make_section(box, "常用快捷操作")
	_add_button_row(convenience, [
		_make_button("金币设为 10000", _set_quick_coins, 154.0),
		_make_button("体力回满", _fill_stamina, 110.0),
		_make_button("全部种子各20", _grant_all_seeds, 150.0),
	])
	_add_button_row(convenience, [
		_make_button("清空手持物", _clear_held_items, 130.0),
		_make_button("发放工具/测试材料", _grant_test_items, 190.0),
	])


func _build_resources_page(tabs: TabContainer) -> void:
	var box := _make_tab(tabs, "资源")
	var seeds := _make_section(box, "种子库存")
	var seed_pick := HBoxContainer.new()
	seeds.add_child(seed_pick)
	_seed_crop_button = _make_button("胡萝卜", _cycle_seed_crop, 110.0)
	seed_pick.add_child(_seed_crop_button)
	_seed_quality_button = _make_button("品质 0", _cycle_seed_quality, 90.0)
	seed_pick.add_child(_seed_quality_button)
	_seed_amount = _make_spin(0, 999, 1, 20)
	seed_pick.add_child(_seed_amount)
	_seed_current_label = _small_label("当前 0")
	_seed_current_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seed_pick.add_child(_seed_current_label)
	_add_button_row(seeds, [
		_make_button("设置数量", _set_selected_seed, 105.0),
		_make_button("+10", _add_selected_seed.bind(10), 72.0),
		_make_button("-10", _add_selected_seed.bind(-10), 72.0),
		_make_button("全部清空", _clear_all_seeds, 105.0),
	])

	var food := _make_section(box, "食材箱库存")
	var food_pick := HBoxContainer.new()
	food.add_child(food_pick)
	_food_crop_button = _make_button("胡萝卜", _cycle_food_crop, 110.0)
	food_pick.add_child(_food_crop_button)
	_food_quality_button = _make_button("品质 0", _cycle_food_quality, 90.0)
	food_pick.add_child(_food_quality_button)
	_food_amount = _make_spin(0, 999, 1, 5)
	food_pick.add_child(_food_amount)
	_food_current_label = _small_label("当前 0")
	_food_current_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	food_pick.add_child(_food_current_label)
	_add_button_row(food, [
		_make_button("设置库存", _set_selected_food, 110.0),
		_make_button("补齐目标关卡", _fill_selected_level_requirements, 150.0),
		_make_button("清空食材箱", _clear_food_storage, 122.0),
	])

	var currency := _make_section(box, "货币与成长")
	var grid := GridContainer.new()
	grid.columns = 3
	currency.add_child(grid)
	grid.add_child(_small_label("个人金币"))
	_coins_amount = _make_spin(0, 999999, 100, 10000)
	grid.add_child(_coins_amount)
	grid.add_child(_make_button("应用", _apply_coins, 72.0))
	grid.add_child(_small_label("合作金币"))
	_coop_coins_amount = _make_spin(0, 999999, 10, 1000)
	grid.add_child(_coop_coins_amount)
	grid.add_child(_make_button("应用", _apply_coop_coins, 72.0))
	grid.add_child(_small_label("厨房体力"))
	_stamina_amount = _make_spin(0, 30, 1, 30)
	grid.add_child(_stamina_amount)
	grid.add_child(_make_button("应用", _apply_stamina, 72.0))
	grid.add_child(_small_label("人气经验"))
	_popularity_amount = _make_spin(0, 99999, 10, 120)
	grid.add_child(_popularity_amount)
	grid.add_child(_make_button("应用", _apply_popularity, 72.0))


func _build_progress_page(tabs: TabContainer) -> void:
	var box := _make_tab(tabs, "进度")
	var stars := _make_section(box, "关卡星级（不重复发首通奖励）")
	var row := HBoxContainer.new()
	stars.add_child(row)
	row.add_child(_small_label("关卡"))
	_level_button_secondary = _make_button("第1关", _cycle_level, 96.0)
	row.add_child(_level_button_secondary)
	row.add_child(_small_label("设为"))
	_level_star_amount = _make_spin(0, 3, 1, 1)
	row.add_child(_level_star_amount)
	row.add_child(_make_button("星并同步解锁", _apply_level_stars, 142.0))

	var features := _make_section(box, "玩法三态")
	_add_wrapped_note(features, "点状态按钮循环切换，再点右侧应用。‘已解锁·未看引导’用于验收首次引导。")
	for index in range(FEATURE_IDS.size()):
		if not _feature_states.has(FEATURE_IDS[index]):
			_feature_states[FEATURE_IDS[index]] = 0
		var feature_row := HBoxContainer.new()
		features.add_child(feature_row)
		var name_label := _small_label(FEATURE_NAMES[index])
		name_label.custom_minimum_size.x = 100.0
		feature_row.add_child(name_label)
		var state_button := _make_button(FEATURE_STATES[0], _cycle_feature.bind(FEATURE_IDS[index]), 205.0)
		state_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		feature_row.add_child(state_button)
		_feature_buttons[FEATURE_IDS[index]] = state_button
		feature_row.add_child(_make_button("应用", _apply_feature.bind(FEATURE_IDS[index]), 72.0))
	_add_button_row(features, [
		_make_button("全部设为已解锁·未看引导", _set_all_features_unseen, 245.0),
		_make_button("全部完成", _set_all_features_complete, 120.0),
	])


func _build_business_page(tabs: TabContainer) -> void:
	var box := _make_tab(tabs, "经营")
	var active := _make_section(box, "当前营业")
	_business_state_label = Label.new()
	_business_state_label.text = "当前没有营业关卡"
	_business_state_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	active.add_child(_business_state_label)
	_add_button_row(active, [
		_make_button("时间 +30秒", _change_business_time.bind(30.0), 106.0),
		_make_button("时间 -30秒", _change_business_time.bind(-30.0), 106.0),
		_make_button("完成当前订单", _complete_active_order, 126.0),
		_make_button("当前订单超时", _expire_active_order, 126.0),
	])
	var finish_row := HBoxContainer.new()
	active.add_child(finish_row)
	finish_row.add_child(_small_label("结算前设完成单数"))
	_business_served_amount = _make_spin(0, 20, 1, 1)
	finish_row.add_child(_business_served_amount)
	finish_row.add_child(_make_button("按此数量立即结算", _finish_business_with_count, 184.0))
	_add_button_row(active, [
		_make_button("直接结束当前营业", _finish_business_now, 184.0),
		_make_button("清空厨房运行状态", _clear_kitchen_runtime, 184.0),
	])
	_add_wrapped_note(active, "完成当前订单会走真实订单奖励与礼花逻辑；按数量结算只用于星级边界测试。")

	var speed := _make_section(box, "运行速度")
	_add_button_row(speed, [
		_make_button("暂停", _set_time_scale.bind(0.0), 82.0),
		_make_button("0.5×", _set_time_scale.bind(0.5), 82.0),
		_make_button("1×", _set_time_scale.bind(1.0), 82.0),
		_make_button("2×", _set_time_scale.bind(2.0), 82.0),
		_make_button("4×", _set_time_scale.bind(4.0), 82.0),
	])
	_add_wrapped_note(speed, "倍率在关闭验收面板后生效；F10 始终可以重新打开工具。")


func _build_world_page(tabs: TabContainer) -> void:
	var box := _make_tab(tabs, "世界")
	var clock := _make_section(box, "昼夜时间")
	_add_button_row(clock, [
		_make_button("06:00 黎明", _set_game_time.bind(6), 110.0),
		_make_button("12:00 白天", _set_game_time.bind(12), 110.0),
		_make_button("18:00 黄昏", _set_game_time.bind(18), 110.0),
		_make_button("22:00 夜晚", _set_game_time.bind(22), 110.0),
	])
	_add_button_row(clock, [
		_make_button("冻结时间", _set_clock_frozen.bind(true), 110.0),
		_make_button("恢复流速", _set_clock_frozen.bind(false), 110.0),
	])
	var events := _make_section(box, "地方突发经营")
	for event_id in LocalEventCatalog.ALL_IDS:
		var event_config := LocalEventCatalog.get_event(event_id)
		var event_row := HBoxContainer.new()
		events.add_child(event_row)
		var event_name := _small_label(str(event_config.get("short_name", event_id)))
		event_name.custom_minimum_size.x = 110.0
		event_row.add_child(event_name)
		event_row.add_child(_make_button("生成并传送", _force_local_event.bind(event_id), 126.0))
		event_row.add_child(_make_button("设为首通", _pass_local_event.bind(event_id), 105.0))
		event_row.add_child(_make_button("重置", _reset_local_event.bind(event_id), 72.0))
	var farm := _make_section(box, "农田")
	_add_button_row(farm, [
		_make_button("全部浇水", _water_all_crops, 110.0),
		_make_button("全部成熟", _mature_all_crops, 110.0),
		_make_button("恢复腐烂作物", _restore_rotten_crops, 138.0),
		_make_button("清除杂草", _clear_all_weeds, 110.0),
	])
	_add_button_row(farm, [
		_make_button("在空耕地生成当前种子", _spawn_selected_crop, 220.0),
		_make_button("水壶加满", _fill_watering_can, 110.0),
	])

	var teleport := _make_section(box, "快速传送")
	var teleport_row := HBoxContainer.new()
	teleport.add_child(teleport_row)
	_teleport_button = _make_button(TELEPORT_NAMES[0], _cycle_teleport, 190.0)
	_teleport_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	teleport_row.add_child(_teleport_button)
	teleport_row.add_child(_make_button("传送", _teleport_player, 100.0))
	_add_wrapped_note(teleport, "传送会先退出屋内状态，并按当前地形高度修正玩家位置。")


func _build_upgrades_page(tabs: TabContainer) -> void:
	var box := _make_tab(tabs, "升级")
	var equipment := _make_section(box, "房车设备数量等级")
	var equipment_row := HBoxContainer.new()
	equipment.add_child(equipment_row)
	_equipment_button = _make_button(EQUIPMENT_NAMES[0], _cycle_equipment, 150.0)
	equipment_row.add_child(_equipment_button)
	_equipment_level_amount = _make_spin(1, 5, 1, 1)
	equipment_row.add_child(_equipment_level_amount)
	equipment_row.add_child(_make_button("设置等级", _apply_equipment_level, 112.0))
	_add_button_row(equipment, [
		_make_button("全部设备 Lv.5", _max_all_equipment_levels, 150.0),
		_make_button("生成验收布局", _create_acceptance_layout, 150.0),
		_make_button("清空设备任务", _clear_kitchen_runtime, 138.0),
	])

	var functional := _make_section(box, "当前设备的 8 项功能改造")
	_upgrade_button = _make_button("第1项", _cycle_function_upgrade, 220.0)
	functional.add_child(_upgrade_button)
	_upgrade_state_label = _small_label("状态：未购买")
	functional.add_child(_upgrade_state_label)
	_add_button_row(functional, [
		_make_button("切换当前项购买状态", _toggle_function_upgrade, 205.0),
		_make_button("当前设备全部购买", _buy_all_current_equipment_upgrades, 190.0),
	])
	_add_button_row(functional, [
		_make_button("重置当前设备改造", _reset_current_equipment_upgrades, 170.0),
	])

	var village := _make_section(box, "村落改造")
	_village_button = _make_button("第1项", _cycle_village_upgrade, 220.0)
	village.add_child(_village_button)
	_village_state_label = _small_label("状态：未购买")
	village.add_child(_village_state_label)
	_add_button_row(village, [
		_make_button("切换当前项目", _toggle_village_upgrade, 160.0),
		_make_button("全部完成", _buy_all_village_upgrades, 120.0),
		_make_button("全部重置", _reset_village_upgrades, 120.0),
	])


func _make_tab(tabs: TabContainer, tab_name: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = tab_name
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	scroll.add_child(box)
	return box


func _make_section(parent: VBoxContainer, title_text: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _style_box(Color(0.88, 0.77, 0.55, 0.96), Color(0.45, 0.28, 0.10, 1.0), 2, 7))
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	var label := Label.new()
	label.text = title_text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.24, 0.13, 0.045))
	box.add_child(label)
	return box


func _add_wrapped_note(parent: VBoxContainer, text_value: String) -> void:
	var label := Label.new()
	label.text = text_value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.34, 0.22, 0.10))
	parent.add_child(label)


func _add_button_row(parent: VBoxContainer, buttons: Array[Button]) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)
	for button in buttons:
		row.add_child(button)


func _small_label(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.25, 0.15, 0.06))
	return label


func _make_button(text_value: String, callback: Callable, minimum_width: float = 92.0) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(minimum_width, 34.0)
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", Color(0.25, 0.14, 0.045))
	button.add_theme_color_override("font_hover_color", Color(0.16, 0.08, 0.02))
	button.add_theme_stylebox_override("normal", _style_box(Color(0.94, 0.84, 0.63), Color(0.40, 0.24, 0.08), 2, 6))
	button.add_theme_stylebox_override("hover", _style_box(Color(1.0, 0.91, 0.68), Color(0.72, 0.46, 0.13), 2, 6))
	button.add_theme_stylebox_override("pressed", _style_box(Color(0.78, 0.63, 0.40), Color(0.32, 0.18, 0.05), 2, 6))
	if callback.is_valid():
		button.pressed.connect(callback)
	return button


func _make_spin(minimum: float, maximum: float, step_value: float, initial: float) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = minimum
	spin.max_value = maximum
	spin.step = step_value
	spin.value = initial
	spin.custom_minimum_size = Vector2(104.0, 34.0)
	spin.allow_greater = false
	spin.allow_lesser = false
	spin.update_on_text_changed = true
	spin.get_line_edit().context_menu_enabled = false
	spin.get_line_edit().select_all_on_focus = true
	return spin


func _style_box(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 7.0
	style.content_margin_bottom = 7.0
	return style


func _toggle_panel() -> void:
	if _panel == null:
		return
	if _panel_open:
		_close_panel()
	else:
		_open_panel()


func _open_panel() -> void:
	if _panel == null or _world == null:
		return
	_panel_open = true
	_previous_tree_paused = get_tree().paused
	_previous_mouse_mode = Input.mouse_mode
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_panel.visible = true
	_panel.move_to_front()
	_launcher.visible = false
	_refresh_cycle_button_texts()
	_refresh_live_labels()


func _close_panel() -> void:
	if not _panel_open:
		return
	_panel_open = false
	if _panel != null:
		_panel.visible = false
	if _launcher != null:
		_launcher.visible = true
	_restore_game_input()


func _restore_game_input() -> void:
	get_tree().paused = _previous_tree_paused
	Input.set_mouse_mode(_previous_mouse_mode)


func _hide_for_session() -> void:
	_close_panel()
	_session_hidden = true
	if _layer != null:
		_layer.visible = false


func _set_status(text_value: String, success: bool = true) -> void:
	if _status_label != null:
		_status_label.text = text_value
		_status_label.add_theme_color_override("font_color", Color(0.80, 0.92, 0.67) if success else Color(1.0, 0.55, 0.42))
	_call_world("_show_notification", ["[验收] %s" % text_value])
	if _panel_open:
		get_tree().paused = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _refresh_cycle_button_texts() -> void:
	if _seed_crop_button != null:
		_seed_crop_button.text = CROP_NAMES[_seed_crop_index]
	if _seed_quality_button != null:
		_seed_quality_button.text = "品质 %d" % _seed_quality
	if _food_crop_button != null:
		_food_crop_button.text = CROP_NAMES[_food_crop_index]
	if _food_quality_button != null:
		_food_quality_button.text = "品质 %d" % _food_quality
	if _level_button != null:
		_level_button.text = "第%d关" % _selected_level
	if _level_button_secondary != null:
		_level_button_secondary.text = "第%d关" % _selected_level
	if _teleport_button != null:
		_teleport_button.text = TELEPORT_NAMES[_selected_teleport]
	if _equipment_button != null:
		_equipment_button.text = EQUIPMENT_NAMES[_selected_equipment]
	for feature_id in _feature_buttons:
		var button := _feature_buttons[feature_id] as Button
		if button != null:
			button.text = FEATURE_STATES[int(_feature_states.get(feature_id, 0))]
	_refresh_upgrade_labels()


func _refresh_live_labels() -> void:
	if _world == null:
		return
	if _seed_current_label != null:
		_seed_current_label.text = "当前 %d" % int(_call_world("_get_seed_count", [CROP_IDS[_seed_crop_index], _seed_quality], 0))
	if _food_current_label != null:
		var food_key := "%s:%d" % [CROP_IDS[_food_crop_index], _food_quality]
		var stored: Dictionary = _get_world("_stored_crop_counts", {}) as Dictionary
		_food_current_label.text = "当前 %d" % int(stored.get(food_key, 0))
	if _business_state_label != null:
		var active := bool(_get_world("_kitchen_business_active", false))
		if active:
			_business_state_label.text = "第%d关营业中 · 完成 %d 单 · 剩余 %.1f 秒 · 待处理订单 %d" % [
				int(_get_world("_business_active_level_id", 0)),
				int(_get_world("_kitchen_served_count", 0)),
				float(_get_world("_kitchen_business_time", 0.0)),
				(_get_world("_kitchen_orders", []) as Array).size(),
			]
		else:
			_business_state_label.text = "当前没有营业关卡"
	_refresh_upgrade_labels()


func _cycle_seed_crop() -> void:
	_seed_crop_index = (_seed_crop_index + 1) % CROP_IDS.size()
	_refresh_cycle_button_texts()
	_refresh_live_labels()


func _cycle_seed_quality() -> void:
	_seed_quality = (_seed_quality + 1) % 4
	_refresh_cycle_button_texts()
	_refresh_live_labels()


func _cycle_food_crop() -> void:
	_food_crop_index = (_food_crop_index + 1) % CROP_IDS.size()
	_refresh_cycle_button_texts()
	_refresh_live_labels()


func _cycle_food_quality() -> void:
	_food_quality = (_food_quality + 1) % 4
	_refresh_cycle_button_texts()
	_refresh_live_labels()


func _cycle_level() -> void:
	_selected_level = _selected_level % 5 + 1
	_refresh_cycle_button_texts()
	_set_status("目标切换为第%d关" % _selected_level)


func _cycle_teleport() -> void:
	_selected_teleport = (_selected_teleport + 1) % TELEPORT_POSITIONS.size()
	_refresh_cycle_button_texts()


func _cycle_equipment() -> void:
	_selected_equipment = (_selected_equipment + 1) % EQUIPMENT_IDS.size()
	_selected_upgrade_index = 0
	_refresh_cycle_button_texts()


func _cycle_function_upgrade() -> void:
	_selected_upgrade_index = (_selected_upgrade_index + 1) % 8
	_refresh_upgrade_labels()


func _cycle_village_upgrade() -> void:
	_selected_village_index = (_selected_village_index + 1) % 8
	_refresh_upgrade_labels()


func _cycle_feature(feature_id: String) -> void:
	_feature_states[feature_id] = (int(_feature_states.get(feature_id, 0)) + 1) % FEATURE_STATES.size()
	_refresh_cycle_button_texts()


func _set_selected_seed() -> void:
	_set_seed_exact(CROP_IDS[_seed_crop_index], _seed_quality, int(_seed_amount.value))


func _add_selected_seed(delta: int) -> void:
	var current := int(_call_world("_get_seed_count", [CROP_IDS[_seed_crop_index], _seed_quality], 0))
	_set_seed_exact(CROP_IDS[_seed_crop_index], _seed_quality, maxi(current + delta, 0))


func _set_seed_exact(crop_id: String, quality: int, target: int) -> bool:
	target = maxi(target, 0)
	var current := int(_call_world("_get_seed_count", [crop_id, quality], 0))
	if target > current:
		var added := bool(_call_world("_add_seed_to_inventory", [crop_id, quality, target - current, false], false))
		if not added:
			_set_status("物品栏没有空格，未能加入%s品质%d种子" % [_crop_name(crop_id), quality], false)
			return false
	elif target < current:
		_call_world("_remove_seed_from_inventory", [crop_id, quality, current - target])
		if target <= 0:
			_remove_seed_item_from_slots(crop_id, quality)
	_call_world("_sync_total_seed_count")
	_call_world("_update_inventory_bar")
	_set_status("%s品质%d种子已设为 %d" % [_crop_name(crop_id), quality, target])
	_refresh_live_labels()
	return true


func _remove_seed_item_from_slots(crop_id: String, quality: int) -> void:
	var slots: Array = _get_world("_inventory_slot_items", []) as Array
	var item_id := "seed:%s:%d" % [crop_id, quality]
	for index in range(slots.size()):
		if str(slots[index]) == item_id:
			slots[index] = ""
	_set_world("_inventory_slot_items", slots)


func _clear_all_seeds() -> void:
	_set_world("_seed_inventory", {})
	var slots: Array = _get_world("_inventory_slot_items", []) as Array
	for index in range(slots.size()):
		if str(slots[index]).begins_with("seed:"):
			slots[index] = ""
	_set_world("_inventory_slot_items", slots)
	_call_world("_sync_total_seed_count")
	_call_world("_update_inventory_bar")
	_set_status("全部种子已清空")
	_refresh_live_labels()


func _grant_all_seeds() -> void:
	for crop_id in CROP_IDS:
		_set_seed_exact(crop_id, 0, 20)
	_set_status("全部种类的0品质种子已设为20")


func _set_selected_food() -> void:
	_set_food_exact(CROP_IDS[_food_crop_index], _food_quality, int(_food_amount.value))


func _set_food_exact(crop_id: String, quality: int, target: int) -> void:
	var key := "%s:%d" % [crop_id, clampi(quality, 0, 3)]
	var counts: Dictionary = (_get_world("_stored_crop_counts", {}) as Dictionary).duplicate(true)
	var fresh: Dictionary = (_get_world("_stored_crop_fresh_times", {}) as Dictionary).duplicate(true)
	target = maxi(target, 0)
	if target <= 0:
		counts.erase(key)
		fresh.erase(key)
	else:
		counts[key] = target
		var times: Array = []
		for _index in range(target):
			times.append(120.0)
		fresh[key] = times
	_set_world("_stored_crop_counts", counts)
	_set_world("_stored_crop_fresh_times", fresh)
	_call_world("_refresh_food_chest_capacity_label")
	_refresh_open_game_panels()
	_set_status("食材箱中的%s品质%d已设为 %d" % [_crop_name(crop_id), quality, target])
	_refresh_live_labels()


func _clear_food_storage() -> void:
	_set_world("_stored_crop_counts", {})
	_set_world("_stored_crop_fresh_times", {})
	_call_world("_refresh_food_chest_capacity_label")
	_refresh_open_game_panels()
	_set_status("食材箱已清空")


func _apply_coins() -> void:
	_set_world("_coins", int(_coins_amount.value))
	_call_world("_update_coin_hud")
	_set_status("个人金币已设为 %d" % int(_coins_amount.value))


func _apply_coop_coins() -> void:
	_set_world("_coop_coins", int(_coop_coins_amount.value))
	_call_world("_update_coin_hud")
	_set_status("合作金币已设为 %d" % int(_coop_coins_amount.value))


func _apply_stamina() -> void:
	_set_world("_kitchen_stamina", int(_stamina_amount.value))
	_set_world("_kitchen_stamina_recovery_elapsed", 0.0)
	_call_world("_update_coin_hud")
	_call_world("_update_business_prep_top_stats")
	_set_status("厨房体力已设为 %d" % int(_stamina_amount.value))


func _apply_popularity() -> void:
	_set_world("_kitchen_popularity_xp", int(_popularity_amount.value))
	_call_world("_refresh_kitchen_popularity_level")
	_call_world("_update_coin_hud")
	_set_status("人气经验已设为 %d" % int(_popularity_amount.value))


func _set_quick_coins() -> void:
	_set_world("_coins", 10000)
	_call_world("_update_coin_hud")
	_set_status("个人金币已设为10000")


func _fill_stamina() -> void:
	_set_world("_kitchen_stamina", 30)
	_set_world("_kitchen_stamina_recovery_elapsed", 0.0)
	_call_world("_update_coin_hud")
	_set_status("厨房体力已回满")


func _ensure_chapter_one() -> bool:
	if _world == null:
		return false
	if not bool(_get_world("_chapter_one_active", false)):
		_call_world("_build_chapter_one_scene")
		_cache_world_properties()
	return bool(_get_world("_chapter_one_active", false))


func _skip_basic_tutorial() -> void:
	if not _ensure_chapter_one():
		_set_status("无法进入第一章场景", false)
		return
	var true_flags: Array[String] = [
		"_dialogue_completed", "_starter_kit_collected", "_has_hoe", "_has_watering_can", "_has_scythe", "_has_food_chest",
		"_scythe_collected", "_weeding_lesson_completed", "_hoe_rot_lesson_completed", "_mom_talk_guide_completed",
		"_camper_map_guide_completed", "_map_village_guide_completed", "_house_entry_guide_completed", "_house_exit_guide_completed",
		"_hoe_guide_completed", "_tool_switch_guide_completed", "_inventory_sort_guide_completed", "_watering_guide_completed",
		"_scythe_guide_completed", "_food_chest_guide_completed", "_crop_throw_guide_completed", "_food_chests_found",
		"_chest_lesson_completed", "_kitchen_intro_completed", "_post_tutorial_alt_guide_completed",
	]
	for flag in true_flags:
		_set_world(flag, true)
	var false_flags: Array[String] = [
		"_hoe_tutorial_active", "_return_to_mom_prompt_active", "_watering_task_prompt_active", "_watering_task_active",
		"_scythe_task_prompt_active", "_weeding_task_active", "_return_after_weeding_prompt_active", "_hoe_rot_lesson_prompt_active",
		"_tutorial_rotten_seed_prompt_active", "_find_food_chests_prompt_active", "_kitchen_intro_requested",
	]
	for flag in false_flags:
		_set_world(flag, false)
	_set_world("_water_amount", 1.0)
	_set_world("_tutorial_harvested_carrot_count", 5)
	_set_world("_tutorial_watered_carrot_total", 5)
	_set_world("_tutorial_stored_carrot_count", 5)
	_set_world("_weeding_task_cut_count", 2)
	_set_seed_exact("carrot", 0, maxi(int(_call_world("_get_seed_count", ["carrot", 0], 0)), 5))
	_call_world("_update_inventory_bar")
	_call_world("_update_post_tutorial_objective")
	_call_world("_update_coin_hud")
	_set_status("基础新手教程已完成，经营关卡进度未改动")


func _reload_clean_world() -> void:
	_close_panel()
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()


func _prepare_and_open_level() -> void:
	if not _prepare_level(_selected_level):
		return
	_close_panel()
	_call_world("_open_business_prep")


func _prepare_and_start_level() -> void:
	if not _prepare_level(_selected_level):
		return
	_close_panel()
	_call_world("_start_business_level", [_selected_level])


func _prepare_level(level_id: int) -> bool:
	_skip_basic_tutorial()
	var stars: Dictionary = (_get_world("_business_level_stars", {}) as Dictionary).duplicate(true)
	for previous_id in range(1, level_id):
		stars[str(previous_id)] = maxi(int(stars.get(str(previous_id), 0)), 1)
	_set_world("_business_level_stars", stars)
	_sync_unlocks_from_stars()
	if _auto_fill_check == null or _auto_fill_check.button_pressed:
		_fill_selected_level_requirements()
		_fill_stamina()
		_create_acceptance_layout()
	_refresh_open_game_panels()
	_set_status("第%d关验收条件已准备" % level_id)
	return true


func _fill_selected_level_requirements() -> void:
	var level: Dictionary = _call_world("_business_level_by_id", [_selected_level], {}) as Dictionary
	if level.is_empty():
		_set_status("找不到第%d关配置" % _selected_level, false)
		return
	var requirements: Dictionary = level.get("requirements", {}) as Dictionary
	for crop_variant in requirements.keys():
		var crop_id := str(crop_variant)
		var needed := int(requirements.get(crop_variant, 0))
		var current := int(_call_world("_business_level_requirement_total", [level, crop_id], 0))
		if current < needed:
			var stored: Dictionary = _get_world("_stored_crop_counts", {}) as Dictionary
			var key := "%s:0" % crop_id
			_set_food_exact(crop_id, 0, int(stored.get(key, 0)) + needed - current)
	_set_status("第%d关开局食材已补齐" % _selected_level)


func _apply_level_stars() -> void:
	_skip_basic_tutorial()
	var stars: Dictionary = (_get_world("_business_level_stars", {}) as Dictionary).duplicate(true)
	for previous_id in range(1, _selected_level):
		stars[str(previous_id)] = maxi(int(stars.get(str(previous_id), 0)), 1)
	stars[str(_selected_level)] = clampi(int(_level_star_amount.value), 0, 3)
	_set_world("_business_level_stars", stars)
	_sync_unlocks_from_stars()
	_refresh_open_game_panels()
	_call_world("_update_post_tutorial_objective")
	_set_status("第%d关星级已设为 %d" % [_selected_level, int(_level_star_amount.value)])


func _sync_unlocks_from_stars() -> void:
	var stars: Dictionary = _get_world("_business_level_stars", {}) as Dictionary
	if int(stars.get("1", 0)) >= 1:
		_set_world("_kitchen_first_day_completed", true)
		_set_world("_wind_chase_unlocked", true)
		_set_world("_sifter_unlocked", true)
		_call_world("_create_wind_chase_beacon")
		_call_world("_create_seed_sifter")
	if int(stars.get("3", 0)) >= 1:
		_set_world("_camper_drive_unlocked", true)
		_call_world("_unlock_crop_for_shop", ["tomato", 3])
		if int(_call_world("_get_seed_count", ["tomato", 0], 0)) < 2:
			_set_seed_exact("tomato", 0, 2)
	if int(stars.get("4", 0)) >= 1:
		_call_world("_create_young_traveler")
		_call_world("_unlock_crop_for_shop", ["bell_pepper", 2])
		_call_world("_unlock_crop_for_shop", ["pumpkin", 3])
		if int(_call_world("_get_seed_count", ["bell_pepper", 0], 0)) < 2:
			_set_seed_exact("bell_pepper", 0, 2)
		if int(_call_world("_get_seed_count", ["pumpkin", 0], 0)) < 2:
			_set_seed_exact("pumpkin", 0, 2)


func _apply_feature(feature_id: String) -> void:
	_skip_basic_tutorial()
	var state := int(_feature_states.get(feature_id, 0))
	match feature_id:
		"wind":
			_apply_wind_state(state)
		"sifter":
			_apply_sifter_state(state)
		"camper":
			_apply_camper_state(state)
		"traveler":
			_apply_traveler_state(state)
		"opening_sign":
			_apply_opening_sign_state(state)
	_call_world("_update_post_tutorial_objective")
	_set_status("%s已设为：%s" % [_feature_name(feature_id), FEATURE_STATES[state]])


func _apply_wind_state(state: int) -> void:
	_set_world("_wind_chase_unlocked", state > 0)
	_set_world("_wind_chase_completed", state >= 2)
	_set_world("_wind_chase_guide_seen", state >= 2)
	_set_world("_wind_chase_intro_pending", state == 1)
	_set_world("_wind_chase_first_entry", state < 2)
	_set_world("_wind_chase_proximity_hint_shown", false)
	if state > 0:
		_call_world("_create_wind_chase_beacon")
	else:
		_free_world_node_property("_wind_chase_beacon")


func _apply_sifter_state(state: int) -> void:
	_set_world("_sifter_unlocked", state > 0)
	_set_world("_sifter_intro_completed", state >= 2)
	_set_world("_sifter_guide_seen", state >= 2)
	_set_world("_sifter_intro_pending", state == 1)
	if state > 0:
		_call_world("_create_seed_sifter")
	else:
		_call_world("_remove_sifter_circle_blocker")
		_free_world_node_property("_seed_sifter")


func _apply_camper_state(state: int) -> void:
	_set_world("_camper_drive_unlocked", state > 0)
	_set_world("_camper_drive_note_seen", state >= 2)
	_set_world("_camper_drive_note_pending", state == 1)


func _apply_traveler_state(state: int) -> void:
	_set_world("_traveler_intro_completed", state >= 2)
	if state > 0:
		_call_world("_create_young_traveler")
	else:
		_free_world_node_property("_young_traveler")
		_remove_circle_blocker_at(Vector2(5.7, 12.8), 0.82)


func _apply_opening_sign_state(state: int) -> void:
	if state <= 0:
		_call_world("_remove_opening_sign_blocker")
		_set_world("_opening_sign_placed", false)
		_free_world_node_property("_opening_sign")
		var empty_warehouse: Dictionary = (_get_world("_warehouse_items", {}) as Dictionary).duplicate(true)
		empty_warehouse.erase("rv_open_sign")
		_set_world("_warehouse_items", empty_warehouse)
		_call_world("_update_warehouse_button")
		return
	_call_world("_add_warehouse_item", ["rv_open_sign", 1, false])
	if state == 1:
		_call_world("_remove_opening_sign_blocker")
		_set_world("_opening_sign_placed", false)
		_free_world_node_property("_opening_sign")
	elif state >= 2:
		var existing := _get_world("_opening_sign") as Node3D
		if existing != null and is_instance_valid(existing):
			_set_world("_opening_sign_placed", true)
		else:
			_set_world("_opening_sign_placed", false)
			_call_world("_create_opening_sign")
	_call_world("_update_warehouse_button")


func _remove_circle_blocker_at(center: Vector2, radius: float) -> void:
	var blockers: Array = (_get_world("_solid_blockers", []) as Array).duplicate(true)
	for index in range(blockers.size() - 1, -1, -1):
		var blocker: Dictionary = blockers[index] as Dictionary
		if str(blocker.get("shape", "")) != "circle":
			continue
		if absf(float(blocker.get("radius", 0.0)) - radius) > 0.08:
			continue
		var point_3d: Vector3 = blocker.get("center", Vector3.ZERO) as Vector3
		if Vector2(point_3d.x, point_3d.z).distance_squared_to(center) <= 0.09:
			blockers.remove_at(index)
	_set_world("_solid_blockers", blockers)


func _free_world_node_property(property_name: String) -> void:
	var node := _get_world(property_name) as Node
	if node != null and is_instance_valid(node):
		node.queue_free()
	_set_world(property_name, null)


func _set_all_features_unseen() -> void:
	for feature_id in FEATURE_IDS:
		_feature_states[feature_id] = 1
		_apply_feature(feature_id)
	_refresh_cycle_button_texts()


func _set_all_features_complete() -> void:
	for feature_id in FEATURE_IDS:
		_feature_states[feature_id] = 2
		_apply_feature(feature_id)
	_refresh_cycle_button_texts()


func _unlock_everything() -> void:
	_skip_basic_tutorial()
	var stars := {}
	for level_id in range(1, 6):
		stars[str(level_id)] = 3
	_set_world("_business_level_stars", stars)
	_set_world("_kitchen_first_day_completed", true)
	_set_all_features_complete()
	_max_all_equipment_levels()
	for equipment_id in EQUIPMENT_IDS:
		var owned := {}
		for entry_variant in KitchenUpgradeCatalog.get_equipment_upgrades(equipment_id):
			var entry: Dictionary = entry_variant as Dictionary
			owned[str(entry.get("id", ""))] = true
		var all_upgrades: Dictionary = (_get_world("_kitchen_function_upgrades", {}) as Dictionary).duplicate(true)
		all_upgrades[equipment_id] = owned
		_set_world("_kitchen_function_upgrades", all_upgrades)
	_buy_all_village_upgrades()
	for event_id in LocalEventCatalog.ALL_IDS:
		_pass_local_event(event_id)
	_set_quick_coins()
	_fill_stamina()
	_grant_all_seeds()
	_grant_test_items()
	_refresh_world_ui()
	_set_status("全部验收功能已解锁")


func _grant_test_items() -> void:
	_skip_basic_tutorial()
	for item_id in ["simple_cooking_table_lv2_ticket", "cooking_table_upgrade_material", "spare_wooden_crate", "mystery_crop_sample"]:
		_call_world("_add_warehouse_item", [item_id, 3, false])
	_call_world("_update_warehouse_button")
	_set_status("基础工具和常用测试材料已发放")


func _clear_held_items() -> void:
	_set_world("_held_crop_item", "")
	_set_world("_held_crop_quality", 0)
	_set_world("_held_crop_fresh_time", 0.0)
	_set_world("_kitchen_held_item", "")
	_set_world("_kitchen_held_recipe", "")
	_set_world("_kitchen_held_quality", 0)
	_set_world("_kitchen_held_fresh_time", 0.0)
	_free_world_node_property("_held_crop_root")
	_free_world_node_property("_kitchen_held_visual")
	_set_status("手持作物和厨房手持物已清空")


func _change_business_time(delta: float) -> void:
	if not bool(_get_world("_kitchen_business_active", false)):
		_set_status("当前没有营业关卡", false)
		return
	var value := maxf(float(_get_world("_kitchen_business_time", 0.0)) + delta, 0.1)
	_set_world("_kitchen_business_time", value)
	_set_status("营业剩余时间已设为 %.1f 秒" % value)


func _complete_active_order() -> void:
	if not bool(_get_world("_kitchen_business_active", false)):
		_set_status("当前没有营业关卡", false)
		return
	var orders: Array = _get_world("_kitchen_orders", []) as Array
	for order_variant in orders:
		var order: Dictionary = order_variant as Dictionary
		if float(order.get("delay", 0.0)) <= 0.0:
			_call_world("_complete_kitchen_order", [str(order.get("recipe", "")), 0])
			_set_status("已按真实流程完成当前订单")
			return
	_set_status("当前订单尚未出现，请先减少等待时间", false)


func _expire_active_order() -> void:
	if not bool(_get_world("_kitchen_business_active", false)):
		_set_status("当前没有营业关卡", false)
		return
	var orders: Array = (_get_world("_kitchen_orders", []) as Array).duplicate(true)
	for index in range(orders.size()):
		var order: Dictionary = orders[index] as Dictionary
		if float(order.get("delay", 0.0)) <= 0.0:
			order["time"] = 0.0
			orders[index] = order
			_set_world("_kitchen_orders", orders)
			_call_world("_update_kitchen_business", [0.01])
			_set_status("当前订单已按超时处理")
			return
	_set_status("当前没有已出现的订单", false)


func _finish_business_with_count() -> void:
	if not bool(_get_world("_kitchen_business_active", false)):
		_set_status("当前没有营业关卡", false)
		return
	_set_world("_kitchen_served_count", int(_business_served_amount.value))
	_set_world("_kitchen_orders", [])
	_close_panel()
	_call_world("_finish_kitchen_business")


func _finish_business_now() -> void:
	if not bool(_get_world("_kitchen_business_active", false)):
		_set_status("当前没有营业关卡", false)
		return
	_close_panel()
	_call_world("_finish_kitchen_business")


func _clear_kitchen_runtime() -> void:
	_set_world("_kitchen_cook_states", {})
	_set_world("_kitchen_equipment_progress", {})
	_set_world("_kitchen_ready_dishes", {})
	_set_world("_kitchen_scrap_dishes", {})
	_set_world("_kitchen_held_item", "")
	_set_world("_kitchen_held_recipe", "")
	_call_world("_update_kitchen_equipment_bubbles", [0.0])
	_set_status("厨房设备任务与待取料理已清空")


func _set_time_scale(value: float) -> void:
	Engine.time_scale = value
	_set_status("关闭面板后运行倍率为 %s" % ("暂停" if value <= 0.0 else "%.1f×" % value))


func _set_game_time(hour: int) -> void:
	TimeManager.set_time(hour, 0)
	_call_world("_update_day_night", [0.0])
	_set_status("游戏时间已设为 %02d:00" % hour)


func _set_clock_frozen(frozen: bool) -> void:
	TimeManager.paused = frozen
	_set_status("昼夜时间已冻结" if frozen else "昼夜时间已恢复")


func _force_local_event(event_id: String) -> void:
	if not _ensure_chapter_one():
		return
	var config := LocalEventCatalog.get_event(event_id)
	var is_day := str(config.get("phase", "day")) == "day"
	TimeManager.set_time(12 if is_day else 22, 0)
	_set_world("_scheduled_day_event" if is_day else "_scheduled_night_event", event_id)
	_set_world("_active_world_event_id", event_id)
	_call_world("_sync_local_event_world_visual")
	_call_world("_update_local_events", [0.0])
	var point: Vector2 = config.get("position", Vector2.ZERO)
	var player := _get_world("_player") as Node3D
	var camper := _get_world("_camper") as Node3D
	var height := float(_call_world("_height_at", [point.x, point.y], 0.0))
	if player != null and is_instance_valid(player):
		player.global_position = Vector3(point.x + 2.0, height + 0.08, point.y + 1.5)
	if camper != null and is_instance_valid(camper):
		camper.global_position = Vector3(point.x - 4.0, height, point.y)
	_set_status("已强制生成并传送到%s" % str(config.get("name", event_id)))


func _pass_local_event(event_id: String) -> void:
	var config := LocalEventCatalog.get_event(event_id)
	var states: Dictionary = (_get_world("_local_event_state", {}) as Dictionary).duplicate(true)
	var state: Dictionary = (states.get(event_id, {}) as Dictionary).duplicate(true)
	var first_reward := not bool(state.get("reward_claimed", false))
	state["discovered"] = true
	state["best_stars"] = maxi(int(state.get("best_stars", 0)), 1)
	state["reward_claimed"] = true
	states[event_id] = state
	_set_world("_local_event_state", states)
	var perks: Dictionary = (_get_world("_local_event_perks", {}) as Dictionary).duplicate(true)
	perks[str(config.get("perk_id", ""))] = true
	_set_world("_local_event_perks", perks)
	var atlas: Dictionary = (_get_world("_local_event_atlas", {}) as Dictionary).duplicate(true)
	atlas[event_id] = {"name": str(config.get("name", event_id)), "preferred_crop": str(config.get("preferred_crop", "")), "best_stars": int(state.get("best_stars", 1)), "reward_revealed": true}
	_set_world("_local_event_atlas", atlas)
	if first_reward:
		_call_world("_unlock_crop_for_shop", [str(config.get("reward_crop", "")), 2])
		_call_world("_add_seed_to_inventory", [str(config.get("reward_crop", "")), 0, int(config.get("reward_count", 0)), false])
	_call_world("_sync_progression_world_state")
	_call_world("_update_map_codex_panel")
	_set_status("%s已设为首通，奖励与永久特性已生效" % str(config.get("short_name", event_id)))


func _reset_local_event(event_id: String) -> void:
	var config := LocalEventCatalog.get_event(event_id)
	var states: Dictionary = (_get_world("_local_event_state", {}) as Dictionary).duplicate(true)
	states.erase(event_id)
	_set_world("_local_event_state", states)
	var perks: Dictionary = (_get_world("_local_event_perks", {}) as Dictionary).duplicate(true)
	perks.erase(str(config.get("perk_id", "")))
	_set_world("_local_event_perks", perks)
	var atlas: Dictionary = (_get_world("_local_event_atlas", {}) as Dictionary).duplicate(true)
	atlas.erase(event_id)
	_set_world("_local_event_atlas", atlas)
	_call_world("_sync_progression_world_state")
	_call_world("_update_map_codex_panel")
	_set_status("%s进度与永久特性已重置" % str(config.get("short_name", event_id)))


func _water_all_crops() -> void:
	var watered: Array[Vector2] = []
	var crop_nodes: Dictionary = _get_world("_crop_nodes", {}) as Dictionary
	for crop_variant in crop_nodes.values():
		var crop := crop_variant as Node3D
		if crop != null and is_instance_valid(crop):
			watered.append(Vector2(crop.global_position.x, crop.global_position.z))
	_set_world("_watered_soil_centers", watered)
	_set_world("_water_amount", 1.0)
	_call_world("_update_inventory_bar")
	_set_status("现有作物已全部浇水")


func _mature_all_crops() -> void:
	var growth: Dictionary = (_get_world("_crop_growth_remaining", {}) as Dictionary).duplicate(true)
	for key_variant in growth.keys():
		var key := str(key_variant)
		growth[key] = 0.0
		_call_world("_set_crop_mature", [key])
	_set_world("_crop_growth_remaining", growth)
	_set_status("现有作物已全部成熟")


func _restore_rotten_crops() -> void:
	var restored := 0
	var crop_nodes: Dictionary = _get_world("_crop_nodes", {}) as Dictionary
	for key_variant in crop_nodes.keys():
		var key := str(key_variant)
		if bool(_call_world("_is_crop_rotten", [key], false)):
			var crop := crop_nodes.get(key) as Node3D
			var rotten := crop.get_node_or_null("RottenCrop") if crop != null else null
			if rotten != null:
				crop.remove_child(rotten)
				rotten.queue_free()
			_call_world("_set_crop_mature", [key])
			restored += 1
	_set_status("已恢复 %d 株腐烂作物" % restored)


func _clear_all_weeds() -> void:
	var weeds: Array = _get_world("_soil_weed_nodes", []) as Array
	var cleared := 0
	for weed_variant in weeds:
		var weed := weed_variant as Node3D
		if weed != null and is_instance_valid(weed) and weed.visible:
			weed.visible = false
			weed.scale = Vector3.ZERO
			cleared += 1
	_set_status("已隐藏 %d 株田间杂草" % cleared)


func _spawn_selected_crop() -> void:
	var tilled: Array = _get_world("_tilled_soil_centers", []) as Array
	var planted: Array = _get_world("_planted_seed_centers", []) as Array
	for center_variant in tilled:
		var center := center_variant as Vector2
		var occupied := false
		for planted_variant in planted:
			if center.distance_squared_to(planted_variant as Vector2) <= 0.25:
				occupied = true
				break
		if not occupied:
			_call_world("_create_seedling_at", [center, CROP_IDS[_seed_crop_index], _seed_quality])
			planted.append(center)
			_set_world("_planted_seed_centers", planted)
			_set_status("已在空耕地生成%s品质%d作物" % [_crop_name(CROP_IDS[_seed_crop_index]), _seed_quality])
			return
	_set_status("没有可用的空耕地", false)


func _fill_watering_can() -> void:
	_set_world("_water_amount", 1.0)
	_call_world("_update_inventory_bar")
	_set_status("水壶已加满")


func _teleport_player() -> void:
	if not _ensure_chapter_one():
		return
	if bool(_get_world("_inside_house", false)):
		_call_world("_exit_house_interior")
	var player := _get_world("_player") as Node3D
	if player == null or not is_instance_valid(player):
		_set_status("找不到玩家节点", false)
		return
	var target := TELEPORT_POSITIONS[_selected_teleport]
	var height := float(_call_world("_height_at", [target.x, target.z], target.y))
	player.global_position = Vector3(target.x, height + 0.08, target.z)
	_set_status("已传送到%s" % TELEPORT_NAMES[_selected_teleport])


func _apply_equipment_level() -> void:
	var levels: Dictionary = (_get_world("_kitchen_upgrade_levels", {}) as Dictionary).duplicate(true)
	var equipment_id := EQUIPMENT_IDS[_selected_equipment]
	levels[equipment_id] = clampi(int(_equipment_level_amount.value), 1, 5)
	_set_world("_kitchen_upgrade_levels", levels)
	_call_world("_refresh_kitchen_equipment_level_label", [equipment_id])
	_call_world("_rebuild_kitchen_equipment_grid")
	_call_world("_update_kitchen_upgrade_buttons")
	_set_status("%s数量等级已设为 Lv.%d" % [EQUIPMENT_NAMES[_selected_equipment], int(_equipment_level_amount.value)])


func _max_all_equipment_levels() -> void:
	var levels: Dictionary = (_get_world("_kitchen_upgrade_levels", {}) as Dictionary).duplicate(true)
	for equipment_id in EQUIPMENT_IDS:
		levels[equipment_id] = 5
	_set_world("_kitchen_upgrade_levels", levels)
	_set_world("_kitchen_first_day_completed", true)
	_call_world("_rebuild_kitchen_equipment_grid")
	_call_world("_update_kitchen_upgrade_buttons")
	_set_status("全部设备数量等级已设为 Lv.5")


func _refresh_upgrade_labels() -> void:
	var equipment_id := EQUIPMENT_IDS[_selected_equipment]
	var upgrades: Array = KitchenUpgradeCatalog.get_equipment_upgrades(equipment_id)
	if _upgrade_button != null and not upgrades.is_empty():
		var entry: Dictionary = upgrades[_selected_upgrade_index % upgrades.size()] as Dictionary
		_upgrade_button.text = "第%d项 · %s" % [_selected_upgrade_index + 1, str(entry.get("display_name", "功能改造"))]
		var owned_all: Dictionary = _get_world("_kitchen_function_upgrades", {}) as Dictionary
		var owned: Dictionary = owned_all.get(equipment_id, {}) as Dictionary
		if _upgrade_state_label != null:
			_upgrade_state_label.text = "状态：%s · 价格 %d" % ["已购买" if bool(owned.get(str(entry.get("id", "")), false)) else "未购买", int(entry.get("price", 0))]
	var projects: Array = KitchenUpgradeCatalog.get_village_projects()
	if _village_button != null and not projects.is_empty():
		var project: Dictionary = projects[_selected_village_index % projects.size()] as Dictionary
		_village_button.text = "第%d项 · %s" % [_selected_village_index + 1, str(project.get("display_name", "村落改造"))]
		var village_owned: Dictionary = _get_world("_village_upgrades", {}) as Dictionary
		if _village_state_label != null:
			_village_state_label.text = "状态：%s · 价格 %d" % ["已完成" if bool(village_owned.get(str(project.get("id", "")), false)) else "未完成", int(project.get("price", 0))]


func _toggle_function_upgrade() -> void:
	var equipment_id := EQUIPMENT_IDS[_selected_equipment]
	var upgrades: Array = KitchenUpgradeCatalog.get_equipment_upgrades(equipment_id)
	if upgrades.is_empty():
		return
	var entry: Dictionary = upgrades[_selected_upgrade_index % upgrades.size()] as Dictionary
	var all_owned: Dictionary = (_get_world("_kitchen_function_upgrades", {}) as Dictionary).duplicate(true)
	var owned: Dictionary = (all_owned.get(equipment_id, {}) as Dictionary).duplicate(true)
	var upgrade_id := str(entry.get("id", ""))
	owned[upgrade_id] = not bool(owned.get(upgrade_id, false))
	all_owned[equipment_id] = owned
	_set_world("_kitchen_function_upgrades", all_owned)
	_call_world("_refresh_kitchen_equipment_upgrade_visuals", [equipment_id])
	_call_world("_update_kitchen_upgrade_buttons")
	_refresh_upgrade_labels()
	_set_status("%s · %s 状态已切换" % [EQUIPMENT_NAMES[_selected_equipment], str(entry.get("display_name", "改造"))])


func _buy_all_current_equipment_upgrades() -> void:
	var equipment_id := EQUIPMENT_IDS[_selected_equipment]
	var owned := {}
	for entry_variant in KitchenUpgradeCatalog.get_equipment_upgrades(equipment_id):
		var entry: Dictionary = entry_variant as Dictionary
		owned[str(entry.get("id", ""))] = true
	var all_owned: Dictionary = (_get_world("_kitchen_function_upgrades", {}) as Dictionary).duplicate(true)
	all_owned[equipment_id] = owned
	_set_world("_kitchen_function_upgrades", all_owned)
	_call_world("_refresh_kitchen_equipment_upgrade_visuals", [equipment_id])
	_call_world("_update_kitchen_upgrade_buttons")
	_refresh_upgrade_labels()
	_set_status("%s的8项功能改造已全部购买" % EQUIPMENT_NAMES[_selected_equipment])


func _reset_current_equipment_upgrades() -> void:
	var equipment_id := EQUIPMENT_IDS[_selected_equipment]
	var all_owned: Dictionary = (_get_world("_kitchen_function_upgrades", {}) as Dictionary).duplicate(true)
	all_owned[equipment_id] = {}
	_set_world("_kitchen_function_upgrades", all_owned)
	_call_world("_refresh_kitchen_equipment_upgrade_visuals", [equipment_id])
	_call_world("_update_kitchen_upgrade_buttons")
	_refresh_upgrade_labels()
	_set_status("%s功能改造已重置" % EQUIPMENT_NAMES[_selected_equipment])


func _toggle_village_upgrade() -> void:
	var projects: Array = KitchenUpgradeCatalog.get_village_projects()
	if projects.is_empty():
		return
	var project: Dictionary = projects[_selected_village_index % projects.size()] as Dictionary
	var owned: Dictionary = (_get_world("_village_upgrades", {}) as Dictionary).duplicate(true)
	var project_id := str(project.get("id", ""))
	owned[project_id] = not bool(owned.get(project_id, false))
	_set_world("_village_upgrades", owned)
	_call_world("_refresh_village_upgrade_world_visuals")
	_call_world("_update_kitchen_upgrade_buttons")
	_refresh_upgrade_labels()
	_set_status("村落项目“%s”状态已切换" % str(project.get("display_name", "")))


func _buy_all_village_upgrades() -> void:
	var owned := {}
	for project_variant in KitchenUpgradeCatalog.get_village_projects():
		var project: Dictionary = project_variant as Dictionary
		owned[str(project.get("id", ""))] = true
	_set_world("_village_upgrades", owned)
	_call_world("_refresh_village_upgrade_world_visuals")
	_call_world("_update_kitchen_upgrade_buttons")
	_refresh_upgrade_labels()
	_set_status("全部村落改造已完成")


func _reset_village_upgrades() -> void:
	_set_world("_village_upgrades", {})
	_call_world("_refresh_village_upgrade_world_visuals")
	_call_world("_update_kitchen_upgrade_buttons")
	_refresh_upgrade_labels()
	_set_status("全部村落改造已重置")


func _create_acceptance_layout() -> void:
	if not _ensure_chapter_one():
		return
	var level: Dictionary = _call_world("_business_level_by_id", [_selected_level], {}) as Dictionary
	var needed: Array[String] = []
	var needed_variant: Variant = _call_world("_business_level_required_equipment_ids", [level], [])
	if needed_variant is Array:
		for equipment_variant in needed_variant:
			needed.append(str(equipment_variant))
	if needed.is_empty():
		needed = ["sink", "pot", "prep_shelf"]
	if _selected_level >= 2 and not needed.has("grill"):
		needed.append("grill")
	var layout := {}
	var offsets: Array[Vector2] = [Vector2(-6.0, 8.5), Vector2(-3.0, 9.5), Vector2(0.0, 10.0), Vector2(3.0, 9.5), Vector2(6.0, 8.5)]
	for index in range(needed.size()):
		var equipment_id := needed[index]
		var offset := offsets[index % offsets.size()]
		layout[equipment_id] = [{"instance_id": "%s:1" % equipment_id, "index": 1, "x": offset.x, "z": offset.y, "yaw": 0.0}]
	_set_world("_kitchen_saved_layout", layout)
	_call_world("_apply_kitchen_layout_preset")
	_call_world("_rebuild_kitchen_equipment_grid")
	_set_status("已生成第%d关需要的验收设备布局" % _selected_level)


func _refresh_world_ui() -> void:
	for method_name in [
		"_sync_total_seed_count", "_update_inventory_bar", "_update_coin_hud", "_refresh_food_chest_capacity_label",
		"_update_warehouse_button",
		"_update_post_tutorial_objective", "_rebuild_kitchen_equipment_grid", "_update_kitchen_upgrade_buttons",
	]:
		_call_world(method_name)
	_refresh_open_game_panels()
	_set_status("游戏界面已刷新")


func _refresh_open_game_panels() -> void:
	var food_overlay := _get_world("_food_chest_overlay") as Control
	if food_overlay != null and is_instance_valid(food_overlay) and food_overlay.is_inside_tree() and food_overlay.visible:
		_call_world("_rebuild_food_chest_inventory_panel")
	var prep_overlay := _get_world("_business_prep_overlay") as Control
	if prep_overlay != null and is_instance_valid(prep_overlay) and prep_overlay.is_inside_tree() and prep_overlay.visible:
		_call_world("_rebuild_business_prep_ui")


func _crop_name(crop_id: String) -> String:
	var index := CROP_IDS.find(crop_id)
	return CROP_NAMES[index] if index >= 0 else crop_id


func _feature_name(feature_id: String) -> String:
	var index := FEATURE_IDS.find(feature_id)
	return FEATURE_NAMES[index] if index >= 0 else feature_id
