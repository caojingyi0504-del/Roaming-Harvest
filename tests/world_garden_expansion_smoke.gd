extends SceneTree

const BusinessDiscoveryCatalog = preload("res://scripts/business_discovery_catalog.gd")
const LocalEventCatalog = preload("res://scripts/local_event_catalog.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/GrassWorld.tscn") as PackedScene
	assert(packed != null, "WORLD_GARDEN_EXPANSION_SMOKE: GrassWorld failed to load")
	var world := packed.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	world.call("_build_chapter_one_scene")
	await process_frame
	await process_frame

	var constants := (world.get_script() as Script).get_script_constant_map()
	assert(float(constants.get("TERRAIN_SIZE", 0.0)) == 400.0, "world terrain is not 400m wide")
	assert(int(constants.get("TERRAIN_STEPS", 0)) >= 160, "expanded terrain grid is too coarse")
	assert(float(constants.get("CAMPER_DRIVE_FIELD_LIMIT", 0.0)) >= 190.0, "camper world bounds were not expanded")
	assert((world.get("_player") as Node).get("field_limit") >= 190.0, "player cannot walk around remote destinations")
	assert(world.get_node_or_null("WorldRoadNetwork") != null, "expanded road network was not created")

	var expected_mainline := {
		2: Vector2(85.0, -68.0), 3: Vector2(-75.0, -95.0),
		4: Vector2(-150.0, 25.0), 5: Vector2(20.0, 155.0),
	}
	var start := Vector2(15.8, 8.8)
	for level_id in expected_mainline.keys():
		var actual: Vector2 = BusinessDiscoveryCatalog.get_site(level_id).get("position", Vector2.ZERO)
		assert(actual == expected_mainline[level_id], "mainline destination moved to an unexpected position: %d" % level_id)
		var drive_seconds := start.distance_to(actual) / 7.0
		assert(drive_seconds >= 12.0 and drive_seconds <= 25.5, "mainline drive time is outside the 15-25s target: %d %.2fs" % [level_id, drive_seconds])

	var garden_drive_seconds := start.distance_to(Vector2(-150.0, -150.0)) / 7.0
	assert(garden_drive_seconds >= 32.0 and garden_drive_seconds <= 35.5, "garden parking drive time is outside target: %.2fs" % garden_drive_seconds)
	var expected_local := {
		LocalEventCatalog.RABBIT_PARTY: Vector2(145.0, -130.0),
		LocalEventCatalog.BIRD_MARKET: Vector2(145.0, 75.0),
		LocalEventCatalog.FOREST_MARKET: Vector2(-145.0, -85.0),
		LocalEventCatalog.CAMPFIRE_STORY: Vector2(-105.0, 125.0),
	}
	for event_id in expected_local.keys():
		var actual: Vector2 = LocalEventCatalog.get_event(event_id).get("position", Vector2.ZERO)
		assert(actual == expected_local[event_id], "local event is not in its remote quadrant: %s" % event_id)
		assert(actual.length() >= 145.0, "local event remains too close to the village: %s" % event_id)

	var north_height := float(world.call("_height_at", 0.0, 180.0))
	var south_height := float(world.call("_height_at", 0.0, -180.0))
	var west_height := float(world.call("_macro_height_at", -180.0, 80.0))
	var east_height := float(world.call("_macro_height_at", 0.0, 80.0))
	assert(north_height - south_height >= 11.0, "north highland and south valley lack meaningful elevation")
	assert(west_height - east_height >= 1.5, "west ridge is not visible in the height field")

	var routes: Array = constants.get("WORLD_ROAD_ROUTES", [])
	assert(routes.size() >= 7, "not all remote destinations are connected by roads")
	var max_road_slope := 0.0
	var max_road_slope_point := Vector2.ZERO
	for raw_route in routes:
		for segment_index in range(raw_route.size() - 1):
			var a: Vector2 = raw_route[segment_index]
			var b: Vector2 = raw_route[segment_index + 1]
			var length := a.distance_to(b)
			var samples := maxi(int(ceil(length / 2.0)), 1)
			var previous_height := float(world.call("_height_at", a.x, a.y))
			for sample_index in range(1, samples + 1):
				var point := a.lerp(b, float(sample_index) / float(samples))
				var height := float(world.call("_height_at", point.x, point.y))
				var horizontal_step := length / float(samples)
				var slope := absf(height - previous_height) / horizontal_step
				if slope > max_road_slope:
					max_road_slope = slope
					max_road_slope_point = point
				previous_height = height
	assert(max_road_slope <= 0.28, "road slope is too steep near %s: %.3f" % [max_road_slope_point, max_road_slope])

	world.queue_free()
	await process_frame
	await process_frame
	print("WORLD_GARDEN_EXPANSION_SMOKE: PASS north=%.2f south=%.2f garden_drive=%.2fs max_slope=%.3f" % [north_height, south_height, garden_drive_seconds, max_road_slope])
	quit(0)
