extends SceneTree

const BusinessProgressionCatalog = preload("res://scripts/business_progression_catalog.gd")
const CropCatalog = preload("res://scripts/crop_catalog.gd")
const LocalEventCatalog = preload("res://scripts/local_event_catalog.gd")
const ResearchRecipeCatalog = preload("res://scripts/research_recipe_catalog.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_run_catalog_checks()
	var table_scene := load("res://scenes/ResearchTable.tscn") as PackedScene
	assert(table_scene != null, "料理研究台场景必须可加载")
	var table := table_scene.instantiate()
	assert(table != null, "料理研究台场景必须可实例化")
	table.free()

	var world_scene := load("res://scenes/GrassWorld.tscn") as PackedScene
	assert(world_scene != null, "GrassWorld 场景必须可加载")
	var world := world_scene.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame

	_run_table_placement_checks(world)
	_run_event_switch_checks(world)
	_run_special_recipe_flow_checks(world)
	_run_research_consumption_checks(world)
	_run_save_compatibility_checks(world)
	await _run_panel_layout_checks(world)
	await create_timer(1.8).timeout

	root.remove_child(world)
	world.free()
	world = null
	world_scene = null
	table_scene = null
	var audio_manager := root.get_node_or_null("AudioManager")
	if audio_manager != null:
		root.remove_child(audio_manager)
		audio_manager.free()
	await process_frame
	await process_frame
	print("RESEARCH_TABLE_SMOKE: PASS")
	quit(0)


func _run_catalog_checks() -> void:
	assert(BusinessProgressionCatalog.ORDINARY_RECIPE_IDS.size() == 10, "普通料理图鉴必须继续保持10项")
	assert(ResearchRecipeCatalog.ALL_IDS.size() == 4, "特色料理必须恰好为4道")
	var seen_events := {}
	var seen_crops := {}
	for recipe_id in ResearchRecipeCatalog.ALL_IDS:
		var recipe := ResearchRecipeCatalog.get_data(recipe_id)
		var event_id := str(recipe.get("event_id", ""))
		var crop := str(recipe.get("crop", ""))
		assert(event_id in LocalEventCatalog.ALL_IDS, "特色料理必须绑定地方事件：%s" % recipe_id)
		assert(crop in CropCatalog.EVENT_IDS, "特色料理必须使用地方事件作物：%s" % recipe_id)
		assert(str(recipe.get("station", "")) in ["pot", "grill"], "特色料理设备必须为煮锅或烧烤架")
		assert(not (recipe.get("processing_steps", []) as Array).is_empty(), "特色料理必须提供统一处理步骤配置")
		assert(int(recipe.get("price", 0)) > 0 and int(recipe.get("scrap_price", 0)) > 0, "特色料理价格配置必须有效")
		assert(not seen_events.has(event_id), "一个地方事件只能绑定一道特色料理")
		assert(not seen_crops.has(crop), "一种地方作物只能绑定一道特色料理")
		seen_events[event_id] = true
		seen_crops[crop] = true


func _run_table_placement_checks(world: Node) -> void:
	var definition := world.call("_equipment_definition", "research_table") as Dictionary
	assert(not definition.is_empty() and not bool(definition.get("upgradeable", true)), "料理研究台必须为不可升级设备")
	world.set("_research_table_unlocked", true)
	assert(int(world.call("_kitchen_quantity_level", "research_table")) == 1, "料理研究台数量上限必须为1")
	var camper := world.get("_camper") as Node3D
	assert(camper != null and is_instance_valid(camper), "房车必须存在才能验证研究台收纳")
	var instance_id := "research_table:1"
	var position := camper.global_position + Vector3(3.0, 0.0, 2.0)
	var table := world.call("_create_kitchen_equipment_model", world, "research_table", "SmokeResearchTable", position, false, instance_id) as Node3D
	assert(table != null and is_instance_valid(table), "料理研究台必须能通过现有设备摆放流程创建")
	var roots := world.get("_kitchen_equipment_roots") as Dictionary
	roots[instance_id] = table
	world.set("_kitchen_equipment_roots", roots)
	assert(str(world.call("_next_kitchen_instance_id", "research_table")) == "", "已摆放研究台后不得再生成第二台")
	world.call("_pack_camper_travel_attachments")
	assert(not table.visible, "房车驾驶收纳时研究台必须隐藏")
	world.call("_unpack_camper_travel_attachments")
	assert(table.visible, "房车停车展开时研究台必须恢复")
	world.call("_remove_kitchen_equipment_instance_blocker", instance_id)
	roots.erase(instance_id)
	world.set("_kitchen_equipment_roots", roots)
	var bubbles := world.get("_kitchen_equipment_bubbles") as Dictionary
	bubbles.erase(instance_id)
	world.set("_kitchen_equipment_bubbles", bubbles)
	(world.get("_camper_drive_attachments") as Array).clear()
	world.remove_child(table)
	table.free()


func _run_event_switch_checks(world: Node) -> void:
	world.set("_researched_special_recipes", {})
	for event_id in LocalEventCatalog.ALL_IDS:
		var event := LocalEventCatalog.get_event(event_id)
		var preferred_crop := str(event.get("preferred_crop", ""))
		var reward_crop := str(event.get("reward_crop", ""))
		var special_recipe := ResearchRecipeCatalog.recipe_for_event(event_id)
		var original_recipes: Array = world.call("_local_event_effective_recipes", event_id)
		var original_requirements := world.call("_local_event_effective_requirements", event_id) as Dictionary
		assert(original_recipes == event.get("recipes", []), "研究前不得改变地方事件订单：%s" % event_id)
		assert(original_requirements == {preferred_crop: 4}, "研究前必须准备4份原偏好作物：%s" % event_id)

		var researched := world.get("_researched_special_recipes") as Dictionary
		researched[special_recipe] = true
		world.set("_researched_special_recipes", researched)
		var changed_recipes: Array = world.call("_local_event_effective_recipes", event_id)
		var changed_requirements := world.call("_local_event_effective_requirements", event_id) as Dictionary
		assert(changed_recipes.size() == 4 and str(changed_recipes[3]) == special_recipe, "研究后最后一单必须替换为特色料理：%s" % event_id)
		assert(changed_requirements == {preferred_crop: 3, reward_crop: 1}, "研究后必须准备3份原作物和1份特色作物：%s" % event_id)

		world.set("_active_business_location_bonus", {
			"preferred_crops": [preferred_crop, reward_crop],
			"price_multiplier": 1.25,
		})
		var price := int(ResearchRecipeCatalog.get_data(special_recipe).get("price", 0))
		assert(int(world.call("_business_location_order_bonus", special_recipe, price)) == roundi(float(price) * 0.25), "特色料理原产地加成必须精确为25%%：%s" % event_id)


func _run_special_recipe_flow_checks(world: Node) -> void:
	var expected_items := {
		ResearchRecipeCatalog.STRAWBERRY_JAM: "raw_strawberry",
		ResearchRecipeCatalog.ROASTED_SWEET_CORN: "raw_sweet_corn",
		ResearchRecipeCatalog.MOON_MUSHROOM_SOUP: "chopped_moon_mushroom",
		ResearchRecipeCatalog.CAMPFIRE_MARSHMALLOW: "raw_marshmallow",
	}
	for recipe_id in ResearchRecipeCatalog.ALL_IDS:
		var data := ResearchRecipeCatalog.get_data(recipe_id)
		var station := str(data.get("station", ""))
		var required_item := str(world.call("_recipe_required_cook_item", recipe_id))
		assert(required_item == str(expected_items.get(recipe_id, "")), "特色料理加工链不正确：%s" % recipe_id)
		assert(bool(world.call("_recipe_uses_station", recipe_id, station)), "特色料理必须识别配置的最终厨具：%s" % recipe_id)
		assert(bool(world.call("_recipe_accepts_cook_item", recipe_id, required_item)), "特色料理必须识别配置的加工食材：%s" % recipe_id)
		var active_orders: Array[Dictionary] = [world.call("_make_kitchen_order", recipe_id, 60.0, 0.0)]
		world.set("_kitchen_orders", active_orders)
		assert(str(world.call("_pending_kitchen_recipe_for_item_and_station", required_item, station)) == recipe_id, "特色料理必须能被对应厨具接收：%s" % recipe_id)
		if recipe_id == ResearchRecipeCatalog.MOON_MUSHROOM_SOUP:
			assert(str(world.call("_kitchen_next_station_hint", "raw_moon_mushroom")).contains("料理台"), "月光蘑菇必须支持不清洗直接进入切配")

	var ordinary_before := (world.get("_codex_discovered_cooking") as Dictionary).size()
	var served_recipe := ResearchRecipeCatalog.STRAWBERRY_JAM
	world.set("_special_recipe_first_served", {})
	world.call("_record_completed_recipe", served_recipe)
	assert((world.get("_codex_discovered_cooking") as Dictionary).size() == ordinary_before, "特色料理不得计入普通10项料理图鉴")
	assert(bool((world.get("_special_recipe_first_served") as Dictionary).get(served_recipe, false)), "特色料理首次出餐必须写入地方风味图谱")


func _run_research_consumption_checks(world: Node) -> void:
	var recipe_id := ResearchRecipeCatalog.STRAWBERRY_JAM
	var recipe := ResearchRecipeCatalog.get_data(recipe_id)
	var event_id := str(recipe.get("event_id", ""))
	var crop := str(recipe.get("crop", ""))
	world.set("_researched_special_recipes", {})
	world.set("_local_event_atlas", {event_id: {"reward_revealed": true}})
	world.set("_codex_harvested_crops", {crop: true})
	world.set("_held_crop_item", crop)
	world.set("_research_selected_recipe", recipe_id)
	world.set("_research_selected_crop", CropCatalog.SWEET_CORN)
	world.set("_research_selected_station", str(recipe.get("station", "")))
	world.call("_attempt_selected_recipe_research")
	assert(str(world.get("_held_crop_item")) == crop, "错误食材不得被消耗")
	assert(not bool((world.get("_researched_special_recipes") as Dictionary).get(recipe_id, false)), "错误组合不得解锁料理")

	world.set("_research_selected_crop", crop)
	world.set("_research_selected_station", "grill")
	world.call("_attempt_selected_recipe_research")
	assert(str(world.get("_held_crop_item")) == crop, "错误设备不得被消耗")

	world.set("_research_selected_station", str(recipe.get("station", "")))
	world.call("_attempt_selected_recipe_research")
	assert(str(world.get("_held_crop_item")) == "", "正确研究必须只消耗当前手持的一份食材")
	assert(bool((world.get("_researched_special_recipes") as Dictionary).get(recipe_id, false)), "正确组合必须永久解锁料理")

	world.set("_held_crop_item", crop)
	world.call("_attempt_selected_recipe_research")
	assert(str(world.get("_held_crop_item")) == crop, "已研究料理的重复点击不得再次消耗")

	var counts := {}
	var fresh_times := {}
	var low_quality_key := str(world.call("_stored_crop_key", CropCatalog.SWEET_CORN, 0))
	var high_quality_key := str(world.call("_stored_crop_key", CropCatalog.SWEET_CORN, 3))
	counts[low_quality_key] = 1
	counts[high_quality_key] = 1
	fresh_times[low_quality_key] = [95.0]
	fresh_times[high_quality_key] = [24.0]
	world.set("_held_crop_item", "")
	world.set("_stored_crop_counts", counts)
	world.set("_stored_crop_fresh_times", fresh_times)
	assert(bool(world.call("_consume_research_crop", CropCatalog.SWEET_CORN)), "研究必须能从食材箱消耗作物")
	assert(int((world.get("_stored_crop_counts") as Dictionary).get(high_quality_key, 0)) == 0, "研究应优先消耗剩余时间最短的一份箱内作物")
	assert(int((world.get("_stored_crop_counts") as Dictionary).get(low_quality_key, 0)) == 1, "剩余时间较长的箱内作物应保留")


func _run_save_compatibility_checks(world: Node) -> void:
	var save_manager := root.get_node_or_null("SaveManager")
	var world_manager := root.get_node_or_null("WorldManager")
	assert(save_manager != null and world_manager != null, "存档兼容测试需要 SaveManager 与 WorldManager")
	var migrated := save_manager.call("_migrate_snapshot", {
		"version": 2,
		"world": {"world_state": {"roaming_harvest_progression_v2": {
			"business_level_stars": {"1": 1, "2": 1},
			"codex_claimed_rewards": {"cooking:3": true},
		}}},
	}) as Dictionary
	assert(int(migrated.get("version", 0)) == 3, "旧存档必须迁移到研究系统存档版本")
	var progression := (((migrated.get("world", {}) as Dictionary).get("world_state", {}) as Dictionary).get("roaming_harvest_progression_v2", {}) as Dictionary)
	assert(bool(progression.get("needs_cooking_codex_inference", false)), "旧存档缺少料理发现记录时必须标记为待推导")
	assert(progression.has("researched_special_recipes") and progression.has("special_recipe_first_served"), "迁移后必须包含特色料理状态")
	world_manager.set("world_state", {"roaming_harvest_progression_v2": progression})
	world.call("_restore_progression_world_state")
	assert(bool(world.get("_research_table_unlocked")), "旧版已领取3/10线索时必须自动解锁研究台")
	assert((world.get("_codex_discovered_cooking") as Dictionary).size() >= 3, "旧进度必须从已通关关卡补齐已出现的普通料理")


func _run_panel_layout_checks(world: Node) -> void:
	root.size = Vector2i(1223, 711)
	world.call("_create_research_table_panel")
	world.call("_rebuild_research_table_panel")
	var overlay := world.get("_research_overlay") as Control
	var panel := world.get("_research_panel") as Control
	assert(overlay != null and panel != null, "研究界面必须能创建")
	overlay.visible = true
	await process_frame
	await process_frame
	var rect := panel.get_global_rect()
	assert(rect.position.x >= 0.0 and rect.position.y >= 0.0, "1223×711 下研究面板不得越过左上边界")
	assert(rect.end.x <= 1223.1 and rect.end.y <= 711.1, "1223×711 下研究面板不得溢出屏幕")
	root.size = Vector2i(1920, 1080)
	await process_frame
	await process_frame
	rect = panel.get_global_rect()
	assert(rect.position.x >= 0.0 and rect.position.y >= 0.0, "1920×1080 下研究面板不得越过左上边界")
	assert(rect.end.x <= 1920.1 and rect.end.y <= 1080.1, "1920×1080 下研究面板不得溢出屏幕")
