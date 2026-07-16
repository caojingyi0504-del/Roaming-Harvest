extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var packed := load("res://scenes/GrassWorld.tscn") as PackedScene
	assert(packed != null, "KITCHEN_PLACEMENT_SMOKE: GrassWorld failed to load")
	var world := packed.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame

	var player := world.get("_player") as CharacterBody3D
	var visual := player.get_node_or_null("VisualRoot") as Node3D
	assert(player != null and visual != null, "KITCHEN_PLACEMENT_SMOKE: player missing")
	visual.rotation.y = 1.37
	world.set("_orbit", Vector2(-0.31, 0.42))
	world.call("_apply_camera")
	world.call("_start_kitchen_equipment_placement", "sink")
	assert(bool(world.call("_is_kitchen_equipment_placement_active")), "KITCHEN_PLACEMENT_SMOKE: placement did not start")
	assert(bool(world.call("_is_free_cursor_requested")), "KITCHEN_PLACEMENT_SMOKE: placement must request a free cursor")
	var expected_yaw := float(world.call("_snap_kitchen_equipment_yaw", -0.31 + PI))
	assert(is_equal_approx(float(world.get("_kitchen_placing_yaw")), expected_yaw), "KITCHEN_PLACEMENT_SMOKE: initial yaw is not camera-aligned")
	assert(not is_equal_approx(float(world.get("_kitchen_placing_yaw")), visual.rotation.y + PI), "KITCHEN_PLACEMENT_SMOKE: initial yaw still follows player facing")

	player.velocity = Vector3(4.0, 0.0, 2.0)
	player.call("_physics_process", 0.016)
	assert(player.velocity == Vector3.ZERO, "KITCHEN_PLACEMENT_SMOKE: player did not freeze during placement")

	var viewport_center := Vector2(root.size) * 0.5
	var hit := world.call("_kitchen_equipment_cursor_ground_hit", viewport_center) as Dictionary
	assert(bool(hit.get("valid", false)), "KITCHEN_PLACEMENT_SMOKE: center cursor did not hit terrain")
	var hit_position := hit.get("position", Vector3.ZERO) as Vector3
	assert(is_equal_approx(hit_position.y, float(world.call("_height_at", hit_position.x, hit_position.z))), "KITCHEN_PLACEMENT_SMOKE: cursor hit is not grounded")
	world.call("_update_kitchen_equipment_cursor_position", viewport_center)
	assert((world.get("_kitchen_placing_position") as Vector3).is_equal_approx(hit_position), "KITCHEN_PLACEMENT_SMOKE: cursor did not drive preview position")

	var yaw_before := float(world.get("_kitchen_placing_yaw"))
	world.call("_rotate_kitchen_equipment", 1)
	var yaw_after := float(world.get("_kitchen_placing_yaw"))
	assert(is_equal_approx(absf(angle_difference(yaw_before, yaw_after)), PI * 0.25), "KITCHEN_PLACEMENT_SMOKE: rotation step is not 45 degrees")
	var position_before := world.get("_kitchen_placing_position") as Vector3
	world.call("_nudge_kitchen_equipment", Vector2.RIGHT)
	var position_after := world.get("_kitchen_placing_position") as Vector3
	var nudge_distance := Vector2(position_before.x, position_before.z).distance_to(Vector2(position_after.x, position_after.z))
	assert(is_equal_approx(nudge_distance, 0.25), "KITCHEN_PLACEMENT_SMOKE: keyboard nudge is not 0.25m")

	world.call("_show_kitchen_equipment_placement_prompt")
	var prompt_label := world.get("_interaction_prompt_label") as Label
	assert(prompt_label != null and prompt_label.text.contains("旋转45°") and prompt_label.text.contains("方向键微调"), "KITCHEN_PLACEMENT_SMOKE: persistent control hint missing")
	world.set("_kitchen_placing_position", Vector3(72.0, 0.0, 0.0))
	world.set("_kitchen_placing_cursor_valid", true)
	assert(not bool(world.call("_is_kitchen_equipment_place_position_valid", Vector3(72.0, 0.0, 0.0))), "KITCHEN_PLACEMENT_SMOKE: out-of-bounds placement accepted")

	var pond_position := Vector3(-18.0, float(world.call("_height_at", -18.0, 11.0)), 11.0)
	world.set("_kitchen_placing_position", pond_position)
	assert(not bool(world.call("_is_kitchen_equipment_place_position_valid", pond_position)), "KITCHEN_PLACEMENT_SMOKE: pond placement accepted")
	world.call("_cancel_kitchen_equipment_placement")
	assert(not bool(world.call("_is_kitchen_equipment_placement_active")), "KITCHEN_PLACEMENT_SMOKE: placement did not cancel")

	var safe_position := _find_safe_position(world, player.global_position)
	var instance_id := "sink:1"
	var equipment := world.call("_create_kitchen_equipment_model", world, "sink", "SmokeSink", safe_position, false, instance_id) as Node3D
	assert(equipment != null, "KITCHEN_PLACEMENT_SMOKE: failed to create adjustment fixture")
	equipment.rotation.y = 0.37
	var roots := world.get("_kitchen_equipment_roots") as Dictionary
	roots[instance_id] = equipment
	world.set("_kitchen_equipment_roots", roots)
	world.call("_add_kitchen_equipment_blocker", equipment, "sink", instance_id)
	var original_position := equipment.global_position
	var original_yaw := equipment.rotation.y
	world.call("_begin_kitchen_equipment_adjustment", instance_id)
	assert((world.get("_kitchen_placing_position") as Vector3).is_equal_approx(original_position), "KITCHEN_PLACEMENT_SMOKE: adjustment did not preserve position")
	assert(is_equal_approx(float(world.get("_kitchen_placing_yaw")), original_yaw), "KITCHEN_PLACEMENT_SMOKE: adjustment did not preserve yaw")
	world.set("_kitchen_placing_position", original_position + Vector3(1.5, 0.0, 0.0))
	world.set("_kitchen_placing_yaw", PI * 0.25)
	world.call("_cancel_kitchen_equipment_placement")
	assert(equipment.global_position.is_equal_approx(original_position) and is_equal_approx(equipment.rotation.y, original_yaw), "KITCHEN_PLACEMENT_SMOKE: cancelling adjustment changed equipment")

	world.call("_remove_kitchen_equipment_instance_blocker", instance_id)
	roots.erase(instance_id)
	world.set("_kitchen_equipment_roots", roots)
	equipment.queue_free()
	world.queue_free()
	await process_frame
	await process_frame
	print("KITCHEN_PLACEMENT_SMOKE: PASS")
	quit(0)


func _find_safe_position(world: Node, origin: Vector3) -> Vector3:
	world.set("_kitchen_placing_equipment", "sink")
	world.set("_kitchen_placing_instance_id", "")
	world.set("_kitchen_placing_yaw", 0.0)
	world.set("_kitchen_placing_cursor_valid", true)
	for radius in [4.0, 6.0, 8.0]:
		for index in range(16):
			var angle := TAU * float(index) / 16.0
			var position := origin + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
			position.y = float(world.call("_height_at", position.x, position.z))
			world.set("_kitchen_placing_position", position)
			if bool(world.call("_is_kitchen_equipment_place_position_valid", position)):
				world.set("_kitchen_placing_equipment", "")
				return position
	world.set("_kitchen_placing_equipment", "")
	assert(false, "KITCHEN_PLACEMENT_SMOKE: no safe fixture position found")
	return origin
