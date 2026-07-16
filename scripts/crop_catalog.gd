extends RefCounted
class_name CropCatalog

const CARROT := "carrot"
const PEA := "pea"
const EGGPLANT := "eggplant"
const TOMATO := "tomato"
const BELL_PEPPER := "bell_pepper"
const PUMPKIN := "pumpkin"
const STRAWBERRY := "strawberry"
const SWEET_CORN := "sweet_corn"
const MOON_MUSHROOM := "moon_mushroom"
const MARSHMALLOW := "marshmallow"

const MAINLINE_IDS: Array[String] = [
	CARROT,
	PEA,
	EGGPLANT,
	TOMATO,
	BELL_PEPPER,
	PUMPKIN,
]

const EVENT_IDS: Array[String] = [
	STRAWBERRY,
	SWEET_CORN,
	MOON_MUSHROOM,
	MARSHMALLOW,
]

const ALL_IDS: Array[String] = [
	CARROT,
	PEA,
	EGGPLANT,
	TOMATO,
	BELL_PEPPER,
	PUMPKIN,
	STRAWBERRY,
	SWEET_CORN,
	MOON_MUSHROOM,
	MARSHMALLOW,
]

const DATA := {
	CARROT: {
		"name": "胡萝卜", "short": "胡", "group": "mainline", "grow_seconds": 10.0,
		"seed_color": Color(0.90, 0.62, 0.28), "sell_price": 8, "seed_price": 5,
		"detail": "最早学会种植的基础食材，也是第一次经营订单的核心原料。",
		"source": "完成基础种植教学后获得。",
	},
	PEA: {
		"name": "豌豆", "short": "豆", "group": "mainline", "grow_seconds": 16.0,
		"seed_color": Color(0.44, 0.82, 0.36), "sell_price": 10, "seed_price": 7,
		"detail": "清甜而轻盈的豆类作物，适合制作温和的汤料理。",
		"source": "领取开业包后解锁，可通过溪流筛种或瑞巴斯商店补充。",
	},
	EGGPLANT: {
		"name": "茄子", "short": "茄", "group": "mainline", "grow_seconds": 24.0,
		"seed_color": Color(0.56, 0.34, 0.78), "sell_price": 12, "seed_price": 9,
		"detail": "需要耐心照料的紫色作物，切配后特别适合烧烤。",
		"source": "完成逐风后获得首批种子，随后可在瑞巴斯商店补充。",
	},
	TOMATO: {
		"name": "番茄", "short": "番", "group": "mainline", "grow_seconds": 18.0,
		"seed_color": Color(0.91, 0.26, 0.18), "sell_price": 14, "seed_price": 12,
		"detail": "酸甜多汁的红色作物，既能慢炖成汤，也适合直接炙烤。",
		"source": "第3关通过后获得试种包，并同步加入瑞巴斯商店。",
	},
	BELL_PEPPER: {
		"name": "甜椒", "short": "椒", "group": "mainline", "grow_seconds": 20.0,
		"seed_color": Color(0.86, 0.22, 0.16), "sell_price": 15, "seed_price": 15,
		"detail": "颜色明亮、口感清脆的作物，是招牌夜市的重要食材。",
		"source": "第4关通过后可在标记树上找到首批种子。",
	},
	PUMPKIN: {
		"name": "南瓜", "short": "南", "group": "mainline", "grow_seconds": 28.0,
		"seed_color": Color(0.92, 0.48, 0.10), "sell_price": 18, "seed_price": 18,
		"detail": "沉甸甸的秋收作物，能制作浓汤与炙烤料理。",
		"source": "第4关通过后由旅人诺亚带来，随后可在商店补充。",
	},
	STRAWBERRY: {
		"name": "草莓", "short": "莓", "group": "event", "grow_seconds": 14.0,
		"seed_color": Color(0.95, 0.30, 0.42), "sell_price": 28, "seed_price": 42,
		"detail": "兔子们珍藏的酸甜果实，带着灯笼聚会的温暖香气。",
		"source": "通过东南兔子灯笼聚会后首次获得。",
	},
	SWEET_CORN: {
		"name": "甜玉米", "short": "玉", "group": "event", "grow_seconds": 22.0,
		"seed_color": Color(0.95, 0.78, 0.24), "sell_price": 30, "seed_price": 46,
		"detail": "候鸟带来的金黄谷物，颗粒饱满并带有淡淡甜香。",
		"source": "通过候鸟谷物集市后首次获得。",
	},
	MOON_MUSHROOM: {
		"name": "月光蘑菇", "short": "菇", "group": "event", "grow_seconds": 26.0,
		"seed_color": Color(0.48, 0.72, 0.92), "sell_price": 36, "seed_price": 54,
		"detail": "生长在林荫中的发光菌菇，夜晚会泛起柔和蓝光。",
		"source": "通过林荫树精菌市后首次获得。",
	},
	MARSHMALLOW: {
		"name": "棉花糖", "short": "糖", "group": "event", "grow_seconds": 18.0,
		"seed_color": Color(1.0, 0.74, 0.90), "sell_price": 42, "seed_price": 62,
		"detail": "篝火边才会显露来历的奇妙作物，成熟后像云朵一样轻软。",
		"source": "通过湖畔篝火故事会后首次获得。",
	},
}


static func has(crop_id: String) -> bool:
	return DATA.has(crop_id)


static func get_data(crop_id: String) -> Dictionary:
	return (DATA.get(crop_id, DATA[CARROT]) as Dictionary).duplicate(true)


static func display_name(crop_id: String) -> String:
	return str((DATA.get(crop_id, DATA[CARROT]) as Dictionary).get("name", "胡萝卜"))


static func short_name(crop_id: String) -> String:
	return str((DATA.get(crop_id, DATA[CARROT]) as Dictionary).get("short", "胡"))


static func is_event_crop(crop_id: String) -> bool:
	return crop_id in EVENT_IDS


static func grow_seconds(crop_id: String) -> float:
	return float((DATA.get(crop_id, DATA[CARROT]) as Dictionary).get("grow_seconds", 10.0))


static func seed_color(crop_id: String) -> Color:
	return (DATA.get(crop_id, DATA[CARROT]) as Dictionary).get("seed_color", Color(0.90, 0.62, 0.28)) as Color


static func sell_price(crop_id: String) -> int:
	return int((DATA.get(crop_id, DATA[CARROT]) as Dictionary).get("sell_price", 8))


static func seed_price(crop_id: String) -> int:
	return int((DATA.get(crop_id, DATA[CARROT]) as Dictionary).get("seed_price", 5))

