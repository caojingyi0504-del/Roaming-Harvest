extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _fail(message: String, code: int) -> void:
	push_error("MAP_CODEX_SMOKE: %s" % message)
	quit(code)


func _escape_event() -> InputEventKey:
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = KEY_ESCAPE
	return event


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var packed := load("res://scenes/GrassWorld.tscn") as PackedScene
	if packed == null:
		_fail("GrassWorld scene failed to load", 1)
		return
	var world := packed.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	world.call("_build_chapter_one_scene")
	for _frame in range(3):
		await process_frame

	var crop_ids := world.call("_codex_known_ids", "crop") as Array
	var cooking_ids := world.call("_codex_known_ids", "cooking") as Array
	if crop_ids.size() < 10 or cooking_ids.size() < 10:
		_fail("codex source lists are incomplete", 2)
		return
	world.set("_codex_discovered_crops", {str(crop_ids[0]): true, str(crop_ids[1]): true, str(crop_ids[2]): true})
	world.set("_codex_revealed_crops", {str(crop_ids[0]): true, str(crop_ids[1]): true})
	world.set("_codex_discovered_cooking", {str(cooking_ids[0]): true, str(cooking_ids[1]): true})
	world.set("_codex_revealed_cooking", {str(cooking_ids[0]): true})
	world.set("_local_event_atlas", {
		"rabbit_lantern_party": {
			"best_stars": 3,
			"reward_revealed": true,
			"special_recipe_researched": true,
			"special_recipe_served": false,
		}
	})
	world.call("_open_map_popup")
	for _frame in range(2):
		await process_frame

	var map_panel := world.get("_map_panel") as Control
	var exit_button := world.get("_map_exit_button") as Button
	var left_button := world.get("_map_page_left_button") as Button
	var right_button := world.get("_map_page_right_button") as Button
	var page_dots := world.get("_map_page_dots") as HBoxContainer
	var entry_button := world.get("_map_codex_entry_button") as Button
	var entry_count := world.get("_map_codex_entry_count_label") as Label
	var entry_notice := world.get("_map_codex_entry_red_dot") as Label
	var entry_panel := world.get("_map_codex_panel") as Control
	var locked_toast := world.get("_map_page_locked_label") as Label
	if map_panel == null or not map_panel.visible or exit_button == null or exit_button.text != "返回":
		_fail("cream map shell was not created", 3)
		return
	if left_button == null or right_button == null or page_dots == null or page_dots.get_child_count() != 5:
		_fail("locked map navigation was not created", 4)
		return
	if entry_button == null or entry_count == null or entry_notice == null or entry_panel == null:
		_fail("single codex entry was not created", 16)
		return
	if entry_count.text != "6/24" or not entry_notice.visible or entry_panel.get_child_count() != 3:
		_fail("single codex entry progress or attention state is incorrect", 17)
		return
	for cream_button in [entry_button, exit_button, left_button, right_button]:
		if not (cream_button.get_theme_stylebox("normal") is StyleBoxFlat):
			_fail("map shell still uses textured orange controls", 18)
			return
	var camper_before := world.get("_map_camper_pos") as Vector2
	world.call("_on_map_page_left_pressed")
	if (world.get("_map_camper_pos") as Vector2) != camper_before or float(world.get("_map_page_locked_time")) <= 0.0 or locked_toast == null:
		_fail("locked page navigation changed map state or omitted feedback", 5)
		return
	if locked_toast.position.y < map_panel.size.y * 0.70:
		_fail("locked page feedback is not kept in the bottom safe area", 19)
		return
	for _step in range(15):
		world.call("_update_map_popup", 0.1)
	if float(world.get("_map_page_locked_time")) > 0.0:
		_fail("locked page feedback did not expire", 20)
		return

	world.set("_map_codex_active_tab", "flavor")
	entry_button.emit_signal("pressed")
	for _frame in range(3):
		await process_frame
	if not bool(world.call("_is_map_codex_open")) or str(world.get("_map_codex_active_tab")) != "flavor" or (world.get("_map_codex_card_nodes") as Dictionary).size() != 4:
		_fail("single codex entry did not reopen the last tab", 21)
		return
	world.call("_hide_map_codex_detail_popup")
	await process_frame

	world.call("_show_map_codex_detail_popup", "crop")
	for _frame in range(3):
		await process_frame
	var modal := world.get("_map_codex_detail_popup") as Control
	var book := world.get("_map_codex_book_panel") as Control
	var card_nodes := world.get("_map_codex_card_nodes") as Dictionary
	if modal == null or not modal.visible or book == null or card_nodes.size() != 10:
		_fail("crop codex page did not create ten cards", 6)
		return
	world.set("_map_dragging", true)
	world.set("_map_drag_vector", Vector2.ONE)
	world.call("_update_map_popup", 0.016)
	if bool(world.get("_map_dragging")) or (world.get("_map_drag_vector") as Vector2) != Vector2.ZERO:
		_fail("map input remained active behind the codex", 7)
		return

	var first_crop_key := "crop:%s" % str(crop_ids[0])
	var first_crop_card := card_nodes.get(first_crop_key, null) as Button
	if first_crop_card == null:
		_fail("known crop card was not indexed", 8)
		return
	first_crop_card.emit_signal("pressed")
	await process_frame
	if str(world.get("_map_codex_selected_id")) != first_crop_key:
		_fail("crop card selection did not update", 9)
		return

	world.call("_set_map_codex_tab", "cooking")
	await process_frame
	if (world.get("_map_codex_card_nodes") as Dictionary).size() != 10:
		_fail("cooking codex page did not create ten cards", 10)
		return
	world.call("_set_map_codex_tab", "flavor")
	await process_frame
	if (world.get("_map_codex_card_nodes") as Dictionary).size() != 4:
		_fail("local flavor page did not create four postcards", 11)
		return

	world.call("_set_map_codex_tab", "crop")
	await process_frame
	var coins_before := int(world.get("_coins"))
	world.call("_claim_map_codex_reward_at", "crop", 1)
	await process_frame
	if int(world.get("_coins")) != coins_before + 20 or not bool((world.get("_codex_claimed_rewards") as Dictionary).get("crop:1", false)):
		_fail("codex reward settlement changed", 12)
		return

	for viewport_size in [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = viewport_size
		for _frame in range(2):
			await process_frame
		world.call("_layout_map_codex_popup", true)
		world.call("_layout_map_shell_controls")
		await process_frame
		var rect := book.get_global_rect()
		var logical_size := world.get_viewport().get_visible_rect().size
		if rect.position.x < -0.5 or rect.position.y < -0.5 or rect.end.x > logical_size.x + 0.5 or rect.end.y > logical_size.y + 0.5:
			_fail("codex panel overflowed at %s / %s: %s" % [viewport_size, logical_size, rect], 13)
			return
		var entry_rect := entry_panel.get_global_rect()
		var map_display_rect := world.call("_map_texture_display_rect") as Rect2
		var expected_entry_center := map_display_rect.position + map_display_rect.size * Vector2(0.347, 0.323)
		var actual_entry_center := entry_button.get_global_rect().get_center()
		if actual_entry_center.distance_to(expected_entry_center) > 2.0:
			_fail("codex entry left its village map anchor at %s: %s / %s" % [viewport_size, actual_entry_center, expected_entry_center], 22)
			return
		if entry_rect.position.x < -0.5 or entry_rect.position.y < -0.5 or entry_rect.end.x > logical_size.x + 0.5 or entry_rect.end.y > logical_size.y + 0.5:
			_fail("codex entry overflowed at %s: %s" % [viewport_size, entry_rect], 24)
			return
		for shell_control in [exit_button, left_button, right_button, page_dots]:
			var control_rect := (shell_control as Control).get_global_rect()
			if control_rect.position.x < -0.5 or control_rect.position.y < -0.5 or control_rect.end.x > logical_size.x + 0.5 or control_rect.end.y > logical_size.y + 0.5:
				_fail("map shell control overflowed at %s: %s" % [viewport_size, control_rect], 23)
				return

	root.size = Vector2i(1280, 720)
	await process_frame
	world.call("_handle_map_input", _escape_event())
	await process_frame
	if bool(world.call("_is_map_codex_open")) or not bool(world.get("_map_open")):
		_fail("first Escape did not close only the codex", 14)
		return
	world.call("_handle_map_input", _escape_event())
	await process_frame
	if bool(world.get("_map_open")):
		_fail("second Escape did not close the map", 15)
		return

	world.queue_free()
	for _frame in range(5):
		await process_frame
	packed = null
	await process_frame
	print("MAP_CODEX_SMOKE: PASS")
	quit(0)
