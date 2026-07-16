extends SceneTree

const DuelRulesScript = preload("res://scripts/duel/duel_rules.gd")
const DuelMatchScript = preload("res://scripts/duel/duel_match.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_test_order_generation()
	_test_shared_stock_refill()
	_test_complete_pipeline_and_score()
	_test_burn_and_timeout()
	if failures.is_empty():
		print("DUEL_RULES_TEST_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("DUEL_RULES_TEST_FAILED count=%d" % failures.size())
	quit(1)

func _test_order_generation() -> void:
	var first: Array[Dictionary] = DuelRulesScript.create_orders(20260715)
	var second: Array[Dictionary] = DuelRulesScript.create_orders(20260715)
	_check(first == second, "相同随机种子必须生成完全一致的订单")
	for seed_value in range(1, 201):
		var orders: Array[Dictionary] = DuelRulesScript.create_orders(seed_value)
		_check(orders.size() == 7, "每局必须生成 7 张订单")
		var pot_count := 0
		var grill_count := 0
		var last_crop := ""
		for order in orders:
			var recipe := str(order.get("recipe", ""))
			var recipe_data: Dictionary = DuelRulesScript.RECIPES.get(recipe, {})
			var station := str(recipe_data.get("station", ""))
			if station == "pot":
				pot_count += 1
			elif station == "grill":
				grill_count += 1
			var crop := str(recipe_data.get("crop", ""))
			_check(crop != last_crop, "相邻订单不能使用同一种作物（种子 %d）" % seed_value)
			last_crop = crop
		_check(absi(pot_count - grill_count) <= 1, "煮锅和烧烤订单数量必须接近")

func _test_shared_stock_refill() -> void:
	var duel := _new_match()
	_set_position(duel, 0, DuelRulesScript.stock_positions()["carrot"])
	var take_result: Dictionary = duel.interact(0)
	_check(bool(take_result.get("ok", false)), "玩家应能从共享库存拿取胡萝卜")
	_check(int(duel.stock["carrot"].get("count", -1)) == 1, "拿取后共享库存应减少一份")
	_tick_for(duel, DuelRulesScript.STOCK_REFILL_SECONDS + 0.1)
	_check(int(duel.stock["carrot"].get("count", -1)) == 2, "共享库存应按 4 秒补充至上限")
	var second_take: Dictionary = duel.interact(1)
	_check(not bool(second_take.get("ok", false)), "远离库存的玩家不能凭空拿取食材")

func _test_complete_pipeline_and_score() -> void:
	var duel := _new_match()
	var player: Dictionary = duel.players[0]
	player["orders"] = [{
		"id": 1, "recipe": "carrot_soup", "arrival": 0.0,
		"deadline": 45.0, "status": "active",
	}]
	duel.players[0] = player
	_set_position(duel, 0, DuelRulesScript.stock_positions()["carrot"])
	_check(bool(duel.interact(0).get("ok", false)), "加工链：应能拿取原料")
	_set_position(duel, 0, DuelRulesScript.station_positions(0)["sink"])
	_check(bool(duel.interact(0).get("ok", false)), "加工链：应能放入洗菜池")
	_tick_for(duel, DuelRulesScript.WASH_DURATION + 0.1)
	_check(bool(duel.interact(0).get("ok", false)), "加工链：应能取出洗净食材")
	_set_position(duel, 0, DuelRulesScript.station_positions(0)["pot"])
	_check(bool(duel.interact(0).get("ok", false)), "加工链：洗净胡萝卜应能进入煮锅")
	_tick_for(duel, DuelRulesScript.POT_DURATION + 0.1)
	_check(bool(duel.interact(0).get("ok", false)), "加工链：应能从煮锅取出成品")
	_set_position(duel, 0, DuelRulesScript.station_positions(0)["prep_shelf"])
	_check(bool(duel.interact(0).get("ok", false)), "加工链：到达订单应能从备菜架出餐")
	var finished_player: Dictionary = duel.players[0]
	_check(int(finished_player.get("served", 0)) == 1, "成功出餐必须增加完成订单数")
	_check(int(finished_player.get("score", 0)) >= 180, "成功出餐必须按菜价和剩余时间计分")
	var score_before_repeat := int(finished_player.get("score", 0))
	duel.interact(0)
	_check(int(duel.players[0].get("score", 0)) == score_before_repeat, "重复交互不得重复计算同一订单分数")

func _test_burn_and_timeout() -> void:
	var duel := _new_match()
	var player: Dictionary = duel.players[0]
	var stations: Dictionary = player.get("stations", {})
	stations["grill"] = {
		"state": "ready", "remaining": 0.0, "ready": 0.05,
		"crop": "carrot", "stage": "dish", "recipe": "grilled_carrot",
	}
	player["stations"] = stations
	duel.players[0] = player
	duel.tick(0.1)
	_check(str(duel.players[0]["stations"]["grill"].get("state", "")) == "burnt", "成品保留超时后必须烧焦")

	var timeout_duel := _new_match()
	_tick_for(timeout_duel, DuelRulesScript.MATCH_DURATION + 0.5)
	_check(timeout_duel.phase == "finished", "120 秒到达后比赛必须结束")
	_check(not timeout_duel.result.is_empty(), "比赛结束必须产生权威结算")
	_check(int(timeout_duel.players[0].get("missed", 0)) == 7, "未完成的 7 张订单必须全部计为漏单")

func _new_match() -> RefCounted:
	return DuelMatchScript.new(1337, [
		{"nickname": "测试甲", "token": "a", "peer_id": 2},
		{"nickname": "测试乙", "token": "b", "peer_id": 3},
	])

func _set_position(duel: RefCounted, slot: int, position: Vector2) -> void:
	var player: Dictionary = duel.players[slot]
	player["position"] = position
	duel.players[slot] = player

func _tick_for(duel: RefCounted, seconds: float) -> void:
	var steps := int(ceil(seconds / 0.05))
	for _index in range(steps):
		duel.tick(0.05)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
