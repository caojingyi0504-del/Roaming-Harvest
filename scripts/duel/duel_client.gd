extends Node

const DuelRulesScript = preload("res://scripts/duel/duel_rules.gd")
const DuelArenaScript = preload("res://scripts/duel/duel_arena.gd")

signal duel_closed

@onready var endpoint: DuelEndpoint = $Endpoint

var socket: WebSocketMultiplayerPeer
var resume_token := ""
var nickname := ""
var local_slot := -1
var connected := false
var connecting := false
var in_match := false
var reconnecting := false
var reconnect_deadline := 0.0
var reconnect_next_attempt := 0.0
var input_sequence := 0
var arena: Node
var embedded_mode := false
var closing := false

var lobby_canvas: CanvasLayer
var lobby_root: Control
var status_label: Label
var nickname_edit: LineEdit
var server_edit: LineEdit
var connect_button: Button
var action_box: VBoxContainer
var room_code_edit: LineEdit
var room_label: Label
var players_label: Label
var ready_button: Button

func _ready() -> void:
	name = "DuelSession"
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	endpoint.message_received.connect(_on_message)
	endpoint.snapshot_received.connect(_on_snapshot)
	_build_lobby()

func configure_embedded() -> void:
	embedded_mode = true
	process_mode = Node.PROCESS_MODE_ALWAYS

func _exit_tree() -> void:
	_disconnect_socket(false)

func _process(_delta: float) -> void:
	if not reconnecting:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now >= reconnect_deadline:
		reconnecting = false
		in_match = false
		if arena != null and is_instance_valid(arena):
			arena.call("show_connection_lost", "重连超过 15 秒，本局已判负。")
		return
	if not connecting and now >= reconnect_next_attempt:
		reconnect_next_attempt = now + 2.0
		_connect_to_server(true)

func submit_duel_input(direction: Vector2) -> void:
	if not connected or not in_match:
		return
	input_sequence += 1
	endpoint.send_input(input_sequence, direction)

func submit_duel_interact() -> void:
	if connected and in_match:
		endpoint.request("interact")

func request_rematch() -> void:
	if connected:
		endpoint.request("rematch")

func leave_duel() -> void:
	if closing:
		return
	closing = true
	if connected:
		endpoint.request("leave")
	_disconnect_socket()
	if embedded_mode:
		duel_closed.emit()
		queue_free()
		return
	get_tree().change_scene_to_file("res://scenes/GrassWorld.tscn")

func _build_lobby() -> void:
	lobby_canvas = CanvasLayer.new()
	lobby_canvas.name = "LobbyCanvas"
	lobby_canvas.layer = 100
	add_child(lobby_canvas)
	lobby_root = Control.new()
	lobby_root.name = "LobbyUI"
	lobby_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lobby_canvas.add_child(lobby_root)

	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.70, 0.82, 0.76, 1.0)
	lobby_root.add_child(background)

	var panel := PanelContainer.new()
	panel.name = "LobbyPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	var viewport_size := get_viewport().get_visible_rect().size
	panel.size = Vector2(minf(660.0, viewport_size.x - 32.0), minf(610.0, viewport_size.y - 32.0))
	panel.position = -panel.size * 0.5
	panel.add_theme_stylebox_override("panel", _style(Color(0.96, 0.88, 0.68), Color(0.32, 0.22, 0.12), 16, 4))
	lobby_root.add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	panel.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 12)
	scroll.add_child(box)
	var title := _label("双人料理竞速", 30, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(title)
	box.add_child(_label("云端专用服 · 120秒积分赛", 14, HORIZONTAL_ALIGNMENT_CENTER))

	nickname_edit = LineEdit.new()
	nickname_edit.placeholder_text = "输入昵称（1～12字符）"
	nickname_edit.max_length = 12
	nickname_edit.text = "旅人%04d" % randi_range(0, 9999)
	nickname_edit.custom_minimum_size = Vector2(0.0, 42.0)
	box.add_child(nickname_edit)

	var connection_row := HBoxContainer.new()
	connection_row.add_theme_constant_override("separation", 8)
	box.add_child(connection_row)
	server_edit = LineEdit.new()
	server_edit.text = _default_server_url()
	server_edit.placeholder_text = "wss://服务器域名/duel"
	server_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	connection_row.add_child(server_edit)
	connect_button = _button("连接服务器", _on_connect_pressed)
	connect_button.custom_minimum_size.x = 150.0
	connection_row.add_child(connect_button)

	status_label = _label("尚未连接", 15, HORIZONTAL_ALIGNMENT_CENTER)
	status_label.add_theme_color_override("font_color", Color(0.48, 0.18, 0.08))
	box.add_child(status_label)

	action_box = VBoxContainer.new()
	action_box.visible = false
	action_box.add_theme_constant_override("separation", 10)
	box.add_child(action_box)
	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 10)
	action_box.add_child(action_row)
	action_row.add_child(_button("创建好友房", func(): endpoint.request("create_room")))
	action_row.add_child(_button("快速匹配", func(): endpoint.request("queue_join")))
	var join_row := HBoxContainer.new()
	join_row.add_theme_constant_override("separation", 10)
	action_box.add_child(join_row)
	room_code_edit = LineEdit.new()
	room_code_edit.placeholder_text = "六位房间码"
	room_code_edit.max_length = 6
	room_code_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	join_row.add_child(room_code_edit)
	join_row.add_child(_button("加入房间", func(): endpoint.request("join_room", {"code": room_code_edit.text})))

	room_label = _label("", 22, HORIZONTAL_ALIGNMENT_CENTER)
	action_box.add_child(room_label)
	players_label = _label("", 16, HORIZONTAL_ALIGNMENT_CENTER)
	players_label.custom_minimum_size.y = 74.0
	action_box.add_child(players_label)
	ready_button = _button("准备", func(): endpoint.request("ready", {"ready": true}))
	ready_button.visible = false
	action_box.add_child(ready_button)
	var leave_button := _button("离开房间 / 取消匹配", func(): endpoint.request("leave"))
	action_box.add_child(leave_button)

	var back := _button("返回单人世界", leave_duel)
	box.add_child(back)
	get_viewport().size_changed.connect(func() -> void:
		if not is_instance_valid(panel):
			return
		var new_size := get_viewport().get_visible_rect().size
		panel.size = Vector2(minf(660.0, new_size.x - 32.0), minf(610.0, new_size.y - 32.0))
		panel.position = -panel.size * 0.5
	)

func _on_connect_pressed() -> void:
	if connected or connecting:
		_disconnect_socket()
		return
	resume_token = ""
	_connect_to_server(false)

func _connect_to_server(is_reconnect: bool) -> void:
	var url := server_edit.text.strip_edges() if server_edit != null else _default_server_url()
	if not (url.begins_with("ws://") or url.begins_with("wss://")):
		_set_status("服务器地址必须以 ws:// 或 wss:// 开头", true)
		return
	_disconnect_socket(false)
	socket = WebSocketMultiplayerPeer.new()
	socket.supported_protocols = PackedStringArray(["roaming-harvest-duel-v1"])
	var error := socket.create_client(url)
	if error != OK:
		_set_status("无法发起连接：%s" % error_string(error), true)
		return
	multiplayer.multiplayer_peer = socket
	connecting = true
	connected = false
	connect_button.text = "取消连接" if connect_button != null else ""
	_set_status("正在重连…" if is_reconnect else "正在连接服务器…")

func _on_connected() -> void:
	connecting = false
	connected = true
	connect_button.text = "断开连接"
	nickname = nickname_edit.text.strip_edges().left(12)
	endpoint.request("hello", {
		"protocol": DuelRulesScript.PROTOCOL_VERSION,
		"nickname": nickname,
		"resume_token": resume_token,
	})

func _on_connection_failed() -> void:
	connecting = false
	connected = false
	if reconnecting:
		return
	_set_status("连接失败，请检查服务器地址", true)
	connect_button.text = "连接服务器"

func _on_server_disconnected() -> void:
	connecting = false
	connected = false
	if in_match and resume_token != "":
		reconnecting = true
		reconnect_deadline = Time.get_ticks_msec() / 1000.0 + DuelRulesScript.RECONNECT_GRACE
		reconnect_next_attempt = 0.0
		if arena != null and is_instance_valid(arena):
			arena.call("set_reconnecting", true, "与服务器断开，正在重连…")
		return
	_set_status("与服务器断开", true)
	connect_button.text = "连接服务器"
	action_box.visible = false

func _on_message(kind: String, payload: Dictionary) -> void:
	match kind:
		"session":
			resume_token = str(payload.get("resume_token", resume_token))
			reconnecting = false
			if arena != null and is_instance_valid(arena):
				arena.call("set_reconnecting", false, "")
			_set_status("已连接：%s" % str(payload.get("nickname", nickname)))
			action_box.visible = true
		"lobby": _apply_lobby(payload)
		"countdown": _set_status("双方已准备，3秒后开始")
		"match_start": _start_arena(payload)
		"event":
			var message := str(payload.get("message", ""))
			if arena != null and is_instance_valid(arena):
				arena.call("show_toast", message, bool(payload.get("ok", true)))
			else:
				_set_status(message, not bool(payload.get("ok", true)))
		"result":
			if arena != null and is_instance_valid(arena):
				arena.call("show_result", payload, local_slot)
		"error": _set_status(str(payload.get("message", "联机请求失败")), true)

func _on_snapshot(payload: Dictionary) -> void:
	if arena != null and is_instance_valid(arena):
		arena.call("apply_snapshot", payload, local_slot)

func _apply_lobby(payload: Dictionary) -> void:
	var state := str(payload.get("state", "idle"))
	if state == "idle":
		room_label.text = ""
		players_label.text = ""
		ready_button.visible = false
		_set_status("已连接，可创建房间或快速匹配")
	elif state == "queue":
		room_label.text = "快速匹配中…"
		players_label.text = "正在等待另一名玩家"
		ready_button.visible = false
	else:
		room_label.text = "房间码  %s" % str(payload.get("room_code", "------"))
		var lines: Array[String] = []
		for player_variant in payload.get("players", []):
			var player: Dictionary = player_variant
			lines.append("%s  %s" % [str(player.get("nickname", "旅人")), "✓ 已准备" if bool(player.get("ready", false)) else "等待准备"])
		players_label.text = "\n".join(lines)
		ready_button.visible = state == "waiting" and lines.size() == 2
		if state == "result":
			_set_status("等待重赛确认（%d/2）" % int(payload.get("rematch_votes", 0)))

func _start_arena(payload: Dictionary) -> void:
	local_slot = int(payload.get("slot", -1))
	in_match = true
	if lobby_root != null:
		lobby_root.visible = false
	if arena != null and is_instance_valid(arena):
		arena.queue_free()
	arena = DuelArenaScript.new()
	arena.name = "Arena"
	add_child(arena)
	arena.call("configure", local_slot, str(payload.get("room_code", "")))

func _disconnect_socket(reset_state: bool = true) -> void:
	if socket != null:
		socket.close()
	multiplayer.multiplayer_peer = null
	socket = null
	connecting = false
	connected = false
	if reset_state:
		connect_button.text = "连接服务器" if connect_button != null else ""

func _default_server_url() -> String:
	var config := ConfigFile.new()
	if config.load("res://config/duel_network.cfg") == OK:
		return str(config.get_value("network", "server_url", "ws://127.0.0.1:9080"))
	return "ws://127.0.0.1:9080"

func _set_status(text_value: String, is_error: bool = false) -> void:
	if status_label == null:
		return
	status_label.text = text_value
	status_label.add_theme_color_override("font_color", Color(0.65, 0.12, 0.08) if is_error else Color(0.27, 0.35, 0.16))

func _label(text_value: String, size_value: int, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = alignment
	label.add_theme_font_size_override("font_size", size_value)
	label.add_theme_color_override("font_color", Color(0.23, 0.16, 0.09))
	return label

func _button(text_value: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0.0, 44.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_stylebox_override("normal", _style(Color(1.0, 0.94, 0.78), Color(0.46, 0.31, 0.14), 7, 2))
	button.add_theme_stylebox_override("hover", _style(Color(1.0, 0.82, 0.42), Color(0.58, 0.30, 0.08), 7, 2))
	button.pressed.connect(action)
	return button

func _style(fill: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
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
