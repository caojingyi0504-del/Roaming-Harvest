extends Node3D

const DuelRulesScript = preload("res://scripts/duel/duel_rules.gd")

var local_slot := 0
var room_code := ""
var latest_snapshot: Dictionary = {}
var player_visuals: Dictionary = {}
var player_targets: Dictionary = {}
var station_visuals: Dictionary = {}
var stock_visuals: Dictionary = {}
var predicted_position := Vector2.ZERO
var input_accumulator := 0.0
var toast_generation := 0

var timer_label: Label
var score_label: Label
var opponent_label: Label
var held_label: Label
var orders_label: RichTextLabel
var detail_label: RichTextLabel
var toast_label: Label
var reconnect_overlay: ColorRect
var reconnect_label: Label
var result_overlay: ColorRect
var result_title: Label
var result_detail: RichTextLabel
var rematch_button: Button

func _ready() -> void:
	_build_world()
	_build_hud()
	set_process(true)
	set_process_unhandled_input(true)

func configure(slot: int, code: String) -> void:
	local_slot = clampi(slot, 0, 1)
	room_code = code
	predicted_position = Vector2(-7.0, -7.5) if local_slot == 0 else Vector2(7.0, -7.5)
	if detail_label != null:
		detail_label.text = "房间 %s\nWASD / 方向键移动　F / 左键交互" % room_code

func apply_snapshot(payload: Dictionary, slot: int) -> void:
	local_slot = clampi(slot, 0, 1)
	latest_snapshot = payload.duplicate(true)
	var players: Dictionary = payload.get("players", {})
	for player_index in range(2):
		var player: Dictionary = players.get(str(player_index), {})
		var packed_position: Array = player.get("position", [])
		if packed_position.size() >= 2:
			var target := Vector2(float(packed_position[0]), float(packed_position[1]))
			player_targets[player_index] = target
			if player_index == local_slot and predicted_position.distance_to(target) > 1.8:
				predicted_position = target
	_update_hud(payload)
	_update_world_state(payload)

func set_reconnecting(active: bool, message: String) -> void:
	if reconnect_overlay == null:
		return
	reconnect_overlay.visible = active
	reconnect_label.text = message

func show_toast(message: String, ok: bool = true) -> void:
	if toast_label == null:
		return
	toast_generation += 1
	var generation := toast_generation
	toast_label.text = message
	toast_label.add_theme_color_override("font_color", Color(0.18, 0.42, 0.12) if ok else Color(0.72, 0.16, 0.08))
	toast_label.visible = true
	var timer := get_tree().create_timer(2.2)
	timer.timeout.connect(func() -> void:
		if generation == toast_generation and is_instance_valid(toast_label):
			toast_label.visible = false
	)

func show_result(payload: Dictionary, slot: int) -> void:
	local_slot = clampi(slot, 0, 1)
	result_overlay.visible = true
	rematch_button.visible = true
	var winner := int(payload.get("winner", -1))
	result_title.text = "平局" if winner < 0 else ("胜利！" if winner == local_slot else "本局惜败")
	var result_players: Dictionary = payload.get("players", {})
	var mine: Dictionary = result_players.get(str(local_slot), {})
	var other: Dictionary = result_players.get(str(1 - local_slot), {})
	result_detail.text = "[center][font_size=24]%s　%d : %d　%s[/font_size]\n\n" % [
		str(mine.get("nickname", "我")), int(mine.get("score", 0)),
		int(other.get("score", 0)), str(other.get("nickname", "对手"))
	]
	result_detail.text += "我的出餐 %d　漏单 %d\n对手出餐 %d　漏单 %d\n\n20 秒内双方都点击重赛，将开始新一局。[/center]" % [
		int(mine.get("served", 0)), int(mine.get("missed", 0)),
		int(other.get("served", 0)), int(other.get("missed", 0))
	]
	var order_lines: Array[String] = []
	for order_variant in mine.get("orders", []):
		var order: Dictionary = order_variant
		var recipe_name := DuelRulesScript.recipe_name(str(order.get("recipe", "")))
		if str(order.get("status", "")) == "served":
			order_lines.append("[color=#4f7d32]✓ %s　+%d[/color]" % [recipe_name, int(order.get("score", 0))])
		else:
			order_lines.append("[color=#a93626]× %s　-50[/color]" % recipe_name)
	if not order_lines.is_empty():
		result_detail.text += "\n\n[b]我的订单明细[/b]\n%s" % "\n".join(order_lines)
	rematch_button.disabled = false
	rematch_button.text = "再来一局"

func show_connection_lost(message: String) -> void:
	set_reconnecting(false, "")
	result_overlay.visible = true
	result_title.text = "连接中断"
	result_detail.text = "[center][font_size=22]%s[/font_size]\n\n请返回主菜单后重新连接服务器。[/center]" % message
	rematch_button.visible = false

func _process(delta: float) -> void:
	var direction := _movement_direction()
	input_accumulator += delta
	if input_accumulator >= 1.0 / DuelRulesScript.SERVER_TICK_RATE:
		input_accumulator = fmod(input_accumulator, 1.0 / DuelRulesScript.SERVER_TICK_RATE)
		var session := get_parent()
		if session != null and session.has_method("submit_duel_input"):
			session.call("submit_duel_input", direction)
	predicted_position = DuelRulesScript.lane_clamp(
		predicted_position + direction * DuelRulesScript.MOVE_SPEED * delta,
		local_slot
	)
	for player_index in range(2):
		var visual: Node3D = player_visuals.get(player_index)
		if visual == null:
			continue
		var target: Vector2 = player_targets.get(player_index, Vector2.ZERO)
		if player_index == local_slot:
			if direction.length_squared() < 0.01:
				predicted_position = predicted_position.lerp(target, clampf(delta * 6.0, 0.0, 1.0))
			visual.position = _to_world(predicted_position, 0.34)
		else:
			var world_target := _to_world(target, 0.34)
			visual.position = visual.position.lerp(world_target, clampf(delta * 10.0, 0.0, 1.0))

func _unhandled_input(event: InputEvent) -> void:
	var interact := false
	if event is InputEventKey:
		var key_event := event as InputEventKey
		interact = key_event.pressed and not key_event.echo and key_event.keycode == KEY_F
	elif event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		interact = mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT
	if interact and not result_overlay.visible and not reconnect_overlay.visible:
		var session := get_parent()
		if session != null and session.has_method("submit_duel_interact"):
			session.call("submit_duel_interact")
		get_viewport().set_input_as_handled()

func _movement_direction() -> Vector2:
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1.0
	return direction.normalized()

func _build_world() -> void:
	var environment := WorldEnvironment.new()
	var resource := Environment.new()
	resource.background_mode = Environment.BG_COLOR
	resource.background_color = Color(0.65, 0.78, 0.72)
	resource.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	resource.ambient_light_color = Color.WHITE
	resource.ambient_light_energy = 0.82
	environment.environment = resource
	add_child(environment)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-58.0, -28.0, 0.0)
	light.light_energy = 1.1
	light.shadow_enabled = true
	add_child(light)

	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 23.0
	camera.position = Vector3(0.0, 20.0, 12.5)
	camera.rotation_degrees = Vector3(-58.0, 0.0, 0.0)
	camera.current = true
	add_child(camera)

	_add_box(Vector3(25.0, 0.28, 20.0), Vector3(0.0, -0.16, 0.0), Color(0.92, 0.82, 0.59), "ArenaFloor")
	_add_box(Vector3(0.15, 0.04, 19.0), Vector3(0.0, 0.03, 0.0), Color(0.45, 0.31, 0.16), "CenterLine")
	for slot in range(2):
		var side_color := Color(0.62, 0.76, 0.50) if slot == 0 else Color(0.80, 0.55, 0.38)
		var positions := DuelRulesScript.station_positions(slot)
		for station_id_variant in positions.keys():
			var station_id := str(station_id_variant)
			var position: Vector2 = positions[station_id]
			var station := _make_station_visual(station_id, side_color)
			station.position = _to_world(position, 0.0)
			add_child(station)
			station_visuals["%d:%s" % [slot, station_id]] = station
	var stock_positions := DuelRulesScript.stock_positions()
	for crop_variant in DuelRulesScript.CROPS:
		var crop := str(crop_variant)
		var stock_visual := _make_stock_visual(crop)
		stock_visual.position = _to_world(stock_positions[crop], 0.0)
		add_child(stock_visual)
		stock_visuals[crop] = stock_visual
	for slot in range(2):
		var player := _make_player_visual(slot)
		var initial := Vector2(-7.0, -7.5) if slot == 0 else Vector2(7.0, -7.5)
		player.position = _to_world(initial, 0.34)
		add_child(player)
		player_visuals[slot] = player
		player_targets[slot] = initial

func _make_station_visual(station_id: String, side_color: Color) -> Node3D:
	var root := Node3D.new()
	root.name = "Station_%s" % station_id
	var plate := _box_mesh(Vector3(2.1, 0.35, 1.55), side_color.darkened(0.25))
	plate.position.y = 0.18
	root.add_child(plate)
	var equipment_path := str(DuelRulesScript.EQUIPMENT_PATHS.get(station_id, ""))
	if equipment_path != "" and ResourceLoader.exists(equipment_path):
		var packed := load(equipment_path) as PackedScene
		if packed != null:
			var model := packed.instantiate() as Node3D
			if model != null:
				model.scale = Vector3.ONE * 0.78
				model.position.y = 0.35
				root.add_child(model)
	if root.get_child_count() == 1:
		var fallback := _box_mesh(Vector3(1.35, 0.8, 1.0), Color(0.92, 0.87, 0.72))
		fallback.position.y = 0.7
		root.add_child(fallback)
	var label := _world_label(str(DuelRulesScript.EQUIPMENT_NAMES.get(station_id, station_id)))
	label.name = "StatusLabel"
	label.position = Vector3(0.0, 2.0, 0.0)
	root.add_child(label)
	return root

func _make_stock_visual(crop: String) -> Node3D:
	var root := Node3D.new()
	root.name = "Stock_%s" % crop
	var crop_colors := {
		"carrot": Color(0.95, 0.46, 0.12), "pea": Color(0.33, 0.68, 0.22),
		"eggplant": Color(0.44, 0.20, 0.55), "bell_pepper": Color(0.92, 0.30, 0.16),
		"tomato": Color(0.86, 0.16, 0.10), "pumpkin": Color(0.93, 0.57, 0.12),
	}
	var crate := _box_mesh(Vector3(1.5, 0.42, 1.2), Color(0.53, 0.33, 0.15))
	crate.position.y = 0.21
	root.add_child(crate)
	var marker := _box_mesh(Vector3(0.72, 0.48, 0.72), crop_colors.get(crop, Color.WHITE))
	marker.position.y = 0.66
	root.add_child(marker)
	var label := _world_label("%s ×2" % DuelRulesScript.crop_name(crop))
	label.name = "CountLabel"
	label.position = Vector3(0.0, 1.45, 0.0)
	root.add_child(label)
	return root

func _make_player_visual(slot: int) -> Node3D:
	var root := Node3D.new()
	root.name = "Player%d" % (slot + 1)
	var body_color := Color(0.29, 0.64, 0.38) if slot == 0 else Color(0.86, 0.38, 0.20)
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.42
	capsule.height = 1.65
	body.mesh = capsule
	body.position.y = 0.82
	body.material_override = _material(body_color)
	root.add_child(body)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.52
	torus.outer_radius = 0.65
	ring.mesh = torus
	ring.position.y = 0.04
	ring.material_override = _material(Color(1.0, 0.88, 0.26))
	root.add_child(ring)
	return root

func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 20
	add_child(canvas)
	var top_panel := PanelContainer.new()
	top_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_panel.offset_left = 24.0
	top_panel.offset_top = 18.0
	top_panel.offset_right = -24.0
	top_panel.offset_bottom = 82.0
	top_panel.add_theme_stylebox_override("panel", _style(Color(0.97, 0.90, 0.70, 0.96), Color(0.33, 0.22, 0.12), 9, 2))
	canvas.add_child(top_panel)
	var score_row := HBoxContainer.new()
	score_row.alignment = BoxContainer.ALIGNMENT_CENTER
	score_row.add_theme_constant_override("separation", 38)
	top_panel.add_child(score_row)
	score_label = _label("我方 0", 22, HORIZONTAL_ALIGNMENT_CENTER)
	timer_label = _label("2:00", 29, HORIZONTAL_ALIGNMENT_CENTER)
	opponent_label = _label("对手 0", 22, HORIZONTAL_ALIGNMENT_CENTER)
	for item in [score_label, timer_label, opponent_label]:
		item.custom_minimum_size.x = 220.0
		score_row.add_child(item)

	var left_panel := PanelContainer.new()
	left_panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	left_panel.offset_left = 18.0
	left_panel.offset_top = 100.0
	left_panel.offset_right = 300.0
	left_panel.offset_bottom = -86.0
	left_panel.add_theme_stylebox_override("panel", _style(Color(0.97, 0.91, 0.75, 0.94), Color(0.39, 0.27, 0.14), 8, 2))
	canvas.add_child(left_panel)
	orders_label = RichTextLabel.new()
	orders_label.bbcode_enabled = true
	orders_label.fit_content = false
	orders_label.add_theme_font_size_override("normal_font_size", 16)
	orders_label.add_theme_color_override("default_color", Color(0.22, 0.15, 0.08))
	left_panel.add_child(orders_label)

	var bottom_panel := PanelContainer.new()
	bottom_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_panel.offset_left = 318.0
	bottom_panel.offset_top = -72.0
	bottom_panel.offset_right = -18.0
	bottom_panel.offset_bottom = -14.0
	bottom_panel.add_theme_stylebox_override("panel", _style(Color(0.97, 0.90, 0.70, 0.96), Color(0.39, 0.27, 0.14), 8, 2))
	canvas.add_child(bottom_panel)
	var bottom_row := HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 22)
	bottom_panel.add_child(bottom_row)
	held_label = _label("手持：无", 18, HORIZONTAL_ALIGNMENT_LEFT)
	held_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.add_child(held_label)
	detail_label = RichTextLabel.new()
	detail_label.bbcode_enabled = true
	detail_label.fit_content = true
	detail_label.custom_minimum_size.x = 390.0
	detail_label.add_theme_font_size_override("normal_font_size", 14)
	detail_label.text = "WASD / 方向键移动　F / 左键交互"
	bottom_row.add_child(detail_label)

	toast_label = _label("", 18, HORIZONTAL_ALIGNMENT_CENTER)
	toast_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast_label.position = Vector2(-260.0, 94.0)
	toast_label.size = Vector2(520.0, 42.0)
	toast_label.add_theme_stylebox_override("normal", _style(Color(1.0, 0.95, 0.80, 0.96), Color(0.52, 0.34, 0.13), 7, 2))
	toast_label.visible = false
	canvas.add_child(toast_label)

	reconnect_overlay = ColorRect.new()
	reconnect_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	reconnect_overlay.color = Color(0.08, 0.06, 0.04, 0.78)
	reconnect_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	reconnect_overlay.visible = false
	canvas.add_child(reconnect_overlay)
	reconnect_label = _label("正在重新连接……", 28, HORIZONTAL_ALIGNMENT_CENTER)
	reconnect_label.set_anchors_preset(Control.PRESET_CENTER)
	reconnect_label.position = Vector2(-300.0, -40.0)
	reconnect_label.size = Vector2(600.0, 80.0)
	reconnect_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.66))
	reconnect_overlay.add_child(reconnect_label)

	_build_result_overlay(canvas)

func _build_result_overlay(canvas: CanvasLayer) -> void:
	result_overlay = ColorRect.new()
	result_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result_overlay.color = Color(0.08, 0.06, 0.04, 0.72)
	result_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	result_overlay.visible = false
	canvas.add_child(result_overlay)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-310.0, -235.0)
	panel.size = Vector2(620.0, 470.0)
	panel.add_theme_stylebox_override("panel", _style(Color(0.98, 0.91, 0.72), Color(0.31, 0.20, 0.10), 14, 3))
	result_overlay.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	result_title = _label("比赛结束", 32, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(result_title)
	result_detail = RichTextLabel.new()
	result_detail.bbcode_enabled = true
	result_detail.fit_content = false
	result_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	result_detail.add_theme_font_size_override("normal_font_size", 18)
	box.add_child(result_detail)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)
	rematch_button = _button("再来一局", func() -> void:
		rematch_button.disabled = true
		rematch_button.text = "已确认，等待对手"
		var session := get_parent()
		if session != null and session.has_method("request_rematch"):
			session.call("request_rematch")
	)
	row.add_child(rematch_button)
	row.add_child(_button("返回主菜单", func() -> void:
		var session := get_parent()
		if session != null and session.has_method("leave_duel"):
			session.call("leave_duel")
	))

func _update_hud(snapshot: Dictionary) -> void:
	var remaining := maxf(float(snapshot.get("remaining", 0.0)), 0.0)
	var seconds := int(ceil(remaining))
	timer_label.text = "%d:%02d" % [seconds / 60, seconds % 60]
	var players: Dictionary = snapshot.get("players", {})
	var mine: Dictionary = players.get(str(local_slot), {})
	var other: Dictionary = players.get(str(1 - local_slot), {})
	score_label.text = "%s　%d" % [str(mine.get("nickname", "我方")), int(mine.get("score", 0))]
	opponent_label.text = "%d　%s" % [int(other.get("score", 0)), str(other.get("nickname", "对手"))]
	var held: Dictionary = mine.get("held", {})
	if held.is_empty():
		held_label.text = "手持：无"
	elif str(held.get("kind", "")) == "dish":
		held_label.text = "手持：%s" % DuelRulesScript.recipe_name(str(held.get("recipe", "")))
	else:
		var stage_names := {"raw": "原料", "washed": "已洗", "chopped": "已切"}
		held_label.text = "手持：%s（%s）" % [DuelRulesScript.crop_name(str(held.get("crop", ""))), str(stage_names.get(str(held.get("stage", "")), ""))]
	var stock: Dictionary = snapshot.get("stock", {})
	var stock_parts: Array[String] = []
	for crop_variant in DuelRulesScript.CROPS:
		var crop := str(crop_variant)
		stock_parts.append("%s%d" % [DuelRulesScript.crop_name(crop), int(stock.get(crop, 0))])
	detail_label.text = "共享：%s\n房间 %s　F / 左键交互" % ["　".join(stock_parts), room_code]
	_update_orders(mine, float(snapshot.get("elapsed", 0.0)))

func _update_orders(player: Dictionary, elapsed: float) -> void:
	var lines: Array[String] = ["[center][font_size=22]我的订单[/font_size][/center]"]
	for order_variant in player.get("orders", []):
		var order: Dictionary = order_variant
		var status := str(order.get("status", "upcoming"))
		var recipe := DuelRulesScript.recipe_name(str(order.get("recipe", "")))
		if status == "served":
			lines.append("[color=#4f7d32]✓ %s　+%d[/color]" % [recipe, int(order.get("score", 0))])
		elif status == "missed":
			lines.append("[color=#a93626]× %s　已超时[/color]" % recipe)
		elif status == "upcoming":
			lines.append("[color=#796f5a]○ %s　%d秒后到达[/color]" % [recipe, maxi(int(ceil(float(order.get("arrival", 0.0)) - elapsed)), 0)])
		else:
			lines.append("[color=#5a3218]● %s　剩%d秒[/color]" % [recipe, maxi(int(ceil(float(order.get("deadline", 0.0)) - elapsed)), 0)])
	orders_label.text = "\n".join(lines)

func _update_world_state(snapshot: Dictionary) -> void:
	var players: Dictionary = snapshot.get("players", {})
	for slot in range(2):
		var player: Dictionary = players.get(str(slot), {})
		var stations: Dictionary = player.get("stations", {})
		for station_id_variant in stations.keys():
			var station_id := str(station_id_variant)
			var visual: Node3D = station_visuals.get("%d:%s" % [slot, station_id])
			if visual == null:
				continue
			var station: Dictionary = stations[station_id]
			var state := str(station.get("state", "idle"))
			visual.scale.y = 1.08 if state == "working" else 1.0
			visual.rotation.y = 0.0
			var status_label := visual.get_node_or_null("StatusLabel") as Label3D
			if status_label != null:
				var state_names := {"idle": "空闲", "working": "加工中", "done": "可取出", "ready": "可取出", "burnt": "已烧焦"}
				var suffix := " %.1fs" % float(station.get("remaining", 0.0)) if state == "working" else ""
				status_label.text = "%s　%s%s" % [str(DuelRulesScript.EQUIPMENT_NAMES.get(station_id, station_id)), str(state_names.get(state, state)), suffix]
	var stock: Dictionary = snapshot.get("stock", {})
	for crop_variant in stock.keys():
		var crop := str(crop_variant)
		var visual: Node3D = stock_visuals.get(crop)
		if visual != null:
			visual.visible = true
			var count := int(stock.get(crop, 0))
			var marker := visual.get_node_or_null("CountLabel") as Label3D
			if marker != null:
				marker.text = "%s ×%d" % [DuelRulesScript.crop_name(crop), count]
				marker.modulate = Color(0.52, 0.48, 0.42) if count <= 0 else Color.WHITE

func _to_world(value: Vector2, y: float) -> Vector3:
	return Vector3(value.x, y, value.y)

func _add_box(size: Vector3, position_value: Vector3, color: Color, node_name: String) -> MeshInstance3D:
	var instance := _box_mesh(size, color)
	instance.name = node_name
	instance.position = position_value
	add_child(instance)
	return instance

func _box_mesh(size: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = _material(color)
	return instance

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.84
	return material

func _world_label(text_value: String) -> Label3D:
	var label := Label3D.new()
	label.text = text_value
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 30
	label.pixel_size = 0.012
	label.outline_size = 7
	label.modulate = Color(0.24, 0.16, 0.08)
	label.outline_modulate = Color(1.0, 0.94, 0.78)
	label.no_depth_test = true
	return label

func _label(text_value: String, font_size: int, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.23, 0.15, 0.08))
	return label

func _button(text_value: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(190.0, 48.0)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_stylebox_override("normal", _style(Color(1.0, 0.95, 0.80), Color(0.46, 0.31, 0.14), 7, 2))
	button.add_theme_stylebox_override("hover", _style(Color(1.0, 0.83, 0.44), Color(0.58, 0.30, 0.08), 7, 2))
	button.pressed.connect(action)
	return button

func _style(fill: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	return style
