extends SceneTree

var _original_time: Dictionary = {}
var _time_manager: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_time_manager = root.get_node_or_null("TimeManager")
	if _time_manager == null:
		_fail("TimeManager autoload missing", 10)
		return
	_original_time = _time_manager.call("get_time_snapshot") as Dictionary
	var packed := load("res://scenes/GrassWorld.tscn") as PackedScene
	if packed == null:
		_fail("failed to load GrassWorld", 1)
		return
	var world := packed.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame

	var stars_root := world.get("_night_stars_root") as Node3D
	var moon := world.get("_visible_moon_mesh") as MeshInstance3D
	var material := world.get("_night_star_material") as ShaderMaterial
	if stars_root == null or moon == null or material == null:
		_fail("night sky nodes or material missing", 2)
		return
	var star_field := stars_root.get_node_or_null("StarField") as MultiMeshInstance3D
	if star_field == null or star_field.multimesh == null:
		_fail("StarField MultiMesh missing", 3)
		return
	if star_field.multimesh.instance_count != 128 or not star_field.multimesh.use_custom_data:
		_fail("star instance configuration is incorrect", 4)
		return
	if moon.get_parent() != stars_root or moon.name != "VisibleMoon":
		_fail("existing moon node changed or moved", 6)
		return

	_time_manager.call("set_time", 12, 0)
	world.call("_update_day_night", 0.0)
	if float(material.get_shader_parameter("night_visibility")) > 0.001 or stars_root.visible:
		_fail("stars remain visible at noon", 7)
		return

	for transition_hour in [6, 18]:
		_time_manager.call("set_time", transition_hour, 0)
		world.call("_update_day_night", 0.0)
		var transition_visibility := float(material.get_shader_parameter("night_visibility"))
		if transition_visibility <= 0.0 or transition_visibility >= 1.0:
			_fail("stars do not fade smoothly at %02d:00" % transition_hour, 8)
			return

	_time_manager.call("set_time", 22, 0)
	world.call("_update_day_night", 0.0)
	if float(material.get_shader_parameter("night_visibility")) < 0.999 or not stars_root.visible:
		_fail("stars are not fully visible at 22:00", 9)
		return

	world.call("_build_chapter_one_scene")
	await process_frame
	await process_frame
	stars_root = world.get("_night_stars_root") as Node3D
	material = world.get("_night_star_material") as ShaderMaterial
	star_field = stars_root.get_node_or_null("StarField") as MultiMeshInstance3D if stars_root != null else null
	moon = world.get("_visible_moon_mesh") as MeshInstance3D
	if stars_root == null or material == null or star_field == null or moon == null:
		_fail("night sky was not rebuilt for chapter one", 11)
		return
	world.call("_update_day_night", 0.0)
	if star_field.multimesh.instance_count != 128 or float(material.get_shader_parameter("night_visibility")) < 0.999:
		_fail("chapter one star field configuration is incorrect", 12)
		return

	_time_manager.call("apply_time_snapshot", _original_time)
	world.queue_free()
	await process_frame
	await process_frame
	print("NIGHT_SKY_SMOKE: PASS")
	quit(0)


func _fail(message: String, code: int) -> void:
	if _time_manager != null and not _original_time.is_empty():
		_time_manager.call("apply_time_snapshot", _original_time)
	push_error("NIGHT_SKY_SMOKE: %s" % message)
	quit(code)
