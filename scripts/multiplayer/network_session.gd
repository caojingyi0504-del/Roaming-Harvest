extends RefCounted
class_name NetworkSession

signal connection_requested(address: String, port: int)
signal connection_closed()
signal state_received(state: Dictionary)

enum Mode {
	OFFLINE,
	HOST,
	CLIENT,
}

var mode: Mode = Mode.OFFLINE
var peer_id: int = 1

func host(_port: int) -> Error:
	mode = Mode.HOST
	return OK

func join(address: String, port: int) -> Error:
	mode = Mode.CLIENT
	connection_requested.emit(address, port)
	return OK

func leave() -> void:
	mode = Mode.OFFLINE
	connection_closed.emit()

func submit_local_state(_state: Dictionary) -> void:
	pass

func apply_remote_state(state: Dictionary) -> void:
	state_received.emit(state)

func is_online() -> bool:
	return mode != Mode.OFFLINE
