extends Control
class_name KitchenPromptOverlay

const STATUS_SIZE := Vector2(172.0, 58.0)
const HEAT_SIZE := Vector2(336.0, 112.0)
const SCREEN_MARGIN := 12.0
const CARD_GAP := 6.0

const STATUS_TEXTURE := preload("res://ui/kitchen_prompts/status_plaque_v1.png")
const HEAT_TEXTURE := preload("res://ui/kitchen_prompts/heat_panel_v1.png")
const POINTER_TEXTURE := preload("res://ui/kitchen_prompts/heat_pointer_v1.png")
const ICON_TEXTURES := {
	"wash": preload("res://ui/kitchen_prompts/icon_wash_v1.png"),
	"cut": preload("res://ui/kitchen_prompts/icon_cut_v1.png"),
	"pot": preload("res://ui/kitchen_prompts/icon_pot_v1.png"),
	"grill": preload("res://ui/kitchen_prompts/icon_grill_v1.png"),
	"serve": preload("res://ui/kitchen_prompts/icon_serve_v1.png"),
}

const TEXT_COLOR := Color(0.25, 0.20, 0.13, 1.0)
const MUTED_TEXT_COLOR := Color(0.38, 0.34, 0.27, 0.96)
const LOW_HEAT_COLOR := Color(0.43, 0.57, 0.61, 0.96)
const GOOD_HEAT_COLOR := Color(0.49, 0.62, 0.36, 0.96)
const HIGH_HEAT_COLOR := Color(0.72, 0.36, 0.25, 0.96)
const READY_COLOR := Color(0.72, 0.61, 0.29, 1.0)
const WORK_COLOR := Color(0.47, 0.61, 0.43, 1.0)
const BURN_COLOR := Color(0.77, 0.34, 0.22, 1.0)
const BURNT_COLOR := Color(0.24, 0.20, 0.17, 1.0)

var _cards: Dictionary = {}
var _frame_active: Dictionary = {}
var _elapsed := 0.0
var _frame_delta := 0.0
var _viewport_size := Vector2(1280.0, 720.0)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 12


func begin_frame(delta: float, viewport_size: Vector2) -> void:
	_elapsed += delta
	_frame_delta = delta
	_viewport_size = viewport_size
	_frame_active.clear()


func update_station(instance_id: String, data: Dictionary, screen_position: Vector2) -> void:
	if instance_id == "" or data.is_empty():
		return
	var card: Dictionary = _cards.get(instance_id, {})
	if card.is_empty():
		card = _create_card(instance_id)
		_cards[instance_id] = card
	_frame_active[instance_id] = true
	var root := card["root"] as Control
	var expanded := bool(data.get("expanded", false))
	_apply_layout(card, expanded)
	root.set_meta("target_position", screen_position - Vector2(root.size.x * 0.5, root.size.y + 18.0))
	root.set_meta("visual_state", str(data.get("visual_state", "working")))
	if not root.visible:
		root.visible = true
		root.set_meta("shown_at", _elapsed)
		root.set_meta("last_visual_state", "")
	_apply_static_data(card, data)
	_apply_dynamic_data(card, data)


func end_frame() -> void:
	for raw_id in _cards.keys():
		var instance_id := str(raw_id)
		if _frame_active.has(instance_id):
			continue
		var hidden_card: Dictionary = _cards[instance_id]
		var hidden_root := hidden_card["root"] as Control
		hidden_root.visible = false
	var active_roots: Array[Control] = []
	for raw_id in _frame_active.keys():
		var card: Dictionary = _cards.get(str(raw_id), {})
		if not card.is_empty():
			active_roots.append(card["root"] as Control)
	active_roots.sort_custom(func(a: Control, b: Control) -> bool:
		return (a.get_meta("target_position", Vector2.ZERO) as Vector2).y < (b.get_meta("target_position", Vector2.ZERO) as Vector2).y
	)
	var placed: Array[Rect2] = []
	for root in active_roots:
		var target := root.get_meta("target_position", Vector2.ZERO) as Vector2
		target.x = clampf(target.x, SCREEN_MARGIN, maxf(SCREEN_MARGIN, _viewport_size.x - root.size.x - SCREEN_MARGIN))
		target.y = clampf(target.y, SCREEN_MARGIN, maxf(SCREEN_MARGIN, _viewport_size.y - root.size.y - SCREEN_MARGIN))
		var candidate := Rect2(target, root.size)
		for other in placed:
			if candidate.intersects(other):
				candidate.position.y = maxf(SCREEN_MARGIN, other.position.y - candidate.size.y - CARD_GAP)
		placed.append(candidate)
		root.position = candidate.position
		_animate_card(root)


func clear_all() -> void:
	for raw_card in _cards.values():
		var card: Dictionary = raw_card
		var root := card.get("root") as Control
		if root != null and is_instance_valid(root):
			root.queue_free()
	_cards.clear()
	_frame_active.clear()


func _create_card(instance_id: String) -> Dictionary:
	var root := Control.new()
	root.name = "KitchenPrompt_%s" % instance_id
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.visible = false
	add_child(root)

	var background := TextureRect.new()
	background.name = "Background"
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(background)

	var icon := TextureRect.new()
	icon.name = "ActionIcon"
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(icon)

	var title := _make_label(14, TEXT_COLOR)
	title.name = "Title"
	root.add_child(title)
	var subtitle := _make_label(11, MUTED_TEXT_COLOR)
	subtitle.name = "Subtitle"
	root.add_child(subtitle)

	var progress_back := ColorRect.new()
	progress_back.name = "ProgressBack"
	progress_back.color = Color(0.23, 0.20, 0.15, 0.24)
	progress_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(progress_back)
	var progress_fill := ColorRect.new()
	progress_fill.name = "ProgressFill"
	progress_fill.color = WORK_COLOR
	progress_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(progress_fill)

	var heat_low := ColorRect.new()
	heat_low.color = LOW_HEAT_COLOR
	heat_low.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(heat_low)
	var heat_good := ColorRect.new()
	heat_good.color = GOOD_HEAT_COLOR
	heat_good.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(heat_good)
	var heat_high := ColorRect.new()
	heat_high.color = HIGH_HEAT_COLOR
	heat_high.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(heat_high)

	var heat_pointer := TextureRect.new()
	heat_pointer.name = "HeatPointer"
	heat_pointer.texture = POINTER_TEXTURE
	heat_pointer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	heat_pointer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	heat_pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(heat_pointer)

	var low_label := _make_label(9, Color(0.27, 0.38, 0.40, 1.0))
	low_label.text = "小火"
	low_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	root.add_child(low_label)
	var good_label := _make_label(9, Color(0.31, 0.43, 0.24, 1.0))
	good_label.text = "刚好"
	good_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(good_label)
	var high_label := _make_label(9, Color(0.52, 0.24, 0.17, 1.0))
	high_label.text = "旺火"
	high_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(high_label)

	var keycap := PanelContainer.new()
	keycap.name = "Keycap"
	keycap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var keycap_style := StyleBoxFlat.new()
	keycap_style.bg_color = Color(0.32, 0.28, 0.20, 0.96)
	keycap_style.border_color = Color(0.72, 0.59, 0.31, 1.0)
	keycap_style.set_border_width_all(1)
	keycap_style.set_corner_radius_all(5)
	keycap.add_theme_stylebox_override("panel", keycap_style)
	root.add_child(keycap)
	var key_label := _make_label(12, Color(1.0, 0.95, 0.82, 1.0))
	key_label.text = "F"
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	keycap.add_child(key_label)

	var prompt := _make_label(12, TEXT_COLOR)
	prompt.name = "Prompt"
	prompt.text = "锁定火候"
	root.add_child(prompt)

	return {
		"root": root,
		"background": background,
		"icon": icon,
		"title": title,
		"subtitle": subtitle,
		"progress_back": progress_back,
		"progress_fill": progress_fill,
		"heat_low": heat_low,
		"heat_good": heat_good,
		"heat_high": heat_high,
		"heat_pointer": heat_pointer,
		"low_label": low_label,
		"good_label": good_label,
		"high_label": high_label,
		"keycap": keycap,
		"prompt": prompt,
	}


func _make_label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(1.0, 0.97, 0.86, 0.72))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	return label


func _apply_layout(card: Dictionary, expanded: bool) -> void:
	var root := card["root"] as Control
	if bool(root.get_meta("expanded", not expanded)) == expanded:
		return
	root.set_meta("expanded", expanded)
	root.size = HEAT_SIZE if expanded else STATUS_SIZE
	root.pivot_offset = root.size * 0.5
	var background := card["background"] as TextureRect
	background.position = Vector2.ZERO
	background.size = root.size
	background.texture = HEAT_TEXTURE if expanded else STATUS_TEXTURE
	var icon := card["icon"] as TextureRect
	var title := card["title"] as Label
	var subtitle := card["subtitle"] as Label
	var progress_back := card["progress_back"] as ColorRect
	var progress_fill := card["progress_fill"] as ColorRect
	var heat_nodes := [card["heat_low"], card["heat_good"], card["heat_high"], card["heat_pointer"], card["low_label"], card["good_label"], card["high_label"], card["keycap"], card["prompt"]]
	for node in heat_nodes:
		(node as Control).visible = expanded
	if expanded:
		icon.position = Vector2(17.0, 10.0)
		icon.size = Vector2(34.0, 34.0)
		title.position = Vector2(56.0, 8.0)
		title.size = Vector2(246.0, 24.0)
		title.add_theme_font_size_override("font_size", 15)
		subtitle.visible = false
		progress_back.visible = false
		progress_fill.visible = false
		(card["low_label"] as Label).position = Vector2(43.0, 60.0)
		(card["low_label"] as Label).size = Vector2(70.0, 15.0)
		(card["good_label"] as Label).position = Vector2(128.0, 60.0)
		(card["good_label"] as Label).size = Vector2(80.0, 15.0)
		(card["high_label"] as Label).position = Vector2(222.0, 60.0)
		(card["high_label"] as Label).size = Vector2(70.0, 15.0)
		(card["keycap"] as PanelContainer).position = Vector2(126.0, 82.0)
		(card["keycap"] as PanelContainer).size = Vector2(28.0, 21.0)
		(card["prompt"] as Label).position = Vector2(163.0, 81.0)
		(card["prompt"] as Label).size = Vector2(90.0, 22.0)
	else:
		icon.position = Vector2(10.0, 10.0)
		icon.size = Vector2(38.0, 38.0)
		title.position = Vector2(51.0, 6.0)
		title.size = Vector2(108.0, 22.0)
		title.add_theme_font_size_override("font_size", 14)
		subtitle.visible = true
		subtitle.position = Vector2(51.0, 26.0)
		subtitle.size = Vector2(108.0, 18.0)
		progress_back.position = Vector2(51.0, 46.0)
		progress_back.size = Vector2(106.0, 4.0)
		progress_fill.position = progress_back.position


func _apply_static_data(card: Dictionary, data: Dictionary) -> void:
	var root := card["root"] as Control
	var signature := "%s|%s|%s|%s|%s" % [
		str(data.get("title", "")),
		str(data.get("subtitle", "")),
		str(data.get("icon", "")),
		str(data.get("visual_state", "working")),
		str(data.get("expanded", false)),
	]
	if str(root.get_meta("content_signature", "")) == signature:
		return
	root.set_meta("content_signature", signature)
	var previous_state := str(root.get_meta("last_visual_state", ""))
	var visual_state := str(data.get("visual_state", "working"))
	if previous_state != visual_state:
		root.set_meta("state_changed_at", _elapsed)
		root.set_meta("last_visual_state", visual_state)
	(card["title"] as Label).text = str(data.get("title", ""))
	(card["subtitle"] as Label).text = str(data.get("subtitle", ""))
	var icon_key := str(data.get("icon", "pot"))
	(card["icon"] as TextureRect).texture = ICON_TEXTURES.get(icon_key, ICON_TEXTURES["pot"])


func _apply_dynamic_data(card: Dictionary, data: Dictionary) -> void:
	var root := card["root"] as Control
	var expanded := bool(data.get("expanded", false))
	var ratio := clampf(float(data.get("ratio", 0.0)), 0.0, 1.0)
	var visual_state := str(data.get("visual_state", "working"))
	if expanded:
		var meter_x := 43.0
		var meter_y := 44.0
		var meter_width := 250.0
		var meter_height := 12.0
		var lower := clampf(float(data.get("heat_lower", 0.32)), 0.0, 1.0)
		var upper := clampf(float(data.get("heat_upper", 0.68)), lower, 1.0)
		_set_rect(card["heat_low"] as Control, Vector2(meter_x, meter_y), Vector2(meter_width * lower, meter_height))
		_set_rect(card["heat_good"] as Control, Vector2(meter_x + meter_width * lower, meter_y), Vector2(meter_width * (upper - lower), meter_height))
		_set_rect(card["heat_high"] as Control, Vector2(meter_x + meter_width * upper, meter_y), Vector2(meter_width * (1.0 - upper), meter_height))
		var cursor := clampf(float(data.get("heat_cursor", 0.5)), 0.0, 1.0)
		_set_rect(card["heat_pointer"] as Control, Vector2(meter_x + meter_width * cursor - 8.0, 28.0), Vector2(16.0, 38.0))
	else:
		var show_progress := bool(data.get("show_progress", false))
		(card["progress_back"] as ColorRect).visible = show_progress
		(card["progress_fill"] as ColorRect).visible = show_progress
		if show_progress:
			var fill := card["progress_fill"] as ColorRect
			fill.size = Vector2(maxf(2.0, 106.0 * ratio), 4.0)
			match visual_state:
				"ready": fill.color = READY_COLOR
				"burning": fill.color = BURN_COLOR
				"burnt": fill.color = BURNT_COLOR
				_: fill.color = WORK_COLOR
	root.set_meta("ratio", ratio)


func _animate_card(root: Control) -> void:
	var shown_at := float(root.get_meta("shown_at", _elapsed))
	var appear := clampf((_elapsed - shown_at) / 0.16, 0.0, 1.0)
	var eased := 1.0 - pow(1.0 - appear, 3.0)
	var state := str(root.get_meta("visual_state", "working"))
	var pulse := 1.0
	var tint := Color.WHITE
	match state:
		"ready":
			pulse = 1.0 + sin(_elapsed * 5.5) * 0.018
			tint = Color(1.04, 1.02, 0.91, 1.0)
		"burning":
			root.position.x += sin(_elapsed * 24.0) * 1.25
			tint = Color(1.06, 0.86 + sin(_elapsed * 8.0) * 0.06, 0.76, 1.0)
		"burnt":
			tint = Color(0.70, 0.68, 0.64, 1.0)
	root.scale = Vector2.ONE * lerpf(0.92, pulse, eased)
	root.modulate = tint
	root.modulate.a = eased


func _set_rect(control: Control, position: Vector2, size: Vector2) -> void:
	control.position = position
	control.size = size
