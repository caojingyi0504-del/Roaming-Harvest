extends Node

const DuelMatchScript = preload("res://scripts/duel/duel_match.gd")

@onready var arena: Node = $Arena

func _ready() -> void:
	var duel := DuelMatchScript.new(2468, [
		{"nickname": "本地玩家", "token": "a", "peer_id": 2},
		{"nickname": "远程玩家", "token": "b", "peer_id": 3},
	])
	arena.call("configure", 0, "123456")
	arena.call("apply_snapshot", duel.snapshot(), 0)
	arena.call("show_toast", "竞技场界面运行正常", true)
	await get_tree().create_timer(0.25).timeout
	arena.call("show_result", {
		"winner": 0,
		"players": {
			"0": {"nickname": "本地玩家", "score": 520, "served": 2, "missed": 0},
			"1": {"nickname": "远程玩家", "score": 480, "served": 2, "missed": 1},
		},
	}, 0)
	await get_tree().create_timer(0.25).timeout
	print("DUEL_ARENA_SMOKE_OK viewport=%s" % get_viewport().get_visible_rect().size)
	get_tree().quit(0)

func submit_duel_input(_direction: Vector2) -> void:
	pass

func submit_duel_interact() -> void:
	pass

func request_rematch() -> void:
	pass

func leave_duel() -> void:
	pass

