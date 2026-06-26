extends Node

signal player_registered(player: Node)
signal game_state_changed(state: StringName)
signal multiplayer_state_changed(mode: int)

const NetworkSessionScript := preload("res://scripts/multiplayer/network_session.gd")

var player: Node
var game_state: StringName = &"boot"
var network_session: RefCounted = NetworkSessionScript.new()

func _ready() -> void:
	set_game_state(&"playing")

func register_player(player_node: Node) -> void:
	player = player_node
	player_registered.emit(player)

func set_game_state(state: StringName) -> void:
	if game_state == state:
		return
	game_state = state
	game_state_changed.emit(game_state)

func pause_game() -> void:
	get_tree().paused = true
	set_game_state(&"paused")

func resume_game() -> void:
	get_tree().paused = false
	set_game_state(&"playing")

func request_host(port: int = 7777) -> Error:
	var result: Error = network_session.host(port)
	multiplayer_state_changed.emit(network_session.mode)
	return result

func request_join(address: String, port: int = 7777) -> Error:
	var result: Error = network_session.join(address, port)
	multiplayer_state_changed.emit(network_session.mode)
	return result

func leave_multiplayer() -> void:
	network_session.leave()
	multiplayer_state_changed.emit(network_session.mode)
