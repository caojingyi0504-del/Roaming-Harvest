extends RefCounted
class_name DuelMatch

const DuelRulesScript = preload("res://scripts/duel/duel_rules.gd")

var seed_value := 1
var phase := "running"
var elapsed := 0.0
var players: Dictionary = {}
var stock: Dictionary = {}
var result: Dictionary = {}

func _init(match_seed: int = 1, player_entries: Array = []) -> void:
	seed_value = match_seed
	for crop in DuelRulesScript.CROPS:
		stock[crop] = {"count": DuelRulesScript.STOCK_MAX, "refill": 0.0}
	for slot in range(mini(player_entries.size(), 2)):
		var entry: Dictionary = player_entries[slot]
		players[slot] = _make_player(slot, entry)

func set_input(slot: int, sequence: int, direction: Vector2) -> void:
	if phase != "running" or not players.has(slot):
		return
	var player: Dictionary = players[slot]
	if sequence <= int(player.get("input_sequence", -1)):
		return
	player["input_sequence"] = sequence
	player["input"] = direction.limit_length(1.0)
	players[slot] = player

func tick(delta: float) -> void:
	if phase != "running":
		return
	delta = clampf(delta, 0.0, 0.1)
	elapsed += delta
	_tick_stock(delta)
	for slot in players.keys():
		_tick_player(int(slot), delta)
		_tick_orders(int(slot))
		_tick_stations(int(slot), delta)
	if elapsed >= DuelRulesScript.MATCH_DURATION:
		_finish_match("time")

func interact(slot: int) -> Dictionary:
	if phase != "running" or not players.has(slot):
		return _event(false, "比赛尚未开始")
	var player: Dictionary = players[slot]
	var position: Vector2 = player.get("position", Vector2.ZERO)
	var nearest_kind := ""
	var nearest_id := ""
	var nearest_distance := DuelRulesScript.INTERACT_RADIUS * DuelRulesScript.INTERACT_RADIUS
	for crop in DuelRulesScript.CROPS:
		var crop_position: Vector2 = DuelRulesScript.stock_positions()[crop]
		var distance := position.distance_squared_to(crop_position)
		if distance <= nearest_distance:
			nearest_distance = distance
			nearest_kind = "stock"
			nearest_id = crop
	var positions := DuelRulesScript.station_positions(slot)
	for station_id in positions.keys():
		var station_position: Vector2 = positions[station_id]
		var distance := position.distance_squared_to(station_position)
		if distance <= nearest_distance:
			nearest_distance = distance
			nearest_kind = "station"
			nearest_id = str(station_id)
	if nearest_kind == "stock":
		return _take_stock(slot, nearest_id)
	if nearest_kind == "station":
		return _use_station(slot, nearest_id)
	return _event(false, "附近没有可交互的食材或设备")

func disconnect_slot(slot: int) -> void:
	if players.has(slot):
		players[slot]["connected"] = false

func reconnect_slot(slot: int, peer_id: int) -> void:
	if players.has(slot):
		players[slot]["connected"] = true
		players[slot]["peer_id"] = peer_id

func finish_forfeit(loser_slot: int) -> void:
	if phase != "running":
		return
	var winner_slot := 1 - loser_slot
	_finish_match("forfeit", winner_slot)

func snapshot() -> Dictionary:
	var serialized_players := {}
	for slot in players.keys():
		var player: Dictionary = players[slot]
		serialized_players[str(slot)] = {
			"nickname": player.get("nickname", "旅人"),
			"position": _vector_to_array(player.get("position", Vector2.ZERO)),
			"held": player.get("held", {}).duplicate(true),
			"score": int(player.get("score", 0)),
			"served": int(player.get("served", 0)),
			"missed": int(player.get("missed", 0)),
			"connected": bool(player.get("connected", true)),
			"stations": _serialize_stations(player.get("stations", {})),
			"shelf": player.get("shelf", []).duplicate(true),
			"orders": player.get("orders", []).duplicate(true),
		}
	var serialized_stock := {}
	for crop in stock.keys():
		serialized_stock[crop] = int(stock[crop].get("count", 0))
	return {
		"phase": phase,
		"seed": seed_value,
		"elapsed": elapsed,
		"remaining": maxf(DuelRulesScript.MATCH_DURATION - elapsed, 0.0),
		"stock": serialized_stock,
		"players": serialized_players,
		"result": result.duplicate(true),
	}

func _make_player(slot: int, entry: Dictionary) -> Dictionary:
	var stations := {}
	for station_id in DuelRulesScript.EQUIPMENT_NAMES.keys():
		stations[station_id] = _empty_station()
	return {
		"token": str(entry.get("token", "")),
		"peer_id": int(entry.get("peer_id", 0)),
		"nickname": str(entry.get("nickname", "旅人")),
		"connected": true,
		"position": Vector2(-7.0, -7.5) if slot == 0 else Vector2(7.0, -7.5),
		"input": Vector2.ZERO,
		"input_sequence": -1,
		"held": {},
		"stations": stations,
		"shelf": [],
		"orders": DuelRulesScript.create_orders(seed_value),
		"score": 0,
		"served": 0,
		"missed": 0,
		"completion_sum": 0.0,
	}

func _empty_station() -> Dictionary:
	return {"state": "idle", "remaining": 0.0, "ready": 0.0, "crop": "", "stage": "", "recipe": ""}

func _tick_stock(delta: float) -> void:
	for crop in stock.keys():
		var state: Dictionary = stock[crop]
		if int(state.get("count", 0)) >= DuelRulesScript.STOCK_MAX:
			state["refill"] = 0.0
		else:
			state["refill"] = float(state.get("refill", 0.0)) + delta
			while float(state["refill"]) >= DuelRulesScript.STOCK_REFILL_SECONDS and int(state["count"]) < DuelRulesScript.STOCK_MAX:
				state["refill"] = float(state["refill"]) - DuelRulesScript.STOCK_REFILL_SECONDS
				state["count"] = int(state["count"]) + 1
		stock[crop] = state

func _tick_player(slot: int, delta: float) -> void:
	var player: Dictionary = players[slot]
	var direction: Vector2 = player.get("input", Vector2.ZERO)
	var position: Vector2 = player.get("position", Vector2.ZERO)
	position += direction.limit_length(1.0) * DuelRulesScript.MOVE_SPEED * delta
	player["position"] = DuelRulesScript.lane_clamp(position, slot)
	players[slot] = player

func _tick_orders(slot: int) -> void:
	var player: Dictionary = players[slot]
	var orders: Array = player.get("orders", [])
	for index in range(orders.size()):
		var order: Dictionary = orders[index]
		if str(order.get("status", "")) == "upcoming" and elapsed >= float(order.get("arrival", 0.0)):
			order["status"] = "active"
		if str(order.get("status", "")) == "active" and elapsed >= float(order.get("deadline", 0.0)):
			order["status"] = "missed"
			player["missed"] = int(player.get("missed", 0)) + 1
			player["score"] = int(player.get("score", 0)) - 50
		orders[index] = order
	player["orders"] = orders
	players[slot] = player

func _tick_stations(slot: int, delta: float) -> void:
	var player: Dictionary = players[slot]
	var stations: Dictionary = player.get("stations", {})
	for station_id in stations.keys():
		var station: Dictionary = stations[station_id]
		var state := str(station.get("state", "idle"))
		if state == "working":
			station["remaining"] = maxf(float(station.get("remaining", 0.0)) - delta, 0.0)
			if float(station["remaining"]) <= 0.0:
				station["state"] = "ready" if station_id == "pot" or station_id == "grill" else "done"
				station["ready"] = DuelRulesScript.READY_DURATION if station["state"] == "ready" else 0.0
		elif state == "ready":
			station["ready"] = maxf(float(station.get("ready", 0.0)) - delta, 0.0)
			if float(station["ready"]) <= 0.0:
				station["state"] = "burnt"
		stations[station_id] = station
	player["stations"] = stations
	players[slot] = player

func _take_stock(slot: int, crop: String) -> Dictionary:
	var player: Dictionary = players[slot]
	if not (player.get("held", {}) as Dictionary).is_empty():
		return _event(false, "先处理手上的物品")
	var state: Dictionary = stock.get(crop, {})
	if int(state.get("count", 0)) <= 0:
		return _event(false, "%s正在补货" % DuelRulesScript.crop_name(crop))
	state["count"] = int(state["count"]) - 1
	state["refill"] = 0.0
	stock[crop] = state
	player["held"] = {"kind": "ingredient", "crop": crop, "stage": "raw", "recipe": ""}
	players[slot] = player
	return _event(true, "拿取%s" % DuelRulesScript.crop_name(crop))

func _use_station(slot: int, station_id: String) -> Dictionary:
	var player: Dictionary = players[slot]
	var held: Dictionary = player.get("held", {})
	var stations: Dictionary = player.get("stations", {})
	var station: Dictionary = stations.get(station_id, _empty_station())
	var state := str(station.get("state", "idle"))
	if station_id == "prep_shelf":
		return _use_shelf(slot)
	if state == "burnt":
		stations[station_id] = _empty_station()
		player["stations"] = stations
		players[slot] = player
		return _event(true, "已清理烧焦食物")
	if state == "done" or state == "ready":
		if not held.is_empty():
			return _event(false, "先放下手上的物品")
		if station_id == "pot" or station_id == "grill":
			player["held"] = {"kind": "dish", "crop": str(station.get("crop", "")), "stage": "dish", "recipe": str(station.get("recipe", ""))}
		else:
			player["held"] = {"kind": "ingredient", "crop": str(station.get("crop", "")), "stage": str(station.get("stage", "")), "recipe": ""}
		stations[station_id] = _empty_station()
		player["stations"] = stations
		players[slot] = player
		return _event(true, "取出%s" % _held_name(player["held"]))
	if state != "idle":
		return _event(false, "%s正在处理" % DuelRulesScript.EQUIPMENT_NAMES.get(station_id, station_id))
	if held.is_empty():
		return _event(false, "手上没有可处理的食材")
	var crop := str(held.get("crop", ""))
	var stage := str(held.get("stage", ""))
	if station_id == "sink":
		if stage != "raw":
			return _event(false, "只能清洗原始食材")
		station = {"state": "working", "remaining": DuelRulesScript.WASH_DURATION, "ready": 0.0, "crop": crop, "stage": "washed", "recipe": ""}
	elif station_id == "cutting_table":
		if stage != "washed" or not DuelRulesScript.crop_needs_cut(crop):
			return _event(false, "这份食材现在不需要切配")
		station = {"state": "working", "remaining": DuelRulesScript.CUT_DURATION, "ready": 0.0, "crop": crop, "stage": "chopped", "recipe": ""}
	elif station_id == "pot" or station_id == "grill":
		var recipe := DuelRulesScript.recipe_for(crop, station_id)
		if recipe == "":
			return _event(false, "这种食材不适合当前设备")
		var recipe_data: Dictionary = DuelRulesScript.RECIPES[recipe]
		var required_stage := "chopped" if bool(recipe_data.get("needs_cut", false)) else "washed"
		if stage != required_stage:
			return _event(false, "食材加工步骤不正确")
		var duration := DuelRulesScript.POT_DURATION if station_id == "pot" else DuelRulesScript.GRILL_DURATION
		station = {"state": "working", "remaining": duration, "ready": 0.0, "crop": crop, "stage": "dish", "recipe": recipe}
	else:
		return _event(false, "未知设备")
	stations[station_id] = station
	player["held"] = {}
	player["stations"] = stations
	players[slot] = player
	return _event(true, "%s开始处理" % DuelRulesScript.EQUIPMENT_NAMES.get(station_id, station_id))

func _use_shelf(slot: int) -> Dictionary:
	var player: Dictionary = players[slot]
	var held: Dictionary = player.get("held", {})
	var shelf: Array = player.get("shelf", [])
	if not held.is_empty():
		if str(held.get("kind", "")) != "dish":
			return _event(false, "备菜架只能放成品料理")
		var recipe := str(held.get("recipe", ""))
		if _serve_recipe(player, recipe):
			player["held"] = {}
			players[slot] = player
			return _event(true, "%s已出餐" % DuelRulesScript.recipe_name(recipe))
		if not _has_future_order(player, recipe):
			return _event(false, "当前和未来订单都不需要这道菜")
		if shelf.size() >= 2:
			return _event(false, "备菜架已满")
		shelf.append(held.duplicate(true))
		player["shelf"] = shelf
		player["held"] = {}
		players[slot] = player
		return _event(true, "%s已提前备菜" % DuelRulesScript.recipe_name(recipe))
	for index in range(shelf.size()):
		var dish: Dictionary = shelf[index]
		if _serve_recipe(player, str(dish.get("recipe", ""))):
			var served_recipe := str(dish.get("recipe", ""))
			shelf.remove_at(index)
			player["shelf"] = shelf
			players[slot] = player
			return _event(true, "%s已出餐" % DuelRulesScript.recipe_name(served_recipe))
	return _event(false, "备菜架里没有已到达订单需要的菜")

func _serve_recipe(player: Dictionary, recipe: String) -> bool:
	var orders: Array = player.get("orders", [])
	for index in range(orders.size()):
		var order: Dictionary = orders[index]
		if str(order.get("status", "")) == "active" and str(order.get("recipe", "")) == recipe:
			var remaining := maxf(float(order.get("deadline", 0.0)) - elapsed, 0.0)
			order["status"] = "served"
			order["score"] = DuelRulesScript.score_for(recipe, remaining)
			order["served_at"] = elapsed
			orders[index] = order
			player["orders"] = orders
			player["score"] = int(player.get("score", 0)) + int(order["score"])
			player["served"] = int(player.get("served", 0)) + 1
			player["completion_sum"] = float(player.get("completion_sum", 0.0)) + elapsed
			return true
	return false

func _has_future_order(player: Dictionary, recipe: String) -> bool:
	for order_variant in player.get("orders", []):
		var order: Dictionary = order_variant
		if str(order.get("recipe", "")) == recipe and str(order.get("status", "")) == "upcoming":
			return true
	return false

func _finish_match(reason: String, forced_winner: int = -1) -> void:
	if phase != "running":
		return
	for slot in players.keys():
		var player: Dictionary = players[slot]
		var orders: Array = player.get("orders", [])
		for index in range(orders.size()):
			var order: Dictionary = orders[index]
			if str(order.get("status", "")) == "active" or str(order.get("status", "")) == "upcoming":
				order["status"] = "missed"
				player["missed"] = int(player.get("missed", 0)) + 1
				player["score"] = int(player.get("score", 0)) - 50
			orders[index] = order
		player["orders"] = orders
		players[slot] = player
	var winner := forced_winner
	if winner < 0:
		winner = _compare_players()
	phase = "finished"
	result = {
		"reason": reason,
		"winner": winner,
		"players": {
			"0": _result_player(0),
			"1": _result_player(1),
		},
	}

func _compare_players() -> int:
	var first: Dictionary = players.get(0, {})
	var second: Dictionary = players.get(1, {})
	if int(first.get("score", 0)) != int(second.get("score", 0)):
		return 0 if int(first.get("score", 0)) > int(second.get("score", 0)) else 1
	if int(first.get("served", 0)) != int(second.get("served", 0)):
		return 0 if int(first.get("served", 0)) > int(second.get("served", 0)) else 1
	if int(first.get("missed", 0)) != int(second.get("missed", 0)):
		return 0 if int(first.get("missed", 0)) < int(second.get("missed", 0)) else 1
	if not is_equal_approx(float(first.get("completion_sum", 0.0)), float(second.get("completion_sum", 0.0))):
		return 0 if float(first.get("completion_sum", 0.0)) < float(second.get("completion_sum", 0.0)) else 1
	return -1

func _result_player(slot: int) -> Dictionary:
	var player: Dictionary = players.get(slot, {})
	return {
		"nickname": str(player.get("nickname", "旅人")),
		"score": int(player.get("score", 0)),
		"served": int(player.get("served", 0)),
		"missed": int(player.get("missed", 0)),
		"orders": player.get("orders", []).duplicate(true),
	}

func _serialize_stations(stations: Dictionary) -> Dictionary:
	var output := {}
	for station_id in stations.keys():
		output[station_id] = (stations[station_id] as Dictionary).duplicate(true)
	return output

func _vector_to_array(value: Vector2) -> Array:
	return [value.x, value.y]

func _held_name(held: Dictionary) -> String:
	if str(held.get("kind", "")) == "dish":
		return DuelRulesScript.recipe_name(str(held.get("recipe", "")))
	return DuelRulesScript.crop_name(str(held.get("crop", "")))

func _event(ok: bool, message: String) -> Dictionary:
	return {"ok": ok, "message": message}
