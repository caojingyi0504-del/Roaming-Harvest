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
const TREE_SCENE_PATH := "res://3d建模/树/2f5d6b66e5b0fbbf4c7b1bede79477f5.glb"
const MOM_PORTRAIT_PATH := "res://聊天框/安提莉尔.png"
const PLAYER_PORTRAIT_PATH := "res://聊天框/我.png"
const DIALOGUE_BOX_PATH := "res://聊天框/聊天框.png"
const WORLD_MAP_PATH := "res://地图/b47063e2-0274-40a4-817d-c408c0418cd0.png"
const PLAYER_START := Vector3(0.0, 0.0, -26.0)
const CAMPER_POSITION := Vector3(0.0, 0.0, 10.0)
const MOM_POSITION := Vector3(0.0, 0.0, -4.0)
const CAMPER_TARGET_LENGTH := 8.8
const CAMPER_BLOCKER_PADDING := Vector2(0.12, 0.16)
const MOM_MODEL_SCALE := 2.35
const MOM_BLOCKER_RADIUS := 1.05
const MOM_FACE_PLAYER_OFFSET := 0.0
const MOM_INTERACT_RADIUS := 1.65
const CAMPER_INTERACT_RADIUS := 4.2
const MAP_VILLAGE_RADIUS := 0.065
const MAP_CAMPER_START := Vector2(0.06, 0.55)
const MAP_VILLAGE_POINT := Vector2(0.30, 0.39)
const MAP_TRAVEL_SECONDS := 2.7
const DIALOGUE_CHARS_PER_SECOND := 28.0
const TREE_BLOCKER_RADIUS := 1.05
const TREE_CLICK_SHAKE_RADIUS := 1.25
const TREE_SHAKE_DURATION := 0.42
const TREE_SHAKE_STRENGTH := 0.16
const TREE_SHAKE_FREQUENCY := 48.0
const PLAYER_MOVE_SPEED := 5.2
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

var _camera_pivot: Node3D
var _camera: Camera3D
var _grass_material: ShaderMaterial
var _player: Node3D
var _player_visual: Node3D
var _camper: Node3D
var _camper_model: Node3D
var _camper_is_highlighted := false
var _mom: Node3D
var _mom_model: Node3D
var _mom_is_highlighted := false
var _highlight_material: StandardMaterial3D
var _dialogue_layer: CanvasLayer
var _interaction_prompt: Control
var _interaction_prompt_label: Label
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
var _map_panel: Control
var _map_popup: Control
var _map_village_label: Label
var _map_destination_selected := false
var _map_travel_progress := 0.0
var _map_camper_pos := MAP_CAMPER_START
var _typewriter_time := 0.0
var _typewriter_total := 0
var _solid_blockers: Array[Dictionary] = []
var _wind_trees: Array[Dictionary] = []
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
	_grass_material = null
	_camper = null
	_camper_model = null
	_mom = null
	_mom_model = null
	_mom_is_highlighted = false
	_dialogue_open = false
	_dialogue_index = 0
	_dialogue_completed = false
	_map_open = false
	_map_camper_pos = MAP_CAMPER_START
	_map_destination_selected = false
	_map_travel_progress = 0.0
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
	_update_tree_wind(delta)
	_update_grass_player_push()
	_update_mom_interaction()
	if _dialogue_open:
		_update_dialogue_typewriter(delta)
	if _map_open:
		_update_map_popup(delta)
	if not _dialogue_open and not _map_open:
		_update_camera_input(delta)

func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
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
	if event is InputEventKey and event.pressed and event.keycode == KEY_F:
		if not _try_enter_camper():
			_try_start_mom_dialogue()
	if event is InputEventMouseButton and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not _try_enter_camper() and not _try_start_mom_dialogue():
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
	for index in range(PONDS.size()):
		var pond: Dictionary = PONDS[index]
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
	mat.set_shader_parameter("player_push_strength", 0.62)
	_grass_material = mat

	var multimesh := MultiMesh.new()
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
	var player := get_node_or_null("Player")
	if player is Node3D:
		_grass_material.set_shader_parameter("player_position", player.global_position)

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
	for pond in PONDS:
		var center: Vector2 = pond["position"]
		var radius: Vector2 = pond["radius"] + Vector2(padding, padding)
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

	for pond in PONDS:
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

func _create_camper() -> void:
	var scene := load(CAMPER_SCENE_PATH)
	if not scene is PackedScene:
		push_warning("Could not load camper model: %s" % CAMPER_SCENE_PATH)
		return

	var camper := Node3D.new()
	camper.name = "CamperVan"
	camper.position = Vector3(CAMPER_POSITION.x, _height_at(CAMPER_POSITION.x, CAMPER_POSITION.z), CAMPER_POSITION.z)
	camper.rotation.y = deg_to_rad(162.0)
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

func _create_mom() -> void:
	var scene := load(MOM_SCENE_PATH)
	if not scene is PackedScene:
		push_warning("Could not load mom model: %s" % MOM_SCENE_PATH)
		return

	var mom := Node3D.new()
	mom.name = "Mom"
	mom.position = Vector3(MOM_POSITION.x, _height_at(MOM_POSITION.x, MOM_POSITION.z), MOM_POSITION.z)
	mom.rotation.y = _yaw_toward(mom.position, PLAYER_START) + MOM_FACE_PLAYER_OFFSET
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
	_interaction_prompt.add_theme_stylebox_override("panel", _make_round_style(Color(0.92, 0.84, 0.62, 0.82), Color(1.0, 0.95, 0.78, 0.95), 20.0, 1))
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

	_create_map_popup(root)

func _create_map_popup(root: Control) -> void:
	_map_panel = Control.new()
	_map_panel.name = "MapPanel"
	_map_panel.visible = false
	_map_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_map_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_map_panel.gui_input.connect(_on_map_panel_gui_input)
	root.add_child(_map_panel)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.34)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_panel.add_child(dim)

	_map_popup = Control.new()
	_map_popup.name = "WorldMapPopup"
	_map_popup.anchor_left = 0.08
	_map_popup.anchor_top = 0.08
	_map_popup.anchor_right = 0.92
	_map_popup.anchor_bottom = 0.92
	_map_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_panel.add_child(_map_popup)

	var map_image := TextureRect.new()
	map_image.name = "MapImage"
	map_image.texture = load(WORLD_MAP_PATH)
	map_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
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

	_position_map_camper()

func _make_round_style(fill: Color, border: Color, radius: float, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(int(radius))
	return style

func _build_mom_dialogue() -> Array[Dictionary]:
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
	_map_destination_selected = false
	_map_travel_progress = 0.0
	_position_map_camper()
	if _map_panel != null:
		_map_panel.visible = true
		call_deferred("_position_map_camper")
	if _interaction_prompt != null:
		_interaction_prompt.visible = false
	if _interaction_prompt_label != null:
		_interaction_prompt_label.text = "点击地图左上角村庄"
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _close_map_popup() -> void:
	_map_open = false
	if _map_panel != null:
		_map_panel.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _update_map_popup(delta: float) -> void:
	_position_map_camper()
	if _map_destination_selected:
		_map_travel_progress = minf(_map_travel_progress + delta / MAP_TRAVEL_SECONDS, 1.0)
		_map_camper_pos = MAP_CAMPER_START.lerp(MAP_VILLAGE_POINT, _ease_map_travel(_map_travel_progress))
	var near_village := _is_map_camper_near_village()
	if _map_village_label != null:
		var target_alpha := 1.0 if near_village else 0.0
		_map_village_label.modulate.a = move_toward(_map_village_label.modulate.a, target_alpha, delta * 2.8)
	if _interaction_prompt_label != null:
		if near_village:
			_interaction_prompt_label.text = "F / 点击  进入村庄"
		elif _map_destination_selected:
			_interaction_prompt_label.text = "正在前往村庄..."
		else:
			_interaction_prompt_label.text = "点击地图左上角村庄"
	if _interaction_prompt != null:
		_interaction_prompt.visible = true

func _position_map_camper() -> void:
	if _map_popup == null:
		return
	var popup_size := _map_popup.size
	if _map_village_label != null:
		_map_village_label.position = popup_size * MAP_VILLAGE_POINT + Vector2(-75.0, -64.0)

func _is_map_camper_near_village() -> bool:
	return _map_camper_pos.distance_squared_to(MAP_VILLAGE_POINT) <= MAP_VILLAGE_RADIUS * MAP_VILLAGE_RADIUS

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
			_try_select_village(event.position)
		get_viewport().set_input_as_handled()

func _on_map_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not _try_enter_village():
			_try_select_village(event.position)
		get_viewport().set_input_as_handled()

func _try_enter_village() -> bool:
	if not _map_open or not _is_map_camper_near_village():
		return false
	if _interaction_prompt_label != null:
		_interaction_prompt_label.text = "已进入村庄"
	if _interaction_prompt != null:
		_interaction_prompt.visible = true
	_close_map_popup()
	return true

func _try_select_village(screen_position: Vector2) -> bool:
	if _map_popup == null:
		return false
	var local_position := screen_position - _map_popup.global_position
	var popup_size := _map_popup.size
	if popup_size.x <= 0.0 or popup_size.y <= 0.0:
		return false
	var map_position := Vector2(local_position.x / popup_size.x, local_position.y / popup_size.y)
	if map_position.distance_squared_to(MAP_VILLAGE_POINT) > MAP_VILLAGE_RADIUS * MAP_VILLAGE_RADIUS:
		return false
	_map_destination_selected = true
	return true

func _ease_map_travel(value: float) -> float:
	return value * value * (3.0 - 2.0 * value)

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

func _update_player(delta: float) -> void:
	if _player == null:
		return

	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W):
		input_dir.y += 1.0
	if Input.is_key_pressed(KEY_S):
		input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_A):
		input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		input_dir.x += 1.0

	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()

	if input_dir != Vector2.ZERO:
		var forward := Vector3(sin(_orbit.x), 0.0, cos(_orbit.x))
		var right := Vector3(forward.z, 0.0, -forward.x)
		var movement := (right * input_dir.x + forward * input_dir.y).normalized()
		var next_position := _player.global_position + movement * PLAYER_MOVE_SPEED * delta
		if not _is_blocked_by_solid(next_position):
			_player.global_position = next_position
		_player.global_position.y = _height_at(_player.global_position.x, _player.global_position.z)
		_player.rotation.y = atan2(movement.x, movement.z)

func _fit_model_to_height(model: Node3D, target_height: float) -> void:
	var bounds := _get_model_bounds(model)
	if bounds.size.y <= 0.001:
		return
	var factor := target_height / bounds.size.y
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
		maxf(bounds.size.x * model.scale.x * 0.5 + CAMPER_BLOCKER_PADDING.x, 1.4),
		maxf(bounds.size.z * model.scale.z * 0.5 + CAMPER_BLOCKER_PADDING.y, 2.2)
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
	var rotate_speed := 1.35
	var zoom_speed := 7.5
	if Input.is_key_pressed(KEY_LEFT):
		_orbit.x += rotate_speed * delta
	if Input.is_key_pressed(KEY_RIGHT):
		_orbit.x -= rotate_speed * delta
	if Input.is_key_pressed(KEY_UP):
		_orbit.y = clampf(_orbit.y - rotate_speed * 0.28 * delta, 0.04, 0.72)
	if Input.is_key_pressed(KEY_DOWN):
		_orbit.y = clampf(_orbit.y + rotate_speed * 0.28 * delta, 0.04, 0.72)
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
	var player := get_node_or_null("Player")
	if player is Node3D:
		follow_target = player.global_position
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
