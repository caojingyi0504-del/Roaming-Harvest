extends Node

const OUTPUT_DIR := "res://artifacts/rebas_shop"


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/GrassWorld.tscn") as PackedScene
	if packed == null:
		get_tree().quit(1)
		return
	var window := get_window()
	window.size = Vector2i(1280, 720)
	var world := packed.instantiate()
	add_child(world)
	await get_tree().process_frame
	await get_tree().process_frame
	world.call("_build_chapter_one_scene")
	for _frame in range(3):
		await get_tree().process_frame
	world.set("_chapter_one_active", true)
	world.set("_post_tutorial_grand_reward_claimed", true)
	world.set("_coins", 344)
	world.set("_stored_crop_counts", {
		"carrot:0": 4,
		"carrot:1": 2,
		"pea:0": 3,
		"eggplant:2": 1,
	})
	world.call("_update_post_tutorial_objective")
	world.call("_open_rebas_shop")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for viewport_size in [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		window.size = viewport_size
		for _frame in range(4):
			await get_tree().process_frame
		world.call("_layout_rebas_shop", true)
		await get_tree().process_frame
		window.get_texture().get_image().save_png("%s/rebas_shop_sell_%dx%d.png" % [OUTPUT_DIR, viewport_size.x, viewport_size.y])
	window.size = Vector2i(1280, 720)
	world.set("_shop_daily_key", str(world.call("_shop_day_key")))
	world.set("_shop_buy_stock", {"seed:carrot:0": 12})
	world.call("_set_shop_mode", "buy")
	for _frame in range(4):
		await get_tree().process_frame
	window.get_texture().get_image().save_png(OUTPUT_DIR + "/rebas_shop_buy_single_1280x720.png")
	world.set("_stored_crop_counts", {})
	world.call("_set_shop_mode", "sell")
	for _frame in range(4):
		await get_tree().process_frame
	window.get_texture().get_image().save_png(OUTPUT_DIR + "/rebas_shop_empty_1280x720.png")
	world.queue_free()
	await get_tree().process_frame
	print("REBAS_SHOP_PREVIEW: PASS")
	get_tree().quit(0)
