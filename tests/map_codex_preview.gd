extends Node

const OUTPUT_DIR := "res://artifacts/map_codex"


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
	var crop_ids := world.call("_codex_known_ids", "crop") as Array
	var cooking_ids := world.call("_codex_known_ids", "cooking") as Array
	world.set("_codex_discovered_crops", {str(crop_ids[0]): true, str(crop_ids[1]): true, str(crop_ids[2]): true, str(crop_ids[3]): true})
	world.set("_codex_revealed_crops", {str(crop_ids[0]): true, str(crop_ids[1]): true})
	world.set("_codex_discovered_cooking", {str(cooking_ids[0]): true, str(cooking_ids[1]): true, str(cooking_ids[2]): true})
	world.set("_codex_revealed_cooking", {str(cooking_ids[0]): true, str(cooking_ids[1]): true})
	world.set("_local_event_atlas", {
		"rabbit_lantern_party": {"best_stars": 3, "reward_revealed": true},
		"migratory_bird_market": {"best_stars": 2, "reward_revealed": false},
	})
	world.set("_researched_special_recipes", {"lantern_strawberry_jam": true})
	world.call("_open_map_popup")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for viewport_size in [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		window.size = viewport_size
		for _frame in range(4):
			await get_tree().process_frame
		window.get_texture().get_image().save_png("%s/map_home_%dx%d.png" % [OUTPUT_DIR, viewport_size.x, viewport_size.y])
		world.call("_show_map_codex_detail_popup", "crop")
		world.call("_layout_map_codex_popup", true)
		for _frame in range(5):
			await get_tree().process_frame
		window.get_texture().get_image().save_png("%s/codex_crop_%dx%d.png" % [OUTPUT_DIR, viewport_size.x, viewport_size.y])
		world.call("_hide_map_codex_detail_popup")
	window.size = Vector2i(1280, 720)
	world.call("_layout_map_shell_controls")
	world.call("_on_map_page_right_pressed")
	for _frame in range(3):
		await get_tree().process_frame
	window.get_texture().get_image().save_png(OUTPUT_DIR + "/map_locked_feedback_1280x720.png")
	world.call("_show_map_codex_detail_popup", "cooking")
	for _frame in range(5):
		await get_tree().process_frame
	window.get_texture().get_image().save_png(OUTPUT_DIR + "/codex_cooking_1280x720.png")
	world.call("_set_map_codex_tab", "flavor")
	for _frame in range(6):
		await get_tree().process_frame
	window.get_texture().get_image().save_png(OUTPUT_DIR + "/codex_flavor_1280x720.png")
	world.queue_free()
	for _frame in range(5):
		await get_tree().process_frame
	packed = null
	await get_tree().process_frame
	print("MAP_CODEX_PREVIEW: PASS")
	get_tree().quit(0)
