extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var packed := load("res://scenes/GrassWorld.tscn") as PackedScene
	assert(packed != null, "CAMPER_DRIVING_SMOKE: GrassWorld failed to load")
	var world := packed.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	world.call("_build_chapter_one_scene")
	await process_frame
	await process_frame

	var constants := (world.get_script() as Script).get_script_constant_map()
	var forward_speed := float(constants.get("CAMPER_DRIVE_FORWARD_SPEED", 7.0))
	var reverse_speed := -float(constants.get("CAMPER_DRIVE_REVERSE_SPEED", 3.2))
	var left_forward_yaw := float(world.call("_camper_turn_yaw", 0.0, -1.0, forward_speed, 0.25))
	var right_forward_yaw := float(world.call("_camper_turn_yaw", 0.0, 1.0, forward_speed, 0.25))
	assert(left_forward_yaw > 0.0, "CAMPER_DRIVING_SMOKE: A/left still turns the camper right")
	assert(right_forward_yaw < 0.0, "CAMPER_DRIVING_SMOKE: D/right still turns the camper left")
	assert(float(world.call("_camper_turn_yaw", 0.37, 0.0, forward_speed, 0.25)) == 0.37, "CAMPER_DRIVING_SMOKE: neutral steering changed yaw")
	assert(float(world.call("_camper_turn_yaw", 0.37, -1.0, 0.0, 0.25)) == 0.37, "CAMPER_DRIVING_SMOKE: a stopped camper changed yaw")
	assert(float(world.call("_camper_turn_yaw", 0.0, -1.0, reverse_speed, 0.25)) < 0.0, "CAMPER_DRIVING_SMOKE: reverse steering is not vehicle-realistic")
	assert(float(world.call("_camper_turn_yaw", 0.0, 1.0, reverse_speed, 0.25)) > 0.0, "CAMPER_DRIVING_SMOKE: reverse right steering is incorrect")

	var camper := world.get("_camper") as Node3D
	var camper_model := world.get("_camper_model") as Node3D
	var player := world.get("_player") as CharacterBody3D
	assert(camper != null and camper_model != null and player != null, "CAMPER_DRIVING_SMOKE: camper or player missing")
	var blocker := world.call("_camper_blocker_data", camper, camper_model) as Dictionary
	var candidates := world.call("_camper_exit_candidate_positions", blocker) as Array
	assert(not blocker.is_empty() and candidates.size() == 8, "CAMPER_DRIVING_SMOKE: actual camper bounds did not produce eight exit candidates")

	# A normal exit must be outside the rebuilt camper blocker and immediately movable.
	_begin_simulated_drive(world)
	assert(bool(world.call("_try_exit_camper_driving")), "CAMPER_DRIVING_SMOKE: normal exit was not handled")
	assert(not bool(world.get("_camper_driving")), "CAMPER_DRIVING_SMOKE: normal exit left driving enabled")
	assert(bool(world.call("_is_safe_camper_exit_position", player.global_position)), "CAMPER_DRIVING_SMOKE: player spawned inside the final camper footprint")
	assert(not bool(world.call("_is_blocked_by_solid", player.global_position)), "CAMPER_DRIVING_SMOKE: player is blocked immediately after exiting")

	# Kitchen fixtures on both sides must make the search fall back to the tail/front/diagonals.
	blocker = world.call("_camper_blocker_data", camper, camper_model) as Dictionary
	candidates = world.call("_camper_exit_candidate_positions", blocker) as Array
	var equipment_roots := world.get("_kitchen_equipment_roots") as Dictionary
	var fixture_ids := ["sink:camper_exit_left", "pot:camper_exit_right"]
	for index in range(2):
		var fixture_id: String = fixture_ids[index]
		var equipment_id := "sink" if index == 0 else "pot"
		var fixture_position: Vector3 = candidates[index]
		var fixture := world.call("_create_kitchen_equipment_model", world, equipment_id, "CamperExitFixture%d" % index, fixture_position, false, fixture_id) as Node3D
		assert(fixture != null, "CAMPER_DRIVING_SMOKE: failed to create side fixture")
		equipment_roots[fixture_id] = fixture
	world.set("_kitchen_equipment_roots", equipment_roots)
	_begin_simulated_drive(world)
	var packed_exit := world.call("_find_safe_camper_exit_position") as Vector3
	assert(packed_exit.x != INF, "CAMPER_DRIVING_SMOKE: side fixtures prevented every exit")
	assert(_flat_distance(packed_exit, candidates[0]) > 0.2 and _flat_distance(packed_exit, candidates[1]) > 0.2, "CAMPER_DRIVING_SMOKE: exit search ignored packed side fixtures")
	assert(bool(world.call("_try_exit_camper_driving")), "CAMPER_DRIVING_SMOKE: fixture exit was not handled")
	assert(not bool(world.get("_camper_driving")), "CAMPER_DRIVING_SMOKE: fixture exit left driving enabled")
	assert(bool(world.call("_is_safe_camper_exit_position", player.global_position)), "CAMPER_DRIVING_SMOKE: final fixture blockers trapped the player")
	assert(not bool(world.call("_is_blocked_by_solid", player.global_position)), "CAMPER_DRIVING_SMOKE: fixture exit spawned on a blocker")

	for fixture_id in fixture_ids:
		world.call("_remove_kitchen_equipment_instance_blocker", fixture_id)
		(world.get("_kitchen_equipment_bubbles") as Dictionary).erase(fixture_id)
		var fixture := equipment_roots.get(fixture_id) as Node3D
		if fixture != null and is_instance_valid(fixture):
			fixture.queue_free()
		equipment_roots.erase(fixture_id)
	world.set("_kitchen_equipment_roots", equipment_roots)
	await process_frame

	# When every candidate is blocked, F must keep the player safely in driving mode.
	blocker = world.call("_camper_blocker_data", camper, camper_model) as Dictionary
	candidates = world.call("_camper_exit_candidate_positions", blocker) as Array
	_begin_simulated_drive(world)
	var solid_blockers := world.get("_solid_blockers") as Array
	for candidate in candidates:
		solid_blockers.append({
			"shape": "circle",
			"center": candidate,
			"radius": 0.75,
			"camper_exit_smoke": true,
		})
	assert(bool(world.call("_try_exit_camper_driving")), "CAMPER_DRIVING_SMOKE: blocked exit input was not handled")
	assert(bool(world.get("_camper_driving")), "CAMPER_DRIVING_SMOKE: no-safe-space exit incorrectly left driving mode")
	assert(not (player.get_node("VisualRoot") as Node3D).visible, "CAMPER_DRIVING_SMOKE: player became visible without a safe exit")

	world.queue_free()
	await process_frame
	await process_frame
	print("CAMPER_DRIVING_SMOKE: PASS")
	quit(0)


func _begin_simulated_drive(world: Node) -> void:
	world.call("_pack_camper_travel_attachments")
	world.call("_remove_camper_blocker")
	world.set("_camper_driving", true)
	world.set("_camper_drive_speed", 0.0)
	world.call("_set_player_camper_driving_state", true)


func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))
