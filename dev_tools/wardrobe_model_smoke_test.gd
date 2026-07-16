extends Node

const PlayerScene = preload("res://scenes/Player.tscn")
const WardrobeCatalog = preload("res://scripts/wardrobe_catalog.gd")


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var expected_available := ["olive_gardener", "terracotta_cook", "mist_lakeside"]
	for outfit_id in expected_available:
		assert(WardrobeCatalog.model_is_available(outfit_id), "Supplied model is not importable: %s" % outfit_id)
		var outfit := WardrobeCatalog.get_outfit(outfit_id)
		var scene := load(str(outfit.get("model_path", ""))) as PackedScene
		assert(scene != null, "Supplied model did not load as PackedScene: %s" % outfit_id)
		var instance := scene.instantiate() as Node3D
		assert(instance != null, "Supplied model did not instantiate: %s" % outfit_id)
		add_child(instance)
		await get_tree().process_frame
		instance.queue_free()

	assert(not WardrobeCatalog.model_is_available("old_road_traveler"), "Old-road outfit should remain unavailable until its GLB is supplied")
	var player := PlayerScene.instantiate() as CharacterBody3D
	add_child(player)
	await get_tree().process_frame
	var visual_root := player.get_node("VisualRoot") as Node3D
	assert(visual_root.get_child_count() == 1, "Player should begin with one visual model")
	for outfit_id in expected_available:
		var outfit := WardrobeCatalog.get_outfit(outfit_id)
		assert(bool(player.call("apply_outfit", outfit_id, str(outfit.get("model_path", "")))), "Player failed to apply outfit: %s" % outfit_id)
		assert(visual_root.get_child_count() == 1, "Player retained multiple visual models after switching: %s" % outfit_id)
		await get_tree().process_frame

	print("WARDROBE_MODEL_SMOKE_PASS available=3 missing=old_road_traveler")
	player.queue_free()
	await get_tree().process_frame
	get_tree().quit()
