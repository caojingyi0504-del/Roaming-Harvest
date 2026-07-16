extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _fail(message: String, exit_code: int) -> void:
	push_error("REBAS_SHOP_SMOKE: %s" % message)
	quit(exit_code)


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

	var overlay := world.get("_shop_overlay") as Control
	var panel := world.get("_shop_panel") as Control
	var task_board := world.get("_post_tutorial_objective") as Control
	var interaction_prompt := world.get("_interaction_prompt") as Control
	if overlay == null or panel == null or task_board == null or interaction_prompt == null:
		_fail("shop or HUD controls were not created", 2)
		return

	world.set("_chapter_one_active", true)
	world.set("_post_tutorial_grand_reward_claimed", true)
	world.set("_coins", 200)
	world.set("_stored_crop_counts", {"carrot:0": 3, "pea:1": 2})
	world.call("_update_post_tutorial_objective")
	interaction_prompt.visible = true
	if not task_board.visible:
		_fail("task board test precondition was not met", 3)
		return

	world.call("_open_rebas_shop")
	for _frame in range(3):
		await process_frame
	if not overlay.visible:
		_fail("shop did not open", 4)
		return
	if task_board.visible or interaction_prompt.visible:
		_fail("world HUD remained visible over the shop", 5)
		return
	if overlay.z_index <= task_board.z_index:
		_fail("shop modal layer is not above the task board", 6)
		return

	var card_nodes := world.get("_shop_card_nodes") as Dictionary
	var carrot_card := card_nodes.get("sell:carrot:0", null) as PanelContainer
	if carrot_card == null:
		_fail("sell card was not created", 7)
		return
	world.call("_change_shop_quantity", "sell:carrot:0", 1)
	await process_frame
	var same_card := (world.get("_shop_card_nodes") as Dictionary).get("sell:carrot:0", null) as PanelContainer
	var quantity_label := carrot_card.get_node_or_null("Margin/Content/QuantityRow/Quantity") as Label
	var summary := world.get("_shop_summary_label") as Label
	var action := world.get("_shop_action_button") as Button
	if same_card != carrot_card or quantity_label == null or quantity_label.text != "1":
		_fail("quantity change rebuilt the card or failed to refresh it", 8)
		return
	if summary == null or not summary.text.contains("预计获得") or action == null or action.disabled:
		_fail("sell summary did not update", 9)
		return

	var sell_price := int(world.call("_crop_sell_price", "carrot", 0))
	world.call("_execute_shop_action")
	await process_frame
	if int(world.get("_coins")) != 200 + sell_price:
		_fail("sell transaction coin result changed", 10)
		return
	var stored_counts := world.get("_stored_crop_counts") as Dictionary
	if int(stored_counts.get("carrot:0", 0)) != 2:
		_fail("sell transaction inventory result changed", 11)
		return

	world.set("_shop_daily_key", str(world.call("_shop_day_key")))
	world.set("_shop_buy_stock", {"seed:carrot:0": 1})
	world.call("_set_shop_mode", "buy")
	await process_frame
	card_nodes = world.get("_shop_card_nodes") as Dictionary
	if card_nodes.size() != 1 or not card_nodes.has("seed:carrot:0"):
		_fail("single-item buy stock did not render as one card", 12)
		return
	var seed_before := int(world.call("_get_seed_count", "carrot", 0))
	var buy_price := int(world.call("_seed_buy_price", "carrot", 0))
	var coins_before_buy := int(world.get("_coins"))
	world.call("_change_shop_quantity", "seed:carrot:0", 1)
	world.call("_execute_shop_action")
	await process_frame
	if int(world.call("_get_seed_count", "carrot", 0)) != seed_before + 1:
		_fail("buy transaction inventory result changed", 13)
		return
	if int(world.get("_coins")) != coins_before_buy - buy_price:
		_fail("buy transaction coin result changed", 14)
		return

	world.set("_stored_crop_counts", {})
	world.call("_set_shop_mode", "sell")
	await process_frame
	var grid := world.get("_shop_grid") as GridContainer
	if grid == null or grid.get_node_or_null("ShopEmptyState") == null:
		_fail("empty sell state was not created", 15)
		return

	for viewport_size in [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = viewport_size
		for _frame in range(2):
			await process_frame
		world.call("_layout_rebas_shop", true)
		await process_frame
		var rect := panel.get_global_rect()
		var logical_size := world.get_viewport().get_visible_rect().size
		if rect.position.x < -0.5 or rect.position.y < -0.5 or rect.end.x > logical_size.x + 0.5 or rect.end.y > logical_size.y + 0.5:
			_fail("panel overflowed at window %s / viewport %s: %s" % [viewport_size, logical_size, rect], 16)
			return

	root.size = Vector2i(1280, 720)
	await process_frame
	world.call("_close_rebas_shop")
	await process_frame
	if overlay.visible:
		_fail("shop did not close", 17)
		return
	if not task_board.visible:
		_fail("task board was not restored after closing the shop", 18)
		return

	world.queue_free()
	for _frame in range(3):
		await process_frame
	print("REBAS_SHOP_SMOKE: PASS")
	quit(0)
