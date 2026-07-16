extends SceneTree

const OUTPUT_DIR := "res://artifacts/kitchen_placement"
const RESOLUTIONS := [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1920, 1080)]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var packed := load("res://scenes/GrassWorld.tscn") as PackedScene
	if packed == null:
		quit(1)
		return
	var world := packed.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	world.call("_start_kitchen_equipment_placement", "sink")
	var position := _find_safe_position(world, world.get("_player").global_position)
	world.set("_kitchen_placing_position", position)
	world.set("_kitchen_placing_cursor_valid", true)
	world.call("_update_kitchen_equipment_placement_preview")
	world.call("_show_kitchen_equipment_placement_prompt")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))

	for resolution in RESOLUTIONS:
		root.size = resolution
		await _wait_for_render_frames(4)
		world.call("_show_kitchen_equipment_placement_prompt")
		var path := "%s/kitchen_placement_%dx%d.png" % [OUTPUT_DIR, resolution.x, resolution.y]
		if root.get_texture().get_image().save_png(path) != OK:
			quit(2)
			return

	root.size = Vector2i(1280, 720)
	var camper := world.get("_camper") as Node3D
	world.set("_kitchen_placing_position", camper.global_position)
	world.set("_kitchen_placing_cursor_valid", true)
	world.call("_update_kitchen_equipment_placement_preview")
	world.call("_show_kitchen_equipment_placement_prompt")
	await _wait_for_render_frames(4)
	root.get_texture().get_image().save_png(OUTPUT_DIR + "/kitchen_placement_invalid_1280x720.png")

	world.call("_cancel_kitchen_equipment_placement")
	world.queue_free()
	await process_frame
	await process_frame
	print("KITCHEN_PLACEMENT_PREVIEW: PASS")
	quit(0)


func _find_safe_position(world: Node, origin: Vector3) -> Vector3:
	world.set("_kitchen_placing_cursor_valid", true)
	for radius in [2.5, 4.0, 6.0]:
		for index in range(16):
			var angle := TAU * float(index) / 16.0
			var position := origin + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
			position.y = float(world.call("_height_at", position.x, position.z))
			if bool(world.call("_is_kitchen_equipment_place_position_valid", position)):
				return position
	return world.call("_get_kitchen_equipment_player_front_position") as Vector3


func _wait_for_render_frames(count: int) -> void:
	for _frame in range(count):
		await process_frame
