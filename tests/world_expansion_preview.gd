extends SceneTree

const OUTPUT_DIR := "res://artifacts/world_expansion"


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
	world.call("_build_chapter_one_scene")
	await process_frame
	await process_frame
	var time_manager := root.get_node_or_null("TimeManager")
	if time_manager != null:
		time_manager.call("set_time", 12, 0)
		world.call("_update_day_night", 0.0)
	var camera := world.get("_camera") as Camera3D
	if camera == null:
		quit(2)
		return
	world.set_process(false)
	var environment := world.get("_world_environment") as Environment
	if environment != null:
		environment.fog_enabled = false
	var hud := world.get("_hud_root") as Control
	if hud != null:
		hud.visible = false
	for pattern in ["*Cloud*", "*Sun*", "*Moon*", "*PetalFall*"]:
		for visual in world.find_children(pattern, "", true, false):
			if visual is Node3D:
				(visual as Node3D).visible = false
	for high_mesh in world.find_children("*", "MeshInstance3D", true, false):
		var mesh_node := high_mesh as MeshInstance3D
		var bounds := mesh_node.get_aabb()
		if mesh_node.global_position.y > 10.0 and maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z)) > 9.0:
			mesh_node.visible = false
	camera.far = 900.0
	camera.fov = 49.0
	camera.global_position = Vector3(0.0, 245.0, 245.0)
	camera.look_at(Vector3(0.0, 2.5, 0.0), Vector3.UP)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for _frame in range(6):
		await process_frame
	var image := root.get_texture().get_image()
	if image.save_png(OUTPUT_DIR + "/world_overview_1280x720.png") != OK:
		quit(3)
		return
	world.queue_free()
	await process_frame
	await process_frame
	print("WORLD_EXPANSION_PREVIEW: PASS")
	quit(0)
