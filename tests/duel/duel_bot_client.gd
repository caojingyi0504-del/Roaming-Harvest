extends Node

const DuelRulesScript = preload("res://scripts/duel/duel_rules.gd")

@onready var endpoint: DuelEndpoint = $Endpoint

var socket: WebSocketMultiplayerPeer
var bot_name := "测试机器人"
var ready_sent := false
var match_started := false
var started_at := 0.0
var resume_token := ""
var reconnect_mode := false
var reconnect_started := false
var reconnect_confirmed := false
var finished := false
var wait_for_forfeit := false
var local_slot := -1
var lobby_mode := "quick"
var requested_room_code := ""
var room_code_printed := false

func _ready() -> void:
	started_at = Time.get_ticks_msec() / 1000.0
	bot_name = OS.get_environment("DUEL_BOT_NAME")
	if bot_name == "":
		bot_name = "测试机器人"
	reconnect_mode = OS.get_environment("DUEL_BOT_RECONNECT") == "1"
	wait_for_forfeit = OS.get_environment("DUEL_BOT_WAIT_FORFEIT") == "1"
	lobby_mode = OS.get_environment("DUEL_BOT_MODE").strip_edges().to_lower()
	if lobby_mode == "":
		lobby_mode = "quick"
	requested_room_code = OS.get_environment("DUEL_BOT_ROOM_CODE").strip_edges()
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(func() -> void: _finish(false, "connection_failed"))
	multiplayer.server_disconnected.connect(func() -> void:
		if not match_started and not reconnect_started:
			_finish(false, "server_disconnected")
	)
	endpoint.message_received.connect(_on_message)
	endpoint.snapshot_received.connect(_on_snapshot)
	socket = WebSocketMultiplayerPeer.new()
	socket.supported_protocols = PackedStringArray(["roaming-harvest-duel-v1"])
	var url := OS.get_environment("DUEL_BOT_URL")
	if url == "":
		url = "ws://127.0.0.1:19081"
	var error := socket.create_client(url)
	if error != OK:
		_finish(false, "create_client_%s" % error_string(error))
		return
	multiplayer.multiplayer_peer = socket

func _process(_delta: float) -> void:
	if Time.get_ticks_msec() / 1000.0 - started_at > 20.0:
		_finish(false, "timeout")

func _on_connected() -> void:
	endpoint.request("hello", {
		"protocol": DuelRulesScript.PROTOCOL_VERSION,
		"nickname": bot_name,
		"resume_token": resume_token,
	})

func _on_message(kind: String, payload: Dictionary) -> void:
	match kind:
		"session":
			resume_token = str(payload.get("resume_token", resume_token))
			if bool(payload.get("reconnected", false)):
				reconnect_confirmed = true
			else:
				if lobby_mode == "create":
					endpoint.request("create_room")
				elif lobby_mode == "join":
					endpoint.request("join_room", {"code": requested_room_code})
				else:
					endpoint.request("queue_join")
		"lobby":
			var players: Array = payload.get("players", [])
			var received_room_code := str(payload.get("room_code", ""))
			if lobby_mode == "create" and received_room_code != "" and not room_code_printed:
				room_code_printed = true
				print("DUEL_ROOM_CODE=%s" % received_room_code)
			if str(payload.get("state", "")) == "waiting" and players.size() == 2 and not ready_sent:
				ready_sent = true
				endpoint.request("ready", {"ready": true})
		"match_start":
			match_started = true
			local_slot = int(payload.get("slot", -1))
			endpoint.send_input(1, Vector2(0.25, 0.0))
		"result":
			if wait_for_forfeit:
				_finish(int(payload.get("winner", -2)) == local_slot, "forfeit_timeout")
		"error":
			_finish(false, "server_error_%s" % str(payload.get("code", "unknown")))

func _on_snapshot(payload: Dictionary) -> void:
	if match_started and str(payload.get("phase", "")) == "running":
		if wait_for_forfeit:
			return
		if reconnect_mode and not reconnect_started:
			reconnect_started = true
			match_started = false
			if socket != null:
				socket.close()
			multiplayer.multiplayer_peer = null
			get_tree().create_timer(0.8).timeout.connect(_reconnect)
			return
		if reconnect_mode:
			_finish(reconnect_confirmed, "reconnected" if reconnect_confirmed else "resume_not_confirmed")
		else:
			_finish(true, "match_started")

func _reconnect() -> void:
	socket = WebSocketMultiplayerPeer.new()
	socket.supported_protocols = PackedStringArray(["roaming-harvest-duel-v1"])
	var url := OS.get_environment("DUEL_BOT_URL")
	if url == "":
		url = "ws://127.0.0.1:19081"
	var error := socket.create_client(url)
	if error != OK:
		_finish(false, "reconnect_create_%s" % error_string(error))
		return
	multiplayer.multiplayer_peer = socket

func _finish(ok: bool, reason: String) -> void:
	if finished or not is_inside_tree():
		return
	finished = true
	print("DUEL_BOT_OK name=%s reason=%s" % [bot_name, reason] if ok else "DUEL_BOT_FAILED name=%s reason=%s" % [bot_name, reason])
	get_tree().quit(0 if ok else 1)
