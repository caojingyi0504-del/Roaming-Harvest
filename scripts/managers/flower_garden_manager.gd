extends Node

signal state_changed
signal garden_unlocked

const SAVE_VERSION := 1
const SAVE_PATH := "user://flower_garden_save.json"
const PLOT_COUNT := 3
const FLOWER_YIELD := 2
const GIFT_FLOWER_COST := 4

const FLOWERS: Array[Dictionary] = [
	{
		"id": "marigold",
		"name": "金盏花",
		"icon": "✿",
		"grow_seconds": 15.0 * 60.0,
		"seed_price": 6,
		"color": Color(0.98, 0.58, 0.16, 1.0),
		"gift_id": "sunny_welcome_basket",
		"gift_name": "暖阳迎客花篮",
		"gift_effect": "本场完成订单额外收益 +8%",
	},
	{
		"id": "lavender",
		"name": "薰衣草",
		"icon": "❀",
		"grow_seconds": 30.0 * 60.0,
		"seed_price": 8,
		"color": Color(0.62, 0.48, 0.86, 1.0),
		"gift_id": "calming_bouquet",
		"gift_name": "安神香束",
		"gift_effect": "本场所有订单初始时限 +5秒",
	},
	{
		"id": "borage",
		"name": "琉璃苣",
		"icon": "✾",
		"grow_seconds": 45.0 * 60.0,
		"seed_price": 10,
		"color": Color(0.34, 0.62, 0.90, 1.0),
		"gift_id": "starblue_plating_flowers",
		"gift_name": "星蓝餐花",
		"gift_effect": "本场前2份成功出餐品质 +1",
	},
]

var unlocked := false
var starter_granted := false
var intro_seen := false
var seeds: Dictionary = {}
var flowers: Dictionary = {}
var gifts: Dictionary = {}
var plots: Array[Dictionary] = []
var selected_gift := ""

var active_gift := ""
var active_quality_remaining := 0
var active_bonus_coins := 0
var active_quality_orders := 0


func _ready() -> void:
	_reset_defaults()
	_load_state()


func _reset_defaults() -> void:
	seeds.clear()
	flowers.clear()
	gifts.clear()
	for definition in FLOWERS:
		var flower_id := str(definition.get("id", ""))
		var gift_id := str(definition.get("gift_id", ""))
		seeds[flower_id] = 0
		flowers[flower_id] = 0
		gifts[gift_id] = 0
	plots.clear()
	for _index in range(PLOT_COUNT):
		plots.append(_empty_plot())


func _empty_plot() -> Dictionary:
	return {"flower_id": "", "planted_at_unix": 0.0}


func flower_definitions() -> Array[Dictionary]:
	return FLOWERS.duplicate(true)


func flower_definition(flower_id: String) -> Dictionary:
	for definition in FLOWERS:
		if str(definition.get("id", "")) == flower_id:
			return definition
	return {}


func gift_definition(gift_id: String) -> Dictionary:
	for definition in FLOWERS:
		if str(definition.get("gift_id", "")) == gift_id:
			return definition
	return {}


func unlock() -> bool:
	var newly_unlocked := not unlocked
	unlocked = true
	if not starter_granted:
		starter_granted = true
		seeds["marigold"] = int(seeds.get("marigold", 0)) + 3
		flowers["marigold"] = int(flowers.get("marigold", 0)) + 4
	_save_state()
	state_changed.emit()
	if newly_unlocked:
		garden_unlocked.emit()
	return newly_unlocked


func mark_intro_seen() -> void:
	if intro_seen:
		return
	intro_seen = true
	_save_state()
	state_changed.emit()


func seed_count(flower_id: String) -> int:
	return maxi(int(seeds.get(flower_id, 0)), 0)


func flower_count(flower_id: String) -> int:
	return maxi(int(flowers.get(flower_id, 0)), 0)


func gift_count(gift_id: String) -> int:
	return maxi(int(gifts.get(gift_id, 0)), 0)


func seed_purchase_cost(flower_id: String, amount: int) -> int:
	var definition := flower_definition(flower_id)
	if definition.is_empty():
		return 0
	return maxi(amount, 0) * maxi(int(definition.get("seed_price", 0)), 0)


func buy_seeds(flower_id: String, amount: int, available_coins: int) -> Dictionary:
	amount = maxi(amount, 0)
	var cost := seed_purchase_cost(flower_id, amount)
	if amount <= 0 or cost <= 0:
		return {"ok": false, "reason": "invalid", "cost": cost}
	if available_coins < cost:
		return {"ok": false, "reason": "coins", "cost": cost}
	seeds[flower_id] = seed_count(flower_id) + amount
	_save_state()
	state_changed.emit()
	return {"ok": true, "cost": cost, "amount": amount}


func plot_snapshot(plot_index: int, now_unix: float = -1.0) -> Dictionary:
	if plot_index < 0 or plot_index >= plots.size():
		return {}
	if now_unix < 0.0:
		now_unix = Time.get_unix_time_from_system()
	var plot: Dictionary = plots[plot_index]
	var flower_id := str(plot.get("flower_id", ""))
	if flower_id == "":
		return {
			"index": plot_index,
			"flower_id": "",
			"state": "empty",
			"progress": 0.0,
			"remaining": 0.0,
			"ready": false,
		}
	var definition := flower_definition(flower_id)
	var duration := maxf(float(definition.get("grow_seconds", 1.0)), 1.0)
	var planted_at := float(plot.get("planted_at_unix", now_unix))
	var elapsed := maxf(now_unix - planted_at, 0.0)
	var progress := clampf(elapsed / duration, 0.0, 1.0)
	var state := "bloom" if progress >= 1.0 else ("bud" if progress >= 0.66 else "seedling")
	return {
		"index": plot_index,
		"flower_id": flower_id,
		"name": str(definition.get("name", flower_id)),
		"state": state,
		"progress": progress,
		"remaining": maxf(duration - elapsed, 0.0),
		"ready": progress >= 1.0,
		"planted_at_unix": planted_at,
	}


func all_plot_snapshots() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var now_unix := Time.get_unix_time_from_system()
	for plot_index in range(plots.size()):
		result.append(plot_snapshot(plot_index, now_unix))
	return result


func ready_plot_count() -> int:
	var count := 0
	for snapshot in all_plot_snapshots():
		if bool(snapshot.get("ready", false)):
			count += 1
	return count


func plant(plot_index: int, flower_id: String) -> Dictionary:
	if plot_index < 0 or plot_index >= plots.size() or flower_definition(flower_id).is_empty():
		return {"ok": false, "reason": "invalid"}
	if str(plots[plot_index].get("flower_id", "")) != "":
		return {"ok": false, "reason": "occupied"}
	if seed_count(flower_id) <= 0:
		return {"ok": false, "reason": "seed"}
	seeds[flower_id] = seed_count(flower_id) - 1
	plots[plot_index] = {
		"flower_id": flower_id,
		"planted_at_unix": Time.get_unix_time_from_system(),
	}
	_save_state()
	state_changed.emit()
	return {"ok": true, "flower_id": flower_id}


func clear_growing_plot(plot_index: int) -> Dictionary:
	var snapshot := plot_snapshot(plot_index)
	if snapshot.is_empty() or str(snapshot.get("state", "")) == "empty":
		return {"ok": false, "reason": "empty"}
	if bool(snapshot.get("ready", false)):
		return {"ok": false, "reason": "ready"}
	plots[plot_index] = _empty_plot()
	_save_state()
	state_changed.emit()
	return {"ok": true}


func harvest(plot_index: int, replant: bool = false) -> Dictionary:
	var snapshot := plot_snapshot(plot_index)
	if snapshot.is_empty() or not bool(snapshot.get("ready", false)):
		return {"ok": false, "reason": "not_ready"}
	var flower_id := str(snapshot.get("flower_id", ""))
	flowers[flower_id] = flower_count(flower_id) + FLOWER_YIELD
	plots[plot_index] = _empty_plot()
	var replanted := false
	if replant and seed_count(flower_id) > 0:
		seeds[flower_id] = seed_count(flower_id) - 1
		plots[plot_index] = {
			"flower_id": flower_id,
			"planted_at_unix": Time.get_unix_time_from_system(),
		}
		replanted = true
	_save_state()
	state_changed.emit()
	return {
		"ok": true,
		"flower_id": flower_id,
		"amount": FLOWER_YIELD,
		"replanted": replanted,
		"missing_seed": replant and not replanted,
	}


func craft_gift(gift_id: String) -> Dictionary:
	var definition := gift_definition(gift_id)
	if definition.is_empty():
		return {"ok": false, "reason": "invalid"}
	var flower_id := str(definition.get("id", ""))
	if flower_count(flower_id) < GIFT_FLOWER_COST:
		return {"ok": false, "reason": "flowers", "need": GIFT_FLOWER_COST}
	flowers[flower_id] = flower_count(flower_id) - GIFT_FLOWER_COST
	gifts[gift_id] = gift_count(gift_id) + 1
	_save_state()
	state_changed.emit()
	return {"ok": true, "gift_id": gift_id}


func select_gift(gift_id: String) -> Dictionary:
	if gift_id == "":
		selected_gift = ""
		_save_state()
		state_changed.emit()
		return {"ok": true}
	if gift_definition(gift_id).is_empty():
		return {"ok": false, "reason": "invalid"}
	if gift_count(gift_id) <= 0:
		return {"ok": false, "reason": "stock"}
	selected_gift = gift_id
	_save_state()
	state_changed.emit()
	return {"ok": true}


func begin_business_gift() -> String:
	if active_gift != "":
		return active_gift
	if selected_gift == "" or gift_count(selected_gift) <= 0:
		if selected_gift != "":
			selected_gift = ""
			_save_state()
			state_changed.emit()
		return ""
	gifts[selected_gift] = gift_count(selected_gift) - 1
	active_gift = selected_gift
	active_quality_remaining = 2 if active_gift == "starblue_plating_flowers" else 0
	active_bonus_coins = 0
	active_quality_orders = 0
	if gift_count(selected_gift) <= 0:
		selected_gift = ""
	_save_state()
	state_changed.emit()
	return active_gift


func refund_active_business_gift() -> void:
	if active_gift == "":
		return
	gifts[active_gift] = gift_count(active_gift) + 1
	if selected_gift == "":
		selected_gift = active_gift
	_clear_active_gift()
	_save_state()
	state_changed.emit()


func active_order_time_bonus() -> float:
	return 5.0 if active_gift == "calming_bouquet" else 0.0


func active_order_coin_bonus(base_price: int) -> int:
	if active_gift != "sunny_welcome_basket":
		return 0
	return maxi(int(round(float(maxi(base_price, 0)) * 0.08)), 0)


func record_active_bonus_coins(amount: int) -> void:
	active_bonus_coins += maxi(amount, 0)


func try_apply_active_quality_bonus() -> bool:
	if active_gift != "starblue_plating_flowers" or active_quality_remaining <= 0:
		return false
	active_quality_remaining -= 1
	active_quality_orders += 1
	return true


func active_status_text() -> String:
	if active_gift == "":
		return ""
	var definition := gift_definition(active_gift)
	if active_gift == "starblue_plating_flowers":
		return "%s · 剩余%d份品质强化" % [str(definition.get("gift_name", "花礼")), active_quality_remaining]
	return "%s · %s" % [str(definition.get("gift_name", "花礼")), str(definition.get("gift_effect", ""))]


func finish_business_gift() -> Dictionary:
	if active_gift == "":
		return {"gift_id": "", "gift_name": "", "bonus_coins": 0, "quality_orders": 0, "time_bonus": 0}
	var definition := gift_definition(active_gift)
	var result := {
		"gift_id": active_gift,
		"gift_name": str(definition.get("gift_name", "花礼")),
		"effect": str(definition.get("gift_effect", "")),
		"bonus_coins": active_bonus_coins,
		"quality_orders": active_quality_orders,
		"time_bonus": 5 if active_gift == "calming_bouquet" else 0,
	}
	_clear_active_gift()
	return result


func _clear_active_gift() -> void:
	active_gift = ""
	active_quality_remaining = 0
	active_bonus_coins = 0
	active_quality_orders = 0


func _save_state() -> void:
	var snapshot := {
		"version": SAVE_VERSION,
		"unlocked": unlocked,
		"starter_granted": starter_granted,
		"intro_seen": intro_seen,
		"seeds": seeds,
		"flowers": flowers,
		"gifts": gifts,
		"plots": plots,
		"selected_gift": selected_gift,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Unable to save flower garden state: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()


func _load_state() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return
	var snapshot: Dictionary = parsed
	unlocked = bool(snapshot.get("unlocked", false))
	starter_granted = bool(snapshot.get("starter_granted", false))
	intro_seen = bool(snapshot.get("intro_seen", false))
	var saved_seeds = snapshot.get("seeds", {})
	var saved_flowers = snapshot.get("flowers", {})
	var saved_gifts = snapshot.get("gifts", {})
	for definition in FLOWERS:
		var flower_id := str(definition.get("id", ""))
		var gift_id := str(definition.get("gift_id", ""))
		if saved_seeds is Dictionary:
			seeds[flower_id] = maxi(int(saved_seeds.get(flower_id, 0)), 0)
		if saved_flowers is Dictionary:
			flowers[flower_id] = maxi(int(saved_flowers.get(flower_id, 0)), 0)
		if saved_gifts is Dictionary:
			gifts[gift_id] = maxi(int(saved_gifts.get(gift_id, 0)), 0)
	var saved_plots = snapshot.get("plots", [])
	if saved_plots is Array:
		for plot_index in range(mini(saved_plots.size(), PLOT_COUNT)):
			var saved_plot = saved_plots[plot_index]
			if not saved_plot is Dictionary:
				continue
			var flower_id := str(saved_plot.get("flower_id", ""))
			if flower_id != "" and not flower_definition(flower_id).is_empty():
				plots[plot_index] = {
					"flower_id": flower_id,
					"planted_at_unix": float(saved_plot.get("planted_at_unix", Time.get_unix_time_from_system())),
				}
	selected_gift = str(snapshot.get("selected_gift", ""))
	if selected_gift != "" and gift_definition(selected_gift).is_empty():
		selected_gift = ""
