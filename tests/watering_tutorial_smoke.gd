extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/GrassWorld.tscn") as PackedScene
	assert(packed != null, "WATERING_TUTORIAL_SMOKE: GrassWorld failed to load")
	var world := packed.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame

	world.set("_chapter_one_active", true)
	world.set("_watering_guide_completed", false)
	world.set("_tutorial_watered_carrot_total", 0)
	world.set("_tutorial_harvested_carrot_count", 3)
	world.set("_scythe_collected", false)
	world.set("_scythe_task_prompt_active", false)

	# Old live state from the reported bug: three carrots were harvested and the
	# remaining two are still watered in the field.
	var legacy_centers: Array[Vector2] = [Vector2(0.0, 0.0), Vector2(3.0, 0.0)]
	_set_carrot_fixtures(world, legacy_centers)
	world.set("_watered_soil_centers", legacy_centers.duplicate())
	assert(int(world.call("_current_watered_tutorial_carrot_count")) == 2, "legacy fixture must have two live watered carrots")
	assert(int(world.call("_tutorial_watered_carrot_progress")) == 5, "3 harvested + 2 live watered carrots did not recover to 5/5")
	world.call("_sync_tutorial_watering_completion")
	assert(bool(world.get("_watering_guide_completed")), "recovered progress did not complete watering tutorial")
	assert(bool(world.get("_scythe_task_prompt_active")), "recovered progress did not unlock the scythe step")

	# Once completed, clearing live field state must never reduce progress.
	_clear_carrot_fixtures(world)
	(world.get("_watered_soil_centers") as Array).clear()
	assert(int(world.call("_tutorial_watered_carrot_progress")) == 5, "harvesting reduced completed watering progress")

	# A fresh tutorial accumulates successful watering events across harvests.
	world.set("_watering_guide_completed", false)
	world.set("_tutorial_watered_carrot_total", 0)
	world.set("_tutorial_harvested_carrot_count", 0)
	world.set("_scythe_task_prompt_active", false)
	world.set("_scythe_collected", true)
	var first_batch: Array[Vector2] = [Vector2(0.0, 0.0), Vector2(3.0, 0.0), Vector2(6.0, 0.0)]
	_set_carrot_fixtures(world, first_batch)
	for center in first_batch:
		(world.get("_watered_soil_centers") as Array).append(center)
		world.call("_record_tutorial_carrot_watered", center)
	var first_progress := int(world.call("_tutorial_watered_carrot_progress"))
	assert(first_progress == 3, "first three watering events were not accumulated: progress=%d total=%d completed=%s" % [first_progress, int(world.get("_tutorial_watered_carrot_total")), str(world.get("_watering_guide_completed"))])

	_clear_carrot_fixtures(world)
	(world.get("_watered_soil_centers") as Array).clear()
	world.set("_tutorial_harvested_carrot_count", 3)
	var second_batch: Array[Vector2] = [Vector2(0.0, 3.0), Vector2(3.0, 3.0)]
	_set_carrot_fixtures(world, second_batch)
	for center in second_batch:
		(world.get("_watered_soil_centers") as Array).append(center)
		world.call("_record_tutorial_carrot_watered", center)
	assert(int(world.call("_tutorial_watered_carrot_progress")) == 5, "watering after harvest did not reach 5/5")
	assert(int(world.get("_tutorial_watered_carrot_total")) == 5, "cumulative watering progress exceeded or missed the cap")

	# Empty and full watering-can interactions must now explain what happened.
	world.call("_set_inventory_slot_item", 0, "watering_can")
	world.set("_selected_inventory_slot", 0)
	world.set("_has_watering_can", true)
	world.set("_water_amount", 0.0)
	world.set("_notification_text", "")
	assert(bool(world.call("_use_watering_can")), "empty watering can did not consume the interaction")
	assert(str(world.get("_notification_text")).contains("水壶没水"), "empty watering can did not show its refill hint")

	var player := world.get("_player") as Node3D
	assert(player != null, "WATERING_TUTORIAL_SMOKE: player missing")
	player.global_position = Vector3(-18.0, 0.0, 11.0)
	world.set("_water_amount", 1.0)
	world.set("_notification_text", "")
	assert(bool(world.call("_try_start_watering_fill")), "full watering can interaction was not handled at the pond")
	assert(str(world.get("_notification_text")).contains("已经装满"), "full watering can did not show its status")

	var audio_manager := root.get_node_or_null("AudioManager")
	if audio_manager != null:
		audio_manager.call("enter_intro_mode")
	_clear_carrot_fixtures(world)
	root.remove_child(world)
	world.free()
	await process_frame
	await process_frame
	print("WATERING_TUTORIAL_SMOKE: PASS")
	quit(0)


func _set_carrot_fixtures(world: Node, centers: Array[Vector2]) -> void:
	_clear_carrot_fixtures(world)
	var crop_nodes := {}
	var crop_types := {}
	var crop_root := Node3D.new()
	crop_root.name = "WateringTutorialFixtures"
	world.add_child(crop_root)
	world.set_meta("watering_tutorial_fixtures", crop_root)
	for center in centers:
		var crop := Node3D.new()
		crop.position = Vector3(center.x, 0.0, center.y)
		crop_root.add_child(crop)
		var key := str(world.call("_crop_key", center))
		crop_nodes[key] = crop
		crop_types[key] = "carrot"
	world.set("_crop_nodes", crop_nodes)
	world.set("_crop_types", crop_types)


func _clear_carrot_fixtures(world: Node) -> void:
	var fixture := world.get_meta("watering_tutorial_fixtures") as Node if world.has_meta("watering_tutorial_fixtures") else null
	if fixture != null and is_instance_valid(fixture):
		fixture.free()
	if world.has_meta("watering_tutorial_fixtures"):
		world.remove_meta("watering_tutorial_fixtures")
	world.set("_crop_nodes", {})
	world.set("_crop_types", {})
