extends Node3D

const GARDEN_SIZE := Vector2(82.0, 70.0)

var _built := false


func _ready() -> void:
	build_once()


func build_once() -> void:
	if _built:
		return
	_built = true
	name = "FlowerGarden"
	_create_ground()
	_create_creek()
	_create_bridge()
	_create_flowering_trees()
	_create_flower_meadows()
	_create_petals()
	_create_garden_light()


func _create_ground() -> void:
	var lawn := _material(Color("#8fb67a"), 0.96)
	_box("GardenMeadow", Vector3(0.0, -0.24, 0.0), Vector3(GARDEN_SIZE.x, 0.48, GARDEN_SIZE.y), lawn)
	var path_material := _material(Color("#e3d5ac"), 0.95)
	for z in range(-30, 25, 2):
		_box("GardenPathStone", Vector3(sin(float(z) * 0.22) * 0.7, 0.035, float(z)), Vector3(2.5, 0.09, 1.55), path_material)
	for x in range(-19, 20, 2):
		_box("CreekPathStone", Vector3(float(x), 0.03, 3.5 + sin(float(x) * 0.28) * 0.45), Vector3(1.55, 0.08, 2.2), path_material)


func _create_creek() -> void:
	var water := _material(Color(0.32, 0.74, 0.82, 0.78), 0.12, true)
	var bank := _material(Color("#78945d"), 0.96)
	var stone := _material(Color("#a9b2a0"), 0.9)
	for z in range(-34, 35, 2):
		var center_x := -22.0 + sin(float(z) * 0.105) * 3.2
		_box("CreekWater", Vector3(center_x, 0.015, float(z)), Vector3(6.4, 0.08, 2.25), water)
		for side in [-1.0, 1.0]:
			_box("CreekBank", Vector3(center_x + side * 3.45, 0.12, float(z)), Vector3(0.8, 0.28, 2.3), bank)
			if (z + int(side)) % 6 == 0:
				_sphere("CreekRock", Vector3(center_x + side * 3.2, 0.26, float(z) + side * 0.35), Vector3(0.9, 0.5, 0.7), stone)


func _create_bridge() -> void:
	var wood := _material(Color("#9b7047"), 0.9)
	var creek_x := -22.0 + sin(0.35) * 3.2
	for index in range(10):
		var x := creek_x - 4.4 + float(index) * 0.98
		_box("BridgePlank", Vector3(x, 0.48, 3.5), Vector3(0.86, 0.18, 2.7), wood)
	for side in [-1.0, 1.0]:
		_box("BridgeRail", Vector3(creek_x, 1.05, 3.5 + side * 1.42), Vector3(10.0, 0.16, 0.16), wood)
		for index in range(6):
			_box("BridgePost", Vector3(creek_x - 4.7 + index * 1.88, 0.78, 3.5 + side * 1.42), Vector3(0.16, 1.0, 0.16), wood)


func _create_flowering_trees() -> void:
	var tree_points := [
		Vector3(-33.0, 0.0, -24.0), Vector3(-31.0, 0.0, 21.0), Vector3(-14.0, 0.0, 29.0),
		Vector3(18.0, 0.0, 27.0), Vector3(32.0, 0.0, 16.0), Vector3(33.0, 0.0, -18.0),
		Vector3(17.0, 0.0, -28.0), Vector3(-7.0, 0.0, -30.0),
	]
	var blossom_colors := [Color("#f7b7c7"), Color("#f4d7ef"), Color("#fff0bd"), Color("#d5c4f3")]
	for index in range(tree_points.size()):
		_create_flowering_tree(tree_points[index], blossom_colors[index % blossom_colors.size()], 0.88 + float(index % 3) * 0.13)


func _create_flowering_tree(point: Vector3, blossom_color: Color, scale_value: float) -> void:
	var trunk := _material(Color("#7f5d43"), 0.94)
	var leaves := _material(Color("#6f9d67"), 0.92)
	var blossoms := _material(blossom_color, 0.78)
	var root := Node3D.new()
	root.name = "FloweringTree"
	root.position = point
	root.scale = Vector3.ONE * scale_value
	add_child(root)
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.30
	trunk_mesh.bottom_radius = 0.48
	trunk_mesh.height = 4.6
	trunk_mesh.radial_segments = 7
	var trunk_node := MeshInstance3D.new()
	trunk_node.mesh = trunk_mesh
	trunk_node.position.y = 2.3
	trunk_node.material_override = trunk
	root.add_child(trunk_node)
	var crown_points := [Vector3(0.0, 5.2, 0.0), Vector3(-1.35, 4.7, 0.2), Vector3(1.25, 4.8, -0.3), Vector3(0.2, 4.65, 1.25), Vector3(-0.2, 4.8, -1.25)]
	for crown_index in range(crown_points.size()):
		_sphere_on(root, "FloweringCrown", crown_points[crown_index], Vector3(2.5, 1.85, 2.4), leaves)
		for blossom_index in range(5):
			var angle := TAU * float(blossom_index) / 5.0 + float(crown_index) * 0.4
			_sphere_on(root, "TreeBlossom", crown_points[crown_index] + Vector3(cos(angle) * 1.35, 0.45 + sin(angle * 2.0) * 0.3, sin(angle) * 1.2), Vector3.ONE * 0.42, blossoms)


func _create_flower_meadows() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 501714
	var colors := [Color("#f5a7b8"), Color("#ffe080"), Color("#c9a8ee"), Color("#a9d9f5"), Color("#fff3df"), Color("#e688a9")]
	var meadow_centers := [
		Vector2(-31.0, -10.0), Vector2(-29.0, 13.0), Vector2(27.0, -11.0), Vector2(26.0, 12.0),
		Vector2(-8.0, 25.0), Vector2(9.0, -26.0), Vector2(-14.0, -9.0), Vector2(14.0, -9.0),
		Vector2(-14.0, 11.0), Vector2(14.0, 11.0),
	]
	for index in range(360):
		var center: Vector2 = meadow_centers[index % meadow_centers.size()]
		var angle := rng.randf_range(0.0, TAU)
		var radius := sqrt(rng.randf()) * rng.randf_range(2.0, 9.0)
		var point := center + Vector2(cos(angle), sin(angle)) * radius
		_create_flower(Vector3(point.x, 0.0, point.y), colors[index % colors.size()], rng.randf_range(0.55, 1.15))


func _create_flower(point: Vector3, color: Color, scale_value: float) -> void:
	var stem := _material(Color("#5f8d55"), 0.92)
	var petals := _material(color, 0.8)
	var height := 0.58 * scale_value
	_box("FlowerStem", point + Vector3(0.0, height * 0.5, 0.0), Vector3(0.045, height, 0.045), stem)
	for petal_index in range(5):
		var angle := TAU * float(petal_index) / 5.0
		_sphere("FlowerPetal", point + Vector3(cos(angle) * 0.13, height, sin(angle) * 0.13), Vector3(0.22, 0.10, 0.22) * scale_value, petals)


func _create_petals() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 81512
	var petal := _material(Color(1.0, 0.70, 0.80, 0.72), 0.76, true)
	for index in range(80):
		var node := _box("FallenPetal", Vector3(rng.randf_range(-38.0, 38.0), 0.075, rng.randf_range(-32.0, 32.0)), Vector3(rng.randf_range(0.12, 0.26), 0.018, rng.randf_range(0.05, 0.12)), petal)
		node.rotation.y = rng.randf_range(0.0, TAU)


func _create_garden_light() -> void:
	var light := DirectionalLight3D.new()
	light.name = "GardenSunFill"
	light.rotation_degrees = Vector3(-54.0, -28.0, 0.0)
	light.light_color = Color("#ffe9c5")
	light.light_energy = 0.72
	light.shadow_enabled = false
	add_child(light)


func _material(color: Color, roughness: float, transparent: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	if transparent or color.a < 0.999:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func _box(node_name: String, point: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	node.position = point
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	return node


func _sphere(node_name: String, point: Vector3, scale_value: Vector3, material: Material) -> MeshInstance3D:
	return _sphere_on(self, node_name, point, scale_value, material)


func _sphere_on(parent: Node3D, node_name: String, point: Vector3, scale_value: Vector3, material: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 7
	mesh.rings = 4
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	node.position = point
	node.scale = scale_value
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	return node
