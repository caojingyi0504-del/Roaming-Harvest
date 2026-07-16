extends SceneTree

const TIMEOUT_MSEC := 30000


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var packed := load("res://scenes/Intro.tscn") as PackedScene
	assert(packed != null, "STARTUP_TRANSITION_SMOKE: Intro failed to load")
	var intro := packed.instantiate() as Control
	assert(intro != null, "STARTUP_TRANSITION_SMOKE: Intro failed to instantiate")
	root.add_child(intro)
	current_scene = intro
	await process_frame
	var time_manager := root.get_node_or_null("TimeManager")
	assert(time_manager != null and bool(time_manager.get("paused")), "STARTUP_TRANSITION_SMOKE: game time was not frozen during Intro")
	var initial_time := time_manager.call("get_time_snapshot") as Dictionary

	intro.call("_request_finish_intro")
	await process_frame
	assert(bool(intro.get("_transition_requested")), "STARTUP_TRANSITION_SMOKE: skip did not request transition")
	assert((intro.get_node("TransitionOverlay") as Control).visible, "STARTUP_TRANSITION_SMOKE: loading overlay did not appear after immediate skip")
	for resolution in [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = resolution
		await process_frame
		var center_rect := (intro.get_node("TransitionOverlay/Center") as Control).get_global_rect()
		assert(center_rect.position.x >= 0.0 and center_rect.position.y >= 0.0, "STARTUP_TRANSITION_SMOKE: loading panel starts outside %s" % resolution)
		assert(center_rect.end.x <= float(resolution.x) and center_rect.end.y <= float(resolution.y), "STARTUP_TRANSITION_SMOKE: loading panel overflows %s" % resolution)
	root.size = Vector2i(1280, 720)

	var last_progress := 0.0
	var started := Time.get_ticks_msec()
	while current_scene == intro:
		assert(is_instance_valid(intro), "STARTUP_TRANSITION_SMOKE: Intro was freed before world activation")
		var progress := float(intro.get("_displayed_progress"))
		assert(progress + 0.0001 >= last_progress, "STARTUP_TRANSITION_SMOKE: displayed progress moved backwards")
		last_progress = progress
		if Time.get_ticks_msec() - started > TIMEOUT_MSEC:
			push_error("STARTUP_TRANSITION_SMOKE: timed out waiting for staged world")
			quit(2)
			return
		await process_frame

	var world := current_scene as Node3D
	assert(world != null and world.name == "GrassWorld", "STARTUP_TRANSITION_SMOKE: current scene was not switched to GrassWorld")
	assert(bool(world.call("_is_staged_startup_complete")), "STARTUP_TRANSITION_SMOKE: world activated before startup completed")
	assert(world.visible, "STARTUP_TRANSITION_SMOKE: activated world is hidden")
	assert(world.process_mode != Node.PROCESS_MODE_DISABLED, "STARTUP_TRANSITION_SMOKE: activated world is still disabled")
	assert(world.get("_player") != null, "STARTUP_TRANSITION_SMOKE: player missing after staged startup")
	assert(world.get("_camera") != null, "STARTUP_TRANSITION_SMOKE: camera missing after staged startup")
	assert(not bool(time_manager.get("paused")), "STARTUP_TRANSITION_SMOKE: game time was not restored after activation")
	assert((time_manager.call("get_time_snapshot") as Dictionary) == initial_time, "STARTUP_TRANSITION_SMOKE: game time advanced while loading")
	var grass := world.get("_grass_multimesh") as MultiMesh
	assert(grass != null and grass.instance_count > 0, "STARTUP_TRANSITION_SMOKE: grass field missing after staged startup")
	var audio_manager := root.get_node_or_null("AudioManager")
	assert(audio_manager != null and bool(audio_manager.get("_world_music_requested")), "STARTUP_TRANSITION_SMOKE: world music was not activated")

	var immediate_skip_elapsed := Time.get_ticks_msec() - started
	await create_timer(0.45).timeout
	current_scene = null
	world.queue_free()
	await process_frame
	await process_frame

	var natural_intro := packed.instantiate() as Control
	assert(natural_intro != null, "STARTUP_TRANSITION_SMOKE: second Intro failed to instantiate")
	root.add_child(natural_intro)
	current_scene = natural_intro
	await process_frame
	var natural_started := Time.get_ticks_msec()
	while not bool(natural_intro.get("_hidden_world_ready")):
		assert(not bool(natural_intro.get("_transition_requested")), "STARTUP_TRANSITION_SMOKE: natural intro ended before hidden world was ready")
		assert(not (natural_intro.get_node("TransitionOverlay") as Control).visible, "STARTUP_TRANSITION_SMOKE: loading overlay appeared during normal playback")
		if Time.get_ticks_msec() - natural_started > TIMEOUT_MSEC:
			push_error("STARTUP_TRANSITION_SMOKE: timed out prebuilding during natural intro")
			quit(3)
			return
		await process_frame

	var natural_finish_started := Time.get_ticks_msec()
	natural_intro.set("_elapsed", float(natural_intro.get("frame_count")) / float(natural_intro.get("frame_rate")))
	await process_frame
	assert(current_scene != natural_intro, "STARTUP_TRANSITION_SMOKE: ready world did not activate at natural animation end")
	assert(Time.get_ticks_msec() - natural_finish_started < 500, "STARTUP_TRANSITION_SMOKE: natural animation retained a visible post-animation wait")
	assert(not (natural_intro.get_node("TransitionOverlay") as Control).visible, "STARTUP_TRANSITION_SMOKE: ready natural transition flashed the loading overlay")
	var natural_world := current_scene as Node3D
	assert(natural_world != null and bool(natural_world.call("_is_staged_startup_complete")), "STARTUP_TRANSITION_SMOKE: natural transition activated an incomplete world")

	var natural_prebuild_elapsed := Time.get_ticks_msec() - natural_started
	print("STARTUP_TRANSITION_SMOKE: PASS immediate_skip=%dms natural_prebuild=%dms grass=%d" % [immediate_skip_elapsed, natural_prebuild_elapsed, grass.instance_count])
	await create_timer(0.45).timeout
	current_scene = null
	natural_world.queue_free()
	await process_frame
	await process_frame
	quit(0)
