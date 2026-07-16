extends RefCounted
class_name DuelRules

const PROTOCOL_VERSION := 1
const MATCH_DURATION := 120.0
const COUNTDOWN_DURATION := 3.0
const RECONNECT_GRACE := 15.0
const REMATCH_WINDOW := 20.0
const READY_TIMEOUT := 30.0
const ORDER_LIFETIME := 45.0
const ORDER_ARRIVALS := [0.0, 15.0, 30.0, 45.0, 60.0, 75.0, 90.0]
const WASH_DURATION := 2.0
const CUT_DURATION := 2.0
const POT_DURATION := 10.0
const GRILL_DURATION := 12.0
const READY_DURATION := 8.0
const STOCK_MAX := 2
const STOCK_REFILL_SECONDS := 4.0
const MOVE_SPEED := 5.2
const INTERACT_RADIUS := 2.15
const SNAPSHOT_RATE := 10.0
const SERVER_TICK_RATE := 20.0

const CROPS := ["carrot", "pea", "eggplant", "bell_pepper", "tomato", "pumpkin"]
const CROP_NAMES := {
	"carrot": "胡萝卜",
	"pea": "豌豆",
	"eggplant": "茄子",
	"bell_pepper": "彩椒",
	"tomato": "番茄",
	"pumpkin": "南瓜",
}

# 联机竞技规则的独立快照；不依赖单人世界的私有常量和存档数据。
const RECIPES := {
	"carrot_soup": {"name": "胡萝卜清汤", "price": 18, "crop": "carrot", "station": "pot", "needs_cut": false},
	"grilled_carrot": {"name": "烤胡萝卜", "price": 22, "crop": "carrot", "station": "grill", "needs_cut": false},
	"pea_soup": {"name": "豌豆奶油汤", "price": 25, "crop": "pea", "station": "pot", "needs_cut": false},
	"eggplant_grill": {"name": "炙烤茄子", "price": 29, "crop": "eggplant", "station": "grill", "needs_cut": true},
	"pepper_skewers": {"name": "彩椒丰收串", "price": 34, "crop": "bell_pepper", "station": "grill", "needs_cut": true},
	"pepper_soup": {"name": "甜椒暖汤", "price": 32, "crop": "bell_pepper", "station": "pot", "needs_cut": true},
	"tomato_stew": {"name": "番茄慢炖", "price": 31, "crop": "tomato", "station": "pot", "needs_cut": true},
	"tomato_roast": {"name": "炙烤番茄", "price": 33, "crop": "tomato", "station": "grill", "needs_cut": true},
	"pumpkin_potage": {"name": "南瓜浓汤", "price": 38, "crop": "pumpkin", "station": "pot", "needs_cut": true},
	"pumpkin_roast": {"name": "香烤南瓜", "price": 40, "crop": "pumpkin", "station": "grill", "needs_cut": true},
}

const EQUIPMENT_PATHS := {
	"sink": "res://3d建模/设备/洗菜池.glb",
	"cutting_table": "res://3d建模/设备/切菜桌.glb",
	"pot": "res://3d建模/设备/煮锅.glb",
	"grill": "res://3d建模/设备/烧烤架.glb",
	"prep_shelf": "res://3d建模/设备/备菜架.glb",
}

const EQUIPMENT_NAMES := {
	"sink": "洗菜池",
	"cutting_table": "料理台",
	"pot": "煮锅",
	"grill": "烧烤架",
	"prep_shelf": "备菜架",
}

static func crop_name(crop: String) -> String:
	return str(CROP_NAMES.get(crop, crop))

static func recipe_name(recipe: String) -> String:
	return str(RECIPES.get(recipe, {}).get("name", recipe))

static func recipe_for(crop: String, station: String) -> String:
	for recipe_id in RECIPES.keys():
		var data: Dictionary = RECIPES[recipe_id]
		if str(data.get("crop", "")) == crop and str(data.get("station", "")) == station:
			return str(recipe_id)
	return ""

static func crop_needs_cut(crop: String) -> bool:
	for data_variant in RECIPES.values():
		var data: Dictionary = data_variant
		if str(data.get("crop", "")) == crop:
			return bool(data.get("needs_cut", false))
	return false

static func score_for(recipe: String, remaining: float) -> int:
	var data: Dictionary = RECIPES.get(recipe, {})
	return int(data.get("price", 0)) * 10 + clampi(int(floor(remaining)), 0, 30)

static func create_orders(seed_value: int) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var pot_pool: Array = []
	var grill_pool: Array = []
	for recipe_id in RECIPES.keys():
		var data: Dictionary = RECIPES[recipe_id]
		if str(data.get("station", "")) == "pot":
			pot_pool.append(str(recipe_id))
		else:
			grill_pool.append(str(recipe_id))
	_shuffle_with_rng(pot_pool, rng)
	_shuffle_with_rng(grill_pool, rng)
	var first_station := "pot" if rng.randi_range(0, 1) == 0 else "grill"
	var selected: Array[String] = []
	var pot_index := 0
	var grill_index := 0
	for index in range(ORDER_ARRIVALS.size()):
		var station := first_station if index % 2 == 0 else ("grill" if first_station == "pot" else "pot")
		var pool: Array = pot_pool if station == "pot" else grill_pool
		var pool_index := pot_index if station == "pot" else grill_index
		var recipe := str(pool[pool_index % pool.size()])
		if not selected.is_empty() and _recipe_crop(recipe) == _recipe_crop(selected[-1]):
			for offset in range(1, pool.size()):
				var candidate_index := (pool_index + offset) % pool.size()
				var candidate := str(pool[candidate_index])
				if _recipe_crop(candidate) != _recipe_crop(selected[-1]):
					pool[candidate_index] = recipe
					pool[pool_index % pool.size()] = candidate
					recipe = candidate
					break
		selected.append(recipe)
		if station == "pot":
			pot_index += 1
		else:
			grill_index += 1
	var orders: Array[Dictionary] = []
	for index in range(selected.size()):
		orders.append({
			"id": index + 1,
			"recipe": selected[index],
			"arrival": float(ORDER_ARRIVALS[index]),
			"deadline": float(ORDER_ARRIVALS[index]) + ORDER_LIFETIME,
			"status": "upcoming",
		})
	return orders

static func station_positions(slot: int) -> Dictionary:
	var side := -1.0 if slot == 0 else 1.0
	return {
		"sink": Vector2(8.5 * side, -5.4),
		"cutting_table": Vector2(8.5 * side, -1.8),
		"pot": Vector2(8.5 * side, 2.3),
		"grill": Vector2(5.4 * side, 2.3),
		"prep_shelf": Vector2(5.4 * side, -1.8),
	}

static func stock_positions() -> Dictionary:
	return {
		"carrot": Vector2(0.0, -7.5),
		"pea": Vector2(0.0, -4.5),
		"eggplant": Vector2(0.0, -1.5),
		"bell_pepper": Vector2(0.0, 1.5),
		"tomato": Vector2(0.0, 4.5),
		"pumpkin": Vector2(0.0, 7.5),
	}

static func lane_clamp(position: Vector2, slot: int) -> Vector2:
	position.x = clampf(position.x, -12.0, 1.6) if slot == 0 else clampf(position.x, -1.6, 12.0)
	position.y = clampf(position.y, -9.5, 9.5)
	return position

static func _recipe_crop(recipe: String) -> String:
	return str(RECIPES.get(recipe, {}).get("crop", ""))

static func _shuffle_with_rng(values: Array, rng: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var temporary = values[index]
		values[index] = values[swap_index]
		values[swap_index] = temporary
