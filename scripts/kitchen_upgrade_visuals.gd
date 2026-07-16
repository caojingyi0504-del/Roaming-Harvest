extends RefCounted

## Lightweight low-poly attachment factory shared by the upgrade preview and the
## real kitchen equipment.  The base GLB stays untouched; every purchased part
## lives below UpgradeAppearanceRoot so it can be refreshed without disturbing
## collisions or running kitchen jobs.

const ROOT_NAME := "UpgradeAppearanceRoot"

static func refresh_equipment_attachments(parent: Node3D, equipment_id: String, definitions: Array, owned: Dictionary, focused_id: String = "") -> Node3D:
	var old := parent.get_node_or_null(ROOT_NAME)
	if old != null:
		old.free()
	var root := Node3D.new()
	root.name = ROOT_NAME
	parent.add_child(root)
	for index in range(definitions.size()):
		var definition: Dictionary = definitions[index]
		var upgrade_id := str(definition.get("id", ""))
		var purchased := bool(owned.get(upgrade_id, false))
		var focused := upgrade_id == focused_id and not purchased
		if purchased or focused:
			_add_equipment_part(root, equipment_id, index, purchased)
	return root

static func create_village_diorama(definitions: Array, owned: Dictionary, focused_id: String = "") -> Node3D:
	var root := Node3D.new()
	root.name = "VillageUpgradeDiorama"
	_add_box(root, "Ground", Vector3(0.0, -0.12, 0.0), Vector3(7.8, 0.22, 5.6), Color(0.38, 0.55, 0.29))
	_add_box(root, "VillageHouse", Vector3(0.0, 0.65, 0.0), Vector3(1.8, 1.3, 1.35), Color(0.68, 0.48, 0.28))
	_add_prism_roof(root, Vector3(0.0, 1.48, 0.0), Vector3(2.15, 0.85, 1.65), Color(0.30, 0.20, 0.13))
	# A small but complete baseline village makes each focused renovation read as
	# an addition to a real place instead of a detached placeholder primitive.
	for step in range(7):
		_add_box(root, "DirtPath" + str(step), Vector3(-1.8 + step * 0.6, 0.015, 1.30), Vector3(0.50, 0.035, 0.42), Color(0.68, 0.55, 0.34))
	_add_tree(root, Vector3(-3.0, 0.0, -1.75), 1.0)
	_add_tree(root, Vector3(3.0, 0.0, -1.72), 0.86)
	_add_tree(root, Vector3(-3.2, 0.0, 1.45), 0.72)
	_add_tree(root, Vector3(3.18, 0.0, 1.48), 0.78)
	_add_pond(root, Vector3(2.35, 0.01, 1.48))
	_add_box(root, "CamperBody", Vector3(-2.25, 0.46, 0.20), Vector3(1.28, 0.76, 0.72), Color(0.82, 0.74, 0.56))
	_add_box(root, "CamperCab", Vector3(-1.50, 0.34, 0.20), Vector3(0.46, 0.52, 0.70), Color(0.72, 0.66, 0.53))
	_add_cylinder(root, "CamperWheelL", Vector3(-2.58, 0.08, 0.58), 0.15, 0.12, Color(0.18, 0.16, 0.13))
	_add_cylinder(root, "CamperWheelR", Vector3(-1.82, 0.08, 0.58), 0.15, 0.12, Color(0.18, 0.16, 0.13))
	for index in range(definitions.size()):
		var definition: Dictionary = definitions[index]
		var upgrade_id := str(definition.get("id", ""))
		var purchased := bool(owned.get(upgrade_id, false))
		var focused := upgrade_id == focused_id and not purchased
		if purchased or focused:
			_add_village_project(root, index, purchased)
	return root

static func create_world_village_visual(definitions: Array, owned: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "VillageUpgradeWorldVisual"
	for index in range(definitions.size()):
		var definition: Dictionary = definitions[index]
		if bool(owned.get(str(definition.get("id", "")), false)):
			_add_village_project(root, index, true)
	return root

static func _add_equipment_part(root: Node3D, equipment_id: String, index: int, purchased: bool) -> void:
	var palette := _equipment_palette(equipment_id, purchased)
	var metal: Color = palette[0]
	var wood: Color = palette[1]
	var accent: Color = palette[2]
	var slot := index % 8
	match equipment_id:
		"sink":
			match slot:
				0: _add_pipe(root, "HighPressureNozzle", Vector3(-0.45, 1.18, -0.10), metal)
				1: _add_pipe(root, "DualPump", Vector3(0.48, 0.62, -0.16), accent)
				2: _add_box(root, "FineFilter", Vector3(-0.58, 0.50, 0.05), Vector3(0.34, 0.48, 0.28), metal)
				3: _add_box(root, "TemperatureTank", Vector3(0.46, 0.93, 0.08), Vector3(0.50, 0.22, 0.42), accent)
				4: _add_spheres(root, "BubbleRinse", Vector3(0.0, 1.02, 0.0), accent)
				5: _add_box(root, "Sterilizer", Vector3(0.0, 1.42, 0.12), Vector3(1.05, 0.12, 0.18), metal)
				6: _add_box(root, "SensorArm", Vector3(0.62, 1.20, 0.22), Vector3(0.12, 0.75, 0.12), accent)
				7: _add_ring(root, "WaterRecycler", Vector3(0.0, 0.40, -0.32), metal)
		"cutting_table":
			match slot:
				0: _add_box(root, "NonSlipBoard", Vector3(0.0, 1.02, 0.0), Vector3(0.92, 0.08, 0.62), wood)
				1: _add_blades(root, "KnifeSet", Vector3(-0.55, 1.34, -0.15), metal)
				2: _add_box(root, "FreshTray", Vector3(0.46, 1.08, 0.16), Vector3(0.42, 0.10, 0.48), accent)
				3: _add_ticks(root, "PrecisionScale", Vector3(0.0, 1.13, -0.22), metal)
				4: _add_disc(root, "WeighingModule", Vector3(0.44, 1.16, -0.12), accent)
				5: _add_drawers(root, "SpiceDrawer", Vector3(0.0, 0.64, 0.34), wood)
				6: _add_cylinder(root, "AutoSlicer", Vector3(-0.36, 1.28, 0.05), 0.28, 0.16, metal)
				7: _add_box(root, "ChefBackboard", Vector3(0.0, 1.46, -0.30), Vector3(1.20, 0.52, 0.10), accent)
		"pot":
			match slot:
				0: _add_disc(root, "ThickBottom", Vector3(0.0, 0.48, 0.0), metal)
				1: _add_ring(root, "EnergyBurner", Vector3(0.0, 0.38, 0.0), accent)
				2: _add_disc(root, "PressureLid", Vector3(0.0, 1.34, 0.0), metal)
				3: _add_gauge(root, "Thermometer", Vector3(0.52, 1.16, 0.0), accent)
				4: _add_pipe(root, "PrecisionValve", Vector3(-0.54, 1.02, 0.0), metal)
				5: _add_ring(root, "OverflowRim", Vector3(0.0, 1.15, 0.0), accent)
				6: _add_box(root, "CeramicLiner", Vector3(0.0, 0.86, 0.0), Vector3(0.70, 0.20, 0.70), accent)
				7: _add_arch(root, "GoldenSoupRig", Vector3(0.0, 1.52, -0.22), accent)
		"grill":
			match slot:
				0: _add_grate(root, "DenseGrate", Vector3(0.0, 0.96, 0.0), metal)
				1: _add_pipe(root, "AirDamper", Vector3(-0.62, 0.68, 0.0), accent)
				2: _add_box(root, "HeatShield", Vector3(0.0, 0.82, -0.42), Vector3(1.35, 0.55, 0.10), metal)
				3: _add_box(root, "SearPlate", Vector3(0.36, 1.02, 0.0), Vector3(0.54, 0.08, 0.72), accent)
				4: _add_double_ring(root, "DualFireBed", Vector3(0.0, 0.62, 0.0), accent)
				5: _add_box(root, "GreaseTray", Vector3(0.0, 0.45, 0.32), Vector3(1.15, 0.10, 0.45), metal)
				6: _add_arch(root, "SmokeHood", Vector3(0.0, 1.48, -0.28), metal)
				7: _add_flags(root, "FestivalGrill", Vector3(0.0, 1.58, 0.0), accent)
		"prep_shelf":
			match slot:
				0: _add_bell(root, "ServingBell", Vector3(-0.42, 1.20, 0.0), accent)
				1: _add_trays(root, "NumberedTrays", Vector3(0.15, 1.02, 0.0), metal)
				2: _add_arch(root, "HeatCover", Vector3(0.40, 1.20, 0.0), metal)
				3: _add_spheres(root, "PlatingFlowers", Vector3(-0.55, 1.14, 0.22), accent)
				4: _add_arrow(root, "FastLane", Vector3(0.0, 0.75, 0.38), accent)
				5: _add_box(root, "TipBox", Vector3(0.56, 0.92, 0.10), Vector3(0.32, 0.35, 0.28), wood)
				6: _add_box(root, "ServiceBoard", Vector3(0.0, 1.48, -0.30), Vector3(1.15, 0.48, 0.10), accent)
				7: _add_flags(root, "FestivalCounter", Vector3(0.0, 1.62, 0.0), accent)

static func _equipment_palette(equipment_id: String, purchased: bool) -> Array[Color]:
	var alpha := 1.0 if purchased else 0.48
	var metal := Color(0.62, 0.48, 0.28, alpha)
	var wood := Color(0.42, 0.24, 0.12, alpha)
	var accent := Color(0.94, 0.68, 0.18, alpha)
	if equipment_id == "sink": metal = Color(0.52, 0.68, 0.66, alpha)
	if equipment_id == "pot": metal = Color(0.48, 0.52, 0.50, alpha)
	if equipment_id == "grill": metal = Color(0.34, 0.30, 0.26, alpha)
	return [metal, wood, accent]

static func _add_village_project(root: Node3D, index: int, purchased: bool) -> void:
	var alpha := 1.0 if purchased else 0.48
	var gold := Color(0.95, 0.67, 0.18, alpha)
	match index:
		0:
			for x in [-2.6, -2.1, 2.1, 2.6]: _add_spheres(root, "FlowerBed", Vector3(x, 0.12, 1.75), gold)
		1:
			_add_ring(root, "VillageWell", Vector3(-2.35, 0.34, -1.45), Color(0.55, 0.55, 0.52, alpha))
			_add_arch(root, "WellFrame", Vector3(-2.35, 0.86, -1.45), Color(0.38, 0.23, 0.12, alpha))
		2:
			_add_box(root, "MarketTable", Vector3(2.35, 0.32, -1.35), Vector3(1.40, 0.18, 0.75), Color(0.48, 0.28, 0.14, alpha))
			_add_prism_roof(root, Vector3(2.35, 1.10, -1.35), Vector3(1.70, 0.55, 1.00), gold)
		3:
			for step in range(7): _add_box(root, "RoadStone", Vector3(-1.8 + step * 0.6, 0.02, 1.30), Vector3(0.48, 0.05, 0.38), Color(0.58, 0.56, 0.50, alpha))
		4:
			_add_box(root, "StorageShed", Vector3(-2.4, 0.50, 0.0), Vector3(1.25, 1.0, 1.0), Color(0.48, 0.30, 0.15, alpha))
			_add_boxes(root, "StorageCrates", Vector3(-1.55, 0.18, 0.18), gold)
		5:
			_add_box(root, "WindmillTower", Vector3(2.35, 0.75, 0.05), Vector3(0.55, 1.5, 0.55), Color(0.45, 0.28, 0.14, alpha))
			_add_windmill(root, Vector3(2.35, 1.56, 0.32), gold)
		6:
			_add_arch(root, "CommunityKitchen", Vector3(0.0, 0.74, -1.85), Color(0.40, 0.24, 0.13, alpha))
			_add_box(root, "KitchenCounter", Vector3(0.0, 0.38, -1.85), Vector3(1.55, 0.50, 0.50), gold)
		7:
			_add_arch(root, "HarvestArch", Vector3(0.0, 1.05, 2.05), gold)
			_add_flags(root, "FestivalFlags", Vector3(0.0, 1.90, 0.0), gold)

static func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.72
	if color.a < 0.99:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material

static func _add_box(parent: Node3D, name: String, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = name
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = _material(color)
	node.position = pos
	parent.add_child(node)
	return node

static func _add_cylinder(parent: Node3D, name: String, pos: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	node.mesh = mesh
	node.material_override = _material(color)
	node.position = pos
	parent.add_child(node)
	return node

static func _add_pipe(parent: Node3D, name: String, pos: Vector3, color: Color) -> void:
	_add_cylinder(parent, name + "Stem", pos, 0.07, 0.65, color)
	var arm := _add_cylinder(parent, name + "Arm", pos + Vector3(0.16, 0.30, 0.0), 0.07, 0.34, color)
	arm.rotation.z = PI * 0.5

static func _add_ring(parent: Node3D, name: String, pos: Vector3, color: Color) -> void:
	var torus := MeshInstance3D.new()
	torus.name = name
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.34
	mesh.outer_radius = 0.46
	mesh.rings = 12
	mesh.ring_segments = 8
	torus.mesh = mesh
	torus.material_override = _material(color)
	torus.position = pos
	parent.add_child(torus)

static func _add_disc(parent: Node3D, name: String, pos: Vector3, color: Color) -> void:
	_add_cylinder(parent, name, pos, 0.48, 0.10, color)

static func _add_spheres(parent: Node3D, name: String, pos: Vector3, color: Color) -> void:
	for i in range(4):
		var node := MeshInstance3D.new()
		node.name = name + str(i)
		var mesh := SphereMesh.new()
		mesh.radius = 0.09 + i * 0.015
		mesh.height = mesh.radius * 2.0
		node.mesh = mesh
		node.material_override = _material(color)
		node.position = pos + Vector3((i - 1.5) * 0.20, sin(float(i)) * 0.10, (i % 2) * 0.16)
		parent.add_child(node)

static func _add_arch(parent: Node3D, name: String, pos: Vector3, color: Color) -> void:
	_add_box(parent, name + "Left", pos + Vector3(-0.56, -0.28, 0.0), Vector3(0.12, 1.15, 0.12), color)
	_add_box(parent, name + "Right", pos + Vector3(0.56, -0.28, 0.0), Vector3(0.12, 1.15, 0.12), color)
	_add_box(parent, name + "Top", pos + Vector3(0.0, 0.28, 0.0), Vector3(1.24, 0.12, 0.12), color)

static func _add_blades(parent: Node3D, name: String, pos: Vector3, color: Color) -> void:
	for i in range(3):
		var blade := _add_box(parent, name + str(i), pos + Vector3(i * 0.14, i * 0.02, 0.0), Vector3(0.05, 0.52, 0.10), color)
		blade.rotation.z = -0.30

static func _add_ticks(parent: Node3D, name: String, pos: Vector3, color: Color) -> void:
	for i in range(7): _add_box(parent, name + str(i), pos + Vector3((i - 3) * 0.12, 0.0, 0.0), Vector3(0.025, 0.04 + (i % 2) * 0.04, 0.06), color)

static func _add_drawers(parent: Node3D, name: String, pos: Vector3, color: Color) -> void:
	for i in range(3): _add_box(parent, name + str(i), pos + Vector3((i - 1) * 0.34, 0.0, 0.0), Vector3(0.28, 0.24, 0.16), color)

static func _add_gauge(parent: Node3D, name: String, pos: Vector3, color: Color) -> void:
	var gauge := _add_cylinder(parent, name, pos, 0.18, 0.08, color)
	gauge.rotation.z = PI * 0.5

static func _add_grate(parent: Node3D, name: String, pos: Vector3, color: Color) -> void:
	for i in range(6): _add_box(parent, name + str(i), pos + Vector3((i - 2.5) * 0.18, 0.0, 0.0), Vector3(0.035, 0.05, 0.78), color)

static func _add_double_ring(parent: Node3D, name: String, pos: Vector3, color: Color) -> void:
	_add_ring(parent, name + "A", pos + Vector3(-0.34, 0.0, 0.0), color)
	_add_ring(parent, name + "B", pos + Vector3(0.34, 0.0, 0.0), color)

static func _add_flags(parent: Node3D, name: String, pos: Vector3, color: Color) -> void:
	_add_box(parent, name + "Cord", pos, Vector3(1.45, 0.035, 0.035), color)
	for i in range(5): _add_box(parent, name + str(i), pos + Vector3((i - 2) * 0.30, -0.12, 0.0), Vector3(0.18, 0.24, 0.04), color)

static func _add_bell(parent: Node3D, name: String, pos: Vector3, color: Color) -> void:
	_add_cylinder(parent, name, pos, 0.20, 0.18, color)
	_add_cylinder(parent, name + "Handle", pos + Vector3(0.0, 0.18, 0.0), 0.045, 0.20, color)

static func _add_trays(parent: Node3D, name: String, pos: Vector3, color: Color) -> void:
	for i in range(3): _add_box(parent, name + str(i), pos + Vector3((i - 1) * 0.38, 0.0, 0.0), Vector3(0.32, 0.07, 0.46), color)

static func _add_arrow(parent: Node3D, name: String, pos: Vector3, color: Color) -> void:
	_add_box(parent, name + "Shaft", pos, Vector3(0.72, 0.08, 0.08), color)
	var head := _add_box(parent, name + "Head", pos + Vector3(0.42, 0.0, 0.0), Vector3(0.24, 0.20, 0.08), color)
	head.rotation.z = PI * 0.25

static func _add_prism_roof(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> void:
	var left := _add_box(parent, "RoofLeft", pos + Vector3(-size.x * 0.23, 0.0, 0.0), Vector3(size.x * 0.56, 0.12, size.z), color)
	left.rotation.z = -0.48
	var right := _add_box(parent, "RoofRight", pos + Vector3(size.x * 0.23, 0.0, 0.0), Vector3(size.x * 0.56, 0.12, size.z), color)
	right.rotation.z = 0.48

static func _add_boxes(parent: Node3D, name: String, pos: Vector3, color: Color) -> void:
	for i in range(3): _add_box(parent, name + str(i), pos + Vector3((i % 2) * 0.40, (i / 2) * 0.34, (i % 2) * 0.08), Vector3(0.34, 0.32, 0.34), color)

static func _add_windmill(parent: Node3D, pos: Vector3, color: Color) -> void:
	for i in range(4):
		var blade := _add_box(parent, "WindmillBlade" + str(i), pos, Vector3(0.10, 1.15, 0.06), color)
		blade.rotation.z = float(i) * PI * 0.5

static func _add_tree(parent: Node3D, pos: Vector3, scale_value: float) -> void:
	_add_cylinder(parent, "TreeTrunk", pos + Vector3(0.0, 0.38 * scale_value, 0.0), 0.11 * scale_value, 0.76 * scale_value, Color(0.34, 0.22, 0.12))
	var crown := MeshInstance3D.new()
	crown.name = "TreeCrown"
	var mesh := SphereMesh.new()
	mesh.radius = 0.48 * scale_value
	mesh.height = 0.82 * scale_value
	mesh.radial_segments = 8
	mesh.rings = 5
	crown.mesh = mesh
	crown.material_override = _material(Color(0.25, 0.48, 0.24))
	crown.position = pos + Vector3(0.0, 0.98 * scale_value, 0.0)
	parent.add_child(crown)

static func _add_pond(parent: Node3D, pos: Vector3) -> void:
	var pond := _add_cylinder(parent, "VillagePond", pos, 0.72, 0.055, Color(0.30, 0.68, 0.76, 0.88))
	pond.scale.z = 0.72
