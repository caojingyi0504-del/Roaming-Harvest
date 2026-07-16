extends Node
class_name WardrobeSystem

const WardrobeCatalog = preload("res://scripts/wardrobe_catalog.gd")
const EVENT_INTERACT_RADIUS := 2.25
const BUNDLE_INTERACT_RADIUS := 1.75
const DEFAULT_VISUAL_SCALE := 2.35
const TAILOR_OFFSET := Vector3(6.6, 0.0, 3.8)
const BUNDLE_OFFSETS := [
	Vector3(-6.8, 0.0, 5.6),
	Vector3(8.4, 0.0, -4.8),
	Vector3(-3.2, 0.0, -8.6),
]

var _world: Node3D
var _hud_root: Control
var _player: Node3D
var _camper: Node3D
var _manager: Node

var _event_root: Node3D
var _tailor: Node3D
var _trunk: Node3D
var _event_marker: Label3D
var _bundle_nodes: Dictionary = {}
var _event_announced := false
var _animation_time := 0.0

var _objective_panel: PanelContainer
var _objective_label: Label
var _story_overlay: Control
var _story_title: Label
var _story_body: Label
var _story_primary: Button
var _story_secondary: Button
var _story_mode := ""

var _wardrobe_overlay: Control
var _wardrobe_coin_label: Label
var _wardrobe_cards: GridContainer
var _wardrobe_name_label: Label
var _wardrobe_description_label: Label
var _wardrobe_action_button: Button
var _preview_container: SubViewportContainer
var _preview_viewport: SubViewport
var _preview_model_root: Node3D
var _preview_concept: TextureRect
var _preview_hint: Label
var _preview_model: Node3D
var _preview_dragging := false
var _preview_last_mouse := Vector2.ZERO
var _preview_yaw := 0.0
var _selected_outfit_id := WardrobeCatalog.DEFAULT_OUTFIT_ID

var _materials: Dictionary = {}

func setup(world: Node3D, hud_root: Control, player: Node3D, camper: Node3D) -> void:
	_world = world
	_hud_root = hud_root
	_player = player
	_camper = camper
	_manager = get_node_or_null("/root/WardrobeManager")
	if _manager != null and str(_manager.event_state) == _manager.EVENT_LOCKED and _world.has_method("_business_level_star_count") and int(_world.call("_business_level_star_count", 3)) >= 1:
		_manager.mark_event_pending()
	_create_objective_ui()
	_create_story_ui()
	_create_wardrobe_ui()
	if _manager != null:
		_manager.state_changed.connect(_on_manager_state_changed)
		_manager.outfit_equipped.connect(_on_outfit_equipped)
	_restore_event_world()
	_apply_equipped_outfit()

func update(delta: float) -> void:
	_animation_time += maxf(delta, 0.0)
	if _manager == null:
		return
	if str(_manager.event_state) != _manager.EVENT_LOCKED and _event_root == null and _can_activate_world_event():
		_create_event_world()
	if str(_manager.event_state) == _manager.EVENT_PENDING and _event_root != null and not _event_announced and _can_activate_world_event():
		_event_announced = true
		_notify("突发事件：房车旁来了一位流动裁缝")
	_update_event_animation()
	_update_objective_ui()
	if is_overlay_open():
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func mark_event_pending() -> bool:
	if _manager == null:
		return false
	return bool(_manager.mark_event_pending())

func is_overlay_open() -> bool:
	return (_story_overlay != null and _story_overlay.visible) or (_wardrobe_overlay != null and _wardrobe_overlay.visible)

func handle_unhandled_input(event: InputEvent) -> bool:
	if not is_overlay_open():
		return false
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if _wardrobe_overlay != null and _wardrobe_overlay.visible:
			_close_wardrobe()
		else:
			_close_story()
		return true
	return true

func append_interaction_options(options: Array[Dictionary]) -> void:
	if _manager == null or is_overlay_open() or _event_root == null or _player == null:
		return
	var state := str(_manager.event_state)
	if state == _manager.EVENT_COLLECTING:
		var nearest_bundle := _nearest_bundle()
		if not nearest_bundle.is_empty():
			options.append({
				"action": "wardrobe_bundle",
				"bundle_id": str(nearest_bundle.get("id", "")),
				"text": "拾起被风吹散的衣物包",
				"world_position": nearest_bundle.get("position", _player.global_position),
			})
	if _is_player_near(_tailor, EVENT_INTERACT_RADIUS):
		if state == _manager.EVENT_PENDING:
			options.append({"action": "wardrobe_tailor", "text": "询问流动裁缝发生了什么", "world_position": _tailor.global_position})
		elif state == _manager.EVENT_COLLECTING:
			var text := "把找回的衣物交给裁缝" if bool(_manager.can_complete_event()) else "与流动裁缝交谈"
			options.append({"action": "wardrobe_tailor", "text": text, "world_position": _tailor.global_position})
	if state == _manager.EVENT_UNLOCKED and _is_player_near(_trunk, EVENT_INTERACT_RADIUS):
		options.append({"action": "wardrobe_trunk", "text": "打开服装衣箱", "world_position": _trunk.global_position})

func execute_interaction(action: String, option: Dictionary) -> bool:
	match action:
		"wardrobe_bundle":
			return _collect_bundle(str(option.get("bundle_id", "")))
		"wardrobe_tailor":
			return _interact_tailor()
		"wardrobe_trunk":
			return open_wardrobe()
	return false

func open_wardrobe() -> bool:
	if _manager == null or not bool(_manager.is_wardrobe_unlocked()) or _wardrobe_overlay == null:
		return false
	_selected_outfit_id = str(_manager.equipped_outfit_id)
	_wardrobe_overlay.visible = true
	_wardrobe_overlay.move_to_front()
	_rebuild_outfit_cards()
	_refresh_outfit_detail()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	return true

func refresh_coin_balance() -> void:
	if _wardrobe_coin_label != null and _world != null:
		_wardrobe_coin_label.text = "个人金币  %d" % int(_world.get("_coins"))
	if _wardrobe_overlay != null and _wardrobe_overlay.visible:
		_refresh_outfit_detail()

func _restore_event_world() -> void:
	if _manager == null:
		return
	if str(_manager.event_state) != _manager.EVENT_LOCKED and _can_activate_world_event():
		_create_event_world()

func _can_activate_world_event() -> bool:
	if _world == null or _player == null or _camper == null:
		return false
	if not bool(_world.get("_chapter_one_active")):
		return false
	if bool(_world.get("_chapter_transitioning")) or bool(_world.get("_kitchen_business_active")) or bool(_world.get("_camper_driving")):
		return false
	if bool(_world.get("_dialogue_open")) or bool(_world.get("_map_open")) or bool(_world.get("_warehouse_panel_open")) or bool(_world.get("_kitchen_equipment_panel_open")) or bool(_world.get("_kitchen_upgrade_panel_open")):
		return false
	if _world.has_method("_day_night_should_pause") and bool(_world.call("_day_night_should_pause")):
		return false
	for property_name in ["_business_result_overlay", "_business_prep_overlay", "_reward_overlay", "_shop_overlay", "_wind_chase_guide_overlay", "_sifter_guide_overlay", "_camper_drive_note_overlay"]:
		var panel := _world.get(property_name) as CanvasItem
		if panel != null and panel.visible:
			return false
	return true

func _create_event_world() -> void:
	if _event_root != null or _world == null or _camper == null:
		return
	_event_root = Node3D.new()
	_event_root.name = "WardrobeTailorEvent"
	add_child(_event_root)
	var anchor := _safe_ground_position(_camper.global_position + TAILOR_OFFSET.rotated(Vector3.UP, _camper.rotation.y), 0)
	_tailor = _create_tailor(anchor)
	_trunk = _create_trunk(_safe_ground_position(anchor + Vector3(2.5, 0.0, 0.25), 1))
	if _world.has_method("_add_circle_blocker"):
		_world.call("_add_circle_blocker", _tailor.global_position, 0.72)
		_world.call("_add_circle_blocker", _trunk.global_position, 0.72)
	_event_marker = Label3D.new()
	_event_marker.text = "!"
	_event_marker.font_size = 74
	_event_marker.modulate = Color(0.98, 0.72, 0.20)
	_event_marker.outline_modulate = Color(0.32, 0.23, 0.12, 0.95)
	_event_marker.outline_size = 10
	_event_marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_event_marker.no_depth_test = true
	_event_marker.position = Vector3(0.0, 3.35, 0.0)
	_tailor.add_child(_event_marker)
	_spawn_missing_bundles()

func _create_tailor(position: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = "TravelingTailor"
	_event_root.add_child(root)
	root.global_position = position
	_add_sphere(root, "Body", Vector3(0.0, 1.15, 0.0), Vector3(0.72, 0.88, 0.62), _material("cream_cloth", Color("d8cfb5")))
	_add_sphere(root, "Head", Vector3(0.0, 2.18, 0.0), Vector3(0.62, 0.58, 0.58), _material("warm_fur", Color("b9a98c")))
	_add_cone(root, "EarLeft", Vector3(-0.30, 2.82, 0.0), 0.24, 0.78, _material("warm_fur", Color("b9a98c")), Vector3(0.0, 0.0, -0.12))
	_add_cone(root, "EarRight", Vector3(0.30, 2.82, 0.0), 0.24, 0.78, _material("warm_fur", Color("b9a98c")), Vector3(0.0, 0.0, 0.12))
	_add_box(root, "Apron", Vector3(0.0, 1.18, -0.54), Vector3(0.82, 0.92, 0.12), _material("olive", Color("7d8762")))
	_add_box(root, "Satchel", Vector3(0.72, 1.15, 0.0), Vector3(0.48, 0.62, 0.22), _material("terracotta", Color("a9664d")))
	_add_cylinder(root, "FootLeft", Vector3(-0.28, 0.35, 0.0), 0.20, 0.52, _material("boots", Color("64594a")))
	_add_cylinder(root, "FootRight", Vector3(0.28, 0.35, 0.0), 0.20, 0.52, _material("boots", Color("64594a")))
	root.rotation.y = _yaw_toward(position, _player.global_position if _player != null else position + Vector3.FORWARD)
	return root

func _create_trunk(position: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = "TailorWardrobeTrunk"
	_event_root.add_child(root)
	root.global_position = position
	_add_box(root, "Case", Vector3(0.0, 0.55, 0.0), Vector3(1.65, 0.92, 0.88), _material("trunk_cloth", Color("d9d0b5")))
	_add_box(root, "Lid", Vector3(0.0, 1.03, -0.06), Vector3(1.72, 0.18, 0.94), _material("trunk_cloth_light", Color("eee5cb")))
	_add_box(root, "BandLeft", Vector3(-0.53, 0.62, -0.47), Vector3(0.16, 1.05, 0.08), _material("copper", Color("9a7650")))
	_add_box(root, "BandRight", Vector3(0.53, 0.62, -0.47), Vector3(0.16, 1.05, 0.08), _material("copper", Color("9a7650")))
	_add_box(root, "Latch", Vector3(0.0, 0.60, -0.51), Vector3(0.34, 0.28, 0.10), _material("dark_copper", Color("6c5540")))
	return root

func _spawn_missing_bundles() -> void:
	if _manager == null or str(_manager.event_state) != _manager.EVENT_COLLECTING:
		return
	for index in range(3):
		var bundle_id := "bundle_%d" % (index + 1)
		if _manager.collected_bundle_ids.has(bundle_id) or _bundle_nodes.has(bundle_id):
			continue
		var preferred: Vector3 = _camper.global_position + (BUNDLE_OFFSETS[index] as Vector3).rotated(Vector3.UP, _camper.rotation.y)
		var bundle := _create_bundle(bundle_id, _safe_ground_position(preferred, index + 2), index)
		_bundle_nodes[bundle_id] = bundle

func _create_bundle(bundle_id: String, position: Vector3, index: int) -> Node3D:
	var root := Node3D.new()
	root.name = "WindblownClothing_%s" % bundle_id
	root.set_meta("bundle_id", bundle_id)
	root.set_meta("base_y", position.y)
	root.set_meta("phase", float(index) * 1.7)
	_event_root.add_child(root)
	root.global_position = position
	var cloth_colors := [Color("87966e"), Color("b97558"), Color("829ea3")]
	_add_box(root, "FoldedCloth", Vector3(0.0, 0.22, 0.0), Vector3(0.82, 0.34, 0.58), _material("bundle_%d" % index, cloth_colors[index]))
	_add_cylinder(root, "Tie", Vector3(0.0, 0.22, 0.0), 0.10, 0.88, _material("bundle_tie", Color("d6c9a4")), Vector3(0.0, 0.0, PI * 0.5))
	return root

func _safe_ground_position(preferred: Vector3, seed_offset: int) -> Vector3:
	var candidates: Array[Vector3] = [preferred]
	for ring in range(1, 6):
		for step in range(8):
			var angle := TAU * float(step) / 8.0 + float(seed_offset) * 0.37
			candidates.append(preferred + Vector3(cos(angle), 0.0, sin(angle)) * float(ring) * 1.35)
	for candidate in candidates:
		if bool(_world.call("_is_inside_pond", candidate.x, candidate.z, 0.85)):
			continue
		if bool(_world.call("_is_blocked_by_solid", candidate)):
			continue
		candidate.y = float(_world.call("_height_at", candidate.x, candidate.z))
		return candidate
	preferred.y = float(_world.call("_height_at", preferred.x, preferred.z))
	return preferred

func _nearest_bundle() -> Dictionary:
	if _player == null:
		return {}
	var best_id := ""
	var best_node: Node3D
	var best_distance := BUNDLE_INTERACT_RADIUS * BUNDLE_INTERACT_RADIUS
	for raw_id in _bundle_nodes.keys():
		var node := _bundle_nodes[raw_id] as Node3D
		if node == null or not is_instance_valid(node):
			continue
		var distance := _flat_distance_squared(_player.global_position, node.global_position)
		if distance <= best_distance:
			best_distance = distance
			best_id = str(raw_id)
			best_node = node
	if best_id == "" or best_node == null:
		return {}
	return {"id": best_id, "position": best_node.global_position}

func _collect_bundle(bundle_id: String) -> bool:
	if _manager == null or not _bundle_nodes.has(bundle_id):
		return false
	var node := _bundle_nodes.get(bundle_id) as Node3D
	if node == null or not _is_player_near(node, BUNDLE_INTERACT_RADIUS):
		return false
	if not bool(_manager.collect_bundle(bundle_id)):
		return false
	_bundle_nodes.erase(bundle_id)
	var tween := node.create_tween()
	tween.tween_property(node, "scale", Vector3(1.18, 1.18, 1.18), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", Vector3.ZERO, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(node.queue_free)
	_notify("找回衣物包 %d/3" % int(_manager.collected_bundle_count()))
	if bool(_manager.can_complete_event()):
		_notify("衣物已经找齐，回去交给流动裁缝吧")
	return true

func _interact_tailor() -> bool:
	if _manager == null or not _is_player_near(_tailor, EVENT_INTERACT_RADIUS):
		return false
	var state := str(_manager.event_state)
	if state == _manager.EVENT_PENDING:
		_open_story("intro")
		return true
	if state == _manager.EVENT_COLLECTING:
		if bool(_manager.can_complete_event()):
			_open_story("complete")
		else:
			_notify("还有 %d 件衣物没有找回来" % maxi(3 - int(_manager.collected_bundle_count()), 0))
		return true
	return false

func _open_story(mode: String) -> void:
	if _story_overlay == null:
		return
	_story_mode = mode
	_story_overlay.visible = true
	_story_overlay.move_to_front()
	if mode == "intro":
		_story_title.text = "突发事件 · 风中的衣箱"
		_story_body.text = "流动裁缝刚在房车旁停下，一阵风却把衣箱吹开了。\n\n三件包好的衣物落在附近的草地上。帮忙找回来，裁缝就愿意把衣箱留在这里，为你制作新的旅装。"
		_story_primary.text = "帮忙找回衣物"
		_story_secondary.text = "稍后再说"
	else:
		_story_title.text = "新功能开启 · 服装衣箱"
		_story_body.text = "三件衣物都平安回到了箱子里。\n\n流动裁缝决定在房车旁多停留一阵。今后可以使用个人金币购买服装，并随时在衣箱中换装。服装只改变外观，不附带数值效果。"
		_story_primary.text = "打开服装衣箱"
		_story_secondary.text = "稍后再看"
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_story_primary_pressed() -> void:
	if _manager == null:
		return
	if _story_mode == "intro":
		if bool(_manager.begin_event()):
			_spawn_missing_bundles()
			_notify("帮流动裁缝找回衣物 0/3")
		_close_story()
	elif _story_mode == "complete":
		if bool(_manager.unlock_wardrobe()):
			_notify("服装衣箱已经开启")
		_close_story()
		open_wardrobe()

func _close_story() -> void:
	if _story_overlay != null:
		_story_overlay.visible = false
	_story_mode = ""
	if not is_overlay_open():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _close_wardrobe() -> void:
	if _wardrobe_overlay != null:
		_wardrobe_overlay.visible = false
	_clear_preview_model()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _create_objective_ui() -> void:
	if _hud_root == null:
		return
	_objective_panel = PanelContainer.new()
	_objective_panel.name = "WardrobeEventObjective"
	_objective_panel.visible = false
	_objective_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_objective_panel.z_index = 6
	_objective_panel.anchor_left = 1.0
	_objective_panel.anchor_top = 0.0
	_objective_panel.anchor_right = 1.0
	_objective_panel.anchor_bottom = 0.0
	_objective_panel.offset_left = -362.0
	_objective_panel.offset_top = 82.0
	_objective_panel.offset_right = -22.0
	_objective_panel.offset_bottom = 146.0
	_objective_panel.add_theme_stylebox_override("panel", _style(Color(0.95, 0.91, 0.78, 0.94), Color(0.52, 0.43, 0.30, 0.92), 13, 2))
	_hud_root.add_child(_objective_panel)
	_objective_label = Label.new()
	_objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective_label.add_theme_font_size_override("font_size", 15)
	_objective_label.add_theme_color_override("font_color", Color(0.25, 0.22, 0.16))
	_objective_panel.add_child(_objective_label)

func _update_objective_ui() -> void:
	if _objective_panel == null or _manager == null:
		return
	var state := str(_manager.event_state)
	_objective_panel.visible = state == _manager.EVENT_PENDING or state == _manager.EVENT_COLLECTING
	if state == _manager.EVENT_PENDING:
		_objective_label.text = "突发事件：房车旁来了流动裁缝"
	elif state == _manager.EVENT_COLLECTING:
		var count := int(_manager.collected_bundle_count())
		_objective_label.text = "帮流动裁缝找回衣物  %d/3%s" % [count, " · 回去交付" if count >= 3 else ""]

func _create_story_ui() -> void:
	if _hud_root == null:
		return
	_story_overlay = Control.new()
	_story_overlay.name = "WardrobeStoryOverlay"
	_story_overlay.visible = false
	_story_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_story_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_story_overlay.z_index = 104
	_hud_root.add_child(_story_overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.10, 0.10, 0.38)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_story_overlay.add_child(dim)
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -310.0
	panel.offset_top = -210.0
	panel.offset_right = 310.0
	panel.offset_bottom = 210.0
	panel.add_theme_stylebox_override("panel", _style(Color("f1ead7"), Color("8c7254"), 22, 3))
	_story_overlay.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	_story_title = Label.new()
	_story_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_story_title.add_theme_font_size_override("font_size", 25)
	_story_title.add_theme_color_override("font_color", Color("473b2d"))
	box.add_child(_story_title)
	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 2)
	divider.color = Color("a17b50")
	box.add_child(divider)
	_story_body = Label.new()
	_story_body.custom_minimum_size = Vector2(0, 225)
	_story_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_story_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_story_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_story_body.add_theme_font_size_override("font_size", 18)
	_story_body.add_theme_color_override("font_color", Color("51483b"))
	box.add_child(_story_body)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 14)
	box.add_child(buttons)
	_story_secondary = _make_button("稍后再说", false)
	_story_secondary.pressed.connect(_close_story)
	buttons.add_child(_story_secondary)
	_story_primary = _make_button("继续", true)
	_story_primary.pressed.connect(_on_story_primary_pressed)
	buttons.add_child(_story_primary)

func _create_wardrobe_ui() -> void:
	if _hud_root == null:
		return
	_wardrobe_overlay = Control.new()
	_wardrobe_overlay.name = "WardrobeOverlay"
	_wardrobe_overlay.visible = false
	_wardrobe_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_wardrobe_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_wardrobe_overlay.z_index = 105
	_hud_root.add_child(_wardrobe_overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.07, 0.09, 0.09, 0.44)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wardrobe_overlay.add_child(dim)
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -430.0
	panel.offset_top = -260.0
	panel.offset_right = 430.0
	panel.offset_bottom = 260.0
	panel.add_theme_stylebox_override("panel", _style(Color("eee7d4"), Color("8b704f"), 22, 3))
	_wardrobe_overlay.add_child(panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	panel.add_child(outer)
	var header := HBoxContainer.new()
	outer.add_child(header)
	var title := Label.new()
	title.text = "流动裁缝的服装衣箱"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("40382d"))
	header.add_child(title)
	_wardrobe_coin_label = Label.new()
	_wardrobe_coin_label.add_theme_font_size_override("font_size", 18)
	_wardrobe_coin_label.add_theme_color_override("font_color", Color("78602f"))
	header.add_child(_wardrobe_coin_label)
	var close_button := _make_button("关闭", false)
	close_button.custom_minimum_size = Vector2(84, 38)
	close_button.pressed.connect(_close_wardrobe)
	header.add_child(close_button)
	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 2)
	divider.color = Color("9b7952")
	outer.add_child(divider)
	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 14)
	outer.add_child(content)
	var preview_box := PanelContainer.new()
	preview_box.custom_minimum_size = Vector2(308, 416)
	preview_box.add_theme_stylebox_override("panel", _style(Color("d9ddcf"), Color("a07e55"), 16, 2))
	content.add_child(preview_box)
	var preview_stack := Control.new()
	preview_stack.custom_minimum_size = Vector2(292, 400)
	preview_box.add_child(preview_stack)
	_preview_container = SubViewportContainer.new()
	_preview_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_preview_container.stretch = true
	_preview_container.gui_input.connect(_on_preview_input)
	preview_stack.add_child(_preview_container)
	_preview_viewport = SubViewport.new()
	_preview_viewport.size = Vector2i(292, 400)
	_preview_viewport.transparent_bg = true
	_preview_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_preview_container.add_child(_preview_viewport)
	_preview_model_root = Node3D.new()
	_preview_viewport.add_child(_preview_model_root)
	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 1.34, 5.4)
	camera.look_at_from_position(camera.position, Vector3(0.0, 1.30, 0.0), Vector3.UP)
	_preview_viewport.add_child(camera)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-42, -28, 0)
	light.light_color = Color("fff0cf")
	light.light_energy = 1.15
	light.shadow_enabled = false
	_preview_viewport.add_child(light)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-18, 150, 0)
	fill.light_color = Color("cbd8d6")
	fill.light_energy = 0.55
	fill.shadow_enabled = false
	_preview_viewport.add_child(fill)
	_preview_concept = TextureRect.new()
	_preview_concept.set_anchors_preset(Control.PRESET_FULL_RECT)
	_preview_concept.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview_concept.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_preview_concept.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_stack.add_child(_preview_concept)
	_preview_hint = Label.new()
	_preview_hint.anchor_left = 0.08
	_preview_hint.anchor_top = 0.78
	_preview_hint.anchor_right = 0.92
	_preview_hint.anchor_bottom = 0.96
	_preview_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_preview_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_preview_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview_hint.add_theme_font_size_override("font_size", 14)
	_preview_hint.add_theme_color_override("font_color", Color("5c5547"))
	_preview_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_stack.add_child(_preview_hint)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	content.add_child(right)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 240)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(scroll)
	_wardrobe_cards = GridContainer.new()
	_wardrobe_cards.columns = 2
	_wardrobe_cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_wardrobe_cards.add_theme_constant_override("h_separation", 8)
	_wardrobe_cards.add_theme_constant_override("v_separation", 8)
	scroll.add_child(_wardrobe_cards)
	var detail := PanelContainer.new()
	detail.custom_minimum_size = Vector2(0, 145)
	detail.add_theme_stylebox_override("panel", _style(Color("f6f0df"), Color("b19a77"), 13, 1))
	right.add_child(detail)
	var detail_box := VBoxContainer.new()
	detail_box.add_theme_constant_override("separation", 5)
	detail.add_child(detail_box)
	_wardrobe_name_label = Label.new()
	_wardrobe_name_label.add_theme_font_size_override("font_size", 19)
	_wardrobe_name_label.add_theme_color_override("font_color", Color("40372d"))
	detail_box.add_child(_wardrobe_name_label)
	_wardrobe_description_label = Label.new()
	_wardrobe_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_wardrobe_description_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_wardrobe_description_label.add_theme_font_size_override("font_size", 14)
	_wardrobe_description_label.add_theme_color_override("font_color", Color("625849"))
	detail_box.add_child(_wardrobe_description_label)
	_wardrobe_action_button = _make_button("穿上", true)
	_wardrobe_action_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_wardrobe_action_button.pressed.connect(_on_wardrobe_action_pressed)
	detail_box.add_child(_wardrobe_action_button)

func _rebuild_outfit_cards() -> void:
	if _wardrobe_cards == null or _manager == null:
		return
	for child in _wardrobe_cards.get_children():
		child.queue_free()
	for outfit in WardrobeCatalog.all():
		var outfit_id := str(outfit.get("id", ""))
		var owned := bool(_manager.owns_outfit(outfit_id))
		var equipped := str(_manager.equipped_outfit_id) == outfit_id
		var available := WardrobeCatalog.model_is_available(outfit_id)
		var card := Button.new()
		card.custom_minimum_size = Vector2(224, 88)
		card.text = "%s\n%s" % [str(outfit.get("display_name", "")), "已穿着" if equipped else ("已拥有" if owned else ("%d 金币" % int(outfit.get("price", 0)) if available else "模型待导入"))]
		card.alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_theme_font_size_override("font_size", 15)
		var accent: Color = outfit.get("accent", Color("8b806c"))
		var fill := Color("faf4df") if not equipped else Color(accent.r, accent.g, accent.b, 0.36)
		card.add_theme_stylebox_override("normal", _style(fill, accent, 13, 2 if outfit_id == _selected_outfit_id else 1))
		card.add_theme_stylebox_override("hover", _style(Color("fff8e5"), accent.lightened(0.10), 13, 2))
		card.add_theme_stylebox_override("pressed", _style(Color(accent.r, accent.g, accent.b, 0.28), accent, 13, 2))
		card.pressed.connect(_select_outfit.bind(outfit_id))
		_wardrobe_cards.add_child(card)

func _select_outfit(outfit_id: String) -> void:
	if not WardrobeCatalog.has_outfit(outfit_id):
		return
	_selected_outfit_id = outfit_id
	_rebuild_outfit_cards()
	_refresh_outfit_detail()

func _refresh_outfit_detail() -> void:
	if _manager == null:
		return
	var outfit := WardrobeCatalog.get_outfit(_selected_outfit_id)
	if outfit.is_empty():
		return
	refresh_coin_balance_only()
	_wardrobe_name_label.text = str(outfit.get("display_name", ""))
	_wardrobe_description_label.text = str(outfit.get("description", ""))
	var owned := bool(_manager.owns_outfit(_selected_outfit_id))
	var equipped := str(_manager.equipped_outfit_id) == _selected_outfit_id
	var available := WardrobeCatalog.model_is_available(_selected_outfit_id)
	var price := int(outfit.get("price", 0))
	var coins := int(_world.get("_coins"))
	_wardrobe_action_button.disabled = false
	if equipped:
		_wardrobe_action_button.text = "已穿着"
		_wardrobe_action_button.disabled = true
	elif owned:
		_wardrobe_action_button.text = "穿上"
		_wardrobe_action_button.disabled = not available
	elif not available:
		_wardrobe_action_button.text = "模型待导入"
		_wardrobe_action_button.disabled = true
	elif coins < price:
		_wardrobe_action_button.text = "还差 %d 金币" % (price - coins)
		_wardrobe_action_button.disabled = true
	else:
		_wardrobe_action_button.text = "花费 %d 金币购买并穿上" % price
	_update_preview(outfit)

func refresh_coin_balance_only() -> void:
	if _wardrobe_coin_label != null and _world != null:
		_wardrobe_coin_label.text = "个人金币  %d" % int(_world.get("_coins"))

func _on_wardrobe_action_pressed() -> void:
	if _manager == null or _selected_outfit_id == "":
		return
	if bool(_manager.owns_outfit(_selected_outfit_id)):
		if bool(_manager.equip_outfit(_selected_outfit_id)):
			_apply_equipped_outfit()
			_notify("已换上%s" % str(WardrobeCatalog.get_outfit(_selected_outfit_id).get("display_name", "新服装")))
	else:
		var purchased := bool(_world.call("_try_purchase_wardrobe_outfit", _selected_outfit_id)) if _world.has_method("_try_purchase_wardrobe_outfit") else false
		if purchased:
			_manager.equip_outfit(_selected_outfit_id)
			_apply_equipped_outfit()
	_rebuild_outfit_cards()
	_refresh_outfit_detail()

func _update_preview(outfit: Dictionary) -> void:
	_clear_preview_model()
	_preview_yaw = 0.0
	var model_path := str(outfit.get("model_path", ""))
	var available := ResourceLoader.exists(model_path, "PackedScene")
	_preview_concept.texture = null
	var preview_path := str(outfit.get("preview_path", ""))
	if ResourceLoader.exists(preview_path, "Texture2D"):
		_preview_concept.texture = ResourceLoader.load(preview_path) as Texture2D
	if available:
		var scene := ResourceLoader.load(model_path) as PackedScene
		if scene != null:
			_preview_model = scene.instantiate() as Node3D
		if _preview_model != null:
			_preview_model.scale = Vector3.ONE * DEFAULT_VISUAL_SCALE
			_preview_model_root.add_child(_preview_model)
			_disable_shadows(_preview_model)
			_preview_concept.visible = false
			_preview_hint.text = "拖动旋转"
			return
	_preview_concept.visible = true
	_preview_hint.text = "平面设定已准备\n等待导入混元生成的 GLB"

func _clear_preview_model() -> void:
	if _preview_model != null and is_instance_valid(_preview_model):
		_preview_model.queue_free()
	_preview_model = null

func _on_preview_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_preview_dragging = event.pressed
		_preview_last_mouse = event.position
		_preview_container.accept_event()
	elif event is InputEventMouseMotion and _preview_dragging:
		var motion := event as InputEventMouseMotion
		_preview_yaw += motion.relative.x * 0.012
		if _preview_model != null:
			_preview_model.rotation.y = _preview_yaw
		_preview_last_mouse = event.position
		_preview_container.accept_event()

func _apply_equipped_outfit() -> void:
	if _manager == null or _player == null or not _player.has_method("apply_outfit"):
		return
	var outfit_id := str(_manager.equipped_outfit_id)
	var outfit := WardrobeCatalog.get_outfit(outfit_id)
	if outfit.is_empty() or not WardrobeCatalog.model_is_available(outfit_id):
		outfit_id = WardrobeCatalog.DEFAULT_OUTFIT_ID
		outfit = WardrobeCatalog.get_outfit(outfit_id)
		if str(_manager.equipped_outfit_id) != outfit_id:
			_manager.equip_outfit(outfit_id)
	if not outfit.is_empty():
		_player.call("apply_outfit", outfit_id, str(outfit.get("model_path", "")))

func _on_manager_state_changed(_snapshot: Dictionary) -> void:
	if _manager == null:
		return
	_spawn_missing_bundles()
	_update_objective_ui()
	if _event_marker != null:
		_event_marker.visible = str(_manager.event_state) != _manager.EVENT_UNLOCKED

func _on_outfit_equipped(_outfit_id: String) -> void:
	_apply_equipped_outfit()

func _update_event_animation() -> void:
	if _event_marker != null and is_instance_valid(_event_marker):
		_event_marker.position.y = 3.35 + sin(_animation_time * 2.6) * 0.10
		_event_marker.visible = _manager != null and str(_manager.event_state) != _manager.EVENT_UNLOCKED
	for raw_id in _bundle_nodes.keys():
		var node := _bundle_nodes[raw_id] as Node3D
		if node == null or not is_instance_valid(node):
			continue
		var phase := float(node.get_meta("phase", 0.0))
		var base_y := float(node.get_meta("base_y", node.position.y))
		node.global_position.y = base_y + 0.12 + sin(_animation_time * 2.2 + phase) * 0.08
		node.rotation.y = sin(_animation_time * 0.8 + phase) * 0.12

func _is_player_near(node: Node3D, radius: float) -> bool:
	return node != null and is_instance_valid(node) and _player != null and _flat_distance_squared(_player.global_position, node.global_position) <= radius * radius

func _flat_distance_squared(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_squared_to(Vector2(b.x, b.z))

func _yaw_toward(from: Vector3, to: Vector3) -> float:
	var delta := to - from
	return atan2(delta.x, delta.z)

func _notify(text: String) -> void:
	if _world != null and _world.has_method("_show_side_toast"):
		_world.call("_show_side_toast", text)

func _material(key: String, color: Color) -> StandardMaterial3D:
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	material.metallic = 0.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	_materials[key] = material
	return material

func _add_box(parent: Node3D, node_name: String, position: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	node.position = position
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	return node

func _add_sphere(parent: Node3D, node_name: String, position: Vector3, scale_value: Vector3, material: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 12
	mesh.rings = 8
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	node.position = position
	node.scale = scale_value * 2.0
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	return node

func _add_cylinder(parent: Node3D, node_name: String, position: Vector3, radius: float, height: float, material: Material, rotation_value: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	node.position = position
	node.rotation = rotation_value
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	return node

func _add_cone(parent: Node3D, node_name: String, position: Vector3, radius: float, height: float, material: Material, rotation_value: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.02
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	node.position = position
	node.rotation = rotation_value
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	return node

func _disable_shadows(node: Node) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		_disable_shadows(child)

func _style(fill: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	return style

func _make_button(text_value: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(190, 44)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color("3f382e"))
	var fill := Color("dfe4c8") if primary else Color("eee4ca")
	var border := Color("7f8d64") if primary else Color("a1845f")
	button.add_theme_stylebox_override("normal", _style(fill, border, 12, 2))
	button.add_theme_stylebox_override("hover", _style(fill.lightened(0.07), border.lightened(0.08), 12, 2))
	button.add_theme_stylebox_override("pressed", _style(fill.darkened(0.06), border, 12, 2))
	button.add_theme_stylebox_override("disabled", _style(Color("d3cfbd"), Color("aaa18e"), 12, 1))
	return button
