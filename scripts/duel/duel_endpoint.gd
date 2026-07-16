extends Node
class_name DuelEndpoint

signal request_received(peer_id: int, kind: String, payload: Dictionary)
signal input_received(peer_id: int, sequence: int, direction: Vector2)
signal message_received(kind: String, payload: Dictionary)
signal snapshot_received(payload: Dictionary)

@rpc("any_peer", "call_remote", "reliable", 0)
func submit_request(kind: String, payload: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	request_received.emit(multiplayer.get_remote_sender_id(), kind, payload)

@rpc("any_peer", "call_remote", "unreliable_ordered", 1)
func submit_input(sequence: int, x_axis: float, y_axis: float) -> void:
	if not multiplayer.is_server():
		return
	input_received.emit(multiplayer.get_remote_sender_id(), sequence, Vector2(x_axis, y_axis))

@rpc("authority", "call_remote", "reliable", 0)
func receive_message(kind: String, payload: Dictionary) -> void:
	if multiplayer.is_server():
		return
	message_received.emit(kind, payload)

@rpc("authority", "call_remote", "unreliable_ordered", 1)
func receive_snapshot(payload: Dictionary) -> void:
	if multiplayer.is_server():
		return
	snapshot_received.emit(payload)

func request(kind: String, payload: Dictionary = {}) -> void:
	if multiplayer.multiplayer_peer == null or multiplayer.is_server():
		return
	submit_request.rpc_id(1, kind, payload)

func send_input(sequence: int, direction: Vector2) -> void:
	if multiplayer.multiplayer_peer == null or multiplayer.is_server():
		return
	submit_input.rpc_id(1, sequence, direction.x, direction.y)

func send_message(peer_id: int, kind: String, payload: Dictionary = {}) -> void:
	if not multiplayer.is_server() or peer_id <= 1:
		return
	receive_message.rpc_id(peer_id, kind, payload)

func send_snapshot(peer_id: int, payload: Dictionary) -> void:
	if not multiplayer.is_server() or peer_id <= 1:
		return
	receive_snapshot.rpc_id(peer_id, payload)
