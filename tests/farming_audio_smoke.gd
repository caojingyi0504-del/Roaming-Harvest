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

const GARDEN_AUDIO_MIN_LENGTHS := {
	"bgm_garden": 47.9,
	"garden_creek": 15.9,
	"garden_bird": 3.1,
}


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
	for audio_id in GARDEN_AUDIO_MIN_LENGTHS.keys():
		assert(streams.has(audio_id), "Missing garden audio id: %s" % audio_id)
		var garden_stream := streams.get(audio_id) as AudioStream
		assert(garden_stream != null and garden_stream.get_length() >= float(GARDEN_AUDIO_MIN_LENGTHS[audio_id]), "Garden audio is missing or too short: %s" % audio_id)
	audio_manager.call("start_world_music")
	audio_manager.call("set_music_context", "garden", 0.05)
	await create_timer(0.12).timeout
	assert(str(audio_manager.call("get_music_context")) == "garden", "Garden music context was not selected")
	var active_music := audio_manager.get("_music_player") as AudioStreamPlayer
	var creek := audio_manager.get("_garden_creek_player") as AudioStreamPlayer
	assert(active_music != null and active_music.playing and str(active_music.get_meta("music_stream_id", "")) == "bgm_garden", "Garden BGM did not crossfade in")
	assert(creek != null and creek.playing, "Garden creek ambience did not start")
	audio_manager.call("set_music_context", "world", 0.05)
	await create_timer(0.12).timeout
	assert(str(audio_manager.call("get_music_context")) == "world", "World music context was not restored")
	assert(not creek.playing, "Garden creek ambience did not stop after leaving")
	audio_manager.call("stop_world_music", 0.0)

	var packed := load("res://scenes/GrassWorld.tscn") as PackedScene
	assert(packed != null, "GrassWorld scene failed to load")
	var world := packed.instantiate()
	root.add_child(world)
	await process_frame
	assert(world.has_method("_play_farm_soil_impact"), "Farming impact hook is missing")
	world.queue_free()
	print("Farming audio smoke test passed (%d SFX)." % FARM_SFX_IDS.size())
	quit(0)
