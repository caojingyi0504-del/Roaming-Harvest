extends Node

const GrassWorldScene = preload("res://scenes/GrassWorld.tscn")
const WardrobeCatalog = preload("res://scripts/wardrobe_catalog.gd")


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var manager := get_node("/root/WardrobeManager")
	manager.call("_reset_to_defaults")
	manager.call("_commit_state")
	assert(str(manager.event_state) == manager.EVENT_LOCKED)
	assert(bool(manager.owns_outfit(WardrobeCatalog.DEFAULT_OUTFIT_ID)))
	assert(WardrobeCatalog.all().size() == 5)
	assert(WardrobeCatalog.model_is_available(WardrobeCatalog.DEFAULT_OUTFIT_ID))

	var world := GrassWorldScene.instantiate()
	add_child(world)
	await get_tree().process_frame
	world.call("_build_chapter_one_scene")
	await get_tree().process_frame
	var system := world.get("_wardrobe_system") as Node
	assert(system != null and is_instance_valid(system), "服装系统未挂到大世界")

	var level: Dictionary = world.call("_business_level_by_id", 3)
	var order_count := int(level.get("orders", 5))
	world.set("_kitchen_business_active", true)
	world.set("_business_active_level_id", 3)
	world.set("_business_active_level_duration", float(level.get("time_limit", 150.0)))
	world.set("_kitchen_business_time", 0.0)
	world.set("_kitchen_served_count", order_count)
	world.set("_kitchen_failed_count", 0)
	world.call("_finish_kitchen_business")
	assert(str(manager.event_state) == manager.EVENT_PENDING, "第3关一星后未记录裁缝事件")
	system.call("update", 0.0)
	assert(system.get("_event_root") == null, "经营结算未关闭时提前生成了裁缝")
	world.call("_close_business_result_overlay")
	system.call("update", 0.0)
	assert(system.get("_event_root") != null, "返回大世界后未生成裁缝")

	var player := world.get("_player") as Node3D
	var tailor := system.get("_tailor") as Node3D
	player.global_position = tailor.global_position
	assert(bool(system.call("execute_interaction", "wardrobe_tailor", {})))
	system.call("_on_story_primary_pressed")
	assert(str(manager.event_state) == manager.EVENT_COLLECTING)
	var bundle_nodes := system.get("_bundle_nodes") as Dictionary
	assert(bundle_nodes.size() == 3, "衣物包数量不为3")
	for raw_id in bundle_nodes.keys().duplicate():
		var bundle := bundle_nodes.get(raw_id) as Node3D
		assert(bundle != null)
		assert(not bool(world.call("_is_inside_pond", bundle.global_position.x, bundle.global_position.z, 0.45)), "衣物包落入水中")
		player.global_position = bundle.global_position
		assert(bool(system.call("execute_interaction", "wardrobe_bundle", {"bundle_id": str(raw_id)})))
	assert(int(manager.collected_bundle_count()) == 3)

	player.global_position = tailor.global_position
	assert(bool(system.call("execute_interaction", "wardrobe_tailor", {})))
	system.call("_on_story_primary_pressed")
	assert(bool(manager.is_wardrobe_unlocked()), "交付后未永久解锁衣箱")
	assert(bool(system.call("is_overlay_open")), "新功能弹窗后未打开衣箱")
	var visual_root := player.get_node("VisualRoot") as Node3D
	assert(visual_root.get_child_count() == 1, "玩家视觉模型没有保持单实例")
	var available_paid: Array[Dictionary] = []
	var missing_paid: Array[Dictionary] = []
	for outfit in WardrobeCatalog.all():
		var outfit_id := str(outfit.get("id", ""))
		if outfit_id == WardrobeCatalog.DEFAULT_OUTFIT_ID:
			continue
		if WardrobeCatalog.model_is_available(outfit_id):
			available_paid.append(outfit)
		else:
			missing_paid.append(outfit)
	assert(available_paid.size() == 3, "Expected the three supplied outfit models to be available")
	assert(missing_paid.size() == 1, "Expected only one paid outfit model to remain missing")

	var purchasable := available_paid[0]
	var purchasable_id := str(purchasable.get("id", ""))
	var price := int(purchasable.get("price", 0))
	world.set("_coins", price)
	assert(bool(world.call("_try_purchase_wardrobe_outfit", purchasable_id)), "Available outfit purchase failed")
	assert(int(world.get("_coins")) == 0, "Available outfit did not deduct the exact catalog price")
	assert(bool(manager.owns_outfit(purchasable_id)), "Purchased outfit was not recorded as owned")
	assert(bool(world.call("_try_purchase_wardrobe_outfit", purchasable_id)), "Repeated purchase should be treated as already owned")
	assert(int(world.get("_coins")) == 0, "Repeated purchase deducted coins")
	assert(bool(manager.equip_outfit(purchasable_id)), "Purchased outfit could not be equipped")
	assert(bool(player.call("apply_outfit", purchasable_id, str(purchasable.get("model_path", "")))), "Purchased outfit model could not be applied")
	assert(visual_root.get_child_count() == 1, "Outfit switch created multiple visual instances")

	var missing_id := str(missing_paid[0].get("id", ""))
	world.set("_coins", 999999)
	var before_missing_purchase := int(world.get("_coins"))
	assert(not bool(world.call("_try_purchase_wardrobe_outfit", missing_id)), "Missing outfit model should not be purchasable")
	assert(int(world.get("_coins")) == before_missing_purchase, "Missing outfit model deducted coins")
	assert(bool(player.call("apply_outfit", WardrobeCatalog.DEFAULT_OUTFIT_ID, str(WardrobeCatalog.get_outfit(WardrobeCatalog.DEFAULT_OUTFIT_ID).get("model_path", "")))))
	assert(visual_root.get_child_count() == 1, "切换默认服装重建了多份模型")
	var reloaded_manager: Node = (load("res://scripts/managers/wardrobe_manager.gd") as Script).new()
	add_child(reloaded_manager)
	await get_tree().process_frame
	assert(bool(reloaded_manager.is_wardrobe_unlocked()), "服装事件状态没有持久化")
	assert(int(reloaded_manager.collected_bundle_count()) == 3, "衣物包收集进度没有持久化")

	print("WARDROBE_SMOKE_PASS event=unlocked bundles=3 outfits=5 default_model=true")
	reloaded_manager.queue_free()
	world.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit()
