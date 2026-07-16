extends Node

const MUSIC_START_DB := -40.0
const MUSIC_WORLD_DB := -13.0
const MUSIC_BUSINESS_DB := -17.0
const MUSIC_FADE_IN_SECONDS := 1.5
const MUSIC_FADE_OUT_SECONDS := 1.2
const MUSIC_BUSINESS_DUCK_SECONDS := 0.35
const MUSIC_BUSINESS_RESTORE_SECONDS := 0.6
const SFX_POOL_SIZE := 12

const STREAM_PATHS := {
	"bgm_world": "res://audio/v2/bgm_loop_core_v2.wav",
	"ui_hover": "res://audio/v2/ui_hover_v2.wav",
	"ui_press": "res://audio/v2/ui_press_v2.wav",
	"ui_back": "res://audio/v2/ui_back_v2.wav",
	"ui_locked": "res://audio/v2/ui_locked_v2.wav",
	"dialogue_type": "res://audio/v2/ui_hover_v2.wav",
	"dialogue_advance": "res://audio/v2/ui_press_v2.wav",
	"farm_hoe_swing": "res://audio/v2/farm_hoe_swing_v2.wav",
	"farm_soil_impact": "res://audio/v2/farm_soil_impact_v2.wav",
	"farm_seed_plant": "res://audio/v2/farm_seed_plant_v2.wav",
	"farm_water_pour": "res://audio/v2/farm_water_pour_v2.wav",
	"farm_scythe_swing": "res://audio/v2/farm_scythe_swing_v2.wav",
	"farm_grass_cut": "res://audio/v2/farm_grass_cut_v2.wav",
	"farm_harvest": "res://audio/v2/farm_harvest_v2.wav",
	"food_chest_pickup": "res://audio/v2/food_chest_pickup_v2.wav",
	"food_chest_place": "res://audio/v2/food_chest_place_v2.wav",
	"cook_wash": "res://audio/v2/cook_wash_v2.wav",
	"cook_chop": "res://audio/v2/cook_chop_sequence_v2.wav",
	"cook_pot_place": "res://audio/v2/cook_pot_place_v2.wav",
	"cook_boil_loop": "res://audio/v2/cook_boil_loop_v2.wav",
	"cook_grill_place": "res://audio/v2/cook_grill_place_v2.wav",
	"cook_grill_loop": "res://audio/v2/cook_grill_sizzle_loop_v2.wav",
	"cook_ready": "res://audio/v2/cook_ready_v2.wav",
	"cook_burnt": "res://audio/v2/cook_burnt_v2.wav",
	"order_new": "res://audio/v2/order_new_v2.wav",
	"order_warning": "res://audio/v2/order_warning_v2.wav",
	"order_complete": "res://audio/v2/order_complete_v2.wav",
	"reward_small": "res://audio/v2/reward_small_v2.wav",
	"reward_stage": "res://audio/v2/reward_stage_gift_v2.wav",
}

const LOOP_VOLUME_DB := {
	"cook_boil_loop": -3.0,
	"cook_grill_loop": -3.0,
}

const BACK_BUTTON_KEYWORDS := [
	"返回", "关闭", "取消", "退出", "稍后", "以后再说", "暂不", "离开",
	"Back", "Close", "Cancel", "Exit",
]

var _streams: Dictionary = {}
var _music_player: AudioStreamPlayer
var _music_tween: Tween
var _sfx_pool: Array[AudioStreamPlayer] = []
var _next_sfx_player := 0
var _kitchen_loop_players: Dictionary = {}
var _business_mode := false
var _world_music_requested := false
var _last_hover_tick := -1000


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_streams()
	_create_players()
	get_tree().node_added.connect(_on_tree_node_added)
	call_deferred("_register_existing_buttons")


func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	var hovered := get_viewport().gui_get_hovered_control()
	var button := _find_parent_button(hovered)
	if button != null and button.disabled and button.is_visible_in_tree():
		play_sfx("ui_locked")


func enter_intro_mode() -> void:
	_world_music_requested = false
	_business_mode = false
	_kill_music_tween()
	if _music_player != null:
		_music_player.stop()
		_music_player.volume_db = MUSIC_START_DB
	stop_all_kitchen_loops()
	stop_all_sfx()


func start_world_music() -> void:
	_world_music_requested = true
	if _music_player == null or not _streams.has("bgm_world"):
		return
	if not _music_player.playing:
		_music_player.stream = _make_loop_stream(_streams["bgm_world"] as AudioStream)
		_music_player.volume_db = MUSIC_START_DB
		_music_player.play()
	_tween_music_to(_target_music_db(), MUSIC_FADE_IN_SECONDS)


func stop_world_music(fade_seconds: float = MUSIC_FADE_OUT_SECONDS) -> void:
	_world_music_requested = false
	if _music_player == null or not _music_player.playing:
		return
	_kill_music_tween()
	_music_tween = create_tween()
	_music_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_music_tween.tween_property(_music_player, "volume_db", MUSIC_START_DB, maxf(fade_seconds, 0.0))
	_music_tween.tween_callback(_music_player.stop)


func set_business_mode(active: bool) -> void:
	_business_mode = active
	if not _world_music_requested or _music_player == null or not _music_player.playing:
		return
	var duration := MUSIC_BUSINESS_DUCK_SECONDS if active else MUSIC_BUSINESS_RESTORE_SECONDS
	_tween_music_to(_target_music_db(), duration)


func play_sfx(sfx_id: String, volume_offset_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	var stream := _streams.get(sfx_id) as AudioStream
	if stream == null or _sfx_pool.is_empty():
		return
	var player := _next_available_sfx_player()
	player.stop()
	player.stream = stream
	player.volume_db = volume_offset_db
	player.pitch_scale = clampf(pitch_scale, 0.5, 2.0)
	player.play()


func stop_all_sfx() -> void:
	for player in _sfx_pool:
		if player != null:
			player.stop()


func start_kitchen_loop(instance_id: String, sfx_id: String) -> void:
	if instance_id == "":
		return
	var stream := _streams.get(sfx_id) as AudioStream
	if stream == null:
		return
	stop_kitchen_loop(instance_id)
	var player := AudioStreamPlayer.new()
	player.name = "KitchenLoop_%s" % instance_id.validate_node_name()
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.stream = _make_loop_stream(stream)
	player.volume_db = float(LOOP_VOLUME_DB.get(sfx_id, -3.0))
	add_child(player)
	_kitchen_loop_players[instance_id] = player
	player.play()


func stop_kitchen_loop(instance_id: String) -> void:
	var player := _kitchen_loop_players.get(instance_id) as AudioStreamPlayer
	if player != null and is_instance_valid(player):
		player.stop()
		player.queue_free()
	_kitchen_loop_players.erase(instance_id)


func stop_all_kitchen_loops() -> void:
	for raw_id in _kitchen_loop_players.keys():
		var instance_id := str(raw_id)
		var player := _kitchen_loop_players.get(instance_id) as AudioStreamPlayer
		if player != null and is_instance_valid(player):
			player.stop()
			player.queue_free()
	_kitchen_loop_players.clear()


func set_button_audio_role(button: BaseButton, role: String) -> void:
	if button == null:
		return
	button.set_meta("audio_role", role)
	_register_button(button)


func _load_streams() -> void:
	_streams.clear()
	for raw_id in STREAM_PATHS.keys():
		var sfx_id := str(raw_id)
		var stream := load(str(STREAM_PATHS[sfx_id])) as AudioStream
		if stream != null:
			_streams[sfx_id] = stream
		else:
			push_warning("AudioManager could not load %s" % str(STREAM_PATHS[sfx_id]))


func _create_players() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "WorldMusic"
	_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_music_player.volume_db = MUSIC_START_DB
	add_child(_music_player)
	for index in range(SFX_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "Sfx_%02d" % index
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		_sfx_pool.append(player)


func _make_loop_stream(stream: AudioStream) -> AudioStream:
	if stream == null:
		return null
	var result := stream.duplicate() as AudioStream
	if result is AudioStreamWAV:
		var wav := result as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = maxi(int(round(wav.get_length() * float(wav.mix_rate))), 1)
	elif result is AudioStreamOggVorbis:
		(result as AudioStreamOggVorbis).loop = true
	return result


func _target_music_db() -> float:
	return MUSIC_BUSINESS_DB if _business_mode else MUSIC_WORLD_DB


func _tween_music_to(target_db: float, duration: float) -> void:
	_kill_music_tween()
	_music_tween = create_tween()
	_music_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_music_tween.tween_property(_music_player, "volume_db", target_db, maxf(duration, 0.0))


func _kill_music_tween() -> void:
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()
	_music_tween = null


func _next_available_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_pool:
		if not player.playing:
			return player
	var player := _sfx_pool[_next_sfx_player]
	_next_sfx_player = (_next_sfx_player + 1) % _sfx_pool.size()
	return player


func _on_tree_node_added(node: Node) -> void:
	if node is BaseButton:
		call_deferred("_register_button", node)


func _register_existing_buttons() -> void:
	var root := get_tree().root
	if root == null:
		return
	_register_buttons_below(root)


func _register_buttons_below(node: Node) -> void:
	if node is BaseButton:
		_register_button(node as BaseButton)
	for child in node.get_children():
		_register_buttons_below(child)


func _register_button(button: BaseButton) -> void:
	if button == null or not is_instance_valid(button) or button.has_meta("audio_manager_registered"):
		return
	button.set_meta("audio_manager_registered", true)
	button.mouse_entered.connect(_on_button_mouse_entered.bind(button))
	button.pressed.connect(_on_button_pressed.bind(button))


func _on_button_mouse_entered(button: BaseButton) -> void:
	if button == null or not is_instance_valid(button) or button.disabled or not button.is_visible_in_tree():
		return
	if str(button.get_meta("audio_role", "")) == "silent":
		return
	var now := Time.get_ticks_msec()
	if now - _last_hover_tick < 45:
		return
	_last_hover_tick = now
	play_sfx("ui_hover")


func _on_button_pressed(button: BaseButton) -> void:
	if button == null or not is_instance_valid(button):
		return
	var role := str(button.get_meta("audio_role", ""))
	if role == "silent":
		return
	if role == "back" or (role == "" and _button_looks_like_back(button)):
		play_sfx("ui_back")
	else:
		play_sfx("ui_press")


func _button_looks_like_back(button: BaseButton) -> bool:
	var description := "%s %s" % [button.name, button.tooltip_text]
	if button is Button:
		description += " " + (button as Button).text
	for keyword in BACK_BUTTON_KEYWORDS:
		if description.contains(keyword):
			return true
	return false


func _find_parent_button(control: Control) -> BaseButton:
	var current: Node = control
	while current != null:
		if current is BaseButton:
			return current as BaseButton
		current = current.get_parent()
	return null
