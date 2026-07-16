extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/GrassWorld.tscn") as PackedScene
	assert(packed != null, "FIRST_DAY_TUTORIAL_SMOKE: GrassWorld failed to load")
	var world := packed.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame

	world.set("_chapter_one_active", true)
	world.set("_kitchen_intro_completed", false)
	world.set("_kitchen_first_day_completed", false)
	world.set("_post_tutorial_grand_reward_claimed", false)
	world.set("_opening_sign_placed", false)
	world.set("_tutorial_harvested_carrot_count", 5)
	world.set("_tutorial_stored_carrot_count", 0)
	world.set("_stored_crop_counts", {})
	world.set("_seed_inventory", {"carrot:0": 5})

	var level_one := world.call("_business_level_by_id", 1) as Dictionary
	assert(not level_one.is_empty(), "FIRST_DAY_TUTORIAL_SMOKE: level 1 missing")
	assert(int(world.call("_business_requirement_total", "carrot")) == 5, "formal requirement fixture must include seeds")
	assert(int(world.call("_business_level_requirement_total", level_one, "carrot")) == 0, "first day must ignore seeds and only count the food chest")
	assert(not bool(world.call("_is_kitchen_phase_unlocked")), "equipment unlocked before five carrots reached the food chest")

	world.set("_stored_crop_counts", {"carrot:0": 4})
	assert(not bool(world.call("_is_kitchen_phase_unlocked")), "equipment unlocked with only four stored carrots")
	world.set("_stored_crop_counts", {"carrot:0": 5})
	assert(bool(world.call("_is_kitchen_phase_unlocked")), "equipment did not unlock after five stored carrots")
	assert(int(world.call("_business_level_requirement_total", level_one, "carrot")) == 5, "first-day gate did not count food chest carrots")

	world.set("_tutorial_stored_carrot_count", 5)
	world.set("_stored_crop_counts", {})
	assert(bool(world.call("_is_kitchen_phase_unlocked")), "equipment relocked after the completed storage milestone")
	assert(int(world.call("_business_level_requirement_total", level_one, "carrot")) == 0, "first-day start gate accepted an empty food chest")

	var equipment_roots := {}
	for equipment_id in ["sink", "pot", "prep_shelf"]:
		var equipment := Node3D.new()
		world.add_child(equipment)
		equipment_roots["%s:1" % equipment_id] = equipment
	world.set("_kitchen_equipment_roots", equipment_roots)
	world.set("_kitchen_intro_completed", true)
	assert(not bool(world.call("_can_start_first_kitchen_business")), "first business started without five current chest carrots")
	world.set("_stored_crop_counts", {"carrot:0": 5})
	assert(bool(world.call("_can_start_first_kitchen_business")), "first business stayed locked with equipment and five chest carrots")

	world.set("_kitchen_first_day_completed", true)
	world.set("_stored_crop_counts", {})
	assert(int(world.call("_business_level_requirement_total", level_one, "carrot")) == 5, "replay did not restore the normal seed/field/chest rule")

	equipment_roots.clear()
	root.remove_child(world)
	world.free()
	await process_frame
	await process_frame
	print("FIRST_DAY_TUTORIAL_SMOKE: PASS")
	quit(0)
