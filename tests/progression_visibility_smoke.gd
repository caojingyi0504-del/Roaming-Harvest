extends SceneTree

const BusinessDiscoveryCatalog = preload("res://scripts/business_discovery_catalog.gd")
const LocalEventCatalog = preload("res://scripts/local_event_catalog.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/GrassWorld.tscn") as PackedScene
	assert(packed != null, "PROGRESSION_VISIBILITY_SMOKE: GrassWorld failed to load")
	var world := packed.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	world.set("_business_level_stars", {})
	world.set("_business_discovery_states", {})
	world.call("_build_chapter_one_scene")
	await process_frame
	await process_frame

	# Remove any visuals inherited from a developer save so the test starts from a
	# true new-game progression state.
	var visuals := world.get("_mainline_site_visuals") as Dictionary
	for candidate in visuals.values():
		if candidate is Node and is_instance_valid(candidate):
			(candidate as Node).queue_free()
	visuals.clear()
	world.set("_business_level_stars", {})
	world.set("_business_discovery_states", {})
	await process_frame

	var player := world.get("_player") as Node3D
	assert(player != null, "PROGRESSION_VISIBILITY_SMOKE: player missing")
	var hidden_position: Vector3 = world.call("_mainline_site_world_position", 2)
	player.global_position = hidden_position
	world.call("_update_mainline_discovery_sites", 0.0)
	assert((world.get("_mainline_site_visuals") as Dictionary).is_empty(), "locked mainline sites must not be created")
	assert(int(world.call("_nearby_mainline_site_level")) == 0, "locked mainline site exposed an interaction")
	assert(not bool(world.call("_open_mainline_commission_card", 2)), "locked mainline site opened its commission card")

	# Every site becomes visible and playable as soon as its clue state is active,
	# and every imported model must sit on the event root's local ground plane.
	for level_id in BusinessDiscoveryCatalog.all_level_ids():
		world.call("_set_business_discovery_state", level_id, BusinessDiscoveryCatalog.STATE_CLUE, false)
		var site_position: Vector3 = world.call("_mainline_site_world_position", level_id)
		player.global_position = site_position
		world.call("_update_mainline_discovery_sites", 0.0)
		var site_root := (world.get("_mainline_site_visuals") as Dictionary).get(str(level_id)) as Node3D
		assert(site_root != null and site_root.visible, "unlocked mainline site must be visible: %d" % level_id)
		assert(int(world.call("_nearby_mainline_site_level")) == level_id, "unlocked mainline site must be interactable: %d" % level_id)
		var model := site_root.get_node_or_null("SiteModel") as Node3D
		assert(model != null, "mainline site model missing: %d" % level_id)
		var bounds: AABB = world.call("_get_node_bounds_in_space", model, site_root)
		assert(absf(bounds.position.y) <= 0.002, "mainline site model is not grounded: %d bottom=%f" % [level_id, bounds.position.y])

	assert(bool(world.call("_open_mainline_commission_card", 2)), "unlocked mainline site card failed to open")
	world.call("_close_mainline_commission_card")

	for event_id in LocalEventCatalog.ALL_IDS:
		var event_root := world.call("_create_local_event_visual", event_id) as Node3D
		assert(event_root != null and event_root.get_child_count() >= 1, "local event model missing: %s" % event_id)
		var event_model := event_root.get_child(0) as Node3D
		var event_bounds: AABB = world.call("_get_node_bounds_in_space", event_model, event_root)
		assert(absf(event_bounds.position.y) <= 0.002, "local event model is not grounded: %s bottom=%f" % [event_id, event_bounds.position.y])

	world.queue_free()
	await process_frame
	await process_frame
	print("PROGRESSION_VISIBILITY_SMOKE: PASS")
	quit(0)
