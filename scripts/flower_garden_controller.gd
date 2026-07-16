extends Node

signal entered
signal exited

const GARDEN_CENTER := Vector3(52.0, 0.0, -49.0)
const GARDEN_SPAWN := Vector3(52.0, 0.0, -39.8)
const GARDEN_EXIT := Vector3(52.0, 0.0, -38.2)
const VILLAGE_GATE := Vector3(36.0, 0.0, 28.0)
const SEED_RACK := Vector3(43.8, 0.0, -48.4)
const GIFT_BENCH := Vector3(60.0, 0.0, -49.0)
const MAP_SIGN := Vector3(59.5, 0.0, -42.0)
const PLOT_POINTS := [
	Vector3(48.0, 0.0, -48.0),
	Vector3(52.0, 0.0, -48.0),
	Vector3(56.0, 0.0, -48.0),
]
const INTERACT_RADIUS := 2.5
const FLOWER_GARDEN_PANEL_ART := "res://ui/flower_garden_panel_v2.png"
const FLOWER_GARDEN_CARD_ART := "res://ui/flower_garden_card_v2.png"
const FLOWER_GARDEN_TAB_ART := "res://ui/flower_garden_tab_v2.png"
const FLOWER_GARDEN_ICON_PATHS := {
	"marigold": "res://ui/flower_garden_icons/marigold_v2.png",
	"lavender": "res://ui/flower_garden_icons/lavender_v2.png",
	"borage": "res://ui/flower_garden_icons/borage_v2.png",
}
const FLOWER_GARDEN_PANEL_SIZE := Vector2(900.0, 540.0)

var host: Node
var world_root: Node3D
var garden_root: Node3D
var village_gate_root: Node3D
var plot_visual_roots: Array[Node3D] = []
var plot_labels: Array[Label3D] = []
var inside := false
var return_position := Vector3.ZERO
var return_orbit := Vector2.ZERO
var return_zoom := 15.0
var has_return_position := false

var overlay: Control
var panel: PanelContainer
var title_label: Label
var content: VBoxContainer
var prompt_panel: PanelContainer
var prompt_label: Label
var current_tab := "plots"
var tab_buttons: Dictionary = {}
var selected_plot := -1
var confirm_clear_plot := -1
var refresh_left := 0.0
var visual_signatures: Array[String] = ["", "", ""]


func setup(world_host: Node) -> void:
	host = world_host
	name = "FlowerGardenController"
	_create_ui()
	if not FlowerGardenManager.state_changed.is_connected(_on_state_changed):
		FlowerGardenManager.state_changed.connect(_on_state_changed)
	_ensure_world_created()
	_refresh_world_visuals(true)


func tick(delta: float) -> void:
	if host == null:
		return
	refresh_left -= maxf(delta, 0.0)
	if refresh_left <= 0.0:
		refresh_left = 1.0
		_refresh_world_visuals()
		if is_overlay_open():
			_rebuild_panel()
	_update_interaction_prompt()


func handle_unhandled_input(event: InputEvent) -> bool:
	if is_overlay_open():
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			close_panel()
		return true
	if _host_blocks_world_interaction():
		return false
	if not event is InputEventKey or not event.pressed or event.echo or event.keycode != KEY_F:
		return false
	var action := _nearest_action()
	match action:
		"village_gate":
			if _is_garden_available():
				enter_garden("village_gate")
			else:
				_notify("晨露花圃将在主线第5关首次获得1星后开放")
			return true
		"garden_exit":
			exit_garden()
			return true
		"seed_rack":
			open_panel("seeds")
			return true
		"gift_bench":
			open_panel("gifts")
			return true
		"map_sign":
			if host.has_method("_open_map_popup"):
				host.call("_open_map_popup")
			return true
		_:
			if action.begins_with("plot_"):
				selected_plot = int(action.trim_prefix("plot_"))
				open_panel("plot")
				return true
	return false


func _host_blocks_world_interaction() -> bool:
	if host == null:
		return true
	if bool(host.get("_dialogue_open")) or bool(host.get("_map_open")) or bool(host.get("_camper_driving")):
		return true
	if bool(host.get("_warehouse_panel_open")) or bool(host.get("_kitchen_equipment_panel_open")) or bool(host.get("_kitchen_upgrade_panel_open")):
		return true
	var prep = host.get("_business_prep_overlay")
	var result = host.get("_business_result_overlay")
	return (prep is Control and (prep as Control).visible) or (result is Control and (result as Control).visible) or bool(host.get("_business_result_pending_open"))


func is_overlay_open() -> bool:
	return overlay != null and overlay.visible


func is_inside_garden() -> bool:
	return inside


func _is_garden_available() -> bool:
	return host != null and host.has_method("_is_flower_garden_available") and bool(host.call("_is_flower_garden_available"))


func enter_garden(_source: String = "village_gate") -> void:
	if not _is_garden_available():
		_notify("第5关通过后开放晨露花圃")
		return
	_ensure_world_created()
	if world_root == null or not is_instance_valid(world_root):
		return
	var player := host.get("_player") as Node3D
	if player == null:
		return
	if not inside:
		return_position = player.global_position
		return_orbit = host.get("_orbit") as Vector2
		return_zoom = float(host.get("_zoom"))
		has_return_position = true
	inside = true
	player.global_position = _grounded(GARDEN_SPAWN)
	host.set("_orbit", Vector2(PI, 0.44))
	host.set("_zoom", 14.5)
	if host.has_method("_apply_camera"):
		host.call("_apply_camera")
	FlowerGardenManager.mark_intro_seen()
	_notify("已抵达晨露花圃 · 花朵会按现实时间离线生长")
	entered.emit()


func exit_garden() -> void:
	if host == null:
		return
	close_panel()
	var player := host.get("_player") as Node3D
	if player != null:
		var target := return_position if has_return_position else VILLAGE_GATE + Vector3(0.0, 0.0, -2.4)
		player.global_position = _grounded(target)
	host.set("_orbit", return_orbit if has_return_position else Vector2(PI, 0.38))
	host.set("_zoom", return_zoom if has_return_position else 15.5)
	inside = false
	if host.has_method("_apply_camera"):
		host.call("_apply_camera")
	exited.emit()


func open_panel(tab: String = "plots", plot_index: int = -1) -> void:
	if not _is_garden_available():
		_notify("第5关通过后开放晨露花圃")
		return
	if plot_index >= 0:
		selected_plot = plot_index
	current_tab = tab
	confirm_clear_plot = -1
	overlay.visible = true
	_rebuild_panel()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func open_gift_selection() -> void:
	open_panel("gifts")


func close_panel() -> void:
	if overlay != null:
		overlay.visible = false
	confirm_clear_plot = -1
	var prep = host.get("_business_prep_overlay") if host != null else null
	if host != null and not bool(host.get("_map_open")) and not (prep is Control and (prep as Control).visible):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _create_world() -> void:
	if world_root != null and is_instance_valid(world_root):
		return
	world_root = Node3D.new()
	world_root.name = "FlowerGardenWorld"
	world_root.set_meta("generated_grass_world", true)
	host.add_child(world_root)
	_create_village_gate()
	_create_garden_area()


func _ensure_world_created() -> void:
	if not _is_garden_available():
		return
	_create_world()


func _create_village_gate() -> void:
	village_gate_root = Node3D.new()
	village_gate_root.name = "MorningDewGardenGate"
	village_gate_root.position = _grounded(VILLAGE_GATE)
	world_root.add_child(village_gate_root)
	var wood := _material(Color("#8a6742"), 0.84)
	var white := _material(Color("#eee5c8"), 0.9)
	var leaf := _material(Color("#708a4a"), 0.92)
	_box(village_gate_root, Vector3(-1.65, 1.35, 0.0), Vector3(0.28, 2.7, 0.32), white)
	_box(village_gate_root, Vector3(1.65, 1.35, 0.0), Vector3(0.28, 2.7, 0.32), white)
	_box(village_gate_root, Vector3(0.0, 2.6, 0.0), Vector3(3.6, 0.3, 0.36), wood)
	for side in [-1.0, 1.0]:
		for i in range(4):
			_sphere(village_gate_root, Vector3(side * (1.25 - i * 0.27), 2.72 + sin(i) * 0.12, 0.0), Vector3.ONE * 0.36, leaf)
	var label := _label3d(village_gate_root, Vector3(0.0, 3.15, 0.0), "晨露花圃")
	label.font_size = 44
	label.outline_size = 10
	host.call("_add_box_blocker", _grounded(VILLAGE_GATE + Vector3(-1.65, 0.0, 0.0)), 0.0, Vector2(0.25, 0.35))
	host.call("_add_box_blocker", _grounded(VILLAGE_GATE + Vector3(1.65, 0.0, 0.0)), 0.0, Vector2(0.25, 0.35))


func _create_garden_area() -> void:
	garden_root = Node3D.new()
	garden_root.name = "MorningDewGarden"
	world_root.add_child(garden_root)
	var cream := _material(Color("#f4e9c9"), 0.93)
	var wood := _material(Color("#9a7047"), 0.88)
	var soil := _material(Color("#765339"), 0.96)
	var green := _material(Color("#78965a"), 0.9)
	var glass := _material(Color(0.72, 0.90, 0.86, 0.34), 0.12, true)
	# 曲折石径让远端区域仍然保留原世界地形，而不是一块悬空地板。
	for z in range(-39, -58, -2):
		var path_point := Vector3(52.0 + sin(float(z) * 0.7) * 0.35, 0.0, float(z))
		var grounded := _grounded(path_point)
		_box(garden_root, grounded + Vector3(0.0, 0.035, 0.0), Vector3(2.2, 0.09, 1.4), cream)
	# 白色围栏，入口中央留空。
	for x in range(42, 63, 2):
		if x < 50 or x > 54:
			_fence_post(garden_root, Vector3(float(x), 0.0, -38.3), cream)
		_fence_post(garden_root, Vector3(float(x), 0.0, -59.5), cream)
	for z in range(-58, -39, 2):
		_fence_post(garden_root, Vector3(41.5, 0.0, float(z)), cream)
		_fence_post(garden_root, Vector3(62.5, 0.0, float(z)), cream)
	for rail_height in [0.52, 0.94]:
		var front_left_y := _height(45.5, -38.3)
		var front_right_y := _height(58.5, -38.3)
		var back_y := _height(52.0, -59.5)
		var left_y := _height(41.5, -49.0)
		var right_y := _height(62.5, -49.0)
		_box(garden_root, Vector3(45.75, front_left_y + rail_height, -38.3), Vector3(8.5, 0.13, 0.13), cream)
		_box(garden_root, Vector3(58.25, front_right_y + rail_height, -38.3), Vector3(8.5, 0.13, 0.13), cream)
		_box(garden_root, Vector3(52.0, back_y + rail_height, -59.5), Vector3(21.0, 0.13, 0.13), cream)
		_box(garden_root, Vector3(41.5, left_y + rail_height, -49.0), Vector3(0.13, 0.13, 21.0), cream)
		_box(garden_root, Vector3(62.5, right_y + rail_height, -49.0), Vector3(0.13, 0.13, 21.0), cream)
	# 返回花门。
	var exit_y := _height(GARDEN_EXIT.x, GARDEN_EXIT.z)
	_box(garden_root, Vector3(50.2, exit_y + 1.25, -38.3), Vector3(0.25, 2.5, 0.3), cream)
	_box(garden_root, Vector3(53.8, exit_y + 1.25, -38.3), Vector3(0.25, 2.5, 0.3), cream)
	_box(garden_root, Vector3(52.0, exit_y + 2.45, -38.3), Vector3(3.9, 0.28, 0.34), wood)
	_label3d(garden_root, Vector3(52.0, exit_y + 2.95, -38.3), "返回村庄")
	# 玻璃温室。
	var greenhouse_center := Vector3(52.0, 0.0, -55.8)
	var greenhouse_y := _height(greenhouse_center.x, greenhouse_center.z)
	for x in [-4.4, 0.0, 4.4]:
		_box(garden_root, Vector3(greenhouse_center.x + x, greenhouse_y + 1.8, greenhouse_center.z), Vector3(0.18, 3.6, 5.3), cream)
	for z in [-2.55, 2.55]:
		_box(garden_root, Vector3(greenhouse_center.x, greenhouse_y + 1.8, greenhouse_center.z + z), Vector3(8.9, 3.6, 0.16), glass)
		_box(garden_root, Vector3(greenhouse_center.x, greenhouse_y + 3.6, greenhouse_center.z + z), Vector3(9.1, 0.18, 0.22), wood)
	_box(garden_root, Vector3(greenhouse_center.x, greenhouse_y + 3.75, greenhouse_center.z), Vector3(9.0, 0.16, 5.3), glass)
	_label3d(garden_root, Vector3(52.0, greenhouse_y + 4.4, -53.15), "晨露温室")
	# 三块独立花床。
	for index in range(PLOT_POINTS.size()):
		var point: Vector3 = PLOT_POINTS[index]
		var y := _height(point.x, point.z)
		_box(garden_root, Vector3(point.x, y + 0.18, point.z), Vector3(3.0, 0.36, 2.4), wood)
		_box(garden_root, Vector3(point.x, y + 0.39, point.z), Vector3(2.65, 0.15, 2.05), soil)
		var visual_root := Node3D.new()
		visual_root.position = Vector3(point.x, y + 0.43, point.z)
		garden_root.add_child(visual_root)
		plot_visual_roots.append(visual_root)
		var status := _label3d(garden_root, Vector3(point.x, y + 2.15, point.z), "%d号花床" % (index + 1))
		status.font_size = 34
		plot_labels.append(status)
		host.call("_add_box_blocker", _grounded(point), 0.0, Vector2(1.48, 1.18))
	# 种架、花礼台与地图牌。
	_create_rack(SEED_RACK, "花种架", wood, cream, green)
	_create_rack(GIFT_BENCH, "花礼工坊", wood, cream, green)
	_create_map_sign(wood, cream)
	# 温室、围栏和工作设施碰撞。
	host.call("_add_box_blocker", _grounded(Vector3(47.6, 0.0, -55.8)), 0.0, Vector2(0.25, 2.8))
	host.call("_add_box_blocker", _grounded(Vector3(56.4, 0.0, -55.8)), 0.0, Vector2(0.25, 2.8))
	host.call("_add_box_blocker", _grounded(Vector3(45.75, 0.0, -38.3)), 0.0, Vector2(4.25, 0.16))
	host.call("_add_box_blocker", _grounded(Vector3(58.25, 0.0, -38.3)), 0.0, Vector2(4.25, 0.16))
	host.call("_add_box_blocker", _grounded(Vector3(52.0, 0.0, -59.5)), 0.0, Vector2(10.5, 0.16))
	host.call("_add_box_blocker", _grounded(Vector3(41.5, 0.0, -49.0)), 0.0, Vector2(0.16, 10.5))
	host.call("_add_box_blocker", _grounded(Vector3(62.5, 0.0, -49.0)), 0.0, Vector2(0.16, 10.5))
	host.call("_add_box_blocker", _grounded(SEED_RACK), 0.0, Vector2(1.0, 0.65))
	host.call("_add_box_blocker", _grounded(GIFT_BENCH), 0.0, Vector2(1.15, 0.7))


func _create_rack(point: Vector3, label_text: String, wood: Material, cream: Material, green: Material) -> void:
	var y := _height(point.x, point.z)
	_box(garden_root, Vector3(point.x, y + 0.65, point.z), Vector3(2.15, 1.15, 1.1), wood)
	_box(garden_root, Vector3(point.x, y + 1.28, point.z), Vector3(2.4, 0.18, 1.3), cream)
	for x in [-0.62, 0.0, 0.62]:
		_sphere(garden_root, Vector3(point.x + x, y + 1.52, point.z), Vector3(0.28, 0.42, 0.28), green)
	_label3d(garden_root, Vector3(point.x, y + 2.15, point.z), label_text)


func _create_map_sign(wood: Material, cream: Material) -> void:
	var y := _height(MAP_SIGN.x, MAP_SIGN.z)
	_box(garden_root, Vector3(MAP_SIGN.x, y + 0.8, MAP_SIGN.z), Vector3(0.18, 1.6, 0.18), wood)
	_box(garden_root, Vector3(MAP_SIGN.x, y + 1.55, MAP_SIGN.z), Vector3(2.0, 1.05, 0.16), cream)
	_label3d(garden_root, Vector3(MAP_SIGN.x, y + 1.58, MAP_SIGN.z - 0.12), "房车地图")


func _fence_post(parent: Node3D, point: Vector3, material: Material) -> void:
	var y := _height(point.x, point.z)
	_box(parent, Vector3(point.x, y + 0.62, point.z), Vector3(0.16, 1.24, 0.16), material)


func _refresh_world_visuals(force: bool = false) -> void:
	if plot_visual_roots.size() != FlowerGardenManager.PLOT_COUNT:
		return
	for snapshot in FlowerGardenManager.all_plot_snapshots():
		var index := int(snapshot.get("index", -1))
		if index < 0 or index >= plot_visual_roots.size():
			continue
		var signature := "%s:%s" % [str(snapshot.get("flower_id", "")), str(snapshot.get("state", "empty"))]
		if force or visual_signatures[index] != signature:
			visual_signatures[index] = signature
			_rebuild_plot_visual(index, snapshot)
		var label := plot_labels[index]
		var state := str(snapshot.get("state", "empty"))
		if state == "empty":
			label.text = "%d号花床 · 空置" % (index + 1)
		elif bool(snapshot.get("ready", false)):
			label.text = "%d号花床 · %s已盛开" % [index + 1, str(snapshot.get("name", "花朵"))]
		else:
			label.text = "%d号花床 · %s %s" % [index + 1, str(snapshot.get("name", "花朵")), _format_time(float(snapshot.get("remaining", 0.0)))]


func _rebuild_plot_visual(index: int, snapshot: Dictionary) -> void:
	var root := plot_visual_roots[index]
	for child in root.get_children():
		child.queue_free()
	var flower_id := str(snapshot.get("flower_id", ""))
	if flower_id == "":
		return
	var definition := FlowerGardenManager.flower_definition(flower_id)
	var flower_color: Color = definition.get("color", Color.WHITE)
	var stem := _material(Color("#62804a"), 0.9)
	var petals := _material(flower_color, 0.82)
	var state := str(snapshot.get("state", "seedling"))
	var height_scale := 0.35 if state == "seedling" else (0.7 if state == "bud" else 1.0)
	for x in [-0.85, 0.0, 0.85]:
		for z in [-0.55, 0.55]:
			var h := (0.56 + fmod(absf(x * 13.0 + z * 7.0), 0.22)) * height_scale
			_box(root, Vector3(x, h * 0.5, z), Vector3(0.07, h, 0.07), stem)
			_sphere(root, Vector3(x, h + 0.05, z), Vector3.ONE * (0.13 if state == "seedling" else (0.19 if state == "bud" else 0.30)), petals)
			if state == "bloom":
				for angle_index in range(6):
					var angle := TAU * float(angle_index) / 6.0
					_sphere(root, Vector3(x + cos(angle) * 0.22, h + 0.05, z + sin(angle) * 0.22), Vector3(0.22, 0.10, 0.22), petals)


func _create_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "FlowerGardenUI"
	layer.layer = 126
	layer.set_meta("generated_grass_world", true)
	host.add_child(layer)
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	layer.add_child(overlay)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.08, 0.12, 0.08, 0.23)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dim)
	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -FLOWER_GARDEN_PANEL_SIZE.x * 0.5
	panel.offset_top = -FLOWER_GARDEN_PANEL_SIZE.y * 0.5
	panel.offset_right = FLOWER_GARDEN_PANEL_SIZE.x * 0.5
	panel.offset_bottom = FLOWER_GARDEN_PANEL_SIZE.y * 0.5
	panel.pivot_offset = FLOWER_GARDEN_PANEL_SIZE * 0.5
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	overlay.add_child(panel)
	var panel_art := TextureRect.new()
	panel_art.texture = load(FLOWER_GARDEN_PANEL_ART) as Texture2D
	panel_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel_art.stretch_mode = TextureRect.STRETCH_SCALE
	panel_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(panel_art)
	var safe_area := MarginContainer.new()
	safe_area.add_theme_constant_override("margin_left", 150)
	safe_area.add_theme_constant_override("margin_top", 102)
	safe_area.add_theme_constant_override("margin_right", 150)
	safe_area.add_theme_constant_override("margin_bottom", 44)
	panel.add_child(safe_area)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 6)
	safe_area.add_child(outer)
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 42.0
	header.add_theme_constant_override("separation", 5)
	outer.add_child(header)
	title_label = Label.new()
	title_label.text = "晨露花圃"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color("#44331f"))
	header.add_child(title_label)
	for tab_data in [["plots", "花床"], ["seeds", "花种架"], ["gifts", "花礼工坊"]]:
		var tab := Button.new()
		tab.text = str(tab_data[1])
		tab.custom_minimum_size = Vector2(88.0 if str(tab_data[0]) != "gifts" else 102.0, 36.0)
		tab.focus_mode = Control.FOCUS_NONE
		tab.pressed.connect(_on_tab_pressed.bind(str(tab_data[0])))
		header.add_child(tab)
		tab_buttons[str(tab_data[0])] = tab
	var close := Button.new()
	close.text = "×"
	close.custom_minimum_size = Vector2(38.0, 36.0)
	close.focus_mode = Control.FOCUS_NONE
	close.add_theme_font_size_override("font_size", 20)
	close.add_theme_color_override("font_color", Color("#44331f"))
	close.add_theme_stylebox_override("normal", _compact_style(Color(0.96, 0.90, 0.74, 0.96), Color("#9a7047"), 16, 2, 4))
	close.add_theme_stylebox_override("hover", _compact_style(Color(1.0, 0.96, 0.82, 1.0), Color("#725032"), 16, 2, 4))
	close.add_theme_stylebox_override("pressed", _compact_style(Color(0.88, 0.82, 0.65, 1.0), Color("#725032"), 16, 2, 4))
	close.pressed.connect(close_panel)
	header.add_child(close)
	content = VBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 6)
	outer.add_child(content)
	_update_tab_styles()
	_update_panel_scale()
	if not get_viewport().size_changed.is_connected(_update_panel_scale):
		get_viewport().size_changed.connect(_update_panel_scale)
	# 世界交互提示使用自己的小框，不与任务/仓库提示叠在一起。
	prompt_panel = PanelContainer.new()
	prompt_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_panel.offset_left = -210.0
	prompt_panel.offset_top = -80.0
	prompt_panel.offset_right = 210.0
	prompt_panel.offset_bottom = -24.0
	prompt_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.96, 0.91, 0.75, 0.96), Color("#637347"), 14, 3))
	prompt_panel.visible = false
	layer.add_child(prompt_panel)
	prompt_label = Label.new()
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 18)
	prompt_label.add_theme_color_override("font_color", Color("#3d321f"))
	prompt_panel.add_child(prompt_label)


func _rebuild_panel() -> void:
	if content == null:
		return
	_update_tab_styles()
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	var summary := Label.new()
	summary.text = "独立花圃仓储  ·  个人金币 %d  ·  成熟花床 %d/3" % [_coins(), FlowerGardenManager.ready_plot_count()]
	summary.add_theme_font_size_override("font_size", 14)
	summary.add_theme_color_override("font_color", Color("#6a5637"))
	content.add_child(summary)
	match current_tab:
		"seeds":
			_build_seed_store()
		"gifts":
			_build_gift_workshop()
		"plot":
			_build_plot_detail()
		_:
			_build_plot_overview()


func _build_plot_overview() -> void:
	var hint := Label.new()
	hint.text = "花朵成熟后会停在盛开状态，不枯萎，也不会自动累积下一批。"
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color("#526244"))
	content.add_child(hint)
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)
	content.add_child(row)
	for snapshot in FlowerGardenManager.all_plot_snapshots():
		var index := int(snapshot.get("index", 0))
		var card_panel := PanelContainer.new()
		card_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_panel.add_theme_stylebox_override("panel", _flower_card_style())
		row.add_child(card_panel)
		var card := VBoxContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_constant_override("separation", 5)
		card_panel.add_child(card)
		var heading := Label.new()
		heading.text = "%d号花床" % (index + 1)
		heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		heading.add_theme_font_size_override("font_size", 18)
		heading.add_theme_color_override("font_color", Color("#44331f"))
		card.add_child(heading)
		var state := Label.new()
		state.custom_minimum_size.y = 142.0
		state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		state.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		state.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if str(snapshot.get("state", "empty")) == "empty":
			state.text = "＋\n空置\n可播种任意花种"
		elif bool(snapshot.get("ready", false)):
			state.text = "✿\n%s已经盛开\n可收取花材 x2" % str(snapshot.get("name", "花朵"))
		else:
			state.text = "♧\n%s正在生长\n剩余 %s" % [str(snapshot.get("name", "花朵")), _format_time(float(snapshot.get("remaining", 0.0)))]
		state.add_theme_font_size_override("font_size", 17)
		state.add_theme_color_override("font_color", Color("#4a3b27"))
		state.add_theme_stylebox_override("normal", _inner_garden_style())
		card.add_child(state)
		var manage := Button.new()
		manage.text = "管理花床"
		manage.custom_minimum_size.y = 38.0
		_apply_garden_action_button_style(manage, true)
		manage.pressed.connect(_on_manage_plot.bind(index))
		card.add_child(manage)


func _build_plot_detail() -> void:
	if selected_plot < 0 or selected_plot >= FlowerGardenManager.PLOT_COUNT:
		current_tab = "plots"
		_build_plot_overview()
		return
	var snapshot := FlowerGardenManager.plot_snapshot(selected_plot)
	var back := Button.new()
	back.text = "← 返回三块花床"
	back.custom_minimum_size = Vector2(180.0, 38.0)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_apply_garden_action_button_style(back)
	back.pressed.connect(_on_tab_pressed.bind("plots"))
	content.add_child(back)
	var title := Label.new()
	title.text = "%d号花床" % (selected_plot + 1)
	title.add_theme_font_size_override("font_size", 25)
	content.add_child(title)
	if str(snapshot.get("state", "empty")) == "empty":
		var hint := Label.new()
		hint.text = "选择一种花种播种（每次消耗种包 x1）"
		content.add_child(hint)
		for definition in FlowerGardenManager.flower_definitions():
			var flower_id := str(definition.get("id", ""))
			var button := Button.new()
			button.text = "%s  %s  ·  种包 x%d  ·  成熟 %d分钟" % [str(definition.get("icon", "✿")), str(definition.get("name", "花")), FlowerGardenManager.seed_count(flower_id), int(float(definition.get("grow_seconds", 0.0)) / 60.0)]
			button.custom_minimum_size.y = 54.0
			var icon_path := str(FLOWER_GARDEN_ICON_PATHS.get(flower_id, ""))
			if icon_path != "" and ResourceLoader.exists(icon_path):
				button.text = "%s  ·  种包 x%d  ·  成熟 %d分钟" % [str(definition.get("name", "花")), FlowerGardenManager.seed_count(flower_id), int(float(definition.get("grow_seconds", 0.0)) / 60.0)]
				button.icon = load(icon_path) as Texture2D
				button.expand_icon = true
				button.icon_max_width = 36
			_apply_garden_action_button_style(button)
			button.disabled = FlowerGardenManager.seed_count(flower_id) <= 0
			button.pressed.connect(_on_plant.bind(selected_plot, flower_id))
			content.add_child(button)
	elif bool(snapshot.get("ready", false)):
		var ready := Label.new()
		ready.text = "%s已盛开！本次可收取花材 x2。" % str(snapshot.get("name", "花朵"))
		ready.add_theme_font_size_override("font_size", 22)
		content.add_child(ready)
		var actions := HBoxContainer.new()
		content.add_child(actions)
		var harvest := Button.new()
		harvest.text = "收取"
		harvest.custom_minimum_size = Vector2(220.0, 56.0)
		_apply_garden_action_button_style(harvest, true)
		harvest.pressed.connect(_on_harvest.bind(selected_plot, false))
		actions.add_child(harvest)
		var flower_id := str(snapshot.get("flower_id", ""))
		var replant := Button.new()
		replant.text = "收取并续种（种包 x%d）" % FlowerGardenManager.seed_count(flower_id)
		replant.custom_minimum_size = Vector2(280.0, 56.0)
		_apply_garden_action_button_style(replant)
		replant.disabled = FlowerGardenManager.seed_count(flower_id) <= 0
		replant.pressed.connect(_on_harvest.bind(selected_plot, true))
		actions.add_child(replant)
	else:
		var growing := Label.new()
		growing.text = "%s正在生长 · %s · 完成 %d%%" % [str(snapshot.get("name", "花朵")), _format_time(float(snapshot.get("remaining", 0.0))), int(float(snapshot.get("progress", 0.0)) * 100.0)]
		growing.add_theme_font_size_override("font_size", 22)
		content.add_child(growing)
		if confirm_clear_plot == selected_plot:
			var warning := Label.new()
			warning.text = "确定铲除吗？原种包不会返还。"
			warning.add_theme_color_override("font_color", Color("#a34b31"))
			content.add_child(warning)
			var confirm_row := HBoxContainer.new()
			content.add_child(confirm_row)
			var yes := Button.new()
			yes.text = "确定铲除"
			_apply_garden_action_button_style(yes)
			yes.pressed.connect(_on_confirm_clear.bind(selected_plot))
			confirm_row.add_child(yes)
			var no := Button.new()
			no.text = "保留花朵"
			_apply_garden_action_button_style(no, true)
			no.pressed.connect(_on_cancel_clear)
			confirm_row.add_child(no)
		else:
			var clear := Button.new()
			clear.text = "铲除改种"
			clear.custom_minimum_size = Vector2(200.0, 48.0)
			clear.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			_apply_garden_action_button_style(clear)
			clear.pressed.connect(_on_request_clear.bind(selected_plot))
			content.add_child(clear)


func _build_seed_store() -> void:
	var hint := Label.new()
	hint.text = "不限每日库存 · 购买后进入独立花圃仓储，不占背包。"
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color("#526244"))
	content.add_child(hint)
	for definition in FlowerGardenManager.flower_definitions():
		var flower_id := str(definition.get("id", ""))
		var card_panel := PanelContainer.new()
		card_panel.custom_minimum_size.y = 74.0
		card_panel.add_theme_stylebox_override("panel", _flower_card_style())
		content.add_child(card_panel)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		card_panel.add_child(row)
		row.add_child(_create_flower_icon(flower_id, Vector2(54.0, 54.0)))
		var info := Label.new()
		info.text = "%s\n%d分钟成熟 · 收获 x2 · 种包 x%d" % [str(definition.get("name", "花")), int(float(definition.get("grow_seconds", 0.0)) / 60.0), FlowerGardenManager.seed_count(flower_id)]
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		info.add_theme_font_size_override("font_size", 15)
		info.add_theme_color_override("font_color", Color("#44331f"))
		row.add_child(info)
		for amount in [1, 5]:
			var cost := FlowerGardenManager.seed_purchase_cost(flower_id, amount)
			var buy := Button.new()
			buy.text = "购买 x%d\n%d 金币" % [amount, cost]
			buy.custom_minimum_size = Vector2(96.0, 50.0)
			_apply_garden_action_button_style(buy)
			buy.disabled = _coins() < cost
			buy.pressed.connect(_on_buy_seed.bind(flower_id, amount))
			row.add_child(buy)


func _build_gift_workshop() -> void:
	var none := Button.new()
	none.text = "本次不携带花礼" + ("  ✓" if FlowerGardenManager.selected_gift == "" else "")
	none.custom_minimum_size.y = 32.0
	none.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_apply_garden_action_button_style(none)
	none.pressed.connect(_on_select_gift.bind(""))
	content.add_child(none)
	for definition in FlowerGardenManager.flower_definitions():
		var flower_id := str(definition.get("id", ""))
		var gift_id := str(definition.get("gift_id", ""))
		var card_panel := PanelContainer.new()
		card_panel.custom_minimum_size.y = 83.0
		card_panel.add_theme_stylebox_override("panel", _flower_card_style())
		content.add_child(card_panel)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 7)
		card_panel.add_child(row)
		row.add_child(_create_flower_icon(flower_id, Vector2(56.0, 56.0)))
		var info := Label.new()
		info.text = "%s%s\n%s\n花材 x%d · 库存 x%d" % [str(definition.get("gift_name", "花礼")), "  ✓ 已选" if FlowerGardenManager.selected_gift == gift_id else "", str(definition.get("gift_effect", "")), FlowerGardenManager.flower_count(flower_id), FlowerGardenManager.gift_count(gift_id)]
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_theme_font_size_override("font_size", 13)
		info.add_theme_color_override("font_color", Color("#44331f"))
		row.add_child(info)
		var craft := Button.new()
		craft.text = "制作\n花材 x4"
		craft.custom_minimum_size = Vector2(82.0, 52.0)
		_apply_garden_action_button_style(craft)
		craft.disabled = FlowerGardenManager.flower_count(flower_id) < FlowerGardenManager.GIFT_FLOWER_COST
		craft.pressed.connect(_on_craft_gift.bind(gift_id))
		row.add_child(craft)
		var select := Button.new()
		select.text = "已装备" if FlowerGardenManager.selected_gift == gift_id else "开业前装备"
		select.custom_minimum_size = Vector2(94.0, 52.0)
		_apply_garden_action_button_style(select, FlowerGardenManager.selected_gift == gift_id)
		select.disabled = FlowerGardenManager.gift_count(gift_id) <= 0 or FlowerGardenManager.selected_gift == gift_id
		select.pressed.connect(_on_select_gift.bind(gift_id))
		row.add_child(select)


func _on_tab_pressed(tab: String) -> void:
	current_tab = tab
	confirm_clear_plot = -1
	_rebuild_panel()


func _on_manage_plot(index: int) -> void:
	selected_plot = index
	current_tab = "plot"
	_rebuild_panel()


func _on_plant(index: int, flower_id: String) -> void:
	var result := FlowerGardenManager.plant(index, flower_id)
	if bool(result.get("ok", false)):
		_notify("已播种%s，离线期间也会继续生长" % str(FlowerGardenManager.flower_definition(flower_id).get("name", "花种")))
	else:
		_notify("没有可用种包，请先去花种架购买")


func _on_harvest(index: int, replant: bool) -> void:
	var result := FlowerGardenManager.harvest(index, replant)
	if not bool(result.get("ok", false)):
		_notify("花朵还没有成熟")
		return
	var flower_id := str(result.get("flower_id", ""))
	var flower_name := str(FlowerGardenManager.flower_definition(flower_id).get("name", "花材"))
	var suffix := "，并已续种" if bool(result.get("replanted", false)) else ""
	if bool(result.get("missing_seed", false)):
		suffix = "，同种种包不足，未能续种"
	_notify("收取%s花材 x%d%s" % [flower_name, int(result.get("amount", 0)), suffix])


func _on_request_clear(index: int) -> void:
	confirm_clear_plot = index
	_rebuild_panel()


func _on_cancel_clear() -> void:
	confirm_clear_plot = -1
	_rebuild_panel()


func _on_confirm_clear(index: int) -> void:
	var result := FlowerGardenManager.clear_growing_plot(index)
	confirm_clear_plot = -1
	if bool(result.get("ok", false)):
		_notify("已铲除，原种包未返还")
	else:
		_notify("成熟花朵需要先收取")


func _on_buy_seed(flower_id: String, amount: int) -> void:
	var result := FlowerGardenManager.buy_seeds(flower_id, amount, _coins())
	if not bool(result.get("ok", false)):
		_notify("个人金币不足")
		return
	host.set("_coins", _coins() - int(result.get("cost", 0)))
	if host.has_method("_update_coin_hud"):
		host.call("_update_coin_hud")
	_notify("购买%s种包 x%d" % [str(FlowerGardenManager.flower_definition(flower_id).get("name", "花")), amount])
	_rebuild_panel()


func _on_craft_gift(gift_id: String) -> void:
	var result := FlowerGardenManager.craft_gift(gift_id)
	if bool(result.get("ok", false)):
		_notify("花礼制作完成，可在经营准备时装备")
	else:
		_notify("花材不足，制作一份需要同类花材 x4")


func _on_select_gift(gift_id: String) -> void:
	var result := FlowerGardenManager.select_gift(gift_id)
	if bool(result.get("ok", false)):
		_notify("本次不携带花礼" if gift_id == "" else "已设为默认花礼，经营真正开始后才会消耗")
	else:
		_notify("该花礼库存不足")


func _on_state_changed() -> void:
	_ensure_world_created()
	_refresh_world_visuals(true)
	if is_overlay_open():
		_rebuild_panel()


func _nearest_action() -> String:
	if not _is_garden_available() or world_root == null or not is_instance_valid(world_root):
		return ""
	var player := host.get("_player") as Node3D
	if player == null:
		return ""
	var point := Vector2(player.global_position.x, player.global_position.z)
	if not inside:
		return "village_gate" if point.distance_to(Vector2(VILLAGE_GATE.x, VILLAGE_GATE.z)) <= 3.2 else ""
	var candidates: Array[Dictionary] = [
		{"action": "garden_exit", "point": GARDEN_EXIT, "radius": 2.8},
		{"action": "seed_rack", "point": SEED_RACK, "radius": INTERACT_RADIUS},
		{"action": "gift_bench", "point": GIFT_BENCH, "radius": INTERACT_RADIUS},
		{"action": "map_sign", "point": MAP_SIGN, "radius": INTERACT_RADIUS},
	]
	for index in range(PLOT_POINTS.size()):
		candidates.append({"action": "plot_%d" % index, "point": PLOT_POINTS[index], "radius": 2.15})
	var nearest := ""
	var nearest_distance := INF
	for candidate in candidates:
		var candidate_point: Vector3 = candidate.get("point", Vector3.ZERO)
		var distance := point.distance_to(Vector2(candidate_point.x, candidate_point.z))
		if distance <= float(candidate.get("radius", INTERACT_RADIUS)) and distance < nearest_distance:
			nearest = str(candidate.get("action", ""))
			nearest_distance = distance
	return nearest


func _update_interaction_prompt() -> void:
	if prompt_panel == null or is_overlay_open() or _host_blocks_world_interaction():
		if prompt_panel != null:
			prompt_panel.visible = false
		return
	var action := _nearest_action()
	if action == "":
		prompt_panel.visible = false
		return
	var text := ""
	match action:
		"village_gate":
			text = "F  进入晨露花圃"
		"garden_exit": text = "F  返回村庄"
		"seed_rack": text = "F  查看花种架"
		"gift_bench": text = "F  制作与装备花礼"
		"map_sign": text = "F  打开房车地图"
		_:
			if action.begins_with("plot_"):
				text = "F  管理%s号花床" % (int(action.trim_prefix("plot_")) + 1)
	prompt_label.text = text
	prompt_panel.visible = text != ""
	var host_prompt = host.get("_interaction_prompt")
	if host_prompt is Control:
		(host_prompt as Control).visible = false


func _coins() -> int:
	return int(host.get("_coins")) if host != null else 0


func _notify(message: String) -> void:
	if host != null:
		if host.has_method("_show_side_toast"):
			host.call("_show_side_toast", message)
		elif host.has_method("_show_notification"):
			host.call("_show_notification", message)


func _height(x: float, z: float) -> float:
	return float(host.call("_height_at", x, z))


func _grounded(point: Vector3) -> Vector3:
	return Vector3(point.x, _height(point.x, point.z), point.z)


func _format_time(seconds: float) -> String:
	var total := maxi(int(ceil(maxf(seconds, 0.0))), 0)
	var minutes := total / 60
	var secs := total % 60
	if minutes >= 60:
		return "%d:%02d:%02d" % [minutes / 60, minutes % 60, secs]
	return "%02d:%02d" % [minutes, secs]


func _material(color: Color, roughness: float = 0.9, transparent: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	if transparent or color.a < 0.999:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func _box(parent: Node3D, position: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	node.mesh = mesh
	node.position = position
	parent.add_child(node)
	return node


func _sphere(parent: Node3D, position: Vector3, scale_value: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radial_segments = 8
	mesh.rings = 4
	mesh.height = 1.0
	mesh.radius = 0.5
	mesh.material = material
	node.mesh = mesh
	node.position = position
	node.scale = scale_value
	parent.add_child(node)
	return node


func _label3d(parent: Node3D, position: Vector3, text_value: String) -> Label3D:
	var label := Label3D.new()
	label.text = text_value
	label.position = position
	label.font_size = 30
	label.outline_size = 8
	label.modulate = Color("#392f1f")
	label.outline_modulate = Color(1.0, 0.95, 0.78, 0.95)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	parent.add_child(label)
	return label


func _update_panel_scale() -> void:
	if panel == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var scale_factor := minf(1.0, minf(viewport_size.x * 0.90 / FLOWER_GARDEN_PANEL_SIZE.x, viewport_size.y * 0.82 / FLOWER_GARDEN_PANEL_SIZE.y))
	panel.scale = Vector2.ONE * maxf(scale_factor, 0.56)


func _update_tab_styles() -> void:
	for tab_id in tab_buttons:
		var button := tab_buttons[tab_id] as Button
		if button == null:
			continue
		var selected := str(tab_id) == current_tab or (current_tab == "plot" and str(tab_id) == "plots")
		button.add_theme_font_size_override("font_size", 14)
		button.add_theme_color_override("font_color", Color("#f8f0d5") if selected else Color("#44331f"))
		button.add_theme_color_override("font_hover_color", Color("#fff8e4") if selected else Color("#302416"))
		button.add_theme_color_override("font_pressed_color", Color("#fff8e4"))
		button.add_theme_stylebox_override("normal", _flower_tab_style(selected, "normal"))
		button.add_theme_stylebox_override("hover", _flower_tab_style(selected, "hover"))
		button.add_theme_stylebox_override("pressed", _flower_tab_style(true, "pressed"))


func _flower_tab_style(selected: bool, state: String) -> StyleBox:
	if ResourceLoader.exists(FLOWER_GARDEN_TAB_ART):
		var style := StyleBoxTexture.new()
		style.texture = load(FLOWER_GARDEN_TAB_ART) as Texture2D
		style.texture_margin_left = 28.0
		style.texture_margin_top = 8.0
		style.texture_margin_right = 28.0
		style.texture_margin_bottom = 8.0
		style.content_margin_left = 9.0
		style.content_margin_top = 5.0
		style.content_margin_right = 9.0
		style.content_margin_bottom = 5.0
		style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
		style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
		if selected:
			style.modulate_color = Color("#687a4e") if state != "pressed" else Color("#566642")
		elif state == "hover":
			style.modulate_color = Color(1.06, 1.02, 0.88, 1.0)
		return style
	var fill := Color("#687a4e") if selected else Color(0.96, 0.90, 0.74, 0.96)
	if state == "hover" and not selected:
		fill = Color("#fff5d5")
	elif state == "pressed":
		fill = Color("#566642")
	return _compact_style(fill, Color("#8b6c3e"), 13, 2, 7)


func _flower_card_style() -> StyleBox:
	if ResourceLoader.exists(FLOWER_GARDEN_CARD_ART):
		var style := StyleBoxTexture.new()
		style.texture = load(FLOWER_GARDEN_CARD_ART) as Texture2D
		style.texture_margin_left = 10.0
		style.texture_margin_top = 10.0
		style.texture_margin_right = 10.0
		style.texture_margin_bottom = 10.0
		style.content_margin_left = 10.0
		style.content_margin_top = 8.0
		style.content_margin_right = 10.0
		style.content_margin_bottom = 8.0
		style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
		style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
		return style
	return _compact_style(Color(0.98, 0.94, 0.82, 0.94), Color("#b28a4d"), 12, 2, 10)


func _inner_garden_style() -> StyleBoxFlat:
	var style := _compact_style(Color(1.0, 0.975, 0.88, 0.76), Color(0.63, 0.51, 0.31, 0.42), 9, 1, 7)
	return style


func _create_flower_icon(flower_id: String, icon_size: Vector2) -> Control:
	var texture_path := str(FLOWER_GARDEN_ICON_PATHS.get(flower_id, ""))
	if texture_path != "" and ResourceLoader.exists(texture_path):
		var icon := TextureRect.new()
		icon.texture = load(texture_path) as Texture2D
		icon.custom_minimum_size = icon_size
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return icon
	var fallback := Label.new()
	fallback.text = str(FlowerGardenManager.flower_definition(flower_id).get("icon", "✿"))
	fallback.custom_minimum_size = icon_size
	fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fallback.add_theme_font_size_override("font_size", int(icon_size.y * 0.48))
	fallback.add_theme_color_override("font_color", Color("#687a4e"))
	return fallback


func _apply_garden_action_button_style(button: Button, emphasized: bool = false) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", Color("#fff8df") if emphasized else Color("#44331f"))
	button.add_theme_color_override("font_hover_color", Color("#fff8df") if emphasized else Color("#302416"))
	button.add_theme_color_override("font_pressed_color", Color("#fff8df"))
	button.add_theme_color_override("font_disabled_color", Color(0.36, 0.32, 0.25, 0.52))
	button.add_theme_stylebox_override("normal", _garden_action_style("emphasized" if emphasized else "normal"))
	button.add_theme_stylebox_override("hover", _garden_action_style("hover_emphasized" if emphasized else "hover"))
	button.add_theme_stylebox_override("pressed", _garden_action_style("pressed"))
	button.add_theme_stylebox_override("disabled", _garden_action_style("disabled"))


func _garden_action_style(state: String) -> StyleBoxFlat:
	var fill := Color(0.96, 0.90, 0.74, 0.96)
	var border := Color("#9a7047")
	if state == "emphasized":
		fill = Color("#687a4e")
		border = Color("#465439")
	elif state == "hover_emphasized":
		fill = Color("#75885a")
		border = Color("#465439")
	elif state == "hover":
		fill = Color("#fff5d5")
	elif state == "pressed":
		fill = Color("#566642")
		border = Color("#465439")
	elif state == "disabled":
		fill = Color(0.78, 0.75, 0.66, 0.78)
		border = Color(0.48, 0.43, 0.34, 0.55)
	return _compact_style(fill, border, 9, 2, 6)


func _compact_style(fill: Color, border: Color, radius: int, width: int, margin: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin * 0.45
	style.content_margin_bottom = margin * 0.45
	return style


func _panel_style(fill: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 14.0
	style.content_margin_bottom = 14.0
	return style
