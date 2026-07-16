extends SceneTree

const EXPECTED_SFX := {
	"farm_water_pour": 1.0,
	"food_chest_pickup": 0.45,
	"food_chest_place": 0.55,
}


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error("FOOD_CHEST_AUDIO_SMOKE: %s" % message)
	quit(1)


func _run() -> void:
	await process_frame
	var audio_manager := root.get_node_or_null("AudioManager")
	if audio_manager == null:
		_fail("AudioManager autoload is missing")
		return
	var streams := audio_manager.get("_streams") as Dictionary
	for sfx_id in EXPECTED_SFX:
		if not streams.has(sfx_id):
			_fail("missing SFX id %s" % sfx_id)
			return
		var stream := streams.get(sfx_id) as AudioStream
		if stream == null or stream.get_length() < float(EXPECTED_SFX[sfx_id]):
			_fail("invalid or unexpectedly short stream %s" % sfx_id)
			return
		audio_manager.call("play_sfx", sfx_id, 0.0, 1.0)
	var world_source := FileAccess.get_file_as_string("res://scripts/grass_world.gd")
	if world_source.count('play_sfx("food_chest_pickup"') != 2:
		_fail("pickup sound must cover initial collection and placed-chest pickup")
		return
	if world_source.count('play_sfx("food_chest_place"') != 1:
		_fail("place sound must trigger once after successful placement")
		return
	print("Food chest and watering audio smoke test passed (%d SFX)." % EXPECTED_SFX.size())
	quit(0)
