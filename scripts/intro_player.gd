extends Control

const FRAME_PATTERN := "res://movies/intro_frames/frame_%04d.jpg"
const NEXT_SCENE := "res://scenes/GrassWorld.tscn"
const MAX_CONCURRENT_LOADS := 2
const RESOURCE_PROGRESS_WEIGHT := 0.55
const WORLD_PROGRESS_WEIGHT := 0.45
const TRANSITION_FADE_SECONDS := 0.38
const WardrobeCatalog = preload("res://scripts/wardrobe_catalog.gd")

const STARTUP_RESOURCES: Array[Dictionary] = [
	{"path": NEXT_SCENE, "weight": 1.0, "required": true},
	{"path": "res://scenes/Player.tscn", "weight": 0.8, "required": false},
	{"path": "res://3d建模/房车3d建模/9074167cffdd2b26a03baf531b4fae76.glb", "weight": 1.7, "required": false},
	{"path": "res://3d建模/妈妈3d建模/95b973b63a8027c98172bc0efdb9bd68.glb", "weight": 1.5, "required": false},
	{"path": "res://3d建模/池塘/1a6db431228638d85c528889bcff7353.glb", "weight": 1.35, "required": false},
	{"path": "res://3d建模/树/2f5d6b66e5b0fbbf4c7b1bede79477f5.glb", "weight": 1.35, "required": false},
	{"path": "res://ui/hud_stamina_bar_v2.png", "weight": 0.1, "required": false},
	{"path": "res://ui/hud_personal_coin_bar_v2.png", "weight": 0.1, "required": false},
	{"path": "res://ui/hud_coop_coin_bar_v2.png", "weight": 0.1, "required": false},
	{"path": "res://ui/hud_popularity_bar_v2.png", "weight": 0.1, "required": false},
	{"path": "res://ui/day_clock_bar_v2.png", "weight": 0.08, "required": false},
	{"path": "res://ui/interaction_prompt_frame_v3.png", "weight": 0.08, "required": false},
	{"path": "res://ui/inventory_slot_v1.png", "weight": 0.08, "required": false},
]

@export var frame_count: int = 120
@export var frame_rate: float = 8.0

@onready var image: TextureRect = $Image
@onready var audio: AudioStreamPlayer = $Audio
@onready var transition_overlay: Control = $TransitionOverlay
@onready var loading_status: Label = $TransitionOverlay/Center/Status
@onready var loading_bar: ProgressBar = $TransitionOverlay/Center/Progress
@onready var loading_percent: Label = $TransitionOverlay/Center/Percent

var _elapsed := 0.0
var _current_frame := -1
var _transition_requested := false
var _transition_started := false
var _load_failed := false
var _load_failure_message := ""
var _load_manifest: Array[Dictionary] = []
var _pending_load_paths: Array[String] = []
var _active_loads: Dictionary = {}
var _loaded_resources: Dictionary = {}
var _resource_progress: Dictionary = {}
var _resource_weight_total := 1.0
var _world_build_progress := 0.0
var _world_build_stage := "准备世界"
var _displayed_progress := 0.0
var _hidden_world: Node3D
var _hidden_world_ready := false
var _time_manager: Node
var _time_manager_was_paused := false
var _time_pause_restored := false


func _ready() -> void:
	AudioManager.enter_intro_mode()
	_time_manager = get_node_or_null("/root/TimeManager")
	if _time_manager != null:
		_time_manager_was_paused = bool(_time_manager.get("paused"))
		_time_manager.set("paused", true)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_filter = Control.MOUSE_FILTER_STOP
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_overlay.visible = false
	audio.play()
	_show_frame(1)
	_begin_preload()


func _exit_tree() -> void:
	_restore_time_pause()


func _process(delta: float) -> void:
	_pump_preload_queue()
	_update_displayed_progress(delta)
	if _transition_requested:
		_update_loading_overlay()
		_try_begin_world_transition()
		return
	_elapsed += delta
	var frame := mini(int(_elapsed * frame_rate) + 1, frame_count)
	_show_frame(frame)
	if _elapsed >= float(frame_count) / frame_rate:
		_request_finish_intro()


func _input(event: InputEvent) -> void:
	if _transition_started:
		return
	var pressed := false
	if event is InputEventKey:
		var key_event := event as InputEventKey
		pressed = key_event.pressed and not key_event.echo
	elif event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		pressed = mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventScreenTouch:
		pressed = (event as InputEventScreenTouch).pressed
	if not pressed:
		return
	if _transition_requested and _load_failed:
		_begin_preload()
	else:
		_request_finish_intro()


func _show_frame(frame: int) -> void:
	if frame == _current_frame:
		return
	_current_frame = frame
	var texture := load(FRAME_PATTERN % frame) as Texture2D
	if texture != null:
		image.texture = texture


func _request_finish_intro() -> void:
	if _transition_requested:
		return
	_transition_requested = true
	audio.stop()
	_show_frame(frame_count)
	transition_overlay.visible = not _hidden_world_ready
	_update_loading_overlay()
	_try_begin_world_transition()


func _begin_preload() -> void:
	_load_failed = false
	_load_failure_message = ""
	_pending_load_paths.clear()
	_active_loads.clear()
	_loaded_resources.clear()
	_resource_progress.clear()
	_load_manifest = STARTUP_RESOURCES.duplicate(true)
	_append_equipped_outfit_to_manifest()
	_resource_weight_total = 0.0
	for entry in _load_manifest:
		var path := str(entry.get("path", ""))
		if path == "" or _resource_progress.has(path):
			continue
		_pending_load_paths.append(path)
		_resource_progress[path] = 0.0
		_resource_weight_total += float(entry.get("weight", 1.0))
	_resource_weight_total = maxf(_resource_weight_total, 0.001)
	_world_build_progress = 0.0
	_world_build_stage = "读取世界资源"
	_displayed_progress = 0.0
	if _transition_requested:
		transition_overlay.visible = true
	_pump_preload_queue()


func _append_equipped_outfit_to_manifest() -> void:
	var manager := get_node_or_null("/root/WardrobeManager")
	if manager == null:
		return
	var outfit := WardrobeCatalog.get_outfit(str(manager.get("equipped_outfit_id")))
	var model_path := str(outfit.get("model_path", ""))
	if model_path != "" and ResourceLoader.exists(model_path, "PackedScene"):
		_load_manifest.append({"path": model_path, "weight": 0.45, "required": false})


func _pump_preload_queue() -> void:
	if _load_failed or _hidden_world != null:
		return
	for raw_path in _active_loads.keys():
		var path := str(raw_path)
		var progress := []
		var status := ResourceLoader.load_threaded_get_status(path, progress)
		if not progress.is_empty():
			_resource_progress[path] = clampf(float(progress[0]), 0.0, 1.0)
		match status:
			ResourceLoader.THREAD_LOAD_LOADED:
				var resource := ResourceLoader.load_threaded_get(path)
				_loaded_resources[path] = resource
				_resource_progress[path] = 1.0
				_active_loads.erase(path)
			ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				_active_loads.erase(path)
				_resource_progress[path] = 1.0
				_handle_load_failure(path)
				if _load_failed:
					return
	while _active_loads.size() < MAX_CONCURRENT_LOADS and not _pending_load_paths.is_empty():
		var path: String = _pending_load_paths.pop_front()
		if not ResourceLoader.exists(path):
			_resource_progress[path] = 1.0
			_handle_load_failure(path)
			if _load_failed:
					return
			continue
		var error := ResourceLoader.load_threaded_request(path, "", false)
		if error != OK:
			_resource_progress[path] = 1.0
			_handle_load_failure(path)
			if _load_failed:
				return
			continue
		_active_loads[path] = true
	if _pending_load_paths.is_empty() and _active_loads.is_empty() and not _load_failed:
		_start_hidden_world()


func _handle_load_failure(path: String) -> void:
	var required := path == NEXT_SCENE
	for entry in _load_manifest:
		if str(entry.get("path", "")) == path:
			required = bool(entry.get("required", required))
			break
	if required:
		_load_failed = true
		_load_failure_message = "主世界加载失败，按任意键重试"
		push_error("Intro startup could not load required resource: %s" % path)
	else:
		push_warning("Intro startup preload skipped optional resource: %s" % path)


func _start_hidden_world() -> void:
	var packed := _loaded_resources.get(NEXT_SCENE) as PackedScene
	if packed == null:
		_load_failed = true
		_load_failure_message = "主世界加载失败，按任意键重试"
		return
	var world := packed.instantiate() as Node3D
	if world == null or not world.has_method("_prepare_staged_startup"):
		_load_failed = true
		_load_failure_message = "主世界初始化失败，按任意键重试"
		if world != null:
			world.queue_free()
		return
	_hidden_world = world
	world.call("_prepare_staged_startup")
	world.connect("startup_progress_changed", Callable(self, "_on_world_startup_progress_changed"))
	world.connect("startup_completed", Callable(self, "_on_world_startup_completed"))
	get_tree().root.add_child(world)


func _on_world_startup_progress_changed(progress: float, stage: String) -> void:
	_world_build_progress = maxf(_world_build_progress, clampf(progress, 0.0, 1.0))
	_world_build_stage = stage


func _on_world_startup_completed() -> void:
	_hidden_world_ready = true
	_world_build_progress = 1.0
	_world_build_stage = "准备完成"
	_try_begin_world_transition()


func _resource_load_progress() -> float:
	var weighted_progress := 0.0
	for entry in _load_manifest:
		var path := str(entry.get("path", ""))
		var weight := float(entry.get("weight", 1.0))
		weighted_progress += float(_resource_progress.get(path, 0.0)) * weight
	return clampf(weighted_progress / _resource_weight_total, 0.0, 1.0)


func _update_displayed_progress(delta: float) -> void:
	var target := _resource_load_progress() * RESOURCE_PROGRESS_WEIGHT
	if _hidden_world != null:
		target = RESOURCE_PROGRESS_WEIGHT + _world_build_progress * WORLD_PROGRESS_WEIGHT
	if _hidden_world_ready:
		target = 1.0
	_displayed_progress = maxf(_displayed_progress, move_toward(_displayed_progress, target, delta * 0.8))


func _update_loading_overlay() -> void:
	if not transition_overlay.visible:
		return
	if _load_failed:
		loading_status.text = _load_failure_message
		loading_percent.text = ""
		return
	loading_status.text = "正在进入世界…  %s" % _world_build_stage
	loading_bar.value = _displayed_progress * 100.0
	loading_percent.text = "%d%%" % int(round(_displayed_progress * 100.0))


func _try_begin_world_transition() -> void:
	if not _transition_requested or not _hidden_world_ready or _transition_started:
		return
	_transition_started = true
	_displayed_progress = 1.0
	_update_loading_overlay()
	set_process_input(false)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hidden_world.visible = true
	get_tree().current_scene = _hidden_world
	_restore_time_pause()
	_hidden_world.call("_activate_staged_startup")
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, TRANSITION_FADE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(_complete_intro_transition)


func _complete_intro_transition() -> void:
	queue_free()


func _restore_time_pause() -> void:
	if _time_pause_restored:
		return
	_time_pause_restored = true
	if _time_manager != null and is_instance_valid(_time_manager):
		_time_manager.set("paused", _time_manager_was_paused)
