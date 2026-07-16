extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var manager := root.get_node_or_null("FlowerGardenManager")
	if manager == null:
		push_error("FLOWER_GARDEN_SMOKE: autoload missing")
		quit(6)
		return
	var original_unlocked := bool(manager.get("unlocked"))
	manager.set("unlocked", false)
	var original_plots: Array = (manager.get("plots") as Array).duplicate(true)
	var temporary_plots: Array = original_plots.duplicate(true)
	temporary_plots[0] = {"flower_id": "marigold", "planted_at_unix": 1000.0}
	manager.set("plots", temporary_plots)
	var mature: Dictionary = manager.call("plot_snapshot", 0, 1901.0)
	var rollback: Dictionary = manager.call("plot_snapshot", 0, 990.0)
	manager.set("plots", original_plots)
	if not bool(mature.get("ready", false)) or float(rollback.get("progress", -1.0)) != 0.0:
		push_error("FLOWER_GARDEN_SMOKE: offline timestamp calculation failed")
		quit(4)
		return
	if int(manager.call("seed_purchase_cost", "lavender", 5)) != 40:
		push_error("FLOWER_GARDEN_SMOKE: seed pricing failed")
		quit(5)
		return
	var original_active := str(manager.get("active_gift"))
	var original_quality_remaining := int(manager.get("active_quality_remaining"))
	var original_quality_orders := int(manager.get("active_quality_orders"))
	manager.set("active_gift", "calming_bouquet")
	if float(manager.call("active_order_time_bonus")) != 5.0:
		push_error("FLOWER_GARDEN_SMOKE: calming gift failed")
		quit(7)
		return
	manager.set("active_gift", "sunny_welcome_basket")
	if int(manager.call("active_order_coin_bonus", 100)) != 8:
		push_error("FLOWER_GARDEN_SMOKE: coin gift failed")
		quit(8)
		return
	manager.set("active_gift", "starblue_plating_flowers")
	manager.set("active_quality_remaining", 2)
	if not bool(manager.call("try_apply_active_quality_bonus")) or not bool(manager.call("try_apply_active_quality_bonus")) or bool(manager.call("try_apply_active_quality_bonus")):
		push_error("FLOWER_GARDEN_SMOKE: quality gift charge count failed")
		quit(9)
		return
	manager.set("active_gift", original_active)
	manager.set("active_quality_remaining", original_quality_remaining)
	manager.set("active_quality_orders", original_quality_orders)
	var packed := load("res://scenes/GrassWorld.tscn") as PackedScene
	if packed == null:
		push_error("FLOWER_GARDEN_SMOKE: failed to load GrassWorld")
		quit(1)
		return
	var world := packed.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	world.call("_build_chapter_one_scene")
	await process_frame
	await process_frame
	var controller = world.get("_flower_garden_controller")
	if controller == null or not is_instance_valid(controller):
		push_error("FLOWER_GARDEN_SMOKE: controller missing")
		quit(2)
		return
	if controller.get("world_root") != null or controller.get("plot_visual_roots").size() != 0:
		push_error("FLOWER_GARDEN_SMOKE: locked garden leaked world visuals")
		quit(3)
		return
	var player := world.get("_player") as Node3D
	var gate := Vector3(36.0, 0.0, 28.0)
	gate.y = float(world.call("_height_at", gate.x, gate.z))
	player.global_position = gate
	if str(controller.call("_nearest_action")) != "":
		push_error("FLOWER_GARDEN_SMOKE: locked garden exposed an interaction")
		quit(11)
		return
	world.set("_map_open", true)
	world.set("_map_camper_pos", Vector2(0.30, 0.67))
	world.call("_update_map_popup", 1.0)
	var map_label := world.get("_map_locked_label") as Label
	if map_label == null or map_label.text != "" or bool(world.call("_try_enter_map_destination")):
		push_error("FLOWER_GARDEN_SMOKE: locked map revealed the garden destination")
		quit(14)
		return
	world.set("_map_open", false)
	manager.set("unlocked", true)
	manager.emit_signal("state_changed")
	await process_frame
	var created_world := controller.get("world_root") as Node3D
	if created_world == null or controller.get("plot_visual_roots").size() != 3:
		push_error("FLOWER_GARDEN_SMOKE: unlocked garden did not create three plots")
		quit(12)
		return
	manager.emit_signal("state_changed")
	await process_frame
	if controller.get("world_root") != created_world or controller.get("plot_visual_roots").size() != 3:
		push_error("FLOWER_GARDEN_SMOKE: garden world was created more than once")
		quit(13)
		return
	world.set("_map_open", true)
	world.call("_update_map_popup", 1.0)
	if map_label.text != "晨露花圃":
		push_error("FLOWER_GARDEN_SMOKE: unlocked map did not reveal the garden")
		quit(15)
		return
	world.set("_map_open", false)
	for tab in ["plots", "seeds", "gifts"]:
		controller.call("open_panel", tab)
		await process_frame
		var garden_panel := controller.get("panel") as Control
		if garden_panel == null or garden_panel.size.x > 900.1 or garden_panel.size.y > 540.1:
			push_error("FLOWER_GARDEN_SMOKE: panel layout overflow on %s" % tab)
			quit(10)
			return
	controller.call("close_panel")
	world.queue_free()
	await process_frame
	await process_frame

	# An already-unlocked save must restore the garden during controller setup,
	# without waiting for a fresh unlock signal.
	manager.set("unlocked", true)
	var restored_world := packed.instantiate()
	root.add_child(restored_world)
	await process_frame
	await process_frame
	restored_world.call("_build_chapter_one_scene")
	await process_frame
	await process_frame
	var restored_controller = restored_world.get("_flower_garden_controller")
	if restored_controller == null or restored_controller.get("world_root") == null or restored_controller.get("plot_visual_roots").size() != 3:
		push_error("FLOWER_GARDEN_SMOKE: unlocked save did not restore the garden")
		quit(16)
		return
	restored_world.queue_free()
	manager.set("unlocked", original_unlocked)
	await process_frame
	await process_frame
	print("FLOWER_GARDEN_SMOKE: PASS")
	quit(0)
