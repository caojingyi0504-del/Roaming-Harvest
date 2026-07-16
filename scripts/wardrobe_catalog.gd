extends RefCounted
class_name WardrobeCatalog

const DEFAULT_OUTFIT_ID := "default_traveler"

const OUTFITS: Array[Dictionary] = [
	{
		"id": DEFAULT_OUTFIT_ID,
		"display_name": "奶油旅装",
		"price": 0,
		"model_path": "res://assets/wardrobe/models/player_default_optimized.glb",
		"preview_path": "res://assets/wardrobe/concepts/player_master_turnaround.png",
		"description": "一路陪伴你的旧旅装，轻便、耐穿，也最熟悉。",
		"owned_by_default": true,
		"accent": Color("b9aa79"),
	},
	{
		"id": "olive_gardener",
		"display_name": "橄榄园丁服",
		"price": 300,
		"model_path": "res://assets/wardrobe/models/player_olive_gardener.glb",
		"preview_path": "res://assets/wardrobe/concepts/olive_gardener_turnaround.png",
		"description": "耐脏的橄榄绿短斗篷与园艺围裙，适合在田间忙上一整天。",
		"owned_by_default": false,
		"accent": Color("7f9468"),
	},
	{
		"id": "terracotta_cook",
		"display_name": "陶土料理服",
		"price": 500,
		"model_path": "res://assets/wardrobe/models/player_terracotta_cook.glb",
		"preview_path": "res://assets/wardrobe/concepts/terracotta_cook_turnaround.png",
		"description": "米白料理外套配陶土红领巾，在热气腾腾的灶台前也很醒目。",
		"owned_by_default": false,
		"accent": Color("b87355"),
	},
	{
		"id": "mist_lakeside",
		"display_name": "雾蓝湖畔采集服",
		"price": 800,
		"model_path": "res://assets/wardrobe/models/player_mist_lakeside.glb",
		"preview_path": "res://assets/wardrobe/concepts/mist_lakeside_turnaround.png",
		"description": "雾蓝防风披肩与防水短靴，带着清晨湖面的安静气息。",
		"owned_by_default": false,
		"accent": Color("7e9ca3"),
	},
	{
		"id": "old_road_traveler",
		"display_name": "旧木远行服",
		"price": 1200,
		"model_path": "res://assets/wardrobe/models/player_old_road_traveler.glb",
		"preview_path": "res://assets/wardrobe/concepts/old_road_traveler_turnaround.png",
		"description": "带补丁的旧木色长外套和轻旅行包，为下一段公路准备。",
		"owned_by_default": false,
		"accent": Color("826c56"),
	},
]

static func all() -> Array[Dictionary]:
	return OUTFITS.duplicate(true)

static func get_outfit(outfit_id: String) -> Dictionary:
	for outfit in OUTFITS:
		if str(outfit.get("id", "")) == outfit_id:
			return outfit.duplicate(true)
	return {}

static func has_outfit(outfit_id: String) -> bool:
	return not get_outfit(outfit_id).is_empty()

static func model_is_available(outfit_id: String) -> bool:
	var outfit := get_outfit(outfit_id)
	if outfit.is_empty():
		return false
	return ResourceLoader.exists(str(outfit.get("model_path", "")), "PackedScene")

static func default_owned_ids() -> Array[String]:
	var result: Array[String] = []
	for outfit in OUTFITS:
		if bool(outfit.get("owned_by_default", false)):
			result.append(str(outfit.get("id", "")))
	if not result.has(DEFAULT_OUTFIT_ID):
		result.push_front(DEFAULT_OUTFIT_ID)
	return result
