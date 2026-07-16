extends RefCounted
class_name ResearchRecipeCatalog

const STRAWBERRY_JAM := "lantern_strawberry_jam"
const ROASTED_SWEET_CORN := "migratory_roasted_sweet_corn"
const MOON_MUSHROOM_SOUP := "moon_mushroom_soup"
const CAMPFIRE_MARSHMALLOW := "lakeside_campfire_marshmallow"

const ALL_IDS: Array[String] = [
	STRAWBERRY_JAM,
	ROASTED_SWEET_CORN,
	MOON_MUSHROOM_SOUP,
	CAMPFIRE_MARSHMALLOW,
]

const DATA := {
	STRAWBERRY_JAM: {
		"name": "灯笼草莓果酱",
		"event_id": "rabbit_lantern_party",
		"crop": "strawberry",
		"station": "pot",
		"processing_steps": ["pot"],
		"needs_wash": false,
		"needs_cut": false,
		"price": 58,
		"scrap_price": 16,
		"clue_title": "兔灯下的甜香",
		"clue": "灯笼聚会留下的纸条写着：红色果实在温热的锅里会变得香甜浓稠。",
		"wrong_crop_hint": "纸条上的颜色像刚成熟的草莓。",
		"wrong_station_hint": "这份甜香需要慢慢熬煮，不是直接炙烤。",
	},
	ROASTED_SWEET_CORN: {
		"name": "候鸟炙烤甜玉米",
		"event_id": "migratory_bird_market",
		"crop": "sweet_corn",
		"station": "grill",
		"processing_steps": ["grill"],
		"needs_wash": false,
		"needs_cut": false,
		"price": 62,
		"scrap_price": 17,
		"clue_title": "金黄谷物的焦香",
		"clue": "候鸟商贩说，完整的金黄谷物最适合靠近火焰，烤到表面微焦。",
		"wrong_crop_hint": "线索指向候鸟带来的甜玉米。",
		"wrong_station_hint": "这道料理需要明火炙烤，而不是放进汤锅。",
	},
	MOON_MUSHROOM_SOUP: {
		"name": "月光菌菇汤",
		"event_id": "forest_spirit_market",
		"crop": "moon_mushroom",
		"station": "pot",
		"processing_steps": ["cut", "pot"],
		"needs_wash": false,
		"needs_cut": true,
		"price": 72,
		"scrap_price": 20,
		"clue_title": "林荫里的幽蓝汤谱",
		"clue": "树精的纸条画着切开的发光菌菇，旁边是一口冒着柔和蒸汽的锅。",
		"wrong_crop_hint": "幽蓝光点来自月光蘑菇。",
		"wrong_station_hint": "切开的菌菇应该放进煮锅，让香气融进汤里。",
	},
	CAMPFIRE_MARSHMALLOW: {
		"name": "湖畔烤棉花糖",
		"event_id": "lakeside_campfire_story",
		"crop": "marshmallow",
		"station": "grill",
		"processing_steps": ["grill"],
		"needs_wash": false,
		"needs_cut": false,
		"price": 78,
		"scrap_price": 22,
		"clue_title": "篝火边的云朵",
		"clue": "故事会的最后一页画着白色云朵靠近篝火，边缘变成淡淡金色。",
		"wrong_crop_hint": "纸条说的是篝火旁成熟的棉花糖。",
		"wrong_station_hint": "云朵般的食材要靠近火焰轻烤。",
	},
}


static func has(recipe_id: String) -> bool:
	return DATA.has(recipe_id)


static func get_data(recipe_id: String) -> Dictionary:
	return (DATA.get(recipe_id, {}) as Dictionary).duplicate(true)


static func recipe_for_event(event_id: String) -> String:
	for recipe_id in ALL_IDS:
		if str((DATA[recipe_id] as Dictionary).get("event_id", "")) == event_id:
			return recipe_id
	return ""


static func event_for_recipe(recipe_id: String) -> String:
	return str((DATA.get(recipe_id, {}) as Dictionary).get("event_id", ""))
