extends SceneTree

const FARM_SFX_IDS := [
	"farm_hoe_swing",
	"farm_soil_impact",
	"farm_seed_plant",
	"farm_water_pour",
	"farm_scythe_swing",
	"farm_grass_cut",
	"farm_harvest",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var audio_manager := root.get_node_or_null("AudioManager")
	assert(audio_manager != null, "AudioManager autoload is missing")
	var streams := audio_manager.get("_streams") as Dictionary
	assert(streams != null, "AudioManager stream registry is unavailable")
	for sfx_id in FARM_SFX_IDS:
		assert(streams.has(sfx_id), "Missing farming SFX id: %s" % sfx_id)
		var stream := streams.get(sfx_id) as AudioStream
		assert(stream != null, "Farming SFX did not load: %s" % sfx_id)
		assert(stream.get_length() >= 0.35, "Farming SFX is unexpectedly short: %s" % sfx_id)
		audio_manager.call("play_sfx", sfx_id, 0.0, 1.0)

	var packed := load("res://scenes/GrassWorld.tscn") as PackedScene
	assert(packed != null, "GrassWorld scene failed to load")
	var world := packed.instantiate()
	root.add_child(world)
	await process_frame
	assert(world.has_method("_play_farm_soil_impact"), "Farming impact hook is missing")
	world.queue_free()
	print("Farming audio smoke test passed (%d SFX)." % FARM_SFX_IDS.size())
	quit(0)
