extends SceneTree

var _frames := 0
var _failed := false
var _world: Node


func _initialize() -> void:
	process_frame.connect(_on_process_frame)
	var packed := load("res://scenes/GrassWorld.tscn") as PackedScene
	if packed == null:
		_fail("GrassWorld scene could not be loaded")
		return
	_world = packed.instantiate()
	root.add_child(_world)
	current_scene = _world


func _on_process_frame() -> void:
	_frames += 1
	if _frames < 4 or _failed:
		return
	var tool := root.get_node_or_null("AcceptanceTool")
	if tool == null:
		_fail("AcceptanceTool autoload is missing")
		return
	tool.call("_sync_scene")
	var layer := tool.get("_layer") as CanvasLayer
	var launcher := tool.get("_launcher") as Button
	var panel := tool.get("_panel") as PanelContainer
	if layer == null or launcher == null or panel == null:
		_fail("AcceptanceTool UI was not created")
		return
	tool.call("_open_panel")
	if not bool(tool.get("_panel_open")) or not paused or not panel.visible:
		_fail("AcceptanceTool did not capture input when opened")
		return
	tool.call("_skip_basic_tutorial")
	if not bool(_world.get("_chapter_one_active")) or not bool(_world.get("_kitchen_intro_completed")):
		_fail("Tutorial skip did not create a coherent chapter-one state")
		return
	if not bool(tool.call("_set_seed_exact", "pea", 0, 12)) or int(_world.call("_get_seed_count", "pea", 0)) != 12:
		_fail("Seed quantity setter did not synchronize the world inventory")
		return
	tool.call("_set_food_exact", "pea", 0, 6)
	var stored: Dictionary = _world.get("_stored_crop_counts") as Dictionary
	if int(stored.get("pea:0", 0)) != 6:
		_fail("Food chest setter did not synchronize storage")
		return
	tool.set("_selected_level", 3)
	var star_spin := tool.get("_level_star_amount") as SpinBox
	star_spin.value = 2
	tool.call("_apply_level_stars")
	var stars: Dictionary = _world.get("_business_level_stars") as Dictionary
	if int(stars.get("1", 0)) < 1 or int(stars.get("2", 0)) < 1 or int(stars.get("3", 0)) != 2:
		_fail("Level jump did not establish prerequisite stars")
		return
	var feature_states: Dictionary = tool.get("_feature_states") as Dictionary
	feature_states["wind"] = 1
	tool.set("_feature_states", feature_states)
	tool.call("_apply_feature", "wind")
	if not bool(_world.get("_wind_chase_unlocked")) or bool(_world.get("_wind_chase_guide_seen")):
		_fail("Feature unseen state was not applied")
		return
	tool.call("_close_panel")
	if bool(tool.get("_panel_open")) or paused or panel.visible:
		_fail("AcceptanceTool did not restore input when closed")
		return
	print("ACCEPTANCE_TOOL_SMOKE_OK")
	quit(0)


func _fail(message: String) -> void:
	_failed = true
	push_error("ACCEPTANCE_TOOL_SMOKE_FAILED: %s" % message)
	quit(1)
