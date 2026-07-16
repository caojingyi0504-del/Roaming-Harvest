extends RefCounted
class_name BusinessProgressionCatalog

const LEVELS := [
	{"id": 1, "name": "第1关 试营业", "orders": 3, "duration": 120.0, "requirements": {"carrot": 5}, "clear_requirements": ["准备胡萝卜 x5", "完成1个订单即可通关"], "star_orders": [1, 2, 3], "challenge_time": 105.0, "recipes": ["carrot_soup", "carrot_soup", "carrot_soup"], "popularity": 12},
	{"id": 2, "name": "第2关 午间小摊", "orders": 4, "duration": 110.0, "requirements": {"carrot": 4, "pea": 4}, "clear_requirements": ["准备胡萝卜 x4、豌豆 x4", "完成2个订单即可通关"], "star_orders": [2, 3, 4], "challenge_time": 100.0, "recipes": ["carrot_soup", "grilled_carrot", "pea_soup", "pea_soup"], "popularity": 16},
	{"id": 3, "name": "第3关 晚风订单", "orders": 5, "duration": 108.0, "requirements": {"carrot": 2, "pea": 3, "eggplant": 4}, "clear_requirements": ["准备胡萝卜 x2、豌豆 x3、茄子 x4", "完成2个订单即可通关"], "star_orders": [2, 3, 5], "challenge_time": 100.0, "recipes": ["pea_soup", "eggplant_grill", "carrot_soup", "eggplant_grill", "pea_soup"], "popularity": 22},
	{"id": 4, "name": "第4关 丰收排队", "orders": 6, "duration": 104.0, "requirements": {"carrot": 2, "pea": 2, "eggplant": 2, "tomato": 4}, "clear_requirements": ["准备4种主线作物", "完成2个订单即可通关"], "star_orders": [2, 4, 6], "challenge_time": 98.0, "recipes": ["eggplant_grill", "tomato_stew", "pea_soup", "tomato_roast", "carrot_soup", "tomato_stew"], "popularity": 28},
	{"id": 5, "name": "第5关 招牌夜市", "orders": 7, "duration": 100.0, "requirements": {"carrot": 2, "pea": 2, "eggplant": 2, "tomato": 2, "bell_pepper": 3, "pumpkin": 4}, "clear_requirements": ["准备6种主线作物", "完成3个订单即可通关"], "star_orders": [3, 4, 7], "challenge_time": 96.0, "recipes": ["tomato_stew", "pepper_skewers", "pumpkin_potage", "eggplant_grill", "pepper_soup", "pumpkin_roast", "pea_soup"], "popularity": 55},
]

const ORDINARY_RECIPE_IDS: Array[String] = [
	"carrot_soup",
	"grilled_carrot",
	"pea_soup",
	"eggplant_grill",
	"tomato_stew",
	"tomato_roast",
	"pepper_soup",
	"pepper_skewers",
	"pumpkin_potage",
	"pumpkin_roast",
]
