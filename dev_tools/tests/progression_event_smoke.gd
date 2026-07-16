extends SceneTree

const CropCatalog = preload("res://scripts/crop_catalog.gd")
const LocalEventCatalog = preload("res://scripts/local_event_catalog.gd")
const BusinessProgressionCatalog = preload("res://scripts/business_progression_catalog.gd")


func _initialize() -> void:
	_run_catalog_checks()
	_run_mainline_checks()
	_run_event_checks()
	_run_time_checks()
	print("PROGRESSION_EVENT_SMOKE_OK")
	quit(0)


func _run_catalog_checks() -> void:
	assert(CropCatalog.ALL_IDS.size() == 10, "作物目录必须恰好为10种")
	assert(CropCatalog.MAINLINE_IDS.size() == 6, "主线作物必须为6种")
	assert(CropCatalog.EVENT_IDS.size() == 4, "地方事件作物必须为4种")
	var unique := {}
	for crop_id in CropCatalog.ALL_IDS:
		assert(not unique.has(crop_id), "作物ID重复：%s" % crop_id)
		unique[crop_id] = true
		assert(CropCatalog.has(crop_id), "作物目录缺失：%s" % crop_id)


func _run_mainline_checks() -> void:
	var levels: Array = BusinessProgressionCatalog.LEVELS
	assert(levels.size() == 5, "主线经营关卡必须为5关")
	var expected_requirements := [
		{"carrot": 5},
		{"carrot": 4, "pea": 4},
		{"carrot": 2, "pea": 3, "eggplant": 4},
		{"carrot": 2, "pea": 2, "eggplant": 2, "tomato": 4},
		{"carrot": 2, "pea": 2, "eggplant": 2, "tomato": 2, "bell_pepper": 3, "pumpkin": 4},
	]
	var expected_stars := [[1, 2, 3], [2, 3, 4], [2, 3, 5], [2, 4, 6], [3, 4, 7]]
	for index in range(levels.size()):
		var level := levels[index] as Dictionary
		assert(level.get("requirements", {}) == expected_requirements[index], "第%d关开局食材门槛不一致" % (index + 1))
		assert(level.get("star_orders", []) == expected_stars[index], "第%d关星级门槛不一致" % (index + 1))
		for crop_id in (level.get("requirements", {}) as Dictionary).keys():
			assert(crop_id in CropCatalog.MAINLINE_IDS, "特殊作物不得进入主线门槛：%s" % crop_id)
	var level5 := levels[4] as Dictionary
	for crop_id in CropCatalog.MAINLINE_IDS:
		assert((level5.get("requirements", {}) as Dictionary).has(crop_id), "第5关必须覆盖主线作物：%s" % crop_id)
	assert(BusinessProgressionCatalog.ORDINARY_RECIPE_IDS.size() == 10, "普通料理图鉴必须恰好为10项")


func _run_event_checks() -> void:
	assert(LocalEventCatalog.ALL_IDS.size() == 4, "地方事件必须为4个")
	assert(LocalEventCatalog.DAY_IDS.size() == 2, "白天事件必须为2个")
	assert(LocalEventCatalog.NIGHT_IDS.size() == 2, "夜间事件必须为2个")
	assert(LocalEventCatalog.NIGHT_IDS[0] == LocalEventCatalog.RABBIT_PARTY, "兔子聚会必须是首个夜间事件")
	var reward_ids := {}
	var perk_ids := {}
	for event_id in LocalEventCatalog.ALL_IDS:
		var event := LocalEventCatalog.get_event(event_id)
		var reward_crop := str(event.get("reward_crop", ""))
		var perk_id := str(event.get("perk_id", ""))
		var asset_path := str(event.get("asset_path", ""))
		assert(reward_crop in CropCatalog.EVENT_IDS, "事件奖励必须为特殊作物：%s" % event_id)
		assert(not reward_ids.has(reward_crop), "特殊作物奖励重复：%s" % reward_crop)
		assert(not perk_ids.has(perk_id), "永久特性重复：%s" % perk_id)
		assert(asset_path.ends_with(".glb") and ResourceLoader.exists(asset_path), "地方事件正式 GLB 资源缺失：%s" % event_id)
		reward_ids[reward_crop] = true
		perk_ids[perk_id] = true
		assert((event.get("recipes", []) as Array).size() == 4, "地方经营必须为4单：%s" % event_id)
		assert(float(event.get("bonus_multiplier", 0.0)) == 1.25, "地方偏爱必须为+25%%：%s" % event_id)


func _run_time_checks() -> void:
	var time_manager := root.get_node_or_null("TimeManager")
	assert(time_manager != null, "TimeManager Autoload 缺失")
	assert(is_equal_approx(float(time_manager.get("real_seconds_per_game_minute")), 1.0), "现实 1 秒必须对应游戏 1 分钟，保证整日为 24 分钟")
	time_manager.call("set_time", 5, 0)
	assert(str(time_manager.call("get_phase")) == "dawn")
	time_manager.call("set_time", 7, 0)
	assert(str(time_manager.call("get_phase")) == "day")
	time_manager.call("set_time", 17, 0)
	assert(str(time_manager.call("get_phase")) == "dusk")
	time_manager.call("set_time", 19, 0)
	assert(str(time_manager.call("get_phase")) == "night")
	time_manager.call("set_time", 4, 59)
	assert(str(time_manager.call("get_phase")) == "night")
	time_manager.call("set_time", 6, 0, 1)
