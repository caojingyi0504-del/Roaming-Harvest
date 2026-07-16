extends SceneTree

const OUTPUT_DIR := "res://artifacts/night_sky"
const PREVIEW_TIMES := [6, 12, 18, 22]
const NIGHT_RESOLUTIONS := [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1920, 1080)]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var time_manager := root.get_node_or_null("TimeManager")
	var packed := load("res://scenes/GrassWorld.tscn") as PackedScene
	if time_manager == null or packed == null:
		push_error("NIGHT_SKY_PREVIEW: dependencies missing")
		quit(1)
		return
	var original_time := time_manager.call("get_time_snapshot") as Dictionary
	var world := packed.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	world.set("_orbit", Vector2(0.0, 0.04))
	world.set("_zoom", 15.0)
	world.call("_apply_camera")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))

	root.size = Vector2i(1280, 720)
	for hour in PREVIEW_TIMES:
		time_manager.call("set_time", hour, 0)
		world.call("_update_day_night", 0.0)
		await _wait_for_render_frames(4)
		var path := "%s/night_sky_%02d00_1280x720.png" % [OUTPUT_DIR, hour]
		if root.get_texture().get_image().save_png(path) != OK:
			push_error("NIGHT_SKY_PREVIEW: failed to save %s" % path)
			quit(2)
			return

	time_manager.call("set_time", 22, 0)
	world.call("_update_day_night", 0.0)
	for resolution in NIGHT_RESOLUTIONS:
		root.size = resolution
		await _wait_for_render_frames(4)
		var path := "%s/night_sky_2200_%dx%d.png" % [OUTPUT_DIR, resolution.x, resolution.y]
		if root.get_texture().get_image().save_png(path) != OK:
			push_error("NIGHT_SKY_PREVIEW: failed to save %s" % path)
			quit(3)
			return

	time_manager.call("apply_time_snapshot", original_time)
	world.queue_free()
	await process_frame
	await process_frame
	print("NIGHT_SKY_PREVIEW: PASS")
	quit(0)


func _wait_for_render_frames(count: int) -> void:
	for _frame in range(count):
		await process_frame
