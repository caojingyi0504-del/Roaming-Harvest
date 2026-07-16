extends Node

const DuelRulesScript = preload("res://scripts/duel/duel_rules.gd")
const DuelMatchScript = preload("res://scripts/duel/duel_match.gd")

@onready var endpoint: DuelEndpoint = $Endpoint

var peer: WebSocketMultiplayerPeer
var sessions: Dictionary = {}
var peer_tokens: Dictionary = {}
var pending_peers: Dictionary = {}
var rooms: Dictionary = {}
var quick_queue: Array[String] = []
var max_connections := 100
var max_rooms := 50
var _seed_counter := 0

func _ready() -> void:
	name = "DuelSession"
	max_connections = _env_int("DUEL_MAX_CONNECTIONS", 100)
	max_rooms = _env_int("DUEL_MAX_ROOMS", 50)
	var bind_address := OS.get_environment("DUEL_WS_BIND")
	if bind_address == "":
		bind_address = "0.0.0.0"
	var port := _env_int("DUEL_WS_PORT", 9080)
	peer = WebSocketMultiplayerPeer.new()
	peer.supported_protocols = PackedStringArray(["roaming-harvest-duel-v1"])
	var error := peer.create_server(port, bind_address)
	if error != OK:
		push_error("Duel server failed to listen on %s:%d (%s)" % [bind_address, port, error_string(error)])
		get_tree().quit(error)
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	endpoint.request_received.connect(_on_request)
	endpoint.input_received.connect(_on_input)
	print("DUEL_SERVER_READY bind=%s port=%d max_connections=%d max_rooms=%d" % [bind_address, port, max_connections, max_rooms])

func _process(delta: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	for pending_peer_variant in pending_peers.keys().duplicate():
		var pending_peer_id := int(pending_peer_variant)
		if Time.get_ticks_msec() - int(pending_peers.get(pending_peer_id, 0)) > 10000:
			pending_peers.erase(pending_peer_id)
			if peer != null:
				peer.disconnect_peer(pending_peer_id)
	for room_code_variant in rooms.keys().duplicate():
		var room_code := str(room_code_variant)
		if not rooms.has(room_code):
			continue
		var room: Dictionary = rooms[room_code]
		var state := str(room.get("state", "waiting"))
		if state == "waiting" and room.has("ready_deadline") and now >= float(room.get("ready_deadline", INF)):
			_expire_ready_room(room_code)
			continue
		if state == "countdown" and now >= float(room.get("countdown_at", INF)):
			room["state"] = "match"
			room["snapshot_accum"] = 0.0
			rooms[room_code] = room
			_send_match_start(room_code)
			_broadcast_snapshot(room_code)
		elif state == "match":
			var match_state: DuelMatch = room.get("match") as DuelMatch
			if match_state == null:
				_close_room(room_code, "比赛状态丢失")
				continue
			_check_reconnect_timeouts(room_code, now)
			match_state.tick(delta)
			room["snapshot_accum"] = float(room.get("snapshot_accum", 0.0)) + delta
			if float(room["snapshot_accum"]) >= 1.0 / DuelRulesScript.SNAPSHOT_RATE:
				room["snapshot_accum"] = fmod(float(room["snapshot_accum"]), 1.0 / DuelRulesScript.SNAPSHOT_RATE)
				rooms[room_code] = room
				_broadcast_snapshot(room_code)
			if match_state.phase == "finished":
				room = rooms.get(room_code, room)
				room["state"] = "result"
				room["result_deadline"] = now + DuelRulesScript.REMATCH_WINDOW
				room["rematch"] = {}
				rooms[room_code] = room
				_broadcast_message(room_code, "result", match_state.result)
				print("DUEL_MATCH_END room=%s reason=%s" % [room_code, str(match_state.result.get("reason", "unknown"))])
		else:
			rooms[room_code] = room
		if rooms.has(room_code) and str(rooms[room_code].get("state", "")) == "result" and now >= float(rooms[room_code].get("result_deadline", INF)):
			_reset_room_after_result(room_code)

func _on_peer_connected(peer_id: int) -> void:
	if peer_tokens.size() + pending_peers.size() >= max_connections:
		endpoint.send_message(peer_id, "error", {"code": "server_full", "message": "服务器已满"})
		peer.disconnect_peer(peer_id)
		return
	pending_peers[peer_id] = Time.get_ticks_msec()
	print("DUEL_CONNECT peer=%d" % peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
	pending_peers.erase(peer_id)
	if not peer_tokens.has(peer_id):
		return
	var token := str(peer_tokens[peer_id])
	peer_tokens.erase(peer_id)
	if not sessions.has(token):
		return
	var session: Dictionary = sessions[token]
	session["peer_id"] = 0
	session["disconnected_at"] = Time.get_ticks_msec() / 1000.0
	sessions[token] = session
	_remove_from_queue(token)
	var room_code := str(session.get("room", ""))
	if room_code != "" and rooms.has(room_code):
		var room: Dictionary = rooms[room_code]
		if str(room.get("state", "waiting")) == "match":
			var slot := _room_slot(room, token)
			var match_state: DuelMatch = room.get("match") as DuelMatch
			if match_state != null and slot >= 0:
				match_state.disconnect_slot(slot)
				_broadcast_message(room_code, "event", {"message": "%s掉线，保留席位15秒" % str(session.get("nickname", "对手"))})
		else:
			_remove_token_from_room(room_code, token, "玩家已离开")
	print("DUEL_DISCONNECT token=%s room=%s" % [_safe_token(token), room_code])

func _on_request(peer_id: int, kind: String, payload: Dictionary) -> void:
	if kind == "hello":
		_handle_hello(peer_id, payload)
		return
	var token := str(peer_tokens.get(peer_id, ""))
	if token == "" or not sessions.has(token):
		endpoint.send_message(peer_id, "error", {"code": "not_authenticated", "message": "请先连接服务器"})
		return
	var bucket := "interaction" if kind == "interact" else "lobby"
	var limit := 10 if bucket == "interaction" else 2
	if not _rate_limit(token, bucket, limit):
		return
	match kind:
		"create_room": _create_room(token)
		"join_room": _join_room(token, str(payload.get("code", "")))
		"queue_join": _join_quick_queue(token)
		"queue_leave": _leave_quick_queue(token)
		"ready": _set_ready(token, bool(payload.get("ready", true)))
		"interact": _interact(token)
		"rematch": _vote_rematch(token)
		"leave": _leave_session_activity(token)
		_: _send_token(token, "error", {"code": "unknown_request", "message": "未知请求"})

func _on_input(peer_id: int, sequence: int, direction: Vector2) -> void:
	var token := str(peer_tokens.get(peer_id, ""))
	if token == "" or not sessions.has(token) or not _rate_limit(token, "input", 20):
		return
	var room_code := str(sessions[token].get("room", ""))
	if not rooms.has(room_code):
		return
	var room: Dictionary = rooms[room_code]
	if str(room.get("state", "")) != "match":
		return
	var slot := _room_slot(room, token)
	var match_state: DuelMatch = room.get("match") as DuelMatch
	if slot >= 0 and match_state != null:
		match_state.set_input(slot, sequence, direction)

func _handle_hello(peer_id: int, payload: Dictionary) -> void:
	if int(payload.get("protocol", -1)) != DuelRulesScript.PROTOCOL_VERSION:
		endpoint.send_message(peer_id, "error", {"code": "protocol_mismatch", "message": "联机版本不一致，请更新客户端"})
		peer.disconnect_peer(peer_id)
		return
	var requested_token := str(payload.get("resume_token", ""))
	if requested_token != "" and sessions.has(requested_token):
		var old_session: Dictionary = sessions[requested_token]
		var disconnected_at := float(old_session.get("disconnected_at", -1.0))
		if int(old_session.get("peer_id", 0)) == 0 and disconnected_at >= 0.0 and Time.get_ticks_msec() / 1000.0 - disconnected_at <= DuelRulesScript.RECONNECT_GRACE:
			old_session["peer_id"] = peer_id
			old_session["disconnected_at"] = -1.0
			sessions[requested_token] = old_session
			peer_tokens[peer_id] = requested_token
			pending_peers.erase(peer_id)
			_send_session(requested_token, true)
			_restore_session_state(requested_token)
			return
	var nickname := _sanitize_nickname(str(payload.get("nickname", "")))
	var token := _new_token()
	sessions[token] = {
		"peer_id": peer_id,
		"nickname": nickname,
		"room": "",
		"queued": false,
		"disconnected_at": -1.0,
		"rate": {},
	}
	peer_tokens[peer_id] = token
	pending_peers.erase(peer_id)
	_send_session(token, false)

func _send_session(token: String, reconnected: bool) -> void:
	_send_token(token, "session", {
		"resume_token": token,
		"nickname": str(sessions[token].get("nickname", "旅人")),
		"reconnected": reconnected,
		"protocol": DuelRulesScript.PROTOCOL_VERSION,
	})

func _restore_session_state(token: String) -> void:
	var room_code := str(sessions[token].get("room", ""))
	if room_code == "" or not rooms.has(room_code):
		_send_token(token, "lobby", {"state": "idle"})
		return
	var room: Dictionary = rooms[room_code]
	var state := str(room.get("state", "waiting"))
	if state == "match":
		var slot := _room_slot(room, token)
		var match_state: DuelMatch = room.get("match") as DuelMatch
		if match_state != null:
			match_state.reconnect_slot(slot, int(sessions[token].get("peer_id", 0)))
		_send_match_start_to(token, room_code)
		_send_token_snapshot(token, match_state.snapshot() if match_state != null else {})
	elif state == "result":
		_broadcast_lobby(room_code)
		var match_state: DuelMatch = room.get("match") as DuelMatch
		if match_state != null:
			_send_token(token, "result", match_state.result)
	else:
		_broadcast_lobby(room_code)

func _create_room(token: String) -> void:
	if rooms.size() >= max_rooms:
		_send_token(token, "error", {"code": "room_limit", "message": "房间数已达上限"})
		return
	_leave_session_activity(token, false)
	var code := _new_room_code()
	rooms[code] = {
		"owner": token,
		"tokens": [token],
		"ready": {token: false},
		"state": "waiting",
		"match": null,
		"snapshot_accum": 0.0,
	}
	sessions[token]["room"] = code
	_broadcast_lobby(code)
	print("DUEL_ROOM_CREATE room=%s" % code)

func _join_room(token: String, raw_code: String) -> void:
	var code := raw_code.strip_edges()
	if not rooms.has(code):
		_send_token(token, "error", {"code": "room_not_found", "message": "房间码不存在"})
		return
	var room: Dictionary = rooms[code]
	if str(room.get("state", "")) != "waiting" or (room.get("tokens", []) as Array).size() >= 2:
		_send_token(token, "error", {"code": "room_unavailable", "message": "房间已满或比赛已开始"})
		return
	_leave_session_activity(token, false)
	(room["tokens"] as Array).append(token)
	(room["ready"] as Dictionary)[token] = false
	rooms[code] = room
	sessions[token]["room"] = code
	_broadcast_lobby(code)
	print("DUEL_ROOM_JOIN room=%s" % code)

func _join_quick_queue(token: String) -> void:
	_leave_session_activity(token, false)
	_remove_invalid_queue_entries()
	if not quick_queue.is_empty():
		var opponent := str(quick_queue.pop_front())
		if opponent == token or not sessions.has(opponent):
			_join_quick_queue(token)
			return
		sessions[opponent]["queued"] = false
		var code := _new_room_code()
		rooms[code] = {
			"owner": opponent,
			"tokens": [opponent, token],
			"ready": {opponent: false, token: false},
			"state": "waiting",
			"match": null,
			"snapshot_accum": 0.0,
			"ready_deadline": Time.get_ticks_msec() / 1000.0 + DuelRulesScript.READY_TIMEOUT,
			"quick_match": true,
		}
		sessions[opponent]["room"] = code
		sessions[token]["room"] = code
		sessions[token]["queued"] = false
		_broadcast_lobby(code)
		print("DUEL_QUICK_MATCH room=%s" % code)
		return
	quick_queue.append(token)
	sessions[token]["queued"] = true
	_send_token(token, "lobby", {"state": "queue", "queue_size": quick_queue.size()})

func _leave_quick_queue(token: String) -> void:
	_remove_from_queue(token)
	_send_token(token, "lobby", {"state": "idle"})

func _set_ready(token: String, ready: bool) -> void:
	var room_code := str(sessions[token].get("room", ""))
	if not rooms.has(room_code):
		return
	var room: Dictionary = rooms[room_code]
	if str(room.get("state", "")) != "waiting":
		return
	(room["ready"] as Dictionary)[token] = ready
	rooms[room_code] = room
	_broadcast_lobby(room_code)
	if (room.get("tokens", []) as Array).size() == 2:
		var all_ready := true
		for player_token in room["tokens"]:
			all_ready = all_ready and bool((room["ready"] as Dictionary).get(player_token, false))
		if all_ready:
			_start_countdown(room_code)

func _start_countdown(room_code: String) -> void:
	if not rooms.has(room_code):
		return
	var room: Dictionary = rooms[room_code]
	var entries: Array = []
	for token_variant in room.get("tokens", []):
		var token := str(token_variant)
		entries.append({"token": token, "peer_id": int(sessions[token].get("peer_id", 0)), "nickname": str(sessions[token].get("nickname", "旅人"))})
	_seed_counter += 1
	var seed_value := int(Time.get_unix_time_from_system()) ^ hash(room_code) ^ _seed_counter
	room["match"] = DuelMatchScript.new(seed_value, entries)
	room["state"] = "countdown"
	room["countdown_at"] = Time.get_ticks_msec() / 1000.0 + DuelRulesScript.COUNTDOWN_DURATION
	room["ready"] = {}
	room.erase("ready_deadline")
	rooms[room_code] = room
	_broadcast_message(room_code, "countdown", {"seconds": DuelRulesScript.COUNTDOWN_DURATION})
	print("DUEL_MATCH_COUNTDOWN room=%s seed=%d" % [room_code, seed_value])

func _interact(token: String) -> void:
	var room_code := str(sessions[token].get("room", ""))
	if not rooms.has(room_code):
		return
	var room: Dictionary = rooms[room_code]
	if str(room.get("state", "")) != "match":
		return
	var slot := _room_slot(room, token)
	var match_state: DuelMatch = room.get("match") as DuelMatch
	if slot < 0 or match_state == null:
		return
	_send_token(token, "event", match_state.interact(slot))

func _vote_rematch(token: String) -> void:
	var room_code := str(sessions[token].get("room", ""))
	if not rooms.has(room_code):
		return
	var room: Dictionary = rooms[room_code]
	if str(room.get("state", "")) != "result":
		return
	(room["rematch"] as Dictionary)[token] = true
	rooms[room_code] = room
	_broadcast_lobby(room_code)
	var votes: Dictionary = room["rematch"]
	if (room.get("tokens", []) as Array).size() == 2 and votes.size() == 2:
		_start_countdown(room_code)

func _send_match_start(room_code: String) -> void:
	if not rooms.has(room_code):
		return
	for token_variant in rooms[room_code].get("tokens", []):
		_send_match_start_to(str(token_variant), room_code)

func _send_match_start_to(token: String, room_code: String) -> void:
	if not rooms.has(room_code):
		return
	var room: Dictionary = rooms[room_code]
	var match_state: DuelMatch = room.get("match") as DuelMatch
	_send_token(token, "match_start", {
		"room_code": room_code,
		"slot": _room_slot(room, token),
		"seed": match_state.seed_value if match_state != null else 0,
		"duration": DuelRulesScript.MATCH_DURATION,
	})

func _broadcast_snapshot(room_code: String) -> void:
	if not rooms.has(room_code):
		return
	var match_state: DuelMatch = rooms[room_code].get("match") as DuelMatch
	if match_state == null:
		return
	var data := match_state.snapshot()
	for token_variant in rooms[room_code].get("tokens", []):
		_send_token_snapshot(str(token_variant), data)

func _send_token_snapshot(token: String, data: Dictionary) -> void:
	if not sessions.has(token):
		return
	var peer_id := int(sessions[token].get("peer_id", 0))
	if _peer_can_receive(peer_id):
		endpoint.send_snapshot(peer_id, data)

func _broadcast_lobby(room_code: String) -> void:
	if not rooms.has(room_code):
		return
	var room: Dictionary = rooms[room_code]
	for local_token_variant in room.get("tokens", []):
		var local_token := str(local_token_variant)
		var player_list: Array[Dictionary] = []
		for token_variant in room.get("tokens", []):
			var token := str(token_variant)
			player_list.append({
				"nickname": str(sessions.get(token, {}).get("nickname", "旅人")),
				"ready": bool((room.get("ready", {}) as Dictionary).get(token, false)),
				"connected": int(sessions.get(token, {}).get("peer_id", 0)) > 1,
			})
		_send_token(local_token, "lobby", {
			"state": str(room.get("state", "waiting")),
			"room_code": room_code,
			"is_owner": str(room.get("owner", "")) == local_token,
			"players": player_list,
			"rematch_votes": (room.get("rematch", {}) as Dictionary).size(),
		})

func _broadcast_message(room_code: String, kind: String, payload: Dictionary) -> void:
	if not rooms.has(room_code):
		return
	for token_variant in rooms[room_code].get("tokens", []):
		_send_token(str(token_variant), kind, payload)

func _send_token(token: String, kind: String, payload: Dictionary) -> void:
	if not sessions.has(token):
		return
	var peer_id := int(sessions[token].get("peer_id", 0))
	if _peer_can_receive(peer_id):
		endpoint.send_message(peer_id, kind, payload)

func _peer_can_receive(peer_id: int) -> bool:
	if peer == null or peer_id <= 1:
		return false
	var websocket_peer := peer.get_peer(peer_id)
	return websocket_peer != null and websocket_peer.get_ready_state() == WebSocketPeer.STATE_OPEN

func _check_reconnect_timeouts(room_code: String, now: float) -> void:
	if not rooms.has(room_code):
		return
	var room: Dictionary = rooms[room_code]
	var match_state: DuelMatch = room.get("match") as DuelMatch
	if match_state == null or match_state.phase != "running":
		return
	for token_variant in room.get("tokens", []):
		var token := str(token_variant)
		var disconnected_at := float(sessions.get(token, {}).get("disconnected_at", -1.0))
		if disconnected_at >= 0.0 and now - disconnected_at > DuelRulesScript.RECONNECT_GRACE:
			match_state.finish_forfeit(_room_slot(room, token))
			return

func _reset_room_after_result(room_code: String) -> void:
	if not rooms.has(room_code):
		return
	var room: Dictionary = rooms[room_code]
	room["state"] = "waiting"
	room["match"] = null
	room["ready"] = {}
	room["rematch"] = {}
	room.erase("ready_deadline")
	for token_variant in room.get("tokens", []):
		(room["ready"] as Dictionary)[str(token_variant)] = false
	rooms[room_code] = room
	_broadcast_lobby(room_code)

func _leave_session_activity(token: String, notify: bool = true) -> void:
	if not sessions.has(token):
		return
	_remove_from_queue(token)
	var room_code := str(sessions[token].get("room", ""))
	if room_code != "" and rooms.has(room_code):
		_remove_token_from_room(room_code, token, "玩家已离开")
	if notify:
		_send_token(token, "lobby", {"state": "idle"})

func _remove_token_from_room(room_code: String, token: String, message: String) -> void:
	if not rooms.has(room_code):
		return
	var room: Dictionary = rooms[room_code]
	var tokens: Array = room.get("tokens", [])
	if str(room.get("state", "")) == "match" or str(room.get("state", "")) == "countdown":
		_forfeit_and_remove(room_code, token)
		return
	if str(room.get("owner", "")) == token:
		_close_room(room_code, message)
		return
	tokens.erase(token)
	(room.get("ready", {}) as Dictionary).erase(token)
	room["tokens"] = tokens
	rooms[room_code] = room
	if sessions.has(token):
		sessions[token]["room"] = ""
	_broadcast_lobby(room_code)

func _forfeit_and_remove(room_code: String, token: String) -> void:
	if not rooms.has(room_code):
		return
	var room: Dictionary = rooms[room_code]
	var slot := _room_slot(room, token)
	var match_state: DuelMatch = room.get("match") as DuelMatch
	if match_state != null and match_state.phase == "running" and slot >= 0:
		match_state.finish_forfeit(slot)
		_broadcast_message(room_code, "result", match_state.result)
	var tokens: Array = room.get("tokens", [])
	tokens.erase(token)
	room["tokens"] = tokens
	room["state"] = "result"
	room["result_deadline"] = Time.get_ticks_msec() / 1000.0 + DuelRulesScript.REMATCH_WINDOW
	room["rematch"] = {}
	if not tokens.is_empty():
		room["owner"] = str(tokens[0])
	rooms[room_code] = room
	if sessions.has(token):
		sessions[token]["room"] = ""
	print("DUEL_MATCH_FORFEIT room=%s slot=%d" % [room_code, slot])

func _expire_ready_room(room_code: String) -> void:
	if not rooms.has(room_code):
		return
	var room: Dictionary = rooms[room_code]
	var tokens: Array = (room.get("tokens", []) as Array).duplicate()
	var return_to_queue := bool(room.get("quick_match", false))
	rooms.erase(room_code)
	for token_variant in tokens:
		var token := str(token_variant)
		if not sessions.has(token):
			continue
		sessions[token]["room"] = ""
		if return_to_queue and int(sessions[token].get("peer_id", 0)) > 1:
			if not quick_queue.has(token):
				quick_queue.append(token)
			sessions[token]["queued"] = true
			_send_token(token, "event", {"ok": false, "message": "准备超时，已返回快速匹配队列"})
			_send_token(token, "lobby", {"state": "queue", "queue_size": quick_queue.size()})
		else:
			_send_token(token, "lobby", {"state": "idle"})
	print("DUEL_READY_TIMEOUT room=%s" % room_code)

func _close_room(room_code: String, message: String) -> void:
	if not rooms.has(room_code):
		return
	var room: Dictionary = rooms[room_code]
	for token_variant in room.get("tokens", []):
		var token := str(token_variant)
		if sessions.has(token):
			sessions[token]["room"] = ""
		_send_token(token, "event", {"ok": false, "message": message})
		_send_token(token, "lobby", {"state": "idle"})
	rooms.erase(room_code)

func _remove_from_queue(token: String) -> void:
	quick_queue.erase(token)
	if sessions.has(token):
		sessions[token]["queued"] = false

func _remove_invalid_queue_entries() -> void:
	for index in range(quick_queue.size() - 1, -1, -1):
		var token := quick_queue[index]
		if not sessions.has(token) or int(sessions[token].get("peer_id", 0)) <= 1 or str(sessions[token].get("room", "")) != "":
			quick_queue.remove_at(index)

func _room_slot(room: Dictionary, token: String) -> int:
	return (room.get("tokens", []) as Array).find(token)

func _new_room_code() -> String:
	for _attempt in range(100):
		var code := "%06d" % randi_range(100000, 999999)
		if not rooms.has(code):
			return code
	return "%06d" % ((Time.get_ticks_msec() % 900000) + 100000)

func _new_token() -> String:
	var bytes := Crypto.new().generate_random_bytes(24)
	return bytes.hex_encode()

func _sanitize_nickname(value: String) -> String:
	var clean := value.replace("\n", "").replace("\r", "").replace("\t", " ").strip_edges()
	if clean == "":
		clean = "旅人%04d" % randi_range(0, 9999)
	return clean.left(12)

func _rate_limit(token: String, bucket: String, limit: int) -> bool:
	if not sessions.has(token):
		return false
	var session: Dictionary = sessions[token]
	var rate: Dictionary = session.get("rate", {})
	var now := Time.get_ticks_msec() / 1000.0
	var state: Dictionary = rate.get(bucket, {"start": now, "count": 0})
	if now - float(state.get("start", now)) >= 1.0:
		state = {"start": now, "count": 0}
	state["count"] = int(state.get("count", 0)) + 1
	rate[bucket] = state
	session["rate"] = rate
	sessions[token] = session
	return int(state["count"]) <= limit

func _env_int(key: String, fallback: int) -> int:
	var value := OS.get_environment(key)
	return int(value) if value.is_valid_int() else fallback

func _safe_token(token: String) -> String:
	return token.left(6) if token.length() >= 6 else "short"
