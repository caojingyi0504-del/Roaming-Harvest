extends RefCounted
class_name LocalEventCatalog

const RABBIT_PARTY := "rabbit_lantern_party"
const BIRD_MARKET := "migratory_bird_market"
const FOREST_MARKET := "forest_spirit_market"
const CAMPFIRE_STORY := "lakeside_campfire_story"

const DAY_IDS: Array[String] = [BIRD_MARKET, FOREST_MARKET]
const NIGHT_IDS: Array[String] = [RABBIT_PARTY, CAMPFIRE_STORY]
const ALL_IDS: Array[String] = [RABBIT_PARTY, BIRD_MARKET, FOREST_MARKET, CAMPFIRE_STORY]

const EVENTS := {
	RABBIT_PARTY: {
		"name": "东南兔子灯笼聚会",
		"short_name": "兔子聚会",
		"phase": "night",
		"position": Vector2(145.0, -130.0),
		"reveal_radius": 22.0,
		"parking_radius": 12.0,
		"preferred_crop": CropCatalog.CARROT,
		"recipes": ["carrot_soup", "grilled_carrot", "carrot_soup", "grilled_carrot"],
		"bonus_multiplier": 1.25,
		"reward_crop": CropCatalog.STRAWBERRY,
		"reward_count": 3,
		"perk_id": "rabbit_regulars",
		"perk_name": "兔子常客",
		"perk_description": "胡萝卜料理售价永久 +3%",
		"unlock_level": 2,
		"direction_hint": "东南方传来了铃铛和欢呼声",
		"approach_hint": "附近传来了兔子的欢呼声，好像正在举办胡萝卜聚会。",
		"asset_path": "res://3d建模/地方事件/兔子灯笼聚会_v1.glb",
	},
	BIRD_MARKET: {
		"name": "候鸟谷物集市",
		"short_name": "候鸟集市",
		"phase": "day",
		"position": Vector2(145.0, 75.0),
		"reveal_radius": 22.0,
		"parking_radius": 12.0,
		"preferred_crop": CropCatalog.PEA,
		"recipes": ["pea_soup", "pea_soup", "pea_soup", "pea_soup"],
		"bonus_multiplier": 1.25,
		"reward_crop": CropCatalog.SWEET_CORN,
		"reward_count": 3,
		"perk_id": "migratory_reputation",
		"perk_name": "候鸟口碑",
		"perk_description": "每天完成的第一单额外获得 5 金币",
		"unlock_level": 3,
		"direction_hint": "东北方出现了临时搭起的谷物旗帜",
		"approach_hint": "附近传来翅膀拍动声，候鸟们似乎正在交换谷物。",
		"asset_path": "res://3d建模/地方事件/候鸟谷物集市_v1.glb",
	},
	FOREST_MARKET: {
		"name": "林荫树精菌市",
		"short_name": "树精菌市",
		"phase": "day",
		"position": Vector2(-145.0, -85.0),
		"reveal_radius": 22.0,
		"parking_radius": 12.0,
		"preferred_crop": CropCatalog.EGGPLANT,
		"recipes": ["eggplant_grill", "eggplant_grill", "eggplant_grill", "eggplant_grill"],
		"bonus_multiplier": 1.25,
		"reward_crop": CropCatalog.MOON_MUSHROOM,
		"reward_count": 2,
		"perk_id": "forest_mycelium",
		"perk_name": "林间菌丝",
		"perk_description": "野外种子掉落率永久 +5%",
		"unlock_level": 3,
		"direction_hint": "西南林荫下亮起了幽蓝色的小灯",
		"approach_hint": "树影里浮着细小光点，似乎有一座临时菌市。",
		"asset_path": "res://3d建模/地方事件/林荫树精菌市_v1.glb",
	},
	CAMPFIRE_STORY: {
		"name": "湖畔篝火故事会",
		"short_name": "篝火故事会",
		"phase": "night",
		"position": Vector2(-105.0, 125.0),
		"reveal_radius": 22.0,
		"parking_radius": 12.0,
		"preferred_crop": CropCatalog.PUMPKIN,
		"recipes": ["pumpkin_potage", "pumpkin_roast", "pumpkin_potage", "pumpkin_roast"],
		"bonus_multiplier": 1.25,
		"reward_crop": CropCatalog.MARSHMALLOW,
		"reward_count": 2,
		"perk_id": "ember_warmth",
		"perk_name": "余烬保温",
		"perk_description": "料理完成后的烧焦缓冲永久增加 2 秒",
		"unlock_level": 4,
		"direction_hint": "西北湖畔升起了一缕温暖的烟",
		"approach_hint": "附近有木柴噼啪作响，好像有人围着篝火讲故事。",
		"asset_path": "res://3d建模/地方事件/湖畔篝火故事会_v1.glb",
	},
}


static func get_event(event_id: String) -> Dictionary:
	return (EVENTS.get(event_id, {}) as Dictionary).duplicate(true)


static func ids_for_phase(phase: String) -> Array[String]:
	return DAY_IDS.duplicate() if phase == "day" else NIGHT_IDS.duplicate()
