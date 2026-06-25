@tool
extends Node3D

@export_range(4000, 60000, 1000) var grass_count: int = 26000:
	set(value):
		grass_count = value
		_queue_editor_rebuild()
@export_range(20.0, 160.0, 1.0) var field_radius: float = 72.0:
	set(value):
		field_radius = value
		_queue_editor_rebuild()
@export_range(0.15, 2.0, 0.05) var grass_height: float = 0.64:
	set(value):
		grass_height = value
		_queue_editor_rebuild()
@export_range(0.2, 1.8, 0.05) var wind_strength: float = 0.30:
	set(value):
		wind_strength = value
		_queue_editor_rebuild()
@export_range(0.4, 4.0, 0.1) var wind_speed: float = 1.35:
	set(value):
		wind_speed = value
		_queue_editor_rebuild()
@export var refresh_grass_preview: bool = false:
	set(value):
		refresh_grass_preview = false
		_queue_editor_rebuild()

const TERRAIN_SIZE := 160.0
const TERRAIN_STEPS := 80
const GRASS_SHADER := preload("res://shaders/grass_wind.gdshader")
const PLAYER_SCENE_PATH := "res://scenes/Player.tscn"
const CAMPER_SCENE_PATH := "res://3d建模/房车3d建模/9074167cffdd2b26a03baf531b4fae76.glb"
const MOM_SCENE_PATH := "res://3d建模/妈妈3d建模/95b973b63a8027c98172bc0efdb9bd68.glb"
const POND_SCENE_PATH := "res://3d建模/池塘/1a6db431228638d85c528889bcff7353.glb"
const REBAS_SCENE_PATH := "res://3d建模/瑞巴斯坎特/edc69c0683555e5c1d2445d7f6f37e75.glb"
const VILLAGE_HOUSE_SCENE_PATH := "res://3d建模/村里房子/311d8c4383612ac907ea5d625b074aaa.glb"
const TREE_SCENE_PATH := "res://3d建模/树/2f5d6b66e5b0fbbf4c7b1bede79477f5.glb"
const HOE_SCENE_PATH := "res://3d建模/工具/锄头.glb"
const MOM_PORTRAIT_PATH := "res://聊天框/安提莉尔.png"
const PLAYER_PORTRAIT_PATH := "res://聊天框/我.png"
const DIALOGUE_BOX_PATH := "res://聊天框/聊天框.png"
const WORLD_MAP_PATH := "res://地图/b47063e2-0274-40a4-817d-c408c0418cd0_feathered.png"
const PLAYER_START := Vector3(0.0, 0.0, -26.0)
const CAMPER_POSITION := Vector3(0.0, 0.0, 10.0)
const MOM_POSITION := Vector3(0.0, 0.0, -4.0)
const CAMPER_TARGET_LENGTH := 8.8
const CAMPER_BLOCKER_PADDING := Vector2(0.12, 0.16)
const CAMPER_BLOCKER_SHRINK := 0.74
const MOM_MODEL_SCALE := 2.35
const MOM_BLOCKER_RADIUS := 1.05
const MOM_FACE_PLAYER_OFFSET := 0.0
const MOM_INTERACT_RADIUS := 1.65
const CAMPER_INTERACT_RADIUS := 4.2
const MAP_VILLAGE_RADIUS := 0.095
const MAP_LOCKED_SITE_RADIUS := 0.065
const MAP_CAMPER_START := Vector2(0.125, 0.515)
const MAP_VILLAGE_POINT := Vector2(0.185, 0.315)
const MAP_VILLAGE_LABEL_POINT := Vector2(0.245, 0.125)
const MAP_LOCKED_SITE_POINTS := [
	Vector2(0.30, 0.67),
	Vector2(0.58, 0.20),
	Vector2(0.78, 0.42),
	Vector2(0.56, 0.72),
]
const MAP_LOCKED_LABEL_POINTS := [
	Vector2(0.30, 0.56),
	Vector2(0.58, 0.12),
	Vector2(0.78, 0.33),
	Vector2(0.56, 0.61),
]
const MAP_CAMPER_SPEED := 0.24
const MAP_CAMPER_RIGHT_FACING_YAW := PI
const MAP_CAMPER_YAW_OFFSET := MAP_CAMPER_RIGHT_FACING_YAW - PI * 0.5
const DIALOGUE_CHARS_PER_SECOND := 28.0
const TREE_BLOCKER_RADIUS := 1.05
const TREE_CLICK_SHAKE_RADIUS := 1.25
const TREE_SHAKE_DURATION := 0.42
const TREE_SHAKE_STRENGTH := 0.16
const TREE_SHAKE_FREQUENCY := 48.0
const PLAYER_MOVE_SPEED := 5.2
const SOIL_TILE_HALF_SIZE := 0.50
const SOIL_POND_EDGE_PADDING := 1.15
const CHAPTER_ONE_PLAYER_START := Vector3(0.4, 0.0, 7.6)
const CHAPTER_ONE_HOUSE_POSITION := Vector3(6.0, 0.0, -7.0)
const CHAPTER_ONE_HOUSE_YAW := -24.0
const CHAPTER_ONE_MOM_POSITION := Vector3(-0.8, 0.0, 2.0)
const CHAPTER_ONE_MOM_MODEL_SCALE := MOM_MODEL_SCALE
const CHAPTER_ONE_REBAS_POSITION := Vector3(-32.784, 0.0, 11.879)
const CHAPTER_ONE_CAMPER_POSITION := Vector3(15.8, 0.0, 8.8)
const CHAPTER_ONE_CAMPER_YAW := -42.0
const CHAPTER_ONE_HOUSE_TARGET_LENGTH := 24.0
const CHAPTER_ONE_REBAS_TARGET_HEIGHT := 3.15
const CHAPTER_ONE_HOUSE_TREE_CLEAR_RADIUS := 30.0
const CHAPTER_ONE_CAMPER_POND_PADDING_RADIUS := 10.0
const VISIBLE_SUN_POSITION := Vector3(-30.0, 42.0, 86.0)
const PONDS := [
	{
		"position": Vector2(-18.0, 11.0),
		"radius": Vector2(8.6, 5.2),
		"rotation": 0.34,
	},
	{
		"position": Vector2(24.0, -19.0),
		"radius": Vector2(6.2, 3.9),
		"rotation": -0.48,
	},
]
const CHAPTER_ONE_PONDS := [
	{
		"position": Vector2(-18.0, -16.0),
		"radius": Vector2(7.8, 4.8),
		"rotation": 0.18,
	},
	{
		"position": Vector2(23.0, 14.0),
		"radius": Vector2(5.4, 3.7),
		"rotation": -0.55,
	},
	{
		"position": Vector2(-34.0, 25.0),
		"radius": Vector2(4.8, 3.1),
		"rotation": 0.72,
	},
]

var _camera_pivot: Node3D
var _camera: Camera3D
var _grass_material: ShaderMaterial
var _grass_multimesh: MultiMesh
var _player: Node3D
var _player_visual: Node3D
var _camper: Node3D
var _camper_model: Node3D
var _camper_is_highlighted := false
var _mom: Node3D
var _mom_model: Node3D
var _mom_exclamation: Label3D
var _mom_is_highlighted := false
var _highlight_material: StandardMaterial3D
var _dialogue_layer: CanvasLayer
var _hud_root: Control
var _interaction_prompt: Control
var _interaction_prompt_label: Label
var _inventory_bar: HBoxContainer
var _inventory_slots: Array[PanelContainer] = []
var _selected_inventory_slot := 0
var _reward_overlay: Control
var _reward_panel: Control
var _reward_viewport: SubViewport
var _reward_model_root: Node3D
var _reward_dragging := false
var _reward_press_position := Vector2.ZERO
var _reward_last_drag_position := Vector2.ZERO
var _reward_collecting := false
var _dialogue_panel: Control
var _dialogue_portrait: TextureRect
var _dialogue_name: Label
var _dialogue_body: Label
var _dialogue_options: HBoxContainer
var _dialogue_steps: Array[Dictionary] = []
var _dialogue_index := 0
var _dialogue_open := false
var _dialogue_completed := false
var _map_open := false
var _chapter_transitioning := false
var _chapter_one_active := false
var _map_panel: Control
var _map_popup: Control
var _map_camper_marker: Control
var _map_camper_icon: TextureRect
var _map_camper_model: Node3D
var _map_village_label: Label
var _map_locked_label: Label
var _map_camper_pos := MAP_CAMPER_START
var _map_village_label_time := 0.0
var _map_was_near_village := false
var _map_locked_label_time := 0.0
var _map_locked_site_index := -1
var _map_dragging := false
var _map_drag_start := Vector2.ZERO
var _map_drag_vector := Vector2.ZERO
var _has_hoe := false
var _notification_time := 0.0
var _notification_text := ""
var _tilled_soil_root: Node3D
var _tilled_soil_centers: Array[Vector2] = []
var _player_hoe_root: Node3D
var _player_hoe_model: Node3D
var _hoe_swinging := false
var _typewriter_time := 0.0
var _typewriter_total := 0
var _solid_blockers: Array[Dictionary] = []
var _wind_trees: Array[Dictionary] = []
var _active_ponds: Array = []
var _orbit := Vector2(0.0, 0.42)
var _zoom := 15.0
var _editor_rebuild_queued := false

func _ready() -> void:
	randomize()
	if Engine.is_editor_hint():
		call_deferred("_rebuild_scene")
		return
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_rebuild_scene()

func _rebuild_scene() -> void:
	_editor_rebuild_queued = false
	_chapter_one_active = false
	_chapter_transitioning = false
	_active_ponds = PONDS.duplicate(true)
	_grass_material = null
	_grass_multimesh = null
	_hud_root = null
	_camper = null
	_camper_model = null
	_map_camper_model = null
	_mom = null
	_mom_model = null
	_mom_exclamation = null
	_mom_is_highlighted = false
	_dialogue_open = false
	_dialogue_index = 0
	_dialogue_completed = false
	_map_open = false
	_map_camper_pos = MAP_CAMPER_START
	_map_dragging = false
	_map_drag_vector = Vector2.ZERO
	_has_hoe = false
	_selected_inventory_slot = 0
	_reward_overlay = null
	_reward_panel = null
	_reward_viewport = null
	_reward_model_root = null
	_reward_dragging = false
	_reward_press_position = Vector2.ZERO
	_reward_collecting = false
	_notification_time = 0.0
	_tilled_soil_root = null
	_tilled_soil_centers.clear()
	_player_hoe_root = null
	_player_hoe_model = null
	_hoe_swinging = false
	_camper_is_highlighted = false
	_typewriter_time = 0.0
	_typewriter_total = 0
	_solid_blockers.clear()
	_wind_trees.clear()
	_clear_generated()
	_setup_world()
	_create_visible_sun()
	_create_background_clouds()
	_create_falling_petals()
	_create_terrain()
	_create_ponds()
	_create_ground_petals()
	_create_grass()
	_create_background_trees()
	_create_asset_trees()
	_create_mom()
	_create_camper()
	_create_player()
	_create_camera()
	_create_dialogue_ui()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _chapter_transitioning:
		return
	if _reward_overlay != null and _reward_overlay.visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return
	_update_tree_wind(delta)
	_update_grass_player_push()
	_update_mom_interaction()
	_refresh_interaction_prompt_text()
	if _dialogue_open:
		_update_dialogue_typewriter(delta)
	if _map_open:
		_update_map_popup(delta)
	if not _dialogue_open and not _map_open:
		_update_camera_input(delta)
		_apply_camera()
	_update_mom_exclamation(delta)
	_update_notification(delta)

func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if _chapter_transitioning:
		get_viewport().set_input_as_handled()
		return
	if _reward_overlay != null and _reward_overlay.visible:
		_handle_reward_overlay_input(event)
		return
	if _map_open:
		_handle_map_input(event)
		return
	if event is InputEventMouseMotion and not _dialogue_open:
		var mouse_sensitivity := 0.0032
		_orbit.x -= event.relative.x * mouse_sensitivity
		_orbit.y = clampf(_orbit.y + event.relative.y * mouse_sensitivity, 0.04, 0.72)
		_apply_camera()
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if _dialogue_open:
			_close_dialogue()
		elif _map_open:
			_close_map_popup()
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if event is InputEventKey and event.pressed and event.keycode == KEY_P:
		_capture_player_position()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_F:
		if not _try_enter_camper() and not _try_start_mom_dialogue():
			_try_use_selected_tool()
	if event is InputEventMouseButton and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_select_inventory_delta(-1)
			get_viewport().set_input_as_handled()
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_select_inventory_delta(1)
			get_viewport().set_input_as_handled()
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not _try_enter_camper() and not _try_start_mom_dialogue():
				if not _try_use_selected_tool():
					_shake_nearby_tree()

func _queue_editor_rebuild() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree() or _editor_rebuild_queued:
		return
	_editor_rebuild_queued = true
	call_deferred("_rebuild_scene")

func _clear_generated() -> void:
	for child in get_children():
		if child.get_meta("generated_grass_world", false):
			child.queue_free()

func _mark_generated(node: Node) -> void:
	node.set_meta("generated_grass_world", true)

func _sun_light_direction() -> Vector3:
	return -VISIBLE_SUN_POSITION.normalized()

func _setup_world() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.48, 0.74, 0.98)
	sky_mat.sky_horizon_color = Color(0.74, 0.88, 0.96)
	sky_mat.ground_bottom_color = Color(0.76, 0.82, 0.72)
	sky_mat.ground_horizon_color = Color(0.86, 0.91, 0.84)
	sky_mat.sun_angle_max = 22.0
	sky_mat.sun_curve = 0.12
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.72
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.08
	env.tonemap_white = 4.2
	env.glow_enabled = true
	env.glow_intensity = 0.20
	env.glow_strength = 0.28
	env.fog_enabled = true
	env.fog_light_color = Color(0.78, 0.88, 0.94)
	env.fog_sun_scatter = 0.12
	env.fog_density = 0.0018
	env.fog_aerial_perspective = 0.08
	world_env.environment = env
	_mark_generated(world_env)
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.name = "SoftSun"
	sun.position = VISIBLE_SUN_POSITION
	sun.light_color = Color(1.0, 0.90, 0.62)
	sun.light_energy = 5.6
	sun.light_angular_distance = 1.2
	sun.shadow_enabled = false
	sun.shadow_opacity = 0.0
	sun.directional_shadow_max_distance = 80.0
	_mark_generated(sun)
	add_child(sun)
	sun.look_at(Vector3.ZERO, Vector3.UP)

func _create_visible_sun() -> void:
	var sun_mesh := SphereMesh.new()
	sun_mesh.radius = 5.2
	sun_mesh.height = 10.4
	sun_mesh.radial_segments = 48
	sun_mesh.rings = 24

	var sun_mat := StandardMaterial3D.new()
	sun_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sun_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sun_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	sun_mat.albedo_color = Color(1.0, 0.86, 0.36, 0.62)
	sun_mat.emission_enabled = true
	sun_mat.emission = Color(1.0, 0.78, 0.28)
	sun_mat.emission_energy_multiplier = 3.8

	var visible_sun := MeshInstance3D.new()
	visible_sun.name = "VisibleSun"
	visible_sun.mesh = sun_mesh
	visible_sun.material_override = sun_mat
	visible_sun.position = VISIBLE_SUN_POSITION
	visible_sun.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mark_generated(visible_sun)
	add_child(visible_sun)

	for halo in [
		{"radius": 13.5, "alpha": 0.24, "energy": 1.8},
		{"radius": 22.0, "alpha": 0.10, "energy": 1.1},
		{"radius": 34.0, "alpha": 0.045, "energy": 0.7},
	]:
		var halo_mesh := SphereMesh.new()
		halo_mesh.radius = halo["radius"]
		halo_mesh.height = halo["radius"] * 2.0
		halo_mesh.radial_segments = 48
		halo_mesh.rings = 16

		var halo_mat := StandardMaterial3D.new()
		halo_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		halo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		halo_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		halo_mat.albedo_color = Color(1.0, 0.70, 0.22, halo["alpha"])
		halo_mat.emission_enabled = true
		halo_mat.emission = Color(1.0, 0.62, 0.18)
		halo_mat.emission_energy_multiplier = halo["energy"]

		var sun_halo := MeshInstance3D.new()
		sun_halo.name = "VisibleSunHalo"
		sun_halo.mesh = halo_mesh
		sun_halo.material_override = halo_mat
		sun_halo.position = visible_sun.position
		sun_halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_mark_generated(sun_halo)
		add_child(sun_halo)

func _create_background_clouds() -> void:
	var cloud_mat := StandardMaterial3D.new()
	cloud_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cloud_mat.albedo_color = Color(0.96, 0.98, 0.94, 0.88)
	cloud_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var rng := RandomNumberGenerator.new()
	rng.seed = 2727
	for i in range(24):
		var cloud := Node3D.new()
		cloud.name = "SoftHorizonCloud"
		var a := TAU * float(i) / 24.0 + rng.randf_range(-0.06, 0.06)
		var r := rng.randf_range(72.0, 118.0)
		cloud.position = Vector3(cos(a) * r, rng.randf_range(24.0, 39.0), sin(a) * r)
		cloud.rotation.y = -a + PI * 0.5
		cloud.scale = Vector3.ONE * rng.randf_range(1.25, 2.15)
		_mark_generated(cloud)
		add_child(cloud)

		var puff_count := rng.randi_range(5, 9)
		for j in range(puff_count):
			var puff := MeshInstance3D.new()
			var puff_mesh := BoxMesh.new()
			puff_mesh.size = Vector3(rng.randf_range(16.0, 32.0), rng.randf_range(4.4, 9.0), 0.72)
			puff.mesh = puff_mesh
			puff.position = Vector3(rng.randf_range(-34.0, 34.0), rng.randf_range(-2.4, 2.8), rng.randf_range(-0.6, 0.6))
			puff.rotation.z = rng.randf_range(-0.035, 0.035)
			puff.material_override = cloud_mat
			puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			cloud.add_child(puff)

func _create_falling_petals() -> void:
	_create_petal_emitter(
		"NearPetalFall",
		Vector3(7.0, 30.0, 24.0),
		Vector3(48.0, 1.0, 64.0),
		950,
		24.0,
		Color(1.0, 0.66, 0.78, 0.86),
		Vector2(0.18, 0.10),
		1.0
	)
	_create_petal_emitter(
		"RoutePetalFall",
		Vector3(10.0, 38.0, 28.0),
		Vector3(86.0, 1.0, 98.0),
		620,
		34.0,
		Color(1.0, 0.86, 0.90, 0.58),
		Vector2(0.14, 0.075),
		0.72
	)
	_create_petal_emitter(
		"SoftDistantPetalFall",
		Vector3(-22.0, 40.0, 16.0),
		Vector3(92.0, 1.0, 96.0),
		320,
		36.0,
		Color(1.0, 0.78, 0.86, 0.42),
		Vector2(0.12, 0.065),
		0.58
	)
	for index in range(_active_ponds.size()):
		var pond: Dictionary = _active_ponds[index]
		var center: Vector2 = pond["position"]
		var radius: Vector2 = pond["radius"]
		_create_petal_emitter(
			"PondPetalFall%d" % index,
			Vector3(center.x, _height_at(center.x, center.y) + 11.0, center.y),
			Vector3(radius.x * 1.25, 0.65, radius.y * 1.25),
			180,
			18.0,
			Color(1.0, 0.67, 0.82, 0.72),
			Vector2(0.15, 0.085),
			0.42
		)

func _create_petal_emitter(
	emitter_name: String,
	emitter_position: Vector3,
	box_extents: Vector3,
	petal_amount: int,
	petal_lifetime: float,
	petal_color: Color,
	petal_size: Vector2,
	speed_scale: float
) -> void:
	var petal_mat := StandardMaterial3D.new()
	petal_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	petal_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	petal_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	petal_mat.albedo_color = petal_color
	petal_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var petal_mesh := _create_petal_mesh(petal_size, petal_mat)

	var process_mat := ParticleProcessMaterial.new()
	process_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process_mat.emission_box_extents = box_extents
	process_mat.direction = Vector3(0.22, -1.0, 0.08).normalized()
	process_mat.spread = 28.0
	process_mat.gravity = Vector3(0.08, -0.16, 0.03) * speed_scale
	process_mat.initial_velocity_min = 0.45 * speed_scale
	process_mat.initial_velocity_max = 1.15 * speed_scale
	process_mat.angular_velocity_min = -170.0
	process_mat.angular_velocity_max = 170.0
	process_mat.linear_accel_min = -0.08
	process_mat.linear_accel_max = 0.08
	process_mat.tangential_accel_min = -0.22
	process_mat.tangential_accel_max = 0.22
	process_mat.damping_min = 0.08
	process_mat.damping_max = 0.22
	process_mat.scale_min = 0.75
	process_mat.scale_max = 1.45
	process_mat.color = petal_color

	var petals := GPUParticles3D.new()
	petals.name = emitter_name
	petals.amount = petal_amount
	petals.lifetime = petal_lifetime
	petals.preprocess = petal_lifetime
	petals.randomness = 0.72
	petals.visibility_aabb = AABB(Vector3(-90.0, -8.0, -90.0), Vector3(180.0, 60.0, 180.0))
	petals.emitting = true
	petals.process_material = process_mat
	petals.draw_pass_1 = petal_mesh
	petals.position = emitter_position
	_mark_generated(petals)
	add_child(petals)

func _create_petal_mesh(petal_size: Vector2, petal_mat: Material) -> ArrayMesh:
	var half_width := petal_size.x * 0.5
	var half_height := petal_size.y * 0.5
	var vertices := PackedVector3Array([
		Vector3(0.0, 0.0, 0.0),
		Vector3(0.0, half_height, 0.0),
		Vector3(-half_width * 0.78, half_height * 0.34, 0.0),
		Vector3(-half_width, -half_height * 0.22, 0.0),
		Vector3(0.0, -half_height, 0.0),
		Vector3(half_width, -half_height * 0.22, 0.0),
		Vector3(half_width * 0.78, half_height * 0.34, 0.0),
	])
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	for vertex in vertices:
		normals.append(Vector3.FORWARD)
		uvs.append(Vector2(vertex.x / petal_size.x + 0.5, vertex.y / petal_size.y + 0.5))

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3, 0, 3, 4, 0, 4, 5, 0, 5, 6, 0, 6, 1])

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, petal_mat)
	return mesh

func _create_terrain() -> void:
	var mesh := ArrayMesh.new()
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var half := TERRAIN_SIZE * 0.5

	for z in range(TERRAIN_STEPS + 1):
		for x in range(TERRAIN_STEPS + 1):
			var px := lerpf(-half, half, float(x) / TERRAIN_STEPS)
			var pz := lerpf(-half, half, float(z) / TERRAIN_STEPS)
			var py := _height_at(px, pz)
			vertices.append(Vector3(px, py, pz))
			normals.append(_normal_at(px, pz))
			uvs.append(Vector2(float(x) / TERRAIN_STEPS, float(z) / TERRAIN_STEPS))

	for z in range(TERRAIN_STEPS):
		for x in range(TERRAIN_STEPS):
			var i := z * (TERRAIN_STEPS + 1) + x
			indices.append_array(PackedInt32Array([i, i + TERRAIN_STEPS + 1, i + 1, i + 1, i + TERRAIN_STEPS + 1, i + TERRAIN_STEPS + 2]))

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var ground := MeshInstance3D.new()
	ground.name = "SoftLowPolyGround"
	ground.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.78, 0.82, 0.72)
	mat.roughness = 0.92
	mat.disable_receive_shadows = false
	ground.material_override = mat
	_mark_generated(ground)
	add_child(ground)

func _create_grass() -> void:
	var grass_mesh := _make_grass_clump_mesh()
	var mat := ShaderMaterial.new()
	mat.shader = GRASS_SHADER
	mat.set_shader_parameter("wind_strength", wind_strength)
	mat.set_shader_parameter("wind_speed", wind_speed)
	mat.set_shader_parameter("player_push_radius", 2.4)
	mat.set_shader_parameter("player_push_strength", 0.0)
	_grass_material = mat

	var multimesh := MultiMesh.new()
	_grass_multimesh = multimesh
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.use_custom_data = false
	multimesh.mesh = grass_mesh
	multimesh.instance_count = grass_count

	var rng := RandomNumberGenerator.new()
	rng.seed = 424242
	var cluster_centers := _make_grass_cluster_centers(rng, 96)
	var placed := 0
	var attempts := 0
	while placed < grass_count and attempts < grass_count * 8:
		attempts += 1
		var x := 0.0
		var z := 0.0
		for retry in range(8):
			var point := _pick_grass_point(rng, cluster_centers)
			x = point.x
			z = point.y
			if not _is_inside_pond(x, z, 1.35):
				break

		var density := _grass_density_at(x, z)
		if rng.randf() > density * 0.95:
			continue

		var y := _height_at(x, z)
		var height_variation := lerpf(0.62, 1.12, pow(rng.randf(), 0.72))
		var density_height := lerpf(0.82, 1.08, density)
		var scale := rng.randf_range(0.78, 1.08) * grass_height * density_height
		var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(Vector3(scale * rng.randf_range(0.95, 1.18), scale * height_variation, scale * rng.randf_range(0.95, 1.18)))
		multimesh.set_instance_transform(placed, Transform3D(basis, Vector3(x, y, z)))
		var shade := rng.randf()
		var clump_color := Color(lerpf(0.35, 0.72, shade), lerpf(0.52, 0.82, shade), lerpf(0.26, 0.38, shade), 1.0)
		multimesh.set_instance_color(placed, clump_color)
		placed += 1

	multimesh.instance_count = placed

	var grass := MultiMeshInstance3D.new()
	grass.name = "VeryDenseWindGrass"
	grass.multimesh = multimesh
	grass.material_override = mat
	grass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mark_generated(grass)
	add_child(grass)

func _update_grass_player_push() -> void:
	if _grass_material == null:
		return
	if _player != null and is_instance_valid(_player):
		_grass_material.set_shader_parameter("player_position", _player.global_position)

func _grass_density_at(x: float, z: float) -> float:
	var broad := sin(x * 0.115 + 1.7) * 0.5 + cos(z * 0.092 - 0.4) * 0.5
	var patches := sin((x + z) * 0.175) * 0.28 + cos((x - z) * 0.145) * 0.22
	var fine := sin(x * 0.43 + z * 0.27) * 0.08
	var clumps := sin(x * 0.31 + z * 0.19) * 0.18 + cos(x * 0.24 - z * 0.28) * 0.16
	var density := 0.42 + broad * 0.18 + patches * 0.28 + clumps + fine
	return clampf(density, 0.10, 0.96)

func _make_grass_cluster_centers(rng: RandomNumberGenerator, count: int) -> Array[Vector2]:
	var centers: Array[Vector2] = []
	for i in range(count):
		var r := field_radius * sqrt(rng.randf())
		var a := rng.randf_range(0.0, TAU)
		centers.append(Vector2(cos(a) * r, sin(a) * r))
	return centers

func _pick_grass_point(rng: RandomNumberGenerator, cluster_centers: Array[Vector2]) -> Vector2:
	if cluster_centers.size() > 0 and rng.randf() < 0.72:
		var center := cluster_centers[rng.randi_range(0, cluster_centers.size() - 1)]
		var spread := rng.randf_range(1.1, 4.6)
		var angle := rng.randf_range(0.0, TAU)
		var distance := spread * pow(rng.randf(), 1.75)
		return center + Vector2(cos(angle), sin(angle)) * distance
	var r := field_radius * sqrt(rng.randf())
	var a := rng.randf_range(0.0, TAU)
	return Vector2(cos(a) * r, sin(a) * r)

func _is_inside_pond(x: float, z: float, padding: float = 0.0) -> bool:
	var effective_padding := padding
	if _chapter_one_active:
		var camper_point := Vector2(CHAPTER_ONE_CAMPER_POSITION.x, CHAPTER_ONE_CAMPER_POSITION.z)
		var sample_point := Vector2(x, z)
		if sample_point.distance_squared_to(camper_point) <= CHAPTER_ONE_CAMPER_POND_PADDING_RADIUS * CHAPTER_ONE_CAMPER_POND_PADDING_RADIUS:
			effective_padding = minf(effective_padding, 0.1)
	for pond in _active_ponds:
		var center: Vector2 = pond["position"]
		var radius: Vector2 = pond["radius"] + Vector2(effective_padding, effective_padding)
		var rotation: float = pond["rotation"]
		var offset := Vector2(x - center.x, z - center.y)
		var local := offset.rotated(-rotation)
		var normalized := pow(local.x / radius.x, 2.0) + pow(local.y / radius.y, 2.0)
		if normalized <= 1.0:
			return true
	return false

func _create_ponds() -> void:
	var scene := load(POND_SCENE_PATH)
	if not scene is PackedScene:
		push_warning("Could not load pond model: %s" % POND_SCENE_PATH)
		return

	for pond in _active_ponds:
		var center: Vector2 = pond["position"]
		var radius: Vector2 = pond["radius"]
		var rotation: float = pond["rotation"]
		var base_y := _height_at(center.x, center.y)

		var pond_root := Node3D.new()
		pond_root.name = "SmallReflectivePond"
		pond_root.position = Vector3(center.x, base_y, center.y)
		pond_root.rotation.y = rotation
		_mark_generated(pond_root)
		add_child(pond_root)

		var model := scene.instantiate() as Node3D
		if model == null:
			continue
		model.name = "PondModel"
		pond_root.add_child(model)
		_fit_model_to_footprint_length(model, maxf(radius.x, radius.y) * 2.25)
		_prepare_pond_model(model)
		_add_floating_pond_petals(pond_root, radius)

func _prepare_pond_model(model: Node3D) -> void:
	model.scale.y *= 0.015
	_ground_model(model)
	model.position.y -= 0.035
	_set_model_shadow(model, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	for mesh_instance in _collect_mesh_instances(model):
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _add_floating_pond_petals(pond_root: Node3D, radius: Vector2) -> void:
	var petal_mat := StandardMaterial3D.new()
	petal_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	petal_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	petal_mat.albedo_color = Color(1.0, 0.70, 0.84, 0.66)
	petal_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var petal_mesh := _create_petal_mesh(Vector2(0.18, 0.095), petal_mat)

	var rng := RandomNumberGenerator.new()
	rng.seed = int(absf(pond_root.position.x * 97.0 + pond_root.position.z * 131.0)) + 5050
	var water_clusters: Array[Vector2] = []
	for i in range(4):
		var cluster_angle := rng.randf_range(0.0, TAU)
		var cluster_distance := sqrt(rng.randf()) * rng.randf_range(0.18, 0.72)
		water_clusters.append(Vector2(cos(cluster_angle) * radius.x * cluster_distance, sin(cluster_angle) * radius.y * cluster_distance))
	for i in range(36):
		var petal := MeshInstance3D.new()
		petal.name = "FloatingCherryPetal"
		petal.mesh = petal_mesh
		var point := Vector2.ZERO
		if rng.randf() < 0.78:
			var cluster := water_clusters[rng.randi_range(0, water_clusters.size() - 1)]
			var angle := rng.randf_range(0.0, TAU)
			var spread := rng.randf_range(0.18, 0.72) * pow(rng.randf(), 1.55)
			point = cluster + Vector2(cos(angle) * radius.x * 0.16, sin(angle) * radius.y * 0.16) * spread
		else:
			var angle := rng.randf_range(0.0, TAU)
			var distance := sqrt(rng.randf()) * rng.randf_range(0.10, 0.82)
			point = Vector2(cos(angle) * radius.x * distance, sin(angle) * radius.y * distance)
		petal.position = Vector3(point.x, 0.045 + rng.randf_range(0.0, 0.012), point.y)
		petal.rotation = Vector3(-PI * 0.5 + rng.randf_range(-0.08, 0.08), rng.randf_range(0.0, TAU), rng.randf_range(-0.04, 0.04))
		petal.scale = Vector3.ONE * rng.randf_range(0.75, 1.25)
		petal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pond_root.add_child(petal)

	for i in range(30):
		var petal := MeshInstance3D.new()
		petal.name = "GroundCherryPetal"
		petal.mesh = petal_mesh
		var angle := rng.randf_range(0.0, TAU)
		var edge_distance := rng.randf_range(0.98, 1.35)
		var cluster_pull := 0.0
		if rng.randf() < 0.62:
			cluster_pull = rng.randf_range(-0.18, 0.18)
		var ground_angle := angle + cluster_pull
		petal.position = Vector3(cos(ground_angle) * radius.x * edge_distance, 0.032 + rng.randf_range(0.0, 0.01), sin(ground_angle) * radius.y * edge_distance)
		petal.rotation = Vector3(-PI * 0.5 + rng.randf_range(-0.10, 0.10), rng.randf_range(0.0, TAU), rng.randf_range(-0.08, 0.08))
		petal.scale = Vector3.ONE * rng.randf_range(0.65, 1.12)
		petal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pond_root.add_child(petal)

func _create_ground_petals() -> void:
	var petal_mat := StandardMaterial3D.new()
	petal_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	petal_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	petal_mat.albedo_color = Color(1.0, 0.68, 0.82, 0.72)
	petal_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var petal_mesh := _create_petal_mesh(Vector2(0.22, 0.12), petal_mat)

	var rng := RandomNumberGenerator.new()
	rng.seed = 606060
	var clusters: Array[Vector2] = []
	for i in range(42):
		var r := field_radius * sqrt(rng.randf())
		var a := rng.randf_range(0.0, TAU)
		clusters.append(Vector2(cos(a) * r, sin(a) * r))

	for i in range(520):
		var point := Vector2.ZERO
		for retry in range(10):
			if clusters.size() > 0 and rng.randf() < 0.68:
				var cluster := clusters[rng.randi_range(0, clusters.size() - 1)]
				var angle := rng.randf_range(0.0, TAU)
				var distance := rng.randf_range(0.35, 4.4) * pow(rng.randf(), 1.7)
				point = cluster + Vector2(cos(angle), sin(angle)) * distance
			else:
				var r := field_radius * sqrt(rng.randf())
				var a := rng.randf_range(0.0, TAU)
				point = Vector2(cos(a) * r, sin(a) * r)
			if not _is_inside_pond(point.x, point.y, 0.55):
				break

		var petal := MeshInstance3D.new()
		petal.name = "GroundCherryPetal"
		petal.mesh = petal_mesh
		petal.position = Vector3(point.x, _height_at(point.x, point.y) + 0.045 + rng.randf_range(0.0, 0.014), point.y)
		petal.rotation = Vector3(-PI * 0.5 + rng.randf_range(-0.10, 0.10), rng.randf_range(0.0, TAU), rng.randf_range(-0.08, 0.08))
		petal.scale = Vector3.ONE * rng.randf_range(0.72, 1.38)
		petal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_mark_generated(petal)
		add_child(petal)

func _make_ellipse_disc_mesh(radius: Vector2, segments: int) -> ArrayMesh:
	var verts := PackedVector3Array([Vector3.ZERO])
	var normals := PackedVector3Array([Vector3.UP])
	var uvs := PackedVector2Array([Vector2(0.5, 0.5)])
	var indices := PackedInt32Array()

	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		verts.append(Vector3(cos(angle) * radius.x, 0.0, sin(angle) * radius.y))
		normals.append(Vector3.UP)
		uvs.append(Vector2(cos(angle) * 0.5 + 0.5, sin(angle) * 0.5 + 0.5))

	for i in range(segments):
		var next := 1 + ((i + 1) % segments)
		indices.append_array(PackedInt32Array([0, 1 + i, next]))

	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _make_ellipse_ring_mesh(outer_radius: Vector2, inner_radius: Vector2, segments: int) -> ArrayMesh:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		var dir := Vector2(cos(angle), sin(angle))
		verts.append(Vector3(dir.x * outer_radius.x, 0.0, dir.y * outer_radius.y))
		verts.append(Vector3(dir.x * inner_radius.x, 0.0, dir.y * inner_radius.y))
		normals.append_array(PackedVector3Array([Vector3.UP, Vector3.UP]))
		uvs.append_array(PackedVector2Array([Vector2(0.0, float(i) / segments), Vector2(1.0, float(i) / segments)]))

	for i in range(segments):
		var outer_a := i * 2
		var inner_a := outer_a + 1
		var outer_b := ((i + 1) % segments) * 2
		var inner_b := outer_b + 1
		indices.append_array(PackedInt32Array([outer_a, inner_a, outer_b, outer_b, inner_a, inner_b]))

	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _make_grass_clump_mesh() -> ArrayMesh:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var blade_data := [
		[0.00, 0.00, 0.00, 0.34, 1.06, 0.12],
		[0.09, 0.03, 0.82, 0.28, 0.82, 0.09],
		[-0.08, -0.02, -0.72, 0.29, 0.94, 0.11],
		[0.04, -0.10, 1.68, 0.24, 0.74, 0.08],
		[-0.05, 0.09, 2.34, 0.26, 0.88, 0.10],
		[0.14, -0.05, 2.86, 0.22, 0.78, 0.07],
		[-0.15, 0.05, -1.82, 0.23, 0.86, 0.09],
		[0.03, 0.15, -2.48, 0.21, 0.72, 0.07],
	]

	for blade in blade_data:
		var base := Vector3(float(blade[0]), 0.0, float(blade[1]))
		var angle: float = float(blade[2])
		var width: float = float(blade[3])
		var height: float = float(blade[4])
		var lean: float = float(blade[5])
		var right := Vector3(cos(angle), 0.0, sin(angle)) * width * 0.5
		var forward := Vector3(-sin(angle), 0.0, cos(angle))
		var mid := base + forward * lean + Vector3(0.0, height * 0.54, 0.0)
		var tip := base + forward * lean * 1.45 + Vector3(0.0, height, 0.0)
		var start := verts.size()
		verts.append(base - right)
		verts.append(base + right)
		verts.append(mid + right * 0.58)
		verts.append(tip + right * 0.18)
		verts.append(tip - right * 0.18)
		verts.append(mid - right * 0.58)
		uvs.append(Vector2(0.0, 0.0))
		uvs.append(Vector2(1.0, 0.0))
		uvs.append(Vector2(1.0, 0.52))
		uvs.append(Vector2(0.68, 1.0))
		uvs.append(Vector2(0.32, 1.0))
		uvs.append(Vector2(0.0, 0.52))
		normals.append_array(PackedVector3Array([Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP]))
		indices.append_array(PackedInt32Array([start, start + 1, start + 2, start, start + 2, start + 5, start + 5, start + 2, start + 3, start + 5, start + 3, start + 4]))

	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _create_background_trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1212
	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.56, 0.51, 0.42)
	var leaf_mat := StandardMaterial3D.new()
	leaf_mat.albedo_color = Color(0.66, 0.74, 0.64)
	leaf_mat.roughness = 0.95

	for i in range(72):
		var a := rng.randf_range(0.0, TAU)
		var r := rng.randf_range(82.0, 122.0)
		var pos := Vector3(cos(a) * r, 0.0, sin(a) * r)
		pos.y = _height_at(pos.x, pos.z)
		var tree := Node3D.new()
		tree.name = "DistantLowPolyTree"
		tree.position = pos
		tree.rotation.y = rng.randf_range(0.0, TAU)
		tree.scale = Vector3.ONE * rng.randf_range(0.68, 1.55)
		_mark_generated(tree)
		add_child(tree)

		var trunk := MeshInstance3D.new()
		var trunk_mesh := CylinderMesh.new()
		trunk_mesh.top_radius = 0.18
		trunk_mesh.bottom_radius = 0.26
		trunk_mesh.height = 2.1
		trunk_mesh.radial_segments = 6
		trunk.mesh = trunk_mesh
		trunk.position.y = 1.05
		trunk.material_override = trunk_mat
		tree.add_child(trunk)

		var crown := MeshInstance3D.new()
		var crown_mesh := CylinderMesh.new()
		crown_mesh.bottom_radius = rng.randf_range(1.35, 2.15)
		crown_mesh.top_radius = 0.0
		crown_mesh.height = rng.randf_range(3.5, 5.2)
		crown_mesh.radial_segments = 7
		crown.mesh = crown_mesh
		crown.position.y = 3.15
		crown.material_override = leaf_mat
		tree.add_child(crown)

	for i in range(44):
		var a := TAU * float(i) / 44.0 + rng.randf_range(-0.035, 0.035)
		var r := rng.randf_range(128.0, 150.0)
		var pos := Vector3(cos(a) * r, 0.0, sin(a) * r)
		pos.y = _height_at(pos.x, pos.z)
		var tree := Node3D.new()
		tree.name = "FarHorizonTreeLine"
		tree.position = pos
		tree.rotation.y = rng.randf_range(0.0, TAU)
		tree.scale = Vector3.ONE * rng.randf_range(1.05, 2.45)
		_mark_generated(tree)
		add_child(tree)

		var crown := MeshInstance3D.new()
		var crown_mesh := CylinderMesh.new()
		crown_mesh.bottom_radius = rng.randf_range(1.6, 2.4)
		crown_mesh.top_radius = 0.0
		crown_mesh.height = rng.randf_range(5.4, 7.2)
		crown_mesh.radial_segments = 6
		crown.mesh = crown_mesh
		crown.position.y = crown_mesh.height * 0.48
		crown.material_override = leaf_mat
		tree.add_child(crown)

func _create_asset_trees() -> void:
	var scene := load(TREE_SCENE_PATH)
	if not scene is PackedScene:
		push_warning("Could not load tree model: %s" % TREE_SCENE_PATH)
		return

	var tree_points := [
		Vector3(-8.5, 0.0, -10.5),
		Vector3(10.5, 0.0, -12.0),
		Vector3(-16.0, 0.0, 3.5),
		Vector3(15.0, 0.0, 5.5),
		Vector3(-5.0, 0.0, 15.0),
		Vector3(18.0, 0.0, -2.0),
		Vector3(-14.0, 0.0, 27.0),
		Vector3(-24.0, 0.0, 34.0),
		Vector3(20.0, 0.0, 35.0),
		Vector3(34.0, 0.0, 22.0),
		Vector3(-36.0, 0.0, 8.0),
		Vector3(42.0, 0.0, -4.0),
		Vector3(-30.0, 0.0, -26.0),
		Vector3(17.0, 0.0, -38.0),
		Vector3(50.0, 0.0, 39.0),
		Vector3(-52.0, 0.0, 40.0),
		Vector3(55.0, 0.0, -30.0),
		Vector3(-48.0, 0.0, -44.0),
	]

	var rng := RandomNumberGenerator.new()
	rng.seed = 9090
	for index in range(tree_points.size()):
		var point: Vector3 = tree_points[index]
		if _should_skip_asset_tree(point):
			continue
		if _is_inside_pond(point.x, point.z, 5.5):
			continue
		var tree := Node3D.new()
		tree.name = "WindTree"
		tree.position = Vector3(point.x, _height_at(point.x, point.z), point.z)
		tree.rotation.y = rng.randf_range(0.0, TAU)
		_mark_generated(tree)
		add_child(tree)

		var model := scene.instantiate() as Node3D
		if model == null:
			continue
		model.name = "TreeModel"
		tree.add_child(model)
		var target_height := rng.randf_range(4.2, 8.8)
		if index < 6:
			target_height = [4.4, 7.9, 5.3, 8.5, 6.1, 4.8][index]
		_fit_model_to_height(model, target_height)
		_ground_model(model)
		_set_model_shadow(model, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)

		_wind_trees.append({
			"node": tree,
			"base_rotation": tree.rotation,
			"phase": rng.randf_range(0.0, TAU),
			"strength": rng.randf_range(0.018, 0.038),
			"speed": rng.randf_range(0.75, 1.15),
			"shake_time": 0.0,
			"shake_axis": Vector2.ZERO,
			"shake_phase": rng.randf_range(0.0, TAU),
		})
		_add_tree_blocker(tree.position, TREE_BLOCKER_RADIUS, _wind_trees.size() - 1)

func _should_skip_asset_tree(point: Vector3) -> bool:
	if not _chapter_one_active:
		return false
	var point_2d := Vector2(point.x, point.z)
	var house_point := Vector2(CHAPTER_ONE_HOUSE_POSITION.x, CHAPTER_ONE_HOUSE_POSITION.z)
	return point_2d.distance_squared_to(house_point) <= CHAPTER_ONE_HOUSE_TREE_CLEAR_RADIUS * CHAPTER_ONE_HOUSE_TREE_CLEAR_RADIUS

func _update_tree_wind(delta: float) -> void:
	var time := Time.get_ticks_msec() * 0.001
	for tree_data in _wind_trees:
		var tree := tree_data["node"] as Node3D
		if tree == null:
			continue
		var base_rotation: Vector3 = tree_data["base_rotation"]
		var phase: float = tree_data["phase"]
		var strength: float = tree_data["strength"]
		var speed: float = tree_data["speed"]
		var gust := sin(time * speed + phase)
		var secondary := sin(time * speed * 1.73 + phase * 0.7) * 0.35
		var wind_rotation := Vector3(strength * (gust + secondary), 0.0, strength * 0.42 * sin(time * speed * 1.21 + phase))
		var shake_rotation := Vector3.ZERO
		var shake_time: float = tree_data["shake_time"]
		if shake_time > 0.0:
			shake_time = maxf(shake_time - delta, 0.0)
			tree_data["shake_time"] = shake_time
			var shake_axis: Vector2 = tree_data["shake_axis"]
			if shake_axis.length_squared() > 0.0001:
				var falloff := shake_time / TREE_SHAKE_DURATION
				var pulse := sin((TREE_SHAKE_DURATION - shake_time) * TREE_SHAKE_FREQUENCY + float(tree_data["shake_phase"]))
				var amount := TREE_SHAKE_STRENGTH * falloff * pulse
				shake_rotation = Vector3(shake_axis.y * amount, 0.0, -shake_axis.x * amount)
		tree.rotation = base_rotation + wind_rotation + shake_rotation

func _create_player() -> void:
	var scene := load(PLAYER_SCENE_PATH)
	if not scene is PackedScene:
		push_warning("Could not load player scene: %s" % PLAYER_SCENE_PATH)
		return

	_player = scene.instantiate() as Node3D
	if _player == null:
		return
	_player.name = "Player"
	_player.position = Vector3(PLAYER_START.x, _height_at(PLAYER_START.x, PLAYER_START.z) + 0.04, PLAYER_START.z)
	_mark_generated(_player)
	add_child(_player)

func _create_chapter_one_player() -> void:
	var scene := load(PLAYER_SCENE_PATH)
	if not scene is PackedScene:
		push_warning("Could not load player scene: %s" % PLAYER_SCENE_PATH)
		return

	_player = scene.instantiate() as Node3D
	if _player == null:
		return
	_player.name = "Player"
	_player.position = Vector3(CHAPTER_ONE_PLAYER_START.x, _height_at(CHAPTER_ONE_PLAYER_START.x, CHAPTER_ONE_PLAYER_START.z) + 0.04, CHAPTER_ONE_PLAYER_START.z)
	_player.rotation.y = 0.0
	var visual_root := _player.get_node_or_null("VisualRoot") as Node3D
	if visual_root != null:
		visual_root.rotation.y = _yaw_toward(_player.position, CHAPTER_ONE_HOUSE_POSITION)
	_mark_generated(_player)
	add_child(_player)

func _create_chapter_one_village_house() -> void:
	var scene := load(VILLAGE_HOUSE_SCENE_PATH)
	if not scene is PackedScene:
		push_warning("Could not load village house model: %s" % VILLAGE_HOUSE_SCENE_PATH)
		return

	var house := Node3D.new()
	house.name = "ChapterOneVillageHouse"
	house.position = Vector3(CHAPTER_ONE_HOUSE_POSITION.x, _height_at(CHAPTER_ONE_HOUSE_POSITION.x, CHAPTER_ONE_HOUSE_POSITION.z), CHAPTER_ONE_HOUSE_POSITION.z)
	house.rotation.y = deg_to_rad(CHAPTER_ONE_HOUSE_YAW)
	_mark_generated(house)
	add_child(house)

	var model := scene.instantiate() as Node3D
	if model == null:
		return
	model.name = "VillageHouseModel"
	house.add_child(model)
	_fit_model_to_footprint_length(model, CHAPTER_ONE_HOUSE_TARGET_LENGTH)
	_ground_model(model)
	_set_model_shadow(model, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	_add_model_box_blocker(house, model, Vector2.ZERO, 0.56)

func _create_chapter_one_rebas() -> void:
	var scene := load(REBAS_SCENE_PATH)
	if not scene is PackedScene:
		push_warning("Could not load Rebas model: %s" % REBAS_SCENE_PATH)
		return

	var rebas := Node3D.new()
	rebas.name = "RebasCant"
	rebas.position = Vector3(CHAPTER_ONE_REBAS_POSITION.x, _height_at(CHAPTER_ONE_REBAS_POSITION.x, CHAPTER_ONE_REBAS_POSITION.z), CHAPTER_ONE_REBAS_POSITION.z)
	rebas.rotation.y = _yaw_toward(rebas.position, CHAPTER_ONE_PLAYER_START)
	_mark_generated(rebas)
	add_child(rebas)

	var model := scene.instantiate() as Node3D
	if model == null:
		return
	model.name = "RebasCantModel"
	rebas.add_child(model)
	_fit_model_to_height(model, CHAPTER_ONE_REBAS_TARGET_HEIGHT)
	_ground_model(model)
	_set_model_shadow(model, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	_add_circle_blocker(rebas.position, 1.0)

func _create_chapter_one_mom() -> void:
	_create_mom(CHAPTER_ONE_MOM_POSITION, CHAPTER_ONE_PLAYER_START)

func _create_camper(camper_position: Vector3 = CAMPER_POSITION, camper_yaw: float = deg_to_rad(162.0)) -> void:
	var scene := load(CAMPER_SCENE_PATH)
	if not scene is PackedScene:
		push_warning("Could not load camper model: %s" % CAMPER_SCENE_PATH)
		return

	var camper := Node3D.new()
	camper.name = "CamperVan"
	camper.position = Vector3(camper_position.x, _height_at(camper_position.x, camper_position.z), camper_position.z)
	camper.rotation.y = camper_yaw
	_camper = camper
	_mark_generated(camper)
	add_child(camper)

	var model := scene.instantiate() as Node3D
	if model == null:
		return
	model.name = "CamperModel"
	_camper_model = model
	camper.add_child(model)
	_fit_model_to_footprint_length(model, CAMPER_TARGET_LENGTH)
	_ground_model(model)
	_set_model_shadow(model, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	_add_camper_blocker(camper, model)

func _create_mom(mom_position: Vector3 = MOM_POSITION, face_target: Vector3 = PLAYER_START) -> void:
	var scene := load(MOM_SCENE_PATH)
	if not scene is PackedScene:
		push_warning("Could not load mom model: %s" % MOM_SCENE_PATH)
		return

	var mom := Node3D.new()
	mom.name = "Mom"
	mom.position = Vector3(mom_position.x, _height_at(mom_position.x, mom_position.z), mom_position.z)
	mom.rotation.y = _yaw_toward(mom.position, face_target) + MOM_FACE_PLAYER_OFFSET
	_mom = mom
	_mark_generated(mom)
	add_child(mom)

	var model := scene.instantiate() as Node3D
	if model == null:
		return
	model.name = "MomModel"
	model.scale = Vector3.ONE * MOM_MODEL_SCALE
	_mom_model = model
	mom.add_child(model)
	_ground_model(model)
	_set_model_shadow(model, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	_add_circle_blocker(mom.position, MOM_BLOCKER_RADIUS)
	_create_mom_exclamation()

func _create_mom_exclamation() -> void:
	if _mom == null:
		return
	var marker := Label3D.new()
	marker.name = "QuestExclamation"
	marker.text = "!"
	marker.position = Vector3(0.0, 3.75, 0.0)
	marker.font_size = 92
	marker.outline_size = 14
	marker.modulate = Color(1.0, 0.82, 0.24, 1.0)
	marker.outline_modulate = Color(0.56, 0.36, 0.10, 1.0)
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.no_depth_test = true
	marker.visible = not _dialogue_completed
	_mom_exclamation = marker
	_mom.add_child(marker)

func _create_dialogue_ui() -> void:
	_dialogue_steps = _build_mom_dialogue()
	_highlight_material = StandardMaterial3D.new()
	_highlight_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_highlight_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_highlight_material.albedo_color = Color(1.0, 1.0, 1.0, 0.34)

	_dialogue_layer = CanvasLayer.new()
	_dialogue_layer.name = "DialogueLayer"
	_mark_generated(_dialogue_layer)
	add_child(_dialogue_layer)

	var root := Control.new()
	root.name = "DialogueRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialogue_layer.add_child(root)
	_hud_root = root

	_interaction_prompt = PanelContainer.new()
	_interaction_prompt.name = "InteractionPrompt"
	_interaction_prompt.visible = false
	_interaction_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_interaction_prompt.anchor_left = 1.0
	_interaction_prompt.anchor_top = 1.0
	_interaction_prompt.anchor_right = 1.0
	_interaction_prompt.anchor_bottom = 1.0
	_interaction_prompt.offset_left = -330.0
	_interaction_prompt.offset_top = -70.0
	_interaction_prompt.offset_right = -24.0
	_interaction_prompt.offset_bottom = -22.0
	_interaction_prompt.add_theme_stylebox_override("panel", _make_round_style(Color(0.92, 0.84, 0.62, 0.94), Color(1.0, 0.95, 0.78, 1.0), 20.0, 1))
	root.add_child(_interaction_prompt)

	_interaction_prompt_label = Label.new()
	_interaction_prompt_label.text = "F / 点击  与 安提莉尔 对话"
	_interaction_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_interaction_prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_interaction_prompt_label.add_theme_color_override("font_color", Color(0.24, 0.18, 0.10))
	_interaction_prompt_label.add_theme_font_size_override("font_size", 18)
	_interaction_prompt.add_child(_interaction_prompt_label)

	_dialogue_panel = Control.new()
	_dialogue_panel.name = "DialoguePanel"
	_dialogue_panel.visible = false
	_dialogue_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dialogue_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_dialogue_panel.gui_input.connect(_on_dialogue_panel_gui_input)
	root.add_child(_dialogue_panel)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.18)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialogue_panel.add_child(dim)

	var box := TextureRect.new()
	box.name = "DialogueBox"
	box.texture = load(DIALOGUE_BOX_PATH)
	box.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	box.stretch_mode = TextureRect.STRETCH_SCALE
	box.anchor_left = 0.04
	box.anchor_top = 1.0
	box.anchor_right = 0.96
	box.anchor_bottom = 1.0
	box.offset_top = -285.0
	box.offset_bottom = -28.0
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialogue_panel.add_child(box)

	_dialogue_portrait = TextureRect.new()
	_dialogue_portrait.name = "Portrait"
	_dialogue_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_dialogue_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_dialogue_portrait.anchor_left = 0.055
	_dialogue_portrait.anchor_top = 1.0
	_dialogue_portrait.anchor_right = 0.285
	_dialogue_portrait.anchor_bottom = 1.0
	_dialogue_portrait.offset_top = -272.0
	_dialogue_portrait.offset_bottom = -30.0
	_dialogue_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialogue_panel.add_child(_dialogue_portrait)

	_dialogue_name = Label.new()
	_dialogue_name.anchor_left = 0.31
	_dialogue_name.anchor_top = 1.0
	_dialogue_name.anchor_right = 0.90
	_dialogue_name.anchor_bottom = 1.0
	_dialogue_name.offset_top = -238.0
	_dialogue_name.offset_bottom = -200.0
	_dialogue_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialogue_name.add_theme_color_override("font_color", Color(0.18, 0.13, 0.08))
	_dialogue_name.add_theme_font_size_override("font_size", 26)
	_dialogue_panel.add_child(_dialogue_name)

	_dialogue_body = Label.new()
	_dialogue_body.anchor_left = 0.31
	_dialogue_body.anchor_top = 1.0
	_dialogue_body.anchor_right = 0.90
	_dialogue_body.anchor_bottom = 1.0
	_dialogue_body.offset_top = -196.0
	_dialogue_body.offset_bottom = -58.0
	_dialogue_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialogue_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_body.add_theme_color_override("font_color", Color(0.24, 0.18, 0.12))
	_dialogue_body.add_theme_font_size_override("font_size", 22)
	_dialogue_panel.add_child(_dialogue_body)

	_dialogue_options = HBoxContainer.new()
	_dialogue_options.name = "Options"
	_dialogue_options.anchor_left = 0.24
	_dialogue_options.anchor_top = 1.0
	_dialogue_options.anchor_right = 0.76
	_dialogue_options.anchor_bottom = 1.0
	_dialogue_options.offset_top = -355.0
	_dialogue_options.offset_bottom = -305.0
	_dialogue_options.alignment = BoxContainer.ALIGNMENT_CENTER
	_dialogue_options.add_theme_constant_override("separation", 14)
	_dialogue_panel.add_child(_dialogue_options)

	var skip_button := Button.new()
	skip_button.text = "跳过"
	skip_button.anchor_left = 0.84
	skip_button.anchor_top = 1.0
	skip_button.anchor_right = 0.92
	skip_button.anchor_bottom = 1.0
	skip_button.offset_top = -270.0
	skip_button.offset_bottom = -228.0
	skip_button.add_theme_font_size_override("font_size", 18)
	skip_button.add_theme_color_override("font_color", Color(0.25, 0.18, 0.10))
	skip_button.add_theme_stylebox_override("normal", _make_round_style(Color(0.96, 0.87, 0.66, 0.94), Color(0.58, 0.42, 0.20, 0.42), 20.0, 1))
	skip_button.add_theme_stylebox_override("hover", _make_round_style(Color(1.0, 0.91, 0.70, 1.0), Color(0.58, 0.42, 0.20, 0.60), 20.0, 1))
	skip_button.pressed.connect(_skip_mom_dialogue)
	_dialogue_panel.add_child(skip_button)

	_create_map_popup(root)
	_create_inventory_bar(root)

func _create_map_popup(root: Control) -> void:
	_map_panel = Control.new()
	_map_panel.name = "MapPanel"
	_map_panel.visible = false
	_map_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_map_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_map_panel.gui_input.connect(_on_map_panel_gui_input)
	root.add_child(_map_panel)
	if _interaction_prompt != null:
		_interaction_prompt.move_to_front()

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.34)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_panel.add_child(dim)

	_map_popup = Control.new()
	_map_popup.name = "WorldMapPopup"
	_map_popup.anchor_left = 0.025
	_map_popup.anchor_top = 0.025
	_map_popup.anchor_right = 0.975
	_map_popup.anchor_bottom = 0.975
	_map_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_panel.add_child(_map_popup)

	var map_image := TextureRect.new()
	map_image.name = "MapImage"
	map_image.texture = load(WORLD_MAP_PATH)
	map_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	map_image.set_anchors_preset(Control.PRESET_FULL_RECT)
	map_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_popup.add_child(map_image)

	_map_village_label = Label.new()
	_map_village_label.text = "村庄"
	_map_village_label.modulate.a = 0.0
	_map_village_label.anchor_left = 0.0
	_map_village_label.anchor_top = 0.0
	_map_village_label.anchor_right = 0.0
	_map_village_label.anchor_bottom = 0.0
	_map_village_label.size = Vector2(150.0, 52.0)
	_map_village_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_map_village_label.add_theme_font_size_override("font_size", 34)
	_map_village_label.add_theme_color_override("font_color", Color(0.25, 0.18, 0.08))
	_map_popup.add_child(_map_village_label)

	_map_locked_label = Label.new()
	_map_locked_label.text = "此地暂未解锁"
	_map_locked_label.modulate.a = 0.0
	_map_locked_label.anchor_left = 0.0
	_map_locked_label.anchor_top = 0.0
	_map_locked_label.anchor_right = 0.0
	_map_locked_label.anchor_bottom = 0.0
	_map_locked_label.size = Vector2(260.0, 48.0)
	_map_locked_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_map_locked_label.add_theme_font_size_override("font_size", 28)
	_map_locked_label.add_theme_color_override("font_color", Color(0.28, 0.22, 0.15))
	_map_popup.add_child(_map_locked_label)

	_map_camper_marker = Control.new()
	_map_camper_marker.name = "MapCamperMarker"
	_map_camper_marker.size = Vector2(136.0, 96.0)
	_map_camper_marker.custom_minimum_size = Vector2(136.0, 96.0)
	_map_camper_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_popup.add_child(_map_camper_marker)
	_create_map_camper_icon()

	_position_map_camper()

func _create_inventory_bar(root: Control) -> void:
	_inventory_slots.clear()
	_inventory_bar = HBoxContainer.new()
	_inventory_bar.name = "InventoryBar"
	_inventory_bar.visible = _has_hoe
	_inventory_bar.anchor_left = 0.5
	_inventory_bar.anchor_top = 1.0
	_inventory_bar.anchor_right = 0.5
	_inventory_bar.anchor_bottom = 1.0
	_inventory_bar.offset_left = -318.0
	_inventory_bar.offset_top = -76.0
	_inventory_bar.offset_right = 318.0
	_inventory_bar.offset_bottom = -16.0
	_inventory_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	_inventory_bar.add_theme_constant_override("separation", 8)
	root.add_child(_inventory_bar)

	for index in range(10):
		var slot := PanelContainer.new()
		slot.name = "Slot%d" % (index + 1)
		slot.custom_minimum_size = Vector2(56.0, 56.0)
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		slot.gui_input.connect(_on_inventory_slot_gui_input.bind(index))
		_inventory_bar.add_child(slot)
		_inventory_slots.append(slot)

		var locked := index >= 5
		var label := Label.new()
		label.name = "SlotLabel"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 21)
		label.add_theme_color_override("font_color", Color(0.26, 0.18, 0.09) if not locked else Color(0.78, 0.71, 0.62))
		label.set_anchors_preset(Control.PRESET_FULL_RECT)
		slot.add_child(label)
	_update_inventory_bar()

func _update_inventory_bar() -> void:
	if _inventory_bar == null:
		return
	_inventory_bar.visible = _has_hoe
	for index in range(_inventory_slots.size()):
		var slot := _inventory_slots[index]
		var locked := index >= 5
		var selected := index == _selected_inventory_slot
		var fill := Color(0.98, 0.84, 0.48, 0.96) if selected else Color(0.92, 0.80, 0.58, 0.86)
		var border := Color(1.0, 0.98, 0.74, 1.0) if selected else Color(1.0, 0.94, 0.72, 0.96)
		if locked:
			fill = Color(0.40, 0.36, 0.30, 0.78)
			border = Color(0.64, 0.58, 0.49, 0.86)
		slot.add_theme_stylebox_override("panel", _make_round_style(fill, border, 8.0, 3 if selected else 2))
		var label := slot.get_node_or_null("SlotLabel") as Label
		if label == null:
			continue
		var icon := slot.get_node_or_null("HoeIcon") as TextureRect
		if index == 0 and _has_hoe:
			label.text = ""
			if icon == null:
				icon = _create_hoe_inventory_icon(slot)
			if icon != null:
				icon.visible = true
		elif index >= 5:
			if icon != null:
				icon.visible = false
			label.text = "锁"
		else:
			if icon != null:
				icon.visible = false
			label.text = ""

func _create_hoe_inventory_icon(slot: PanelContainer) -> TextureRect:
	var icon := TextureRect.new()
	icon.name = "HoeIcon"
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = -5.0
	icon.offset_top = -5.0
	icon.offset_right = 5.0
	icon.offset_bottom = 5.0
	slot.add_child(icon)
	slot.move_child(icon, 0)
	_setup_hoe_preview_viewport(icon, Vector2i(320, 320), false)
	return icon

func _on_inventory_slot_gui_input(event: InputEvent, slot_index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if slot_index < 5:
			_selected_inventory_slot = slot_index
			_update_inventory_bar()
			_try_use_selected_tool()
		get_viewport().set_input_as_handled()

func _select_inventory_delta(delta: int) -> void:
	if not _has_hoe:
		return
	_selected_inventory_slot = wrapi(_selected_inventory_slot + delta, 0, 5)
	_update_inventory_bar()

func _try_use_selected_tool() -> bool:
	if not _has_hoe or _selected_inventory_slot != 0 or _dialogue_open or _map_open or _hoe_swinging:
		return false
	_till_soil_in_front_of_player()
	return true

func _till_soil_in_front_of_player() -> void:
	if _player == null:
		return
	if _tilled_soil_root == null or not is_instance_valid(_tilled_soil_root):
		_tilled_soil_root = Node3D.new()
		_tilled_soil_root.name = "TilledSoilRoot"
		_mark_generated(_tilled_soil_root)
		add_child(_tilled_soil_root)
	_remove_soil_tiles_over_pond()
	var yaw := _get_player_visual_yaw()
	var forward := Vector3(sin(yaw), 0.0, cos(yaw))
	var center := _player.global_position + forward * 2.0
	center = _snap_soil_position(center)
	var center_2d := Vector2(center.x, center.z)
	if not _can_place_soil_tile(center):
		_show_notification("这里是水面，不能锄地")
		return
	_play_hoe_swing(yaw, center)
	for existing in _tilled_soil_centers:
		if existing.distance_squared_to(center_2d) <= 0.25:
			return
	_tilled_soil_centers.append(center_2d)
	var impact_timer := get_tree().create_timer(0.16)
	impact_timer.timeout.connect(_create_soil_patch.bind(center))

func _play_hoe_swing(yaw: float, target_center: Vector3) -> void:
	var scene := load(HOE_SCENE_PATH)
	if not scene is PackedScene or _player == null:
		return
	_hoe_swinging = true
	var forward := Vector3(sin(yaw), 0.0, cos(yaw))
	var right := Vector3(cos(yaw), 0.0, -sin(yaw))
	var root := Node3D.new()
	root.name = "HoeSwing"
	root.global_position = _player.global_position + right * 0.52 + forward * 0.58 + Vector3(0.0, 1.28, 0.0)
	root.rotation = Vector3(deg_to_rad(-18.0), yaw, deg_to_rad(-38.0))
	_player_hoe_root = root
	_mark_generated(root)
	add_child(root)

	var model := scene.instantiate() as Node3D
	if model == null:
		root.queue_free()
		_player_hoe_root = null
		_hoe_swinging = false
		return
	_player_hoe_model = model
	root.add_child(model)
	_fit_model_to_max_dimension(model, 2.0)
	_center_model_on_origin(model)
	model.position = Vector3(0.0, 0.0, -0.82)
	model.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	_set_model_shadow(model, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)

	var tween := create_tween()
	tween.tween_property(root, "global_position", target_center + Vector3(0.0, 0.92, 0.0), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(root, "rotation:x", deg_to_rad(-92.0), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_interval(0.08)
	tween.tween_property(root, "scale", Vector3.ZERO, 0.10)
	tween.finished.connect(_finish_hoe_swing.bind(root))

func _finish_hoe_swing(root: Node3D) -> void:
	if root != null and is_instance_valid(root):
		root.queue_free()
	if _player_hoe_root == root:
		_player_hoe_root = null
	_player_hoe_model = null
	_hoe_swinging = false

func _create_soil_patch(center: Vector3) -> void:
	_clear_grass_in_soil_patch(center)
	_remove_soil_tiles_over_pond()
	var grid_yaw := _soil_grid_yaw()
	var right := Vector2(cos(grid_yaw), -sin(grid_yaw))
	var forward := Vector2(sin(grid_yaw), cos(grid_yaw))
	for x in range(-1, 2):
		for z in range(-1, 2):
			var offset := right * float(x) + forward * float(z)
			var tile_position := Vector3(center.x + offset.x, 0.0, center.z + offset.y)
			if not _can_place_soil_tile(tile_position):
				continue
			_create_soil_tile(tile_position)

func _can_place_soil_tile(position: Vector3) -> bool:
	var grid_yaw := _soil_grid_yaw()
	for offset in [
		Vector2.ZERO,
		Vector2(-SOIL_TILE_HALF_SIZE, -SOIL_TILE_HALF_SIZE),
		Vector2(SOIL_TILE_HALF_SIZE, -SOIL_TILE_HALF_SIZE),
		Vector2(-SOIL_TILE_HALF_SIZE, SOIL_TILE_HALF_SIZE),
		Vector2(SOIL_TILE_HALF_SIZE, SOIL_TILE_HALF_SIZE),
		Vector2(0.0, -SOIL_TILE_HALF_SIZE),
		Vector2(0.0, SOIL_TILE_HALF_SIZE),
		Vector2(-SOIL_TILE_HALF_SIZE, 0.0),
		Vector2(SOIL_TILE_HALF_SIZE, 0.0),
	]:
		var rotated_offset := offset.rotated(-grid_yaw)
		if _is_inside_pond(position.x + rotated_offset.x, position.z + rotated_offset.y, SOIL_POND_EDGE_PADDING):
			return false
	return true

func _soil_grid_yaw() -> float:
	return deg_to_rad(CHAPTER_ONE_HOUSE_YAW) if _chapter_one_active else 0.0

func _snap_soil_position(position: Vector3) -> Vector3:
	var yaw := _soil_grid_yaw()
	var origin := Vector2(CHAPTER_ONE_HOUSE_POSITION.x, CHAPTER_ONE_HOUSE_POSITION.z) if _chapter_one_active else Vector2.ZERO
	var local := (Vector2(position.x, position.z) - origin).rotated(yaw)
	local.x = roundf(local.x)
	local.y = roundf(local.y)
	var snapped := origin + local.rotated(-yaw)
	return Vector3(snapped.x, position.y, snapped.y)

func _remove_soil_tiles_over_pond() -> void:
	if _tilled_soil_root == null or not is_instance_valid(_tilled_soil_root):
		return
	for child in _tilled_soil_root.get_children():
		if child is Node3D:
			var tile := child as Node3D
			if not _can_place_soil_tile(tile.global_position):
				tile.queue_free()

func _clear_grass_in_soil_patch(center: Vector3) -> void:
	if _grass_multimesh == null:
		return
	var half_size := 1.55
	var grid_yaw := _soil_grid_yaw()
	for index in range(_grass_multimesh.instance_count):
		var transform := _grass_multimesh.get_instance_transform(index)
		var origin := transform.origin
		var local := (Vector2(origin.x, origin.z) - Vector2(center.x, center.z)).rotated(grid_yaw)
		if absf(local.x) <= half_size and absf(local.y) <= half_size:
			transform.basis = transform.basis.scaled(Vector3.ZERO)
			_grass_multimesh.set_instance_transform(index, transform)

func _create_soil_tile(position: Vector3) -> void:
	if _tilled_soil_root == null:
		return
	var tile := MeshInstance3D.new()
	tile.name = "SoilTile"
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(0.96, 0.96)
	tile.mesh = mesh
	tile.position = Vector3(position.x, _height_at(position.x, position.z) + 0.018, position.z)
	tile.rotation.y = _soil_grid_yaw()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.72, 0.50, 0.25, 1.0)
	mat.roughness = 0.98
	tile.material_override = mat
	_tilled_soil_root.add_child(tile)

func _get_player_visual_yaw() -> float:
	if _player == null:
		return 0.0
	var visual_root := _player.get_node_or_null("VisualRoot") as Node3D
	if visual_root != null:
		return visual_root.global_rotation.y
	return _player.global_rotation.y

func _create_map_camper_icon() -> void:
	var sub_viewport := SubViewport.new()
	sub_viewport.size = Vector2i(192, 136)
	sub_viewport.transparent_bg = true
	sub_viewport.world_3d = World3D.new()
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_map_camper_marker.add_child(sub_viewport)

	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 2.8, 6.2)
	camera.current = true
	sub_viewport.add_child(camera)
	camera.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)

	var light := DirectionalLight3D.new()
	light.light_energy = 2.4
	light.rotation_degrees = Vector3(-45.0, -35.0, 0.0)
	sub_viewport.add_child(light)

	var scene := load(CAMPER_SCENE_PATH)
	if scene is PackedScene:
		var model := scene.instantiate() as Node3D
		if model != null:
			model.rotation.y = MAP_CAMPER_RIGHT_FACING_YAW
			_map_camper_model = model
			sub_viewport.add_child(model)
			_fit_model_to_footprint_length(model, 4.6)
			_ground_model(model)
			_set_model_shadow(model, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)

	_map_camper_icon = TextureRect.new()
	_map_camper_icon.texture = sub_viewport.get_texture()
	_map_camper_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_map_camper_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_map_camper_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	_map_camper_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_camper_marker.add_child(_map_camper_icon)

func _make_round_style(fill: Color, border: Color, radius: float, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(int(radius))
	return style

func _build_mom_dialogue() -> Array[Dictionary]:
	if _chapter_one_active:
		return [
			{
				"speaker": "安提莉尔",
				"portrait": MOM_PORTRAIT_PATH,
				"text": "先给地松松土吧，我给你把锄头找出来了",
			},
		]
	return [
		{
			"speaker": "安提莉尔",
			"portrait": MOM_PORTRAIT_PATH,
			"text": "前些天收到你的消息，我就一直放心不下。\n这一路赶过来，连面包都忘了从烤箱里拿出来。",
		},
		{
			"speaker": "安提莉尔",
			"portrait": MOM_PORTRAIT_PATH,
			"text": "快让我看看……\n嗯，比离开家的时候瘦了不少。",
		},
		{
			"speaker": "我",
			"portrait": PLAYER_PORTRAIT_PATH,
			"text": "你想怎么回答？",
			"options": ["路上有点累，见到你就好了", "以后会好好吃饭的", "我回来了，妈妈"],
		},
		{
			"speaker": "安提莉尔",
			"portrait": MOM_PORTRAIT_PATH,
			"text": "累了吧，回来就好。\n人总要出去看看远一点的地方才是。",
		},
		{
			"speaker": "安提莉尔",
			"portrait": MOM_PORTRAIT_PATH,
			"text": "现在也看完了，回来也挺好。\n家里的汤锅一直没换。",
		},
		{
			"speaker": "安提莉尔",
			"portrait": MOM_PORTRAIT_PATH,
			"text": "你小时候爱吃的东西，我也都还记得。\n哈哈。",
		},
		{
			"speaker": "我",
			"portrait": PLAYER_PORTRAIT_PATH,
			"text": "你想怎么回答？",
			"options": ["那我今天要吃两碗", "还是家里的味道最好", "这次换我帮你做饭"],
		},
		{
			"speaker": "安提莉尔",
			"portrait": MOM_PORTRAIT_PATH,
			"text": "哈哈，你看那边。\n那片草地还和以前一样。",
		},
		{
			"speaker": "安提莉尔",
			"portrait": MOM_PORTRAIT_PATH,
			"text": "春天会长出小白花，夏天的风总是很大。\n小时候你最喜欢跑过去。",
		},
		{
			"speaker": "安提莉尔",
			"portrait": MOM_PORTRAIT_PATH,
			"text": "一会儿追蝴蝶，一会儿躺在草地上发呆。\n有时候天黑了都不肯回家。",
		},
		{
			"speaker": "安提莉尔",
			"portrait": MOM_PORTRAIT_PATH,
			"text": "最后还得我提着灯去找你。\n哈哈。",
		},
		{
			"speaker": "我",
			"portrait": PLAYER_PORTRAIT_PATH,
			"text": "你想怎么回答？",
			"options": ["原来已经过了这么久", "这里一点都没变", "听你这么说，我又想起来了"],
		},
		{
			"speaker": "安提莉尔",
			"portrait": MOM_PORTRAIT_PATH,
			"text": "这些年村子其实还是变了不少。\n可有些东西倒是一直没变。",
		},
		{
			"speaker": "安提莉尔",
			"portrait": MOM_PORTRAIT_PATH,
			"text": "早晨的风，傍晚的晚霞。\n还有院子后面那块荒了的田。",
		},
		{
			"speaker": "安提莉尔",
			"portrait": MOM_PORTRAIT_PATH,
			"text": "我每天经过的时候都会看两眼。\n总觉得它还在等什么。",
		},
		{
			"speaker": "安提莉尔",
			"portrait": MOM_PORTRAIT_PATH,
			"text": "你先好好休息几天。\n等把觉睡饱了，再陪我去地里转转。",
		},
		{
			"speaker": "安提莉尔",
			"portrait": MOM_PORTRAIT_PATH,
			"text": "那块荒着的田，我一直没舍得种。\n总觉得……",
		},
		{
			"speaker": "安提莉尔",
			"portrait": MOM_PORTRAIT_PATH,
			"text": "该留给某个终于回家的孩子。",
		},
		{
			"speaker": "我",
			"portrait": PLAYER_PORTRAIT_PATH,
			"text": "你想怎么回答？",
			"options": ["好，我们一起种", "我想从第一块田开始", "这次我会好好照顾它"],
		},
		{
			"speaker": "安提莉尔",
			"portrait": MOM_PORTRAIT_PATH,
			"text": "那就这么说定了。\n等你准备好，挑个太阳出来的时候。",
		},
		{
			"speaker": "安提莉尔",
			"portrait": MOM_PORTRAIT_PATH,
			"text": "我带你去看看你小时候常在那儿捉蚂蚱的那块田。",
		},
		{
			"speaker": "安提莉尔",
			"portrait": MOM_PORTRAIT_PATH,
			"text": "从播下第一颗种子开始，慢慢适应村里的生活吧。",
		},
	]

func _update_mom_interaction() -> void:
	var mom_near := _is_player_near_mom() and not _dialogue_completed
	var camper_near := _is_player_near_camper() and not mom_near
	if _interaction_prompt_label != null:
		_interaction_prompt_label.text = "F / 点击  与 安提莉尔 对话" if mom_near else "F / 点击  进入房车地图"
	if _interaction_prompt != null:
		_interaction_prompt.visible = (mom_near or camper_near) and not _dialogue_open and not _map_open
	if mom_near != _mom_is_highlighted:
		_set_mom_highlight(mom_near)
	if camper_near != _camper_is_highlighted:
		_set_camper_highlight(camper_near)

func _update_mom_exclamation(delta: float) -> void:
	if _mom_exclamation == null:
		return
	var should_show := _mom != null and not _dialogue_completed and not _dialogue_open
	_mom_exclamation.visible = should_show
	if should_show:
		var bob := sin(Time.get_ticks_msec() * 0.004) * 0.12
		_mom_exclamation.position.y = 3.75 + bob

func _grant_hoe() -> void:
	if _has_hoe or _reward_overlay != null:
		return
	_show_hoe_reward_overlay()

func _show_notification(text: String) -> void:
	_notification_time = 3.0
	_notification_text = text
	if _interaction_prompt_label != null:
		_interaction_prompt_label.text = text
	if _interaction_prompt != null:
		_interaction_prompt.visible = true
		_interaction_prompt.move_to_front()

func _capture_player_position() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var pos := _player.global_position
	var text := "Vector3(%.3f, 0.0, %.3f)" % [pos.x, pos.z]
	var path := ProjectSettings.globalize_path("res://_last_player_position.txt")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_line(text)
		file.store_line("raw=%.6f,%.6f,%.6f" % [pos.x, pos.y, pos.z])
		file.close()
	print("Captured player position: %s" % text)
	_show_notification("已记录当前位置")

func _show_hoe_reward_overlay() -> void:
	if _hud_root == null:
		_collect_hoe_reward()
		return
	_reward_collecting = false
	_reward_overlay = Control.new()
	_reward_overlay.name = "HoeRewardOverlay"
	_reward_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_reward_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_reward_overlay.gui_input.connect(_on_reward_overlay_gui_input)
	_hud_root.add_child(_reward_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.70, 0.78, 0.78, 0.36)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reward_overlay.add_child(dim)

	var panel := PanelContainer.new()
	panel.name = "RewardPanel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 34.0
	panel.offset_top = 26.0
	panel.offset_right = -34.0
	panel.offset_bottom = -26.0
	panel.pivot_offset = get_viewport().get_visible_rect().size * 0.5
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _make_round_style(Color(0.94, 0.92, 0.84, 0.18), Color(1.0, 0.98, 0.84, 0.44), 10.0, 1))
	_reward_overlay.add_child(panel)
	_reward_panel = panel

	var stack := VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 8)
	panel.add_child(stack)

	var title := Label.new()
	title.text = "恭喜获得锄头"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.24, 0.15, 0.07))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(title)

	var view := TextureRect.new()
	view.name = "HoePreview"
	var viewport_size := get_viewport().get_visible_rect().size
	view.custom_minimum_size = Vector2(maxf(viewport_size.x - 140.0, 520.0), maxf(viewport_size.y - 210.0, 360.0))
	view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.mouse_filter = Control.MOUSE_FILTER_STOP
	view.gui_input.connect(_on_reward_overlay_gui_input)
	stack.add_child(view)
	_setup_hoe_preview_viewport(view, Vector2i(int(view.custom_minimum_size.x), int(view.custom_minimum_size.y)), true)

	var hint := Label.new()
	hint.text = "旋转查看锄头"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color(0.34, 0.28, 0.18))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(hint)

	var collect_button := Button.new()
	collect_button.text = "收进背包"
	collect_button.custom_minimum_size = Vector2(132.0, 42.0)
	collect_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	collect_button.add_theme_font_size_override("font_size", 18)
	collect_button.add_theme_color_override("font_color", Color(0.25, 0.18, 0.10))
	collect_button.add_theme_stylebox_override("normal", _make_round_style(Color(0.93, 0.80, 0.55, 0.96), Color(1.0, 0.94, 0.70, 1.0), 18.0, 2))
	collect_button.add_theme_stylebox_override("hover", _make_round_style(Color(0.98, 0.87, 0.62, 1.0), Color(1.0, 0.98, 0.80, 1.0), 18.0, 2))
	collect_button.add_theme_stylebox_override("pressed", _make_round_style(Color(0.82, 0.66, 0.40, 1.0), Color(0.98, 0.90, 0.66, 1.0), 18.0, 2))
	collect_button.pressed.connect(_collect_hoe_reward)
	stack.add_child(collect_button)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _setup_hoe_preview_viewport(target: TextureRect, size: Vector2i, interactive: bool) -> void:
	var sub_viewport := SubViewport.new()
	sub_viewport.size = size
	sub_viewport.transparent_bg = true
	sub_viewport.world_3d = World3D.new()
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	target.add_child(sub_viewport)
	target.texture = sub_viewport.get_texture()

	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	if interactive:
		camera.size = 6.8
		camera.position = Vector3(0.0, 0.0, 8.0)
	else:
		camera.size = 3.05
		camera.position = Vector3(0.0, 0.0, 7.0)
	camera.current = true
	sub_viewport.add_child(camera)
	camera.look_at(Vector3.ZERO, Vector3.UP)

	var light := DirectionalLight3D.new()
	light.light_energy = 2.8
	light.rotation_degrees = Vector3(-46.0, -35.0, 0.0)
	sub_viewport.add_child(light)

	var fill_light := OmniLight3D.new()
	fill_light.light_energy = 0.8
	fill_light.position = Vector3(1.6, 2.4, 2.2)
	sub_viewport.add_child(fill_light)

	var scene := load(HOE_SCENE_PATH)
	if not scene is PackedScene:
		return
	var root := Node3D.new()
	root.name = "HoePreviewRoot"
	sub_viewport.add_child(root)
	var model := scene.instantiate() as Node3D
	if model == null:
		return
	root.add_child(model)
	_fit_model_to_max_dimension(model, 5.2 if interactive else 4.05)
	_center_model_on_origin(model)
	model.rotation_degrees = Vector3(0.0 if interactive else 58.0, -35.0 if interactive else -24.0, 28.0 if interactive else -43.0)
	root.rotation_degrees = Vector3(0.0, 0.0, 0.0)
	if interactive:
		_reward_viewport = sub_viewport
		_reward_model_root = root

func _on_reward_overlay_gui_input(event: InputEvent) -> void:
	_handle_reward_overlay_input(event)

func _handle_reward_overlay_input(event: InputEvent) -> void:
	if _reward_overlay == null or _reward_collecting:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_reward_dragging = true
			_reward_press_position = event.position
			_reward_last_drag_position = event.position
		else:
			_reward_dragging = false
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _reward_dragging:
		var drag_delta: Vector2 = event.position - _reward_last_drag_position
		_reward_last_drag_position = event.position
		if _reward_model_root != null:
			_reward_model_root.rotation.y += drag_delta.x * 0.01
			_reward_model_root.rotation.x += drag_delta.y * 0.01
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_reward_dragging = true
			_reward_press_position = event.position
			_reward_last_drag_position = event.position
		else:
			_reward_dragging = false
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and _reward_dragging:
		var drag_delta: Vector2 = event.position - _reward_last_drag_position
		_reward_last_drag_position = event.position
		if _reward_model_root != null:
			_reward_model_root.rotation.y += drag_delta.x * 0.01
			_reward_model_root.rotation.x += drag_delta.y * 0.01
		get_viewport().set_input_as_handled()

func _collect_hoe_reward() -> void:
	if _reward_collecting:
		return
	_reward_collecting = true
	_has_hoe = true
	_selected_inventory_slot = 0
	_update_inventory_bar()
	if _inventory_bar != null:
		_inventory_bar.visible = true
	if _reward_overlay != null:
		var tween := create_tween()
		tween.set_parallel(true)
		if _reward_panel != null:
			var target := _get_inventory_slot_center(0)
			tween.tween_property(_reward_panel, "global_position", target - Vector2(26.0, 26.0), 0.36).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			tween.tween_property(_reward_panel, "scale", Vector2(0.12, 0.12), 0.36).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.tween_property(_reward_overlay, "modulate:a", 0.0, 0.34)
		tween.finished.connect(_finish_collect_hoe_reward)
		return
	_finish_collect_hoe_reward()

func _get_inventory_slot_center(index: int) -> Vector2:
	if index >= 0 and index < _inventory_slots.size():
		var slot := _inventory_slots[index]
		return slot.global_position + slot.size * 0.5
	var viewport_size := get_viewport().get_visible_rect().size
	return Vector2(viewport_size.x * 0.5, viewport_size.y - 46.0)

func _finish_collect_hoe_reward() -> void:
	if _reward_overlay != null:
		_reward_overlay.queue_free()
	_reward_overlay = null
	_reward_panel = null
	_reward_viewport = null
	_reward_model_root = null
	_reward_dragging = false
	_reward_press_position = Vector2.ZERO
	_reward_collecting = false
	_show_notification("获得锄头")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _update_notification(delta: float) -> void:
	if _notification_time <= 0.0:
		return
	_notification_time = maxf(_notification_time - delta, 0.0)
	if _interaction_prompt_label != null:
		_interaction_prompt_label.text = _notification_text
	if _interaction_prompt != null:
		_interaction_prompt.visible = true
		_interaction_prompt.move_to_front()
	if _notification_time <= 0.0 and _interaction_prompt != null:
		_interaction_prompt.visible = false
		_notification_text = ""

func _refresh_interaction_prompt_text() -> void:
	if _interaction_prompt_label == null or _notification_time > 0.0 or _dialogue_open or _map_open:
		return
	var mom_near := _is_player_near_mom() and not _dialogue_completed
	if mom_near:
		_interaction_prompt_label.text = "F / 点击  与 安提莉尔 对话"
	elif _is_player_near_camper():
		_interaction_prompt_label.text = "F / 点击  进入房车地图"

func _update_camper_interaction() -> void:
	if _mom_is_highlighted:
		_set_mom_highlight(false)
	var is_near := _is_player_near_camper()
	if _interaction_prompt_label != null:
		_interaction_prompt_label.text = "F / 点击  进入房车地图"
	if _interaction_prompt != null:
		_interaction_prompt.visible = is_near and not _dialogue_open and not _map_open
	if is_near != _camper_is_highlighted:
		_set_camper_highlight(is_near)

func _is_player_near_camper() -> bool:
	if _player == null or _camper == null:
		return false
	var player_point := Vector2(_player.global_position.x, _player.global_position.z)
	var camper_point := Vector2(_camper.global_position.x, _camper.global_position.z)
	return player_point.distance_squared_to(camper_point) <= CAMPER_INTERACT_RADIUS * CAMPER_INTERACT_RADIUS

func _try_enter_camper() -> bool:
	if not _dialogue_completed and _is_player_near_mom():
		return false
	if not _is_player_near_camper():
		return false
	_open_map_popup()
	return true

func _set_camper_highlight(enabled: bool) -> void:
	_camper_is_highlighted = enabled
	if _camper_model == null:
		return
	for mesh_instance in _collect_mesh_instances(_camper_model):
		mesh_instance.material_overlay = _highlight_material if enabled else null

func _open_map_popup() -> void:
	_map_open = true
	_map_camper_pos = MAP_CAMPER_START
	_map_village_label_time = 0.0
	_map_was_near_village = false
	_map_locked_label_time = 0.0
	_map_locked_site_index = -1
	_map_dragging = false
	_map_drag_vector = Vector2.ZERO
	if _map_village_label != null:
		_map_village_label.modulate.a = 0.0
	if _map_locked_label != null:
		_map_locked_label.modulate.a = 0.0
	_position_map_camper()
	if _map_panel != null:
		_map_panel.visible = true
		call_deferred("_position_map_camper")
	if _interaction_prompt != null:
		_interaction_prompt.visible = true
		_interaction_prompt.move_to_front()
	if _interaction_prompt_label != null:
		_interaction_prompt_label.text = "WASD / 滑动  开往村庄"
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _close_map_popup() -> void:
	_map_open = false
	if _map_panel != null:
		_map_panel.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _update_map_popup(delta: float) -> void:
	_position_map_camper()
	var move_dir := _get_map_move_direction()
	if move_dir.length_squared() > 0.0:
		move_dir = move_dir.normalized()
		_map_camper_pos += move_dir * MAP_CAMPER_SPEED * delta
		_map_camper_pos.x = clampf(_map_camper_pos.x, 0.035, 0.965)
		_map_camper_pos.y = clampf(_map_camper_pos.y, 0.08, 0.90)
		_update_map_camper_heading(move_dir)
	var near_village := _is_map_camper_near_village()
	var locked_site_index := -1 if near_village else _get_near_locked_site_index()
	var near_locked_site := locked_site_index >= 0
	if near_village:
		if not _map_was_near_village:
			_map_village_label_time = 0.0
			if _map_village_label != null:
				_map_village_label.modulate.a = 0.0
		_map_village_label_time += delta
	_map_was_near_village = near_village
	if _map_village_label != null:
		var target_alpha := 1.0 if near_village else 0.0
		_map_village_label.modulate.a = move_toward(_map_village_label.modulate.a, target_alpha, delta * 1.9)
	if near_locked_site:
		if locked_site_index != _map_locked_site_index:
			_map_locked_label_time = 0.0
			if _map_locked_label != null:
				_map_locked_label.modulate.a = 0.0
		_map_locked_label_time += delta
	_map_locked_site_index = locked_site_index
	if _map_locked_label != null:
		var locked_target_alpha := 1.0 if near_locked_site else 0.0
		_map_locked_label.modulate.a = move_toward(_map_locked_label.modulate.a, locked_target_alpha, delta * 1.9)
	if _interaction_prompt_label != null:
		if near_village:
			_interaction_prompt_label.text = "F / 点击  进入村庄"
		elif near_locked_site:
			_interaction_prompt_label.text = "此地暂未解锁"
		else:
			_interaction_prompt_label.text = "WASD / 滑动  开往村庄"
	if _interaction_prompt != null:
		_interaction_prompt.visible = true
		_interaction_prompt.move_to_front()

func _get_map_move_direction() -> Vector2:
	var move_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		move_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		move_dir.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		move_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		move_dir.y += 1.0
	if move_dir.length_squared() > 0.0:
		return move_dir
	return _map_drag_vector

func _update_map_camper_heading(move_dir: Vector2) -> void:
	if _map_camper_model == null:
		return
	var target_yaw := atan2(move_dir.x, move_dir.y) + MAP_CAMPER_YAW_OFFSET
	_map_camper_model.rotation.y = lerp_angle(_map_camper_model.rotation.y, target_yaw, 0.22)

func _position_map_camper() -> void:
	if _map_popup == null:
		return
	var popup_size := _map_popup.size
	if _map_camper_marker != null:
		var marker_size := Vector2(136.0, 96.0)
		_map_camper_marker.position = popup_size * _map_camper_pos - marker_size * 0.5
	if _map_village_label != null:
		var appear_lift := lerpf(18.0, 0.0, clampf(_map_village_label_time * 1.35, 0.0, 1.0))
		var idle_float := sin(_map_village_label_time * 2.2) * 2.0
		_map_village_label.position = popup_size * MAP_VILLAGE_LABEL_POINT + Vector2(-75.0, -64.0 + appear_lift + idle_float)
	if _map_locked_label != null and _map_locked_site_index >= 0 and _map_locked_site_index < MAP_LOCKED_LABEL_POINTS.size():
		var locked_appear_lift := lerpf(16.0, 0.0, clampf(_map_locked_label_time * 1.35, 0.0, 1.0))
		var locked_idle_float := sin(_map_locked_label_time * 2.2) * 2.0
		_map_locked_label.position = popup_size * MAP_LOCKED_LABEL_POINTS[_map_locked_site_index] + Vector2(-130.0, -46.0 + locked_appear_lift + locked_idle_float)

func _is_map_camper_near_village() -> bool:
	return _map_camper_pos.distance_squared_to(MAP_VILLAGE_POINT) <= MAP_VILLAGE_RADIUS * MAP_VILLAGE_RADIUS

func _get_near_locked_site_index() -> int:
	for i in range(MAP_LOCKED_SITE_POINTS.size()):
		var site_point: Vector2 = MAP_LOCKED_SITE_POINTS[i]
		if _map_camper_pos.distance_squared_to(site_point) <= MAP_LOCKED_SITE_RADIUS * MAP_LOCKED_SITE_RADIUS:
			return i
	return -1

func _handle_map_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_close_map_popup()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_F:
		_try_enter_village()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not _try_enter_village():
			_start_map_drag(event.position)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_stop_map_drag()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion and _map_dragging:
		_update_map_drag(event.position)
		get_viewport().set_input_as_handled()
	if event is InputEventScreenTouch:
		if event.pressed:
			if not _try_enter_village():
				_start_map_drag(event.position)
		else:
			_stop_map_drag()
		get_viewport().set_input_as_handled()
	if event is InputEventScreenDrag:
		_update_map_drag(event.position)
		get_viewport().set_input_as_handled()

func _on_map_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not _try_enter_village():
			_start_map_drag(event.position)
		get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_stop_map_drag()
		get_viewport().set_input_as_handled()
	if event is InputEventMouseMotion and _map_dragging:
		_update_map_drag(event.position)
		get_viewport().set_input_as_handled()
	if event is InputEventScreenTouch:
		if event.pressed:
			if not _try_enter_village():
				_start_map_drag(event.position)
		else:
			_stop_map_drag()
		get_viewport().set_input_as_handled()
	if event is InputEventScreenDrag:
		_update_map_drag(event.position)
		get_viewport().set_input_as_handled()

func _try_enter_village() -> bool:
	if not _map_open or not _is_map_camper_near_village():
		return false
	if _interaction_prompt_label != null:
		_interaction_prompt_label.text = "已进入村庄"
	if _interaction_prompt != null:
		_interaction_prompt.visible = true
	_close_map_popup()
	_start_chapter_one_transition()
	return true

func _start_chapter_one_transition() -> void:
	if _chapter_transitioning:
		return
	_chapter_transitioning = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	var transition_layer := CanvasLayer.new()
	transition_layer.name = "ChapterTransitionLayer"
	transition_layer.layer = 100
	add_child(transition_layer)

	var overlay := ColorRect.new()
	overlay.name = "BlackFade"
	overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	transition_layer.add_child(overlay)

	var title := Label.new()
	title.name = "ChapterTitle"
	title.text = "Chapter 1: 新的开始"
	title.modulate.a = 0.0
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_FULL_RECT)
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	transition_layer.add_child(title)

	var tween := create_tween()
	tween.tween_property(overlay, "color:a", 1.0, 1.2)
	await tween.finished

	var title_tween := create_tween()
	title_tween.tween_property(title, "modulate:a", 1.0, 0.85)
	await title_tween.finished
	await get_tree().create_timer(2.3).timeout

	_build_chapter_one_scene()

	var title_out := create_tween()
	title_out.tween_property(title, "modulate:a", 0.0, 0.6)
	await title_out.finished

	var fade_out := create_tween()
	fade_out.tween_property(overlay, "color:a", 0.0, 2.4)
	await fade_out.finished

	transition_layer.queue_free()
	_chapter_transitioning = false
	_apply_camera()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _build_chapter_one_scene() -> void:
	_chapter_one_active = true
	_active_ponds = CHAPTER_ONE_PONDS.duplicate(true)
	_grass_material = null
	_grass_multimesh = null
	_hud_root = null
	_camper = null
	_camper_model = null
	_map_camper_model = null
	_mom = null
	_mom_model = null
	_mom_exclamation = null
	_mom_is_highlighted = false
	_dialogue_open = false
	_dialogue_index = 0
	_dialogue_completed = false
	_map_open = false
	_camper_is_highlighted = false
	_has_hoe = false
	_selected_inventory_slot = 0
	_reward_overlay = null
	_reward_panel = null
	_reward_viewport = null
	_reward_model_root = null
	_reward_dragging = false
	_reward_collecting = false
	_notification_time = 0.0
	_tilled_soil_root = null
	_tilled_soil_centers.clear()
	_player_hoe_root = null
	_player_hoe_model = null
	_hoe_swinging = false
	_typewriter_time = 0.0
	_typewriter_total = 0
	_solid_blockers.clear()
	_wind_trees.clear()
	_clear_generated()
	_setup_world()
	_create_visible_sun()
	_create_background_clouds()
	_create_falling_petals()
	_create_terrain()
	_create_ponds()
	_create_ground_petals()
	_create_grass()
	_create_background_trees()
	_create_asset_trees()
	_create_chapter_one_village_house()
	_create_camper(CHAPTER_ONE_CAMPER_POSITION, deg_to_rad(CHAPTER_ONE_CAMPER_YAW))
	_create_chapter_one_mom()
	_create_chapter_one_rebas()
	_create_chapter_one_player()
	_orbit = Vector2(PI, 0.38)
	_zoom = 15.5
	_create_camera()
	_create_dialogue_ui()
	if _interaction_prompt != null:
		_interaction_prompt.visible = false

func _start_map_drag(screen_position: Vector2) -> void:
	_map_dragging = true
	_map_drag_start = screen_position
	_map_drag_vector = Vector2.ZERO

func _update_map_drag(screen_position: Vector2) -> void:
	var drag_offset := screen_position - _map_drag_start
	if drag_offset.length() < 12.0:
		_map_drag_vector = Vector2.ZERO
		return
	_map_drag_vector = drag_offset.normalized()

func _stop_map_drag() -> void:
	_map_dragging = false
	_map_drag_vector = Vector2.ZERO

func _is_player_near_mom() -> bool:
	if _player == null or _mom == null:
		return false
	var player_point := Vector2(_player.global_position.x, _player.global_position.z)
	var mom_point := Vector2(_mom.global_position.x, _mom.global_position.z)
	return player_point.distance_squared_to(mom_point) <= MOM_INTERACT_RADIUS * MOM_INTERACT_RADIUS

func _set_mom_highlight(enabled: bool) -> void:
	_mom_is_highlighted = enabled
	if _mom_model == null:
		return
	for mesh_instance in _collect_mesh_instances(_mom_model):
		mesh_instance.material_overlay = _highlight_material if enabled else null

func _try_start_mom_dialogue() -> bool:
	if _dialogue_completed:
		return false
	if _dialogue_open:
		_advance_dialogue()
		return true
	if not _is_player_near_mom():
		return false
	_start_mom_dialogue()
	return true

func _start_mom_dialogue() -> void:
	_dialogue_open = true
	_dialogue_index = 0
	_set_mom_highlight(false)
	if _dialogue_panel != null:
		_dialogue_panel.visible = true
	if _interaction_prompt != null:
		_interaction_prompt.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_show_dialogue_step()

func _close_dialogue(completed: bool = false) -> void:
	_dialogue_open = false
	if completed:
		_dialogue_completed = true
		_set_mom_highlight(false)
		if _chapter_one_active and not _has_hoe:
			_grant_hoe()
	if _dialogue_panel != null:
		_dialogue_panel.visible = false
	if _interaction_prompt != null:
		_interaction_prompt.visible = false
	_clear_dialogue_options()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _advance_dialogue() -> void:
	if not _dialogue_open:
		return
	if not _is_dialogue_text_finished():
		_finish_dialogue_typewriter()
		return
	if _dialogue_index < _dialogue_steps.size():
		var step := _dialogue_steps[_dialogue_index]
		if step.has("options"):
			return
	_dialogue_index += 1
	if _dialogue_index >= _dialogue_steps.size():
		_close_dialogue(true)
		return
	_show_dialogue_step()

func _choose_dialogue_option(_option_index: int) -> void:
	if not _dialogue_open:
		return
	if not _is_dialogue_text_finished():
		_finish_dialogue_typewriter()
		return
	_dialogue_index += 1
	if _dialogue_index >= _dialogue_steps.size():
		_close_dialogue(true)
		return
	_show_dialogue_step()

func _skip_mom_dialogue() -> void:
	if not _dialogue_open:
		return
	_close_dialogue(true)

func _on_dialogue_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		_advance_dialogue()

func _load_portrait_texture(path: String) -> Texture2D:
	var base_texture := load(path) as Texture2D
	if base_texture == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = base_texture
	atlas.region = Rect2(430.0, 40.0, 780.0, 984.0)
	return atlas

func _show_dialogue_step() -> void:
	if _dialogue_index < 0 or _dialogue_index >= _dialogue_steps.size():
		_close_dialogue(true)
		return
	var step := _dialogue_steps[_dialogue_index]
	_dialogue_name.text = str(step["speaker"])
	_dialogue_body.text = str(step["text"])
	_typewriter_time = 0.0
	_typewriter_total = _dialogue_body.get_total_character_count()
	_dialogue_body.visible_characters = 0
	_dialogue_portrait.texture = _load_portrait_texture(str(step["portrait"]))
	_clear_dialogue_options()
	if step.has("options"):
		var options: Array = step["options"]
		for option_index in range(options.size()):
			var option_button := Button.new()
			option_button.text = str(options[option_index])
			option_button.custom_minimum_size = Vector2(188.0, 48.0)
			option_button.add_theme_font_size_override("font_size", 19)
			option_button.add_theme_color_override("font_color", Color(0.24, 0.16, 0.06))
			option_button.add_theme_stylebox_override("normal", _make_round_style(Color(0.96, 0.84, 0.55, 0.96), Color(0.55, 0.39, 0.18, 0.38), 22.0, 1))
			option_button.add_theme_stylebox_override("hover", _make_round_style(Color(1.0, 0.90, 0.66, 1.0), Color(0.55, 0.39, 0.18, 0.56), 22.0, 1))
			option_button.add_theme_stylebox_override("pressed", _make_round_style(Color(0.88, 0.72, 0.42, 1.0), Color(0.48, 0.33, 0.14, 0.62), 22.0, 1))
			option_button.pressed.connect(_choose_dialogue_option.bind(option_index))
			option_button.visible = false
			_dialogue_options.add_child(option_button)

func _update_dialogue_typewriter(delta: float) -> void:
	if _dialogue_body == null or _typewriter_total <= 0:
		return
	if _dialogue_body.visible_characters >= _typewriter_total:
		_show_dialogue_options(true)
		return
	_typewriter_time += delta * DIALOGUE_CHARS_PER_SECOND
	_dialogue_body.visible_characters = mini(int(_typewriter_time), _typewriter_total)
	if _dialogue_body.visible_characters >= _typewriter_total:
		_show_dialogue_options(true)

func _is_dialogue_text_finished() -> bool:
	return _dialogue_body == null or _typewriter_total <= 0 or _dialogue_body.visible_characters >= _typewriter_total

func _finish_dialogue_typewriter() -> void:
	if _dialogue_body == null:
		return
	_dialogue_body.visible_characters = _typewriter_total
	_show_dialogue_options(true)

func _show_dialogue_options(visible: bool) -> void:
	if _dialogue_options == null:
		return
	for child in _dialogue_options.get_children():
		if child is CanvasItem:
			child.visible = visible

func _clear_dialogue_options() -> void:
	if _dialogue_options == null:
		return
	for child in _dialogue_options.get_children():
		child.queue_free()

func _is_dialogue_open() -> bool:
	return _dialogue_open

func _is_map_open() -> bool:
	return _map_open

func _is_chapter_transitioning() -> bool:
	return _chapter_transitioning

func _fit_model_to_height(model: Node3D, target_height: float) -> void:
	var bounds := _get_model_bounds(model)
	if bounds.size.y <= 0.001:
		return
	var factor := target_height / bounds.size.y
	model.scale *= factor

func _fit_model_to_max_dimension(model: Node3D, target_size: float) -> void:
	var bounds := _get_model_bounds(model)
	var max_dimension := maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
	if max_dimension <= 0.001:
		return
	var factor := target_size / max_dimension
	model.scale *= factor

func _fit_model_to_footprint_length(model: Node3D, target_length: float) -> void:
	var bounds := _get_model_bounds(model)
	var footprint_length := maxf(bounds.size.x, bounds.size.z)
	if footprint_length <= 0.001:
		return
	var factor := target_length / footprint_length
	model.scale *= factor

func _ground_model(model: Node3D) -> void:
	var bounds := _get_model_bounds(model)
	model.position.y -= bounds.position.y * model.scale.y

func _center_model_on_origin(model: Node3D) -> void:
	var bounds := _get_model_bounds(model)
	var center := bounds.get_center()
	model.position -= Vector3(center.x * model.scale.x, center.y * model.scale.y, center.z * model.scale.z)

func _set_model_shadow(model: Node3D, mode: int) -> void:
	for mesh_instance in _collect_mesh_instances(model):
		mesh_instance.cast_shadow = mode
		_stabilize_imported_materials(mesh_instance)

func _stabilize_imported_materials(mesh_instance: MeshInstance3D) -> void:
	var mesh := mesh_instance.mesh
	if mesh == null:
		return
	for surface_index in range(mesh.get_surface_count()):
		var material := mesh.surface_get_material(surface_index)
		if material is BaseMaterial3D:
			var base_material := material as BaseMaterial3D
			base_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
			base_material.alpha_antialiasing_mode = BaseMaterial3D.ALPHA_ANTIALIASING_OFF
			base_material.no_depth_test = false
			base_material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY

func _yaw_toward(from_position: Vector3, to_position: Vector3) -> float:
	var direction := to_position - from_position
	direction.y = 0.0
	if direction.length_squared() <= 0.0001:
		return 0.0
	direction = direction.normalized()
	return atan2(direction.x, direction.z)

func _add_camper_blocker(camper: Node3D, model: Node3D) -> void:
	var bounds := _get_model_bounds(model)
	var center_local := bounds.get_center()
	var center_world := model.global_transform * center_local
	var half_extents := Vector2(
		maxf(bounds.size.x * model.scale.x * 0.5 * CAMPER_BLOCKER_SHRINK + CAMPER_BLOCKER_PADDING.x, 0.9),
		maxf(bounds.size.z * model.scale.z * 0.5 * CAMPER_BLOCKER_SHRINK + CAMPER_BLOCKER_PADDING.y, 1.45)
	)
	_solid_blockers.append({
		"shape": "box",
		"center": center_world,
		"yaw": camper.rotation.y,
		"half_extents": half_extents,
	})

func _add_circle_blocker(center: Vector3, radius: float) -> void:
	_solid_blockers.append({
		"shape": "circle",
		"center": center,
		"radius": radius,
	})

func _add_model_box_blocker(root: Node3D, model: Node3D, padding: Vector2, shrink: float = 1.0) -> void:
	var bounds := _get_model_bounds(model)
	var center_local := bounds.get_center()
	var center_world := model.global_transform * center_local
	var half_extents := Vector2(
		maxf(bounds.size.x * model.scale.x * 0.5 * shrink + padding.x, 0.8),
		maxf(bounds.size.z * model.scale.z * 0.5 * shrink + padding.y, 0.8)
	)
	_solid_blockers.append({
		"shape": "box",
		"center": center_world,
		"yaw": root.rotation.y,
		"half_extents": half_extents,
	})

func _add_tree_blocker(center: Vector3, radius: float, tree_index: int) -> void:
	_solid_blockers.append({
		"shape": "tree",
		"center": center,
		"radius": radius,
		"tree_index": tree_index,
	})

func _handle_solid_bump(world_position: Vector3) -> bool:
	var point := Vector2(world_position.x, world_position.z)
	for blocker in _solid_blockers:
		var shape: String = blocker["shape"]
		var center_3d: Vector3 = blocker["center"]
		var center := Vector2(center_3d.x, center_3d.z)
		if shape == "tree":
			var radius: float = blocker["radius"]
			if point.distance_squared_to(center) <= radius * radius:
				_shake_tree(int(blocker["tree_index"]), point - center)
				return true
		elif _is_point_inside_blocker(point, blocker):
			return true
	return false

func _shake_tree(tree_index: int, impact_offset: Vector2) -> void:
	if tree_index < 0 or tree_index >= _wind_trees.size():
		return
	var shake_axis := impact_offset
	if shake_axis.length_squared() <= 0.0001:
		shake_axis = Vector2.RIGHT
	else:
		shake_axis = shake_axis.normalized()
	_wind_trees[tree_index]["shake_time"] = TREE_SHAKE_DURATION
	_wind_trees[tree_index]["shake_axis"] = shake_axis

func _shake_nearby_tree() -> bool:
	if _player == null:
		return false
	var player_point := Vector2(_player.global_position.x, _player.global_position.z)
	var closest_index := -1
	var closest_offset := Vector2.ZERO
	var closest_distance_sq := TREE_CLICK_SHAKE_RADIUS * TREE_CLICK_SHAKE_RADIUS
	for index in range(_wind_trees.size()):
		var tree := _wind_trees[index]["node"] as Node3D
		if tree == null:
			continue
		var tree_point := Vector2(tree.global_position.x, tree.global_position.z)
		var offset := player_point - tree_point
		var distance_sq := offset.length_squared()
		if distance_sq <= closest_distance_sq:
			closest_distance_sq = distance_sq
			closest_index = index
			closest_offset = offset
	if closest_index == -1:
		return false
	_shake_tree(closest_index, closest_offset)
	return true

func _is_blocked_by_solid(world_position: Vector3) -> bool:
	var point := Vector2(world_position.x, world_position.z)
	for blocker in _solid_blockers:
		if _is_point_inside_blocker(point, blocker):
			return true
	return false

func _is_point_inside_blocker(point: Vector2, blocker: Dictionary) -> bool:
	var shape: String = blocker["shape"]
	var center_3d: Vector3 = blocker["center"]
	var center := Vector2(center_3d.x, center_3d.z)
	if shape == "box":
		var yaw: float = blocker["yaw"]
		var half_extents: Vector2 = blocker["half_extents"]
		var local := (point - center).rotated(-yaw)
		return absf(local.x) <= half_extents.x and absf(local.y) <= half_extents.y
	elif shape == "circle" or shape == "tree":
		var radius: float = blocker["radius"]
		return point.distance_squared_to(center) <= radius * radius
	return false

func _get_model_bounds(model: Node3D) -> AABB:
	var has_bounds := false
	var bounds := AABB()
	var model_to_local := model.global_transform.affine_inverse()
	for mesh_instance in _collect_mesh_instances(model):
		var mesh_bounds: AABB = mesh_instance.get_aabb()
		for corner in _aabb_corners(mesh_bounds):
			var local_point := model_to_local * (mesh_instance.global_transform * corner)
			if not has_bounds:
				bounds = AABB(local_point, Vector3.ZERO)
				has_bounds = true
			else:
				bounds = bounds.expand(local_point)
	return bounds

func _collect_mesh_instances(root: Node) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	if root is MeshInstance3D:
		meshes.append(root)
	for child in root.get_children():
		meshes.append_array(_collect_mesh_instances(child))
	return meshes

func _aabb_corners(bounds: AABB) -> Array[Vector3]:
	var p := bounds.position
	var s := bounds.size
	return [
		p,
		p + Vector3(s.x, 0.0, 0.0),
		p + Vector3(0.0, s.y, 0.0),
		p + Vector3(0.0, 0.0, s.z),
		p + Vector3(s.x, s.y, 0.0),
		p + Vector3(s.x, 0.0, s.z),
		p + Vector3(0.0, s.y, s.z),
		p + s,
	]

func _create_camera() -> void:
	_camera_pivot = Node3D.new()
	_camera_pivot.name = "CameraPivot"
	_mark_generated(_camera_pivot)
	add_child(_camera_pivot)

	_camera = Camera3D.new()
	_camera.name = "Camera"
	_camera.fov = 48.0
	_camera.near = 0.04
	_camera.current = true
	_camera_pivot.add_child(_camera)
	_apply_camera()

func _update_camera_input(delta: float) -> void:
	var zoom_speed := 7.5
	if Input.is_key_pressed(KEY_Q):
		_zoom = clampf(_zoom + zoom_speed * delta, 9.0, 26.0)
	if Input.is_key_pressed(KEY_E):
		_zoom = clampf(_zoom - zoom_speed * delta, 9.0, 26.0)
	_apply_camera()

func get_camera_yaw() -> float:
	return _orbit.x

func _apply_camera() -> void:
	if _camera_pivot == null or _camera == null:
		return
	var follow_target := Vector3.ZERO
	if _player != null and is_instance_valid(_player):
		follow_target = _player.global_position
	var target := follow_target + Vector3(0.0, 1.15, 0.0)
	var distance := cos(_orbit.y) * _zoom
	var height := sin(_orbit.y) * _zoom + 1.1
	var eye_offset := Vector3(0.0, height, -distance).rotated(Vector3.UP, _orbit.x)
	var eye := follow_target + eye_offset
	_camera.global_position = eye
	_camera.look_at(target, Vector3.UP)

func _height_at(x: float, z: float) -> float:
	var rolling := sin(x * 0.026 + z * 0.014) * 1.35
	var cross_slope := cos(x * 0.018 - z * 0.024 + 1.2) * 0.95
	var meadow := sin(x * 0.056) * 0.42 + cos(z * 0.049) * 0.38
	var small := sin((x + z) * 0.105) * 0.16
	return rolling + cross_slope + meadow + small

func _normal_at(x: float, z: float) -> Vector3:
	var sample_distance := 1.0
	var left := _height_at(x - sample_distance, z)
	var right := _height_at(x + sample_distance, z)
	var back := _height_at(x, z - sample_distance)
	var front := _height_at(x, z + sample_distance)
	return Vector3(left - right, sample_distance * 2.0, back - front).normalized()
