extends RefCounted
class_name BusinessDiscoveryCatalog

const STATE_HIDDEN := 0
const STATE_CLUE := 1
const STATE_DISCOVERED := 2
const STATE_REGULAR := 3

const FIRST_DISCOVERY_LEVEL := 2
const LAST_DISCOVERY_LEVEL := 5

const SITES := {
	2: {
		"event_name": "兔子们的野餐邀请",
		"short_name": "兔子野餐",
		"customer_name": "兔子野餐团",
		"position": Vector2(85.0, -68.0),
		"reveal_radius": 22.0,
		"notice_radius": 10.0,
		"interact_radius": 4.2,
		"parking_radius": 12.0,
		"clue": "东南草坡挂起了胡萝卜色的彩旗，沿着兔子脚印去看看。",
		"rumor": "这片草坡上摆着尚未完成的长桌，像是在等待一场聚会。",
		"approach_hint": "附近传来兔子的笑声，似乎有人正在筹备野餐宴会。",
		"invitation": "我们想请房车厨师办一场真正的野餐！先把房车停进彩旗下的空地，再为大家准备午餐吧。",
		"regular_hint": "兔子们已经是老主顾，随时欢迎房车再次开业。",
		"compass_icon": "🥕",
		"asset_path": "res://3d建模/主线委托/兔子野餐邀请_v1.glb",
	},
	3: {
		"event_name": "风车工匠的午餐委托",
		"short_name": "风车午餐",
		"customer_name": "风车工匠",
		"position": Vector2(-75.0, -95.0),
		"reveal_radius": 22.0,
		"notice_radius": 10.0,
		"interact_radius": 4.2,
		"parking_radius": 12.0,
		"clue": "西南风岭传来断断续续的风铃声，旧风车旁似乎有人忙碌。",
		"rumor": "风岭上堆着工具箱和布条，像有一群工匠尚未到齐。",
		"approach_hint": "风铃声越来越清楚，修理风车的工匠正在寻找能供餐的房车。",
		"invitation": "风车修到一半，大家已经饿坏了。把房车停在弯路牌旁，为工匠们准备一顿热饭吧。",
		"regular_hint": "工匠们已经认得这辆房车，会继续带来晚风订单。",
		"compass_icon": "❧",
		"asset_path": "res://3d建模/主线委托/风车工匠午餐_v1.glb",
	},
	4: {
		"event_name": "刺猬园丁的丰收席",
		"short_name": "园丁丰收席",
		"customer_name": "刺猬园丁",
		"position": Vector2(-150.0, 25.0),
		"reveal_radius": 22.0,
		"notice_radius": 10.0,
		"interact_radius": 4.2,
		"parking_radius": 12.0,
		"clue": "西侧藤蔓园出现了番茄花环，园丁们正在搬运空餐桌。",
		"rumor": "藤架下留着一排空木箱，花环拱门还没有挂完。",
		"approach_hint": "藤架后传来推车声，刺猬园丁们似乎在筹备丰收席。",
		"invitation": "今年的第一批番茄值得好好庆祝。请把房车开进藤架外的空地，为园丁们办一场丰收席。",
		"regular_hint": "刺猬园丁已经成为老主顾，丰收排队会持续开放。",
		"compass_icon": "🍅",
		"asset_path": "res://3d建模/主线委托/刺猬园丁丰收席_v1.glb",
	},
	5: {
		"event_name": "湖畔旅团的招牌夜宴",
		"short_name": "旅团夜宴",
		"customer_name": "湖畔旅团",
		"position": Vector2(20.0, 155.0),
		"reveal_radius": 22.0,
		"notice_radius": 10.0,
		"interact_radius": 4.2,
		"parking_radius": 12.0,
		"clue": "北部高地亮起了新的灯串，旅人帐篷旁正在搭一座夜市拱门。",
		"rumor": "高地上留下了未完工的摊位，像在等待一次盛大的开场。",
		"approach_hint": "灯串下传来旅人的招呼声，一场招牌夜宴正在等待主厨。",
		"invitation": "旅团想在离开村落前尝遍这里的收成。把房车停到灯串拱门前，办一场真正的招牌夜宴吧。",
		"regular_hint": "湖畔旅团把这里当成固定停靠点，招牌夜市会持续开放。",
		"compass_icon": "✦",
		"asset_path": "res://3d建模/主线委托/湖畔旅团夜宴_v1.glb",
	},
}


static func get_site(level_id: int) -> Dictionary:
	return (SITES.get(level_id, {}) as Dictionary).duplicate(true)


static func all_level_ids() -> Array[int]:
	return [2, 3, 4, 5]


static func state_name(state: int) -> String:
	match clampi(state, STATE_HIDDEN, STATE_REGULAR):
		STATE_CLUE:
			return "线索已出现"
		STATE_DISCOVERED:
			return "已发现委托"
		STATE_REGULAR:
			return "老主顾"
	return "未有线索"
