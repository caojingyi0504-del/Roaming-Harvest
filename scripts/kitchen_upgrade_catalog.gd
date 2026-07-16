extends RefCounted
class_name KitchenUpgradeCatalog

## 房车设备与村落改造的只读目录及纯计算辅助。
##
## 购买状态约定：
## - 设备功能改造：{equipment_id: {upgrade_id: true}}
## - 村落改造：{project_id: true}
##
## effects 约定：
## - multipliers：同名数值相乘，默认 1.0。
## - additions：同名数值相加，默认 0.0。
## - chances：同名概率按独立事件合并，结果为 1 - ∏(1 - p)。
## - flags：同名布尔值执行逻辑或。

const QUANTITY_LEVEL_MIN := 1
const QUANTITY_LEVEL_MAX := 5

const FUNCTIONAL_UPGRADE_PRICES: Array[int] = [
	500,
	800,
	1200,
	1800,
	2600,
	3800,
	5500,
	8000,
]

const QUANTITY_UPGRADE_COSTS := {
	1: 500,
	2: 1800,
	3: 4200,
	4: 8000,
}

const EQUIPMENT_ORDER: Array[String] = [
	"sink",
	"cutting_table",
	"pot",
	"grill",
	"prep_shelf",
]

const EQUIPMENT_CATALOG := {
	"sink": {
		"display_name": "洗菜池",
		"upgrades": [
			{
				"id": "high_pressure_nozzle",
				"display_name": "高压喷头",
				"price": 500,
				"description": "清洗时间缩短 10%。",
				"effects": {"multipliers": {"wash_duration": 0.90}},
			},
			{
				"id": "dual_pump",
				"display_name": "双路水泵",
				"price": 800,
				"description": "清洗时间再缩短 15%。",
				"effects": {"multipliers": {"wash_duration": 0.85}},
			},
			{
				"id": "fine_filter",
				"display_name": "细滤芯",
				"price": 1200,
				"description": "洗后食材保鲜时间增加 15 秒。",
				"effects": {"additions": {"washed_freshness_seconds": 15.0}},
			},
			{
				"id": "temperature_controlled_sink",
				"display_name": "温控水槽",
				"price": 1800,
				"description": "洗后食材保鲜时间再增加 30 秒。",
				"effects": {"additions": {"washed_freshness_seconds": 30.0}},
			},
			{
				"id": "bubble_wash",
				"display_name": "气泡冲洗",
				"price": 2600,
				"description": "清洗完成时有 20% 概率使食材品质 +1。",
				"effects": {"chances": {"washed_quality_up": 0.20}},
			},
			{
				"id": "polish_sterilizer",
				"display_name": "光洁杀菌",
				"price": 3800,
				"description": "清洗完成后食材品质固定 +1。",
				"effects": {"additions": {"washed_quality": 1.0}},
			},
			{
				"id": "sensor_pickup",
				"display_name": "感应取物",
				"price": 5500,
				"description": "玩家双手为空时自动收取完成的食材。",
				"effects": {"flags": {"auto_collect_if_hands_empty": true}},
			},
			{
				"id": "water_recycling_system",
				"display_name": "循环净水系统",
				"price": 8000,
				"description": "清洗时间再缩短 25%，需要清洗的订单时限增加 6 秒。",
				"effects": {
					"multipliers": {"wash_duration": 0.75},
					"additions": {"washed_recipe_order_seconds": 6.0},
				},
			},
		],
	},
	"cutting_table": {
		"display_name": "简易料理台",
		"upgrades": [
			{
				"id": "non_slip_cutting_board",
				"display_name": "防滑砧板",
				"price": 500,
				"description": "切配时间缩短 10%。",
				"effects": {"multipliers": {"cut_duration": 0.90}},
			},
			{
				"id": "sharp_knife_set",
				"display_name": "锋利刀组",
				"price": 800,
				"description": "切配时间再缩短 15%。",
				"effects": {"multipliers": {"cut_duration": 0.85}},
			},
			{
				"id": "freshness_tray",
				"display_name": "锁鲜托盘",
				"price": 1200,
				"description": "切配后食材保鲜时间增加 15 秒。",
				"effects": {"additions": {"cut_freshness_seconds": 15.0}},
			},
			{
				"id": "precision_scale_marks",
				"display_name": "精准刻度",
				"price": 1800,
				"description": "切配完成时有 20% 概率使食材品质 +1。",
				"effects": {"chances": {"cut_quality_up": 0.20}},
			},
			{
				"id": "weighing_module",
				"display_name": "称重模块",
				"price": 2600,
				"description": "切配完成后食材品质固定 +1。",
				"effects": {"additions": {"cut_quality": 1.0}},
			},
			{
				"id": "spice_drawer",
				"display_name": "香料抽屉",
				"price": 3800,
				"description": "需要切配的料理售价提高 8%。",
				"effects": {"multipliers": {"cut_recipe_price": 1.08}},
			},
			{
				"id": "automatic_slicer",
				"display_name": "自动切片机",
				"price": 5500,
				"description": "切配时间再缩短 25%。",
				"effects": {"multipliers": {"cut_duration": 0.75}},
			},
			{
				"id": "chef_prep_table",
				"display_name": "主厨料理台",
				"price": 8000,
				"description": "需要切配的订单时限增加 6 秒，售价再提高 12%。",
				"effects": {
					"multipliers": {"cut_recipe_price": 1.12},
					"additions": {"cut_recipe_order_seconds": 6.0},
				},
			},
		],
	},
	"pot": {
		"display_name": "煮锅",
		"upgrades": [
			{
				"id": "thickened_pot_base",
				"display_name": "加厚锅底",
				"price": 500,
				"description": "烹煮时间缩短 8%。",
				"effects": {"multipliers": {"pot_cook_duration": 0.92}},
			},
			{
				"id": "energy_saving_burner",
				"display_name": "聚能炉芯",
				"price": 800,
				"description": "烹煮时间再缩短 12%。",
				"effects": {"multipliers": {"pot_cook_duration": 0.88}},
			},
			{
				"id": "pressure_lid",
				"display_name": "压力锅盖",
				"price": 1200,
				"description": "烹煮时间再缩短 10%。",
				"effects": {"multipliers": {"pot_cook_duration": 0.90}},
			},
			{
				"id": "temperature_gauge",
				"display_name": "温度表",
				"price": 1800,
				"description": "煮锅火候游标速度降低 15%。",
				"effects": {"multipliers": {"pot_heat_cursor_speed": 0.85}},
			},
			{
				"id": "precision_valve",
				"display_name": "精准阀门",
				"price": 2600,
				"description": "煮锅绿色火候区扩大。",
				"effects": {"additions": {"pot_green_zone_width": 0.12}},
			},
			{
				"id": "overflow_guard",
				"display_name": "防溢边圈",
				"price": 3800,
				"description": "煮锅完成后的可领取停留时间增加 5 秒。",
				"effects": {"additions": {"pot_ready_hold_seconds": 5.0}},
			},
			{
				"id": "ceramic_liner",
				"display_name": "陶瓷内胆",
				"price": 5500,
				"description": "煮锅烧焦缓冲时间增加 8 秒。",
				"effects": {"additions": {"pot_burn_grace_seconds": 8.0}},
			},
			{
				"id": "golden_soup_stove",
				"display_name": "金汤炉组",
				"price": 8000,
				"description": "汤类售价提高 20%，绿色火候完成时品质 +1。",
				"effects": {
					"multipliers": {"soup_recipe_price": 1.20},
					"additions": {"pot_green_heat_quality": 1.0},
				},
			},
		],
	},
	"grill": {
		"display_name": "烧烤架",
		"upgrades": [
			{
				"id": "dense_grill_grate",
				"display_name": "密纹烤网",
				"price": 500,
				"description": "烧烤时间缩短 8%。",
				"effects": {"multipliers": {"grill_cook_duration": 0.92}},
			},
			{
				"id": "air_damper",
				"display_name": "鼓风风门",
				"price": 800,
				"description": "烧烤时间再缩短 12%。",
				"effects": {"multipliers": {"grill_cook_duration": 0.88}},
			},
			{
				"id": "heat_shield",
				"display_name": "隔热挡板",
				"price": 1200,
				"description": "烧烤烧焦缓冲时间增加 4 秒。",
				"effects": {"additions": {"grill_burn_grace_seconds": 4.0}},
			},
			{
				"id": "branding_plate",
				"display_name": "烙纹铁板",
				"price": 1800,
				"description": "烧烤料理售价提高 8%。",
				"effects": {"multipliers": {"grill_recipe_price": 1.08}},
			},
			{
				"id": "dual_zone_firebed",
				"display_name": "双区火床",
				"price": 2600,
				"description": "烧烤架绿色火候区扩大。",
				"effects": {"additions": {"grill_green_zone_width": 0.12}},
			},
			{
				"id": "drip_tray",
				"display_name": "接油托盘",
				"price": 3800,
				"description": "烧烤完成后的可领取停留时间增加 5 秒。",
				"effects": {"additions": {"grill_ready_hold_seconds": 5.0}},
			},
			{
				"id": "smoke_hood",
				"display_name": "排烟罩",
				"price": 5500,
				"description": "烧焦缓冲时间再增加 8 秒，火候游标速度降低 10%。",
				"effects": {
					"multipliers": {"grill_heat_cursor_speed": 0.90},
					"additions": {"grill_burn_grace_seconds": 8.0},
				},
			},
			{
				"id": "festival_grill",
				"display_name": "节庆烤炉",
				"price": 8000,
				"description": "烧烤料理售价提高 20%，绿色火候完成时品质 +1。",
				"effects": {
					"multipliers": {"grill_recipe_price": 1.20},
					"additions": {"grill_green_heat_quality": 1.0},
				},
			},
		],
	},
	"prep_shelf": {
		"display_name": "备菜架",
		"upgrades": [
			{
				"id": "service_bell",
				"display_name": "出餐铃",
				"price": 500,
				"description": "所有订单时限增加 2 秒。",
				"effects": {"additions": {"all_order_seconds": 2.0}},
			},
			{
				"id": "numbered_trays",
				"display_name": "编号托盘",
				"price": 800,
				"description": "所有订单时限再增加 3 秒。",
				"effects": {"additions": {"all_order_seconds": 3.0}},
			},
			{
				"id": "warming_cover",
				"display_name": "保温罩",
				"price": 1200,
				"description": "通过备菜架出餐的售价提高 3%。",
				"effects": {"multipliers": {"served_recipe_price": 1.03}},
			},
			{
				"id": "plating_flower_rack",
				"display_name": "摆盘花架",
				"price": 1800,
				"description": "出餐时有 20% 概率使料理品质 +1。",
				"effects": {"chances": {"served_quality_up": 0.20}},
			},
			{
				"id": "express_lane",
				"display_name": "快速通道",
				"price": 2600,
				"description": "完成紧急订单时额外获得 8 金币。",
				"effects": {"additions": {"urgent_order_coins": 8.0}},
			},
			{
				"id": "tip_box",
				"display_name": "小费匣",
				"price": 3800,
				"description": "每完成一单额外获得 5 金币。",
				"effects": {"additions": {"completed_order_coins": 5.0}},
			},
			{
				"id": "service_board",
				"display_name": "服务看板",
				"price": 5500,
				"description": "连续出餐每单额外 +3 金币，最高 +15；漏单后清零。",
				"effects": {
					"additions": {
						"service_combo_coins_per_order": 3.0,
						"service_combo_coins_cap": 15.0,
					},
					"flags": {"reset_service_combo_on_miss": true},
				},
			},
			{
				"id": "festival_service_counter",
				"display_name": "节庆出餐台",
				"price": 8000,
				"description": "全部订单售价提高 15%。",
				"effects": {"multipliers": {"all_order_price": 1.15}},
			},
		],
	},
}

const VILLAGE_PROJECT_ORDER: Array[String] = [
	"roadside_flowerbeds",
	"public_well",
	"market_canopy",
	"stone_village_road",
	"public_storehouse",
	"seed_sifting_windmill",
	"village_public_kitchen",
	"harvest_festival_square",
]

const VILLAGE_PROJECTS := {
	"roadside_flowerbeds": {
		"id": "roadside_flowerbeds",
		"display_name": "路边花圃",
		"price": 500,
		"description": "野外种子掉落频率提高 5%，村路旁增加花坛。",
		"visual_key": "flowerbeds",
		"effects": {"multipliers": {"wild_seed_drop_frequency": 1.05}},
	},
	"public_well": {
		"id": "public_well",
		"display_name": "公共水井",
		"price": 800,
		"description": "水壶补水速度提高 25%，村中增加石井与木架。",
		"visual_key": "public_well",
		"effects": {"multipliers": {"watering_can_refill_speed": 1.25}},
	},
	"market_canopy": {
		"id": "market_canopy",
		"display_name": "集市棚架",
		"price": 1200,
		"description": "瑞巴斯商店每项库存增加 2，商店旁增加市场遮棚。",
		"visual_key": "market_canopy",
		"effects": {"additions": {"rebas_shop_stock_per_item": 2.0}},
	},
	"stone_village_road": {
		"id": "stone_village_road",
		"display_name": "石板村道",
		"price": 1800,
		"description": "玩家移动速度提高 8%，村落道路铺设石板。",
		"visual_key": "stone_roads",
		"effects": {"multipliers": {"player_move_speed": 1.08}},
	},
	"public_storehouse": {
		"id": "public_storehouse",
		"display_name": "公共储藏屋",
		"price": 2600,
		"description": "食材出售价格提高 10%，村中增加储藏棚与木箱。",
		"visual_key": "storehouse",
		"effects": {"multipliers": {"stored_crop_sell_price": 1.10}},
	},
	"seed_sifting_windmill": {
		"id": "seed_sifting_windmill",
		"display_name": "筛种风车",
		"price": 3800,
		"description": "每日筛种奖励增加 1，村中增加木风车。",
		"visual_key": "sifting_windmill",
		"effects": {"additions": {"daily_seed_sifting_reward": 1.0}},
	},
	"village_public_kitchen": {
		"id": "village_public_kitchen",
		"display_name": "村落公共厨房",
		"price": 5500,
		"description": "所有料理基础售价提高 10%，村中增加厨房凉棚。",
		"visual_key": "public_kitchen",
		"effects": {"multipliers": {"base_recipe_price": 1.10}},
	},
	"harvest_festival_square": {
		"id": "harvest_festival_square",
		"display_name": "丰收节广场",
		"price": 8000,
		"description": "经营关卡首通人气奖励提高 20%，增加灯串、旗帜与拱门。",
		"visual_key": "festival_square",
		"effects": {"multipliers": {"first_clear_popularity_reward": 1.20}},
	},
}


static func get_equipment_ids() -> Array[String]:
	return EQUIPMENT_ORDER.duplicate()


static func get_equipment(equipment_id: String) -> Dictionary:
	var definition: Dictionary = EQUIPMENT_CATALOG.get(equipment_id, {})
	return definition.duplicate(true)


static func get_equipment_display_name(equipment_id: String) -> String:
	return str(EQUIPMENT_CATALOG.get(equipment_id, {}).get("display_name", ""))


static func get_equipment_upgrades(equipment_id: String) -> Array:
	var definition: Dictionary = EQUIPMENT_CATALOG.get(equipment_id, {})
	var upgrades: Array = definition.get("upgrades", [])
	return upgrades.duplicate(true)


static func get_equipment_upgrade(equipment_id: String, upgrade_id: String) -> Dictionary:
	for upgrade_variant in get_equipment_upgrades(equipment_id):
		var upgrade: Dictionary = upgrade_variant
		if str(upgrade.get("id", "")) == upgrade_id:
			return upgrade
	return {}


static func get_equipment_upgrade_at(equipment_id: String, index: int) -> Dictionary:
	var upgrades := get_equipment_upgrades(equipment_id)
	if index < 0 or index >= upgrades.size():
		return {}
	return upgrades[index]


static func get_village_project_ids() -> Array[String]:
	return VILLAGE_PROJECT_ORDER.duplicate()


static func get_village_projects() -> Array:
	var projects: Array = []
	for project_id in VILLAGE_PROJECT_ORDER:
		projects.append(get_village_project(project_id))
	return projects


static func get_village_project(project_id: String) -> Dictionary:
	var project: Dictionary = VILLAGE_PROJECTS.get(project_id, {})
	return project.duplicate(true)


static func clamp_quantity_level(level: int) -> int:
	return clampi(level, QUANTITY_LEVEL_MIN, QUANTITY_LEVEL_MAX)


static func get_quantity_limit(level: int) -> int:
	return clamp_quantity_level(level)


static func get_quantity_upgrade_cost(current_level: int) -> int:
	if current_level < QUANTITY_LEVEL_MIN or current_level >= QUANTITY_LEVEL_MAX:
		return -1
	return int(QUANTITY_UPGRADE_COSTS.get(current_level, -1))


static func validate_quantity_purchase(
	equipment_id: String,
	current_level: int,
	coins: int,
	equipment_unlocked: bool = true,
	use_cutting_table_lv2_ticket: bool = false
) -> Dictionary:
	if not EQUIPMENT_CATALOG.has(equipment_id):
		return _purchase_result(false, "unknown_equipment", -1)
	if not equipment_unlocked:
		return _purchase_result(false, "equipment_locked", -1)
	if current_level < QUANTITY_LEVEL_MIN or current_level > QUANTITY_LEVEL_MAX:
		return _purchase_result(false, "invalid_quantity_level", -1)
	if current_level >= QUANTITY_LEVEL_MAX:
		return _purchase_result(false, "quantity_level_maxed", -1)
	var ticket_applies := (
		use_cutting_table_lv2_ticket
		and equipment_id == "cutting_table"
		and current_level == 1
	)
	var cost := 0 if ticket_applies else get_quantity_upgrade_cost(current_level)
	if coins < cost:
		return _purchase_result(false, "insufficient_coins", cost, ticket_applies)
	return _purchase_result(true, "", cost, ticket_applies)


static func validate_equipment_upgrade_purchase(
	equipment_id: String,
	upgrade_id: String,
	owned: Dictionary,
	coins: int,
	equipment_unlocked: bool = true,
	use_upgrade_material: bool = false
) -> Dictionary:
	if not EQUIPMENT_CATALOG.has(equipment_id):
		return _purchase_result(false, "unknown_equipment", -1)
	if not equipment_unlocked:
		return _purchase_result(false, "equipment_locked", -1)
	var upgrade := get_equipment_upgrade(equipment_id, upgrade_id)
	if upgrade.is_empty():
		return _purchase_result(false, "unknown_upgrade", -1)
	if is_equipment_upgrade_owned(owned, equipment_id, upgrade_id):
		return _purchase_result(false, "already_owned", int(upgrade.get("price", -1)))
	var listed_price := int(upgrade.get("price", -1))
	var material_applies := use_upgrade_material and listed_price <= 1200
	var cost := 0 if material_applies else listed_price
	if coins < cost:
		return _purchase_result(false, "insufficient_coins", cost, material_applies)
	return _purchase_result(true, "", cost, material_applies)


static func validate_village_project_purchase(
	project_id: String,
	owned: Dictionary,
	coins: int
) -> Dictionary:
	var project := get_village_project(project_id)
	if project.is_empty():
		return _purchase_result(false, "unknown_village_project", -1)
	var price := int(project.get("price", -1))
	if is_village_project_owned(owned, project_id):
		return _purchase_result(false, "already_owned", price)
	if coins < price:
		return _purchase_result(false, "insufficient_coins", price)
	return _purchase_result(true, "", price)


static func is_equipment_upgrade_owned(
	owned: Dictionary,
	equipment_id: String,
	upgrade_id: String
) -> bool:
	var equipment_owned_variant: Variant = owned.get(equipment_id, {})
	if not equipment_owned_variant is Dictionary:
		return false
	var equipment_owned: Dictionary = equipment_owned_variant
	return bool(equipment_owned.get(upgrade_id, false))


static func is_village_project_owned(owned: Dictionary, project_id: String) -> bool:
	return bool(owned.get(project_id, false))


static func aggregate_equipment_effects(equipment_id: String, owned: Dictionary) -> Dictionary:
	if not EQUIPMENT_CATALOG.has(equipment_id):
		return _empty_effects()
	var selected_effects: Array[Dictionary] = []
	for upgrade_variant in get_equipment_upgrades(equipment_id):
		var upgrade: Dictionary = upgrade_variant
		var upgrade_id := str(upgrade.get("id", ""))
		if is_equipment_upgrade_owned(owned, equipment_id, upgrade_id):
			selected_effects.append(upgrade.get("effects", {}))
	return _aggregate_effect_list(selected_effects)


static func aggregate_village_effects(owned: Dictionary) -> Dictionary:
	var selected_effects: Array[Dictionary] = []
	for project_id in VILLAGE_PROJECT_ORDER:
		if is_village_project_owned(owned, project_id):
			selected_effects.append(VILLAGE_PROJECTS[project_id].get("effects", {}))
	return _aggregate_effect_list(selected_effects)


static func get_equipment_effect_multiplier(
	equipment_id: String,
	owned: Dictionary,
	effect_key: String,
	base_value: float = 1.0
) -> float:
	var effects := aggregate_equipment_effects(equipment_id, owned)
	return base_value * float(effects["multipliers"].get(effect_key, 1.0))


static func get_equipment_effect_addition(
	equipment_id: String,
	owned: Dictionary,
	effect_key: String,
	base_value: float = 0.0
) -> float:
	var effects := aggregate_equipment_effects(equipment_id, owned)
	return base_value + float(effects["additions"].get(effect_key, 0.0))


static func get_equipment_effect_chance(
	equipment_id: String,
	owned: Dictionary,
	effect_key: String
) -> float:
	var effects := aggregate_equipment_effects(equipment_id, owned)
	return float(effects["chances"].get(effect_key, 0.0))


static func has_equipment_effect_flag(
	equipment_id: String,
	owned: Dictionary,
	effect_key: String
) -> bool:
	var effects := aggregate_equipment_effects(equipment_id, owned)
	return bool(effects["flags"].get(effect_key, false))


static func get_village_effect_multiplier(
	owned: Dictionary,
	effect_key: String,
	base_value: float = 1.0
) -> float:
	var effects := aggregate_village_effects(owned)
	return base_value * float(effects["multipliers"].get(effect_key, 1.0))


static func get_village_effect_addition(
	owned: Dictionary,
	effect_key: String,
	base_value: float = 0.0
) -> float:
	var effects := aggregate_village_effects(owned)
	return base_value + float(effects["additions"].get(effect_key, 0.0))


static func get_village_effect_chance(
	owned: Dictionary,
	effect_key: String
) -> float:
	var effects := aggregate_village_effects(owned)
	return float(effects["chances"].get(effect_key, 0.0))


static func has_village_effect_flag(
	owned: Dictionary,
	effect_key: String
) -> bool:
	var effects := aggregate_village_effects(owned)
	return bool(effects["flags"].get(effect_key, false))


static func validate_catalog() -> PackedStringArray:
	var errors := PackedStringArray()
	if EQUIPMENT_ORDER.size() != 5:
		errors.append("equipment catalog must contain exactly 5 equipment types")
	for equipment_id in EQUIPMENT_ORDER:
		if not EQUIPMENT_CATALOG.has(equipment_id):
			errors.append("missing equipment: %s" % equipment_id)
			continue
		var upgrades: Array = EQUIPMENT_CATALOG[equipment_id].get("upgrades", [])
		if upgrades.size() != FUNCTIONAL_UPGRADE_PRICES.size():
			errors.append("%s must contain exactly 8 upgrades" % equipment_id)
		var seen_ids := {}
		for index in upgrades.size():
			var upgrade: Dictionary = upgrades[index]
			var upgrade_id := str(upgrade.get("id", ""))
			if upgrade_id.is_empty() or seen_ids.has(upgrade_id):
				errors.append("%s has an empty or duplicate upgrade id: %s" % [equipment_id, upgrade_id])
			seen_ids[upgrade_id] = true
			if index < FUNCTIONAL_UPGRADE_PRICES.size() and int(upgrade.get("price", -1)) != FUNCTIONAL_UPGRADE_PRICES[index]:
				errors.append("%s/%s has an invalid price" % [equipment_id, upgrade_id])
			_validate_effects(upgrade.get("effects", {}), "%s/%s" % [equipment_id, upgrade_id], errors)
	if VILLAGE_PROJECT_ORDER.size() != FUNCTIONAL_UPGRADE_PRICES.size():
		errors.append("village catalog must contain exactly 8 projects")
	var seen_projects := {}
	for index in VILLAGE_PROJECT_ORDER.size():
		var project_id := VILLAGE_PROJECT_ORDER[index]
		if seen_projects.has(project_id) or not VILLAGE_PROJECTS.has(project_id):
			errors.append("missing or duplicate village project: %s" % project_id)
			continue
		seen_projects[project_id] = true
		var project: Dictionary = VILLAGE_PROJECTS[project_id]
		if str(project.get("id", "")) != project_id:
			errors.append("village project key/id mismatch: %s" % project_id)
		if int(project.get("price", -1)) != FUNCTIONAL_UPGRADE_PRICES[index]:
			errors.append("%s has an invalid price" % project_id)
		_validate_effects(project.get("effects", {}), project_id, errors)
	return errors


static func _aggregate_effect_list(effect_list: Array[Dictionary]) -> Dictionary:
	var result := _empty_effects()
	for effects in effect_list:
		var multipliers: Dictionary = effects.get("multipliers", {})
		for key_variant in multipliers:
			var key := str(key_variant)
			result["multipliers"][key] = float(result["multipliers"].get(key, 1.0)) * float(multipliers[key_variant])
		var additions: Dictionary = effects.get("additions", {})
		for key_variant in additions:
			var key := str(key_variant)
			result["additions"][key] = float(result["additions"].get(key, 0.0)) + float(additions[key_variant])
		var chances: Dictionary = effects.get("chances", {})
		for key_variant in chances:
			var key := str(key_variant)
			var old_chance := clampf(float(result["chances"].get(key, 0.0)), 0.0, 1.0)
			var new_chance := clampf(float(chances[key_variant]), 0.0, 1.0)
			result["chances"][key] = 1.0 - (1.0 - old_chance) * (1.0 - new_chance)
		var flags: Dictionary = effects.get("flags", {})
		for key_variant in flags:
			var key := str(key_variant)
			result["flags"][key] = bool(result["flags"].get(key, false)) or bool(flags[key_variant])
	return result


static func _empty_effects() -> Dictionary:
	return {
		"multipliers": {},
		"additions": {},
		"chances": {},
		"flags": {},
	}


static func _purchase_result(
	ok: bool,
	reason: String,
	cost: int,
	uses_free_item: bool = false
) -> Dictionary:
	return {
		"ok": ok,
		"reason": reason,
		"cost": cost,
		"uses_free_item": uses_free_item,
	}


static func _validate_effects(effects: Variant, context: String, errors: PackedStringArray) -> void:
	if not effects is Dictionary:
		errors.append("%s effects must be a dictionary" % context)
		return
	var effect_dictionary: Dictionary = effects
	for group_name in ["multipliers", "additions", "chances", "flags"]:
		if effect_dictionary.has(group_name) and not effect_dictionary[group_name] is Dictionary:
			errors.append("%s/%s must be a dictionary" % [context, group_name])
	var chances: Dictionary = effect_dictionary.get("chances", {})
	for chance_key in chances:
		var chance := float(chances[chance_key])
		if chance < 0.0 or chance > 1.0:
			errors.append("%s chance %s must be between 0 and 1" % [context, chance_key])
