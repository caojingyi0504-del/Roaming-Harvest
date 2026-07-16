extends SceneTree

const OUTPUT_DIR := "res://artifacts"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var manager := root.get_node_or_null("FlowerGardenManager")
	var packed := load("res://scenes/GrassWorld.tscn") as PackedScene
	if manager == null or packed == null:
		quit(1)
		return
	var original_unlocked := bool(manager.get("unlocked"))
	manager.set("unlocked", true)
	var world := packed.instantiate()
	root.add_child(world)
	print("FLOWER_GARDEN_PREVIEW: base world")
	await process_frame
	await process_frame
	world.call("_build_chapter_one_scene")
	print("FLOWER_GARDEN_PREVIEW: chapter built")
	await process_frame
	await process_frame
	var controller = world.get("_flower_garden_controller")
	var player := world.get("_player") as Node3D
	if controller == null or player == null:
		manager.set("unlocked", original_unlocked)
		quit(2)
		return
	var gate := Vector3(-132.0, 0.0, -132.0)
	gate.y = float(world.call("_height_at", gate.x, gate.z))
	player.global_position = gate
	controller.call("enter_garden", "preview")
	await create_timer(1.15).timeout
	if not bool(controller.call("is_inside_garden")) or controller.get("garden_scene_instance") == null:
		manager.set("unlocked", original_unlocked)
		quit(3)
		return
	print("FLOWER_GARDEN_PREVIEW: camera placed")
	for _frame in range(3):
		await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var world_image := root.get_texture().get_image()
	print("FLOWER_GARDEN_PREVIEW: world captured")
	world_image.save_png(OUTPUT_DIR + "/flower_garden_world_preview_v2.png")
	controller.call("open_panel", "plots")
	for _frame in range(2):
		await process_frame
	var panel_image := root.get_texture().get_image()
	print("FLOWER_GARDEN_PREVIEW: panel captured")
	panel_image.save_png(OUTPUT_DIR + "/flower_garden_ui_preview_v2.png")
	root.size = Vector2i(1024, 576)
	for _frame in range(3):
		await process_frame
	root.get_texture().get_image().save_png(OUTPUT_DIR + "/flower_garden_ui_1024x576_v2.png")
	root.size = Vector2i(1920, 1080)
	for _frame in range(3):
		await process_frame
	root.get_texture().get_image().save_png(OUTPUT_DIR + "/flower_garden_ui_1920x1080_v2.png")
	root.size = Vector2i(1280, 720)
	for _frame in range(3):
		await process_frame
	controller.call("open_panel", "seeds")
	for _frame in range(2):
		await process_frame
	root.get_texture().get_image().save_png(OUTPUT_DIR + "/flower_garden_seeds_preview_v2.png")
	controller.call("open_panel", "gifts")
	for _frame in range(2):
		await process_frame
	root.get_texture().get_image().save_png(OUTPUT_DIR + "/flower_garden_gifts_preview_v2.png")
	controller.call("close_panel")
	manager.set("unlocked", original_unlocked)
	world.queue_free()
	await process_frame
	await process_frame
	print("FLOWER_GARDEN_PREVIEW: PASS")
	quit(0)
