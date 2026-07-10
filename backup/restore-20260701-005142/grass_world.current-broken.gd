@tool
extends Node3D

@export_range(4000, 60000, 1000) var grass_count: int = 26000:
	set(value):
		grass_count = value
		_queue_editor_rebuild()
@export_range(20.0, 160.0, 1.0) var field_radius: float = 72.0:
	set(value):
		field_radius = value
		_queue_editor_rebuild()
@export_range(0.15, 2.0, 0.05) var grass_height: float = 0.64:
	set(value):
		grass_height = value
		_queue_editor_rebuild()
@export_range(0.2, 1.8, 0.05) var wind_strength: float = 0.30:
	set(value):
		wind_strength = value
		_queue_editor_rebuild()
@export_range(0.4, 4.0, 0.1) var wind_speed: float = 1.35:
	set(value):
		wind_speed = value
		_queue_editor_rebuild()
@export var refresh_grass_preview: bool = false:
	set(value):
		refresh_grass_preview = false
		_queue_editor_rebuild()

const TERRAIN_SIZE := 160.0
const TERRAIN_STEPS := 80
const GRASS_SHADER := preload("res://shaders/grass_wind.gdshader")
const PLAYER_SCENE_PATH := "res://scenes/Player.tscn"
const CAMPER_SCENE_PATH := "res://3d建模/房车3d建模/9074167cffdd2b26a03baf531b4fae76.glb"
const MOM_SCENE_PATH := "res://3d建模/妈妈3d建模/95b973b63a8027c98172bc0efdb9bd68.glb"
const POND_SCENE_PATH := "res://3d建模/池塘/1a6db431228638d85c528889bcff7353.glb"
const REBAS_SCENE_PATH := "res://3d寤烘ā/鐟炲反鏂潕鐗?edc69c0683555e5c1d2445d7f6f37e75.glb"
const VILLAGE_HOUSE_SCENE_PATH := "res://3d建模/村里房子/311d8c4383612ac907ea5d625b074aaa.glb"
const TREE_SCENE_PATH := "res://3d寤烘ā/鏍?2f5d6b66e5b0fbbf4c7b1bede79477f5.glb"
const HOE_SCENE_PATH := "res://3d建模/工具/锄头.glb"
const WATERING_CAN_SCENE_PATH := "res://3d建模/工具/水壶.glb"
const SCYTHE_SCENE_PATH := "res://3d建模/工具/镰刀.glb"
const FOOD_CHEST_SCENE_PATH := "res://3d寤烘ā/璁惧/椋熸潗绠?glb"
const SEED_ICON_PATH := "res://ui/icons/seed_icon.png"
const MOM_PORTRAIT_PATH := "res://鑱婂ぉ妗?瀹夋彁鑾夊皵.png"
const PLAYER_PORTRAIT_PATH := "res://鑱婂ぉ妗?鎴?png"
const REBAS_PORTRAIT_PATH := "res://鑱婂ぉ妗?鑰佷集.png"
const DIALOGUE_BOX_PATH := "res://鑱婂ぉ妗?鑱婂ぉ妗?png"
const WORLD_MAP_PATH := "res://地图/b47063e2-0274-40a4-817d-c408c0418cd0_feathered.png"
const PLAYER_START := Vector3(0.0, 0.0, -26.0)
const CAMPER_POSITION := Vector3(0.0, 0.0, 10.0)
const MOM_POSITION := Vector3(0.0, 0.0, -4.0)
const CAMPER_TARGET_LENGTH := 8.8
const CAMPER_BLOCKER_PADDING := Vector2(0.12, 0.16)
const CAMPER_BLOCKER_SHRINK := 0.74
const MOM_MODEL_SCALE := 2.35
const MOM_BLOCKER_RADIUS := 1.05
const MOM_FACE_PLAYER_OFFSET := 0.0
const MOM_INTERACT_RADIUS := 1.65
const CAMPER_INTERACT_RADIUS := 4.2
const DROPPED_CROP_PICKUP_RADIUS := 2.1
const CAMPER_DROPPED_CROP_PICKUP_RADIUS := 4.6
const CAMPER_DROPPED_CROP_NEAR_RADIUS := 3.6
const DROPPED_SEED_PICKUP_RADIUS := 2.0
const MAP_VILLAGE_RADIUS := 0.095
const MAP_LOCKED_SITE_RADIUS := 0.065
const MAP_CAMPER_START := Vector2(0.125, 0.515)
const MAP_VILLAGE_POINT := Vector2(0.185, 0.315)
const MAP_VILLAGE_LABEL_POINT := Vector2(0.245, 0.125)
const MAP_LOCKED_SITE_POINTS := [
	Vector2(0.30, 0.67),
	Vector2(0.58, 0.20),
	Vector2(0.78, 0.42),
	Vector2(0.56, 0.72),
]
const MAP_LOCKED_LABEL_POINTS := [
	Vector2(0.30, 0.56),
	Vector2(0.58, 0.12),
	Vector2(0.78, 0.33),
	Vector2(0.56, 0.61),
]
const MAP_CAMPER_SPEED := 0.24
const MAP_CAMPER_RIGHT_FACING_YAW := PI
const MAP_CAMPER_YAW_OFFSET := MAP_CAMPER_RIGHT_FACING_YAW - PI * 0.5
const DIALOGUE_CHARS_PER_SECOND := 28.0
const MOM_NAME := "安提莉尔"
const TREE_BLOCKER_RADIUS := 1.05
const TREE_CLICK_SHAKE_RADIUS := 1.25
const TREE_SHAKE_DURATION := 0.42
const TREE_SHAKE_STRENGTH := 0.16
const TREE_SHAKE_FREQUENCY := 48.0
const PLAYER_MOVE_SPEED := 5.2
const SOIL_TILE_HALF_SIZE := 0.52
const SOIL_TILE_SIZE := 1.04
const SOIL_PATCH_SPACING := 3.35
const SOIL_POND_EDGE_PADDING := 1.75
const WATER_FILL_RADIUS := 2.2
const WATER_FILL_SECONDS := 3.2
const WATER_PER_USE := 0.20
const SCYTHE_SWEEP_RADIUS := 2.55
const SCYTHE_SWEEP_ANGLE := deg_to_rad(112.0)
const SCYTHE_SWEEP_MIN_DISTANCE := 0.35
const SCYTHE_GRASS_REGROW_SECONDS := 120.0
const SCYTHE_GRASS_REGROW_STAGGER_SECONDS := 360.0
const SCYTHE_GRASS_REGROW_STEP_SECONDS := 0.34
const FIRST_WEEDING_TARGET_COUNT := 34
const GRASS_SPATIAL_CELL_SIZE := 2.5
const CARROT_GROW_SECONDS := 10.0
const PEA_GROW_SECONDS := 16.0
const EGGPLANT_GROW_SECONDS := 24.0
const CROP_WEED_CHECK_RADIUS := 2.9
const CROP_WEED_PRESSURE_THRESHOLD := 24
const CROP_SOIL_WEED_PRESSURE_THRESHOLD := 4
const CROP_ROT_SECONDS := 120.0
const EMPTY_SOIL_DECAY_SECONDS := 120.0
const SOIL_WEED_MAX_PER_PATCH := 12
const SOIL_WEED_HALF_EXTENT := 1.34
const SOIL_WEED_INITIAL_GROW_MIN_SECONDS := 30.0
const SOIL_WEED_INITIAL_GROW_MAX_SECONDS := 90.0
const CROP_THROW_FULL_CHARGE_SECONDS := 1.25
const CROP_THROW_MIN_DISTANCE := 3.2
const CROP_THROW_MAX_DISTANCE := 18.0
const CHAPTER_ONE_PLAYER_START := Vector3(0.4, 0.0, 7.6)
const CHAPTER_ONE_HOUSE_POSITION := Vector3(6.0, 0.0, -7.0)
const CHAPTER_ONE_HOUSE_YAW := -24.0
const CHAPTER_ONE_MOM_POSITION := Vector3(-0.8, 0.0, 2.0)
const CHAPTER_ONE_MOM_MODEL_SCALE := MOM_MODEL_SCALE
const CHAPTER_ONE_REBAS_POSITION := Vector3(-32.784, 0.0, 11.879)
const CHAPTER_ONE_CAMPER_POSITION := Vector3(15.8, 0.0, 8.8)
const CHAPTER_ONE_CAMPER_YAW := -42.0
const CHAPTER_ONE_CAMPER_PATH_WIDTH := 2.25
const CHAPTER_ONE_CAMPER_PATH_GRASS_CLEAR_WIDTH := 3.0
const START_CAMPER_PATH_WIDTH := 3.8
const START_CAMPER_PATH_GRASS_CLEAR_WIDTH := 5.8
const START_CAMPER_PATH_CORE_CLEAR_WIDTH := 3.2
const CHAPTER_ONE_HOUSE_TARGET_LENGTH := 24.0
const CHAPTER_ONE_REBAS_TARGET_HEIGHT := 3.15
const CHAPTER_ONE_HOUSE_TREE_CLEAR_RADIUS := 30.0
const CHAPTER_ONE_CAMPER_POND_PADDING_RADIUS := 10.0
const HOUSE_DOOR_INTERACT_POSITION := Vector3(3.914, 0.0, -0.633)
const HOUSE_DOOR_INTERACT_RADIUS := 2.15
const HOUSE_OUTSIDE_SPAWN := Vector3(3.914, 0.0, 1.05)
const HOUSE_INTERIOR_CENTER := Vector3(-54.0, 0.0, -54.0)
const HOUSE_INTERIOR_SIZE := Vector2(15.5, 11.5)
const HOUSE_INTERIOR_FLOOR_Y := 2.2
const HOUSE_INTERIOR_SPAWN := Vector3(-54.0, HOUSE_INTERIOR_FLOOR_Y + 0.04, -49.55)
const HOUSE_INTERIOR_EXIT_POSITION := Vector3(-54.0, HOUSE_INTERIOR_FLOOR_Y, -48.45)
const HOUSE_INTERIOR_EXIT_RADIUS := 1.9
const HOUSE_INTERIOR_MOM_POSITION := Vector3(-57.4, HOUSE_INTERIOR_FLOOR_Y, -54.0)
const HOUSE_INTERIOR_MOM_PACE_A := Vector3(-57.4, HOUSE_INTERIOR_FLOOR_Y, -56.1)
const HOUSE_INTERIOR_MOM_PACE_B := Vector3(-50.8, HOUSE_INTERIOR_FLOOR_Y, -56.1)
const HOUSE_INTERIOR_CAMERA_ORBIT := Vector2(PI, 0.55)
const HOUSE_INTERIOR_CAMERA_ZOOM := 12.5
const FOOD_CHEST_A_POSITION := Vector3(-57.2, HOUSE_INTERIOR_FLOOR_Y + 0.08, -56.8)
const FOOD_CHEST_INTERACT_RADIUS := 1.8
const FOOD_CHEST_PLACE_RADIUS := 9.5
const FOOD_CHEST_DEPOSIT_RADIUS := 1.55
const FOOD_CHEST_PREVIEW_DISTANCE := 2.15
const INVENTORY_HAND_SLOT := 0
const INVENTORY_HOE_SLOT := 1
const INVENTORY_SEED_SLOT := 2
const INVENTORY_WATERING_CAN_SLOT := 3
const INVENTORY_SCYTHE_SLOT := 4
const INVENTORY_UNLOCKED_SLOT_COUNT := 10
const INVENTORY_DRAG_HOLD_TIME := 0.35
const INVENTORY_DISCARD_HOLD_TIME := 0.85
const INVENTORY_ITEM_NONE := ""
const INVENTORY_ITEM_HAND := "hand"
const INVENTORY_ITEM_HOE := "hoe"
const INVENTORY_ITEM_SEED_PREFIX := "seed:"
const INVENTORY_ITEM_SEED := "seed:carrot:0"
const INVENTORY_ITEM_WATERING_CAN := "watering_can"
const INVENTORY_ITEM_SCYTHE := "scythe"
const INVENTORY_ITEM_FOOD_CHEST := "food_chest"
const CROP_CARROT := "carrot"
const CROP_EGGPLANT := "eggplant"
const CROP_PEA := "pea"
const CROP_BELL_PEPPER := "bell_pepper"
const CROP_MARSHMALLOW := "marshmallow"
const CROP_TYPES := [CROP_CARROT, CROP_EGGPLANT, CROP_PEA]
const CODEX_CROP_TOTAL := 10
const CODEX_COOKING_TOTAL := 10
const CODEX_CROP_REWARDS := [
	{"count": 1, "label": "20 金币", "coins": 20},
	{"count": 3, "label": "胡萝卜种子 x3", "seed_crop": CROP_CARROT, "seed_quality": 0, "seed_count": 3},
	{"count": 6, "label": "80 金币", "coins": 80},
	{"count": 10, "label": "料理笔记线索", "toast": "新的料理灵感已经记录"},
]
const CODEX_COOKING_REWARDS := [
	{"count": 1, "label": "20 金币", "coins": 20},
	{"count": 3, "label": "料理研究台线索", "toast": "料理研究台线索已记录"},
	{"count": 6, "label": "120 金币", "coins": 120},
	{"count": 10, "label": "村庄料理委托", "toast": "村庄料理委托已记录"},
]
const KITCHEN_EQUIPMENT_TYPES := [
	{"id": "sink", "name": "洗菜池", "path": "res://3d建模/设备/洗菜池.glb"},
	{"id": "cutting_table", "name": "切菜桌", "path": "res://3d建模/设备/切菜桌.glb"},
	{"id": "pot", "name": "煮锅", "path": "res://3d建模/设备/煮锅.glb"},
	{"id": "grill", "name": "烧烤架", "path": "res://3d建模/设备/烧烤架.glb"},
	{"id": "prep_shelf", "name": "备菜架", "path": "res://3d建模/设备/备菜架.glb"},
]
const KITCHEN_EQUIPMENT_PREVIEW_DISTANCE := 2.0
const KITCHEN_EQUIPMENT_FOOTPRINT_HALF_EXTENTS := Vector2(1.08, 0.88)
const KITCHEN_EQUIPMENT_POND_PADDING := 0.42
const KITCHEN_EQUIPMENT_INTERACT_RADIUS := 2.0
const KITCHEN_RECIPE_SOUP := "carrot_soup"
const KITCHEN_RECIPE_GRILLED := "grilled_carrot"
const KITCHEN_RECIPE_DATA := {
	KITCHEN_RECIPE_SOUP: {"name": "胡萝卜清汤", "price": 18, "scrap_price": 5},
	KITCHEN_RECIPE_GRILLED: {"name": "烤胡萝卜", "price": 22, "scrap_price": 6},
}
const KITCHEN_FIRST_DAY_DURATION := 120.0
const KITCHEN_COOK_SOUP_SECONDS := 10.0
const KITCHEN_COOK_GRILL_SECONDS := 12.0
const KITCHEN_READY_SECONDS := 10.0
const KITCHEN_BURN_SECONDS := 12.0
const KITCHEN_ORDER_URGENT_SECONDS := 18.0
const KITCHEN_PREP_SECONDS := 2.0
const REBAS_NAME := "瑞巴斯坎特"
const REBAS_INTERACT_RADIUS := 2.0
const SHOP_REFRESH_UTC8_HOUR := 5
const SEED_DROP_SWING_MIN := 5
const SEED_DROP_SWING_MAX := 20
const SEED_DROP_SWING_MEDIAN := 10
const TREE_SEED_DROP_SHAKE_MIN := 4
const TREE_SEED_DROP_SHAKE_MAX := 8
const TREE_SEED_DROP_SHAKE_MEDIAN := 6
const VISIBLE_SUN_POSITION := Vector3(-30.0, 42.0, 86.0)
const PONDS := [
	{
		"position": Vector2(-18.0, 11.0),
		"radius": Vector2(8.6, 5.2),
		"rotation": 0.34,
	},
	{
		"position": Vector2(24.0, -19.0),
		"radius": Vector2(6.2, 3.9),
		"rotation": -0.48,
	},
]
const CHAPTER_ONE_PONDS := [
	{
		"position": Vector2(-18.0, -16.0),
		"radius": Vector2(7.8, 4.8),
		"rotation": 0.18,
	},
	{
		"position": Vector2(23.0, 14.0),
		"radius": Vector2(5.4, 3.7),
		"rotation": -0.55,
	},
	{
		"position": Vector2(-34.0, 25.0),
		"radius": Vector2(4.8, 3.1),
		"rotation": 0.72,
	},
]

var _camera_pivot: Node3D
var _camera: Camera3D
var _grass_material: ShaderMaterial
var _grass_multimesh: MultiMesh
var _soil_weed_root: Node3D
var _soil_weed_nodes: Array[Node3D] = []
var _player: Node3D
var _player_visual: Node3D
var _camper: Node3D
var _camper_model: Node3D
var _camper_is_highlighted := false
var _mom: Node3D
var _mom_model: Node3D
var _mom_exclamation: Label3D
var _mom_is_highlighted := false
var _rebas: Node3D
var _rebas_model: Node3D
var _rebas_exclamation: Label3D
var _rebas_is_highlighted := false
var _highlight_material: StandardMaterial3D
var _dialogue_layer: CanvasLayer
var _hud_root: Control
var _interaction_prompt: Control
var _interaction_prompt_label: Label
var _interaction_options: Array[Dictionary] = []
var _interaction_option_index := 0
var _post_tutorial_objective: PanelContainer
var _post_tutorial_objective_label: Label
var _pickup_feed: VBoxContainer
var _held_crop_quality_panel: PanelContainer
var _held_crop_quality_label: Label
var _inventory_bar: HBoxContainer
var _inventory_slots: Array[PanelContainer] = []
var _inventory_slot_items: Array[String] = []
var _selected_inventory_slot := 0
var _inventory_press_slot := -1
var _inventory_press_time := 0.0
var _inventory_press_position := Vector2.ZERO
var _inventory_dragging_item := false
var _inventory_drag_source_slot := -1
var _inventory_drag_hover_slot := -1
var _inventory_drag_ghost: Control
var _discard_hold_active := false
var _discard_hold_time := 0.0
var _discard_hold_source := ""
var _mouse_released_by_escape := false
var _reward_overlay: Control
var _reward_panel: Control
var _reward_viewport: SubViewport
var _reward_model_root: Node3D
var _reward_dragging := false
var _reward_press_position := Vector2.ZERO
var _reward_last_drag_position := Vector2.ZERO
var _reward_collecting := false
var _dialogue_panel: Control
var _dialogue_portrait: TextureRect
var _dialogue_name: Label
var _dialogue_body: Label
var _dialogue_options: VBoxContainer
var _dialogue_steps: Array[Dictionary] = []
var _dialogue_index := 0
var _dialogue_open := false
var _dialogue_completed := false
var _map_open := false
var _chapter_transitioning := false
var _chapter_one_active := false
var _map_panel: Control
var _map_popup: Control
var _map_camper_marker: Control
var _map_camper_icon: TextureRect
var _map_camper_model: Node3D
var _map_village_label: Label
var _map_locked_label: Label
var _map_page_locked_label: Label
var _map_codex_panel: Control
var _map_codex_crop_red_dot: Label
var _map_codex_crop_claim_button: Button
var _map_codex_cooking_red_dot: Label
var _map_codex_cooking_claim_button: Button
var _map_page_locked_time := 0.0
var _map_page_locked_side := 0
var _map_camper_pos := MAP_CAMPER_START
var _map_village_label_time := 0.0
var _map_was_near_village := false
var _map_locked_label_time := 0.0
var _map_locked_site_index := -1
var _map_dragging := false
var _map_drag_start := Vector2.ZERO
var _map_drag_vector := Vector2.ZERO
var _has_hoe := false
var _has_watering_can := false
var _has_scythe := false
var _has_food_chest := false
var _seed_count := 0
var _seed_inventory: Dictionary = {}
var _hoe_tutorial_active := false
var _return_to_mom_prompt_active := false
var _starter_kit_collected := false
var _watering_task_prompt_active := false
var _watering_task_active := false
var _scythe_task_prompt_active := false
var _scythe_collected := false
var _weeding_task_active := false
var _weeding_task_cut_count := 0
var _return_after_weeding_prompt_active := false
var _weeding_lesson_completed := false
var _hoe_rot_lesson_prompt_active := false
var _hoe_rot_lesson_completed := false
var _mom_talk_guide_completed := false
var _camper_map_guide_completed := false
var _map_village_guide_completed := false
var _house_entry_guide_completed := false
var _house_exit_guide_completed := false
var _hoe_guide_completed := false
var _tool_switch_guide_completed := false
var _inventory_sort_guide_completed := false
var _watering_guide_completed := false
var _scythe_guide_completed := false
var _food_chest_guide_completed := false
var _crop_throw_guide_completed := false
var _water_amount := 0.0
var _water_filling := false
var _water_fill_effect_cooldown := 0.0
var _notification_time := 0.0
var _notification_text := ""
var _shown_interaction_prompt_texts: Dictionary = {}
var _tilled_soil_root: Node3D
var _tilled_soil_centers: Array[Vector2] = []
var _planted_seed_root: Node3D
var _planted_seed_centers: Array[Vector2] = []
var _crop_nodes: Dictionary = {}
var _crop_growth_remaining: Dictionary = {}
var _crop_countdown_labels: Dictionary = {}
var _crop_rot_remaining: Dictionary = {}
var _crop_types: Dictionary = {}
var _crop_qualities: Dictionary = {}
var _empty_soil_decay_remaining: Dictionary = {}
var _matured_carrot_count := 0
var _crop_future_talk_completed := false
var _find_food_chests_prompt_active := false
var _food_chests_found := false
var _chest_lesson_completed := false
var _food_chest_nodes: Array[Node3D] = []
var _placed_food_chests: Array[Node3D] = []
var _food_chest_preview: Node3D
var _stored_crop_counts: Dictionary = {}
var _coins := 0
var _codex_discovered_crops: Dictionary = {}
var _codex_discovered_cooking: Dictionary = {}
var _codex_claimed_rewards: Dictionary = {}
var _rebas_intro_completed := false
var _pending_open_rebas_shop := false
var _shop_overlay: Control
var _shop_grid: GridContainer
var _shop_tab_sell: Button
var _shop_tab_buy: Button
var _shop_coin_label: Label
var _shop_refresh_label: Label
var _shop_action_button: Button
var _shop_select_all: CheckBox
var _food_chest_overlay: Control
var _food_chest_grid: GridContainer
var _shop_mode := "sell"
var _shop_selected_quantities: Dictionary = {}
var _shop_daily_key := ""
var _rebas_seen_shop_key := ""
var _shop_buy_stock: Dictionary = {}
var _shop_hold_button := ""
var _shop_hold_item_id := ""
var _shop_hold_direction := 0
var _shop_hold_time := 0.0
var _kitchen_equipment_panel: PanelContainer
var _kitchen_status_panel: PanelContainer
var _kitchen_status_label: Label
var _kitchen_equipment_panel_open := false
var _kitchen_placing_equipment := ""
var _kitchen_placing_yaw := 0.0
var _kitchen_equipment_preview: Node3D
var _kitchen_equipment_roots: Dictionary = {}
var _kitchen_washed_carrot := 0
var _kitchen_chopped_carrot := 0
var _kitchen_served_count := 0
var _kitchen_failed_count := 0
var _kitchen_business_active := false
var _kitchen_first_day_completed := false
var _kitchen_business_time := 0.0
var _kitchen_orders: Array[Dictionary] = []
var _kitchen_pot_state: Dictionary = {}
var _kitchen_grill_state: Dictionary = {}
var _kitchen_ready_dishes: Dictionary = {}
var _kitchen_scrap_dishes: Dictionary = {}
var _kitchen_scrap_income := 0
var _kitchen_held_item := ""
var _kitchen_held_recipe := ""
var _kitchen_held_visual: Node3D
var _kitchen_equipment_bubbles: Dictionary = {}
var _kitchen_equipment_progress: Dictionary = {}
var _watered_soil_centers: Array[Vector2] = []
var _held_crop_item := ""
var _held_crop_quality := 0
var _held_crop_root: Node3D
var _crop_throw_charging := false
var _crop_throw_charge_time := 0.0
var _crop_throw_button := ""
var _crop_throw_charge_bar: PanelContainer
var _crop_throw_charge_fill: ColorRect
var _dropped_crop_roots: Array[Node3D] = []
var _dropped_seed_roots: Array[Node3D] = []
var _player_hoe_root: Node3D
var _player_hoe_model: Node3D
var _hoe_swinging := false
var _scythe_swinging := false
var _seed_drop_swing_counter := 0
var _seed_drop_swing_target := 10
var _tree_seed_drop_shake_counter := 0
var _tree_seed_drop_shake_target := 6
var _tree_seed_drop_shaken_tree_indices: Array[int] = []
var _cut_grass_transforms: Dictionary = {}
var _grass_spatial_cells: Dictionary = {}
var _camera_shake_time := 0.0
var _camera_shake_strength := 0.0
var _camera_shake_offset := Vector3.ZERO
var _inside_house := false
var _house_transitioning := false
var _house_interior_root: Node3D
var _mom_outside_position := Vector3.ZERO
var _mom_outside_rotation_y := 0.0
var _mom_pace_target := HOUSE_INTERIOR_MOM_PACE_B
var _outside_camera_orbit := Vector2.ZERO
var _outside_camera_zoom := 0.0
var _typewriter_time := 0.0
var _typewriter_total := 0
var _solid_blockers: Array[Dictionary] = []
var _wind_trees: Array[Dictionary] = []
var _active_ponds: Array = []
var _orbit := Vector2(0.0, 0.42)
var _zoom := 15.0
var _editor_rebuild_queued := false

func _ready() -> void:
	randomize()
	if Engine.is_editor_hint():
		call_deferred("_rebuild_scene")
		return
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_rebuild_scene()

func _rebuild_scene() -> void:
	_editor_rebuild_queued = false
	_chapter_one_active = false
	_chapter_transitioning = false
	_active_ponds = PONDS.duplicate(true)
	_grass_material = null
	_grass_multimesh = null
	_soil_weed_root = null
	_soil_weed_nodes.clear()
	_hud_root = null
	_camper = null
	_camper_model = null
	_map_camper_model = null
	_map_codex_panel = null
	_mom = null
	_mom_model = null
	_mom_exclamation = null
	_mom_is_highlighted = false
	_rebas = null
	_rebas_model = null
	_rebas_exclamation = null
	_rebas_is_highlighted = false
	_dialogue_open = false
	_dialogue_index = 0
	_dialogue_completed = false
	_map_open = false
	_map_camper_pos = MAP_CAMPER_START
	_map_dragging = false
	_map_drag_vector = Vector2.ZERO
	_has_hoe = false
	_has_watering_can = false
	_has_scythe = false
	_has_food_chest = false
	_seed_count = 0
	_seed_inventory.clear()
	_hoe_tutorial_active = false
	_return_to_mom_prompt_active = false
	_starter_kit_collected = false
	_watering_task_prompt_active = false
	_watering_task_active = false
	_scythe_task_prompt_active = false
	_scythe_collected = false
	_weeding_task_active = false
	_weeding_task_cut_count = 0
	_return_after_weeding_prompt_active = false
	_weeding_lesson_completed = false
	_hoe_rot_lesson_prompt_active = false
	_hoe_rot_lesson_completed = false
	_mom_talk_guide_completed = false
	_camper_map_guide_completed = false
	_map_village_guide_completed = false
	_house_entry_guide_completed = false
	_house_exit_guide_completed = false
	_hoe_guide_completed = false
	_tool_switch_guide_completed = false
	_inventory_sort_guide_completed = false
	_watering_guide_completed = false
	_scythe_guide_completed = false
	_food_chest_guide_completed = false
	_crop_throw_guide_completed = false
	_water_amount = 0.0
	_water_filling = false
	_water_fill_effect_cooldown = 0.0
	_selected_inventory_slot = 0
	_shown_interaction_prompt_texts.clear()
	_reset_inventory_slot_items()
	_clear_inventory_drag_state()
	_mouse_released_by_escape = false
	_reward_overlay = null
	_reward_panel = null
	_reward_viewport = null
	_reward_model_root = null
	_reward_dragging = false
	_reward_press_position = Vector2.ZERO
	_reward_collecting = false
	_notification_time = 0.0
	_tilled_soil_root = null
	_tilled_soil_centers.clear()
	_planted_seed_root = null
	_planted_seed_centers.clear()
	_crop_nodes.clear()
	_crop_growth_remaining.clear()
	_crop_countdown_labels.clear()
	_crop_rot_remaining.clear()
	_crop_types.clear()
	_crop_qualities.clear()
	_empty_soil_decay_remaining.clear()
	_matured_carrot_count = 0
	_crop_future_talk_completed = false
	_find_food_chests_prompt_active = false
	_food_chests_found = false
	_chest_lesson_completed = false
	_food_chest_nodes.clear()
	_placed_food_chests.clear()
	_food_chest_preview = null
	_stored_crop_counts.clear()
	_codex_discovered_crops.clear()
	_codex_discovered_cooking.clear()
	_codex_claimed_rewards.clear()
	_rebas_intro_completed = false
	_pending_open_rebas_shop = false
	_shop_overlay = null
	_food_chest_overlay = null
	_food_chest_grid = null
	_shop_grid = null
	_rebas_seen_shop_key = ""
	_shop_selected_quantities.clear()
	_shop_hold_button = ""
	_shop_hold_item_id = ""
	_shop_hold_direction = 0
	_rebas_intro_completed = false
	_pending_open_rebas_shop = false
	_shop_overlay = null
	_food_chest_overlay = null
	_food_chest_grid = null
	_shop_grid = null
	_rebas_seen_shop_key = ""
	_shop_selected_quantities.clear()
	_shop_hold_button = ""
	_shop_hold_item_id = ""
	_shop_hold_direction = 0
	_watered_soil_centers.clear()
	_held_crop_item = ""
	_held_crop_quality = 0
	_held_crop_root = null
	_crop_throw_charging = false
	_crop_throw_charge_time = 0.0
	_crop_throw_button = ""
	_update_crop_throw_charge_bar()
	_crop_throw_charge_bar = null
	_crop_throw_charge_fill = null
	_dropped_crop_roots.clear()
	_dropped_seed_roots.clear()
	_player_hoe_root = null
	_player_hoe_model = null
	_hoe_swinging = false
	_scythe_swinging = false
	_seed_drop_swing_counter = 0
	_seed_drop_swing_target = _roll_seed_drop_swing_target()
	_tree_seed_drop_shake_counter = 0
	_tree_seed_drop_shake_target = _roll_tree_seed_drop_shake_target()
	_tree_seed_drop_shaken_tree_indices.clear()
	_cut_grass_transforms.clear()
	_grass_spatial_cells.clear()
	_camera_shake_time = 0.0
	_camera_shake_strength = 0.0
	_camera_shake_offset = Vector3.ZERO
	_inside_house = false
	_house_transitioning = false
	_house_interior_root = null
	_mom_outside_position = Vector3.ZERO
	_mom_outside_rotation_y = 0.0
	_mom_pace_target = HOUSE_INTERIOR_MOM_PACE_B
	_outside_camera_orbit = Vector2.ZERO
	_outside_camera_zoom = 0.0
	_camper_is_highlighted = false
	_typewriter_time = 0.0
	_typewriter_total = 0
	_solid_blockers.clear()
	_wind_trees.clear()
	_reset_kitchen_state()
	_clear_generated()
	_setup_world()
	_create_visible_sun()
	_create_background_clouds()
	_create_falling_petals()
	_create_terrain()
	_create_ponds()
	_create_chapter_one_camper_path()
	_create_ground_petals()
	_create_grass()
	_create_background_trees()
	_create_asset_trees()
	_create_mom()
	_create_camper()
	_create_player()
	_create_camera()
	_create_dialogue_ui()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _chapter_transitioning:
		return
	if _reward_overlay != null and _reward_overlay.visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return
	if _shop_overlay != null and _shop_overlay.visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		_update_shop_hold(delta)
		_update_shop_header()
		return
	if _food_chest_overlay != null and _food_chest_overlay.visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return
	_update_mouse_cursor_mode()
	_update_inventory_press(delta)
	_update_discard_hold(delta)
	_update_watering_can_fill(delta)
	_update_crop_throw_charge(delta)
	_update_crop_throw_charge_bar()
	_update_food_chest_placement_preview()
	_update_kitchen_equipment_placement_preview()
	_update_kitchen_business(delta)
	_update_kitchen_equipment_progress(delta)
	_update_kitchen_held_visual()
	_update_kitchen_equipment_bubbles()
	_update_kitchen_status_panel()
	_update_food_chest_deposits()
	_update_crop_growth(delta)
	_update_empty_soil_decay(delta)
	_update_post_tutorial_objective()
	_update_camera_shake(delta)
	_update_tree_wind(delta)
	_update_grass_player_push()
	_update_house_mom_pacing(delta)
	_update_mom_interaction()
	_refresh_interaction_prompt_text()
	if _dialogue_open:
		_update_dialogue_typewriter(delta)
	if _map_open:
		_update_map_popup(delta)
	if not _dialogue_open and not _map_open and not _is_free_cursor_requested():
		_update_camera_input(delta)
		_apply_camera()
	_update_mom_exclamation(delta)
	_update_rebas_exclamation(delta)
	_update_notification(delta)

func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event is InputEventMouseMotion and _inventory_dragging_item:
		_update_inventory_drag(event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and (_inventory_dragging_item or _inventory_press_slot != -1):
		_finish_inventory_drag(event.position)
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if _chapter_transitioning:
		get_viewport().set_input_as_handled()
		return
	if _reward_overlay != null and _reward_overlay.visible:
		_handle_reward_overlay_input(event)
		return
	if _shop_overlay != null and _shop_overlay.visible:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			_close_rebas_shop()
			get_viewport().set_input_as_handled()
		return
	if _food_chest_overlay != null and _food_chest_overlay.visible:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			_close_food_chest_inventory_panel()
			get_viewport().set_input_as_handled()
		return
	if _kitchen_placing_equipment != "" and _handle_kitchen_placement_input(event):
		return
	if _kitchen_equipment_panel_open and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_close_kitchen_equipment_panel()
		get_viewport().set_input_as_handled()
		return
	if _map_open:
		_handle_map_input(event)
		return
	if event is InputEventMouseMotion and not _dialogue_open and not _is_free_cursor_requested():
		var mouse_sensitivity := 0.0032
		_orbit.x -= event.relative.x * mouse_sensitivity
		_orbit.y = clampf(_orbit.y + event.relative.y * mouse_sensitivity, 0.04, 0.72)
		_apply_camera()
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if _dialogue_open:
			_close_dialogue()
		elif _map_open:
			_close_map_popup()
		else:
			_mouse_released_by_escape = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if event is InputEventKey and event.pressed and event.keycode == KEY_P:
		_capture_player_position()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_F:
		if _try_start_crop_throw_charge("keyboard"):
			get_viewport().set_input_as_handled()
			return
		if _try_execute_selected_interaction_option():
			get_viewport().set_input_as_handled()
			return
		if _try_interact_food_chest():
			get_viewport().set_input_as_handled()
			return
		if _try_use_house_door():
			get_viewport().set_input_as_handled()
			return
		if _try_start_watering_fill():
			get_viewport().set_input_as_handled()
			return
		if not _try_enter_camper() and not _try_start_mom_dialogue():
			if _try_use_selected_tool():
				get_viewport().set_input_as_handled()
				return
		if _try_start_discard_hold("keyboard"):
			get_viewport().set_input_as_handled()
			return
	if event is InputEventKey and not event.pressed and event.keycode == KEY_F:
		_stop_crop_throw_charge("keyboard")
		_stop_watering_fill()
		_stop_discard_hold("keyboard")
	if event is InputEventMouseButton and event.pressed:
		if not _is_free_cursor_requested():
			_mouse_released_by_escape = false
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if _select_interaction_option_delta(-1):
				get_viewport().set_input_as_handled()
				return
			_select_inventory_delta(-1)
			get_viewport().set_input_as_handled()
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if _select_interaction_option_delta(1):
				get_viewport().set_input_as_handled()
				return
			_select_inventory_delta(1)
			get_viewport().set_input_as_handled()
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			if _try_start_crop_throw_charge("mouse"):
				get_viewport().set_input_as_handled()
				return
			if _try_execute_selected_interaction_option():
				get_viewport().set_input_as_handled()
				return
			if _try_interact_food_chest():
				get_viewport().set_input_as_handled()
				return
			if _try_use_house_door():
				get_viewport().set_input_as_handled()
				return
			if _try_start_watering_fill():
				get_viewport().set_input_as_handled()
				return
			if not _try_enter_camper() and not _try_start_mom_dialogue():
				if not _try_use_selected_tool():
					_shake_nearby_tree()
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_stop_crop_throw_charge("mouse")
		_stop_watering_fill()

func _is_free_cursor_requested() -> bool:
	return Input.is_key_pressed(KEY_ALT) or _inventory_dragging_item or _kitchen_equipment_panel_open

func _update_mouse_cursor_mode() -> void:
	if _dialogue_open or _map_open or _is_free_cursor_requested():
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif not _mouse_released_by_escape:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _queue_editor_rebuild() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree() or _editor_rebuild_queued:
		return
	_editor_rebuild_queued = true
	call_deferred("_rebuild_scene")

func _clear_generated() -> void:
	for child in get_children():
		if child.get_meta("generated_grass_world", false):
			child.queue_free()

func _mark_generated(node: Node) -> void:
	node.set_meta("generated_grass_world", true)

func _sun_light_direction() -> Vector3:
	return -VISIBLE_SUN_POSITION.normalized()

func _setup_world() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.48, 0.74, 0.98)
	sky_mat.sky_horizon_color = Color(0.74, 0.88, 0.96)
	sky_mat.ground_bottom_color = Color(0.76, 0.82, 0.72)
	sky_mat.ground_horizon_color = Color(0.86, 0.91, 0.84)
	sky_mat.sun_angle_max = 22.0
	sky_mat.sun_curve = 0.12
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.72
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.08
	env.tonemap_white = 4.2
	env.glow_enabled = true
	env.glow_intensity = 0.20
	env.glow_strength = 0.28
	env.fog_enabled = true
	env.fog_light_color = Color(0.78, 0.88, 0.94)
	env.fog_sun_scatter = 0.12
	env.fog_density = 0.0018
	env.fog_aerial_perspective = 0.08
	world_env.environment = env
	_mark_generated(world_env)
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.name = "SoftSun"
	sun.position = VISIBLE_SUN_POSITION
	sun.light_color = Color(1.0, 0.90, 0.62)
	sun.light_energy = 5.6
	sun.light_angular_distance = 1.2
	sun.shadow_enabled = false
	sun.shadow_opacity = 0.0
	sun.directional_shadow_max_distance = 80.0
	_mark_generated(sun)
	add_child(sun)
	sun.look_at(Vector3.ZERO, Vector3.UP)

func _create_visible_sun() -> void:
	var sun_mesh := SphereMesh.new()
	sun_mesh.radius = 5.2
	sun_mesh.height = 10.4
	sun_mesh.radial_segments = 48
	sun_mesh.rings = 24

	var sun_mat := StandardMaterial3D.new()
	sun_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sun_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sun_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	sun_mat.albedo_color = Color(1.0, 0.86, 0.36, 0.62)
	sun_mat.emission_enabled = true
	sun_mat.emission = Color(1.0, 0.78, 0.28)
	sun_mat.emission_energy_multiplier = 3.8

	var visible_sun := MeshInstance3D.new()
	visible_sun.name = "VisibleSun"
	visible_sun.mesh = sun_mesh
	visible_sun.material_override = sun_mat
	visible_sun.position = VISIBLE_SUN_POSITION
	visible_sun.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mark_generated(visible_sun)
	add_child(visible_sun)

	for halo in [
		{"radius": 13.5, "alpha": 0.24, "energy": 1.8},
		{"radius": 22.0, "alpha": 0.10, "energy": 1.1},
		{"radius": 34.0, "alpha": 0.045, "energy": 0.7},
	]:
		var halo_mesh := SphereMesh.new()
		halo_mesh.radius = halo["radius"]
		halo_mesh.height = halo["radius"] * 2.0
		halo_mesh.radial_segments = 48
		halo_mesh.rings = 16

		var halo_mat := StandardMaterial3D.new()
		halo_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		halo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		halo_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		halo_mat.albedo_color = Color(1.0, 0.70, 0.22, halo["alpha"])
		halo_mat.emission_enabled = true
		halo_mat.emission = Color(1.0, 0.62, 0.18)
		halo_mat.emission_energy_multiplier = halo["energy"]

		var sun_halo := MeshInstance3D.new()
		sun_halo.name = "VisibleSunHalo"
		sun_halo.mesh = halo_mesh
		sun_halo.material_override = halo_mat
		sun_halo.position = visible_sun.position
		sun_halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_mark_generated(sun_halo)
		add_child(sun_halo)

func _create_background_clouds() -> void:
	var cloud_mat := StandardMaterial3D.new()
	cloud_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cloud_mat.albedo_color = Color(0.96, 0.98, 0.94, 0.88)
	cloud_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var rng := RandomNumberGenerator.new()
	rng.seed = 2727
	for i in range(24):
		var cloud := Node3D.new()
		cloud.name = "SoftHorizonCloud"
		var a := TAU * float(i) / 24.0 + rng.randf_range(-0.06, 0.06)
		var r := rng.randf_range(72.0, 118.0)
		cloud.position = Vector3(cos(a) * r, rng.randf_range(24.0, 39.0), sin(a) * r)
		cloud.rotation.y = -a + PI * 0.5
		cloud.scale = Vector3.ONE * rng.randf_range(1.25, 2.15)
		_mark_generated(cloud)
		add_child(cloud)

		var puff_count := rng.randi_range(5, 9)
		for j in range(puff_count):
			var puff := MeshInstance3D.new()
			var puff_mesh := BoxMesh.new()
			puff_mesh.size = Vector3(rng.randf_range(16.0, 32.0), rng.randf_range(4.4, 9.0), 0.72)
			puff.mesh = puff_mesh
			puff.position = Vector3(rng.randf_range(-34.0, 34.0), rng.randf_range(-2.4, 2.8), rng.randf_range(-0.6, 0.6))
			puff.rotation.z = rng.randf_range(-0.035, 0.035)
			puff.material_override = cloud_mat
			puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			cloud.add_child(puff)

func _create_falling_petals() -> void:
	_create_petal_emitter(
		"NearPetalFall",
		Vector3(7.0, 30.0, 24.0),
		Vector3(48.0, 1.0, 64.0),
		950,
		24.0,
		Color(1.0, 0.66, 0.78, 0.86),
		Vector2(0.18, 0.10),
		1.0
	)
	_create_petal_emitter(
		"RoutePetalFall",
		Vector3(10.0, 38.0, 28.0),
		Vector3(86.0, 1.0, 98.0),
		620,
		34.0,
		Color(1.0, 0.86, 0.90, 0.58),
		Vector2(0.14, 0.075),
		0.72
	)
	_create_petal_emitter(
		"SoftDistantPetalFall",
		Vector3(-22.0, 40.0, 16.0),
		Vector3(92.0, 1.0, 96.0),
		320,
		36.0,
		Color(1.0, 0.78, 0.86, 0.42),
		Vector2(0.12, 0.065),
		0.58
	)
	for index in range(_active_ponds.size()):
		var pond: Dictionary = _active_ponds[index]
		var center: Vector2 = pond["position"]
		var radius: Vector2 = pond["radius"]
		_create_petal_emitter(
			"PondPetalFall%d" % index,
			Vector3(center.x, _height_at(center.x, center.y) + 11.0, center.y),
			Vector3(radius.x * 1.25, 0.65, radius.y * 1.25),
			180,
			18.0,
			Color(1.0, 0.67, 0.82, 0.72),
			Vector2(0.15, 0.085),
			0.42
		)

func _create_petal_emitter(
	emitter_name: String,
	emitter_position: Vector3,
	box_extents: Vector3,
	petal_amount: int,
	petal_lifetime: float,
	petal_color: Color,
	petal_size: Vector2,
	speed_scale: float
) -> void:
	var petal_mat := StandardMaterial3D.new()
	petal_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	petal_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	petal_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	petal_mat.albedo_color = petal_color
	petal_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var petal_mesh := _create_petal_mesh(petal_size, petal_mat)

	var process_mat := ParticleProcessMaterial.new()
	process_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process_mat.emission_box_extents = box_extents
	process_mat.direction = Vector3(0.22, -1.0, 0.08).normalized()
	process_mat.spread = 28.0
	process_mat.gravity = Vector3(0.08, -0.16, 0.03) * speed_scale
	process_mat.initial_velocity_min = 0.45 * speed_scale
	process_mat.initial_velocity_max = 1.15 * speed_scale
	process_mat.angular_velocity_min = -170.0
	process_mat.angular_velocity_max = 170.0
	process_mat.linear_accel_min = -0.08
	process_mat.linear_accel_max = 0.08
	process_mat.tangential_accel_min = -0.22
	process_mat.tangential_accel_max = 0.22
	process_mat.damping_min = 0.08
	process_mat.damping_max = 0.22
	process_mat.scale_min = 0.75
	process_mat.scale_max = 1.45
	process_mat.color = petal_color

	var petals := GPUParticles3D.new()
	petals.name = emitter_name
	petals.amount = petal_amount
	petals.lifetime = petal_lifetime
	petals.preprocess = petal_lifetime
	petals.randomness = 0.72
	petals.visibility_aabb = AABB(Vector3(-90.0, -8.0, -90.0), Vector3(180.0, 60.0, 180.0))
	petals.emitting = true
	petals.process_material = process_mat
	petals.draw_pass_1 = petal_mesh
	petals.position = emitter_position
	_mark_generated(petals)
	add_child(petals)

func _create_petal_mesh(petal_size: Vector2, petal_mat: Material) -> ArrayMesh:
	var half_width := petal_size.x * 0.5
	var half_height := petal_size.y * 0.5
	var vertices := PackedVector3Array([
		Vector3(0.0, 0.0, 0.0),
		Vector3(0.0, half_height, 0.0),
		Vector3(-half_width * 0.78, half_height * 0.34, 0.0),
		Vector3(-half_width, -half_height * 0.22, 0.0),
		Vector3(0.0, -half_height, 0.0),
		Vector3(half_width, -half_height * 0.22, 0.0),
		Vector3(half_width * 0.78, half_height * 0.34, 0.0),
	])
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	for vertex in vertices:
		normals.append(Vector3.FORWARD)
		uvs.append(Vector2(vertex.x / petal_size.x + 0.5, vertex.y / petal_size.y + 0.5))

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3, 0, 3, 4, 0, 4, 5, 0, 5, 6, 0, 6, 1])

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, petal_mat)
	return mesh

func _create_terrain() -> void:
	var mesh := ArrayMesh.new()
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var half := TERRAIN_SIZE * 0.5

	for z in range(TERRAIN_STEPS + 1):
		for x in range(TERRAIN_STEPS + 1):
			var px := lerpf(-half, half, float(x) / TERRAIN_STEPS)
			var pz := lerpf(-half, half, float(z) / TERRAIN_STEPS)
			var py := _height_at(px, pz)
			vertices.append(Vector3(px, py, pz))
			normals.append(_normal_at(px, pz))
			uvs.append(Vector2(float(x) / TERRAIN_STEPS, float(z) / TERRAIN_STEPS))

	for z in range(TERRAIN_STEPS):
		for x in range(TERRAIN_STEPS):
			var i := z * (TERRAIN_STEPS + 1) + x
			indices.append_array(PackedInt32Array([i, i + TERRAIN_STEPS + 1, i + 1, i + 1, i + TERRAIN_STEPS + 1, i + TERRAIN_STEPS + 2]))

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var ground := MeshInstance3D.new()
	ground.name = "SoftLowPolyGround"
	ground.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.78, 0.82, 0.72)
	mat.roughness = 0.92
	mat.disable_receive_shadows = false
	ground.material_override = mat
	_mark_generated(ground)
	add_child(ground)

func _create_grass() -> void:
	_grass_spatial_cells.clear()
	var grass_mesh := _make_grass_clump_mesh()
	var mat := ShaderMaterial.new()
	mat.shader = GRASS_SHADER
	mat.set_shader_parameter("wind_strength", wind_strength)
	mat.set_shader_parameter("wind_speed", wind_speed)
	mat.set_shader_parameter("player_push_radius", 2.4)
	mat.set_shader_parameter("player_push_strength", 0.0)
	_grass_material = mat

	var multimesh := MultiMesh.new()
	_grass_multimesh = multimesh
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.use_custom_data = false
	multimesh.mesh = grass_mesh
	multimesh.instance_count = grass_count

	var rng := RandomNumberGenerator.new()
	rng.seed = 424242
	var cluster_centers := _make_grass_cluster_centers(rng, 96)
	var placed := 0
	var attempts := 0
	while placed < grass_count and attempts < grass_count * 8:
		attempts += 1
		var x := 0.0
		var z := 0.0
		for retry in range(8):
			var point := _pick_grass_point(rng, cluster_centers)
			x = point.x
			z = point.y
			if _can_place_grass_at(x, z):
				break
		if not _can_place_grass_at(x, z):
			continue

		var density := _grass_density_at(x, z)
		density *= _start_camper_path_grass_density_multiplier(x, z)
		if rng.randf() > density * 0.95:
			continue

		var y := _height_at(x, z)
		var height_variation := lerpf(0.62, 1.12, pow(rng.randf(), 0.72))
		var density_height := lerpf(0.82, 1.08, density)
		var scale := rng.randf_range(0.78, 1.08) * grass_height * density_height
		var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(Vector3(scale * rng.randf_range(0.95, 1.18), scale * height_variation, scale * rng.randf_range(0.95, 1.18)))
		multimesh.set_instance_transform(placed, Transform3D(basis, Vector3(x, y, z)))
		var cell_key := _grass_cell_key(Vector2(x, z))
		if not _grass_spatial_cells.has(cell_key):
			_grass_spatial_cells[cell_key] = []
		_grass_spatial_cells[cell_key].append(placed)
		var shade := rng.randf()
		var clump_color := Color(lerpf(0.35, 0.72, shade), lerpf(0.52, 0.82, shade), lerpf(0.26, 0.38, shade), 1.0)
		multimesh.set_instance_color(placed, clump_color)
		placed += 1

	multimesh.instance_count = placed

	var grass := MultiMeshInstance3D.new()
	grass.name = "VeryDenseWindGrass"
	grass.multimesh = multimesh
	grass.material_override = mat
	grass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mark_generated(grass)
	add_child(grass)

func _update_grass_player_push() -> void:
	if _grass_material == null:
		return
	if _player != null and is_instance_valid(_player):
		_grass_material.set_shader_parameter("player_position", _player.global_position)

func _start_camera_shake(duration: float, strength: float) -> void:
	_camera_shake_time = maxf(_camera_shake_time, duration)
	_camera_shake_strength = maxf(_camera_shake_strength, strength)

func _update_camera_shake(delta: float) -> void:
	if _camera_shake_time <= 0.0:
		_camera_shake_offset = Vector3.ZERO
		_camera_shake_strength = 0.0
		return
	_camera_shake_time = maxf(_camera_shake_time - delta, 0.0)
	var falloff := _camera_shake_time / 0.16
	_camera_shake_offset = Vector3(randf_range(-1.0, 1.0), randf_range(-0.45, 0.45), randf_range(-1.0, 1.0)) * _camera_shake_strength * falloff

func _grass_cell_key(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x / GRASS_SPATIAL_CELL_SIZE), floori(point.y / GRASS_SPATIAL_CELL_SIZE))

func _grass_density_at(x: float, z: float) -> float:
	var broad := sin(x * 0.115 + 1.7) * 0.5 + cos(z * 0.092 - 0.4) * 0.5
	var patches := sin((x + z) * 0.175) * 0.28 + cos((x - z) * 0.145) * 0.22
	var fine := sin(x * 0.43 + z * 0.27) * 0.08
	var clumps := sin(x * 0.31 + z * 0.19) * 0.18 + cos(x * 0.24 - z * 0.28) * 0.16
	var density := 0.42 + broad * 0.18 + patches * 0.28 + clumps + fine
	return clampf(density, 0.10, 0.96)

func _make_grass_cluster_centers(rng: RandomNumberGenerator, count: int) -> Array[Vector2]:
	var centers: Array[Vector2] = []
	for i in range(count):
		var r := field_radius * sqrt(rng.randf())
		var a := rng.randf_range(0.0, TAU)
		centers.append(Vector2(cos(a) * r, sin(a) * r))
	return centers

func _pick_grass_point(rng: RandomNumberGenerator, cluster_centers: Array[Vector2]) -> Vector2:
	if cluster_centers.size() > 0 and rng.randf() < 0.72:
		var center := cluster_centers[rng.randi_range(0, cluster_centers.size() - 1)]
		var spread := rng.randf_range(1.1, 4.6)
		var angle := rng.randf_range(0.0, TAU)
		var distance := spread * pow(rng.randf(), 1.75)
		return center + Vector2(cos(angle), sin(angle)) * distance
	var r := field_radius * sqrt(rng.randf())
	var a := rng.randf_range(0.0, TAU)
	return Vector2(cos(a) * r, sin(a) * r)

func _can_place_grass_at(x: float, z: float) -> bool:
	if _is_inside_pond(x, z, 1.35):
		return false
	if _is_inside_chapter_one_house_grass_clear(x, z):
		return false
	if _is_inside_chapter_one_camper_path_clear(x, z):
		return false
	if _is_inside_start_camper_path_clear(x, z):
		return false
	if _is_inside_house_interior_grass_clear(x, z):
		return false
	return true

func _is_inside_house_interior_grass_clear(x: float, z: float) -> bool:
	var point := Vector2(x, z)
	var center := Vector2(HOUSE_INTERIOR_CENTER.x, HOUSE_INTERIOR_CENTER.z)
	var half := HOUSE_INTERIOR_SIZE * 0.5 + Vector2(1.8, 1.8)
	var local := point - center
	return absf(local.x) <= half.x and absf(local.y) <= half.y

func _is_inside_chapter_one_house_grass_clear(x: float, z: float) -> bool:
	if not _chapter_one_active:
		return false
	var point := Vector2(x, z)
	var house_center := Vector2(CHAPTER_ONE_HOUSE_POSITION.x, CHAPTER_ONE_HOUSE_POSITION.z)
	var house_local := (point - house_center).rotated(-deg_to_rad(CHAPTER_ONE_HOUSE_YAW))
	if absf(house_local.x) <= 13.0 and absf(house_local.y) <= 7.2:
		return true
	var door_center := Vector2(HOUSE_DOOR_INTERACT_POSITION.x, HOUSE_DOOR_INTERACT_POSITION.z)
	var door_local := (point - door_center).rotated(-deg_to_rad(CHAPTER_ONE_HOUSE_YAW))
	return absf(door_local.x) <= 4.4 and absf(door_local.y) <= 3.0

func _is_inside_chapter_one_camper_path_clear(x: float, z: float) -> bool:
	return false

func _is_inside_start_camper_path_clear(x: float, z: float) -> bool:
	if _chapter_one_active:
		return false
	return _distance_to_polyline(Vector2(x, z), _start_camper_path_points()) <= START_CAMPER_PATH_CORE_CLEAR_WIDTH * 0.5

func _start_camper_path_grass_density_multiplier(x: float, z: float) -> float:
	if _chapter_one_active:
		return 1.0
	var distance := _distance_to_polyline(Vector2(x, z), _start_camper_path_points())
	var core := START_CAMPER_PATH_CORE_CLEAR_WIDTH * 0.5
	var outer := START_CAMPER_PATH_GRASS_CLEAR_WIDTH * 0.5
	if distance <= core:
		return 0.0
	if distance >= outer:
		return 1.0
	var t := (distance - core) / maxf(outer - core, 0.001)
	return lerpf(0.16, 1.0, smoothstep(0.0, 1.0, t))

func _chapter_one_camper_path_points() -> Array[Vector2]:
	return [
		Vector2(2.8, 1.15),
		Vector2(5.7, 3.25),
		Vector2(9.4, 5.15),
		Vector2(12.7, 6.75),
		Vector2(15.1, 7.8),
	]

func _start_camper_path_points() -> Array[Vector2]:
	return [
		Vector2(-0.8, -39.0),
		Vector2(-0.55, -32.0),
		Vector2(0.28, -25.0),
		Vector2(0.78, -18.2),
		Vector2(0.28, -11.0),
		Vector2(-0.20, -4.0),
		Vector2(0.34, 3.0),
		Vector2(0.0, 8.7),
	]

func _distance_to_polyline(point: Vector2, points: Array[Vector2]) -> float:
	if points.is_empty():
		return INF
	if points.size() == 1:
		return point.distance_to(points[0])
	var best := INF
	for index in range(points.size() - 1):
		var a := points[index]
		var b := points[index + 1]
		var ab := b - a
		var length_sq := ab.length_squared()
		if length_sq <= 0.0001:
			best = minf(best, point.distance_to(a))
			continue
		var t := clampf((point - a).dot(ab) / length_sq, 0.0, 1.0)
		best = minf(best, point.distance_to(a + ab * t))
	return best

func _is_inside_pond(x: float, z: float, padding: float = 0.0) -> bool:
	var effective_padding := padding
	if _chapter_one_active:
		var camper_point := Vector2(CHAPTER_ONE_CAMPER_POSITION.x, CHAPTER_ONE_CAMPER_POSITION.z)
		var sample_point := Vector2(x, z)
		if sample_point.distance_squared_to(camper_point) <= CHAPTER_ONE_CAMPER_POND_PADDING_RADIUS * CHAPTER_ONE_CAMPER_POND_PADDING_RADIUS:
			effective_padding = minf(effective_padding, 0.1)
	for pond in _active_ponds:
		var center: Vector2 = pond["position"]
		var radius: Vector2 = pond["radius"] + Vector2(effective_padding, effective_padding)
		var rotation: float = pond["rotation"]
		var offset := Vector2(x - center.x, z - center.y)
		var local := offset.rotated(-rotation)
		var normalized := pow(local.x / radius.x, 2.0) + pow(local.y / radius.y, 2.0)
		if normalized <= 1.0:
			return true
	return false

func _create_ponds() -> void:
	var scene := load(POND_SCENE_PATH)
	if not scene is PackedScene:
		push_warning("Could not load pond model: %s" % POND_SCENE_PATH)
		return

	for pond in _active_ponds:
		var center: Vector2 = pond["position"]
		var radius: Vector2 = pond["radius"]
		var rotation: float = pond["rotation"]
		var base_y := _height_at(center.x, center.y)

		var pond_root := Node3D.new()
		pond_root.name = "SmallReflectivePond"
		pond_root.position = Vector3(center.x, base_y, center.y)
		pond_root.rotation.y = rotation
		_mark_generated(pond_root)
		add_child(pond_root)

		var model := scene.instantiate() as Node3D
		if model == null:
			continue
		model.name = "PondModel"
		pond_root.add_child(model)
		_fit_model_to_footprint_length(model, maxf(radius.x, radius.y) * 2.25)
		_prepare_pond_model(model)
		_add_floating_pond_petals(pond_root, radius)

func _create_chapter_one_camper_path() -> void:
	if _chapter_one_active:
		return
	var points := _chapter_one_camper_path_points() if _chapter_one_active else _start_camper_path_points()
	if points.size() < 2:
		return
	var root := Node3D.new()
	root.name = "ChapterOneCamperPath" if _chapter_one_active else "StartCamperPath"
	_mark_generated(root)
	add_child(root)

	var path_width := CHAPTER_ONE_CAMPER_PATH_WIDTH if _chapter_one_active else START_CAMPER_PATH_WIDTH
	var render_points := _subdivide_polyline(points, 1.35)
	if _chapter_one_active:
		var path_mesh := _create_path_strip_mesh(render_points, path_width, 0.04)
		var path := MeshInstance3D.new()
		path.name = "SoftTrampledPath"
		path.mesh = path_mesh
		var path_mat := StandardMaterial3D.new()
		path_mat.albedo_color = Color(0.80, 0.76, 0.60, 1.0)
		path_mat.roughness = 0.94
		path_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		path_mat.disable_receive_shadows = false
		path.material_override = path_mat
		path.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(path)

	var edge_mat := StandardMaterial3D.new()
	edge_mat.albedo_color = Color(0.88, 0.86, 0.76, 1.0) if not _chapter_one_active else Color(0.90, 0.86, 0.66, 1.0)
	edge_mat.roughness = 0.96
	var pebble_mat := StandardMaterial3D.new()
	pebble_mat.albedo_color = Color(0.78, 0.76, 0.66, 1.0) if not _chapter_one_active else Color(0.72, 0.73, 0.62, 1.0)
	pebble_mat.roughness = 0.9
	var rng := RandomNumberGenerator.new()
	rng.seed = 71337 if _chapter_one_active else 91331
	var pebble_count := 26 if _chapter_one_active else 34
	for index in range(pebble_count):
		var sample := _sample_polyline(points, rng.randf_range(0.03, 0.97))
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		var tangent := _polyline_tangent_at(points, sample)
		var normal := Vector2(-tangent.y, tangent.x) * side
		var offset := normal * rng.randf_range(0.0, path_width * (0.48 if not _chapter_one_active else 0.54))
		var center := sample + offset
		if _is_inside_pond(center.x, center.y, 0.25):
			continue
		var stone := MeshInstance3D.new()
		stone.name = "PathPaperScrap" if not _chapter_one_active else "PathPebble"
		var mesh := BoxMesh.new()
		mesh.size = Vector3(rng.randf_range(0.22, 0.64), rng.randf_range(0.010, 0.018), rng.randf_range(0.12, 0.36)) if not _chapter_one_active else Vector3(rng.randf_range(0.35, 0.82), rng.randf_range(0.025, 0.045), rng.randf_range(0.22, 0.52))
		stone.mesh = mesh
		stone.position = Vector3(center.x, _height_at(center.x, center.y) + (0.12 if not _chapter_one_active else 0.055), center.y)
		stone.rotation.y = atan2(tangent.x, tangent.y) + rng.randf_range(-1.45, 1.45)
		stone.rotation.x = rng.randf_range(-0.04, 0.04)
		stone.rotation.z = rng.randf_range(-0.04, 0.04)
		stone.material_override = edge_mat if rng.randf() < (0.55 if not _chapter_one_active else 0.62) else pebble_mat
		stone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(stone)

func _create_path_strip_mesh(points: Array[Vector2], width: float, height_offset: float = 0.035, natural_width: bool = false) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var half_width := width * 0.5
	for index in range(points.size()):
		var point := points[index]
		var tangent := _path_point_tangent(points, index)
		var normal_2d := Vector2(-tangent.y, tangent.x)
		var progress := float(index) / maxf(float(points.size() - 1), 1.0)
		var taper := 1.0
		if natural_width:
			taper = lerpf(0.62, 1.0, smoothstep(0.0, 0.20, progress))
			taper *= lerpf(1.0, 0.56, smoothstep(0.76, 1.0, progress))
		var local_half_width := half_width * taper
		var edge_wobble := sin(float(index) * 1.13) * (0.14 if natural_width else 0.16) + sin(float(index) * 2.47 + 0.8) * (0.07 if natural_width else 0.0)
		var left := point + normal_2d * (local_half_width + edge_wobble)
		var right := point - normal_2d * (local_half_width - edge_wobble * 0.7)
		vertices.append(Vector3(left.x, _height_at(left.x, left.y) + height_offset, left.y))
		vertices.append(Vector3(right.x, _height_at(right.x, right.y) + height_offset, right.y))
		normals.append(Vector3.UP)
		normals.append(Vector3.UP)
		uvs.append(Vector2(0.0, float(index)))
		uvs.append(Vector2(1.0, float(index)))
		var color_mix := 0.5 + sin(float(index) * 0.73) * 0.22 + sin(float(index) * 1.91 + 0.8) * 0.12
		var base_color := Color(0.76, 0.72, 0.64, 1.0).lerp(Color(0.86, 0.78, 0.61, 1.0), clampf(color_mix, 0.0, 1.0))
		base_color = base_color.lerp(Color(0.68, 0.61, 0.50, 1.0), 0.16 + 0.10 * sin(float(index) * 1.37 + 1.2))
		if not natural_width:
			base_color = Color(0.80, 0.76, 0.60, 1.0)
		colors.append(base_color)
		colors.append(base_color.lerp(Color(0.72, 0.68, 0.58, 1.0), 0.12))
	for index in range(points.size() - 1):
		var base := index * 2
		indices.append_array(PackedInt32Array([base, base + 1, base + 2, base + 1, base + 3, base + 2]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _offset_polyline(points: Array[Vector2], offset: float) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for index in range(points.size()):
		var tangent := _path_point_tangent(points, index)
		var normal := Vector2(-tangent.y, tangent.x)
		result.append(points[index] + normal * offset)
	return result

func _subdivide_polyline(points: Array[Vector2], max_step: float) -> Array[Vector2]:
	if points.size() <= 1:
		return points.duplicate()
	var result: Array[Vector2] = []
	for index in range(points.size() - 1):
		var a := points[index]
		var b := points[index + 1]
		if result.is_empty():
			result.append(a)
		var distance := a.distance_to(b)
		var steps := maxi(1, ceili(distance / maxf(max_step, 0.1)))
		for step in range(1, steps + 1):
			result.append(a.lerp(b, float(step) / float(steps)))
	return result

func _path_point_tangent(points: Array[Vector2], index: int) -> Vector2:
	if points.size() < 2:
		return Vector2(0.0, 1.0)
	if index <= 0:
		return (points[1] - points[0]).normalized()
	if index >= points.size() - 1:
		return (points[index] - points[index - 1]).normalized()
	return (points[index + 1] - points[index - 1]).normalized()

func _sample_polyline(points: Array[Vector2], t: float) -> Vector2:
	if points.is_empty():
		return Vector2.ZERO
	if points.size() == 1:
		return points[0]
	var lengths: Array[float] = []
	var total := 0.0
	for index in range(points.size() - 1):
		var length := points[index].distance_to(points[index + 1])
		lengths.append(length)
		total += length
	var target := clampf(t, 0.0, 1.0) * total
	var walked := 0.0
	for index in range(lengths.size()):
		var length := lengths[index]
		if walked + length >= target:
			var local_t := 0.0 if length <= 0.0001 else (target - walked) / length
			return points[index].lerp(points[index + 1], local_t)
		walked += length
	return points[points.size() - 1]

func _polyline_tangent_at(points: Array[Vector2], sample: Vector2) -> Vector2:
	if points.size() < 2:
		return Vector2(0.0, 1.0)
	var best_index := 0
	var best_distance := INF
	for index in range(points.size() - 1):
		var a := points[index]
		var b := points[index + 1]
		var ab := b - a
		var length_sq := ab.length_squared()
		var closest := a
		if length_sq > 0.0001:
			var segment_t := clampf((sample - a).dot(ab) / length_sq, 0.0, 1.0)
			closest = a + ab * segment_t
		var distance := sample.distance_squared_to(closest)
		if distance < best_distance:
			best_distance = distance
			best_index = index
	return (points[best_index + 1] - points[best_index]).normalized()

func _prepare_pond_model(model: Node3D) -> void:
	model.scale.y *= 0.015
	_ground_model(model)
	model.position.y -= 0.035
	_set_model_shadow(model, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	for mesh_instance in _collect_mesh_instances(model):
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _add_floating_pond_petals(pond_root: Node3D, radius: Vector2) -> void:
	var petal_mat := StandardMaterial3D.new()
	petal_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	petal_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	petal_mat.albedo_color = Color(1.0, 0.70, 0.84, 0.66)
	petal_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var petal_mesh := _create_petal_mesh(Vector2(0.18, 0.095), petal_mat)

	var rng := RandomNumberGenerator.new()
	rng.seed = int(absf(pond_root.position.x * 97.0 + pond_root.position.z * 131.0)) + 5050
	var water_clusters: Array[Vector2] = []
	for i in range(4):
		var cluster_angle := rng.randf_range(0.0, TAU)
		var cluster_distance := sqrt(rng.randf()) * rng.randf_range(0.18, 0.72)
		water_clusters.append(Vector2(cos(cluster_angle) * radius.x * cluster_distance, sin(cluster_angle) * radius.y * cluster_distance))
	for i in range(36):
		var petal := MeshInstance3D.new()
		petal.name = "FloatingCherryPetal"
		petal.mesh = petal_mesh
		var point := Vector2.ZERO
		if rng.randf() < 0.78:
			var cluster := water_clusters[rng.randi_range(0, water_clusters.size() - 1)]
			var angle := rng.randf_range(0.0, TAU)
			var spread := rng.randf_range(0.18, 0.72) * pow(rng.randf(), 1.55)
			point = cluster + Vector2(cos(angle) * radius.x * 0.16, sin(angle) * radius.y * 0.16) * spread
		else:
			var angle := rng.randf_range(0.0, TAU)
			var distance := sqrt(rng.randf()) * rng.randf_range(0.10, 0.82)
			point = Vector2(cos(angle) * radius.x * distance, sin(angle) * radius.y * distance)
		petal.position = Vector3(point.x, 0.045 + rng.randf_range(0.0, 0.012), point.y)
		petal.rotation = Vector3(-PI * 0.5 + rng.randf_range(-0.08, 0.08), rng.randf_range(0.0, TAU), rng.randf_range(-0.04, 0.04))
		petal.scale = Vector3.ONE * rng.randf_range(0.75, 1.25)
		petal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pond_root.add_child(petal)

	for i in range(30):
		var petal := MeshInstance3D.new()
		petal.name = "GroundCherryPetal"
		petal.mesh = petal_mesh
		var angle := rng.randf_range(0.0, TAU)
		var edge_distance := rng.randf_range(0.98, 1.35)
		var cluster_pull := 0.0
		if rng.randf() < 0.62:
			cluster_pull = rng.randf_range(-0.18, 0.18)
		var ground_angle := angle + cluster_pull
		petal.position = Vector3(cos(ground_angle) * radius.x * edge_distance, 0.032 + rng.randf_range(0.0, 0.01), sin(ground_angle) * radius.y * edge_distance)
		petal.rotation = Vector3(-PI * 0.5 + rng.randf_range(-0.10, 0.10), rng.randf_range(0.0, TAU), rng.randf_range(-0.08, 0.08))
		petal.scale = Vector3.ONE * rng.randf_range(0.65, 1.12)
		petal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pond_root.add_child(petal)

func _create_ground_petals() -> void:
	var petal_mat := StandardMaterial3D.new()
	petal_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	petal_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	petal_mat.albedo_color = Color(1.0, 0.68, 0.82, 0.72)
	petal_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var petal_mesh := _create_petal_mesh(Vector2(0.22, 0.12), petal_mat)

	var rng := RandomNumberGenerator.new()
	rng.seed = 606060
	var clusters: Array[Vector2] = []
	for i in range(42):
		var r := field_radius * sqrt(rng.randf())
		var a := rng.randf_range(0.0, TAU)
		clusters.append(Vector2(cos(a) * r, sin(a) * r))

	for i in range(520):
		var point := Vector2.ZERO
		for retry in range(10):
			if clusters.size() > 0 and rng.randf() < 0.68:
				var cluster := clusters[rng.randi_range(0, clusters.size() - 1)]
				var angle := rng.randf_range(0.0, TAU)
				var distance := rng.randf_range(0.35, 4.4) * pow(rng.randf(), 1.7)
				point = cluster + Vector2(cos(angle), sin(angle)) * distance
			else:
				var r := field_radius * sqrt(rng.randf())
				var a := rng.randf_range(0.0, TAU)
				point = Vector2(cos(a) * r, sin(a) * r)
			if not _is_inside_pond(point.x, point.y, 0.55):
				break

		var petal := MeshInstance3D.new()
		petal.name = "GroundCherryPetal"
		petal.mesh = petal_mesh
		petal.position = Vector3(point.x, _height_at(point.x, point.y) + 0.045 + rng.randf_range(0.0, 0.014), point.y)
		petal.rotation = Vector3(-PI * 0.5 + rng.randf_range(-0.10, 0.10), rng.randf_range(0.0, TAU), rng.randf_range(-0.08, 0.08))
		petal.scale = Vector3.ONE * rng.randf_range(0.72, 1.38)
		petal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_mark_generated(petal)
		add_child(petal)

func _make_ellipse_disc_mesh(radius: Vector2, segments: int) -> ArrayMesh:
	var verts := PackedVector3Array([Vector3.ZERO])
	var normals := PackedVector3Array([Vector3.UP])
	var uvs := PackedVector2Array([Vector2(0.5, 0.5)])
	var indices := PackedInt32Array()

	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		verts.append(Vector3(cos(angle) * radius.x, 0.0, sin(angle) * radius.y))
		normals.append(Vector3.UP)
		uvs.append(Vector2(cos(angle) * 0.5 + 0.5, sin(angle) * 0.5 + 0.5))

	for i in range(segments):
		var next := 1 + ((i + 1) % segments)
		indices.append_array(PackedInt32Array([0, 1 + i, next]))

	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _make_ellipse_ring_mesh(outer_radius: Vector2, inner_radius: Vector2, segments: int) -> ArrayMesh:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		var dir := Vector2(cos(angle), sin(angle))
		verts.append(Vector3(dir.x * outer_radius.x, 0.0, dir.y * outer_radius.y))
		verts.append(Vector3(dir.x * inner_radius.x, 0.0, dir.y * inner_radius.y))
		normals.append_array(PackedVector3Array([Vector3.UP, Vector3.UP]))
		uvs.append_array(PackedVector2Array([Vector2(0.0, float(i) / segments), Vector2(1.0, float(i) / segments)]))

	for i in range(segments):
		var outer_a := i * 2
		var inner_a := outer_a + 1
		var outer_b := ((i + 1) % segments) * 2
		var inner_b := outer_b + 1
		indices.append_array(PackedInt32Array([outer_a, inner_a, outer_b, outer_b, inner_a, inner_b]))

	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _make_grass_clump_mesh() -> ArrayMesh:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var blade_data := [
		[0.00, 0.00, 0.00, 0.34, 1.06, 0.12],
		[0.09, 0.03, 0.82, 0.28, 0.82, 0.09],
		[-0.08, -0.02, -0.72, 0.29, 0.94, 0.11],
		[0.04, -0.10, 1.68, 0.24, 0.74, 0.08],
		[-0.05, 0.09, 2.34, 0.26, 0.88, 0.10],
		[0.14, -0.05, 2.86, 0.22, 0.78, 0.07],
		[-0.15, 0.05, -1.82, 0.23, 0.86, 0.09],
		[0.03, 0.15, -2.48, 0.21, 0.72, 0.07],
	]

	for blade in blade_data:
		var base := Vector3(float(blade[0]), 0.0, float(blade[1]))
		var angle: float = float(blade[2])
		var width: float = float(blade[3])
		var height: float = float(blade[4])
		var lean: float = float(blade[5])
		var right := Vector3(cos(angle), 0.0, sin(angle)) * width * 0.5
		var forward := Vector3(-sin(angle), 0.0, cos(angle))
		var mid := base + forward * lean + Vector3(0.0, height * 0.54, 0.0)
		var tip := base + forward * lean * 1.45 + Vector3(0.0, height, 0.0)
		var start := verts.size()
		verts.append(base - right)
		verts.append(base + right)
		verts.append(mid + right * 0.58)
		verts.append(tip + right * 0.18)
		verts.append(tip - right * 0.18)
		verts.append(mid - right * 0.58)
		uvs.append(Vector2(0.0, 0.0))
		uvs.append(Vector2(1.0, 0.0))
		uvs.append(Vector2(1.0, 0.52))
		uvs.append(Vector2(0.68, 1.0))
		uvs.append(Vector2(0.32, 1.0))
		uvs.append(Vector2(0.0, 0.52))
		normals.append_array(PackedVector3Array([Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP]))
		indices.append_array(PackedInt32Array([start, start + 1, start + 2, start, start + 2, start + 5, start + 5, start + 2, start + 3, start + 5, start + 3, start + 4]))

	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _create_background_trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1212
	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.56, 0.51, 0.42)
	var leaf_mat := StandardMaterial3D.new()
	leaf_mat.albedo_color = Color(0.66, 0.74, 0.64)
	leaf_mat.roughness = 0.95

	for i in range(72):
		var a := rng.randf_range(0.0, TAU)
		var r := rng.randf_range(82.0, 122.0)
		var pos := Vector3(cos(a) * r, 0.0, sin(a) * r)
		pos.y = _height_at(pos.x, pos.z)
		var tree := Node3D.new()
		tree.name = "DistantLowPolyTree"
		tree.position = pos
		tree.rotation.y = rng.randf_range(0.0, TAU)
		tree.scale = Vector3.ONE * rng.randf_range(0.68, 1.55)
		_mark_generated(tree)
		add_child(tree)

		var trunk := MeshInstance3D.new()
		var trunk_mesh := CylinderMesh.new()
		trunk_mesh.top_radius = 0.18
		trunk_mesh.bottom_radius = 0.26
		trunk_mesh.height = 2.1
		trunk_mesh.radial_segments = 6
		trunk.mesh = trunk_mesh
		trunk.position.y = 1.05
		trunk.material_override = trunk_mat
		tree.add_child(trunk)

		var crown := MeshInstance3D.new()
		var crown_mesh := CylinderMesh.new()
		crown_mesh.bottom_radius = rng.randf_range(1.35, 2.15)
		crown_mesh.top_radius = 0.0
		crown_mesh.height = rng.randf_range(3.5, 5.2)
		crown_mesh.radial_segments = 7
		crown.mesh = crown_mesh
		crown.position.y = 3.15
		crown.material_override = leaf_mat
		tree.add_child(crown)

	for i in range(44):
		var a := TAU * float(i) / 44.0 + rng.randf_range(-0.035, 0.035)
		var r := rng.randf_range(128.0, 150.0)
		var pos := Vector3(cos(a) * r, 0.0, sin(a) * r)
		pos.y = _height_at(pos.x, pos.z)
		var tree := Node3D.new()
		tree.name = "FarHorizonTreeLine"
		tree.position = pos
		tree.rotation.y = rng.randf_range(0.0, TAU)
		tree.scale = Vector3.ONE * rng.randf_range(1.05, 2.45)
		_mark_generated(tree)
		add_child(tree)

		var crown := MeshInstance3D.new()
		var crown_mesh := CylinderMesh.new()
		crown_mesh.bottom_radius = rng.randf_range(1.6, 2.4)
		crown_mesh.top_radius = 0.0
		crown_mesh.height = rng.randf_range(5.4, 7.2)
		crown_mesh.radial_segments = 6
		crown.mesh = crown_mesh
		crown.position.y = crown_mesh.height * 0.48
		crown.material_override = leaf_mat
		tree.add_child(crown)

func _create_asset_trees() -> void:
	var scene := load(TREE_SCENE_PATH)
	if not scene is PackedScene:
		push_warning("Could not load tree model: %s" % TREE_SCENE_PATH)
		return

	var tree_points := [
		Vector3(-8.5, 0.0, -10.5),
		Vector3(10.5, 0.0, -12.0),
		Vector3(-16.0, 0.0, 3.5),
		Vector3(15.0, 0.0, 5.5),
		Vector3(-5.0, 0.0, 15.0),
		Vector3(18.0, 0.0, -2.0),
		Vector3(-14.0, 0.0, 27.0),
		Vector3(-24.0, 0.0, 34.0),
		Vector3(20.0, 0.0, 35.0),
		Vector3(34.0, 0.0, 22.0),
		Vector3(-36.0, 0.0, 8.0),
		Vector3(42.0, 0.0, -4.0),
		Vector3(-30.0, 0.0, -26.0),
		Vector3(17.0, 0.0, -38.0),
		Vector3(50.0, 0.0, 39.0),
		Vector3(-52.0, 0.0, 40.0),
		Vector3(55.0, 0.0, -30.0),
		Vector3(-48.0, 0.0, -44.0),
	]

	var rng := RandomNumberGenerator.new()
	rng.seed = 9090
	for index in range(tree_points.size()):
		var point: Vector3 = tree_points[index]
		if _should_skip_asset_tree(point):
			continue
		if _is_inside_pond(point.x, point.z, 5.5):
			continue
		var tree := Node3D.new()
		tree.name = "WindTree"
		tree.position = Vector3(point.x, _height_at(point.x, point.z), point.z)
		tree.rotation.y = rng.randf_range(0.0, TAU)
		_mark_generated(tree)
		add_child(tree)

		var model := scene.instantiate() as Node3D
		if model == null:
			continue
		model.name = "TreeModel"
		tree.add_child(model)
		var target_height := rng.randf_range(4.2, 8.8)
		if index < 6:
			target_height = [4.4, 7.9, 5.3, 8.5, 6.1, 4.8][index]
		_fit_model_to_height(model, target_height)
		_ground_model(model)
		_set_model_shadow(model, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)

		_wind_trees.append({
			"node": tree,
			"base_rotation": tree.rotation,
			"phase": rng.randf_range(0.0, TAU),
			"strength": rng.randf_range(0.018, 0.038),
			"speed": rng.randf_range(0.75, 1.15),
			"shake_time": 0.0,
			"shake_axis": Vector2.ZERO,
			"shake_phase": rng.randf_range(0.0, TAU),
		})
		_add_tree_blocker(tree.position, TREE_BLOCKER_RADIUS, _wind_trees.size() - 1)

func _should_skip_asset_tree(point: Vector3) -> bool:
	if not _chapter_one_active:
		return false
	var point_2d := Vector2(point.x, point.z)
	var house_point := Vector2(CHAPTER_ONE_HOUSE_POSITION.x, CHAPTER_ONE_HOUSE_POSITION.z)
	return point_2d.distance_squared_to(house_point) <= CHAPTER_ONE_HOUSE_TREE_CLEAR_RADIUS * CHAPTER_ONE_HOUSE_TREE_CLEAR_RADIUS

func _update_tree_wind(delta: float) -> void:
	var time := Time.get_ticks_msec() * 0.001
	for tree_data in _wind_trees:
		var tree := tree_data["node"] as Node3D
		if tree == null:
			continue
		var base_rotation: Vector3 = tree_data["base_rotation"]
		var phase: float = tree_data["phase"]
		var strength: float = tree_data["strength"]
		var speed: float = tree_data["speed"]
		var gust := sin(time * speed + phase)
		var secondary := sin(time * speed * 1.73 + phase * 0.7) * 0.35
		var wind_rotation := Vector3(strength * (gust + secondary), 0.0, strength * 0.42 * sin(time * speed * 1.21 + phase))
		var shake_rotation := Vector3.ZERO
		var shake_time: float = tree_data["shake_time"]
		if shake_time > 0.0:
			shake_time = maxf(shake_time - delta, 0.0)
			tree_data["shake_time"] = shake_time
			var shake_axis: Vector2 = tree_data["shake_axis"]
			if shake_axis.length_squared() > 0.0001:
				var falloff := shake_time / TREE_SHAKE_DURATION
				var pulse := sin((TREE_SHAKE_DURATION - shake_time) * TREE_SHAKE_FREQUENCY + float(tree_data["shake_phase"]))
				var amount := TREE_SHAKE_STRENGTH * falloff * pulse
				shake_rotation = Vector3(shake_axis.y * amount, 0.0, -shake_axis.x * amount)
		tree.rotation = base_rotation + wind_rotation + shake_rotation

func _create_player() -> void:
	var scene := load(PLAYER_SCENE_PATH)
	if not scene is PackedScene:
		push_warning("Could not load player scene: %s" % PLAYER_SCENE_PATH)
		return

	_player = scene.instantiate() as Node3D
	if _player == null:
		return
	_player.name = "Player"
	_player.add_to_group("player")
	_player.position = Vector3(PLAYER_START.x, _height_at(PLAYER_START.x, PLAYER_START.z) + 0.04, PLAYER_START.z)
	_mark_generated(_player)
	add_child(_player)

func _create_chapter_one_player() -> void:
	var scene := load(PLAYER_SCENE_PATH)
	if not scene is PackedScene:
		push_warning("Could not load player scene: %s" % PLAYER_SCENE_PATH)
		return

	_player = scene.instantiate() as Node3D
	if _player == null:
		return
	_player.name = "Player"
	_player.add_to_group("player")
	_player.position = Vector3(CHAPTER_ONE_PLAYER_START.x, _height_at(CHAPTER_ONE_PLAYER_START.x, CHAPTER_ONE_PLAYER_START.z) + 0.04, CHAPTER_ONE_PLAYER_START.z)
	_player.rotation.y = 0.0
	var visual_root := _player.get_node_or_null("VisualRoot") as Node3D
	if visual_root != null:
		visual_root.rotation.y = _yaw_toward(_player.position, CHAPTER_ONE_HOUSE_POSITION)
	_mark_generated(_player)
	add_child(_player)

func _create_chapter_one_village_house() -> void:
	var scene := load(VILLAGE_HOUSE_SCENE_PATH)
	if not scene is PackedScene:
		push_warning("Could not load village house model: %s" % VILLAGE_HOUSE_SCENE_PATH)
		return

	var house := Node3D.new()
	house.name = "ChapterOneVillageHouse"
	house.position = Vector3(CHAPTER_ONE_HOUSE_POSITION.x, _height_at(CHAPTER_ONE_HOUSE_POSITION.x, CHAPTER_ONE_HOUSE_POSITION.z), CHAPTER_ONE_HOUSE_POSITION.z)
	house.rotation.y = deg_to_rad(CHAPTER_ONE_HOUSE_YAW)
	_mark_generated(house)
	add_child(house)

	var model := scene.instantiate() as Node3D
	if model == null:
		return
	model.name = "VillageHouseModel"
	house.add_child(model)
	_fit_model_to_footprint_length(model, CHAPTER_ONE_HOUSE_TARGET_LENGTH)
	_ground_model(model)
	_set_model_shadow(model, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	_add_model_box_blocker(house, model, Vector2.ZERO, 0.56)

func _create_house_interior() -> void:
	var root := Node3D.new()
	root.name = "HouseInteriorRoot"
	root.position = Vector3.ZERO
	root.visible = false
	_house_interior_root = root
	_mark_generated(root)
	add_child(root)

	var floor_mat := _make_material(Color(0.78, 0.55, 0.31), 0.88)
	var wall_mat := _make_material(Color(0.93, 0.86, 0.70), 0.9)
	var trim_mat := _make_material(Color(0.56, 0.36, 0.18), 0.86)
	var glass_mat := _make_glass_material(Color(0.68, 0.90, 1.0, 0.34))
	var door_mat := _make_material(Color(0.62, 0.40, 0.22), 0.84)

	var center := HOUSE_INTERIOR_CENTER
	var half := HOUSE_INTERIOR_SIZE * 0.5
	var floor_y := HOUSE_INTERIOR_FLOOR_Y
	_create_box_mesh(root, "InteriorFloor", Vector3(center.x, floor_y - 0.04, center.z), Vector3(HOUSE_INTERIOR_SIZE.x, 0.08, HOUSE_INTERIOR_SIZE.y), floor_mat)
	for i in range(1, 7):
		var z := center.z - half.y + HOUSE_INTERIOR_SIZE.y * float(i) / 7.0
		_create_box_mesh(root, "InteriorFloorSeam", Vector3(center.x, floor_y + 0.012, z), Vector3(HOUSE_INTERIOR_SIZE.x - 0.35, 0.018, 0.035), trim_mat)

	var wall_h := 4.8
	var wall_t := 0.26
	var wall_y := floor_y + wall_h * 0.5
	var door_w := 2.2
	var door_h := 2.25
	var window_w := 2.15
	var window_h := 1.15
	var window_y := floor_y + 1.65
	var window_z := center.z

	_create_box_mesh(root, "InteriorBackWall", Vector3(center.x, wall_y, center.z - half.y), Vector3(HOUSE_INTERIOR_SIZE.x, wall_h, wall_t), wall_mat)
	_create_box_mesh(root, "InteriorFrontWallLeft", Vector3(center.x - (half.x + door_w * 0.5) * 0.5, wall_y, center.z + half.y), Vector3(half.x - door_w * 0.5, wall_h, wall_t), wall_mat)
	_create_box_mesh(root, "InteriorFrontWallRight", Vector3(center.x + (half.x + door_w * 0.5) * 0.5, wall_y, center.z + half.y), Vector3(half.x - door_w * 0.5, wall_h, wall_t), wall_mat)
	_create_box_mesh(root, "InteriorFrontWallTop", Vector3(center.x, floor_y + door_h + (wall_h - door_h) * 0.5, center.z + half.y), Vector3(door_w, wall_h - door_h, wall_t), wall_mat)
	_create_box_mesh(root, "InteriorLeftWall", Vector3(center.x - half.x, wall_y, center.z), Vector3(wall_t, wall_h, HOUSE_INTERIOR_SIZE.y), wall_mat)
	var right_wall_segment_depth := maxf((HOUSE_INTERIOR_SIZE.y - window_w) * 0.5, 0.1)
	_create_box_mesh(root, "InteriorRightWallFront", Vector3(center.x + half.x, wall_y, window_z + window_w * 0.5 + right_wall_segment_depth * 0.5), Vector3(wall_t, wall_h, right_wall_segment_depth), wall_mat)
	_create_box_mesh(root, "InteriorRightWallBack", Vector3(center.x + half.x, wall_y, window_z - window_w * 0.5 - right_wall_segment_depth * 0.5), Vector3(wall_t, wall_h, right_wall_segment_depth), wall_mat)
	_create_box_mesh(root, "InteriorRightWallUnderWindow", Vector3(center.x + half.x, floor_y + (window_y - window_h * 0.5 - floor_y) * 0.5, window_z), Vector3(wall_t, window_y - window_h * 0.5 - floor_y, window_w), wall_mat)
	_create_box_mesh(root, "InteriorRightWallOverWindow", Vector3(center.x + half.x, window_y + window_h * 0.5 + (floor_y + wall_h - window_y - window_h * 0.5) * 0.5, window_z), Vector3(wall_t, floor_y + wall_h - window_y - window_h * 0.5, window_w), wall_mat)

	_create_box_mesh(root, "InteriorDoor", Vector3(center.x, floor_y + door_h * 0.5, center.z + half.y + 0.04), Vector3(door_w * 0.82, door_h, 0.08), door_mat)
	_create_box_mesh(root, "InteriorDoorFrameTop", Vector3(center.x, floor_y + door_h + 0.12, center.z + half.y + 0.02), Vector3(door_w + 0.4, 0.24, 0.18), trim_mat)
	_create_box_mesh(root, "InteriorDoorFrameLeft", Vector3(center.x - door_w * 0.5 - 0.13, floor_y + door_h * 0.5, center.z + half.y + 0.02), Vector3(0.24, door_h, 0.18), trim_mat)
	_create_box_mesh(root, "InteriorDoorFrameRight", Vector3(center.x + door_w * 0.5 + 0.13, floor_y + door_h * 0.5, center.z + half.y + 0.02), Vector3(0.24, door_h, 0.18), trim_mat)

	_create_box_mesh(root, "InteriorWindowPane", Vector3(center.x + half.x + 0.012, window_y, window_z), Vector3(0.035, window_h, window_w), glass_mat)
	_create_box_mesh(root, "InteriorWindowFrameVertical", Vector3(center.x + half.x + 0.035, window_y, window_z), Vector3(0.08, window_h + 0.24, 0.10), trim_mat)
	_create_box_mesh(root, "InteriorWindowFrameTop", Vector3(center.x + half.x + 0.035, window_y + window_h * 0.5 + 0.08, window_z), Vector3(0.08, 0.12, window_w + 0.28), trim_mat)
	_create_box_mesh(root, "InteriorWindowFrameBottom", Vector3(center.x + half.x + 0.035, window_y - window_h * 0.5 - 0.08, window_z), Vector3(0.08, 0.12, window_w + 0.28), trim_mat)
	_create_box_mesh(root, "InteriorWindowFrameBack", Vector3(center.x + half.x + 0.035, window_y, window_z - window_w * 0.5 - 0.08), Vector3(0.08, window_h + 0.24, 0.12), trim_mat)
	_create_box_mesh(root, "InteriorWindowFrameFront", Vector3(center.x + half.x + 0.035, window_y, window_z + window_w * 0.5 + 0.08), Vector3(0.08, window_h + 0.24, 0.12), trim_mat)

	_add_box_blocker(Vector3(center.x, floor_y, center.z - half.y), 0.0, Vector2(half.x, 0.38), true)
	_add_box_blocker(Vector3(center.x - half.x, floor_y, center.z), 0.0, Vector2(0.38, half.y), true)
	_add_box_blocker(Vector3(center.x + half.x, floor_y, center.z), 0.0, Vector2(0.38, half.y), true)
	_add_box_blocker(Vector3(center.x - 4.2, floor_y, center.z + half.y), 0.0, Vector2(1.85, 0.38), true)
	_add_box_blocker(Vector3(center.x + 4.2, floor_y, center.z + half.y), 0.0, Vector2(1.85, 0.38), true)
	_create_food_chests(root)

func _create_food_chests(root: Node3D) -> void:
	_food_chest_nodes.clear()
	var chest_root := _create_food_chest_model(root, "FoodChest", FOOD_CHEST_A_POSITION)
	_food_chest_nodes.append(chest_root)
	_add_box_blocker(FOOD_CHEST_A_POSITION, 0.0, Vector2(0.8, 0.58), true)

func _create_food_chest_model(parent: Node3D, root_name: String, position: Vector3, preview: bool = false) -> Node3D:
	var chest_root := Node3D.new()
	chest_root.name = root_name
	chest_root.position = position
	parent.add_child(chest_root)
	var scene := load(FOOD_CHEST_SCENE_PATH)
	if scene is PackedScene:
		var model := scene.instantiate() as Node3D
		if model != null:
			model.name = "FoodChestModel"
			chest_root.add_child(model)
			_fit_model_to_max_dimension(model, 1.25)
			_center_model_on_origin(model)
			_ground_model(model)
			_set_model_shadow(model, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
			if preview:
				for mesh in _collect_mesh_instances(model):
					var mat := StandardMaterial3D.new()
					mat.albedo_color = Color(0.78, 0.72, 0.56, 0.42)
					mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
					mesh.material_override = mat
			return chest_root
	var alpha := 0.42 if preview else 1.0
	var fallback_mat := _make_material(Color(0.52, 0.31, 0.14, alpha), 0.82)
	if preview:
		fallback_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		fallback_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_create_box_mesh(chest_root, "ChestBody", Vector3.ZERO, Vector3(1.05, 0.64, 0.72), fallback_mat)
	return chest_root

func _create_box_mesh(parent: Node3D, mesh_name: String, position: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = mesh_name
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.material_override = material
	mesh_instance.position = position
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh_instance)
	return mesh_instance

func _make_material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material

func _make_glass_material(color: Color) -> StandardMaterial3D:
	var material := _make_material(color, 0.18)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.alpha_antialiasing_mode = BaseMaterial3D.ALPHA_ANTIALIASING_ALPHA_TO_COVERAGE
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	return material

func _create_chapter_one_rebas() -> void:
	var scene := load(REBAS_SCENE_PATH)
	if not scene is PackedScene:
		push_warning("Could not load Rebas model: %s" % REBAS_SCENE_PATH)
		return

	var rebas := Node3D.new()
	rebas.name = "RebasCant"
	rebas.position = Vector3(CHAPTER_ONE_REBAS_POSITION.x, _height_at(CHAPTER_ONE_REBAS_POSITION.x, CHAPTER_ONE_REBAS_POSITION.z), CHAPTER_ONE_REBAS_POSITION.z)
	rebas.rotation.y = _yaw_toward(rebas.position, CHAPTER_ONE_PLAYER_START)
	_rebas = rebas
	_mark_generated(rebas)
	add_child(rebas)

	var model := scene.instantiate() as Node3D
	if model == null:
		return
	model.name = "RebasCantModel"
	_rebas_model = model
	rebas.add_child(model)
	_fit_model_to_height(model, CHAPTER_ONE_REBAS_TARGET_HEIGHT)
	_ground_model(model)
	_set_model_shadow(model, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	_add_circle_blocker(rebas.position, 1.0)
	_create_rebas_exclamation()

func _create_chapter_one_mom() -> void:
	_create_mom(CHAPTER_ONE_MOM_POSITION, CHAPTER_ONE_PLAYER_START)

func _create_camper(camper_position: Vector3 = CAMPER_POSITION, camper_yaw: float = deg_to_rad(162.0)) -> void:
	var scene := load(CAMPER_SCENE_PATH)
	if not scene is PackedScene:
		push_warning("Could not load camper model: %s" % CAMPER_SCENE_PATH)
		return

	var camper := Node3D.new()
	camper.name = "CamperVan"
	camper.position = Vector3(camper_position.x, _height_at(camper_position.x, camper_position.z), camper_position.z)
	camper.rotation.y = camper_yaw
	_camper = camper
	_mark_generated(camper)
	add_child(camper)

	var model := scene.instantiate() as Node3D
	if model == null:
		return
	model.name = "CamperModel"
	_camper_model = model
	camper.add_child(model)
	_fit_model_to_footprint_length(model, CAMPER_TARGET_LENGTH)
	_ground_model(model)
	_set_model_shadow(model, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	_add_camper_blocker(camper, model)

func _create_mom(mom_position: Vector3 = MOM_POSITION, face_target: Vector3 = PLAYER_START) -> void:
	var scene := load(MOM_SCENE_PATH)
	if not scene is PackedScene:
		push_warning("Could not load mom model: %s" % MOM_SCENE_PATH)
		return

	var mom := Node3D.new()
	mom.name = "Mom"
	mom.position = Vector3(mom_position.x, _height_at(mom_position.x, mom_position.z), mom_position.z)
	mom.rotation.y = _yaw_toward(mom.position, face_target) + MOM_FACE_PLAYER_OFFSET
	_mom = mom
	_mark_generated(mom)
	add_child(mom)

	var model := scene.instantiate() as Node3D
	if model == null:
		return
	model.name = "MomModel"
	model.scale = Vector3.ONE * MOM_MODEL_SCALE
	_mom_model = model
	mom.add_child(model)
	_ground_model(model)
	_set_model_shadow(model, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	_add_circle_blocker(mom.position, MOM_BLOCKER_RADIUS)
	_create_mom_exclamation()

func _create_mom_exclamation() -> void:
	if _mom == null:
		return
	var marker := Label3D.new()
	marker.name = "QuestExclamation"
	marker.text = "!"
	marker.position = Vector3(0.0, 3.28, 0.0)
	marker.font_size = 150
	marker.outline_size = 22
	marker.modulate = Color(1.0, 0.82, 0.24, 1.0)
	marker.outline_modulate = Color(0.56, 0.36, 0.10, 1.0)
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.no_depth_test = true
	marker.visible = _should_show_mom_exclamation()
	_mom_exclamation = marker
	_mom.add_child(marker)

func _create_rebas_exclamation() -> void:
	if _rebas == null:
		return
	var marker := Label3D.new()
	marker.name = "ShopExclamation"
	marker.text = "!"
	marker.position = Vector3(0.0, 3.36, 0.0)
	marker.font_size = 140
	marker.outline_size = 20
	marker.modulate = Color(1.0, 0.82, 0.24, 1.0)
	marker.outline_modulate = Color(0.56, 0.36, 0.10, 1.0)
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.no_depth_test = true
	marker.visible = _should_show_rebas_exclamation()
	_rebas_exclamation = marker
	_rebas.add_child(marker)

func _create_dialogue_ui() -> void:
	_dialogue_steps = _build_mom_dialogue()
	_highlight_material = StandardMaterial3D.new()
	_highlight_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_highlight_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_highlight_material.albedo_color = Color(1.0, 1.0, 1.0, 0.34)

	_dialogue_layer = CanvasLayer.new()
	_dialogue_layer.name = "DialogueLayer"
	_mark_generated(_dialogue_layer)
	add_child(_dialogue_layer)

	var root := Control.new()
	root.name = "DialogueRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialogue_layer.add_child(root)
	_hud_root = root

	_interaction_prompt = PanelContainer.new()
	_interaction_prompt.name = "InteractionPrompt"
	_interaction_prompt.visible = false
	_interaction_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_interaction_prompt.anchor_left = 1.0
	_interaction_prompt.anchor_top = 1.0
	_interaction_prompt.anchor_right = 1.0
	_interaction_prompt.anchor_bottom = 1.0
	_interaction_prompt.offset_left = -500.0
	_interaction_prompt.offset_top = -146.0
	_interaction_prompt.offset_right = -24.0
	_interaction_prompt.offset_bottom = -92.0
	_interaction_prompt.add_theme_stylebox_override("panel", _make_round_style(Color(0.92, 0.84, 0.62, 0.94), Color(1.0, 0.95, 0.78, 1.0), 20.0, 1))
	root.add_child(_interaction_prompt)

	_interaction_prompt_label = Label.new()
	_interaction_prompt_label.text = "F / 点击  与安提莉尔对话"
	_interaction_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_interaction_prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_interaction_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_interaction_prompt_label.add_theme_color_override("font_color", Color(0.24, 0.18, 0.10))
	_interaction_prompt_label.add_theme_font_size_override("font_size", 18)
	_interaction_prompt.add_child(_interaction_prompt_label)

	_create_pickup_feed(root)
	_create_held_crop_quality_panel(root)
	_create_post_tutorial_objective(root)

	_dialogue_panel = Control.new()
	_dialogue_panel.name = "DialoguePanel"
	_dialogue_panel.visible = false
	_dialogue_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dialogue_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_dialogue_panel.gui_input.connect(_on_dialogue_panel_gui_input)
	root.add_child(_dialogue_panel)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.18)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialogue_panel.add_child(dim)

	var box := TextureRect.new()
	box.name = "DialogueBox"
	box.texture = load(DIALOGUE_BOX_PATH)
	box.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	box.stretch_mode = TextureRect.STRETCH_SCALE
	box.anchor_left = 0.04
	box.anchor_top = 1.0
	box.anchor_right = 0.96
	box.anchor_bottom = 1.0
	box.offset_top = -285.0
	box.offset_bottom = -28.0
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialogue_panel.add_child(box)

	_dialogue_portrait = TextureRect.new()
	_dialogue_portrait.name = "Portrait"
	_dialogue_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_dialogue_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_dialogue_portrait.anchor_left = 0.055
	_dialogue_portrait.anchor_top = 1.0
	_dialogue_portrait.anchor_right = 0.285
	_dialogue_portrait.anchor_bottom = 1.0
	_dialogue_portrait.offset_top = -272.0
	_dialogue_portrait.offset_bottom = -30.0
	_dialogue_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialogue_panel.add_child(_dialogue_portrait)

	_dialogue_name = Label.new()
	_dialogue_name.anchor_left = 0.31
	_dialogue_name.anchor_top = 1.0
	_dialogue_name.anchor_right = 0.90
	_dialogue_name.anchor_bottom = 1.0
	_dialogue_name.offset_top = -238.0
	_dialogue_name.offset_bottom = -200.0
	_dialogue_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialogue_name.add_theme_color_override("font_color", Color(0.18, 0.13, 0.08))
	_dialogue_name.add_theme_font_size_override("font_size", 26)
	_dialogue_panel.add_child(_dialogue_name)

	_dialogue_body = Label.new()
	_dialogue_body.anchor_left = 0.31
	_dialogue_body.anchor_top = 1.0
	_dialogue_body.anchor_right = 0.90
	_dialogue_body.anchor_bottom = 1.0
	_dialogue_body.offset_top = -196.0
	_dialogue_body.offset_bottom = -58.0
	_dialogue_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialogue_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_body.add_theme_color_override("font_color", Color(0.24, 0.18, 0.12))
	_dialogue_body.add_theme_font_size_override("font_size", 22)
	_dialogue_panel.add_child(_dialogue_body)

	_dialogue_options = VBoxContainer.new()
	_dialogue_options.name = "Options"
	_dialogue_options.anchor_left = 0.34
	_dialogue_options.anchor_top = 0.30
	_dialogue_options.anchor_right = 0.64
	_dialogue_options.anchor_bottom = 0.30
	_dialogue_options.offset_top = 0.0
	_dialogue_options.offset_bottom = 170.0
	_dialogue_options.alignment = BoxContainer.ALIGNMENT_CENTER
	_dialogue_options.add_theme_constant_override("separation", 8)
	_dialogue_panel.add_child(_dialogue_options)

	var skip_button := Button.new()
	skip_button.text = "跳过"
	skip_button.anchor_left = 0.84
	skip_button.anchor_top = 1.0
	skip_button.anchor_right = 0.92
	skip_button.anchor_bottom = 1.0
	skip_button.offset_top = -270.0
	skip_button.offset_bottom = -228.0
	skip_button.add_theme_font_size_override("font_size", 18)
	skip_button.add_theme_color_override("font_color", Color(0.25, 0.18, 0.10))
	skip_button.add_theme_stylebox_override("normal", _make_round_style(Color(0.96, 0.87, 0.66, 0.94), Color(0.58, 0.42, 0.20, 0.42), 20.0, 1))
	skip_button.add_theme_stylebox_override("hover", _make_round_style(Color(1.0, 0.91, 0.70, 1.0), Color(0.58, 0.42, 0.20, 0.60), 20.0, 1))
	skip_button.pressed.connect(_skip_mom_dialogue)
	_dialogue_panel.add_child(skip_button)

	_create_map_popup(root)
	_create_rebas_shop(root)
	_create_food_chest_inventory_panel(root)
	_create_kitchen_equipment_ui(root)
	_create_kitchen_status_ui(root)
	_create_inventory_bar(root)
	_create_crop_throw_charge_bar(root)

func _create_pickup_feed(root: Control) -> void:
	_pickup_feed = VBoxContainer.new()
	_pickup_feed.name = "PickupFeed"
	_pickup_feed.anchor_left = 0.02
	_pickup_feed.anchor_top = 0.18
	_pickup_feed.anchor_right = 0.28
	_pickup_feed.anchor_bottom = 0.48
	_pickup_feed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pickup_feed.add_theme_constant_override("separation", 6)
	root.add_child(_pickup_feed)

func _create_kitchen_equipment_ui(root: Control) -> void:
	_kitchen_equipment_panel = PanelContainer.new()
	_kitchen_equipment_panel.name = "KitchenEquipmentPanel"
	_kitchen_equipment_panel.visible = false
	_kitchen_equipment_panel.anchor_left = 1.0
	_kitchen_equipment_panel.anchor_top = 0.18
	_kitchen_equipment_panel.anchor_right = 1.0
	_kitchen_equipment_panel.anchor_bottom = 0.82
	_kitchen_equipment_panel.offset_left = -210.0
	_kitchen_equipment_panel.offset_right = -18.0
	_kitchen_equipment_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_kitchen_equipment_panel.add_theme_stylebox_override("panel", _make_round_style(Color(0.92, 0.84, 0.62, 0.94), Color(1.0, 0.95, 0.78, 1.0), 14.0, 1))
	root.add_child(_kitchen_equipment_panel)

	var box := VBoxContainer.new()
	box.name = "EquipmentList"
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 12.0
	box.offset_top = 12.0
	box.offset_right = -12.0
	box.offset_bottom = -12.0
	box.add_theme_constant_override("separation", 8)
	_kitchen_equipment_panel.add_child(box)

	var title := Label.new()
	title.text = "鎴胯溅璁惧"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.24, 0.17, 0.09))
	box.add_child(title)

	for equipment in KITCHEN_EQUIPMENT_TYPES:
		var button := Button.new()
		button.text = str(equipment.get("name", "设备"))
		button.custom_minimum_size = Vector2(160.0, 38.0)
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 17)
		button.add_theme_color_override("font_color", Color(0.25, 0.18, 0.10))
		button.add_theme_stylebox_override("normal", _make_round_style(Color(0.98, 0.88, 0.64, 0.94), Color(0.65, 0.48, 0.24, 0.40), 10.0, 1))
		button.add_theme_stylebox_override("hover", _make_round_style(Color(1.0, 0.92, 0.70, 1.0), Color(0.65, 0.48, 0.24, 0.65), 10.0, 1))
		button.pressed.connect(_start_kitchen_equipment_placement.bind(str(equipment.get("id", ""))))
		box.add_child(button)

	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.custom_minimum_size = Vector2(160.0, 36.0)
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(_close_kitchen_equipment_panel)
	box.add_child(close_button)

func _create_kitchen_status_ui(root: Control) -> void:
	_kitchen_status_panel = PanelContainer.new()
	_kitchen_status_panel.name = "KitchenStatusPanel"
	_kitchen_status_panel.visible = false
	_kitchen_status_panel.anchor_left = 0.02
	_kitchen_status_panel.anchor_top = 0.02
	_kitchen_status_panel.anchor_right = 0.38
	_kitchen_status_panel.anchor_bottom = 0.02
	_kitchen_status_panel.offset_bottom = 126.0
	_kitchen_status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_kitchen_status_panel.add_theme_stylebox_override("panel", _make_round_style(Color(0.92, 0.84, 0.62, 0.92), Color(1.0, 0.95, 0.78, 1.0), 12.0, 1))
	root.add_child(_kitchen_status_panel)

	_kitchen_status_label = Label.new()
	_kitchen_status_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_kitchen_status_label.offset_left = 12.0
	_kitchen_status_label.offset_top = 8.0
	_kitchen_status_label.offset_right = -12.0
	_kitchen_status_label.offset_bottom = -8.0
	_kitchen_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_kitchen_status_label.add_theme_font_size_override("font_size", 16)
	_kitchen_status_label.add_theme_color_override("font_color", Color(0.22, 0.15, 0.08))
	_kitchen_status_panel.add_child(_kitchen_status_label)

func _create_held_crop_quality_panel(root: Control) -> void:
	_held_crop_quality_panel = PanelContainer.new()
	_held_crop_quality_panel.name = "HeldCropQualityPanel"
	_held_crop_quality_panel.visible = false
	_held_crop_quality_panel.anchor_left = 0.0
	_held_crop_quality_panel.anchor_top = 0.0
	_held_crop_quality_panel.anchor_right = 0.0
	_held_crop_quality_panel.anchor_bottom = 0.0
	_held_crop_quality_panel.offset_left = 18.0
	_held_crop_quality_panel.offset_top = 18.0
	_held_crop_quality_panel.offset_right = 258.0
	_held_crop_quality_panel.offset_bottom = 62.0
	_held_crop_quality_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_held_crop_quality_panel.add_theme_stylebox_override("panel", _make_round_style(Color(0.92, 0.80, 0.56, 0.90), Color(1.0, 0.95, 0.72, 0.96), 12.0, 1))
	root.add_child(_held_crop_quality_panel)

	_held_crop_quality_label = Label.new()
	_held_crop_quality_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_held_crop_quality_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_held_crop_quality_label.add_theme_font_size_override("font_size", 18)
	_held_crop_quality_label.add_theme_color_override("font_color", Color(0.25, 0.17, 0.08))
	_held_crop_quality_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_held_crop_quality_panel.add_child(_held_crop_quality_label)

func _create_post_tutorial_objective(root: Control) -> void:
	_post_tutorial_objective = PanelContainer.new()
	_post_tutorial_objective.name = "PostTutorialObjective"
	_post_tutorial_objective.visible = false
	_post_tutorial_objective.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_post_tutorial_objective.anchor_left = 1.0
	_post_tutorial_objective.anchor_top = 1.0
	_post_tutorial_objective.anchor_right = 1.0
	_post_tutorial_objective.anchor_bottom = 1.0
	_post_tutorial_objective.offset_left = -362.0
	_post_tutorial_objective.offset_top = -216.0
	_post_tutorial_objective.offset_right = -24.0
	_post_tutorial_objective.offset_bottom = -162.0
	_post_tutorial_objective.add_theme_stylebox_override("panel", _make_round_style(Color(0.31, 0.26, 0.18, 0.78), Color(1.0, 0.86, 0.46, 0.72), 10.0, 1))
	root.add_child(_post_tutorial_objective)

	_post_tutorial_objective_label = Label.new()
	_post_tutorial_objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_post_tutorial_objective_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_post_tutorial_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_post_tutorial_objective_label.add_theme_font_size_override("font_size", 18)
	_post_tutorial_objective_label.add_theme_color_override("font_color", Color(1.0, 0.93, 0.70, 1.0))
	_post_tutorial_objective_label.add_theme_color_override("font_shadow_color", Color(0.12, 0.08, 0.04, 0.72))
	_post_tutorial_objective_label.add_theme_constant_override("shadow_offset_x", 1)
	_post_tutorial_objective_label.add_theme_constant_override("shadow_offset_y", 2)
	_post_tutorial_objective_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_post_tutorial_objective_label.offset_left = 16.0
	_post_tutorial_objective_label.offset_right = -16.0
	_post_tutorial_objective.add_child(_post_tutorial_objective_label)

func _create_crop_throw_charge_bar(root: Control) -> void:
	_crop_throw_charge_bar = PanelContainer.new()
	_crop_throw_charge_bar.name = "CropThrowChargeBar"
	_crop_throw_charge_bar.visible = false
	_crop_throw_charge_bar.anchor_left = 0.5
	_crop_throw_charge_bar.anchor_top = 1.0
	_crop_throw_charge_bar.anchor_right = 0.5
	_crop_throw_charge_bar.anchor_bottom = 1.0
	_crop_throw_charge_bar.offset_left = -86.0
	_crop_throw_charge_bar.offset_right = 86.0
	_crop_throw_charge_bar.offset_top = -142.0
	_crop_throw_charge_bar.offset_bottom = -126.0
	_crop_throw_charge_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crop_throw_charge_bar.add_theme_stylebox_override("panel", _make_round_style(Color(0.18, 0.13, 0.08, 0.58), Color(1.0, 0.94, 0.70, 0.72), 8.0, 1))
	root.add_child(_crop_throw_charge_bar)

	var fill_clip := Control.new()
	fill_clip.name = "FillClip"
	fill_clip.clip_contents = true
	fill_clip.set_anchors_preset(Control.PRESET_FULL_RECT)
	fill_clip.offset_left = 4.0
	fill_clip.offset_top = 4.0
	fill_clip.offset_right = -4.0
	fill_clip.offset_bottom = -4.0
	fill_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crop_throw_charge_bar.add_child(fill_clip)

	_crop_throw_charge_fill = ColorRect.new()
	_crop_throw_charge_fill.name = "Fill"
	_crop_throw_charge_fill.color = Color(1.0, 0.74, 0.28, 0.96)
	_crop_throw_charge_fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	_crop_throw_charge_fill.scale.x = 0.0
	_crop_throw_charge_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill_clip.add_child(_crop_throw_charge_fill)

func _create_rebas_shop(root: Control) -> void:
	_shop_overlay = Control.new()
	_shop_overlay.name = "RebasShop"
	_shop_overlay.visible = false
	_shop_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shop_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(_shop_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.22)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_shop_overlay.add_child(dim)

	var panel := PanelContainer.new()
	panel.name = "ShopPanel"
	panel.anchor_left = 0.12
	panel.anchor_top = 0.10
	panel.anchor_right = 0.88
	panel.anchor_bottom = 0.88
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", _make_round_style(Color(0.92, 0.80, 0.58, 0.96), Color(1.0, 0.94, 0.70, 1.0), 12.0, 2))
	_shop_overlay.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	layout.add_child(header)

	var title := Label.new()
	title.text = "%s的交换商店" % REBAS_NAME
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.24, 0.16, 0.08))
	header.add_child(title)

	_shop_coin_label = Label.new()
	_shop_coin_label.add_theme_font_size_override("font_size", 20)
	_shop_coin_label.add_theme_color_override("font_color", Color(0.36, 0.24, 0.08))
	header.add_child(_shop_coin_label)

	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.custom_minimum_size = Vector2(72.0, 34.0)
	close_button.add_theme_font_size_override("font_size", 16)
	close_button.pressed.connect(_close_rebas_shop)
	header.add_child(close_button)

	_shop_refresh_label = Label.new()
	_shop_refresh_label.add_theme_font_size_override("font_size", 16)
	_shop_refresh_label.add_theme_color_override("font_color", Color(0.34, 0.27, 0.18))
	layout.add_child(_shop_refresh_label)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	layout.add_child(tabs)
	_shop_tab_sell = _create_shop_tab_button("出售", "sell")
	_shop_tab_buy = _create_shop_tab_button("购买", "buy")
	tabs.add_child(_shop_tab_sell)
	tabs.add_child(_shop_tab_buy)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)

	_shop_grid = GridContainer.new()
	_shop_grid.columns = 4
	_shop_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_shop_grid.add_theme_constant_override("h_separation", 10)
	_shop_grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(_shop_grid)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	layout.add_child(footer)

	_shop_select_all = CheckBox.new()
	_shop_select_all.text = "一键勾选可出售"
	_shop_select_all.add_theme_font_size_override("font_size", 16)
	_shop_select_all.toggled.connect(_on_shop_select_all_toggled)
	footer.add_child(_shop_select_all)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)

	_shop_action_button = Button.new()
	_shop_action_button.text = "出售"
	_shop_action_button.custom_minimum_size = Vector2(180.0, 44.0)
	_shop_action_button.add_theme_font_size_override("font_size", 20)
	_shop_action_button.pressed.connect(_execute_shop_action)
	footer.add_child(_shop_action_button)

func _create_shop_tab_button(text: String, mode: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(120.0, 38.0)
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(_set_shop_mode.bind(mode))
	return button

func _open_rebas_shop() -> void:
	_refresh_shop_stock_if_needed()
	_rebas_seen_shop_key = _shop_daily_key
	_shop_mode = "sell"
	_shop_selected_quantities.clear()
	_shop_hold_button = ""
	_shop_hold_item_id = ""
	_set_rebas_highlight(false)
	if _rebas_exclamation != null:
		_rebas_exclamation.visible = false
	if _shop_overlay != null:
		_shop_overlay.visible = true
		_shop_overlay.move_to_front()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_rebuild_shop_items()

func _close_rebas_shop() -> void:
	if _shop_overlay != null:
		_shop_overlay.visible = false
	_shop_hold_button = ""
	_shop_hold_item_id = ""
	_shop_hold_direction = 0
	_shop_selected_quantities.clear()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _create_food_chest_inventory_panel(root: Control) -> void:
	_food_chest_overlay = Control.new()
	_food_chest_overlay.name = "FoodChestInventoryPanel"
	_food_chest_overlay.visible = false
	_food_chest_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_food_chest_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(_food_chest_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.18)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_food_chest_overlay.add_child(dim)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.18
	panel.anchor_top = 0.14
	panel.anchor_right = 0.82
	panel.anchor_bottom = 0.86
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", _make_round_style(Color(0.92, 0.80, 0.58, 0.97), Color(1.0, 0.94, 0.70, 1.0), 12.0, 2))
	_food_chest_overlay.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	layout.add_child(header)

	var title := Label.new()
	title.text = "食材箱"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.24, 0.16, 0.08))
	header.add_child(title)

	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.custom_minimum_size = Vector2(72.0, 34.0)
	close_button.add_theme_font_size_override("font_size", 16)
	close_button.pressed.connect(_close_food_chest_inventory_panel)
	header.add_child(close_button)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)

	_food_chest_grid = GridContainer.new()
	_food_chest_grid.columns = 4
	_food_chest_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_food_chest_grid.add_theme_constant_override("h_separation", 10)
	_food_chest_grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(_food_chest_grid)

func _open_food_chest_inventory_panel() -> bool:
	if _food_chest_overlay == null:
		return false
	_rebuild_food_chest_inventory_panel()
	_food_chest_overlay.visible = true
	_food_chest_overlay.move_to_front()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	return true

func _close_food_chest_inventory_panel() -> void:
	if _food_chest_overlay != null:
		_food_chest_overlay.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _rebuild_food_chest_inventory_panel() -> void:
	if _food_chest_grid == null:
		return
	for child in _food_chest_grid.get_children():
		child.queue_free()
	var grouped := _get_grouped_food_chest_items()
	if grouped.is_empty():
		var empty_label := Label.new()
		empty_label.text = "食材箱里还没有食材"
		empty_label.custom_minimum_size = Vector2(360.0, 80.0)
		empty_label.add_theme_font_size_override("font_size", 20)
		empty_label.add_theme_color_override("font_color", Color(0.32, 0.24, 0.15))
		_food_chest_grid.add_child(empty_label)
		return
	for item in grouped:
		_food_chest_grid.add_child(_create_food_chest_inventory_card(item))

func _get_grouped_food_chest_items() -> Array[Dictionary]:
	var grouped := {}
	for raw_key in _stored_crop_counts.keys():
		var key := str(raw_key)
		var count := int(_stored_crop_counts.get(key, 0))
		if count <= 0:
			continue
		var crop_type := _crop_type_from_storage_key(key)
		var quality := _quality_from_storage_key(key)
		if not grouped.has(crop_type):
			grouped[crop_type] = {
				"crop_type": crop_type,
				"count": 0,
				"qualities": {},
			}
		var item: Dictionary = grouped[crop_type]
		item["count"] = int(item["count"]) + count
		var qualities: Dictionary = item["qualities"]
		qualities[quality] = int(qualities.get(quality, 0)) + count
	var items: Array[Dictionary] = []
	for crop_type in grouped.keys():
		items.append(grouped[crop_type])
	items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _crop_display_name(str(a.get("crop_type", ""))) < _crop_display_name(str(b.get("crop_type", "")))
	)
	return items

func _create_food_chest_inventory_card(item: Dictionary) -> PanelContainer:
	var crop_type := str(item.get("crop_type", CROP_CARROT))
	var count := int(item.get("count", 0))
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(150.0, 150.0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _make_round_style(Color(0.98, 0.86, 0.60, 0.94), Color(1.0, 0.96, 0.76, 1.0), 8.0, 1))
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)

	var icon := TextureRect.new()
	icon.texture = load(SEED_ICON_PATH) as Texture2D
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(124.0, 46.0)
	icon.modulate = _seed_color(crop_type, 1)
	box.add_child(icon)

	var name_label := Label.new()
	name_label.text = "%s  x%d" % [_crop_display_name(crop_type), count]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 17)
	name_label.add_theme_color_override("font_color", Color(0.24, 0.16, 0.08))
	box.add_child(name_label)

	var quality_label := Label.new()
	quality_label.text = _food_chest_quality_summary(item)
	quality_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quality_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quality_label.custom_minimum_size = Vector2(124.0, 34.0)
	quality_label.add_theme_font_size_override("font_size", 13)
	quality_label.add_theme_color_override("font_color", Color(0.46, 0.32, 0.14))
	box.add_child(quality_label)
	return card

func _food_chest_quality_summary(item: Dictionary) -> String:
	var qualities: Dictionary = item.get("qualities", {})
	var parts: Array[String] = []
	for quality in range(0, 4):
		var count := int(qualities.get(quality, 0))
		if count <= 0:
			continue
		var label := "普通" if quality == 0 else _quality_stars(quality)
		parts.append("%s x%d" % [label, count])
	return " / ".join(parts)

func _set_shop_mode(mode: String) -> void:
	_shop_mode = mode
	_shop_selected_quantities.clear()
	if _shop_select_all != null:
		_shop_select_all.button_pressed = false
	_rebuild_shop_items()

func _refresh_shop_stock_if_needed() -> void:
	var key := _shop_day_key()
	if key == _shop_daily_key and not _shop_buy_stock.is_empty():
		return
	_shop_daily_key = key
	_shop_buy_stock.clear()
	_shop_buy_stock["seed:%s:0" % CROP_CARROT] = 12
	_shop_buy_stock["seed:%s:1" % CROP_CARROT] = 5
	_shop_buy_stock["seed:%s:2" % CROP_CARROT] = 2
	_shop_buy_stock["seed:%s:0" % CROP_PEA] = 8
	_shop_buy_stock["seed:%s:1" % CROP_PEA] = 3
	_shop_buy_stock["seed:%s:0" % CROP_EGGPLANT] = 6
	_shop_buy_stock["seed:%s:1" % CROP_EGGPLANT] = 2
	_shop_buy_stock["seed:%s:2" % CROP_EGGPLANT] = 1
	_shop_buy_stock["seed:%s:0" % CROP_MARSHMALLOW] = 1

func _shop_day_key() -> String:
	var unix := Time.get_unix_time_from_system()
	var shifted := int(floor((unix + 8.0 * 3600.0 - float(SHOP_REFRESH_UTC8_HOUR) * 3600.0) / 86400.0))
	return str(shifted)

func _seconds_until_shop_refresh() -> int:
	var unix := Time.get_unix_time_from_system()
	var utc8 := unix + 8.0 * 3600.0
	var day_start: float = floor(utc8 / 86400.0) * 86400.0
	var next_refresh: float = day_start + float(SHOP_REFRESH_UTC8_HOUR) * 3600.0
	if utc8 >= next_refresh:
		next_refresh += 86400.0
	return maxi(int(ceil(next_refresh - utc8)), 0)

func _update_shop_header() -> void:
	if _shop_coin_label != null:
		_shop_coin_label.text = "金币：%d" % _coins
	if _shop_refresh_label != null:
		var seconds := _seconds_until_shop_refresh()
		var hours := seconds / 3600
		var minutes := (seconds % 3600) / 60
		var remaining_seconds := seconds % 60
		_shop_refresh_label.text = "每天 05:00 刷新"

func _rebuild_shop_items() -> void:
	if _shop_grid == null:
		return
	_refresh_shop_stock_if_needed()
	_update_shop_header()
	for child in _shop_grid.get_children():
		child.queue_free()
	if _shop_tab_sell != null:
		_shop_tab_sell.disabled = _shop_mode == "sell"
	if _shop_tab_buy != null:
		_shop_tab_buy.disabled = _shop_mode == "buy"
	if _shop_select_all != null:
		_shop_select_all.visible = _shop_mode == "sell"
	if _shop_action_button != null:
		_shop_action_button.text = "出售" if _shop_mode == "sell" else "购买"
	var items := _get_shop_sell_items() if _shop_mode == "sell" else _get_shop_buy_items()
	items.sort_custom(_sort_shop_items)
	if items.is_empty():
		var empty_label := Label.new()
		empty_label.text = "食材箱里暂时没有可出售的食材" if _shop_mode == "sell" else "今天没有新货"
		empty_label.custom_minimum_size = Vector2(360.0, 80.0)
		empty_label.add_theme_font_size_override("font_size", 20)
		empty_label.add_theme_color_override("font_color", Color(0.32, 0.24, 0.15))
		_shop_grid.add_child(empty_label)
		return
	for item in items:
		_shop_grid.add_child(_create_shop_item_card(item))

func _sort_shop_items(a: Dictionary, b: Dictionary) -> bool:
	var a_enabled := bool(a.get("enabled", false))
	var b_enabled := bool(b.get("enabled", false))
	if a_enabled != b_enabled:
		return a_enabled
	return str(a.get("name", "")) < str(b.get("name", ""))

func _get_shop_sell_items() -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	for raw_key in _stored_crop_counts.keys():
		var key := str(raw_key)
		var count := int(_stored_crop_counts.get(key, 0))
		var crop_type := _crop_type_from_storage_key(key)
		var quality := _quality_from_storage_key(key)
		var price := _crop_sell_price(crop_type, quality)
		items.append({
			"id": "sell:%s" % key,
			"kind": "sell",
			"crop_type": crop_type,
			"quality": quality,
			"name": _crop_display_name(crop_type),
			"price": price,
			"count": count,
			"enabled": count > 0 and price > 0,
		})
	return items

func _get_shop_buy_items() -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	for raw_id in _shop_buy_stock.keys():
		var item_id := str(raw_id)
		var crop_type := _seed_item_crop_type(item_id)
		var quality := _seed_item_quality(item_id)
		var stock := int(_shop_buy_stock.get(item_id, 0))
		var price := _seed_buy_price(crop_type, quality)
		var can_add := _find_inventory_slot_for_item(item_id, -1) != -1 or _find_empty_inventory_slot() != -1
		items.append({
			"id": item_id,
			"kind": "buy",
			"crop_type": crop_type,
			"quality": quality,
			"name": "绁炵绉嶅瓙" if crop_type == CROP_MARSHMALLOW else _seed_display_name(crop_type, quality),
			"price": price,
			"count": stock,
			"enabled": stock > 0 and _coins >= price and can_add,
		})
	return items

func _create_shop_item_card(item: Dictionary) -> PanelContainer:
	var enabled := bool(item.get("enabled", false))
	var item_id := str(item.get("id", ""))
	var selected := int(_shop_selected_quantities.get(item_id, 0))
	var max_qty := _shop_item_max_quantity(item)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(166.0, 196.0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.modulate = Color(1, 1, 1, 1) if enabled else Color(0.55, 0.55, 0.55, 0.62)
	card.add_theme_stylebox_override("panel", _make_round_style(Color(0.98, 0.86, 0.60, 0.94), Color(1.0, 0.96, 0.76, 1.0), 8.0, 1))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)

	var icon := TextureRect.new()
	icon.name = "ShopSeedIcon"
	icon.texture = load(SEED_ICON_PATH) as Texture2D
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(148.0, 48.0)
	icon.modulate = _seed_color(str(item.get("crop_type", CROP_CARROT)), int(item.get("quality", 0)))
	box.add_child(icon)

	var star_label := Label.new()
	star_label.text = "%d⭐" % clampi(int(item.get("quality", 0)), 0, 3)
	star_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	star_label.custom_minimum_size = Vector2(148.0, 20.0)
	star_label.add_theme_font_size_override("font_size", 15)
	star_label.add_theme_color_override("font_color", Color(0.76, 0.50, 0.08))
	box.add_child(star_label)

	var name_label := Label.new()
	name_label.text = str(item.get("name", ""))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size = Vector2(148.0, 34.0)
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", Color(0.25, 0.17, 0.08))
	box.add_child(name_label)

	var info := Label.new()
	info.text = "%d 閲戝竵 路 %s锛?d" % [int(item.get("price", 0)), "搴撳瓨" if _shop_mode == "buy" else "鎷ユ湁", int(item.get("count", 0))]
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 13)
	info.add_theme_color_override("font_color", Color(0.42, 0.30, 0.14))
	box.add_child(info)

	var qty_row := HBoxContainer.new()
	qty_row.alignment = BoxContainer.ALIGNMENT_CENTER
	qty_row.add_theme_constant_override("separation", 8)
	box.add_child(qty_row)
	var minus := _create_shop_quantity_button("-", item_id, -1, enabled)
	qty_row.add_child(minus)
	var qty := Label.new()
	qty.text = str(selected)
	qty.custom_minimum_size = Vector2(42.0, 28.0)
	qty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	qty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	qty.add_theme_font_size_override("font_size", 18)
	qty.add_theme_color_override("font_color", Color(0.22, 0.15, 0.08))
	qty_row.add_child(qty)
	var plus := _create_shop_quantity_button("+", item_id, 1, enabled and max_qty > 0)
	qty_row.add_child(plus)

	if not enabled:
		var reason := Label.new()
		reason.text = _shop_disabled_reason(item)
		reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		reason.add_theme_font_size_override("font_size", 13)
		reason.add_theme_color_override("font_color", Color(0.42, 0.30, 0.20))
		box.add_child(reason)
	return card

func _create_shop_quantity_button(text: String, item_id: String, direction: int, enabled: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.disabled = not enabled
	button.custom_minimum_size = Vector2(34.0, 30.0)
	button.gui_input.connect(_on_shop_quantity_button_input.bind(item_id, direction))
	button.pressed.connect(_change_shop_quantity.bind(item_id, direction))
	return button

func _on_shop_quantity_button_input(event: InputEvent, item_id: String, direction: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_shop_hold_button = "%s:%d" % [item_id, direction]
			_shop_hold_item_id = item_id
			_shop_hold_direction = direction
			_shop_hold_time = 0.0
		elif _shop_hold_button == "%s:%d" % [item_id, direction]:
			_shop_hold_button = ""
			_shop_hold_item_id = ""
			_shop_hold_direction = 0
			_shop_hold_time = 0.0

func _update_shop_hold(delta: float) -> void:
	if _shop_hold_item_id == "" or _shop_hold_direction == 0:
		return
	_shop_hold_time += delta
	if _shop_hold_time < 0.35:
		return
	var step_time := 0.08
	while _shop_hold_time >= 0.35 + step_time:
		_shop_hold_time -= step_time
		_change_shop_quantity(_shop_hold_item_id, _shop_hold_direction)

func _change_shop_quantity(item_id: String, direction: int) -> void:
	var item := _find_shop_item(item_id)
	if item.is_empty():
		return
	var max_qty := _shop_item_max_quantity(item)
	var current := int(_shop_selected_quantities.get(item_id, 0))
	current = clampi(current + direction, 0, max_qty)
	if current <= 0:
		_shop_selected_quantities.erase(item_id)
	else:
		_shop_selected_quantities[item_id] = current
	_rebuild_shop_items()

func _find_shop_item(item_id: String) -> Dictionary:
	var items := _get_shop_sell_items() if _shop_mode == "sell" else _get_shop_buy_items()
	for item in items:
		if str(item.get("id", "")) == item_id:
			return item
	return {}

func _shop_item_max_quantity(item: Dictionary) -> int:
	if not bool(item.get("enabled", false)):
		return 0
	var price := maxi(int(item.get("price", 0)), 1)
	var count := int(item.get("count", 0))
	if _shop_mode == "buy":
		return mini(count, _coins / price)
	return count

func _on_shop_select_all_toggled(enabled: bool) -> void:
	if _shop_mode != "sell":
		return
	_shop_selected_quantities.clear()
	if enabled:
		for item in _get_shop_sell_items():
			if bool(item.get("enabled", false)):
				_shop_selected_quantities[str(item.get("id", ""))] = int(item.get("count", 0))
	_rebuild_shop_items()

func _execute_shop_action() -> void:
	if _shop_selected_quantities.is_empty():
		_show_side_toast("先选择要%s的数量" % ("出售" if _shop_mode == "sell" else "购买"))
		return
	if _shop_mode == "sell":
		_execute_shop_sell()
	else:
		_execute_shop_buy()
	_shop_selected_quantities.clear()
	if _shop_select_all != null:
		_shop_select_all.button_pressed = false
	_rebuild_shop_items()

func _execute_shop_sell() -> void:
	var total := 0
	for raw_id in _shop_selected_quantities.keys():
		var item_id := str(raw_id)
		var qty := int(_shop_selected_quantities.get(item_id, 0))
		if qty <= 0 or not item_id.begins_with("sell:"):
			continue
		var key := item_id.substr(5)
		var current := int(_stored_crop_counts.get(key, 0))
		var sell_qty := mini(qty, current)
		if sell_qty <= 0:
			continue
		var crop_type := _crop_type_from_storage_key(key)
		var quality := _quality_from_storage_key(key)
		total += _crop_sell_price(crop_type, quality) * sell_qty
		current -= sell_qty
		if current <= 0:
			_stored_crop_counts.erase(key)
		else:
			_stored_crop_counts[key] = current
	_coins += total
	_show_side_toast("卖出食材，获得 %d 金币" % total)

func _execute_shop_buy() -> void:
	var bought := 0
	var spent := 0
	for raw_id in _shop_selected_quantities.keys():
		var item_id := str(raw_id)
		var qty := int(_shop_selected_quantities.get(item_id, 0))
		if qty <= 0:
			continue
		var stock := int(_shop_buy_stock.get(item_id, 0))
		var crop_type := _seed_item_crop_type(item_id)
		var quality := _seed_item_quality(item_id)
		var price := _seed_buy_price(crop_type, quality)
		var buy_qty := mini(qty, stock)
		if buy_qty <= 0 or _coins < price * buy_qty:
			continue
		if _find_inventory_slot_for_item(item_id, -1) == -1 and _find_empty_inventory_slot() == -1:
			_show_inventory_full_prompt()
			break
		if _add_seed_to_inventory(crop_type, quality, buy_qty, true):
			_coins -= price * buy_qty
			spent += price * buy_qty
			bought += buy_qty
			_shop_buy_stock[item_id] = stock - buy_qty
	if bought > 0:
		_show_side_toast("买入 %d 件种子，花费 %d 金币" % [bought, spent])

func _shop_disabled_reason(item: Dictionary) -> String:
	if int(item.get("count", 0)) <= 0:
		return "今日售罄" if _shop_mode == "buy" else "暂无库存"
	if _shop_mode == "buy":
		var price := int(item.get("price", 0))
		if _coins < price:
			return "金币不足"
		if _find_inventory_slot_for_item(str(item.get("id", "")), -1) == -1 and _find_empty_inventory_slot() == -1:
			return "物品栏已满"
	return "暂不可交易"

func _shop_item_icon(crop_type: String, kind: String) -> String:
	if kind == "buy":
		return _crop_short_name(crop_type) + "种"
	return _crop_short_name(crop_type)

func _crop_type_from_storage_key(key: String) -> String:
	var parts := key.split(":")
	if parts.size() >= 1:
		return str(parts[0])
	return CROP_CARROT

func _quality_from_storage_key(key: String) -> int:
	var parts := key.split(":")
	if parts.size() >= 2:
		return clampi(int(parts[1]), 0, 3)
	return 0

func _crop_sell_price(crop_type: String, quality: int) -> int:
	var base := 8
	match crop_type:
		CROP_PEA:
			base = 10
		CROP_EGGPLANT:
			base = 12
		CROP_MARSHMALLOW:
			base = 220
	return int(round(float(base) * [1.0, 1.5, 2.2, 3.4][clampi(quality, 0, 3)]))

func _seed_buy_price(crop_type: String, quality: int) -> int:
	var base := 5
	match crop_type:
		CROP_PEA:
			base = 7
		CROP_EGGPLANT:
			base = 9
		CROP_MARSHMALLOW:
			base = 120
	return int(round(float(base) * [1.0, 1.6, 2.5, 3.8][clampi(quality, 0, 3)]))

func _create_map_popup(root: Control) -> void:
	_map_panel = Control.new()
	_map_panel.name = "MapPanel"
	_map_panel.visible = false
	_map_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_map_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_map_panel.gui_input.connect(_on_map_panel_gui_input)
	root.add_child(_map_panel)
	if _interaction_prompt != null:
		_interaction_prompt.move_to_front()

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.34)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_panel.add_child(dim)

	_map_popup = Control.new()
	_map_popup.name = "WorldMapPopup"
	_map_popup.anchor_left = 0.025
	_map_popup.anchor_top = 0.025
	_map_popup.anchor_right = 0.975
	_map_popup.anchor_bottom = 0.975
	_map_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_panel.add_child(_map_popup)

	var map_image := TextureRect.new()
	map_image.name = "MapImage"
	map_image.texture = load(WORLD_MAP_PATH)
	map_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	map_image.set_anchors_preset(Control.PRESET_FULL_RECT)
	map_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_popup.add_child(map_image)

	_map_village_label = Label.new()
	_map_village_label.text = "村庄"
	_map_village_label.modulate.a = 0.0
	_map_village_label.anchor_left = 0.0
	_map_village_label.anchor_top = 0.0
	_map_village_label.anchor_right = 0.0
	_map_village_label.anchor_bottom = 0.0
	_map_village_label.size = Vector2(150.0, 52.0)
	_map_village_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_map_village_label.add_theme_font_size_override("font_size", 34)
	_map_village_label.add_theme_color_override("font_color", Color(0.25, 0.18, 0.08))
	_map_popup.add_child(_map_village_label)

	_map_locked_label = Label.new()
	_map_locked_label.text = "此地暂未解锁"
	_map_locked_label.modulate.a = 0.0
	_map_locked_label.anchor_left = 0.0
	_map_locked_label.anchor_top = 0.0
	_map_locked_label.anchor_right = 0.0
	_map_locked_label.anchor_bottom = 0.0
	_map_locked_label.size = Vector2(260.0, 48.0)
	_map_locked_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_map_locked_label.add_theme_font_size_override("font_size", 28)
	_map_locked_label.add_theme_color_override("font_color", Color(0.28, 0.22, 0.15))
	_map_popup.add_child(_map_locked_label)

	_map_page_locked_label = Label.new()
	_map_page_locked_label.text = "地图未解锁"
	_map_page_locked_label.modulate.a = 0.0
	_map_page_locked_label.anchor_left = 0.0
	_map_page_locked_label.anchor_top = 0.0
	_map_page_locked_label.anchor_right = 0.0
	_map_page_locked_label.anchor_bottom = 0.0
	_map_page_locked_label.size = Vector2(220.0, 46.0)
	_map_page_locked_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_map_page_locked_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_map_page_locked_label.add_theme_font_size_override("font_size", 24)
	_map_page_locked_label.add_theme_color_override("font_color", Color(0.28, 0.19, 0.10))
	_map_page_locked_label.add_theme_color_override("font_shadow_color", Color(1.0, 0.94, 0.72, 0.86))
	_map_page_locked_label.add_theme_constant_override("shadow_offset_x", 0)
	_map_page_locked_label.add_theme_constant_override("shadow_offset_y", 2)
	_map_panel.add_child(_map_page_locked_label)

	_map_camper_marker = Control.new()
	_map_camper_marker.name = "MapCamperMarker"
	_map_camper_marker.size = Vector2(136.0, 96.0)
	_map_camper_marker.custom_minimum_size = Vector2(136.0, 96.0)
	_map_camper_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_popup.add_child(_map_camper_marker)
	_create_map_camper_icon()

	_position_map_camper()

	var exit_button := Button.new()
	exit_button.name = "MapExitButton"
	exit_button.text = "退出"
	exit_button.anchor_left = 1.0
	exit_button.anchor_top = 0.0
	exit_button.anchor_right = 1.0
	exit_button.anchor_bottom = 0.0
	exit_button.offset_left = -118.0
	exit_button.offset_top = 18.0
	exit_button.offset_right = -24.0
	exit_button.offset_bottom = 58.0
	exit_button.add_theme_font_size_override("font_size", 18)
	exit_button.add_theme_color_override("font_color", Color(0.25, 0.18, 0.10))
	exit_button.add_theme_stylebox_override("normal", _make_round_style(Color(0.92, 0.84, 0.62, 0.92), Color(1.0, 0.94, 0.72, 0.96), 18.0, 1))
	exit_button.add_theme_stylebox_override("hover", _make_round_style(Color(0.98, 0.89, 0.66, 1.0), Color(1.0, 0.98, 0.80, 1.0), 18.0, 1))
	exit_button.add_theme_stylebox_override("pressed", _make_round_style(Color(0.82, 0.68, 0.46, 1.0), Color(0.98, 0.90, 0.66, 1.0), 18.0, 1))
	exit_button.pressed.connect(_close_map_popup)
	_map_panel.add_child(exit_button)

	var left_button := _create_map_page_button("MapPageLeftButton", "<")
	left_button.anchor_left = 0.0
	left_button.anchor_top = 0.5
	left_button.anchor_right = 0.0
	left_button.anchor_bottom = 0.5
	left_button.offset_left = 28.0
	left_button.offset_top = -34.0
	left_button.offset_right = 88.0
	left_button.offset_bottom = 34.0
	left_button.pressed.connect(_on_map_page_left_pressed)
	_map_panel.add_child(left_button)

	var right_button := _create_map_page_button("MapPageRightButton", ">")
	right_button.anchor_left = 1.0
	right_button.anchor_top = 0.5
	right_button.anchor_right = 1.0
	right_button.anchor_bottom = 0.5
	right_button.offset_left = -88.0
	right_button.offset_top = -34.0
	right_button.offset_right = -28.0
	right_button.offset_bottom = 34.0
	right_button.pressed.connect(_on_map_page_right_pressed)
	_map_panel.add_child(right_button)

	var page_dots := HBoxContainer.new()
	page_dots.name = "MapPageDots"
	page_dots.anchor_left = 0.5
	page_dots.anchor_top = 1.0
	page_dots.anchor_right = 0.5
	page_dots.anchor_bottom = 1.0
	page_dots.offset_left = -58.0
	page_dots.offset_top = -50.0
	page_dots.offset_right = 58.0
	page_dots.offset_bottom = -30.0
	page_dots.alignment = BoxContainer.ALIGNMENT_CENTER
	page_dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page_dots.add_theme_constant_override("separation", 9)
	_map_panel.add_child(page_dots)
	for index in range(5):
		var dot := PanelContainer.new()
		dot.name = "PageDot%d" % (index + 1)
		dot.custom_minimum_size = Vector2(15.0, 15.0)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var fill := Color(0.98, 0.82, 0.36, 0.96) if index == 0 else Color(0.84, 0.77, 0.61, 0.72)
		var border := Color(1.0, 0.95, 0.74, 1.0) if index == 0 else Color(0.95, 0.90, 0.72, 0.78)
		dot.add_theme_stylebox_override("panel", _make_round_style(fill, border, 8.0, 2))
		page_dots.add_child(dot)
	_create_map_codex_panel()

func _create_map_codex_panel() -> void:
	if _map_panel == null:
		return
	_map_codex_panel = Control.new()
	_map_codex_panel.name = "MapCodexPanel"
	_map_codex_panel.anchor_left = 0.122
	_map_codex_panel.anchor_top = 0.150
	_map_codex_panel.anchor_right = 0.360
	_map_codex_panel.anchor_bottom = 0.245
	_map_codex_panel.z_index = 40
	_map_codex_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_map_panel.add_child(_map_codex_panel)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 2)
	_map_codex_panel.add_child(box)

	var crop_controls := _create_map_codex_text_row(box, "作物", "crop")
	_map_codex_crop_claim_button = crop_controls["button"] as Button
	_map_codex_crop_red_dot = crop_controls["red_dot"] as Label

	var cooking_controls := _create_map_codex_text_row(box, "料理", "cooking")
	_map_codex_cooking_claim_button = cooking_controls["button"] as Button
	_map_codex_cooking_red_dot = cooking_controls["red_dot"] as Label
	_update_map_codex_panel()

func _create_map_codex_text_row(parent: VBoxContainer, title_text: String, kind: String) -> Dictionary:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	parent.add_child(row)

	var button := Button.new()
	button.text = "%s 0/10 奖励" % title_text
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(112.0, 30.0)
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color(0.24, 0.15, 0.06))
	button.add_theme_color_override("font_hover_color", Color(0.42, 0.24, 0.06))
	button.add_theme_color_override("font_pressed_color", Color(0.18, 0.10, 0.04))
	button.add_theme_color_override("font_shadow_color", Color(1.0, 0.93, 0.72, 0.84))
	button.add_theme_constant_override("shadow_offset_x", 0)
	button.add_theme_constant_override("shadow_offset_y", 2)
	button.pressed.connect(_on_map_codex_text_pressed.bind(kind))
	row.add_child(button)

	var red_dot := Label.new()
	red_dot.text = "●"
	red_dot.visible = false
	red_dot.add_theme_font_size_override("font_size", 15)
	red_dot.add_theme_color_override("font_color", Color(0.92, 0.08, 0.05, 1.0))
	red_dot.add_theme_color_override("font_shadow_color", Color(1.0, 0.82, 0.62, 0.85))
	red_dot.add_theme_constant_override("shadow_offset_x", 0)
	red_dot.add_theme_constant_override("shadow_offset_y", 1)
	row.add_child(red_dot)

	return {
		"button": button,
		"red_dot": red_dot,
	}

func _update_map_codex_panel() -> void:
	_update_map_codex_text_row("作物", _codex_discovered_crops.size(), CODEX_CROP_TOTAL, CODEX_CROP_REWARDS, "crop", _map_codex_crop_claim_button, _map_codex_crop_red_dot)
	_update_map_codex_text_row("料理", _codex_discovered_cooking.size(), CODEX_COOKING_TOTAL, CODEX_COOKING_REWARDS, "cooking", _map_codex_cooking_claim_button, _map_codex_cooking_red_dot)

func _update_map_codex_text_row(title_text: String, count: int, total: int, rewards: Array, kind: String, button: Button, red_dot: Label) -> void:
	if button == null or red_dot == null:
		return
	count = clampi(count, 0, total)
	button.text = "%s %d/%d 奖励" % [title_text, count, total]
	var reward := _find_next_codex_reward(kind, rewards)
	if reward.is_empty():
		red_dot.visible = false
		return
	var threshold := int(reward.get("count", 0))
	red_dot.visible = count >= threshold

func _find_next_codex_reward(kind: String, rewards: Array) -> Dictionary:
	for reward in rewards:
		var threshold := int(reward.get("count", 0))
		if not bool(_codex_claimed_rewards.get("%s:%d" % [kind, threshold], false)):
			return reward
	return {}

func _on_map_codex_text_pressed(kind: String) -> void:
	var count := _codex_discovered_crops.size() if kind == "crop" else _codex_discovered_cooking.size()
	var total := CODEX_CROP_TOTAL if kind == "crop" else CODEX_COOKING_TOTAL
	var rewards := CODEX_CROP_REWARDS if kind == "crop" else CODEX_COOKING_REWARDS
	var reward := _find_next_codex_reward(kind, rewards)
	if reward.is_empty():
		_show_side_toast("这条图鉴奖励已经全部领取")
		return
	var threshold := int(reward.get("count", 0))
	if count >= threshold:
		_claim_map_codex_reward(kind)
	else:
		_show_side_toast("下一等级奖励：%d/%d  %s" % [threshold, total, str(reward.get("label", "奖励"))])

func _claim_map_codex_reward(kind: String) -> void:
	var count := _codex_discovered_crops.size() if kind == "crop" else _codex_discovered_cooking.size()
	var rewards := CODEX_CROP_REWARDS if kind == "crop" else CODEX_COOKING_REWARDS
	var reward := _find_next_codex_reward(kind, rewards)
	if reward.is_empty():
		return
	var threshold := int(reward.get("count", 0))
	if count < threshold:
		_show_side_toast("图鉴进度还不够")
		return
	_codex_claimed_rewards["%s:%d" % [kind, threshold]] = true
	if reward.has("coins"):
		_coins += int(reward["coins"])
	if reward.has("seed_crop"):
		_add_seed_to_inventory(str(reward["seed_crop"]), int(reward.get("seed_quality", 0)), int(reward.get("seed_count", 1)), true)
	_show_side_toast(str(reward.get("toast", "领取图鉴奖励：%s" % str(reward.get("label", "奖励")))))
	_update_map_codex_panel()

func _record_codex_crop(crop_type: String) -> void:
	if crop_type == "" or _codex_discovered_crops.has(crop_type):
		return
	_codex_discovered_crops[crop_type] = true
	_show_side_toast("图鉴更新：%s" % _crop_display_name(crop_type))
	_update_map_codex_panel()

func _create_map_page_button(button_name: String, label_text: String) -> Button:
	var button := Button.new()
	button.name = button_name
	button.text = label_text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 34)
	button.add_theme_color_override("font_color", Color(0.32, 0.23, 0.12))
	button.add_theme_stylebox_override("normal", _make_round_style(Color(0.92, 0.84, 0.62, 0.78), Color(1.0, 0.95, 0.74, 0.92), 22.0, 2))
	button.add_theme_stylebox_override("hover", _make_round_style(Color(0.98, 0.88, 0.63, 0.94), Color(1.0, 0.98, 0.82, 1.0), 22.0, 2))
	button.add_theme_stylebox_override("pressed", _make_round_style(Color(0.78, 0.64, 0.43, 0.94), Color(0.98, 0.90, 0.68, 1.0), 22.0, 2))
	return button

func _on_map_page_left_pressed() -> void:
	_show_map_page_locked(-1)

func _on_map_page_right_pressed() -> void:
	_show_map_page_locked(1)

func _show_map_page_locked(side: int) -> void:
	_map_page_locked_side = side
	_map_page_locked_time = 1.45
	if _map_page_locked_label != null:
		_map_page_locked_label.modulate.a = 0.0
		_map_page_locked_label.move_to_front()
	_position_map_camper()

func _reset_inventory_slot_items() -> void:
	_inventory_slot_items.clear()
	for _index in range(10):
		_inventory_slot_items.append(INVENTORY_ITEM_NONE)
	_inventory_slot_items[INVENTORY_HAND_SLOT] = INVENTORY_ITEM_HAND
	_inventory_slot_items[INVENTORY_HOE_SLOT] = INVENTORY_ITEM_HOE
	_inventory_slot_items[INVENTORY_SEED_SLOT] = INVENTORY_ITEM_SEED
	_inventory_slot_items[INVENTORY_WATERING_CAN_SLOT] = INVENTORY_ITEM_WATERING_CAN
	_inventory_slot_items[INVENTORY_SCYTHE_SLOT] = INVENTORY_ITEM_SCYTHE

func _get_inventory_slot_item(slot_index: int) -> String:
	if slot_index >= 0 and slot_index < _inventory_slot_items.size():
		return _inventory_slot_items[slot_index]
	return INVENTORY_ITEM_NONE

func _set_inventory_slot_item(slot_index: int, item: String) -> void:
	if slot_index >= 0 and slot_index < _inventory_slot_items.size():
		_inventory_slot_items[slot_index] = item

func _seed_item(crop_type: String, quality: int) -> String:
	return "%s%s:%d" % [INVENTORY_ITEM_SEED_PREFIX, crop_type, clampi(quality, 0, 3)]

func _is_seed_item(item: String) -> bool:
	return item.begins_with(INVENTORY_ITEM_SEED_PREFIX)

func _seed_inventory_key(crop_type: String, quality: int) -> String:
	return "%s:%d" % [crop_type, clampi(quality, 0, 3)]

func _seed_item_crop_type(item: String) -> String:
	var parts := item.split(":")
	if parts.size() >= 2:
		return str(parts[1])
	return CROP_CARROT

func _seed_item_quality(item: String) -> int:
	var parts := item.split(":")
	if parts.size() >= 3:
		return clampi(int(parts[2]), 0, 3)
	return 0

func _get_seed_count(crop_type: String, quality: int) -> int:
	return int(_seed_inventory.get(_seed_inventory_key(crop_type, quality), 0))

func _get_seed_count_for_item(item: String) -> int:
	if not _is_seed_item(item):
		return 0
	return _get_seed_count(_seed_item_crop_type(item), _seed_item_quality(item))

func _seed_display_name(crop_type: String, quality: int) -> String:
	var crop_name := _crop_display_name(crop_type)
	var quality_name := ""
	match clampi(quality, 0, 3):
		1:
			quality_name = "优质"
		2:
			quality_name = "精品"
		3:
			quality_name = "稀有"
	return "%s%s种子" % [quality_name, crop_name]

func _crop_display_name(crop_type: String) -> String:
	match crop_type:
		CROP_EGGPLANT:
			return "茄子"
		CROP_PEA:
			return "豌豆"
		CROP_BELL_PEPPER:
			return "甜椒"
		CROP_MARSHMALLOW:
			return "棉花糖"
		_:
			return "胡萝卜"

func _crop_short_name(crop_type: String) -> String:
	match crop_type:
		CROP_EGGPLANT:
			return "茄"
		CROP_PEA:
			return "豆"
		CROP_BELL_PEPPER:
			return "椒"
		CROP_MARSHMALLOW:
			return "糖"
		_:
			return "胡"

func _quality_stars(quality: int) -> String:
	return "⭐".repeat(clampi(quality, 0, 3))

func _quality_color(quality: int) -> Color:
	match clampi(quality, 0, 3):
		1:
			return Color(0.56, 0.86, 0.46, 1.0)
		2:
			return Color(0.48, 0.72, 1.0, 1.0)
		3:
			return Color(1.0, 0.72, 0.30, 1.0)
	return Color(1.0, 0.94, 0.70, 1.0)

func _show_pickup_toast(display_name: String, amount: int, quality: int = 0) -> void:
	if _pickup_feed == null or not is_instance_valid(_pickup_feed):
		return
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.modulate.a = 0.0
	panel.add_theme_stylebox_override("panel", _make_round_style(Color(0.35, 0.25, 0.13, 0.68), Color(1.0, 0.88, 0.46, 0.80), 8.0, 1))
	var label := Label.new()
	var star_text := _quality_stars(quality)
	label.text = "%s%s x%d" % [star_text + " " if star_text != "" else "", display_name, amount]
	label.custom_minimum_size = Vector2(230.0, 30.0)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", _quality_color(quality))
	label.add_theme_color_override("font_shadow_color", Color(0.12, 0.08, 0.04, 0.78))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.offset_left = 12.0
	label.offset_right = -12.0
	label.offset_top = 4.0
	label.offset_bottom = -4.0
	panel.add_child(label)
	_pickup_feed.add_child(panel)
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.16)
	tween.tween_interval(1.85)
	tween.tween_property(panel, "modulate:a", 0.0, 0.28)
	tween.finished.connect(panel.queue_free)

func _show_side_toast(text: String) -> void:
	if _pickup_feed == null or not is_instance_valid(_pickup_feed):
		return
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.modulate.a = 0.0
	panel.add_theme_stylebox_override("panel", _make_round_style(Color(0.35, 0.25, 0.13, 0.68), Color(1.0, 0.88, 0.46, 0.80), 8.0, 1))
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(280.0, 32.0)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.70, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0.12, 0.08, 0.04, 0.78))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.offset_left = 12.0
	label.offset_right = -12.0
	label.offset_top = 4.0
	label.offset_bottom = -4.0
	panel.add_child(label)
	_pickup_feed.add_child(panel)
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.16)
	tween.tween_interval(2.2)
	tween.tween_property(panel, "modulate:a", 0.0, 0.28)
	tween.finished.connect(panel.queue_free)

func _sync_total_seed_count() -> void:
	var total := 0
	for value in _seed_inventory.values():
		total += int(value)
	_seed_count = total

func _add_seed_to_inventory(crop_type: String, quality: int, amount: int, show_feed: bool = true) -> bool:
	if amount <= 0:
		return false
	quality = clampi(quality, 0, 3)
	var item := _seed_item(crop_type, quality)
	var existing_slot := _find_inventory_slot_for_item(item, -1)
	if existing_slot == -1 and _find_empty_inventory_slot() == -1:
		_show_inventory_full_prompt()
		return false
	var key := _seed_inventory_key(crop_type, quality)
	_seed_inventory[key] = int(_seed_inventory.get(key, 0)) + amount
	_sync_total_seed_count()
	if existing_slot == -1:
		var target_slot := _find_empty_inventory_slot()
		if target_slot != -1:
			_set_inventory_slot_item(target_slot, item)
	_update_inventory_bar()
	if show_feed:
		_show_pickup_toast(_seed_display_name(crop_type, quality), amount, quality)
	return true

func _remove_seed_from_inventory(crop_type: String, quality: int, amount: int) -> bool:
	var key := _seed_inventory_key(crop_type, quality)
	var count := int(_seed_inventory.get(key, 0))
	if count < amount:
		return false
	count -= amount
	if count <= 0:
		_seed_inventory.erase(key)
	else:
		_seed_inventory[key] = count
	_sync_total_seed_count()
	return true

func _find_empty_inventory_slot() -> int:
	for index in range(INVENTORY_UNLOCKED_SLOT_COUNT):
		if _get_inventory_slot_item(index) == INVENTORY_ITEM_NONE:
			return index
	return -1

func _is_inventory_full() -> bool:
	return _find_empty_inventory_slot() == -1

func _show_inventory_full_prompt() -> void:
	_show_notification("物品栏满了，长按 F 或长按物品格丢弃后再拾取")

func _is_inventory_item_discardable(item: String) -> bool:
	return _is_seed_item(item)

func _is_selected_inventory_item_discardable() -> bool:
	return _is_inventory_item_discardable(_get_inventory_slot_item(_selected_inventory_slot))

func _discard_inventory_slot(slot_index: int) -> bool:
	var item := _get_inventory_slot_item(slot_index)
	if not _is_inventory_item_discardable(item):
		_show_notification("这个不能丢弃，选择种子等消耗品再长按")
		return false
	if _is_seed_item(item):
		var crop_type := _seed_item_crop_type(item)
		var quality := _seed_item_quality(item)
		var count := _get_seed_count(crop_type, quality)
		_seed_inventory.erase(_seed_inventory_key(crop_type, quality))
		_sync_total_seed_count()
		_set_inventory_slot_item(slot_index, INVENTORY_ITEM_NONE)
		_update_inventory_bar()
		_show_notification("已丢弃 %s x%d" % [_seed_display_name(crop_type, quality), count])
		return true
	return false

func _discard_selected_inventory_item() -> bool:
	return _discard_inventory_slot(_selected_inventory_slot)

func _is_inventory_item_available(item: String) -> bool:
	if _is_seed_item(item):
		return _get_seed_count_for_item(item) > 0
	match item:
		INVENTORY_ITEM_HAND:
			return _has_inventory_items()
		INVENTORY_ITEM_HOE:
			return _has_hoe
		INVENTORY_ITEM_WATERING_CAN:
			return _has_watering_can
		INVENTORY_ITEM_SCYTHE:
			return _has_scythe
		INVENTORY_ITEM_FOOD_CHEST:
			return _has_food_chest
	return false

func _find_inventory_slot_for_item(item: String, fallback_slot: int) -> int:
	for index in range(INVENTORY_UNLOCKED_SLOT_COUNT):
		if _get_inventory_slot_item(index) == item:
			return index
	return fallback_slot

func _create_inventory_bar(root: Control) -> void:
	_inventory_slots.clear()
	_inventory_bar = HBoxContainer.new()
	_inventory_bar.name = "InventoryBar"
	_inventory_bar.visible = _has_inventory_items()
	_inventory_bar.anchor_left = 0.5
	_inventory_bar.anchor_top = 1.0
	_inventory_bar.anchor_right = 0.5
	_inventory_bar.anchor_bottom = 1.0
	_inventory_bar.offset_left = -318.0
	_inventory_bar.offset_top = -76.0
	_inventory_bar.offset_right = 318.0
	_inventory_bar.offset_bottom = -16.0
	_inventory_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	_inventory_bar.add_theme_constant_override("separation", 8)
	root.add_child(_inventory_bar)

	for index in range(10):
		var slot := PanelContainer.new()
		slot.name = "Slot%d" % (index + 1)
		slot.custom_minimum_size = Vector2(56.0, 56.0)
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		slot.gui_input.connect(_on_inventory_slot_gui_input.bind(index))
		_inventory_bar.add_child(slot)
		_inventory_slots.append(slot)

		var locked := index >= INVENTORY_UNLOCKED_SLOT_COUNT
		var label := Label.new()
		label.name = "SlotLabel"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 21)
		label.add_theme_color_override("font_color", Color(0.26, 0.18, 0.09) if not locked else Color(0.78, 0.71, 0.62))
		label.set_anchors_preset(Control.PRESET_FULL_RECT)
		slot.add_child(label)
	_update_inventory_bar()

func _update_inventory_bar() -> void:
	if _inventory_bar == null:
		return
	_inventory_bar.visible = _has_inventory_items() and not _dialogue_open and not _map_open and _reward_overlay == null
	for index in range(_inventory_slots.size()):
		var slot := _inventory_slots[index]
		var locked := index >= INVENTORY_UNLOCKED_SLOT_COUNT
		var selected := index == _selected_inventory_slot
		var drag_hover := _inventory_dragging_item and index == _inventory_drag_hover_slot and not locked
		var fill := Color(0.98, 0.84, 0.48, 0.96) if selected else Color(0.92, 0.80, 0.58, 0.86)
		var border := Color(1.0, 0.98, 0.74, 1.0) if selected else Color(1.0, 0.94, 0.72, 0.96)
		if locked:
			fill = Color(0.40, 0.36, 0.30, 0.78)
			border = Color(0.64, 0.58, 0.49, 0.86)
		elif drag_hover:
			fill = Color(0.98, 0.88, 0.58, 0.98)
			border = Color(0.58, 0.95, 0.78, 1.0)
		slot.add_theme_stylebox_override("panel", _make_round_style(fill, border, 8.0, 3 if selected else 2))
		var label := slot.get_node_or_null("SlotLabel") as Label
		if label == null:
			continue
		var hoe_icon := slot.get_node_or_null("HoeIcon") as TextureRect
		var watering_can_icon := slot.get_node_or_null("WateringCanIcon") as TextureRect
		var scythe_icon := slot.get_node_or_null("ScytheIcon") as TextureRect
		var food_chest_icon := slot.get_node_or_null("FoodChestIcon") as TextureRect
		var water_bar := slot.get_node_or_null("WaterLevelBar") as Node2D
		var water_fill: Line2D = null
		if water_bar != null:
			water_fill = water_bar.get_node_or_null("WaterLevelFill") as Line2D
		var seed_icon := slot.get_node_or_null("SeedIcon") as TextureRect
		var seed_count_label := slot.get_node_or_null("SeedCount") as Label
		var seed_star_label := slot.get_node_or_null("SeedStars") as Label
		var seed_type_label := slot.get_node_or_null("SeedType") as Label
		var hand_icon := slot.get_node_or_null("HandIcon") as Label
		if hoe_icon != null:
			hoe_icon.visible = false
		if watering_can_icon != null:
			watering_can_icon.visible = false
		if scythe_icon != null:
			scythe_icon.visible = false
		if food_chest_icon != null:
			food_chest_icon.visible = false
		if water_bar != null:
			water_bar.visible = false
		if water_fill != null:
			water_fill.visible = false
		if seed_icon != null:
			seed_icon.visible = false
		if seed_count_label != null:
			seed_count_label.visible = false
		if seed_star_label != null:
			seed_star_label.visible = false
		if seed_type_label != null:
			seed_type_label.visible = false
		if hand_icon != null:
			hand_icon.visible = false
		var item := _get_inventory_slot_item(index)
		var item_available := _is_inventory_item_available(item)
		if item == INVENTORY_ITEM_HAND and item_available:
			label.text = ""
			if hand_icon == null:
				hand_icon = _create_hand_inventory_icon(slot)
			if hand_icon != null:
				hand_icon.visible = true
		elif item == INVENTORY_ITEM_HOE and item_available:
			label.text = ""
			if hoe_icon == null:
				hoe_icon = _create_hoe_inventory_icon(slot)
			if hoe_icon != null:
				hoe_icon.visible = true
		elif _is_seed_item(item) and item_available:
			label.text = ""
			if seed_icon == null:
				seed_icon = _create_seed_inventory_icon(slot)
			if seed_count_label == null:
				seed_count_label = _create_seed_count_label(slot)
			if seed_star_label == null:
				seed_star_label = _create_seed_star_label(slot)
			if seed_type_label == null:
				seed_type_label = _create_seed_type_label(slot)
			if seed_icon != null:
				_tint_seed_inventory_icon(seed_icon, _seed_item_crop_type(item), _seed_item_quality(item))
				seed_icon.visible = true
			if seed_count_label != null:
				seed_count_label.text = "x%d" % _get_seed_count_for_item(item)
				seed_count_label.visible = true
			if seed_star_label != null:
				var quality := _seed_item_quality(item)
				seed_star_label.text = _quality_stars(quality)
				seed_star_label.visible = quality > 0
			if seed_type_label != null:
				seed_type_label.text = _crop_short_name(_seed_item_crop_type(item))
				seed_type_label.visible = true
		elif item == INVENTORY_ITEM_WATERING_CAN and item_available:
			label.text = ""
			if watering_can_icon == null:
				watering_can_icon = _create_watering_can_inventory_icon(slot)
			if water_bar == null or water_fill == null:
				_create_watering_can_water_bar(slot)
				water_bar = slot.get_node_or_null("WaterLevelBar") as Node2D
				if water_bar != null:
					water_fill = water_bar.get_node_or_null("WaterLevelFill") as Line2D
			if watering_can_icon != null:
				watering_can_icon.visible = true
			if water_bar != null:
				water_bar.visible = true
			if water_fill != null:
				water_fill.visible = true
				water_fill.points = PackedVector2Array([Vector2(5.0, 50.0), Vector2(5.0 + 46.0 * clampf(_water_amount, 0.0, 1.0), 50.0)])
		elif item == INVENTORY_ITEM_SCYTHE and item_available:
			label.text = ""
			if scythe_icon == null:
				scythe_icon = _create_scythe_inventory_icon(slot)
			if scythe_icon != null:
				scythe_icon.visible = true
		elif item == INVENTORY_ITEM_FOOD_CHEST and item_available:
			label.text = ""
			if food_chest_icon == null:
				food_chest_icon = _create_food_chest_inventory_icon(slot)
			if food_chest_icon != null:
				food_chest_icon.visible = true
		elif index >= INVENTORY_UNLOCKED_SLOT_COUNT:
			label.text = "锁"
		else:
			label.text = ""

func _has_inventory_items() -> bool:
	return _has_hoe or _has_watering_can or _has_scythe or _has_food_chest or _seed_count > 0 or _held_crop_item != ""

func _create_hand_inventory_icon(slot: PanelContainer) -> Label:
	var icon := Label.new()
	icon.name = "HandIcon"
	icon.text = "↖"
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 34)
	icon.add_theme_color_override("font_color", Color(0.28, 0.20, 0.10))
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	slot.add_child(icon)
	slot.move_child(icon, 0)
	return icon

func _create_hoe_inventory_icon(slot: PanelContainer) -> TextureRect:
	var icon := TextureRect.new()
	icon.name = "HoeIcon"
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = -5.0
	icon.offset_top = -5.0
	icon.offset_right = 5.0
	icon.offset_bottom = 5.0
	slot.add_child(icon)
	slot.move_child(icon, 0)
	_setup_hoe_preview_viewport(icon, Vector2i(320, 320), false)
	return icon

func _create_seed_inventory_icon(slot: PanelContainer) -> TextureRect:
	var icon := TextureRect.new()
	icon.name = "SeedIcon"
	icon.texture = load(SEED_ICON_PATH) as Texture2D
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = -4.0
	icon.offset_top = -5.0
	icon.offset_right = 4.0
	icon.offset_bottom = 3.0
	slot.add_child(icon)
	slot.move_child(icon, 0)
	return icon

func _tint_seed_inventory_icon(icon: TextureRect, crop_type: String, quality: int) -> void:
	if icon == null:
		return
	icon.modulate = _seed_color(crop_type, quality)
	match crop_type:
		CROP_EGGPLANT:
			icon.offset_left = -8.0
			icon.offset_top = -3.0
			icon.offset_right = 6.0
			icon.offset_bottom = 1.0
		CROP_PEA:
			icon.offset_left = 1.0
			icon.offset_top = -7.0
			icon.offset_right = -1.0
			icon.offset_bottom = 5.0
		CROP_BELL_PEPPER:
			icon.offset_left = -5.0
			icon.offset_top = -4.0
			icon.offset_right = 5.0
			icon.offset_bottom = 2.0
		CROP_MARSHMALLOW:
			icon.offset_left = -3.0
			icon.offset_top = -6.0
			icon.offset_right = 3.0
			icon.offset_bottom = 4.0
		_:
			icon.offset_left = -4.0
			icon.offset_top = -5.0
			icon.offset_right = 4.0
			icon.offset_bottom = 3.0

func _create_seed_count_label(slot: PanelContainer) -> Label:
	var label := Label.new()
	label.name = "SeedCount"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color(0.26, 0.18, 0.09))
	label.add_theme_color_override("font_shadow_color", Color(1.0, 0.95, 0.76, 0.82))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 4.0
	label.offset_top = 4.0
	label.offset_right = -5.0
	label.offset_bottom = -3.0
	slot.add_child(label)
	return label

func _create_seed_star_label(slot: PanelContainer) -> Label:
	var label := Label.new()
	label.name = "SeedStars"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.20))
	label.add_theme_color_override("font_shadow_color", Color(0.36, 0.20, 0.05, 0.82))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 5.0
	label.offset_top = 32.0
	label.offset_bottom = -2.0
	slot.add_child(label)
	return label

func _create_seed_type_label(slot: PanelContainer) -> Label:
	var label := Label.new()
	label.name = "SeedType"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.27, 0.16, 0.08))
	label.add_theme_color_override("font_shadow_color", Color(1.0, 0.93, 0.64, 0.86))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 13.0
	label.offset_top = 34.0
	label.offset_right = -13.0
	label.offset_bottom = -2.0
	slot.add_child(label)
	return label

func _create_watering_can_inventory_icon(slot: PanelContainer) -> TextureRect:
	var icon := TextureRect.new()
	icon.name = "WateringCanIcon"
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = -5.0
	icon.offset_top = -5.0
	icon.offset_right = 5.0
	icon.offset_bottom = 5.0
	slot.add_child(icon)
	slot.move_child(icon, 0)
	_setup_watering_can_preview_viewport(icon, Vector2i(320, 320), false)
	return icon

func _create_scythe_inventory_icon(slot: PanelContainer) -> TextureRect:
	var icon := TextureRect.new()
	icon.name = "ScytheIcon"
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 0.0
	icon.offset_top = 0.0
	icon.offset_right = 0.0
	icon.offset_bottom = 0.0
	slot.add_child(icon)
	slot.move_child(icon, 0)
	_setup_scythe_preview_viewport(icon, Vector2i(320, 320), false)
	return icon

func _create_food_chest_inventory_icon(slot: PanelContainer) -> TextureRect:
	var icon := TextureRect.new()
	icon.name = "FoodChestIcon"
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = -2.0
	icon.offset_top = -4.0
	icon.offset_right = 2.0
	icon.offset_bottom = 4.0
	slot.add_child(icon)
	slot.move_child(icon, 0)
	_setup_food_chest_preview_viewport(icon, Vector2i(320, 320))
	return icon

func _draw_food_chest_inventory_icon(icon: Control) -> void:
	var shadow := ColorRect.new()
	shadow.name = "ChestShadow"
	shadow.color = Color(0.30, 0.20, 0.10, 0.22)
	shadow.anchor_left = 0.12
	shadow.anchor_top = 0.78
	shadow.anchor_right = 0.92
	shadow.anchor_bottom = 0.90
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.add_child(shadow)

	var body := PanelContainer.new()
	body.name = "ChestBody"
	body.anchor_left = 0.06
	body.anchor_top = 0.34
	body.anchor_right = 0.94
	body.anchor_bottom = 0.84
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_theme_stylebox_override("panel", _make_round_style(Color(0.88, 0.62, 0.30, 1.0), Color(0.54, 0.32, 0.14, 1.0), 3.0, 1))
	icon.add_child(body)

	var lid := PanelContainer.new()
	lid.name = "ChestLid"
	lid.anchor_left = 0.03
	lid.anchor_top = 0.16
	lid.anchor_right = 0.97
	lid.anchor_bottom = 0.46
	lid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lid.add_theme_stylebox_override("panel", _make_round_style(Color(0.96, 0.74, 0.38, 1.0), Color(0.58, 0.35, 0.16, 1.0), 3.0, 1))
	icon.add_child(lid)

	var seam := ColorRect.new()
	seam.name = "ChestSeam"
	seam.color = Color(0.58, 0.35, 0.16, 0.75)
	seam.anchor_left = 0.08
	seam.anchor_top = 0.50
	seam.anchor_right = 0.92
	seam.anchor_bottom = 0.56
	seam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.add_child(seam)

	var band := ColorRect.new()
	band.name = "ChestBand"
	band.color = Color(0.98, 0.84, 0.48, 1.0)
	band.anchor_left = 0.45
	band.anchor_top = 0.18
	band.anchor_right = 0.55
	band.anchor_bottom = 0.82
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.add_child(band)

	var lock := PanelContainer.new()
	lock.name = "ChestLock"
	lock.anchor_left = 0.41
	lock.anchor_top = 0.48
	lock.anchor_right = 0.59
	lock.anchor_bottom = 0.70
	lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lock.add_theme_stylebox_override("panel", _make_round_style(Color(1.0, 0.78, 0.28, 1.0), Color(0.50, 0.30, 0.10, 1.0), 2.0, 1))
	icon.add_child(lock)

func _setup_food_chest_preview_viewport(target: TextureRect, size: Vector2i) -> void:
	var sub_viewport := SubViewport.new()
	sub_viewport.size = size
	sub_viewport.transparent_bg = true
	sub_viewport.world_3d = World3D.new()
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	target.add_child(sub_viewport)
	target.texture = sub_viewport.get_texture()

	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.15
	camera.position = Vector3(0.0, 0.55, 4.2)
	camera.current = true
	sub_viewport.add_child(camera)
	camera.look_at(Vector3(0.0, 0.42, 0.0), Vector3.UP)

	var light := DirectionalLight3D.new()
	light.light_energy = 2.5
	light.rotation_degrees = Vector3(-48.0, -35.0, 0.0)
	sub_viewport.add_child(light)

	var scene := load(FOOD_CHEST_SCENE_PATH)
	if not scene is PackedScene:
		return
	var root := Node3D.new()
	root.name = "FoodChestPreviewRoot"
	sub_viewport.add_child(root)
	var model := scene.instantiate() as Node3D
	if model == null:
		return
	root.add_child(model)
	_fit_model_to_max_dimension(model, 1.62)
	_center_model_on_origin(model)
	_ground_model(model)
	model.rotation_degrees = Vector3(0.0, -34.0, 0.0)

func _create_watering_can_water_bar(slot: PanelContainer) -> void:
	var bar := Node2D.new()
	bar.name = "WaterLevelBar"
	slot.add_child(bar)

	var back := Line2D.new()
	back.name = "WaterLevelBack"
	back.width = 5.0
	back.default_color = Color(0.16, 0.22, 0.24, 0.62)
	back.points = PackedVector2Array([Vector2(5.0, 50.0), Vector2(51.0, 50.0)])
	bar.add_child(back)

	var fill := Line2D.new()
	fill.name = "WaterLevelFill"
	fill.width = 5.0
	fill.default_color = Color(0.28, 0.67, 1.0, 0.94)
	fill.points = PackedVector2Array([Vector2(5.0, 50.0), Vector2(5.0, 50.0)])
	bar.add_child(fill)

func _on_inventory_slot_gui_input(event: InputEvent, slot_index: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and slot_index < INVENTORY_UNLOCKED_SLOT_COUNT:
			_selected_inventory_slot = slot_index
			_inventory_press_slot = slot_index
			_inventory_press_time = 0.0
			_inventory_press_position = event.global_position
			_update_inventory_bar()
		elif not event.pressed and (_inventory_dragging_item or _inventory_press_slot != -1):
			_finish_inventory_drag(event.global_position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _inventory_dragging_item:
		_update_inventory_drag(event.global_position)
		get_viewport().set_input_as_handled()

func _update_inventory_press(delta: float) -> void:
	if _inventory_press_slot == -1 or _inventory_dragging_item:
		return
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_clear_inventory_drag_state()
		return
	_inventory_press_time += delta
	if _is_inventory_full() and _inventory_press_slot == _selected_inventory_slot and _is_inventory_item_discardable(_get_inventory_slot_item(_inventory_press_slot)):
		if _inventory_press_time >= INVENTORY_DISCARD_HOLD_TIME:
			_discard_inventory_slot(_inventory_press_slot)
			_clear_inventory_drag_state()
		return
	if _inventory_press_time >= INVENTORY_DRAG_HOLD_TIME:
		_start_inventory_drag(_inventory_press_slot)

func _try_start_discard_hold(source: String) -> bool:
	if not _is_inventory_full():
		return false
	if not _is_selected_inventory_item_discardable():
		_show_notification("物品栏满了，选择种子等消耗品长按丢弃")
		return false
	_discard_hold_active = true
	_discard_hold_time = 0.0
	_discard_hold_source = source
	_show_notification("继续长按丢弃当前物品")
	return true

func _update_discard_hold(delta: float) -> void:
	if not _discard_hold_active:
		return
	if _discard_hold_source == "keyboard" and not Input.is_key_pressed(KEY_F):
		_clear_discard_hold_state()
		return
	_discard_hold_time += delta
	if _discard_hold_time >= INVENTORY_DISCARD_HOLD_TIME:
		_discard_selected_inventory_item()
		_clear_discard_hold_state()

func _stop_discard_hold(source: String) -> void:
	if _discard_hold_active and _discard_hold_source == source:
		_clear_discard_hold_state()

func _clear_discard_hold_state() -> void:
	_discard_hold_active = false
	_discard_hold_time = 0.0
	_discard_hold_source = ""

func _start_inventory_drag(slot_index: int) -> void:
	var item := _get_inventory_slot_item(slot_index)
	if not _is_inventory_item_available(item):
		_clear_inventory_drag_state()
		return
	_inventory_dragging_item = true
	_inventory_drag_source_slot = slot_index
	_inventory_drag_hover_slot = slot_index
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_inventory_drag_ghost = _create_inventory_drag_ghost(item)
	_update_inventory_drag(_inventory_press_position)
	_update_inventory_bar()

func _update_inventory_drag(screen_position: Vector2) -> void:
	if _inventory_drag_ghost != null:
		_inventory_drag_ghost.global_position = screen_position - _inventory_drag_ghost.size * 0.5
	_inventory_drag_hover_slot = _get_inventory_slot_at_position(screen_position)
	_update_inventory_bar()

func _finish_inventory_drag(screen_position: Vector2) -> void:
	if _inventory_dragging_item:
		var target_slot := _get_inventory_slot_at_position(screen_position)
		if target_slot >= 0 and target_slot < INVENTORY_UNLOCKED_SLOT_COUNT and target_slot != _inventory_drag_source_slot:
			var source_item := _get_inventory_slot_item(_inventory_drag_source_slot)
			var target_item := _get_inventory_slot_item(target_slot)
			_set_inventory_slot_item(target_slot, source_item)
			_set_inventory_slot_item(_inventory_drag_source_slot, target_item)
			if _selected_inventory_slot == _inventory_drag_source_slot:
				_selected_inventory_slot = target_slot
			elif _selected_inventory_slot == target_slot:
				_selected_inventory_slot = _inventory_drag_source_slot
	_clear_inventory_drag_state()
	_update_inventory_bar()

func _get_inventory_slot_at_position(screen_position: Vector2) -> int:
	for index in range(mini(INVENTORY_UNLOCKED_SLOT_COUNT, _inventory_slots.size())):
		var slot := _inventory_slots[index]
		var rect := Rect2(slot.global_position, slot.size)
		if rect.has_point(screen_position):
			return index
	return -1

func _create_inventory_drag_ghost(item: String) -> Control:
	var ghost := PanelContainer.new()
	ghost.name = "InventoryDragGhost"
	ghost.size = Vector2(56.0, 56.0)
	ghost.custom_minimum_size = Vector2(56.0, 56.0)
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.modulate.a = 0.86
	ghost.add_theme_stylebox_override("panel", _make_round_style(Color(0.98, 0.84, 0.48, 0.92), Color(1.0, 0.98, 0.74, 1.0), 8.0, 3))
	if _hud_root != null:
		_hud_root.add_child(ghost)
	if _is_seed_item(item):
		var seed_icon := _create_seed_inventory_icon(ghost)
		_tint_seed_inventory_icon(seed_icon, _seed_item_crop_type(item), _seed_item_quality(item))
		var seed_count_label := _create_seed_count_label(ghost)
		seed_count_label.text = "x%d" % _get_seed_count_for_item(item)
		var seed_star_label := _create_seed_star_label(ghost)
		var quality := _seed_item_quality(item)
		seed_star_label.text = _quality_stars(quality)
		seed_star_label.visible = quality > 0
		var seed_type_label := _create_seed_type_label(ghost)
		seed_type_label.text = _crop_short_name(_seed_item_crop_type(item))
	else:
		match item:
			INVENTORY_ITEM_HAND:
				_create_hand_inventory_icon(ghost)
			INVENTORY_ITEM_HOE:
				_create_hoe_inventory_icon(ghost)
			INVENTORY_ITEM_WATERING_CAN:
				_create_watering_can_inventory_icon(ghost)
			INVENTORY_ITEM_SCYTHE:
				_create_scythe_inventory_icon(ghost)
			INVENTORY_ITEM_FOOD_CHEST:
				_create_food_chest_inventory_icon(ghost)
	ghost.move_to_front()
	return ghost

func _clear_inventory_drag_state() -> void:
	if _inventory_drag_ghost != null and is_instance_valid(_inventory_drag_ghost):
		_inventory_drag_ghost.queue_free()
	_inventory_press_slot = -1
	_inventory_press_time = 0.0
	_inventory_press_position = Vector2.ZERO
	_inventory_dragging_item = false
	_inventory_drag_source_slot = -1
	_inventory_drag_hover_slot = -1
	_inventory_drag_ghost = null

func _select_inventory_delta(delta: int) -> void:
	if not _has_inventory_items():
		return
	_selected_inventory_slot = wrapi(_selected_inventory_slot + delta, 0, INVENTORY_UNLOCKED_SLOT_COUNT)
	_update_inventory_bar()

func _select_interaction_option_delta(delta: int) -> bool:
	_update_interaction_options()
	if _interaction_options.size() <= 1:
		return false
	_interaction_option_index = wrapi(_interaction_option_index + delta, 0, _interaction_options.size())
	_show_interaction_options_prompt()
	return true

func _try_execute_selected_interaction_option() -> bool:
	_update_interaction_options()
	if _interaction_options.is_empty():
		return false
	_interaction_option_index = clampi(_interaction_option_index, 0, _interaction_options.size() - 1)
	var option := _interaction_options[_interaction_option_index]
	var action := str(option.get("action", ""))
	match action:
		"pickup_seed":
			return _try_pickup_dropped_seed()
		"pickup_crop":
			return _try_pickup_dropped_crop()
		"harvest_crop":
			return _try_harvest_crop()
		"clear_rotten_crop":
			return _try_clear_rotten_crop_with_hoe()
		"food_chest":
			return _try_interact_food_chest()
		"view_placed_food_chest":
			return _open_food_chest_inventory_panel()
		"pickup_placed_food_chest":
			return _try_pickup_placed_food_chest()
		"place_food_chest":
			return _try_place_food_chest_from_inventory()
		"kitchen_take_order_ingredient":
			return _try_take_kitchen_order_ingredient()
		"open_kitchen_equipment":
			return _open_kitchen_equipment_panel()
		"start_kitchen_business":
			return _start_first_kitchen_business()
		"use_kitchen_equipment":
			return _use_nearest_kitchen_equipment()
		"house_door":
			return _try_use_house_door()
		"camper":
			return _try_enter_camper()
		"mom":
			return _try_start_mom_dialogue()
		"rebas_shop":
			return _try_start_rebas_shop()
	return false

func _update_interaction_options() -> void:
	_interaction_options.clear()
	if _dialogue_open or _map_open or _kitchen_equipment_panel_open or (_food_chest_overlay != null and _food_chest_overlay.visible) or (_reward_overlay != null and _reward_overlay.visible):
		_interaction_option_index = 0
		return
	if _held_crop_item == "" and _find_near_dropped_seed() != null:
		_interaction_options.append({"action": "pickup_seed", "text": "鎹¤捣绉嶅瓙"})
	if _held_crop_item == "":
		if _find_near_dropped_crop() != null:
			_interaction_options.append({"action": "pickup_crop", "text": "捡起食材"})
		elif _find_harvestable_crop_key() != "":
			_interaction_options.append({"action": "harvest_crop", "text": "收获作物"})
	if _find_rotten_crop_key_in_front() != "" and _has_hoe and _get_inventory_slot_item(_selected_inventory_slot) == INVENTORY_ITEM_HOE:
		_interaction_options.append({"action": "clear_rotten_crop", "text": "清理腐烂作物"})
	if _inside_house and _is_player_near_food_chest():
		_interaction_options.append({"action": "food_chest", "text": "查看食材箱子"})
	if _is_player_near_placed_food_chest() and _kitchen_business_active:
		_interaction_options.append({"action": "kitchen_take_order_ingredient", "text": "取订单食材"})
	if _is_player_near_placed_food_chest():
		_interaction_options.append({"action": "view_placed_food_chest", "text": "查看食材箱子"})
		_interaction_options.append({"action": "pickup_placed_food_chest", "text": "收起食材箱子"})
	if _can_place_selected_food_chest():
		_interaction_options.append({"action": "place_food_chest", "text": "摆放食材箱子"})
	var nearest_equipment := _nearest_kitchen_equipment_id()
	if nearest_equipment != "":
		_interaction_options.append({"action": "use_kitchen_equipment", "text": "使用%s" % _equipment_name(nearest_equipment)})
	if _is_player_near_house_entry() or _is_player_near_house_exit():
		_interaction_options.append({"action": "house_door", "text": "离开房子" if _inside_house else "进入房子"})
	if _is_player_near_camper() and not (_can_talk_to_mom() and _is_player_near_mom()):
		if _chest_lesson_completed:
			_interaction_options.append({"action": "open_kitchen_equipment", "text": "打开设备栏"})
		if _can_start_first_kitchen_business():
			_interaction_options.append({"action": "start_kitchen_business", "text": "开始第一次营业"})
		_interaction_options.append({"action": "camper", "text": "进入房车地图"})
	if _is_player_near_mom() and _can_talk_to_mom():
		_interaction_options.append({"action": "mom", "text": "与%s对话" % MOM_NAME})
	if _is_player_near_rebas():
		_interaction_options.append({"action": "rebas_shop", "text": "与%s交换" % REBAS_NAME})
	if _interaction_option_index >= _interaction_options.size():
		_interaction_option_index = 0

func _show_interaction_options_prompt() -> bool:
	if _interaction_prompt == null or _interaction_prompt_label == null:
		return false
	if _interaction_options.is_empty():
		return false
	if _interaction_options.size() == 1:
		var option := _interaction_options[0]
		_interaction_prompt_label.text = "F / 点击  %s" % str(option.get("text", ""))
		_interaction_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if not _is_repeatable_interaction_action(str(option.get("action", ""))) and _has_shown_interaction_prompt(_interaction_prompt_label.text):
			_interaction_prompt.visible = false
			return false
		if not _is_repeatable_interaction_action(str(option.get("action", ""))):
			_mark_interaction_prompt_shown(_interaction_prompt_label.text)
		_fit_interaction_prompt_to_lines([_interaction_prompt_label.text])
		_interaction_prompt.visible = true
		_interaction_prompt.move_to_front()
		return true
	var lines: Array[String] = []
	for index in range(_interaction_options.size()):
		var prefix := "▶" if index == _interaction_option_index else "  "
		var option := _interaction_options[index]
		lines.append("%sF / 点击  %s" % [prefix, str(option.get("text", ""))])
	_interaction_prompt_label.text = "\n".join(lines)
	_interaction_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_fit_interaction_prompt_to_lines(lines)
	_interaction_prompt.visible = true
	_interaction_prompt.move_to_front()
	return true

func _is_repeatable_interaction_action(action: String) -> bool:
	return action in ["use_kitchen_equipment", "open_kitchen_equipment", "start_kitchen_business", "kitchen_take_order_ingredient", "camper", "rebas_shop"]

func _has_shown_interaction_prompt(text: String) -> bool:
	return _shown_interaction_prompt_texts.has(text.strip_edges())

func _mark_interaction_prompt_shown(text: String) -> void:
	_shown_interaction_prompt_texts[text.strip_edges()] = true

func _reset_interaction_prompt_layout() -> void:
	_fit_interaction_prompt_to_lines([_notification_text])
	if _interaction_prompt_label != null:
		_interaction_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _fit_interaction_prompt_to_lines(lines: Array[String]) -> void:
	if _interaction_prompt != null:
		var longest_width := 0.0
		for line in lines:
			longest_width = maxf(longest_width, _estimate_prompt_text_width(line))
		var panel_width := clampf(longest_width + 44.0, 190.0, 500.0)
		var panel_height := maxf(54.0, 18.0 + float(maxi(lines.size(), 1)) * 30.0)
		_interaction_prompt.offset_left = -24.0 - panel_width
		_interaction_prompt.offset_top = -92.0 - panel_height
		_interaction_prompt.offset_right = -24.0
		_interaction_prompt.offset_bottom = -92.0

func _estimate_prompt_text_width(text: String) -> float:
	var width := 0.0
	for i in range(text.length()):
		var code := text.unicode_at(i)
		if code == 10:
			continue
		width += 18.0 if code > 127 else 9.5
	return width

func _reset_kitchen_state() -> void:
	_kitchen_equipment_roots.clear()
	_kitchen_equipment_preview = null
	_kitchen_equipment_panel_open = false
	_kitchen_placing_equipment = ""
	_kitchen_placing_yaw = 0.0
	_kitchen_washed_carrot = 0
	_kitchen_chopped_carrot = 0
	_kitchen_served_count = 0
	_kitchen_failed_count = 0
	_kitchen_business_active = false
	_kitchen_first_day_completed = false
	_kitchen_business_time = 0.0
	_kitchen_orders.clear()
	_kitchen_pot_state.clear()
	_kitchen_grill_state.clear()
	_kitchen_ready_dishes.clear()
	_kitchen_scrap_dishes.clear()
	_kitchen_scrap_income = 0
	_kitchen_held_item = ""
	_kitchen_held_recipe = ""
	if _kitchen_held_visual != null and is_instance_valid(_kitchen_held_visual):
		_kitchen_held_visual.queue_free()
	_kitchen_held_visual = null
	_kitchen_equipment_bubbles.clear()
	_kitchen_equipment_progress.clear()
	if _kitchen_equipment_panel != null:
		_kitchen_equipment_panel.visible = false
	if _kitchen_status_panel != null:
		_kitchen_status_panel.visible = false

func _open_kitchen_equipment_panel() -> bool:
	if _inside_house:
		return false
	if _kitchen_equipment_panel == null:
		return false
	_kitchen_equipment_panel_open = true
	_kitchen_equipment_panel.visible = true
	_kitchen_equipment_panel.move_to_front()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	return true

func _close_kitchen_equipment_panel() -> void:
	_kitchen_equipment_panel_open = false
	if _kitchen_equipment_panel != null:
		_kitchen_equipment_panel.visible = false

func _start_kitchen_equipment_placement(equipment_id: String) -> void:
	if _equipment_definition(equipment_id).is_empty():
		return
	_kitchen_placing_equipment = equipment_id
	_kitchen_placing_yaw = _get_player_visual_yaw() + PI
	_close_kitchen_equipment_panel()
	_mouse_released_by_escape = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_update_kitchen_equipment_placement_preview()
	_show_notification("F / 点击确认摆放，ESC 取消")

func _handle_kitchen_placement_input(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_cancel_kitchen_equipment_placement()
		get_viewport().set_input_as_handled()
		return true
	if event is InputEventKey and event.pressed and event.keycode == KEY_F:
		_place_selected_kitchen_equipment()
		get_viewport().set_input_as_handled()
		return true
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_kitchen_placing_yaw -= PI * 0.125
			get_viewport().set_input_as_handled()
			return true
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_kitchen_placing_yaw += PI * 0.125
			get_viewport().set_input_as_handled()
			return true
		if event.button_index == MOUSE_BUTTON_LEFT:
			_place_selected_kitchen_equipment()
			get_viewport().set_input_as_handled()
			return true
	return false

func _cancel_kitchen_equipment_placement() -> void:
	_kitchen_placing_equipment = ""
	if _kitchen_equipment_preview != null and is_instance_valid(_kitchen_equipment_preview):
		_kitchen_equipment_preview.queue_free()
	_kitchen_equipment_preview = null

func _update_kitchen_equipment_placement_preview() -> void:
	if _kitchen_placing_equipment == "":
		if _kitchen_equipment_preview != null and is_instance_valid(_kitchen_equipment_preview):
			_kitchen_equipment_preview.visible = false
		return
	var position := _get_kitchen_equipment_place_position()
	var valid := _is_kitchen_equipment_place_position_valid(position)
	if _kitchen_equipment_preview == null or not is_instance_valid(_kitchen_equipment_preview) or str(_kitchen_equipment_preview.get_meta("equipment_id", "")) != _kitchen_placing_equipment:
		if _kitchen_equipment_preview != null and is_instance_valid(_kitchen_equipment_preview):
			_kitchen_equipment_preview.queue_free()
		_kitchen_equipment_preview = _create_kitchen_equipment_model(self, _kitchen_placing_equipment, "KitchenEquipmentPreview", position, true)
		_mark_generated(_kitchen_equipment_preview)
	_kitchen_equipment_preview.visible = true
	_kitchen_equipment_preview.global_position = position
	_kitchen_equipment_preview.rotation.y = _kitchen_placing_yaw
	_set_kitchen_preview_valid(valid)

func _place_selected_kitchen_equipment() -> void:
	if _kitchen_placing_equipment == "":
		return
	var position := _get_kitchen_equipment_place_position()
	if not _is_kitchen_equipment_place_position_valid(position):
		_show_notification("设备只能放在陆地上，不能和已有物体重叠")
		return
	var existing := _kitchen_equipment_roots.get(_kitchen_placing_equipment) as Node3D
	_remove_kitchen_equipment_blocker(_kitchen_placing_equipment)
	if existing != null and is_instance_valid(existing):
		existing.global_position = position
		existing.rotation.y = _kitchen_placing_yaw
		_add_kitchen_equipment_blocker(existing, _kitchen_placing_equipment)
	else:
		var placed := _create_kitchen_equipment_model(self, _kitchen_placing_equipment, "Kitchen_%s" % _kitchen_placing_equipment, position, false)
		placed.rotation.y = _kitchen_placing_yaw
		_remove_kitchen_equipment_blocker(_kitchen_placing_equipment)
		_add_kitchen_equipment_blocker(placed, _kitchen_placing_equipment)
		_mark_generated(placed)
		_kitchen_equipment_roots[_kitchen_placing_equipment] = placed
	var placed_name := _equipment_name(_kitchen_placing_equipment)
	_cancel_kitchen_equipment_placement()
	_show_side_toast("%s 已摆好" % placed_name)

func _get_kitchen_equipment_place_position() -> Vector3:
	if _player == null:
		return Vector3.ZERO
	var yaw := _get_player_visual_yaw()
	var forward := Vector3(sin(yaw), 0.0, cos(yaw))
	var position := _player.global_position + forward * KITCHEN_EQUIPMENT_PREVIEW_DISTANCE
	position.y = _height_at(position.x, position.z)
	return position

func _is_kitchen_equipment_place_position_valid(position: Vector3) -> bool:
	if _inside_house:
		return false
	var point := Vector2(position.x, position.z)
	if _is_kitchen_equipment_footprint_over_pond(point, _kitchen_placing_yaw):
		return false
	if _is_kitchen_equipment_footprint_blocked(point, _kitchen_placing_yaw, _kitchen_placing_equipment):
		return false
	return true

func _is_kitchen_equipment_footprint_over_pond(center: Vector2, yaw: float) -> bool:
	for sample in _kitchen_equipment_footprint_samples(center, yaw):
		if _is_inside_pond(sample.x, sample.y, KITCHEN_EQUIPMENT_POND_PADDING):
			return true
	return false

func _is_kitchen_equipment_footprint_blocked(center: Vector2, yaw: float, equipment_id: String) -> bool:
	for blocker in _solid_blockers:
		if str(blocker.get("kitchen_equipment_id", "")) == equipment_id:
			continue
		if _does_kitchen_equipment_footprint_overlap_blocker(center, yaw, blocker):
			return true
	return false

func _does_kitchen_equipment_footprint_overlap_blocker(center: Vector2, yaw: float, blocker: Dictionary) -> bool:
	if bool(blocker.get("house_interior_only", false)) and not _inside_house:
		return false
	var shape: String = blocker["shape"]
	var blocker_center_3d: Vector3 = blocker["center"]
	var blocker_center := Vector2(blocker_center_3d.x, blocker_center_3d.z)
	if shape == "box":
		var blocker_yaw: float = blocker["yaw"]
		var blocker_half_extents: Vector2 = blocker["half_extents"]
		return _oriented_boxes_overlap(center, yaw, KITCHEN_EQUIPMENT_FOOTPRINT_HALF_EXTENTS, blocker_center, blocker_yaw, blocker_half_extents)
	if shape == "circle" or shape == "tree":
		var local := (blocker_center - center).rotated(-yaw)
		var half := KITCHEN_EQUIPMENT_FOOTPRINT_HALF_EXTENTS
		var closest := Vector2(clampf(local.x, -half.x, half.x), clampf(local.y, -half.y, half.y))
		var radius: float = blocker["radius"]
		return local.distance_squared_to(closest) <= radius * radius
	return false

func _kitchen_equipment_footprint_samples(center: Vector2, yaw: float) -> Array[Vector2]:
	var half := KITCHEN_EQUIPMENT_FOOTPRINT_HALF_EXTENTS
	var local_points := [
		Vector2.ZERO,
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(-half.x, half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, 0.0),
		Vector2(half.x, 0.0),
		Vector2(0.0, -half.y),
		Vector2(0.0, half.y),
	]
	var samples: Array[Vector2] = []
	for local in local_points:
		samples.append(center + local.rotated(yaw))
	return samples

func _oriented_boxes_overlap(center_a: Vector2, yaw_a: float, half_a: Vector2, center_b: Vector2, yaw_b: float, half_b: Vector2) -> bool:
	var axes := [
		Vector2(cos(yaw_a), sin(yaw_a)),
		Vector2(-sin(yaw_a), cos(yaw_a)),
		Vector2(cos(yaw_b), sin(yaw_b)),
		Vector2(-sin(yaw_b), cos(yaw_b)),
	]
	for axis in axes:
		var projection_a := half_a.x * absf(axis.dot(axes[0])) + half_a.y * absf(axis.dot(axes[1]))
		var projection_b := half_b.x * absf(axis.dot(axes[2])) + half_b.y * absf(axis.dot(axes[3]))
		var center_distance := absf(axis.dot(center_b - center_a))
		if center_distance > projection_a + projection_b:
			return false
	return true

func _create_kitchen_equipment_model(parent: Node3D, equipment_id: String, root_name: String, position: Vector3, preview: bool = false) -> Node3D:
	var root := Node3D.new()
	root.name = root_name
	root.position = position
	root.set_meta("equipment_id", equipment_id)
	parent.add_child(root)
	var definition := _equipment_definition(equipment_id)
	var scene_path := str(definition.get("path", ""))
	var scene := load(scene_path)
	if scene is PackedScene:
		var model := scene.instantiate() as Node3D
		if model != null:
			model.name = "EquipmentModel"
			root.add_child(model)
			_fit_model_to_max_dimension(model, 2.0)
			_center_model_on_origin(model)
			_ground_model(model)
			_snap_model_to_world_ground(root, model, position.y)
			root.global_position.y += _kitchen_equipment_ground_lift(equipment_id)
			_set_model_shadow(model, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
			if preview:
				_apply_preview_material(model, Color(0.78, 0.72, 0.56, 0.42))
			else:
				_create_kitchen_equipment_base(root)
				_add_kitchen_equipment_blocker(root, equipment_id)
				_create_kitchen_equipment_bubble(root, equipment_id)
			return root
	var fallback_alpha := 0.42 if preview else 1.0
	var fallback := _make_material(Color(0.62, 0.46, 0.26, fallback_alpha), 0.82)
	if preview:
		fallback.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		fallback.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_create_box_mesh(root, "EquipmentFallback", Vector3(0.0, 0.35, 0.0), Vector3(1.35, 0.70, 0.85), fallback)
	if not preview:
		_create_kitchen_equipment_base(root)
		_add_kitchen_equipment_blocker(root, equipment_id)
		_create_kitchen_equipment_bubble(root, equipment_id)
	return root

func _remove_kitchen_equipment_blocker(equipment_id: String) -> void:
	for index in range(_solid_blockers.size() - 1, -1, -1):
		if str(_solid_blockers[index].get("kitchen_equipment_id", "")) == equipment_id:
			_solid_blockers.remove_at(index)

func _add_kitchen_equipment_blocker(root: Node3D, equipment_id: String) -> void:
	_solid_blockers.append({
		"shape": "box",
		"center": root.global_position,
		"yaw": root.rotation.y,
		"half_extents": KITCHEN_EQUIPMENT_FOOTPRINT_HALF_EXTENTS,
		"kitchen_equipment_id": equipment_id,
	})

func _kitchen_equipment_ground_lift(equipment_id: String) -> float:
	match equipment_id:
		"sink":
			return 0.24
	return 0.0

func _snap_model_to_world_ground(root: Node3D, model: Node3D, ground_y: float) -> void:
	var bounds := _get_model_bounds(model)
	if bounds.size == Vector3.ZERO:
		return
	var world_bottom := model.global_transform * Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z)
	root.global_position.y += ground_y - world_bottom.y + 0.03

func _create_kitchen_equipment_base(root: Node3D) -> void:
	var base_mat := _make_material(Color(0.88, 0.78, 0.54, 0.96), 0.78)
	_create_box_mesh(root, "KitchenEquipmentBase", Vector3(0.0, 0.025, 0.0), Vector3(2.15, 0.05, 1.75), base_mat)

func _apply_preview_material(root: Node3D, color: Color) -> void:
	for mesh in _collect_mesh_instances(root):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mesh.material_override = mat

func _set_kitchen_preview_valid(valid: bool) -> void:
	if _kitchen_equipment_preview == null or not is_instance_valid(_kitchen_equipment_preview):
		return
	var color := Color(0.68, 0.95, 0.62, 0.46) if valid else Color(1.0, 0.34, 0.24, 0.46)
	_apply_preview_material(_kitchen_equipment_preview, color)

func _equipment_definition(equipment_id: String) -> Dictionary:
	for equipment in KITCHEN_EQUIPMENT_TYPES:
		if str(equipment.get("id", "")) == equipment_id:
			return equipment
	return {}

func _equipment_name(equipment_id: String) -> String:
	return str(_equipment_definition(equipment_id).get("name", equipment_id))

func _nearest_kitchen_equipment_id() -> String:
	if _player == null:
		return ""
	var player_point := Vector2(_player.global_position.x, _player.global_position.z)
	var best_id := ""
	var best_distance := INF
	for raw_id in _kitchen_equipment_roots.keys():
		var equipment_id := str(raw_id)
		var root := _kitchen_equipment_roots[equipment_id] as Node3D
		if root == null or not is_instance_valid(root):
			continue
		var distance := player_point.distance_squared_to(Vector2(root.global_position.x, root.global_position.z))
		if distance <= KITCHEN_EQUIPMENT_INTERACT_RADIUS * KITCHEN_EQUIPMENT_INTERACT_RADIUS and distance < best_distance:
			best_distance = distance
			best_id = equipment_id
	return best_id

func _use_nearest_kitchen_equipment() -> bool:
	var equipment_id := _nearest_kitchen_equipment_id()
	if equipment_id == "":
		return false
	match equipment_id:
		"sink":
			return _use_kitchen_sink()
		"cutting_table":
			return _use_kitchen_cutting_table()
		"pot":
			return _use_kitchen_pot()
		"grill":
			return _use_kitchen_grill()
		"prep_shelf":
			return _use_kitchen_prep_shelf()
	return false

func _use_kitchen_sink() -> bool:
	if _finish_kitchen_progress("sink"):
		return true
	if _kitchen_held_item != "raw_carrot":
		_show_notification("先从食材箱取订单需要的胡萝卜")
		return true
	_start_kitchen_progress("sink", "washing", KITCHEN_PREP_SECONDS, "washed_carrot", _kitchen_held_recipe)
	_clear_kitchen_held_item()
	_show_side_toast("胡萝卜放进洗菜池")
	return true

func _use_kitchen_cutting_table() -> bool:
	if _finish_kitchen_progress("cutting_table"):
		return true
	if _kitchen_held_item != "washed_carrot":
		_show_notification("先把洗好的胡萝卜拿到切菜桌")
		return true
	_start_kitchen_progress("cutting_table", "cutting", KITCHEN_PREP_SECONDS, "chopped_carrot", _kitchen_held_recipe)
	_clear_kitchen_held_item()
	_show_side_toast("开始切胡萝卜")
	return true

func _use_kitchen_pot() -> bool:
	if _kitchen_pot_state.is_empty():
		if _kitchen_held_item != "chopped_carrot":
			_show_notification("胡萝卜清汤需要切好的胡萝卜")
			return true
		_kitchen_pot_state = {"recipe": KITCHEN_RECIPE_SOUP, "time": 0.0, "stage": "cooking"}
		_clear_kitchen_held_item()
		_show_side_toast("胡萝卜清汤下锅了")
		return true
	return _finish_kitchen_cook_state(_kitchen_pot_state, "pot")

func _use_kitchen_grill() -> bool:
	if _kitchen_grill_state.is_empty():
		if _kitchen_held_item != "raw_carrot":
			_show_notification("烤胡萝卜需要从食材箱拿胡萝卜")
			return true
		_kitchen_grill_state = {"recipe": KITCHEN_RECIPE_GRILLED, "time": 0.0, "stage": "cooking"}
		_clear_kitchen_held_item()
		_show_side_toast("胡萝卜放上烤架了")
		return true
	return _finish_kitchen_cook_state(_kitchen_grill_state, "grill")

func _use_kitchen_prep_shelf() -> bool:
	if not _kitchen_business_active:
		_show_notification("备菜架也是出餐台，营业时把菜端到这里")
		return true
	if _serve_ready_kitchen_dish():
		return true
	_show_notification("备菜架暂无可出的菜：" + _kitchen_order_summary())
	return true

func _finish_kitchen_cook_state(state: Dictionary, station: String) -> bool:
	var stage := str(state.get("stage", "cooking"))
	var recipe := str(state.get("recipe", ""))
	if stage == "cooking":
		_show_notification("还没熟，先去忙别的")
		return true
	if stage == "burnt":
		if station == "pot":
			_kitchen_pot_state.clear()
		else:
			_kitchen_grill_state.clear()
		_kitchen_failed_count += 1
		_kitchen_scrap_dishes[recipe] = int(_kitchen_scrap_dishes.get(recipe, 0)) + 1
		_show_notification("糊掉了，端到备菜架低价处理")
		return true
	_kitchen_ready_dishes[recipe] = int(_kitchen_ready_dishes.get(recipe, 0)) + 1
	_show_side_toast("%s 已装盘，去备菜架出餐" % _recipe_name(recipe))
	if station == "pot":
		_kitchen_pot_state.clear()
	else:
		_kitchen_grill_state.clear()
	return true

func _try_take_kitchen_order_ingredient() -> bool:
	if not _kitchen_business_active:
		return false
	if _kitchen_held_item != "":
		_show_notification("手上已经拿着%s" % _kitchen_item_name(_kitchen_held_item))
		return true
	var recipe := _next_kitchen_recipe_needing_ingredient()
	if recipe == "":
		_show_notification("现在没有待做订单")
		return true
	if not _take_any_stored_crop(CROP_CARROT, 1):
		_show_notification("食材箱里没有胡萝卜")
		return true
	_set_kitchen_held_item("raw_carrot", recipe)
	_show_side_toast("取出%s需要的胡萝卜" % _recipe_name(recipe))
	return true

func _next_kitchen_recipe_needing_ingredient() -> String:
	var best_recipe := ""
	var best_time := INF
	for order in _kitchen_orders:
		var recipe := str(order.get("recipe", ""))
		var remaining := float(order.get("time", 0.0))
		if remaining < best_time:
			best_time = remaining
			best_recipe = recipe
	return best_recipe

func _start_kitchen_progress(station: String, action: String, duration: float, result_item: String, recipe: String) -> void:
	_kitchen_equipment_progress[station] = {
		"action": action,
		"time": duration,
		"duration": duration,
		"result": result_item,
		"recipe": recipe,
		"done": false,
	}

func _finish_kitchen_progress(station: String) -> bool:
	if not _kitchen_equipment_progress.has(station):
		return false
	var progress := _kitchen_equipment_progress[station] as Dictionary
	if not bool(progress.get("done", false)):
		_show_notification("%s %.0fs" % [_kitchen_progress_action_name(str(progress.get("action", ""))), float(progress.get("time", 0.0))])
		return true
	if _kitchen_held_item != "":
		_show_notification("先把手上的%s送去下一台设备" % _kitchen_item_name(_kitchen_held_item))
		return true
	_set_kitchen_held_item(str(progress.get("result", "")), str(progress.get("recipe", "")))
	_kitchen_equipment_progress.erase(station)
	_show_side_toast("拿起%s" % _kitchen_item_name(_kitchen_held_item))
	return true

func _update_kitchen_equipment_progress(delta: float) -> void:
	for station in _kitchen_equipment_progress.keys():
		var progress := _kitchen_equipment_progress[station] as Dictionary
		if bool(progress.get("done", false)):
			continue
		var time := maxf(float(progress.get("time", 0.0)) - delta, 0.0)
		progress["time"] = time
		if time <= 0.0:
			progress["done"] = true
		_kitchen_equipment_progress[station] = progress

func _set_kitchen_held_item(item: String, recipe: String) -> void:
	_kitchen_held_item = item
	_kitchen_held_recipe = recipe
	_update_kitchen_held_visual(true)

func _clear_kitchen_held_item() -> void:
	_kitchen_held_item = ""
	_kitchen_held_recipe = ""
	if _kitchen_held_visual != null and is_instance_valid(_kitchen_held_visual):
		_kitchen_held_visual.queue_free()
	_kitchen_held_visual = null

func _update_kitchen_held_visual(force_rebuild: bool = false) -> void:
	if _player == null:
		return
	if _kitchen_held_item == "":
		if _kitchen_held_visual != null and is_instance_valid(_kitchen_held_visual):
			_kitchen_held_visual.queue_free()
		_kitchen_held_visual = null
		return
	if force_rebuild or _kitchen_held_visual == null or not is_instance_valid(_kitchen_held_visual):
		if _kitchen_held_visual != null and is_instance_valid(_kitchen_held_visual):
			_kitchen_held_visual.queue_free()
		_kitchen_held_visual = _create_kitchen_held_item_model(_kitchen_held_item)
		_mark_generated(_kitchen_held_visual)
		_player.add_child(_kitchen_held_visual)
	_kitchen_held_visual.position = Vector3(0.42, 1.08, 0.48)
	_kitchen_held_visual.rotation_degrees = Vector3(64.0, -18.0, -24.0)

func _create_kitchen_held_item_model(item: String) -> Node3D:
	var root := Node3D.new()
	root.name = "KitchenHeldItem"
	var color := Color(0.95, 0.48, 0.18)
	if item == "washed_carrot":
		color = Color(1.0, 0.66, 0.26)
	elif item == "chopped_carrot":
		color = Color(1.0, 0.78, 0.32)
	var mat := _make_material(color, 0.72)
	var mesh_instance := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.12
	mesh.height = 0.52
	mesh_instance.mesh = mesh
	mesh_instance.material_override = mat
	root.add_child(mesh_instance)
	if item == "chopped_carrot":
		root.scale = Vector3(0.82, 0.82, 0.82)
	return root

func _create_kitchen_equipment_bubble(root: Node3D, equipment_id: String) -> void:
	var bubble := Label3D.new()
	bubble.name = "KitchenBubble"
	bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bubble.no_depth_test = true
	bubble.font_size = 26
	bubble.modulate = Color(0.25, 0.17, 0.08, 1.0)
	bubble.outline_size = 8
	bubble.outline_modulate = Color(0.98, 0.86, 0.55, 0.92)
	bubble.position = Vector3(0.0, 2.25, 0.0)
	root.add_child(bubble)
	var bar_back_mat := _make_material(Color(0.30, 0.21, 0.11, 0.72), 0.8)
	var bar_fill_mat := _make_material(Color(0.98, 0.72, 0.26, 0.95), 0.65)
	var bar_back := _create_box_mesh(root, "KitchenProgressBack", Vector3(0.0, 2.02, 0.0), Vector3(1.15, 0.055, 0.055), bar_back_mat)
	var bar_fill := _create_box_mesh(root, "KitchenProgressFill", Vector3(0.0, 2.025, 0.0), Vector3(1.08, 0.065, 0.065), bar_fill_mat)
	bar_back.visible = false
	bar_fill.visible = false
	_kitchen_equipment_bubbles[equipment_id] = bubble

func _update_kitchen_equipment_bubbles() -> void:
	for raw_id in _kitchen_equipment_bubbles.keys():
		var equipment_id := str(raw_id)
		var bubble := _kitchen_equipment_bubbles[equipment_id] as Label3D
		if bubble == null or not is_instance_valid(bubble):
			continue
		var text := _kitchen_equipment_bubble_text(equipment_id)
		bubble.text = text
		bubble.visible = text != ""
		_update_kitchen_equipment_progress_bar(equipment_id)
	_update_food_chest_order_bubble()

func _update_kitchen_equipment_progress_bar(equipment_id: String) -> void:
	var root := _kitchen_equipment_roots.get(equipment_id) as Node3D
	if root == null or not is_instance_valid(root):
		return
	var back := root.get_node_or_null("KitchenProgressBack") as MeshInstance3D
	var fill := root.get_node_or_null("KitchenProgressFill") as MeshInstance3D
	if back == null or fill == null:
		return
	var show_bar := _kitchen_equipment_progress.has(equipment_id)
	back.visible = show_bar
	fill.visible = show_bar
	if not show_bar:
		return
	var progress := _kitchen_equipment_progress[equipment_id] as Dictionary
	var duration := maxf(float(progress.get("duration", 1.0)), 0.01)
	var ratio := 1.0 - clampf(float(progress.get("time", 0.0)) / duration, 0.0, 1.0)
	if bool(progress.get("done", false)):
		ratio = 1.0
	fill.scale.x = maxf(ratio, 0.04)
	fill.position.x = -0.54 + 0.54 * ratio

func _kitchen_equipment_bubble_text(equipment_id: String) -> String:
	if _kitchen_equipment_progress.has(equipment_id):
		var progress := _kitchen_equipment_progress[equipment_id] as Dictionary
		if bool(progress.get("done", false)):
			return "完成：%s\nF 取走" % _kitchen_item_name(str(progress.get("result", "")))
		return "%s %.0fs" % [_kitchen_progress_action_name(str(progress.get("action", ""))), float(progress.get("time", 0.0))]
	match equipment_id:
		"sink":
			return "需要：胡萝卜" if _kitchen_held_item == "raw_carrot" else ""
		"cutting_table":
			return "需要：洗好胡萝卜" if _kitchen_held_item == "washed_carrot" else ""
		"pot":
			if not _kitchen_pot_state.is_empty():
				return _cook_state_text(_kitchen_pot_state, KITCHEN_COOK_SOUP_SECONDS)
			return "清汤：切好胡萝卜" if _kitchen_held_item == "chopped_carrot" else ""
		"grill":
			if not _kitchen_grill_state.is_empty():
				return _cook_state_text(_kitchen_grill_state, KITCHEN_COOK_GRILL_SECONDS)
			return "烤胡萝卜：胡萝卜" if _kitchen_held_item == "raw_carrot" else ""
		"prep_shelf":
			var ready := _kitchen_ready_dish_summary()
			if ready != "":
				return "出餐：" + ready
			var scrap := _kitchen_scrap_dish_summary()
			return "处理：" + scrap if scrap != "" else ""
	return ""

func _update_food_chest_order_bubble() -> void:
	if _placed_food_chests.is_empty():
		return
	var chest := _placed_food_chests[0] as Node3D
	if chest == null or not is_instance_valid(chest):
		return
	var bubble := chest.get_node_or_null("KitchenOrderBubble") as Label3D
	if bubble == null:
		bubble = Label3D.new()
		bubble.name = "KitchenOrderBubble"
		bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		bubble.no_depth_test = true
		bubble.font_size = 25
		bubble.modulate = Color(0.24, 0.15, 0.08, 1.0)
		bubble.outline_size = 8
		bubble.outline_modulate = Color(0.98, 0.86, 0.55, 0.92)
		bubble.position = Vector3(0.0, 1.6, 0.0)
		chest.add_child(bubble)
	var recipe := _next_kitchen_recipe_needing_ingredient()
	if _kitchen_business_active and recipe != "":
		bubble.text = "订单食材\n%s：胡萝卜" % _recipe_name(recipe)
		bubble.visible = true
	else:
		bubble.visible = false

func _kitchen_item_name(item: String) -> String:
	match item:
		"raw_carrot":
			return "胡萝卜"
		"washed_carrot":
			return "洗好胡萝卜"
		"chopped_carrot":
			return "切好胡萝卜"
	return item

func _kitchen_progress_action_name(action: String) -> String:
	match action:
		"washing":
			return "清洗中"
		"cutting":
			return "切菜中"
	return "处理中"

func _take_stored_crop(crop_type: String, quality: int, amount: int) -> bool:
	var key := _stored_crop_key(crop_type, quality)
	var current := int(_stored_crop_counts.get(key, 0))
	if current < amount:
		return false
	current -= amount
	if current <= 0:
		_stored_crop_counts.erase(key)
	else:
		_stored_crop_counts[key] = current
	return true

func _take_any_stored_crop(crop_type: String, amount: int) -> bool:
	for quality in range(4):
		if _take_stored_crop(crop_type, quality, amount):
			return true
	return false

func _can_start_first_kitchen_business() -> bool:
	return not _kitchen_first_day_completed and not _kitchen_business_active and _has_all_first_day_kitchen_equipment() and not _placed_food_chests.is_empty()

func _has_all_first_day_kitchen_equipment() -> bool:
	return _has_kitchen_equipment("sink") and _has_kitchen_equipment("cutting_table") and _has_kitchen_equipment("pot") and _has_kitchen_equipment("grill") and _has_kitchen_equipment("prep_shelf")

func _has_kitchen_equipment(equipment_id: String) -> bool:
	var root := _kitchen_equipment_roots.get(equipment_id) as Node3D
	return root != null and is_instance_valid(root)

func _start_first_kitchen_business() -> bool:
	if not _can_start_first_kitchen_business():
		_show_notification("鍏堟憜濂介鏉愮銆佹礂鑿滄睜銆佸垏鑿滄銆佺叜閿呫€佺儳鐑ゆ灦鍜屽鑿滄灦")
		return true
	_kitchen_business_active = true
	_kitchen_business_time = KITCHEN_FIRST_DAY_DURATION
	_kitchen_served_count = 0
	_kitchen_failed_count = 0
	_kitchen_orders = [
		{"recipe": KITCHEN_RECIPE_SOUP, "time": 65.0},
		{"recipe": KITCHEN_RECIPE_GRILLED, "time": 82.0},
		{"recipe": KITCHEN_RECIPE_SOUP, "time": 105.0},
	]
	_kitchen_pot_state.clear()
	_kitchen_grill_state.clear()
	_kitchen_ready_dishes.clear()
	_kitchen_scrap_dishes.clear()
	_kitchen_scrap_income = 0
	_show_notification("第一次营业开始：胡萝卜清汤、烤胡萝卜")
	return true

func _update_kitchen_business(delta: float) -> void:
	_update_kitchen_cook_state(_kitchen_pot_state, KITCHEN_COOK_SOUP_SECONDS, delta)
	_update_kitchen_cook_state(_kitchen_grill_state, KITCHEN_COOK_GRILL_SECONDS, delta)
	if not _kitchen_business_active:
		return
	_kitchen_business_time = maxf(_kitchen_business_time - delta, 0.0)
	for index in range(_kitchen_orders.size() - 1, -1, -1):
		var order := _kitchen_orders[index]
		order["time"] = maxf(float(order.get("time", 0.0)) - delta, 0.0)
		_kitchen_orders[index] = order
		if float(order.get("time", 0.0)) <= 0.0:
			_kitchen_orders.remove_at(index)
			_kitchen_failed_count += 1
	if _kitchen_business_time <= 0.0 or _kitchen_orders.is_empty():
		_finish_kitchen_business()

func _update_kitchen_cook_state(state: Dictionary, cook_seconds: float, delta: float) -> void:
	if state.is_empty():
		return
	var time := float(state.get("time", 0.0)) + delta
	state["time"] = time
	if time >= cook_seconds + KITCHEN_READY_SECONDS + KITCHEN_BURN_SECONDS:
		state["stage"] = "burnt"
	elif time >= cook_seconds + KITCHEN_READY_SECONDS:
		state["stage"] = "over"
	elif time >= cook_seconds:
		state["stage"] = "ready"
	else:
		state["stage"] = "cooking"

func _complete_kitchen_order(recipe: String) -> void:
	for index in range(_kitchen_orders.size()):
		if str(_kitchen_orders[index].get("recipe", "")) == recipe:
			_kitchen_orders.remove_at(index)
			_kitchen_served_count += 1
			var price := _recipe_price(recipe)
			_coins += price
			_codex_discovered_cooking[recipe] = true
			_show_side_toast("%s 出餐 +%d" % [_recipe_name(recipe), price])
			return
	_show_notification("现在没有客人点这道菜")

func _serve_ready_kitchen_dish() -> bool:
	for order in _kitchen_orders:
		var recipe := str(order.get("recipe", ""))
		var ready_count := int(_kitchen_ready_dishes.get(recipe, 0))
		if ready_count <= 0:
			continue
		ready_count -= 1
		if ready_count <= 0:
			_kitchen_ready_dishes.erase(recipe)
		else:
			_kitchen_ready_dishes[recipe] = ready_count
		_complete_kitchen_order(recipe)
		return true
	for recipe in _kitchen_ready_dishes.keys():
		var ready_count := int(_kitchen_ready_dishes.get(recipe, 0))
		if ready_count <= 0:
			continue
		ready_count -= 1
		if ready_count <= 0:
			_kitchen_ready_dishes.erase(recipe)
		else:
			_kitchen_ready_dishes[recipe] = ready_count
		_sell_kitchen_scrap_dish(str(recipe), "多余菜低价卖出")
		return true
	for recipe in _kitchen_scrap_dishes.keys():
		var scrap_count := int(_kitchen_scrap_dishes.get(recipe, 0))
		if scrap_count <= 0:
			continue
		scrap_count -= 1
		if scrap_count <= 0:
			_kitchen_scrap_dishes.erase(recipe)
		else:
			_kitchen_scrap_dishes[recipe] = scrap_count
		_sell_kitchen_scrap_dish(str(recipe), "糊菜处理")
		return true
	return false

func _sell_kitchen_scrap_dish(recipe: String, label: String) -> void:
	var price := _recipe_scrap_price(recipe)
	_coins += price
	_kitchen_scrap_income += price
	_show_side_toast("%s：%s +%d" % [label, _recipe_name(recipe), price])

func _finish_kitchen_business() -> void:
	if not _kitchen_business_active:
		return
	_kitchen_business_active = false
	_kitchen_first_day_completed = true
	_show_notification("营业结束：完成 %d 单，漏单 %d" % [_kitchen_served_count, _kitchen_failed_count])

func _update_kitchen_status_panel() -> void:
	if _kitchen_status_panel == null or _kitchen_status_label == null:
		return
	var should_show := _kitchen_business_active or _kitchen_held_item != "" or not _kitchen_equipment_progress.is_empty() or not _kitchen_pot_state.is_empty() or not _kitchen_grill_state.is_empty() or not _kitchen_ready_dishes.is_empty() or not _kitchen_scrap_dishes.is_empty()
	_kitchen_status_panel.visible = should_show
	if not should_show:
		return
	var urgent := _has_urgent_kitchen_order()
	var panel_color := Color(0.98, 0.72, 0.55, 0.95) if urgent else Color(0.92, 0.84, 0.62, 0.92)
	var border_color := Color(0.98, 0.32, 0.20, 0.95) if urgent else Color(1.0, 0.95, 0.78, 1.0)
	_kitchen_status_panel.add_theme_stylebox_override("panel", _make_round_style(panel_color, border_color, 12.0, 1))
	_kitchen_status_label.add_theme_color_override("font_color", Color(0.40, 0.06, 0.03) if urgent else Color(0.22, 0.15, 0.08))
	_kitchen_status_label.text = _kitchen_status_text()
	_kitchen_status_panel.move_to_front()

func _kitchen_status_text() -> String:
	var lines: Array[String] = []
	if _kitchen_business_active:
		lines.append("营业 %.0fs  出餐 %d  漏单 %d" % [_kitchen_business_time, _kitchen_served_count, _kitchen_failed_count])
		lines.append(_kitchen_order_summary())
	if _kitchen_held_item != "":
		lines.append("手持：%s → %s" % [_kitchen_item_name(_kitchen_held_item), _recipe_name(_kitchen_held_recipe)])
	elif _kitchen_business_active:
		lines.append("手持：空")
	var progress_summary := _kitchen_progress_summary()
	if progress_summary != "":
		lines.append("加工：" + progress_summary)
	var ready_summary := _kitchen_ready_dish_summary()
	if ready_summary != "":
		lines.append("备菜架：" + ready_summary)
	var scrap_summary := _kitchen_scrap_dish_summary()
	if scrap_summary != "":
		lines.append("残次处理：" + scrap_summary)
	if not _kitchen_pot_state.is_empty():
		lines.append("煮锅：%s" % _cook_state_text(_kitchen_pot_state, KITCHEN_COOK_SOUP_SECONDS))
	if not _kitchen_grill_state.is_empty():
		lines.append("烤架：%s" % _cook_state_text(_kitchen_grill_state, KITCHEN_COOK_GRILL_SECONDS))
	return "\n".join(lines)

func _kitchen_order_summary() -> String:
	if _kitchen_orders.is_empty():
		return "订单：暂无"
	var parts: Array[String] = []
	for order in _kitchen_orders:
		var remaining := float(order.get("time", 0.0))
		var marker := "急" if remaining <= KITCHEN_ORDER_URGENT_SECONDS else ""
		parts.append("%s%s %.0fs" % [marker, _recipe_name(str(order.get("recipe", ""))), remaining])
	return "订单：" + " / ".join(parts)

func _kitchen_ready_dish_summary() -> String:
	var parts: Array[String] = []
	for recipe in _kitchen_ready_dishes.keys():
		var count := int(_kitchen_ready_dishes.get(recipe, 0))
		if count > 0:
			parts.append("%s x%d" % [_recipe_name(str(recipe)), count])
	return " / ".join(parts)

func _kitchen_scrap_dish_summary() -> String:
	var parts: Array[String] = []
	for recipe in _kitchen_scrap_dishes.keys():
		var count := int(_kitchen_scrap_dishes.get(recipe, 0))
		if count > 0:
			parts.append("%s x%d" % [_recipe_name(str(recipe)), count])
	return " / ".join(parts)

func _kitchen_progress_summary() -> String:
	var parts: Array[String] = []
	for station in _kitchen_equipment_progress.keys():
		var progress := _kitchen_equipment_progress[station] as Dictionary
		if bool(progress.get("done", false)):
			parts.append("%s完成" % _equipment_name(str(station)))
		else:
			parts.append("%s %.0fs" % [_equipment_name(str(station)), float(progress.get("time", 0.0))])
	return " / ".join(parts)

func _has_urgent_kitchen_order() -> bool:
	if not _kitchen_business_active:
		return false
	for order in _kitchen_orders:
		if float(order.get("time", 0.0)) <= KITCHEN_ORDER_URGENT_SECONDS:
			return true
	return false

func _cook_state_text(state: Dictionary, cook_seconds: float) -> String:
	var stage := str(state.get("stage", "cooking"))
	var time := float(state.get("time", 0.0))
	match stage:
		"cooking":
			return "加热 %.0fs" % maxf(cook_seconds - time, 0.0)
		"ready":
			return "最佳，快出锅"
		"over":
			return "过熟，快救"
		"burnt":
			return "糊了"
	return stage

func _recipe_name(recipe: String) -> String:
	return str(_recipe_data(recipe).get("name", recipe))

func _recipe_price(recipe: String) -> int:
	return int(_recipe_data(recipe).get("price", 1))

func _recipe_scrap_price(recipe: String) -> int:
	return int(_recipe_data(recipe).get("scrap_price", max(1, int(round(float(_recipe_price(recipe)) * 0.28)))))

func _recipe_data(recipe: String) -> Dictionary:
	if KITCHEN_RECIPE_DATA.has(recipe):
		return KITCHEN_RECIPE_DATA[recipe]
	return {}

func _try_use_selected_tool() -> bool:
	if _dialogue_open or _map_open or _hoe_swinging:
		return false
	if _held_crop_item == "" and _try_pickup_dropped_seed():
		return true
	var item := _get_inventory_slot_item(_selected_inventory_slot)
	match item:
		INVENTORY_ITEM_HAND:
			return _try_harvest_crop()
		INVENTORY_ITEM_HOE:
			if not _has_hoe:
				return false
			if _try_clear_rotten_crop_with_hoe():
				return true
			_till_soil_in_front_of_player()
			return true
		INVENTORY_ITEM_WATERING_CAN:
			if not _has_watering_can:
				return false
			return _use_watering_can()
		INVENTORY_ITEM_SCYTHE:
			if not _has_scythe or _scythe_swinging:
				return false
			_use_scythe()
			return true
		INVENTORY_ITEM_FOOD_CHEST:
			return _try_place_food_chest_from_inventory()
	if _is_seed_item(item):
		if _get_seed_count_for_item(item) <= 0:
			return false
		return _plant_seed_in_front_of_player(item)
	return false

func _is_hand_selected() -> bool:
	return _get_inventory_slot_item(_selected_inventory_slot) == INVENTORY_ITEM_HAND

func _till_soil_in_front_of_player() -> void:
	if _player == null:
		return
	if _tilled_soil_root == null or not is_instance_valid(_tilled_soil_root):
		_tilled_soil_root = Node3D.new()
		_tilled_soil_root.name = "TilledSoilRoot"
		_mark_generated(_tilled_soil_root)
		add_child(_tilled_soil_root)
	_remove_soil_tiles_over_pond()
	var yaw := _get_player_visual_yaw()
	var forward := Vector3(sin(yaw), 0.0, cos(yaw))
	var center := _player.global_position + forward * 2.0
	center = _snap_soil_position(center)
	var center_2d := Vector2(center.x, center.z)
	if not _can_place_soil_tile(center):
		return
	_play_hoe_swing(yaw, center)
	for existing in _tilled_soil_centers:
		if existing.distance_squared_to(center_2d) <= 0.25:
			return
	_tilled_soil_centers.append(center_2d)
	_start_empty_soil_decay(center_2d)
	_hoe_guide_completed = true
	if _hoe_tutorial_active:
		_hoe_tutorial_active = false
		_return_to_mom_prompt_active = true
		_notification_time = 0.0
		_notification_text = ""
		if _interaction_prompt != null:
			_interaction_prompt.visible = false
		_show_good_job_feedback()
	var impact_timer := get_tree().create_timer(0.16)
	impact_timer.timeout.connect(_create_soil_patch.bind(center))

func _plant_seed_in_front_of_player(seed_item: String) -> bool:
	if _player == null:
		return false
	var yaw := _get_player_visual_yaw()
	var forward := Vector3(sin(yaw), 0.0, cos(yaw))
	var target := _player.global_position + forward * 2.0
	var soil_center := _find_tilled_soil_center_at(target)
	if soil_center.x == INF:
		_show_notification("鍏堝湪鏉惧ソ鐨勫湡鍦颁笂鎾")
		return true
	for planted in _planted_seed_centers:
		if planted.distance_squared_to(soil_center) <= 0.25:
			_show_notification("杩欏潡鍦板凡缁忕杩囦簡")
			return true
	var crop_type := _seed_item_crop_type(seed_item)
	var quality := _seed_item_quality(seed_item)
	if not _remove_seed_from_inventory(crop_type, quality, 1):
		return false
	_planted_seed_centers.append(soil_center)
	_stop_empty_soil_decay(soil_center)
	_create_seedling_at(soil_center, crop_type, quality)
	_update_inventory_bar()
	_show_good_job_feedback()
	if not _watering_task_active:
		_watering_task_prompt_active = true
	return true

func _find_tilled_soil_center_at(position: Vector3) -> Vector2:
	if _tilled_soil_centers.is_empty():
		return Vector2(INF, INF)
	var grid_yaw := _soil_grid_yaw()
	var target := Vector2(position.x, position.z)
	var best_center := Vector2(INF, INF)
	var best_distance := INF
	for center in _tilled_soil_centers:
		var local := (target - center).rotated(grid_yaw)
		if absf(local.x) <= 1.52 and absf(local.y) <= 1.52:
			var distance := target.distance_squared_to(center)
			if distance < best_distance:
				best_distance = distance
				best_center = center
	return best_center

func _create_seedling_at(center: Vector2, crop_type: String = CROP_CARROT, quality: int = 0) -> void:
	if _planted_seed_root == null or not is_instance_valid(_planted_seed_root):
		_planted_seed_root = Node3D.new()
		_planted_seed_root.name = "PlantedSeedRoot"
		_mark_generated(_planted_seed_root)
		add_child(_planted_seed_root)
	var root := Node3D.new()
	root.name = "PlantedSeed"
	root.position = Vector3(center.x, _height_at(center.x, center.y) + 0.045, center.y)
	root.rotation.y = _soil_grid_yaw()
	_planted_seed_root.add_child(root)
	var crop_key := _crop_key(center)
	var grow_seconds := _crop_grow_seconds(crop_type)
	_crop_nodes[crop_key] = root
	_crop_growth_remaining[crop_key] = grow_seconds
	_crop_types[crop_key] = crop_type
	_crop_qualities[crop_key] = clampi(quality, 0, 3)

	var seed_mat := StandardMaterial3D.new()
	seed_mat.albedo_color = _seed_color(crop_type, quality)
	seed_mat.roughness = 0.9
	var leaf_mat := StandardMaterial3D.new()
	leaf_mat.albedo_color = Color(0.42, 0.76, 0.26, 1.0)
	leaf_mat.roughness = 0.82

	var seed := MeshInstance3D.new()
	seed.name = "SeedBody"
	var seed_mesh := SphereMesh.new()
	seed_mesh.radius = 0.12
	seed_mesh.height = 0.18
	seed.mesh = seed_mesh
	seed.scale = Vector3(1.35, 0.55, 0.82)
	seed.rotation_degrees = Vector3(0.0, 0.0, -18.0)
	seed.material_override = seed_mat
	root.add_child(seed)

	var stem := MeshInstance3D.new()
	stem.name = "SeedStem"
	var stem_mesh := CylinderMesh.new()
	stem_mesh.top_radius = 0.025
	stem_mesh.bottom_radius = 0.035
	stem_mesh.height = 0.34
	stem.mesh = stem_mesh
	stem.position.y = 0.18
	stem.material_override = leaf_mat
	root.add_child(stem)

	for side in [-1.0, 1.0]:
		var leaf := MeshInstance3D.new()
		leaf.name = "SeedLeaf"
		var leaf_mesh := SphereMesh.new()
		leaf_mesh.radius = 0.11
		leaf_mesh.height = 0.08
		leaf.mesh = leaf_mesh
		leaf.scale = Vector3(1.55, 0.38, 0.74)
		leaf.position = Vector3(0.08 * side, 0.35, 0.0)
		leaf.rotation_degrees = Vector3(0.0, 0.0, 28.0 * side)
		leaf.material_override = leaf_mat
		root.add_child(leaf)

	var label := Label3D.new()
	label.name = "GrowthCountdown"
	label.text = "%ds" % int(ceilf(grow_seconds))
	label.position = Vector3(0.0, 0.82, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.fixed_size = false
	label.font_size = 32
	label.pixel_size = 0.014
	label.modulate = Color(1.0, 0.96, 0.72, 1.0)
	label.outline_size = 6
	label.outline_modulate = Color(0.20, 0.13, 0.05, 0.82)
	root.add_child(label)
	_crop_countdown_labels[crop_key] = label

func _crop_grow_seconds(crop_type: String) -> float:
	match crop_type:
		CROP_PEA:
			return PEA_GROW_SECONDS
		CROP_EGGPLANT:
			return EGGPLANT_GROW_SECONDS
		_:
			return CARROT_GROW_SECONDS

func _crop_key(center: Vector2) -> String:
	return "%.2f,%.2f" % [center.x, center.y]

func _soil_key_to_center(key: String) -> Vector2:
	var parts := key.split(",")
	if parts.size() < 2:
		return Vector2(INF, INF)
	return Vector2(float(parts[0]), float(parts[1]))

func _start_empty_soil_decay(center: Vector2) -> void:
	if not _is_tilled_soil_center(center) or _has_crop_on_soil(center):
		return
	_empty_soil_decay_remaining[_crop_key(center)] = EMPTY_SOIL_DECAY_SECONDS

func _stop_empty_soil_decay(center: Vector2) -> void:
	_empty_soil_decay_remaining.erase(_crop_key(center))

func _update_empty_soil_decay(delta: float) -> void:
	if _empty_soil_decay_remaining.is_empty():
		return
	for raw_key in _empty_soil_decay_remaining.keys():
		var key := str(raw_key)
		var center := _soil_key_to_center(key)
		if center.x == INF or not _is_tilled_soil_center(center):
			_empty_soil_decay_remaining.erase(key)
			continue
		if _has_crop_on_soil(center):
			_empty_soil_decay_remaining.erase(key)
			continue
		var remaining := maxf(float(_empty_soil_decay_remaining.get(key, EMPTY_SOIL_DECAY_SECONDS)) - delta, 0.0)
		if remaining <= 0.0:
			_remove_empty_soil_patch(center)
		else:
			_empty_soil_decay_remaining[key] = remaining

func _is_tilled_soil_center(center: Vector2) -> bool:
	for existing in _tilled_soil_centers:
		if existing.distance_squared_to(center) <= 0.25:
			return true
	return false

func _has_crop_on_soil(center: Vector2) -> bool:
	for planted in _planted_seed_centers:
		if planted.distance_squared_to(center) <= 0.25:
			return true
	return false

func _remove_empty_soil_patch(center: Vector2) -> void:
	if _has_crop_on_soil(center):
		_stop_empty_soil_decay(center)
		return
	_stop_empty_soil_decay(center)
	_remove_center_from_array(_tilled_soil_centers, center)
	_remove_center_from_array(_watered_soil_centers, center)
	_remove_soil_tiles_near(center)
	_remove_soil_weeds_near(center)

func _remove_soil_tiles_near(center: Vector2) -> void:
	if _tilled_soil_root == null or not is_instance_valid(_tilled_soil_root):
		return
	var grid_yaw := _soil_grid_yaw()
	for child in _tilled_soil_root.get_children():
		if child is Node3D:
			var tile := child as Node3D
			var local := (Vector2(tile.global_position.x, tile.global_position.z) - center).rotated(grid_yaw)
			if absf(local.x) <= 1.62 and absf(local.y) <= 1.62:
				tile.queue_free()

func _remove_soil_weeds_near(center: Vector2) -> void:
	var grid_yaw := _soil_grid_yaw()
	for index in range(_soil_weed_nodes.size() - 1, -1, -1):
		var weed := _soil_weed_nodes[index]
		if weed == null or not is_instance_valid(weed):
			_soil_weed_nodes.remove_at(index)
			continue
		var local := (Vector2(weed.global_position.x, weed.global_position.z) - center).rotated(grid_yaw)
		if absf(local.x) <= 1.72 and absf(local.y) <= 1.72:
			_soil_weed_nodes.remove_at(index)
			weed.queue_free()

func _update_crop_growth(delta: float) -> void:
	if _crop_growth_remaining.is_empty():
		return
	for key in _crop_growth_remaining.keys():
		var remaining := float(_crop_growth_remaining[key])
		var crop_node := _crop_nodes.get(key) as Node3D
		var crop_center := Vector2.ZERO
		var can_grow := false
		if crop_node != null and is_instance_valid(crop_node):
			crop_center = Vector2(crop_node.global_position.x, crop_node.global_position.z)
			can_grow = _is_crop_watered(crop_center) and not _is_crop_blocked_by_weeds(crop_center)
		if remaining > 0.0 and can_grow:
			remaining = maxf(remaining - delta, 0.0)
			_crop_growth_remaining[key] = remaining
			if remaining <= 0.0:
				_set_crop_mature(str(key))
		elif remaining <= 0.0 and crop_node != null and is_instance_valid(crop_node) and not _is_crop_rotten(str(key)):
			var rot_remaining := float(_crop_rot_remaining.get(str(key), CROP_ROT_SECONDS))
			rot_remaining = maxf(rot_remaining - delta, 0.0)
			_crop_rot_remaining[str(key)] = rot_remaining
			if rot_remaining <= 0.0:
				_set_crop_rotten(str(key))
		_update_crop_countdown(str(key))

func _update_crop_countdown(key: String) -> void:
	var label := _crop_countdown_labels.get(key) as Label3D
	if label == null or not is_instance_valid(label):
		return
	var node := _crop_nodes.get(key) as Node3D
	if node == null or not is_instance_valid(node):
		return
	var remaining := float(_crop_growth_remaining.get(key, 0.0))
	var center := Vector2(node.global_position.x, node.global_position.z)
	var is_watered := _is_crop_watered(center)
	if remaining > 0.0:
		if not is_watered:
			label.text = "闇€娴囨按"
			label.modulate = Color(0.72, 0.90, 1.0, 1.0)
			return
		var blocked_by_weeds := _is_crop_blocked_by_weeds(center)
		label.text = ("%ds  !" % int(ceilf(remaining))) if blocked_by_weeds else ("%ds" % int(ceilf(remaining)))
		label.modulate = Color(1.0, 0.56, 0.38, 1.0) if blocked_by_weeds else Color(1.0, 0.96, 0.72, 1.0)
	else:
		if _is_crop_rotten(key):
			label.text = "鑵愮儌"
			label.modulate = Color(0.62, 0.48, 0.34, 1.0)
		else:
			var rot_remaining := float(_crop_rot_remaining.get(key, CROP_ROT_SECONDS))
			label.text = "鎴愮啛 %ds" % int(ceilf(rot_remaining))
			label.modulate = Color(0.68, 1.0, 0.48, 1.0)

func _is_crop_watered(center: Vector2) -> bool:
	for watered in _watered_soil_centers:
		if watered.distance_squared_to(center) <= 0.25:
			return true
	return false

func _is_crop_blocked_by_weeds(center: Vector2) -> bool:
	if _count_visible_grass_on_crop_soil(center) >= CROP_SOIL_WEED_PRESSURE_THRESHOLD:
		return true
	return _count_visible_grass_near(center, CROP_WEED_CHECK_RADIUS) >= CROP_WEED_PRESSURE_THRESHOLD

func _count_visible_grass_on_crop_soil(center: Vector2) -> int:
	var half_size := 1.58
	var grid_yaw := _soil_grid_yaw()
	var count := _count_visible_soil_weeds_in_patch(center, half_size, grid_yaw)
	if _grass_multimesh == null:
		return count
	var radius := half_size * 1.5
	var min_cell := _grass_cell_key(center - Vector2(radius, radius))
	var max_cell := _grass_cell_key(center + Vector2(radius, radius))
	for cell_x in range(min_cell.x, max_cell.x + 1):
		for cell_y in range(min_cell.y, max_cell.y + 1):
			var key := Vector2i(cell_x, cell_y)
			if not _grass_spatial_cells.has(key):
				continue
			for index in _grass_spatial_cells[key]:
				var transform := _grass_multimesh.get_instance_transform(int(index))
				if absf(transform.basis.determinant()) < 0.0001:
					continue
				var local := (Vector2(transform.origin.x, transform.origin.z) - center).rotated(grid_yaw)
				if absf(local.x) <= half_size and absf(local.y) <= half_size:
					count += 1
	return count

func _count_visible_soil_weeds_in_patch(center: Vector2, half_size: float, grid_yaw: float) -> int:
	var count := 0
	for weed in _soil_weed_nodes:
		if weed == null or not is_instance_valid(weed) or not weed.visible or weed.scale.length_squared() <= 0.0001:
			continue
		var local := (Vector2(weed.global_position.x, weed.global_position.z) - center).rotated(grid_yaw)
		if absf(local.x) <= half_size and absf(local.y) <= half_size:
			count += 1
	return count

func _set_crop_mature(key: String) -> void:
	var root := _crop_nodes.get(key) as Node3D
	if root == null or not is_instance_valid(root) or root.has_node("CropRoot"):
		return
	_crop_rot_remaining[key] = CROP_ROT_SECONDS
	var crop_type := str(_crop_types.get(key, CROP_CARROT))
	var quality := int(_crop_qualities.get(key, 0))
	var crop_model := _create_crop_model(crop_type, quality, "CropRoot")
	crop_model.position = Vector3(0.0, 0.15, 0.0)
	root.add_child(crop_model)
	_matured_carrot_count = mini(_matured_carrot_count + 1, 5)
	var tween := create_tween()
	var target_scale := Vector3.ONE * _crop_quality_scale(quality)
	crop_model.scale = Vector3(0.2, 0.2, 0.2)
	tween.tween_property(crop_model, "scale", target_scale, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _is_crop_rotten(key: String) -> bool:
	var root := _crop_nodes.get(key) as Node3D
	return root != null and is_instance_valid(root) and root.has_node("RottenCrop")

func _set_crop_rotten(key: String) -> void:
	var root := _crop_nodes.get(key) as Node3D
	if root == null or not is_instance_valid(root) or root.has_node("RottenCrop"):
		return
	var fresh := root.get_node_or_null("CropRoot")
	if fresh != null:
		fresh.queue_free()
	var rotten := _create_rotten_crop_model()
	rotten.name = "RottenCrop"
	rotten.position = Vector3(0.0, 0.13, 0.0)
	root.add_child(rotten)
	_show_side_toast("鏈夎儭钀濆崪鑵愮儌浜嗭紝鐢ㄩ攧澶存竻鎺夊悗鍐嶉噸鏂扮")

func _create_rotten_crop_model() -> Node3D:
	var root := Node3D.new()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.34, 0.25, 0.13, 1.0)
	mat.roughness = 0.96
	for index in range(3):
		var clump := MeshInstance3D.new()
		clump.name = "RottenClump"
		var mesh := SphereMesh.new()
		mesh.radius = 0.15 + float(index) * 0.025
		mesh.height = 0.12
		clump.mesh = mesh
		clump.scale = Vector3(1.45, 0.45, 0.85)
		clump.position = Vector3(float(index - 1) * 0.12, 0.0, float(index % 2) * 0.10)
		clump.rotation_degrees = Vector3(0.0, float(index) * 37.0, 0.0)
		clump.material_override = mat
		root.add_child(clump)
	return root

func _try_harvest_crop() -> bool:
	if _player == null:
		return false
	if _held_crop_item != "":
		_show_notification("先把手里的食材放下或扔出去")
		return true
	if _try_pickup_dropped_seed():
		return true
	if _try_pickup_dropped_crop():
		return true
	if _has_rotten_crop_near_player():
		_show_side_toast("这颗已经腐烂了，切到锄头把它锄掉")
		return true
	if not _has_mature_crop():
		return false
	var crop_key := _find_harvestable_crop_key()
	if crop_key == "":
		_show_notification("靠近成熟的作物再收获")
		return true
	var crop := _crop_nodes.get(crop_key) as Node3D
	if crop == null or not is_instance_valid(crop):
		return true
	var center := Vector2(crop.global_position.x, crop.global_position.z)
	var crop_type := str(_crop_types.get(crop_key, CROP_CARROT))
	var quality := int(_crop_qualities.get(crop_key, 0))
	_crop_nodes.erase(crop_key)
	_crop_growth_remaining.erase(crop_key)
	_crop_countdown_labels.erase(crop_key)
	_crop_rot_remaining.erase(crop_key)
	_crop_types.erase(crop_key)
	_crop_qualities.erase(crop_key)
	_remove_center_from_array(_planted_seed_centers, center)
	_remove_center_from_array(_watered_soil_centers, center)
	_dry_soil_patch(center)
	_start_empty_soil_decay(center)
	_create_harvest_pop(center, crop_type, quality)
	crop.queue_free()
	_record_codex_crop(crop_type)
	_hold_crop_item(crop_type, quality)
	_update_inventory_bar()
	_show_good_job_feedback()
	_show_crop_throw_guide_once()
	return true

func _has_mature_crop() -> bool:
	for raw_key in _crop_nodes.keys():
		var key := str(raw_key)
		if float(_crop_growth_remaining.get(key, 1.0)) > 0.0:
			continue
		var crop := _crop_nodes.get(key) as Node3D
		if crop != null and is_instance_valid(crop) and crop.has_node("CropRoot") and not crop.has_node("RottenCrop"):
			return true
	return false

func _has_rotten_crop_near_player() -> bool:
	return _find_rotten_crop_key_in_front() != ""

func _find_rotten_crop_key_in_front() -> String:
	if _player == null:
		return ""
	var yaw := _get_player_visual_yaw()
	var forward := Vector2(sin(yaw), cos(yaw)).normalized()
	var player_point := Vector2(_player.global_position.x, _player.global_position.z)
	var best_key := ""
	var best_score := INF
	for raw_key in _crop_nodes.keys():
		var key := str(raw_key)
		if not _is_crop_rotten(key):
			continue
		var crop := _crop_nodes.get(key) as Node3D
		if crop == null or not is_instance_valid(crop):
			continue
		var point := Vector2(crop.global_position.x, crop.global_position.z)
		var offset := point - player_point
		var distance := offset.length()
		if distance > 2.75:
			continue
		if distance > 0.001 and absf(forward.angle_to(offset.normalized())) > deg_to_rad(78.0):
			continue
		var score := distance + absf(forward.angle_to(offset.normalized())) * 0.35
		if score < best_score:
			best_score = score
			best_key = key
	return best_key

func _try_clear_rotten_crop_with_hoe() -> bool:
	if not _has_hoe or _get_inventory_slot_item(_selected_inventory_slot) != INVENTORY_ITEM_HOE:
		return false
	var crop_key := _find_rotten_crop_key_in_front()
	if crop_key == "":
		return false
	var crop := _crop_nodes.get(crop_key) as Node3D
	if crop == null or not is_instance_valid(crop):
		return true
	var center := Vector2(crop.global_position.x, crop.global_position.z)
	var yaw := _get_player_visual_yaw()
	_play_hoe_swing(yaw, Vector3(center.x, _height_at(center.x, center.y), center.y))
	_crop_nodes.erase(crop_key)
	_crop_growth_remaining.erase(crop_key)
	_crop_countdown_labels.erase(crop_key)
	_crop_rot_remaining.erase(crop_key)
	_crop_types.erase(crop_key)
	_crop_qualities.erase(crop_key)
	_remove_center_from_array(_planted_seed_centers, center)
	_remove_center_from_array(_watered_soil_centers, center)
	_dry_soil_patch(center)
	_start_empty_soil_decay(center)
	_create_rotten_cleanup_effect(center)
	crop.queue_free()
	_show_side_toast("腐烂作物已清理，这块地可以重新播种")
	return true

func _create_rotten_cleanup_effect(center: Vector2) -> void:
	var root := Node3D.new()
	root.name = "RottenCleanupEffect"
	root.position = Vector3(center.x, _height_at(center.x, center.y) + 0.08, center.y)
	_mark_generated(root)
	add_child(root)
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.42, 0.30, 0.16, 0.48)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for index in range(10):
		var dust := MeshInstance3D.new()
		dust.name = "RotDust"
		var mesh := SphereMesh.new()
		mesh.radius = 0.07
		mesh.height = 0.05
		dust.mesh = mesh
		dust.material_override = mat
		var angle := float(index) / 10.0 * TAU
		dust.position = Vector3(cos(angle) * 0.15, 0.08, sin(angle) * 0.15)
		root.add_child(dust)
		var tween := create_tween()
		tween.tween_property(dust, "position", Vector3(cos(angle) * 0.8, 0.02, sin(angle) * 0.8), 0.34)
		tween.parallel().tween_property(dust, "scale", Vector3.ZERO, 0.34)
		tween.finished.connect(dust.queue_free)
	var timer := get_tree().create_timer(0.42)
	timer.timeout.connect(root.queue_free)

func _find_harvestable_crop_key() -> String:
	var yaw := _get_player_visual_yaw()
	var forward := Vector2(sin(yaw), cos(yaw)).normalized()
	var player_point := Vector2(_player.global_position.x, _player.global_position.z)
	var best_key := ""
	var best_score := INF
	for raw_key in _crop_nodes.keys():
		var key := str(raw_key)
		if float(_crop_growth_remaining.get(key, 1.0)) > 0.0:
			continue
		var crop := _crop_nodes.get(key) as Node3D
		if crop == null or not is_instance_valid(crop) or not crop.has_node("CropRoot") or crop.has_node("RottenCrop"):
			continue
		var point := Vector2(crop.global_position.x, crop.global_position.z)
		var offset := point - player_point
		var distance := offset.length()
		if distance > 2.75:
			continue
		if distance > 0.001 and absf(forward.angle_to(offset.normalized())) > deg_to_rad(78.0):
			continue
		var score := distance + absf(forward.angle_to(offset.normalized())) * 0.35
		if score < best_score:
			best_score = score
			best_key = key
	return best_key

func _remove_center_from_array(array: Array[Vector2], center: Vector2) -> void:
	for index in range(array.size() - 1, -1, -1):
		if array[index].distance_squared_to(center) <= 0.25:
			array.remove_at(index)

func _create_carrot_model(model_name: String) -> Node3D:
	var root := Node3D.new()
	root.name = model_name
	var carrot_mat := StandardMaterial3D.new()
	carrot_mat.albedo_color = Color(0.94, 0.42, 0.12, 1.0)
	carrot_mat.roughness = 0.86
	var leaf_mat := StandardMaterial3D.new()
	leaf_mat.albedo_color = Color(0.35, 0.72, 0.24, 1.0)
	leaf_mat.roughness = 0.82

	var body := MeshInstance3D.new()
	body.name = "CarrotBody"
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.12
	body_mesh.height = 0.46
	body.mesh = body_mesh
	body.rotation_degrees = Vector3(0.0, 0.0, 180.0)
	body.material_override = carrot_mat
	root.add_child(body)

	for index in range(3):
		var leaf := MeshInstance3D.new()
		leaf.name = "CarrotLeaf"
		var leaf_mesh := SphereMesh.new()
		leaf_mesh.radius = 0.09
		leaf_mesh.height = 0.05
		leaf.mesh = leaf_mesh
		leaf.scale = Vector3(1.45, 0.35, 0.55)
		leaf.position = Vector3(0.0, 0.25, 0.0)
		leaf.rotation_degrees = Vector3(0.0, float(index) * 120.0, 22.0)
		leaf.material_override = leaf_mat
		root.add_child(leaf)
	return root

func _create_crop_model(crop_type: String, quality: int, model_name: String) -> Node3D:
	var root := _create_carrot_model(model_name)
	root.set_meta("crop_type", crop_type)
	root.set_meta("crop_quality", clampi(quality, 0, 3))
	root.scale *= _crop_quality_scale(quality)
	if crop_type == CROP_EGGPLANT:
		for mesh in _collect_mesh_instances(root):
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.48, 0.22, 0.62, 1.0)
			mat.roughness = 0.86
			mesh.material_override = mat
	elif crop_type == CROP_PEA:
		for mesh in _collect_mesh_instances(root):
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.28, 0.72, 0.28, 1.0)
			mat.roughness = 0.86
			mesh.material_override = mat
	elif crop_type == CROP_BELL_PEPPER:
		for mesh in _collect_mesh_instances(root):
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.82, 0.16, 0.10, 1.0)
			mat.roughness = 0.84
			mesh.material_override = mat
		root.scale *= Vector3(1.16, 0.92, 1.16)
	elif crop_type == CROP_MARSHMALLOW:
		for mesh in _collect_mesh_instances(root):
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(1.0, 0.82, 0.92, 1.0)
			mat.roughness = 0.78
			mesh.material_override = mat
		root.scale *= 1.08
	return root

func _crop_quality_scale(quality: int) -> float:
	return 1.0 + float(clampi(quality, 0, 3)) * 0.16

func _hold_crop_item(item: String, quality: int = 0) -> void:
	_clear_held_crop()
	_held_crop_item = item
	_held_crop_quality = clampi(quality, 0, 3)
	if _player == null:
		return
	_held_crop_root = _create_crop_model(item, _held_crop_quality, "HeldCrop")
	_held_crop_root.position = Vector3(0.42, 1.04, 0.46)
	_held_crop_root.rotation_degrees = Vector3(68.0, -20.0, -28.0)
	_held_crop_root.scale = Vector3.ONE * 1.18 * _crop_quality_scale(_held_crop_quality)
	_mark_generated(_held_crop_root)
	_player.add_child(_held_crop_root)
	_update_held_crop_quality_panel()

func _clear_held_crop() -> void:
	if _held_crop_root != null and is_instance_valid(_held_crop_root):
		_held_crop_root.queue_free()
	_held_crop_root = null
	_held_crop_item = ""
	_held_crop_quality = 0
	_crop_throw_charging = false
	_crop_throw_charge_time = 0.0
	_crop_throw_button = ""
	_update_crop_throw_charge_bar()
	_update_held_crop_quality_panel()

func _update_held_crop_quality_panel() -> void:
	if _held_crop_quality_panel == null or _held_crop_quality_label == null:
		return
	_held_crop_quality_panel.visible = _held_crop_item != ""
	if _held_crop_item == "":
		return
	var quality_text := _quality_stars(_held_crop_quality)
	if quality_text == "":
		quality_text = "普通品质"
	_held_crop_quality_label.text = "%s  %s" % [_crop_display_name(_held_crop_item), quality_text]

func _try_start_crop_throw_charge(button: String) -> bool:
	if _held_crop_item == "" or _held_crop_root == null or not is_instance_valid(_held_crop_root):
		return false
	if _crop_throw_charging:
		return true
	_crop_throw_charging = true
	_crop_throw_charge_time = 0.0
	_crop_throw_button = button
	_update_crop_throw_charge_bar()
	return true

func _stop_crop_throw_charge(button: String) -> void:
	if _crop_throw_button == button:
		_throw_held_crop()

func _update_crop_throw_charge(delta: float) -> void:
	if not _crop_throw_charging:
		_update_crop_throw_charge_bar()
		return
	if _held_crop_item == "" or _held_crop_root == null or not is_instance_valid(_held_crop_root):
		_stop_crop_throw_charge(_crop_throw_button)
		return
	_crop_throw_charge_time = minf(_crop_throw_charge_time + delta, CROP_THROW_FULL_CHARGE_SECONDS)
	_update_crop_throw_charge_bar()

func _update_crop_throw_charge_bar(progress: float = -1.0) -> void:
	if progress < 0.0:
		progress = clampf(_crop_throw_charge_time / CROP_THROW_FULL_CHARGE_SECONDS, 0.0, 1.0) if _crop_throw_charging else 0.0
	if _crop_throw_charge_bar != null and is_instance_valid(_crop_throw_charge_bar):
		_crop_throw_charge_bar.visible = _crop_throw_charging and progress > 0.0
	if _crop_throw_charge_fill != null and is_instance_valid(_crop_throw_charge_fill):
		_crop_throw_charge_fill.scale.x = clampf(progress, 0.0, 1.0)

func _throw_held_crop() -> void:
	if _held_crop_item == "" or _held_crop_root == null or not is_instance_valid(_held_crop_root):
		return
	var charge_ratio := clampf(_crop_throw_charge_time / CROP_THROW_FULL_CHARGE_SECONDS, 0.0, 1.0)
	var throw_distance := lerpf(CROP_THROW_MIN_DISTANCE, CROP_THROW_MAX_DISTANCE, charge_ratio)
	var start := _held_crop_root.global_position
	var direction := _get_camera_throw_direction()
	var end := start + direction * throw_distance
	end.y = _height_at(end.x, end.z) + 0.18
	var peak := (start + end) * 0.5 + Vector3(0.0, lerpf(1.2, 3.4, charge_ratio), 0.0)
	var thrown := _create_crop_model(_held_crop_item, _held_crop_quality, "ThrownCrop")
	thrown.global_position = start
	thrown.rotation_degrees = Vector3(40.0, rad_to_deg(atan2(direction.x, direction.z)), -25.0)
	thrown.scale = Vector3.ONE * 1.12 * _crop_quality_scale(_held_crop_quality)
	thrown.set_meta("crop_type", _held_crop_item)
	thrown.set_meta("crop_quality", _held_crop_quality)
	_mark_generated(thrown)
	add_child(thrown)
	_clear_held_crop()
	var tween := create_tween()
	var flight_out_time := lerpf(0.18, 0.34, charge_ratio)
	var flight_in_time := lerpf(0.24, 0.46, charge_ratio)
	tween.tween_property(thrown, "global_position", peak, flight_out_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(thrown, "rotation_degrees", Vector3(210.0, thrown.rotation_degrees.y + 180.0, -95.0), flight_out_time)
	tween.tween_property(thrown, "global_position", end, flight_in_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(thrown, "rotation_degrees", Vector3(390.0, thrown.rotation_degrees.y + 360.0, -155.0), flight_in_time)
	tween.finished.connect(_register_dropped_crop.bind(thrown))

func _register_dropped_crop(crop: Node3D) -> void:
	if crop == null or not is_instance_valid(crop):
		return
	if not _dropped_crop_roots.has(crop):
		_dropped_crop_roots.append(crop)
	crop.rotation_degrees = Vector3(74.0, crop.rotation_degrees.y, -18.0)
	crop.position.y = _height_at(crop.position.x, crop.position.z) + 0.2

func _try_pickup_dropped_crop() -> bool:
	if _held_crop_item != "":
		_show_notification("先把手里的食材放下或扔出去")
		return true
	var best_crop := _find_near_dropped_crop()
	if best_crop == null:
		return false
	_dropped_crop_roots.erase(best_crop)
	var crop_type := str(best_crop.get_meta("crop_type", CROP_CARROT))
	var quality := int(best_crop.get_meta("crop_quality", 0))
	best_crop.queue_free()
	_hold_crop_item(crop_type, quality)
	_update_inventory_bar()
	_show_crop_throw_guide_once()
	return true

func _show_crop_throw_guide_once() -> void:
	if _crop_throw_guide_completed:
		return
	_crop_throw_guide_completed = true
	_show_notification("长按 F / 左键 可以扔出去")

func _find_near_dropped_crop() -> Node3D:
	if _player == null:
		return null
	var player_point := Vector2(_player.global_position.x, _player.global_position.z)
	var best_crop: Node3D = null
	var best_distance := INF
	for index in range(_dropped_crop_roots.size() - 1, -1, -1):
		var crop := _dropped_crop_roots[index]
		if crop == null or not is_instance_valid(crop):
			_dropped_crop_roots.remove_at(index)
			continue
		var crop_point := Vector2(crop.global_position.x, crop.global_position.z)
		var pickup_radius := DROPPED_CROP_PICKUP_RADIUS
		if _is_dropped_crop_near_camper(crop_point):
			pickup_radius = CAMPER_DROPPED_CROP_PICKUP_RADIUS
		var distance := player_point.distance_to(crop_point)
		if distance <= pickup_radius and distance < best_distance:
			best_distance = distance
			best_crop = crop
	return best_crop

func _try_pickup_dropped_seed() -> bool:
	var best_seed := _find_near_dropped_seed()
	if best_seed == null:
		return false
	var crop_type := str(best_seed.get_meta("crop_type", CROP_CARROT))
	var quality := int(best_seed.get_meta("crop_quality", 0))
	if not _add_seed_to_inventory(crop_type, quality, 1, true):
		return true
	_dropped_seed_roots.erase(best_seed)
	best_seed.queue_free()
	return true

func _find_near_dropped_seed() -> Node3D:
	if _player == null:
		return null
	var player_point := Vector2(_player.global_position.x, _player.global_position.z)
	var best_seed: Node3D = null
	var best_distance := INF
	for index in range(_dropped_seed_roots.size() - 1, -1, -1):
		var seed := _dropped_seed_roots[index]
		if seed == null or not is_instance_valid(seed):
			_dropped_seed_roots.remove_at(index)
			continue
		var seed_point := Vector2(seed.global_position.x, seed.global_position.z)
		var distance := player_point.distance_to(seed_point)
		if distance <= DROPPED_SEED_PICKUP_RADIUS and distance < best_distance:
			best_distance = distance
			best_seed = seed
	return best_seed

func _is_dropped_crop_near_camper(crop_point: Vector2) -> bool:
	if _camper == null or not is_instance_valid(_camper):
		return false
	var camper_point := Vector2(_camper.global_position.x, _camper.global_position.z)
	return crop_point.distance_squared_to(camper_point) <= CAMPER_DROPPED_CROP_NEAR_RADIUS * CAMPER_DROPPED_CROP_NEAR_RADIUS

func _get_camera_throw_direction() -> Vector3:
	if _camera != null and is_instance_valid(_camera):
		var forward := -_camera.global_transform.basis.z
		forward.y = 0.0
		if forward.length_squared() > 0.001:
			return forward.normalized()
	var yaw := _get_player_visual_yaw()
	return Vector3(sin(yaw), 0.0, cos(yaw)).normalized()

func _create_harvest_pop(center: Vector2, crop_type: String = CROP_CARROT, quality: int = 0) -> void:
	var pop := _create_crop_model(crop_type, quality, "HarvestPop")
	pop.position = Vector3(center.x, _height_at(center.x, center.y) + 0.62, center.y)
	var quality_scale := _crop_quality_scale(quality)
	pop.scale = Vector3.ONE * 0.72 * quality_scale
	_mark_generated(pop)
	add_child(pop)
	var tween := create_tween()
	tween.tween_property(pop, "position:y", pop.position.y + 0.55, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(pop, "scale", Vector3.ONE * 0.92 * quality_scale, 0.18)
	tween.tween_property(pop, "scale", Vector3.ZERO, 0.18)
	tween.finished.connect(pop.queue_free)

func _count_visible_grass_near(center: Vector2, radius: float) -> int:
	var count := _count_visible_soil_weeds_near(center, radius)
	if _grass_multimesh == null:
		return count
	var min_cell := _grass_cell_key(center - Vector2(radius, radius))
	var max_cell := _grass_cell_key(center + Vector2(radius, radius))
	var radius_squared := radius * radius
	for cell_x in range(min_cell.x, max_cell.x + 1):
		for cell_y in range(min_cell.y, max_cell.y + 1):
			var key := Vector2i(cell_x, cell_y)
			if not _grass_spatial_cells.has(key):
				continue
			for index in _grass_spatial_cells[key]:
				var transform := _grass_multimesh.get_instance_transform(int(index))
				if absf(transform.basis.determinant()) < 0.0001:
					continue
				var point := Vector2(transform.origin.x, transform.origin.z)
				if point.distance_squared_to(center) <= radius_squared:
					count += 1
	return count

func _count_visible_soil_weeds_near(center: Vector2, radius: float) -> int:
	var count := 0
	var radius_squared := radius * radius
	for weed in _soil_weed_nodes:
		if weed == null or not is_instance_valid(weed) or not weed.visible or weed.scale.length_squared() <= 0.0001:
			continue
		var point := Vector2(weed.global_position.x, weed.global_position.z)
		if point.distance_squared_to(center) <= radius_squared:
			count += 1
	return count

func _try_start_watering_fill() -> bool:
	if not _has_watering_can or _get_inventory_slot_item(_selected_inventory_slot) != INVENTORY_ITEM_WATERING_CAN:
		return false
	if not _is_player_near_pond_edge():
		return false
	if _water_amount >= 0.995:
		return true
		_show_notification("水壶已经装满了")
		return true
	_water_filling = true
	return true
	_show_notification("正在补水...")
	return true

func _stop_watering_fill() -> void:
	_water_filling = false

func _update_watering_can_fill(delta: float) -> void:
	if not _water_filling:
		return
	_water_fill_effect_cooldown = maxf(_water_fill_effect_cooldown - delta, 0.0)
	if not _has_watering_can or _get_inventory_slot_item(_selected_inventory_slot) != INVENTORY_ITEM_WATERING_CAN or not _is_player_near_pond_edge():
		_stop_watering_fill()
		return
	var before := _water_amount
	_water_amount = clampf(_water_amount + delta / WATER_FILL_SECONDS, 0.0, 1.0)
	if absf(_water_amount - before) > 0.002:
		_update_inventory_bar()
		if _water_fill_effect_cooldown <= 0.0:
			_create_water_fill_effect()
			_water_fill_effect_cooldown = 0.18
		return
		_show_notification("姝ｅ湪琛ユ按...")
	if _water_amount >= 0.995:
		_water_amount = 1.0
		_stop_watering_fill()
		_update_inventory_bar()
		return
		_show_notification("姘村６瑁呮弧浜嗭紝鍙互鍘绘祰姘翠簡")

func _is_player_near_pond_edge() -> bool:
	if _player == null:
		return false
	var pos := _player.global_position
	return _is_inside_pond(pos.x, pos.z, WATER_FILL_RADIUS)

func _use_watering_can() -> bool:
	if _water_amount + 0.001 < WATER_PER_USE:
		return true
	var preview_yaw := _get_player_visual_yaw()
	var preview_forward := Vector3(sin(preview_yaw), 0.0, cos(preview_yaw))
	var preview_target := _player.global_position + preview_forward * 2.0
	var preview_soil_center := _find_tilled_soil_center_at(preview_target)
	if preview_soil_center.x == INF:
		return true
	var preview_planted := false
	for preview_center in _planted_seed_centers:
		if preview_center.distance_squared_to(preview_soil_center) <= 0.25:
			preview_planted = true
			break
	if not preview_planted:
		return true
	if _water_amount + 0.001 < WATER_PER_USE:
		return true
		_show_notification("水壶没水了，去湖边长按补水")
		return true
	var yaw := _get_player_visual_yaw()
	var forward := Vector3(sin(yaw), 0.0, cos(yaw))
	var target := _player.global_position + forward * 2.0
	var soil_center := _find_tilled_soil_center_at(target)
	if soil_center.x == INF:
		_show_notification("对准种好的土地再浇水")
		return true
	var planted := false
	for center in _planted_seed_centers:
		if center.distance_squared_to(soil_center) <= 0.25:
			planted = true
			break
	if not planted:
		_show_notification("这里还没种胡萝卜种子")
		return true
	for watered in _watered_soil_centers:
		if watered.distance_squared_to(soil_center) <= 0.25:
			return true
	_water_amount = maxf(_water_amount - WATER_PER_USE, 0.0)
	_watered_soil_centers.append(soil_center)
	_watering_guide_completed = true
	_darkened_watered_soil_patch(soil_center)
	_update_inventory_bar()
	_play_watering_can_use(yaw, soil_center)
	_create_watering_effect(soil_center)
	if not _scythe_collected and not _scythe_task_prompt_active:
		_scythe_task_prompt_active = true
		_show_good_job_feedback()
	return true

func _create_water_fill_effect() -> void:
	if _player == null:
		return
	var effect := MeshInstance3D.new()
	effect.name = "WaterFillSplash"
	var mesh := SphereMesh.new()
	mesh.radius = 0.08
	mesh.height = 0.05
	effect.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.42, 0.75, 1.0, 0.55)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	effect.material_override = mat
	effect.position = _player.global_position + Vector3(0.0, 0.16, 0.0)
	_mark_generated(effect)
	add_child(effect)
	var tween := create_tween()
	tween.tween_property(effect, "scale", Vector3(2.2, 0.2, 2.2), 0.34)
	tween.finished.connect(effect.queue_free)

func _create_watering_effect(center: Vector2) -> void:
	var root := Node3D.new()
	root.name = "WateringEffect"
	root.position = Vector3(center.x, _height_at(center.x, center.y) + 0.08, center.y)
	_mark_generated(root)
	add_child(root)

	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.36, 0.70, 1.0, 0.62)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for index in range(18):
		var drop := MeshInstance3D.new()
		drop.name = "WaterDrop"
		var mesh := SphereMesh.new()
		mesh.radius = 0.065
		mesh.height = 0.13
		drop.mesh = mesh
		drop.material_override = mat
		var angle := float(index) / 18.0 * TAU
		var radius := 0.28 + float(index % 3) * 0.22
		drop.position = Vector3(cos(angle) * radius, 0.76 + float(index % 4) * 0.07, sin(angle) * radius)
		root.add_child(drop)
		var tween := create_tween()
		tween.tween_property(drop, "position:y", 0.02, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(drop, "scale", Vector3(0.2, 0.2, 0.2), 0.38)
		tween.finished.connect(drop.queue_free)

	var timer := get_tree().create_timer(0.46)
	timer.timeout.connect(root.queue_free)

func _darkened_watered_soil_patch(center: Vector2) -> void:
	if _tilled_soil_root == null or not is_instance_valid(_tilled_soil_root):
		return
	var grid_yaw := _soil_grid_yaw()
	var wet_mat := StandardMaterial3D.new()
	wet_mat.albedo_color = Color(0.42, 0.25, 0.12, 1.0)
	wet_mat.roughness = 0.96
	for child in _tilled_soil_root.get_children():
		if child is MeshInstance3D:
			var tile := child as MeshInstance3D
			var local := (Vector2(tile.global_position.x, tile.global_position.z) - center).rotated(grid_yaw)
			if absf(local.x) <= 1.58 and absf(local.y) <= 1.58:
				tile.material_override = wet_mat

func _dry_soil_patch(center: Vector2) -> void:
	if _tilled_soil_root == null or not is_instance_valid(_tilled_soil_root):
		return
	var grid_yaw := _soil_grid_yaw()
	var dry_mat := StandardMaterial3D.new()
	dry_mat.albedo_color = Color(0.72, 0.50, 0.25, 1.0)
	dry_mat.roughness = 0.98
	for child in _tilled_soil_root.get_children():
		if child is MeshInstance3D:
			var tile := child as MeshInstance3D
			var local := (Vector2(tile.global_position.x, tile.global_position.z) - center).rotated(grid_yaw)
			if absf(local.x) <= 1.58 and absf(local.y) <= 1.58:
				tile.material_override = dry_mat

func _play_watering_can_use(yaw: float, center: Vector2) -> void:
	var scene := load(WATERING_CAN_SCENE_PATH)
	if not scene is PackedScene or _player == null:
		return
	var forward := Vector3(sin(yaw), 0.0, cos(yaw))
	var right := Vector3(cos(yaw), 0.0, -sin(yaw))
	var root := Node3D.new()
	root.name = "WateringCanUse"
	root.global_position = _player.global_position + right * 0.46 + forward * 0.48 + Vector3(0.0, 1.12, 0.0)
	root.rotation = Vector3(deg_to_rad(-10.0), yaw, deg_to_rad(-22.0))
	_mark_generated(root)
	add_child(root)

	var model := scene.instantiate() as Node3D
	if model == null:
		root.queue_free()
		return
	root.add_child(model)
	_fit_model_to_max_dimension(model, 1.25)
	_center_model_on_origin(model)
	model.rotation_degrees = Vector3(-8.0, -32.0, -70.0)
	_set_model_shadow(model, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)

	var target := Vector3(center.x, _height_at(center.x, center.y) + 0.78, center.y)
	var tween := create_tween()
	tween.tween_property(root, "global_position", target, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(root, "rotation:x", deg_to_rad(-38.0), 0.16)
	tween.tween_interval(0.24)
	tween.tween_property(root, "scale", Vector3.ZERO, 0.12)
	tween.finished.connect(root.queue_free)

func _use_scythe() -> void:
	if _player == null or _grass_multimesh == null:
		return
	_scythe_guide_completed = true
	var yaw := _get_player_visual_yaw()
	_scythe_swinging = true
	_play_scythe_swing(yaw)
	var hit_timer := get_tree().create_timer(0.13)
	hit_timer.timeout.connect(_cut_grass_in_front.bind(yaw))

func _play_scythe_swing(yaw: float) -> void:
	var scene := load(SCYTHE_SCENE_PATH)
	if not scene is PackedScene or _player == null:
		_scythe_swinging = false
		return
	var forward := Vector3(sin(yaw), 0.0, cos(yaw))
	var root := Node3D.new()
	root.name = "ScytheSwing"
	root.global_position = _player.global_position + Vector3(0.0, 0.78, 0.0)
	root.rotation = Vector3(0.0, yaw - SCYTHE_SWEEP_ANGLE * 0.5, 0.0)
	_mark_generated(root)
	add_child(root)

	var model := scene.instantiate() as Node3D
	if model == null:
		root.queue_free()
		_scythe_swinging = false
		return
	root.add_child(model)
	_fit_model_to_max_dimension(model, 1.85)
	_center_model_on_origin(model)
	model.position = Vector3(0.0, 0.0, 1.35)
	model.rotation_degrees = Vector3(0.0, 155.0, 88.0)
	_set_model_shadow(model, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)

	var tween := create_tween()
	tween.tween_property(root, "rotation:y", yaw + SCYTHE_SWEEP_ANGLE * 0.5, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(root, "global_position", _player.global_position + forward * 0.12 + Vector3(0.0, 0.72, 0.0), 0.28)
	tween.tween_property(root, "scale", Vector3.ZERO, 0.08)
	tween.finished.connect(_finish_scythe_swing.bind(root))

func _finish_scythe_swing(root: Node3D) -> void:
	if root != null and is_instance_valid(root):
		root.queue_free()
	_scythe_swinging = false

func _cut_grass_in_front(yaw: float) -> void:
	if _grass_multimesh == null or _player == null:
		return
	var forward := Vector2(sin(yaw), cos(yaw))
	var player_pos := Vector2(_player.global_position.x, _player.global_position.z)
	var min_cell := _grass_cell_key(player_pos - Vector2(SCYTHE_SWEEP_RADIUS, SCYTHE_SWEEP_RADIUS))
	var max_cell := _grass_cell_key(player_pos + Vector2(SCYTHE_SWEEP_RADIUS, SCYTHE_SWEEP_RADIUS))
	var cut_count := 0
	var drop_origin := Vector3.ZERO
	var candidates := {}
	for cell_x in range(min_cell.x, max_cell.x + 1):
		for cell_y in range(min_cell.y, max_cell.y + 1):
			var key := Vector2i(cell_x, cell_y)
			if not _grass_spatial_cells.has(key):
				continue
			for index in _grass_spatial_cells[key]:
				candidates[index] = true
	for index in candidates.keys():
		if _try_cut_grass_instance(int(index), player_pos, forward):
			cut_count += 1
			if drop_origin == Vector3.ZERO:
				var transform := _grass_multimesh.get_instance_transform(int(index))
				drop_origin = transform.origin
			if cut_count >= 96:
				break
	cut_count += _cut_soil_weeds_in_front(player_pos, forward, 96 - cut_count)
	if cut_count > 0:
		if drop_origin == Vector3.ZERO:
			drop_origin = _player.global_position + Vector3(forward.x, 0.0, forward.y) * 1.4
		_try_drop_seed_from_scythe_swing(drop_origin)
		_start_camera_shake(0.16, 0.055)
		_record_weeding_progress(cut_count)

func _cut_soil_weeds_in_front(player_pos: Vector2, forward: Vector2, max_count: int) -> int:
	if max_count <= 0:
		return 0
	var cut_count := 0
	for weed in _soil_weed_nodes:
		if weed == null or not is_instance_valid(weed) or not weed.visible or weed.scale.length_squared() <= 0.0001:
			continue
		var offset := Vector2(weed.global_position.x, weed.global_position.z) - player_pos
		var distance := offset.length()
		if distance < SCYTHE_SWEEP_MIN_DISTANCE or distance > SCYTHE_SWEEP_RADIUS:
			continue
		if absf(forward.angle_to(offset.normalized())) > SCYTHE_SWEEP_ANGLE * 0.5:
			continue
		_cut_soil_weed(weed)
		cut_count += 1
		if cut_count >= max_count:
			break
	return cut_count

func _cut_soil_weed(weed: Node3D) -> void:
	var transform := weed.global_transform
	_create_cut_grass_feedback(transform)
	var original_scale := weed.get_meta("soil_weed_original_scale", weed.scale) as Vector3
	weed.visible = false
	weed.scale = Vector3.ZERO
	var timer := get_tree().create_timer(SCYTHE_GRASS_REGROW_SECONDS + randf_range(0.0, SCYTHE_GRASS_REGROW_STAGGER_SECONDS))
	timer.timeout.connect(_regrow_soil_weed.bind(weed, original_scale))

func _regrow_soil_weed(weed: Node3D, original_scale: Vector3) -> void:
	if weed == null or not is_instance_valid(weed):
		return
	weed.visible = true
	weed.scale = original_scale * 0.12
	var tween := create_tween()
	tween.tween_property(weed, "scale", original_scale, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _record_weeding_progress(cut_count: int) -> void:
	if not _weeding_task_active or _weeding_lesson_completed:
		return
	_weeding_task_cut_count += cut_count
	if _weeding_task_cut_count < FIRST_WEEDING_TARGET_COUNT:
		return
	_weeding_task_active = false
	_return_after_weeding_prompt_active = true
	_show_good_job_feedback()

func _try_cut_grass_instance(index: int, player_pos: Vector2, forward: Vector2) -> bool:
	if _cut_grass_transforms.has(index):
		return false
	var transform := _grass_multimesh.get_instance_transform(index)
	if absf(transform.basis.determinant()) < 0.0001:
		return false
	var offset := Vector2(transform.origin.x, transform.origin.z) - player_pos
	var distance := offset.length()
	if distance < SCYTHE_SWEEP_MIN_DISTANCE or distance > SCYTHE_SWEEP_RADIUS:
		return false
	if absf(forward.angle_to(offset.normalized())) > SCYTHE_SWEEP_ANGLE * 0.5:
		return false
	_hide_grass_for_regrowth(index, transform, SCYTHE_GRASS_REGROW_SECONDS, SCYTHE_GRASS_REGROW_STAGGER_SECONDS)
	_create_cut_grass_feedback(transform)
	return true

func _hide_grass_for_regrowth(index: int, transform: Transform3D, base_delay: float, stagger_delay: float) -> void:
	if _grass_multimesh == null or _cut_grass_transforms.has(index):
		return
	_cut_grass_transforms[index] = transform
	var hidden := transform
	hidden.basis = hidden.basis.scaled(Vector3.ZERO)
	_grass_multimesh.set_instance_transform(index, hidden)
	var timer := get_tree().create_timer(base_delay + randf_range(0.0, stagger_delay))
	timer.timeout.connect(_regrow_grass_instance.bind(index))

func _regrow_grass_instance(index: int) -> void:
	if _grass_multimesh == null or not _cut_grass_transforms.has(index):
		return
	var transform := _cut_grass_transforms[index] as Transform3D
	var sprout := transform
	sprout.basis = transform.basis.scaled(Vector3(0.18, 0.18, 0.18))
	_grass_multimesh.set_instance_transform(index, sprout)
	_grow_grass_instance_step(index, transform, 1)

func _grow_grass_instance_step(index: int, transform: Transform3D, step: int) -> void:
	if _grass_multimesh == null or not _cut_grass_transforms.has(index):
		return
	var progress := clampf(float(step) / 5.0, 0.18, 1.0)
	var regrowing := transform
	regrowing.basis = transform.basis.scaled(Vector3(progress, progress, progress))
	_grass_multimesh.set_instance_transform(index, regrowing)
	if step >= 5:
		_grass_multimesh.set_instance_transform(index, transform)
		_cut_grass_transforms.erase(index)
		return
	var timer := get_tree().create_timer(SCYTHE_GRASS_REGROW_STEP_SECONDS)
	timer.timeout.connect(_grow_grass_instance_step.bind(index, transform, step + 1))

func _create_cut_grass_feedback(transform: Transform3D) -> void:
	var falling := MeshInstance3D.new()
	falling.name = "CutGrassFallingClump"
	falling.mesh = _grass_multimesh.mesh if _grass_multimesh != null else _make_grass_clump_mesh()
	falling.transform = transform
	falling.material_override = _grass_material
	_mark_generated(falling)
	add_child(falling)
	var fall_tween := create_tween()
	fall_tween.tween_property(falling, "scale", Vector3(1.0, 0.08, 1.0), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fall_tween.parallel().tween_property(falling, "rotation:x", falling.rotation.x + randf_range(-0.65, 0.65), 0.16)
	fall_tween.tween_property(falling, "scale", Vector3.ZERO, 0.18)
	fall_tween.finished.connect(falling.queue_free)

	var pieces := randi_range(2, 4)
	for _piece_index in range(pieces):
		_create_cut_grass_piece(transform.origin)

func _try_drop_seed_from_scythe_swing(origin: Vector3) -> void:
	_seed_drop_swing_counter += 1
	if _seed_drop_swing_counter < _seed_drop_swing_target:
		return
	_seed_drop_swing_counter = 0
	_seed_drop_swing_target = _roll_seed_drop_swing_target()
	_create_grass_resource_drop(origin)

func _roll_seed_drop_swing_target() -> int:
	if randf() < 0.55:
		return randi_range(SEED_DROP_SWING_MIN, SEED_DROP_SWING_MEDIAN)
	return randi_range(SEED_DROP_SWING_MEDIAN, SEED_DROP_SWING_MAX)

func _roll_tree_seed_drop_shake_target() -> int:
	if randf() < 0.55:
		return randi_range(TREE_SEED_DROP_SHAKE_MIN, TREE_SEED_DROP_SHAKE_MEDIAN)
	return randi_range(TREE_SEED_DROP_SHAKE_MEDIAN, TREE_SEED_DROP_SHAKE_MAX)

func _create_cut_grass_piece(origin: Vector3) -> void:
	var piece := MeshInstance3D.new()
	piece.name = "CutGrassPiece"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.08, 0.014, randf_range(0.18, 0.36))
	piece.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.42, 0.68, 0.22, 1.0)
	mat.roughness = 0.9
	piece.material_override = mat
	piece.position = Vector3(origin.x, origin.y + 0.055, origin.z)
	piece.rotation = Vector3(randf_range(-0.35, 0.35), randf_range(0.0, TAU), randf_range(-0.35, 0.35))
	_mark_generated(piece)
	add_child(piece)
	var tween := create_tween()
	tween.tween_property(piece, "position", piece.position + Vector3(randf_range(-0.18, 0.18), 0.02, randf_range(-0.18, 0.18)), 0.18)
	tween.tween_interval(5.5)
	tween.tween_property(piece, "scale", Vector3.ZERO, 0.4)
	tween.finished.connect(piece.queue_free)

func _create_grass_resource_drop(origin: Vector3) -> void:
	var seed_data := _roll_random_seed_drop()
	_create_seed_resource_drop(origin, str(seed_data["crop_type"]), int(seed_data["quality"]))

func _create_seed_resource_drop(origin: Vector3, crop_type: String, quality: int = 0) -> void:
	if not _add_seed_to_inventory(crop_type, quality, 1, true):
		_create_spilled_seed_drop(origin, crop_type, quality)
		return
	var drop := MeshInstance3D.new()
	drop.name = "SeedAutoPickup"
	var mesh := SphereMesh.new()
	mesh.radius = 0.095
	mesh.height = 0.11
	drop.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _seed_color(crop_type, quality)
	mat.roughness = 0.86
	drop.material_override = mat
	drop.position = origin + Vector3(randf_range(-0.18, 0.18), 0.16, randf_range(-0.18, 0.18))
	_mark_generated(drop)
	add_child(drop)
	var target := drop.position + Vector3(randf_range(-0.24, 0.24), 0.72, randf_range(-0.24, 0.24))
	if _player != null:
		target = _player.global_position + Vector3(0.0, 1.1, 0.0)
	var tween := create_tween()
	tween.tween_property(drop, "position", drop.position + Vector3(randf_range(-0.35, 0.35), 0.62, randf_range(-0.35, 0.35)), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(drop, "position", target, 0.34).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(drop, "scale", Vector3.ZERO, 0.24)
	tween.finished.connect(drop.queue_free)

func _create_spilled_seed_drop(origin: Vector3, crop_type: String, quality: int = 0) -> void:
	quality = clampi(quality, 0, 3)
	var root := Node3D.new()
	root.name = "SpilledSeedDrop"
	root.set_meta("crop_type", crop_type)
	root.set_meta("crop_quality", quality)
	var offset := Vector3(randf_range(-0.42, 0.42), 0.0, randf_range(-0.42, 0.42))
	root.position = origin + offset
	root.position.y = _height_at(root.position.x, root.position.z) + 0.08
	_mark_generated(root)
	add_child(root)

	var seed := MeshInstance3D.new()
	seed.name = "SeedBody"
	var mesh := SphereMesh.new()
	mesh.radius = 0.13
	mesh.height = 0.15
	seed.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _seed_color(crop_type, quality)
	mat.roughness = 0.78
	seed.material_override = mat
	root.add_child(seed)

	var ring := MeshInstance3D.new()
	ring.name = "SeedPickupRing"
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.18
	ring_mesh.outer_radius = 0.21
	ring.mesh = ring_mesh
	ring.rotation_degrees.x = 90.0
	var ring_mat := StandardMaterial3D.new()
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.albedo_color = Color(1.0, 0.86, 0.30, 0.72)
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = ring_mat
	root.add_child(ring)

	var label := Label3D.new()
	label.name = "SeedLabel"
	label.text = _seed_display_name(crop_type, quality)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0.0, 0.42, 0.0)
	label.font_size = 32
	label.modulate = _quality_color(quality)
	label.outline_size = 8
	label.outline_modulate = Color(0.12, 0.08, 0.03, 0.86)
	root.add_child(label)

	_dropped_seed_roots.append(root)
	_show_side_toast("%s掉在地上了" % _seed_display_name(crop_type, quality))
	var tween := create_tween()
	tween.tween_property(seed, "position", Vector3(0.0, 0.34, 0.0), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(seed, "position", Vector3.ZERO, 0.22).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func _roll_random_seed_drop() -> Dictionary:
	return {
		"crop_type": CROP_TYPES.pick_random(),
		"quality": _roll_seed_quality(),
	}

func _roll_seed_quality() -> int:
	var roll := randf()
	if roll < 0.75:
		return 0
	if roll < 0.90:
		return 1
	if roll < 0.98:
		return 2
	return 3

func _seed_color(crop_type: String, quality: int) -> Color:
	var base := Color(0.90, 0.62, 0.28, 1.0)
	match crop_type:
		CROP_EGGPLANT:
			base = Color(0.56, 0.34, 0.78, 1.0)
		CROP_PEA:
			base = Color(0.44, 0.82, 0.36, 1.0)
		CROP_BELL_PEPPER:
			base = Color(0.86, 0.22, 0.16, 1.0)
		CROP_MARSHMALLOW:
			base = Color(1.0, 0.74, 0.90, 1.0)
	if quality > 0:
		base = base.lerp(Color(1.0, 0.88, 0.28, 1.0), float(quality) * 0.18)
	return base

func _show_good_job_feedback() -> void:
	if _hud_root == null:
		return
	var layer := CanvasLayer.new()
	layer.name = "GoodJobLayer"
	_mark_generated(layer)
	add_child(layer)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	var viewport_size := get_viewport().get_visible_rect().size
	var center := Vector2(viewport_size.x * 0.5, viewport_size.y * 0.36)
	var label := Label.new()
	label.text = "Good job!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 42)
	label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.38))
	label.add_theme_color_override("font_shadow_color", Color(0.34, 0.22, 0.08, 0.55))
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 4)
	label.size = Vector2(320.0, 70.0)
	label.position = center - label.size * 0.5
	label.scale = Vector2(0.65, 0.65)
	label.pivot_offset = label.size * 0.5
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(label)

	var rng := RandomNumberGenerator.new()
	rng.seed = Time.get_ticks_msec()
	var colors := [
		Color(1.0, 0.54, 0.48),
		Color(1.0, 0.84, 0.36),
		Color(0.55, 0.86, 1.0),
		Color(0.70, 0.94, 0.54),
		Color(0.95, 0.61, 1.0),
	]
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:y", label.position.y - 18.0, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.36).set_delay(0.86)
	for index in range(34):
		var piece := ColorRect.new()
		piece.color = colors[index % colors.size()]
		piece.size = Vector2(rng.randf_range(5.0, 9.0), rng.randf_range(8.0, 14.0))
		piece.position = center + Vector2(rng.randf_range(-20.0, 20.0), rng.randf_range(-8.0, 10.0))
		piece.pivot_offset = piece.size * 0.5
		piece.rotation = rng.randf_range(-PI, PI)
		piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(piece)
		var drift := Vector2(rng.randf_range(-190.0, 190.0), rng.randf_range(-165.0, 120.0))
		tween.tween_property(piece, "position", piece.position + drift, rng.randf_range(0.62, 1.05)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(piece, "rotation", piece.rotation + rng.randf_range(-4.4, 4.4), 0.95)
		tween.tween_property(piece, "modulate:a", 0.0, 0.32).set_delay(0.64)
	tween.finished.connect(layer.queue_free)

func _play_hoe_swing(yaw: float, target_center: Vector3) -> void:
	var scene := load(HOE_SCENE_PATH)
	if not scene is PackedScene or _player == null:
		return
	_hoe_swinging = true
	var forward := Vector3(sin(yaw), 0.0, cos(yaw))
	var right := Vector3(cos(yaw), 0.0, -sin(yaw))
	var root := Node3D.new()
	root.name = "HoeSwing"
	root.global_position = _player.global_position + right * 0.52 + forward * 0.58 + Vector3(0.0, 1.28, 0.0)
	root.rotation = Vector3(deg_to_rad(-18.0), yaw, deg_to_rad(-38.0))
	_player_hoe_root = root
	_mark_generated(root)
	add_child(root)

	var model := scene.instantiate() as Node3D
	if model == null:
		root.queue_free()
		_player_hoe_root = null
		_hoe_swinging = false
		return
	_player_hoe_model = model
	root.add_child(model)
	_fit_model_to_max_dimension(model, 2.0)
	_center_model_on_origin(model)
	model.position = Vector3(0.0, 0.0, -0.82)
	model.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	_set_model_shadow(model, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)

	var tween := create_tween()
	tween.tween_property(root, "global_position", target_center + Vector3(0.0, 0.92, 0.0), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(root, "rotation:x", deg_to_rad(-92.0), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_interval(0.08)
	tween.tween_property(root, "scale", Vector3.ZERO, 0.10)
	tween.finished.connect(_finish_hoe_swing.bind(root))

func _finish_hoe_swing(root: Node3D) -> void:
	if root != null and is_instance_valid(root):
		root.queue_free()
	if _player_hoe_root == root:
		_player_hoe_root = null
	_player_hoe_model = null
	_hoe_swinging = false

func _create_soil_patch(center: Vector3) -> void:
	_clear_grass_in_soil_patch(center)
	_remove_soil_tiles_over_pond()
	var grid_yaw := _soil_grid_yaw()
	var right := Vector2(cos(grid_yaw), -sin(grid_yaw))
	var forward := Vector2(sin(grid_yaw), cos(grid_yaw))
	for x in range(-1, 2):
		for z in range(-1, 2):
			var offset := right * float(x) + forward * float(z)
			var tile_position := Vector3(center.x + offset.x, 0.0, center.z + offset.y)
			if not _can_place_soil_tile(tile_position):
				continue
			_create_soil_tile(tile_position)
	_create_soil_weeds_for_patch(center)

func _create_soil_weeds_for_patch(center: Vector3) -> void:
	if _soil_weed_root == null or not is_instance_valid(_soil_weed_root):
		_soil_weed_root = Node3D.new()
		_soil_weed_root.name = "SoilWeedRoot"
		_mark_generated(_soil_weed_root)
		add_child(_soil_weed_root)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(absf(center.x * 928371.0 + center.z * 689287.0)) + 117
	var points := _make_soil_weed_points(center, rng)
	var order: Array[int] = []
	for index in range(points.size()):
		order.append(index)
	order.shuffle()
	for order_index in range(order.size()):
		var position := points[order[order_index]]
		var grow_delay := lerpf(SOIL_WEED_INITIAL_GROW_MIN_SECONDS, SOIL_WEED_INITIAL_GROW_MAX_SECONDS, float(order_index) / maxf(float(order.size() - 1), 1.0))
		grow_delay += rng.randf_range(-6.0, 10.0)
		_create_soil_weed(position, rng, maxf(grow_delay, 4.0))

func _make_soil_weed_points(center: Vector3, rng: RandomNumberGenerator) -> Array[Vector3]:
	var points: Array[Vector3] = []
	var grid_yaw := _soil_grid_yaw()
	var right := Vector2(cos(grid_yaw), -sin(grid_yaw))
	var forward := Vector2(sin(grid_yaw), cos(grid_yaw))
	var lanes := 4
	for lane_x in range(lanes):
		for lane_z in range(lanes):
			if points.size() >= SOIL_WEED_MAX_PER_PATCH:
				break
			if rng.randf() < 0.20:
				continue
			var u := lerpf(-SOIL_WEED_HALF_EXTENT, SOIL_WEED_HALF_EXTENT, (float(lane_x) + rng.randf_range(0.18, 0.82)) / float(lanes))
			var v := lerpf(-SOIL_WEED_HALF_EXTENT, SOIL_WEED_HALF_EXTENT, (float(lane_z) + rng.randf_range(0.18, 0.82)) / float(lanes))
			var offset := right * u + forward * v
			var position := Vector3(center.x + offset.x, 0.0, center.z + offset.y)
			if _can_place_soil_tile(position):
				points.append(position)
	while points.size() < SOIL_WEED_MAX_PER_PATCH:
		var offset := right * rng.randf_range(-SOIL_WEED_HALF_EXTENT, SOIL_WEED_HALF_EXTENT) + forward * rng.randf_range(-SOIL_WEED_HALF_EXTENT, SOIL_WEED_HALF_EXTENT)
		var position := Vector3(center.x + offset.x, 0.0, center.z + offset.y)
		if _can_place_soil_tile(position):
			points.append(position)
	return points

func _create_soil_weed(position: Vector3, rng: RandomNumberGenerator, initial_grow_delay: float = 0.0) -> void:
	if _soil_weed_root == null:
		return
	var weed := MeshInstance3D.new()
	weed.name = "SoilWeed"
	weed.mesh = _grass_multimesh.mesh if _grass_multimesh != null and _grass_multimesh.mesh != null else _make_grass_clump_mesh()
	weed.material_override = _grass_material
	weed.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	weed.position = Vector3(position.x, _height_at(position.x, position.z) + 0.035, position.z)
	weed.rotation.y = rng.randf_range(0.0, TAU)
	var scale := rng.randf_range(0.72, 1.02) * grass_height
	weed.scale = Vector3(scale, scale, scale)
	weed.set_meta("soil_weed_original_scale", weed.scale)
	_soil_weed_root.add_child(weed)
	_soil_weed_nodes.append(weed)
	weed.visible = false
	weed.scale = Vector3.ZERO
	var timer := get_tree().create_timer(initial_grow_delay)
	timer.timeout.connect(_regrow_soil_weed.bind(weed, weed.get_meta("soil_weed_original_scale", Vector3.ONE)))

func _can_place_soil_tile(position: Vector3) -> bool:
	var grid_yaw: float = _soil_grid_yaw()
	for x in range(-2, 3):
		for z in range(-2, 3):
			var offset := Vector2(float(x), float(z)) * (SOIL_TILE_HALF_SIZE * 0.5)
			var rotated_offset: Vector2 = offset.rotated(-grid_yaw)
			if _is_inside_pond(position.x + rotated_offset.x, position.z + rotated_offset.y, SOIL_POND_EDGE_PADDING):
				return false
	return true

func _soil_grid_yaw() -> float:
	return deg_to_rad(CHAPTER_ONE_HOUSE_YAW) if _chapter_one_active else 0.0

func _snap_soil_position(position: Vector3) -> Vector3:
	var yaw: float = _soil_grid_yaw()
	var origin: Vector2 = Vector2(CHAPTER_ONE_HOUSE_POSITION.x, CHAPTER_ONE_HOUSE_POSITION.z) if _chapter_one_active else Vector2.ZERO
	var local: Vector2 = (Vector2(position.x, position.z) - origin).rotated(yaw)
	local.x = roundf(local.x / SOIL_PATCH_SPACING) * SOIL_PATCH_SPACING
	local.y = roundf(local.y / SOIL_PATCH_SPACING) * SOIL_PATCH_SPACING
	var snapped: Vector2 = origin + local.rotated(-yaw)
	return Vector3(snapped.x, position.y, snapped.y)

func _remove_soil_tiles_over_pond() -> void:
	if _tilled_soil_root == null or not is_instance_valid(_tilled_soil_root):
		return
	for child in _tilled_soil_root.get_children():
		if child is Node3D:
			var tile := child as Node3D
			if not _can_place_soil_tile(tile.global_position):
				tile.queue_free()

func _clear_grass_in_soil_patch(center: Vector3) -> void:
	if _grass_multimesh == null:
		return
	var half_size := 1.68
	var grid_yaw := _soil_grid_yaw()
	for index in range(_grass_multimesh.instance_count):
		var transform := _grass_multimesh.get_instance_transform(index)
		var origin := transform.origin
		var local := (Vector2(origin.x, origin.z) - Vector2(center.x, center.z)).rotated(grid_yaw)
		if absf(local.x) <= half_size and absf(local.y) <= half_size:
			if absf(transform.basis.determinant()) >= 0.0001:
				_hide_grass_for_regrowth(index, transform, SCYTHE_GRASS_REGROW_SECONDS, SCYTHE_GRASS_REGROW_STAGGER_SECONDS)

func _create_soil_tile(position: Vector3) -> void:
	if _tilled_soil_root == null:
		return
	var tile := MeshInstance3D.new()
	tile.name = "SoilTile"
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(SOIL_TILE_SIZE, SOIL_TILE_SIZE)
	tile.mesh = mesh
	tile.position = Vector3(position.x, _height_at(position.x, position.z) + 0.018, position.z)
	tile.rotation.y = _soil_grid_yaw()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.72, 0.50, 0.25, 1.0)
	mat.roughness = 0.98
	tile.material_override = mat
	_tilled_soil_root.add_child(tile)

func _get_player_visual_yaw() -> float:
	if _player == null:
		return 0.0
	var visual_root := _player.get_node_or_null("VisualRoot") as Node3D
	if visual_root != null:
		return visual_root.global_rotation.y
	return _player.global_rotation.y

func _create_map_camper_icon() -> void:
	var sub_viewport := SubViewport.new()
	sub_viewport.size = Vector2i(192, 136)
	sub_viewport.transparent_bg = true
	sub_viewport.world_3d = World3D.new()
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_map_camper_marker.add_child(sub_viewport)

	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 2.8, 6.2)
	camera.current = true
	sub_viewport.add_child(camera)
	camera.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)

	var light := DirectionalLight3D.new()
	light.light_energy = 2.4
	light.rotation_degrees = Vector3(-45.0, -35.0, 0.0)
	sub_viewport.add_child(light)

	var scene := load(CAMPER_SCENE_PATH)
	if scene is PackedScene:
		var model := scene.instantiate() as Node3D
		if model != null:
			model.rotation.y = MAP_CAMPER_RIGHT_FACING_YAW
			_map_camper_model = model
			sub_viewport.add_child(model)
			_fit_model_to_footprint_length(model, 4.6)
			_ground_model(model)
			_set_model_shadow(model, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)

	_map_camper_icon = TextureRect.new()
	_map_camper_icon.texture = sub_viewport.get_texture()
	_map_camper_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_map_camper_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_map_camper_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	_map_camper_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_camper_marker.add_child(_map_camper_icon)

func _make_round_style(fill: Color, border: Color, radius: float, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(int(radius))
	return style

func _build_mom_dialogue() -> Array[Dictionary]:
	if _chapter_one_active:
		if _hoe_rot_lesson_prompt_active and not _hoe_rot_lesson_completed:
			return [
				{"speaker": MOM_NAME, "portrait": MOM_PORTRAIT_PATH, "text": "这把锄头先拿来松土。以后地里的植物如果放太久坏掉了，也要靠它来清理。"},
				{"speaker": MOM_NAME, "portrait": MOM_PORTRAIT_PATH, "text": "腐烂的作物不能再用手摘，切到锄头，把坏掉的地方锄掉，土地就能重新整理出来。"},
				{"speaker": MOM_NAME, "portrait": MOM_PORTRAIT_PATH, "text": "所以别怕工具多。每样东西都有用处，先从眼前这块地开始吧。"},
			]
		if _is_chest_lesson_pending():
			return [
				{"speaker": MOM_NAME, "portrait": MOM_PORTRAIT_PATH, "text": "你把家里的食材箱收起来了吗？别看它旧，它其实是家里最特别的东西。"},
				{"speaker": MOM_NAME, "portrait": MOM_PORTRAIT_PATH, "text": "它可以放进背包，滚到物品栏里选中后，就能先看见一个虚线位置，再按下去摆在地上。"},
				{"speaker": MOM_NAME, "portrait": MOM_PORTRAIT_PATH, "text": "不过它的传输功能要接房车的电，所以只能摆在房车周围。离房车太远，它就只是个普通旧箱子。"},
				{"speaker": MOM_NAME, "portrait": MOM_PORTRAIT_PATH, "text": "现在家里只有这一个箱子，先把它当作随身仓库用。食材可以直接走近放进去，也可以扔进箱子旁边。"},
				{"speaker": "我", "portrait": PLAYER_PORTRAIT_PATH, "text": "你想怎么回答？", "options": ["先把箱子安在房车旁", "如果能升级，它会很可靠", "先从村庄开始整理食材"]},
				{"speaker": MOM_NAME, "portrait": MOM_PORTRAIT_PATH, "text": "嗯。箱子太老了，传送前仍然需要人站在旁边摇晃 3.5 秒，真正送过去还要再等 8 秒。"},
				{"speaker": MOM_NAME, "portrait": MOM_PORTRAIT_PATH, "text": "以后若是遇到懂这个的维修店，也许能把摇晃和传送的时间都缩短。先用它把村庄里的食材整理起来吧。"},
			]
		if _is_crop_future_talk_pending():
			return [
				{"speaker": MOM_NAME, "portrait": MOM_PORTRAIT_PATH, "text": "五颗胡萝卜都成熟了。你做得很好，这已经不只是练习了。"},
				{"speaker": MOM_NAME, "portrait": MOM_PORTRAIT_PATH, "text": "家里有一个储存食材的箱子。以后，这辆房车可以带你去任何地方。"},
				{"speaker": MOM_NAME, "portrait": MOM_PORTRAIT_PATH, "text": "你可以去任何地方售卖这些食材。我们祖祖辈辈，都是这样把路走出来的。"},
				{"speaker": "我", "portrait": PLAYER_PORTRAIT_PATH, "text": "你想怎么回答？", "options": ["在各地研究料理", "做当地人喜欢的菜", "先从村庄开始"]},
				{"speaker": MOM_NAME, "portrait": MOM_PORTRAIT_PATH, "text": "嗯。食材要在当地被理解，才能做成真正有价值的料理。先去屋里找到那个食材箱吧。"},
			]
		if _return_after_weeding_prompt_active and not _weeding_lesson_completed:
			return [
				{"speaker": MOM_NAME, "portrait": MOM_PORTRAIT_PATH, "text": "清理得不错。杂草不会一次就消失，隔一段时间还会慢慢长回来。"},
				{"speaker": MOM_NAME, "portrait": MOM_PORTRAIT_PATH, "text": "田地里或周围有两三簇杂草没关系。杂草太多时，胡萝卜会先停止生长。"},
				{"speaker": MOM_NAME, "portrait": MOM_PORTRAIT_PATH, "text": "看见倒计时旁边出现向下箭头，就说明附近杂草太多、成长暂停了，记得勤除草。"},
			]
		if _scythe_task_prompt_active and not _scythe_collected:
			return [
				{"speaker": MOM_NAME, "portrait": MOM_PORTRAIT_PATH, "text": "浇得很好，土喝饱水，胡萝卜才会慢慢长大。"},
				{"speaker": MOM_NAME, "portrait": MOM_PORTRAIT_PATH, "text": "草长得太快了，这把镰刀你拿着。前面草太密的时候，就横着扫过去。"},
				{"speaker": MOM_NAME, "portrait": MOM_PORTRAIT_PATH, "text": "清理杂草的时候，偶尔会翻出还能用的种子。路边的树也可以摇一摇。"},
			]
		if _watering_task_prompt_active:
			return [
				{"speaker": MOM_NAME, "portrait": MOM_PORTRAIT_PATH, "text": "做得很好，胡萝卜种子已经种下去了。"},
				{"speaker": MOM_NAME, "portrait": MOM_PORTRAIT_PATH, "text": "接下来带着水壶去湖边，长按把水装满，再回来给它浇水吧。"},
			]
		if _return_to_mom_prompt_active and not _starter_kit_collected:
			return [
				{"speaker": MOM_NAME, "portrait": MOM_PORTRAIT_PATH, "text": "做得很好，这块地已经松好了。"},
				{"speaker": MOM_NAME, "portrait": MOM_PORTRAIT_PATH, "text": "这里有 5 颗胡萝卜种子，还有水壶。先拿去试试吧。"},
			]
		if _is_mom_soil_task_pending():
			return [
				{"speaker": MOM_NAME, "portrait": MOM_PORTRAIT_PATH, "text": "别担心孩子，每个人都有第一次尝试。"},
				{"speaker": MOM_NAME, "portrait": MOM_PORTRAIT_PATH, "text": "我在这看着你呢，大胆去做吧。"},
			]
		return [
			{"speaker": MOM_NAME, "portrait": MOM_PORTRAIT_PATH, "text": "先给地松松土吧，我给你把锄头找出来了。"},
			{"speaker": MOM_NAME, "portrait": MOM_PORTRAIT_PATH, "text": "这把锄头不只是开垦土地，以后作物腐烂了，也要靠它清理。"},
		]
	return [
		{"speaker": MOM_NAME, "portrait": MOM_PORTRAIT_PATH, "text": "前些天收到你的消息，我就一直放心不下。\n这一路赶过来，连面包都忘了从烤箱里拿出来。"},
		{"speaker": MOM_NAME, "portrait": MOM_PORTRAIT_PATH, "text": "快让我看看……\n嗯，比离开家的时候瘦了不少。"},
		{"speaker": "我", "portrait": PLAYER_PORTRAIT_PATH, "text": "你想怎么回答？", "options": ["路上有点累，见到你就好了", "以后会好好吃饭的", "我回来了，妈妈"]},
		{"speaker": MOM_NAME, "portrait": MOM_PORTRAIT_PATH, "text": "累了吧，回来就好。人总要出去看看远一点的地方才是。"},
		{"speaker": MOM_NAME, "portrait": MOM_PORTRAIT_PATH, "text": "那块荒着的田，我一直没舍得种。总觉得该留给某个终于回家的孩子。"},
		{"speaker": "我", "portrait": PLAYER_PORTRAIT_PATH, "text": "你想怎么回答？", "options": ["好，我们一起种", "我想从第一块田开始", "这次我会好好照顾家"]},
		{"speaker": MOM_NAME, "portrait": MOM_PORTRAIT_PATH, "text": "那就这么说定了。从播下第一颗胡萝卜种子开始，慢慢适应村里的生活吧。"},
	]
func _update_mom_interaction() -> void:
	var house_entry_near := _is_player_near_house_entry()
	var house_exit_near := _is_player_near_house_exit()
	if house_entry_near or house_exit_near:
		var should_show_house_prompt := not _house_exit_guide_completed if house_exit_near else not _house_entry_guide_completed
		if _interaction_prompt_label != null:
			_interaction_prompt_label.text = "F / 点击  离开房子" if house_exit_near else "F / 点击  进入房子"
		if _interaction_prompt != null:
			_interaction_prompt.visible = should_show_house_prompt and not _dialogue_open and not _map_open
			if _interaction_prompt.visible:
				_interaction_prompt.move_to_front()
		if _mom_is_highlighted:
			_set_mom_highlight(false)
		if _camper_is_highlighted:
			_set_camper_highlight(false)
		if _rebas_is_highlighted:
			_set_rebas_highlight(false)
		return
	var mom_near := _is_player_near_mom() and _can_talk_to_mom()
	var camper_near := _is_player_near_camper() and not mom_near
	var rebas_near := _is_player_near_rebas() and not mom_near and not camper_near
	var show_mom_prompt := mom_near and not _mom_talk_guide_completed
	var show_camper_prompt := camper_near and not _camper_map_guide_completed
	if _interaction_prompt_label != null:
		_interaction_prompt_label.text = ("F / 点击  与%s对话" % MOM_NAME) if mom_near else "F / 点击  进入房车地图"
	if _interaction_prompt != null:
		_interaction_prompt.visible = (show_mom_prompt or show_camper_prompt) and not _dialogue_open and not _map_open
	if mom_near != _mom_is_highlighted:
		_set_mom_highlight(mom_near)
	if camper_near != _camper_is_highlighted:
		_set_camper_highlight(camper_near)
	if rebas_near != _rebas_is_highlighted:
		_set_rebas_highlight(rebas_near)

func _update_mom_exclamation(delta: float) -> void:
	if _mom_exclamation == null:
		return
	var should_show := _mom != null and _should_show_mom_exclamation() and not _dialogue_open
	_mom_exclamation.visible = should_show
	if should_show:
		var bob := sin(Time.get_ticks_msec() * 0.004) * 0.08
		_mom_exclamation.position.y = 3.28 + bob

func _update_rebas_exclamation(_delta: float) -> void:
	if _rebas_exclamation == null:
		return
	var should_show := _should_show_rebas_exclamation()
	_rebas_exclamation.visible = should_show
	if should_show:
		var bob := sin(Time.get_ticks_msec() * 0.004 + 0.8) * 0.08
		_rebas_exclamation.position.y = 3.36 + bob

func _grant_hoe() -> void:
	if _has_hoe or _reward_overlay != null:
		return
	_show_hoe_reward_overlay()

func _show_notification(text: String) -> void:
	if _is_objective_notification_text(text):
		return
	if _has_shown_interaction_prompt(text):
		return
	_mark_interaction_prompt_shown(text)
	_notification_time = 3.0
	_notification_text = text
	_reset_interaction_prompt_layout()
	if _interaction_prompt_label != null:
		_interaction_prompt_label.text = text
	if _interaction_prompt != null:
		_interaction_prompt.visible = true
		_interaction_prompt.move_to_front()

func _is_objective_notification_text(text: String) -> bool:
	return text.begins_with("目标：") or text.begins_with("回去") or text.begins_with("进屋") or text.begins_with("选中食材箱子") or text.begins_with("去湖边") or text.begins_with("记得看倒计时")

func _capture_player_position() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var pos := _player.global_position
	var text := "Vector3(%.3f, 0.0, %.3f)" % [pos.x, pos.z]
	var path := ProjectSettings.globalize_path("res://_last_player_position.txt")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_line(text)
		file.store_line("raw=%.6f,%.6f,%.6f" % [pos.x, pos.y, pos.z])
		file.close()
	print("Captured player position: %s" % text)
	_show_notification("已记录当前位置")

func _try_use_house_door() -> bool:
	if not _chapter_one_active or _house_transitioning or _dialogue_open or _map_open:
		return false
	if _inside_house:
		if not _is_player_near_house_exit():
			return false
		_start_house_transition(false)
		return true
	if not _is_player_near_house_entry():
		return false
	_start_house_transition(true)
	return true

func _is_player_near_house_entry() -> bool:
	if _player == null or _inside_house:
		return false
	var player_point := Vector2(_player.global_position.x, _player.global_position.z)
	var door_point := Vector2(HOUSE_DOOR_INTERACT_POSITION.x, HOUSE_DOOR_INTERACT_POSITION.z)
	return player_point.distance_squared_to(door_point) <= HOUSE_DOOR_INTERACT_RADIUS * HOUSE_DOOR_INTERACT_RADIUS

func _is_player_near_house_exit() -> bool:
	if _player == null or not _inside_house:
		return false
	var player_point := Vector2(_player.global_position.x, _player.global_position.z)
	var exit_point := Vector2(HOUSE_INTERIOR_EXIT_POSITION.x, HOUSE_INTERIOR_EXIT_POSITION.z)
	return player_point.distance_squared_to(exit_point) <= HOUSE_INTERIOR_EXIT_RADIUS * HOUSE_INTERIOR_EXIT_RADIUS

func _start_house_transition(entering: bool) -> void:
	if _house_transitioning:
		return
	if entering:
		_house_entry_guide_completed = true
	else:
		_house_exit_guide_completed = true
	_house_transitioning = true
	call_deferred("_run_house_transition", entering)

func _run_house_transition(entering: bool) -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var layer := CanvasLayer.new()
	layer.name = "HouseDoorTransition"
	layer.layer = 130
	add_child(layer)
	var overlay := ColorRect.new()
	overlay.name = "BlackFade"
	overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(overlay)

	var fade_out := create_tween()
	fade_out.tween_property(overlay, "color:a", 1.0, 0.24)
	await fade_out.finished

	if entering:
		_enter_house_interior()
	else:
		_exit_house_interior()

	var fade_in := create_tween()
	fade_in.tween_property(overlay, "color:a", 0.0, 0.24)
	await fade_in.finished
	layer.queue_free()
	_house_transitioning = false
	_apply_camera()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _enter_house_interior() -> void:
	_inside_house = true
	if _house_interior_root != null and is_instance_valid(_house_interior_root):
		_house_interior_root.visible = true
	if _player != null:
		_player.global_position = HOUSE_INTERIOR_SPAWN
		var visual_root := _player.get_node_or_null("VisualRoot") as Node3D
		if visual_root != null:
			visual_root.rotation.y = PI
	_outside_camera_orbit = _orbit
	_outside_camera_zoom = _zoom
	_orbit = HOUSE_INTERIOR_CAMERA_ORBIT
	_zoom = HOUSE_INTERIOR_CAMERA_ZOOM
	if _interaction_prompt != null:
		_interaction_prompt.visible = false

func _exit_house_interior() -> void:
	_inside_house = false
	if _house_interior_root != null and is_instance_valid(_house_interior_root):
		_house_interior_root.visible = false
	if _player != null:
		var outside := HOUSE_OUTSIDE_SPAWN
		_player.global_position = Vector3(outside.x, _height_at(outside.x, outside.z) + 0.04, outside.z)
		var visual_root := _player.get_node_or_null("VisualRoot") as Node3D
		if visual_root != null:
			visual_root.rotation.y = _yaw_toward(_player.global_position, CHAPTER_ONE_HOUSE_POSITION)
	if _outside_camera_zoom > 0.0:
		_orbit = _outside_camera_orbit
		_zoom = _outside_camera_zoom
	if _interaction_prompt != null:
		_interaction_prompt.visible = false

func _update_house_mom_pacing(_delta: float) -> void:
	return

func _show_hoe_reward_overlay() -> void:
	_show_tool_reward_overlay("恭喜获得锄头", "HoePreview", "旋转查看锄头", Callable(self, "_setup_hoe_preview_viewport"), Callable(self, "_collect_hoe_reward"))

func _show_watering_can_reward_overlay() -> void:
	_show_tool_reward_overlay("恭喜获得水壶", "WateringCanPreview", "旋转查看水壶", Callable(self, "_setup_watering_can_preview_viewport"), Callable(self, "_collect_watering_can_reward"))

func _show_scythe_reward_overlay() -> void:
	_show_tool_reward_overlay("恭喜获得镰刀", "ScythePreview", "旋转查看镰刀", Callable(self, "_setup_scythe_preview_viewport"), Callable(self, "_collect_scythe_reward"))

func _show_tool_reward_overlay(title_text: String, preview_name: String, hint_text: String, preview_setup: Callable, collect_callable: Callable) -> void:
	if _hud_root == null:
		collect_callable.call()
		return
	_reward_collecting = false
	_reward_overlay = Control.new()
	_reward_overlay.name = "ToolRewardOverlay"
	_reward_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_reward_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_reward_overlay.gui_input.connect(_on_reward_overlay_gui_input)
	_hud_root.add_child(_reward_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.70, 0.78, 0.78, 0.36)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reward_overlay.add_child(dim)

	var panel := PanelContainer.new()
	panel.name = "RewardPanel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 34.0
	panel.offset_top = 26.0
	panel.offset_right = -34.0
	panel.offset_bottom = -26.0
	panel.pivot_offset = get_viewport().get_visible_rect().size * 0.5
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _make_round_style(Color(0.94, 0.92, 0.84, 0.18), Color(1.0, 0.98, 0.84, 0.44), 10.0, 1))
	_reward_overlay.add_child(panel)
	_reward_panel = panel

	var stack := VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 8)
	panel.add_child(stack)

	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.24, 0.15, 0.07))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(title)

	var view := TextureRect.new()
	view.name = preview_name
	var viewport_size := get_viewport().get_visible_rect().size
	view.custom_minimum_size = Vector2(maxf(viewport_size.x - 140.0, 520.0), maxf(viewport_size.y - 210.0, 360.0))
	view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.mouse_filter = Control.MOUSE_FILTER_STOP
	view.gui_input.connect(_on_reward_overlay_gui_input)
	stack.add_child(view)
	preview_setup.call(view, Vector2i(int(view.custom_minimum_size.x), int(view.custom_minimum_size.y)), true)

	var hint := Label.new()
	hint.text = hint_text
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color(0.34, 0.28, 0.18))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(hint)

	var collect_button := Button.new()
	collect_button.text = "鏀惰繘鑳屽寘"
	collect_button.custom_minimum_size = Vector2(132.0, 42.0)
	collect_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	collect_button.add_theme_font_size_override("font_size", 18)
	collect_button.add_theme_color_override("font_color", Color(0.25, 0.18, 0.10))
	collect_button.add_theme_stylebox_override("normal", _make_round_style(Color(0.93, 0.80, 0.55, 0.96), Color(1.0, 0.94, 0.70, 1.0), 18.0, 2))
	collect_button.add_theme_stylebox_override("hover", _make_round_style(Color(0.98, 0.87, 0.62, 1.0), Color(1.0, 0.98, 0.80, 1.0), 18.0, 2))
	collect_button.add_theme_stylebox_override("pressed", _make_round_style(Color(0.82, 0.66, 0.40, 1.0), Color(0.98, 0.90, 0.66, 1.0), 18.0, 2))
	collect_button.pressed.connect(collect_callable)
	stack.add_child(collect_button)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	call_deferred("_play_tool_reward_burst", title)

func _play_tool_reward_burst(title: Label) -> void:
	if title == null or not is_instance_valid(title) or _reward_overlay == null:
		return
	var burst_root := Control.new()
	burst_root.name = "RewardConfettiBurst"
	burst_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	burst_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reward_overlay.add_child(burst_root)

	var title_center := title.get_global_rect().get_center()
	var rng := RandomNumberGenerator.new()
	rng.seed = Time.get_ticks_msec()
	var colors := [
		Color(1.0, 0.55, 0.48),
		Color(1.0, 0.82, 0.34),
		Color(0.56, 0.84, 1.0),
		Color(0.64, 0.93, 0.50),
		Color(0.96, 0.63, 1.0),
		Color(1.0, 0.96, 0.62),
	]
	title.pivot_offset = title.size * 0.5
	title.scale = Vector2(0.76, 0.76)
	title.modulate.a = 1.0
	var title_tween := create_tween()
	title_tween.tween_property(title, "scale", Vector2(1.16, 1.16), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	title_tween.tween_property(title, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var burst_tween := create_tween()
	burst_tween.set_parallel(true)
	for index in range(58):
		var piece := ColorRect.new()
		piece.color = colors[index % colors.size()]
		piece.size = Vector2(rng.randf_range(5.0, 10.0), rng.randf_range(9.0, 18.0))
		piece.position = title_center + Vector2(rng.randf_range(-34.0, 34.0), rng.randf_range(-10.0, 14.0))
		piece.pivot_offset = piece.size * 0.5
		piece.rotation = rng.randf_range(-PI, PI)
		piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
		burst_root.add_child(piece)
		var angle := rng.randf_range(-PI, PI)
		var distance := rng.randf_range(95.0, 260.0)
		var outward := Vector2(cos(angle), sin(angle)) * distance
		outward.y += rng.randf_range(-70.0, 85.0)
		var duration := rng.randf_range(0.58, 1.05)
		burst_tween.tween_property(piece, "position", piece.position + outward, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		burst_tween.tween_property(piece, "rotation", piece.rotation + rng.randf_range(-5.2, 5.2), duration)
		burst_tween.tween_property(piece, "modulate:a", 0.0, 0.34).set_delay(rng.randf_range(0.42, 0.70))
	for index in range(12):
		var spark := ColorRect.new()
		spark.color = Color(1.0, 0.96, 0.70, 0.95)
		spark.size = Vector2(rng.randf_range(3.0, 5.0), rng.randf_range(28.0, 48.0))
		spark.position = title_center + Vector2(rng.randf_range(-20.0, 20.0), rng.randf_range(-8.0, 8.0))
		spark.pivot_offset = spark.size * 0.5
		spark.rotation = rng.randf_range(-PI, PI)
		spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		burst_root.add_child(spark)
		var angle := spark.rotation - PI * 0.5
		var outward := Vector2(cos(angle), sin(angle)) * rng.randf_range(80.0, 170.0)
		burst_tween.tween_property(spark, "position", spark.position + outward, rng.randf_range(0.42, 0.72)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		burst_tween.tween_property(spark, "scale:y", 0.18, 0.32).set_delay(0.18)
		burst_tween.tween_property(spark, "modulate:a", 0.0, 0.24).set_delay(0.36)
	burst_tween.finished.connect(burst_root.queue_free)

func _setup_hoe_preview_viewport(target: TextureRect, size: Vector2i, interactive: bool) -> void:
	var sub_viewport := SubViewport.new()
	sub_viewport.size = size
	sub_viewport.transparent_bg = true
	sub_viewport.world_3d = World3D.new()
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	target.add_child(sub_viewport)
	target.texture = sub_viewport.get_texture()

	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	if interactive:
		camera.size = 6.8
		camera.position = Vector3(0.0, 0.0, 8.0)
	else:
		camera.size = 3.05
		camera.position = Vector3(0.0, 0.0, 7.0)
	camera.current = true
	sub_viewport.add_child(camera)
	camera.look_at(Vector3.ZERO, Vector3.UP)

	var light := DirectionalLight3D.new()
	light.light_energy = 2.8
	light.rotation_degrees = Vector3(-46.0, -35.0, 0.0)
	sub_viewport.add_child(light)

	var fill_light := OmniLight3D.new()
	fill_light.light_energy = 0.8
	fill_light.position = Vector3(1.6, 2.4, 2.2)
	sub_viewport.add_child(fill_light)

	var scene := load(HOE_SCENE_PATH)
	if not scene is PackedScene:
		return
	var root := Node3D.new()
	root.name = "HoePreviewRoot"
	sub_viewport.add_child(root)
	var model := scene.instantiate() as Node3D
	if model == null:
		return
	root.add_child(model)
	_fit_model_to_max_dimension(model, 5.2 if interactive else 4.05)
	_center_model_on_origin(model)
	model.rotation_degrees = Vector3(0.0 if interactive else 58.0, -35.0 if interactive else -24.0, 28.0 if interactive else -43.0)
	root.rotation_degrees = Vector3(0.0, 0.0, 0.0)
	if interactive:
		_reward_viewport = sub_viewport
		_reward_model_root = root

func _setup_watering_can_preview_viewport(target: TextureRect, size: Vector2i, interactive: bool) -> void:
	var sub_viewport := SubViewport.new()
	sub_viewport.size = size
	sub_viewport.transparent_bg = true
	sub_viewport.world_3d = World3D.new()
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	target.add_child(sub_viewport)
	target.texture = sub_viewport.get_texture()

	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	if interactive:
		camera.size = 6.4
		camera.position = Vector3(0.0, 0.0, 8.0)
	else:
		camera.size = 3.2
		camera.position = Vector3(0.0, 0.0, 7.0)
	camera.current = true
	sub_viewport.add_child(camera)
	camera.look_at(Vector3.ZERO, Vector3.UP)

	var light := DirectionalLight3D.new()
	light.light_energy = 2.8
	light.rotation_degrees = Vector3(-46.0, -35.0, 0.0)
	sub_viewport.add_child(light)

	var fill_light := OmniLight3D.new()
	fill_light.light_energy = 0.8
	fill_light.position = Vector3(1.6, 2.4, 2.2)
	sub_viewport.add_child(fill_light)

	var scene := load(WATERING_CAN_SCENE_PATH)
	if not scene is PackedScene:
		return
	var root := Node3D.new()
	root.name = "WateringCanPreviewRoot"
	sub_viewport.add_child(root)
	var model := scene.instantiate() as Node3D
	if model == null:
		return
	root.add_child(model)
	_fit_model_to_max_dimension(model, 4.8 if interactive else 3.7)
	_center_model_on_origin(model)
	model.rotation_degrees = Vector3(0.0, -32.0 if interactive else -28.0, 0.0)
	root.rotation_degrees = Vector3(0.0, 0.0, 0.0)
	if interactive:
		_reward_viewport = sub_viewport
		_reward_model_root = root

func _setup_scythe_preview_viewport(target: TextureRect, size: Vector2i, interactive: bool) -> void:
	var sub_viewport := SubViewport.new()
	sub_viewport.size = size
	sub_viewport.transparent_bg = true
	sub_viewport.world_3d = World3D.new()
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	target.add_child(sub_viewport)
	target.texture = sub_viewport.get_texture()

	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 6.6 if interactive else 3.45
	camera.position = Vector3(0.0, 0.0, 8.0 if interactive else 7.0)
	camera.current = true
	sub_viewport.add_child(camera)
	camera.look_at(Vector3.ZERO, Vector3.UP)

	var light := DirectionalLight3D.new()
	light.light_energy = 2.8
	light.rotation_degrees = Vector3(-46.0, -35.0, 0.0)
	sub_viewport.add_child(light)

	var fill_light := OmniLight3D.new()
	fill_light.light_energy = 0.8
	fill_light.position = Vector3(1.6, 2.4, 2.2)
	sub_viewport.add_child(fill_light)

	var scene := load(SCYTHE_SCENE_PATH)
	if not scene is PackedScene:
		return
	var root := Node3D.new()
	root.name = "ScythePreviewRoot"
	sub_viewport.add_child(root)
	var model := scene.instantiate() as Node3D
	if model == null:
		return
	root.add_child(model)
	_fit_model_to_max_dimension(model, 5.2 if interactive else 3.65)
	_center_model_on_origin(model)
	model.rotation_degrees = Vector3(0.0, -38.0, 48.0) if interactive else Vector3.ZERO
	if not interactive:
		model.position += Vector3(0.0, 0.04, 0.0)
	root.rotation_degrees = Vector3.ZERO
	if interactive:
		_reward_viewport = sub_viewport
		_reward_model_root = root

func _on_reward_overlay_gui_input(event: InputEvent) -> void:
	_handle_reward_overlay_input(event)

func _handle_reward_overlay_input(event: InputEvent) -> void:
	if _reward_overlay == null or _reward_collecting:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_reward_dragging = true
			_reward_press_position = event.position
			_reward_last_drag_position = event.position
		else:
			_reward_dragging = false
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _reward_dragging:
		var drag_delta: Vector2 = event.position - _reward_last_drag_position
		_reward_last_drag_position = event.position
		if _reward_model_root != null:
			_reward_model_root.rotation.y += drag_delta.x * 0.01
			_reward_model_root.rotation.x += drag_delta.y * 0.01
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_reward_dragging = true
			_reward_press_position = event.position
			_reward_last_drag_position = event.position
		else:
			_reward_dragging = false
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and _reward_dragging:
		var drag_delta: Vector2 = event.position - _reward_last_drag_position
		_reward_last_drag_position = event.position
		if _reward_model_root != null:
			_reward_model_root.rotation.y += drag_delta.x * 0.01
			_reward_model_root.rotation.x += drag_delta.y * 0.01
		get_viewport().set_input_as_handled()

func _collect_hoe_reward() -> void:
	if _reward_collecting:
		return
	_reward_collecting = true
	_has_hoe = true
	var hoe_slot := _find_inventory_slot_for_item(INVENTORY_ITEM_HOE, INVENTORY_HOE_SLOT)
	_selected_inventory_slot = hoe_slot
	_update_inventory_bar()
	if _inventory_bar != null:
		_inventory_bar.visible = true
	if _reward_overlay != null:
		var tween := create_tween()
		tween.set_parallel(true)
		if _reward_panel != null:
			var target := _get_inventory_slot_center(hoe_slot)
			tween.tween_property(_reward_panel, "global_position", target - Vector2(26.0, 26.0), 0.36).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			tween.tween_property(_reward_panel, "scale", Vector2(0.12, 0.12), 0.36).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.tween_property(_reward_overlay, "modulate:a", 0.0, 0.34)
		tween.finished.connect(_finish_collect_hoe_reward)
		return
	_finish_collect_hoe_reward()

func _get_inventory_slot_center(index: int) -> Vector2:
	if index >= 0 and index < _inventory_slots.size():
		var slot := _inventory_slots[index]
		return slot.global_position + slot.size * 0.5
	var viewport_size := get_viewport().get_visible_rect().size
	return Vector2(viewport_size.x * 0.5, viewport_size.y - 46.0)

func _finish_collect_hoe_reward() -> void:
	if _reward_overlay != null:
		_reward_overlay.queue_free()
	_reward_overlay = null
	_reward_panel = null
	_reward_viewport = null
	_reward_model_root = null
	_reward_dragging = false
	_reward_press_position = Vector2.ZERO
	_reward_collecting = false
	_hoe_tutorial_active = true
	_hoe_rot_lesson_completed = true
	_hoe_rot_lesson_prompt_active = false
	_show_pickup_toast("閿勫ご", 1)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _grant_starter_kit() -> void:
	_add_seed_to_inventory(CROP_CARROT, 0, maxi(5 - _get_seed_count(CROP_CARROT, 0), 0), false)
	_update_inventory_bar()
	if _has_watering_can or _reward_overlay != null:
		_show_tool_switch_prompt()
		return
	_show_watering_can_reward_overlay()

func _collect_watering_can_reward() -> void:
	if _reward_collecting:
		return
	_reward_collecting = true
	_has_watering_can = true
	var seed_slot := _find_inventory_slot_for_item(INVENTORY_ITEM_SEED, INVENTORY_SEED_SLOT)
	_selected_inventory_slot = seed_slot
	_update_inventory_bar()
	if _inventory_bar != null:
		_inventory_bar.visible = true
	if _reward_overlay != null:
		var tween := create_tween()
		tween.set_parallel(true)
		if _reward_panel != null:
			var target := _get_inventory_slot_center(_find_inventory_slot_for_item(INVENTORY_ITEM_WATERING_CAN, INVENTORY_WATERING_CAN_SLOT))
			tween.tween_property(_reward_panel, "global_position", target - Vector2(26.0, 26.0), 0.36).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			tween.tween_property(_reward_panel, "scale", Vector2(0.12, 0.12), 0.36).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.tween_property(_reward_overlay, "modulate:a", 0.0, 0.34)
		tween.finished.connect(_finish_collect_watering_can_reward)
		return
	_finish_collect_watering_can_reward()

func _finish_collect_watering_can_reward() -> void:
	if _reward_overlay != null:
		_reward_overlay.queue_free()
	_reward_overlay = null
	_reward_panel = null
	_reward_viewport = null
	_reward_model_root = null
	_reward_dragging = false
	_reward_press_position = Vector2.ZERO
	_reward_collecting = false
	_show_pickup_toast("水壶", 1)
	_show_tool_switch_prompt()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _show_tool_switch_prompt() -> void:
	if _tool_switch_guide_completed:
		return
	_tool_switch_guide_completed = true

func _show_inventory_sort_prompt() -> void:
	if _inventory_sort_guide_completed:
		return
	_inventory_sort_guide_completed = true
	_show_notification("长按 Alt 呼出鼠标，可以拖动物品调整顺序")

func _grant_scythe() -> void:
	if _has_scythe or _reward_overlay != null:
		return
	_show_scythe_reward_overlay()

func _collect_scythe_reward() -> void:
	if _reward_collecting:
		return
	_reward_collecting = true
	_has_scythe = true
	var scythe_slot := _find_inventory_slot_for_item(INVENTORY_ITEM_SCYTHE, INVENTORY_SCYTHE_SLOT)
	_selected_inventory_slot = scythe_slot
	_update_inventory_bar()
	if _inventory_bar != null:
		_inventory_bar.visible = true
	if _reward_overlay != null:
		var tween := create_tween()
		tween.set_parallel(true)
		if _reward_panel != null:
			var target := _get_inventory_slot_center(scythe_slot)
			tween.tween_property(_reward_panel, "global_position", target - Vector2(26.0, 26.0), 0.36).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			tween.tween_property(_reward_panel, "scale", Vector2(0.12, 0.12), 0.36).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.tween_property(_reward_overlay, "modulate:a", 0.0, 0.34)
		tween.finished.connect(_finish_collect_scythe_reward)
		return
	_finish_collect_scythe_reward()

func _finish_collect_scythe_reward() -> void:
	if _reward_overlay != null:
		_reward_overlay.queue_free()
	_reward_overlay = null
	_reward_panel = null
	_reward_viewport = null
	_reward_model_root = null
	_reward_dragging = false
	_reward_press_position = Vector2.ZERO
	_reward_collecting = false
	_weeding_task_active = true
	_weeding_task_cut_count = 0
	_show_pickup_toast("闂€鏉垮瀬", 1)
	_show_inventory_sort_prompt()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _update_notification(delta: float) -> void:
	if _notification_time <= 0.0:
		return
	_notification_time = maxf(_notification_time - delta, 0.0)
	_reset_interaction_prompt_layout()
	if _interaction_prompt_label != null:
		_interaction_prompt_label.text = _notification_text
	if _interaction_prompt != null:
		_interaction_prompt.visible = true
		_interaction_prompt.move_to_front()
	if _notification_time <= 0.0 and _interaction_prompt != null:
		_interaction_prompt.visible = false
		_notification_text = ""

func _update_post_tutorial_objective() -> void:
	if _post_tutorial_objective == null or _post_tutorial_objective_label == null:
		return
	var text := ""
	var hide_when_mom_interactable := false
	var hide_when_house_interactable := false
	var hide_when_food_chest_interactable := false
	var hide_when_camper_interactable := false
	if _return_to_mom_prompt_active and not _starter_kit_collected:
		text = "目标：回去和%s对话" % MOM_NAME
		hide_when_mom_interactable = true
	elif _hoe_tutorial_active and not _hoe_guide_completed:
		text = "目标：选中锄头，松一块土地"
	elif _watering_task_prompt_active:
		text = "目标：回去和%s学习浇水" % MOM_NAME
		hide_when_mom_interactable = true
	elif _watering_task_active and not _watering_guide_completed:
		text = "目标：装满水壶，给胡萝卜浇水"
	elif _scythe_task_prompt_active and not _scythe_collected:
		text = "目标：回去和%s领取除草工具" % MOM_NAME
		hide_when_mom_interactable = true
	elif _weeding_task_active and not _weeding_lesson_completed:
		text = "目标：选中镰刀，清理田边杂草"
	elif _return_after_weeding_prompt_active and not _weeding_lesson_completed:
		text = "目标：回去和%s聊聊杂草" % MOM_NAME
		hide_when_mom_interactable = true
	elif _are_guided_tutorials_complete() and _seed_count > 0 and _matured_carrot_count < 5:
		text = "目标：种完 5 颗胡萝卜种子，并让它们成熟（%d/5）" % _matured_carrot_count
	elif _is_crop_future_talk_pending():
		text = "目标：回去和%s聊聊接下来要做什么" % MOM_NAME
		hide_when_mom_interactable = true
	elif _find_food_chests_prompt_active and not _food_chests_found:
		text = "目标：进屋找到储存食材的箱子"
		hide_when_house_interactable = not _inside_house
		hide_when_food_chest_interactable = _inside_house
	elif _is_chest_lesson_pending():
		text = "目标：回去和%s聊聊食材箱子" % MOM_NAME
		hide_when_mom_interactable = true
	elif _chest_lesson_completed and _has_food_chest and _placed_food_chests.is_empty():
		text = "目标：选中食材箱子，摆在房车周围"
		hide_when_camper_interactable = true
	elif _chest_lesson_completed and not _kitchen_first_day_completed and _placed_food_chests.is_empty():
		text = "目标：先把食材箱摆在房车周围"
	elif _chest_lesson_completed and not _kitchen_first_day_completed and not _has_all_first_day_kitchen_equipment():
		text = "目标：打开房车设备栏，摆好第一天厨房"
		hide_when_camper_interactable = true
	elif _can_start_first_kitchen_business():
		text = "目标：在房车旁开始第一次营业"
		hide_when_camper_interactable = true
	var should_show := text != "" and not _dialogue_open and not _map_open and _reward_overlay == null
	if should_show and hide_when_mom_interactable and _is_player_near_mom() and _can_talk_to_mom():
		should_show = false
	if should_show and hide_when_house_interactable and (_is_player_near_house_entry() or _is_player_near_house_exit()):
		should_show = false
	if should_show and hide_when_food_chest_interactable and _is_player_near_food_chest():
		should_show = false
	if should_show and hide_when_camper_interactable and _is_player_near_camper():
		should_show = false
	_post_tutorial_objective.visible = should_show
	if not should_show:
		return
	_post_tutorial_objective_label.text = text
	_post_tutorial_objective.move_to_front()

func _are_guided_tutorials_complete() -> bool:
	return _chapter_one_active and _dialogue_completed and _starter_kit_collected and _watering_task_active and _scythe_collected and _weeding_lesson_completed and not _return_to_mom_prompt_active and not _watering_task_prompt_active and not _scythe_task_prompt_active and not _return_after_weeding_prompt_active

func _is_crop_future_talk_pending() -> bool:
	return _are_guided_tutorials_complete() and _matured_carrot_count >= 5 and not _crop_future_talk_completed

func _is_chest_lesson_pending() -> bool:
	return _crop_future_talk_completed and _food_chests_found and not _chest_lesson_completed

func _refresh_interaction_prompt_text() -> void:
	if _interaction_prompt_label == null or _notification_time > 0.0 or _dialogue_open or _map_open:
		return
	_update_interaction_options()
	if _show_interaction_options_prompt():
		return
	_reset_interaction_prompt_layout()
	if _is_player_near_house_entry() or _is_player_near_house_exit():
		_interaction_prompt_label.text = "F / 点击  离开房子" if _inside_house else "F / 点击  进入房子"
		if _interaction_prompt != null:
			_interaction_prompt.visible = true
			_interaction_prompt.move_to_front()
		return
	var mom_near := _is_player_near_mom() and _can_talk_to_mom()
	if _find_food_chests_prompt_active and not _food_chests_found and _is_player_near_food_chest():
		if _food_chest_guide_completed:
			return
		_interaction_prompt_label.text = "F / 点击  查看食材箱子"
		if _interaction_prompt != null:
			_interaction_prompt.visible = true
			_interaction_prompt.move_to_front()
		return
	if mom_near:
		_interaction_prompt_label.text = "F / 点击  与%s对话" % MOM_NAME
	elif _is_player_near_camper():
		_interaction_prompt_label.text = "F / 点击  进入房车地图"

func _update_camper_interaction() -> void:
	if _mom_is_highlighted:
		_set_mom_highlight(false)
	var is_near := _is_player_near_camper()
	if _interaction_prompt_label != null:
		_interaction_prompt_label.text = "F / 点击  进入房车地图"
	if _interaction_prompt != null:
		_interaction_prompt.visible = is_near and not _camper_map_guide_completed and not _dialogue_open and not _map_open
	if is_near != _camper_is_highlighted:
		_set_camper_highlight(is_near)

func _is_player_near_camper() -> bool:
	if _player == null or _camper == null:
		return false
	var player_point := Vector2(_player.global_position.x, _player.global_position.z)
	var camper_point := Vector2(_camper.global_position.x, _camper.global_position.z)
	return player_point.distance_squared_to(camper_point) <= CAMPER_INTERACT_RADIUS * CAMPER_INTERACT_RADIUS

func _try_interact_food_chest() -> bool:
	if not _inside_house or not _is_player_near_food_chest():
		return false
	if not _find_food_chests_prompt_active or _food_chests_found:
		_show_notification("食材箱静静放在屋里，像是等了很久")
		return true
	_food_chests_found = true
	_find_food_chests_prompt_active = false
	_food_chest_guide_completed = true
	_grant_food_chest()
	for index in range(_food_chest_nodes.size()):
		var chest := _food_chest_nodes[index]
		if chest != null and is_instance_valid(chest):
			chest.queue_free()
			_food_chest_nodes.remove_at(index)
			break
	_show_good_job_feedback()
	_show_notification("收起了食材箱，回去问问%s" % MOM_NAME)
	return true

func _is_player_near_food_chest() -> bool:
	if _player == null or not _inside_house:
		return false
	var player_point := Vector2(_player.global_position.x, _player.global_position.z)
	var chest_a := Vector2(FOOD_CHEST_A_POSITION.x, FOOD_CHEST_A_POSITION.z)
	var radius_squared := FOOD_CHEST_INTERACT_RADIUS * FOOD_CHEST_INTERACT_RADIUS
	return player_point.distance_squared_to(chest_a) <= radius_squared

func _grant_food_chest() -> void:
	if _has_food_chest:
		return
	_has_food_chest = true
	var target_slot := _find_empty_inventory_slot()
	if target_slot == -1:
		target_slot = INVENTORY_UNLOCKED_SLOT_COUNT - 1
	_set_inventory_slot_item(target_slot, INVENTORY_ITEM_FOOD_CHEST)
	_selected_inventory_slot = target_slot
	_update_inventory_bar()
	_show_pickup_toast("食材箱子", 1)

func _try_place_food_chest_from_inventory() -> bool:
	if not _has_food_chest or _get_inventory_slot_item(_selected_inventory_slot) != INVENTORY_ITEM_FOOD_CHEST:
		return false
	var place_position := _get_food_chest_place_position()
	if _inside_house:
		_show_notification("箱子要接房车的电，得放在房车外面")
		return true
	if not _is_food_chest_place_position_valid(place_position):
		_show_notification("箱子需要接房车的电，只能放在房车周围")
		return true
	_place_food_chest(place_position)
	_consume_food_chest_from_inventory()
	return true

func _consume_food_chest_from_inventory() -> void:
	for slot_index in range(INVENTORY_UNLOCKED_SLOT_COUNT):
		if _get_inventory_slot_item(slot_index) == INVENTORY_ITEM_FOOD_CHEST:
			_set_inventory_slot_item(slot_index, INVENTORY_ITEM_NONE)
			break
	_has_food_chest = false
	_hide_food_chest_preview()
	if _selected_inventory_slot >= 0 and _selected_inventory_slot < INVENTORY_UNLOCKED_SLOT_COUNT:
		if _get_inventory_slot_item(_selected_inventory_slot) == INVENTORY_ITEM_NONE:
			_selected_inventory_slot = _find_inventory_slot_for_item(INVENTORY_ITEM_HAND, INVENTORY_HAND_SLOT)
	_update_inventory_bar()

func _can_place_selected_food_chest() -> bool:
	if not _has_food_chest or _get_inventory_slot_item(_selected_inventory_slot) != INVENTORY_ITEM_FOOD_CHEST:
		return false
	return _is_food_chest_place_position_valid(_get_food_chest_place_position())

func _get_food_chest_place_position() -> Vector3:
	if _player == null:
		return Vector3.ZERO
	var yaw := _get_player_visual_yaw()
	var forward := Vector3(sin(yaw), 0.0, cos(yaw))
	var position := _player.global_position + forward * FOOD_CHEST_PREVIEW_DISTANCE
	position.y = _height_at(position.x, position.z) + 0.32
	return position

func _is_food_chest_place_position_valid(position: Vector3) -> bool:
	if _inside_house or _camper == null or not is_instance_valid(_camper):
		return false
	var chest_point := Vector2(position.x, position.z)
	var camper_point := Vector2(_camper.global_position.x, _camper.global_position.z)
	return chest_point.distance_squared_to(camper_point) <= FOOD_CHEST_PLACE_RADIUS * FOOD_CHEST_PLACE_RADIUS

func _place_food_chest(position: Vector3) -> void:
	var chest: Node3D = null
	if not _placed_food_chests.is_empty():
		chest = _placed_food_chests[0]
		if chest == null or not is_instance_valid(chest):
			_placed_food_chests.clear()
			chest = null
	if chest == null:
		chest = _create_food_chest_model(self, "PlacedFoodChest", position)
		_mark_generated(chest)
		_placed_food_chests.append(chest)
	else:
		chest.global_position = position
	chest.rotation.y = _get_player_visual_yaw() + PI
	_show_side_toast("食材箱子已接上房车的电")

func _update_food_chest_placement_preview() -> void:
	if not _has_food_chest or _get_inventory_slot_item(_selected_inventory_slot) != INVENTORY_ITEM_FOOD_CHEST or _dialogue_open or _map_open or _inside_house:
		_hide_food_chest_preview()
		return
	var position := _get_food_chest_place_position()
	var valid := _is_food_chest_place_position_valid(position)
	if _food_chest_preview == null or not is_instance_valid(_food_chest_preview):
		_food_chest_preview = _create_food_chest_model(self, "FoodChestPlacementPreview", position, true)
		_mark_generated(_food_chest_preview)
		_create_food_chest_preview_outline(_food_chest_preview)
	_food_chest_preview.visible = true
	_food_chest_preview.global_position = position
	_food_chest_preview.rotation.y = _get_player_visual_yaw() + PI
	_set_food_chest_preview_valid(valid)

func _hide_food_chest_preview() -> void:
	if _food_chest_preview != null and is_instance_valid(_food_chest_preview):
		_food_chest_preview.visible = false

func _create_food_chest_preview_outline(root: Node3D) -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.62, 1.0, 0.62, 0.82)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var y := -0.34
	var segment_count := 5
	var half_x := 0.72
	var half_z := 0.52
	for side in range(4):
		for index in range(segment_count):
			if index % 2 == 1:
				continue
			var t := (float(index) + 0.5) / float(segment_count)
			var mesh := MeshInstance3D.new()
			mesh.name = "PreviewDash"
			var box := BoxMesh.new()
			box.size = Vector3(0.22, 0.035, 0.035)
			mesh.mesh = box
			mesh.material_override = mat
			if side < 2:
				mesh.position = Vector3(lerpf(-half_x, half_x, t), y, -half_z if side == 0 else half_z)
			else:
				mesh.position = Vector3(-half_x if side == 2 else half_x, y, lerpf(-half_z, half_z, t))
				mesh.rotation.y = PI * 0.5
			root.add_child(mesh)

func _set_food_chest_preview_valid(valid: bool) -> void:
	if _food_chest_preview == null or not is_instance_valid(_food_chest_preview):
		return
	var color := Color(0.58, 1.0, 0.58, 0.76) if valid else Color(1.0, 0.34, 0.26, 0.76)
	for mesh in _collect_mesh_instances(_food_chest_preview):
		var material := mesh.material_override as StandardMaterial3D
		if material != null and mesh.name == "PreviewDash":
			material.albedo_color = color

func _update_food_chest_deposits() -> void:
	if _placed_food_chests.is_empty() or _player == null:
		return
	if _held_crop_item != "" and _is_position_near_placed_food_chest(_player.global_position):
		_store_crop_in_food_chest(_held_crop_item, _held_crop_quality)
		_clear_held_crop()
		_update_inventory_bar()
	for index in range(_dropped_crop_roots.size() - 1, -1, -1):
		var crop := _dropped_crop_roots[index]
		if crop == null or not is_instance_valid(crop):
			_dropped_crop_roots.remove_at(index)
			continue
		if _is_position_near_placed_food_chest(crop.global_position):
			var crop_type := str(crop.get_meta("crop_type", CROP_CARROT))
			var quality := int(crop.get_meta("crop_quality", 0))
			_store_crop_in_food_chest(crop_type, quality)
			_dropped_crop_roots.remove_at(index)
			crop.queue_free()

func _is_position_near_placed_food_chest(position: Vector3) -> bool:
	var point := Vector2(position.x, position.z)
	for index in range(_placed_food_chests.size() - 1, -1, -1):
		var chest := _placed_food_chests[index]
		if chest == null or not is_instance_valid(chest):
			_placed_food_chests.remove_at(index)
			continue
		var chest_point := Vector2(chest.global_position.x, chest.global_position.z)
		if point.distance_squared_to(chest_point) <= FOOD_CHEST_DEPOSIT_RADIUS * FOOD_CHEST_DEPOSIT_RADIUS:
			return true
	return false

func _is_player_near_placed_food_chest() -> bool:
	if _player == null:
		return false
	return _is_position_near_placed_food_chest(_player.global_position)

func _try_pickup_placed_food_chest() -> bool:
	if _player == null:
		return false
	for index in range(_placed_food_chests.size() - 1, -1, -1):
		var chest := _placed_food_chests[index]
		if chest == null or not is_instance_valid(chest):
			_placed_food_chests.remove_at(index)
			continue
		var player_point := Vector2(_player.global_position.x, _player.global_position.z)
		var chest_point := Vector2(chest.global_position.x, chest.global_position.z)
		if player_point.distance_squared_to(chest_point) > FOOD_CHEST_DEPOSIT_RADIUS * FOOD_CHEST_DEPOSIT_RADIUS:
			continue
		var target_slot := _find_empty_inventory_slot()
		if target_slot == -1:
			_show_notification("鐗╁搧鏍忔弧浜嗭紝鑵惧嚭涓€鏍煎啀鏀惰捣绠卞瓙")
			return true
		_placed_food_chests.remove_at(index)
		chest.queue_free()
		_has_food_chest = true
		_set_inventory_slot_item(target_slot, INVENTORY_ITEM_FOOD_CHEST)
		_selected_inventory_slot = target_slot
		_update_inventory_bar()
		_show_pickup_toast("食材箱子", 1)
		return true
	return false

func _store_crop_in_food_chest(crop_type: String, quality: int) -> void:
	var key := _stored_crop_key(crop_type, quality)
	_stored_crop_counts[key] = int(_stored_crop_counts.get(key, 0)) + 1
	_show_side_toast("%s已放入食材箱子" % _crop_display_name(crop_type))

func _stored_crop_key(crop_type: String, quality: int) -> String:
	return "%s:%d" % [crop_type, clampi(quality, 0, 3)]

func _try_enter_camper() -> bool:
	if _can_talk_to_mom() and _is_player_near_mom():
		return false
	if not _is_player_near_camper():
		return false
	_camper_map_guide_completed = true
	_open_map_popup()
	return true

func _set_camper_highlight(enabled: bool) -> void:
	_camper_is_highlighted = enabled
	if _camper_model == null:
		return
	for mesh_instance in _collect_mesh_instances(_camper_model):
		mesh_instance.material_overlay = _highlight_material if enabled else null

func _open_map_popup() -> void:
	_map_open = true
	_camper_map_guide_completed = true
	_map_village_label_time = 0.0
	_map_was_near_village = false
	_map_locked_label_time = 0.0
	_map_locked_site_index = -1
	_map_page_locked_time = 0.0
	_map_page_locked_side = 0
	_map_dragging = false
	_map_drag_vector = Vector2.ZERO
	if _map_village_label != null:
		_map_village_label.modulate.a = 0.0
	if _map_locked_label != null:
		_map_locked_label.modulate.a = 0.0
	if _map_page_locked_label != null:
		_map_page_locked_label.modulate.a = 0.0
	_update_map_codex_panel()
	if _map_codex_panel != null:
		_map_codex_panel.move_to_front()
	_position_map_camper()
	if _map_panel != null:
		_map_panel.visible = true
		call_deferred("_position_map_camper")
	_update_inventory_bar()
	if _interaction_prompt != null:
		_interaction_prompt.visible = false
		_interaction_prompt.move_to_front()
	if _interaction_prompt_label != null:
		_interaction_prompt_label.text = "WASD / 婊戝姩  寮€寰€鏉戝簞"
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _close_map_popup() -> void:
	_map_open = false
	if _map_panel != null:
		_map_panel.visible = false
	_update_inventory_bar()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _update_map_popup(delta: float) -> void:
	_position_map_camper()
	var move_dir := _get_map_move_direction()
	if move_dir.length_squared() > 0.0:
		move_dir = move_dir.normalized()
		_map_camper_pos += move_dir * MAP_CAMPER_SPEED * delta
		_map_camper_pos.x = clampf(_map_camper_pos.x, 0.035, 0.965)
		_map_camper_pos.y = clampf(_map_camper_pos.y, 0.08, 0.90)
		_update_map_camper_heading(move_dir)
	var near_village := _is_map_camper_near_village()
	var locked_site_index := -1 if near_village else _get_near_locked_site_index()
	var near_locked_site := locked_site_index >= 0
	if near_village:
		if not _map_was_near_village:
			_map_village_label_time = 0.0
			if _map_village_label != null:
				_map_village_label.modulate.a = 0.0
		_map_village_label_time += delta
	_map_was_near_village = near_village
	if _map_village_label != null:
		var target_alpha := 1.0 if near_village else 0.0
		_map_village_label.modulate.a = move_toward(_map_village_label.modulate.a, target_alpha, delta * 1.9)
	if near_locked_site:
		if locked_site_index != _map_locked_site_index:
			_map_locked_label_time = 0.0
			if _map_locked_label != null:
				_map_locked_label.modulate.a = 0.0
		_map_locked_label_time += delta
	_map_locked_site_index = locked_site_index
	if _map_locked_label != null:
		var locked_target_alpha := 1.0 if near_locked_site else 0.0
		_map_locked_label.modulate.a = move_toward(_map_locked_label.modulate.a, locked_target_alpha, delta * 1.9)
	if _map_page_locked_time > 0.0:
		_map_page_locked_time = maxf(_map_page_locked_time - delta, 0.0)
	if _map_page_locked_label != null:
		var page_locked_target_alpha := 1.0 if _map_page_locked_time > 0.0 else 0.0
		_map_page_locked_label.modulate.a = move_toward(_map_page_locked_label.modulate.a, page_locked_target_alpha, delta * 5.2)
	var should_show_map_prompt := near_locked_site or not _map_village_guide_completed
	if _interaction_prompt_label != null and should_show_map_prompt:
		if near_village:
			_interaction_prompt_label.text = "F / 点击  返回当前位置" if _chapter_one_active else "F / 点击  进入村庄"
		elif near_locked_site:
			_interaction_prompt_label.text = "此地暂未解锁"
		else:
			_interaction_prompt_label.text = "WASD / 滑动  开往村庄"
		_fit_interaction_prompt_to_lines([_interaction_prompt_label.text])
	if should_show_map_prompt and _interaction_prompt_label != null:
		if _has_shown_interaction_prompt(_interaction_prompt_label.text):
			should_show_map_prompt = false
		else:
			_mark_interaction_prompt_shown(_interaction_prompt_label.text)
	if _interaction_prompt != null:
		_interaction_prompt.visible = should_show_map_prompt
		if should_show_map_prompt:
			_interaction_prompt.move_to_front()

func _get_map_move_direction() -> Vector2:
	var move_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		move_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		move_dir.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		move_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		move_dir.y += 1.0
	if move_dir.length_squared() > 0.0:
		return move_dir
	return _map_drag_vector

func _update_map_camper_heading(move_dir: Vector2) -> void:
	if _map_camper_model == null:
		return
	var target_yaw := atan2(move_dir.x, move_dir.y) + MAP_CAMPER_YAW_OFFSET
	_map_camper_model.rotation.y = lerp_angle(_map_camper_model.rotation.y, target_yaw, 0.22)

func _position_map_camper() -> void:
	if _map_popup == null:
		return
	var popup_size := _map_popup.size
	if _map_camper_marker != null:
		var marker_size := Vector2(136.0, 96.0)
		_map_camper_marker.position = popup_size * _map_camper_pos - marker_size * 0.5
	if _map_village_label != null:
		var appear_lift := lerpf(18.0, 0.0, clampf(_map_village_label_time * 1.35, 0.0, 1.0))
		var idle_float := sin(_map_village_label_time * 2.2) * 2.0
		_map_village_label.position = popup_size * MAP_VILLAGE_LABEL_POINT + Vector2(-75.0, -64.0 + appear_lift + idle_float)
	if _map_locked_label != null and _map_locked_site_index >= 0 and _map_locked_site_index < MAP_LOCKED_LABEL_POINTS.size():
		var locked_appear_lift := lerpf(16.0, 0.0, clampf(_map_locked_label_time * 1.35, 0.0, 1.0))
		var locked_idle_float := sin(_map_locked_label_time * 2.2) * 2.0
		_map_locked_label.position = popup_size * MAP_LOCKED_LABEL_POINTS[_map_locked_site_index] + Vector2(-130.0, -46.0 + locked_appear_lift + locked_idle_float)
	if _map_page_locked_label != null:
		var page_locked_lift := lerpf(10.0, 0.0, clampf((1.45 - _map_page_locked_time) * 3.0, 0.0, 1.0))
		var page_locked_y := _map_panel.size.y * 0.5 - 92.0 + page_locked_lift
		if _map_page_locked_side < 0:
			_map_page_locked_label.position = Vector2(42.0, page_locked_y)
		elif _map_page_locked_side > 0:
			_map_page_locked_label.position = Vector2(maxf(_map_panel.size.x - 262.0, 42.0), page_locked_y)

func _is_map_camper_near_village() -> bool:
	return _map_camper_pos.distance_squared_to(MAP_VILLAGE_POINT) <= MAP_VILLAGE_RADIUS * MAP_VILLAGE_RADIUS

func _get_near_locked_site_index() -> int:
	for i in range(MAP_LOCKED_SITE_POINTS.size()):
		var site_point: Vector2 = MAP_LOCKED_SITE_POINTS[i]
		if _map_camper_pos.distance_squared_to(site_point) <= MAP_LOCKED_SITE_RADIUS * MAP_LOCKED_SITE_RADIUS:
			return i
	return -1

func _handle_map_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_close_map_popup()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_F:
		_try_enter_village()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not _try_enter_village():
			_start_map_drag(event.position)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_stop_map_drag()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion and _map_dragging:
		_update_map_drag(event.position)
		get_viewport().set_input_as_handled()
	if event is InputEventScreenTouch:
		if event.pressed:
			if not _try_enter_village():
				_start_map_drag(event.position)
		else:
			_stop_map_drag()
		get_viewport().set_input_as_handled()
	if event is InputEventScreenDrag:
		_update_map_drag(event.position)
		get_viewport().set_input_as_handled()

func _on_map_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not _try_enter_village():
			_start_map_drag(event.position)
		get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_stop_map_drag()
		get_viewport().set_input_as_handled()
	if event is InputEventMouseMotion and _map_dragging:
		_update_map_drag(event.position)
		get_viewport().set_input_as_handled()
	if event is InputEventScreenTouch:
		if event.pressed:
			if not _try_enter_village():
				_start_map_drag(event.position)
		else:
			_stop_map_drag()
		get_viewport().set_input_as_handled()
	if event is InputEventScreenDrag:
		_update_map_drag(event.position)
		get_viewport().set_input_as_handled()

func _try_enter_village() -> bool:
	if not _map_open or not _is_map_camper_near_village():
		return false
	var should_show_enter_feedback := not _map_village_guide_completed
	_map_village_guide_completed = true
	if _interaction_prompt_label != null:
		_interaction_prompt_label.text = "已进入村庄"
	if _interaction_prompt != null:
		_interaction_prompt.visible = should_show_enter_feedback
	_close_map_popup()
	if _chapter_one_active:
		return true
	_map_camper_pos = MAP_VILLAGE_POINT
	_start_chapter_one_transition()
	return true

func _start_chapter_one_transition() -> void:
	if _chapter_transitioning:
		return
	_chapter_transitioning = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	var transition_layer := CanvasLayer.new()
	transition_layer.name = "ChapterTransitionLayer"
	transition_layer.layer = 100
	add_child(transition_layer)
	var unlock_timer := get_tree().create_timer(5.0)
	unlock_timer.timeout.connect(_force_finish_chapter_one_transition.bind(transition_layer))

	var overlay := ColorRect.new()
	overlay.name = "BlackFade"
	overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	transition_layer.add_child(overlay)

	var title := Label.new()
	title.name = "ChapterTitle"
	title.text = "Chapter 1: 新的开始"
	title.modulate.a = 0.0
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_FULL_RECT)
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	transition_layer.add_child(title)

	var tween := create_tween()
	tween.tween_property(overlay, "color:a", 1.0, 0.45)
	await tween.finished

	var title_tween := create_tween()
	title_tween.tween_property(title, "modulate:a", 1.0, 0.35)
	await title_tween.finished
	await get_tree().create_timer(0.55).timeout

	_build_chapter_one_scene()

	var title_out := create_tween()
	title_out.tween_property(title, "modulate:a", 0.0, 0.25)
	await title_out.finished

	var fade_out := create_tween()
	fade_out.tween_property(overlay, "color:a", 0.0, 0.65)
	await fade_out.finished

	transition_layer.queue_free()
	_finish_chapter_one_transition()

func _finish_chapter_one_transition() -> void:
	_chapter_transitioning = false
	_map_open = false
	_dialogue_open = false
	_reward_collecting = false
	_reward_dragging = false
	_map_dragging = false
	_map_drag_vector = Vector2.ZERO
	_clear_dialogue_options()
	if _map_panel != null:
		_map_panel.visible = false
	if _dialogue_panel != null:
		_dialogue_panel.visible = false
	if _interaction_prompt != null:
		_interaction_prompt.visible = false
	if _reward_overlay != null:
		_reward_overlay.visible = false
	_apply_camera()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _force_finish_chapter_one_transition(transition_layer: CanvasLayer) -> void:
	if transition_layer != null and is_instance_valid(transition_layer):
		transition_layer.queue_free()
	if not _chapter_one_active:
		_build_chapter_one_scene()
	_finish_chapter_one_transition()

func _build_chapter_one_scene() -> void:
	_chapter_one_active = true
	_map_camper_pos = MAP_VILLAGE_POINT
	_active_ponds = CHAPTER_ONE_PONDS.duplicate(true)
	_grass_material = null
	_grass_multimesh = null
	_soil_weed_root = null
	_soil_weed_nodes.clear()
	_hud_root = null
	_post_tutorial_objective = null
	_post_tutorial_objective_label = null
	_camper = null
	_camper_model = null
	_map_camper_model = null
	_mom = null
	_mom_model = null
	_mom_exclamation = null
	_mom_is_highlighted = false
	_rebas = null
	_rebas_model = null
	_rebas_exclamation = null
	_rebas_is_highlighted = false
	_dialogue_open = false
	_dialogue_index = 0
	_dialogue_completed = false
	_map_open = false
	_camper_is_highlighted = false
	_has_hoe = false
	_has_watering_can = false
	_has_scythe = false
	_has_food_chest = false
	_seed_count = 0
	_seed_inventory.clear()
	_hoe_tutorial_active = false
	_return_to_mom_prompt_active = false
	_starter_kit_collected = false
	_watering_task_prompt_active = false
	_watering_task_active = false
	_scythe_task_prompt_active = false
	_scythe_collected = false
	_weeding_task_active = false
	_weeding_task_cut_count = 0
	_return_after_weeding_prompt_active = false
	_weeding_lesson_completed = false
	_hoe_rot_lesson_prompt_active = false
	_hoe_rot_lesson_completed = false
	_water_amount = 0.0
	_water_filling = false
	_water_fill_effect_cooldown = 0.0
	_selected_inventory_slot = 0
	_reset_inventory_slot_items()
	_clear_inventory_drag_state()
	_mouse_released_by_escape = false
	_reward_overlay = null
	_reward_panel = null
	_reward_viewport = null
	_reward_model_root = null
	_reward_dragging = false
	_reward_collecting = false
	_notification_time = 0.0
	_tilled_soil_root = null
	_tilled_soil_centers.clear()
	_planted_seed_root = null
	_planted_seed_centers.clear()
	_crop_nodes.clear()
	_crop_growth_remaining.clear()
	_crop_countdown_labels.clear()
	_crop_rot_remaining.clear()
	_crop_types.clear()
	_crop_qualities.clear()
	_empty_soil_decay_remaining.clear()
	_matured_carrot_count = 0
	_crop_future_talk_completed = false
	_find_food_chests_prompt_active = false
	_food_chests_found = false
	_chest_lesson_completed = false
	_food_chest_nodes.clear()
	_placed_food_chests.clear()
	_food_chest_preview = null
	_stored_crop_counts.clear()
	_watered_soil_centers.clear()
	_held_crop_item = ""
	_held_crop_quality = 0
	_held_crop_root = null
	_crop_throw_charging = false
	_crop_throw_charge_time = 0.0
	_crop_throw_button = ""
	_crop_throw_charge_bar = null
	_crop_throw_charge_fill = null
	_dropped_crop_roots.clear()
	_dropped_seed_roots.clear()
	_player_hoe_root = null
	_player_hoe_model = null
	_hoe_swinging = false
	_scythe_swinging = false
	_seed_drop_swing_counter = 0
	_seed_drop_swing_target = _roll_seed_drop_swing_target()
	_tree_seed_drop_shake_counter = 0
	_tree_seed_drop_shake_target = _roll_tree_seed_drop_shake_target()
	_tree_seed_drop_shaken_tree_indices.clear()
	_cut_grass_transforms.clear()
	_grass_spatial_cells.clear()
	_camera_shake_time = 0.0
	_camera_shake_strength = 0.0
	_camera_shake_offset = Vector3.ZERO
	_inside_house = false
	_house_transitioning = false
	_house_interior_root = null
	_mom_outside_position = Vector3.ZERO
	_mom_outside_rotation_y = 0.0
	_mom_pace_target = HOUSE_INTERIOR_MOM_PACE_B
	_outside_camera_orbit = Vector2.ZERO
	_outside_camera_zoom = 0.0
	_typewriter_time = 0.0
	_typewriter_total = 0
	_solid_blockers.clear()
	_wind_trees.clear()
	_reset_kitchen_state()
	_clear_generated()
	_setup_world()
	_create_visible_sun()
	_create_background_clouds()
	_create_falling_petals()
	_create_terrain()
	_create_ponds()
	_create_chapter_one_camper_path()
	_create_ground_petals()
	_create_grass()
	_create_background_trees()
	_create_asset_trees()
	_create_chapter_one_village_house()
	_create_house_interior()
	_create_camper(CHAPTER_ONE_CAMPER_POSITION, deg_to_rad(CHAPTER_ONE_CAMPER_YAW))
	_create_chapter_one_mom()
	_create_chapter_one_rebas()
	_create_chapter_one_player()
	_orbit = Vector2(PI, 0.38)
	_zoom = 15.5
	_create_camera()
	_create_dialogue_ui()
	if _interaction_prompt != null:
		_interaction_prompt.visible = false

func _start_map_drag(screen_position: Vector2) -> void:
	_map_dragging = true
	_map_drag_start = screen_position
	_map_drag_vector = Vector2.ZERO

func _update_map_drag(screen_position: Vector2) -> void:
	var drag_offset := screen_position - _map_drag_start
	if drag_offset.length() < 12.0:
		_map_drag_vector = Vector2.ZERO
		return
	_map_drag_vector = drag_offset.normalized()

func _stop_map_drag() -> void:
	_map_dragging = false
	_map_drag_vector = Vector2.ZERO

func _is_player_near_mom() -> bool:
	if _player == null or _mom == null:
		return false
	var player_point := Vector2(_player.global_position.x, _player.global_position.z)
	var mom_point := Vector2(_mom.global_position.x, _mom.global_position.z)
	return player_point.distance_squared_to(mom_point) <= MOM_INTERACT_RADIUS * MOM_INTERACT_RADIUS

func _is_player_near_rebas() -> bool:
	if _player == null or _rebas == null:
		return false
	var player_point := Vector2(_player.global_position.x, _player.global_position.z)
	var rebas_point := Vector2(_rebas.global_position.x, _rebas.global_position.z)
	return player_point.distance_squared_to(rebas_point) <= REBAS_INTERACT_RADIUS * REBAS_INTERACT_RADIUS

func _try_start_rebas_shop() -> bool:
	if not _is_player_near_rebas():
		return false
	if _dialogue_open:
		return false
	_set_rebas_highlight(false)
	if not _rebas_intro_completed:
		_pending_open_rebas_shop = true
		_dialogue_open = true
		_dialogue_index = 0
		_dialogue_steps = _build_rebas_shop_intro_dialogue()
		if _dialogue_panel != null:
			_dialogue_panel.visible = true
		if _interaction_prompt != null:
			_interaction_prompt.visible = false
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		_show_dialogue_step()
	else:
		_open_rebas_shop()
	return true

func _build_rebas_shop_intro_dialogue() -> Array[Dictionary]:
	return [
		{"speaker": REBAS_NAME, "portrait": REBAS_PORTRAIT_PATH, "text": "你就是回到村里的年轻人吧，可以来看看我这儿的货。"},
		{"speaker": REBAS_NAME, "portrait": REBAS_PORTRAIT_PATH, "text": "村里偶尔会来些奇怪的货，不一定每天一样。"},
		{"speaker": REBAS_NAME, "portrait": REBAS_PORTRAIT_PATH, "text": "早上五点，送货的人会从山路那边过来，所以我的摊子也会跟着换一批东西。"},
		{"speaker": REBAS_NAME, "portrait": REBAS_PORTRAIT_PATH, "text": "普通种子不贵，慢慢种慢慢卖就能周转起来。"},
		{"speaker": REBAS_NAME, "portrait": REBAS_PORTRAIT_PATH, "text": "不过要是你攒够钱，可以看看那种神秘种子。没人说得准它会长出什么。"},
		{"speaker": REBAS_NAME, "portrait": REBAS_PORTRAIT_PATH, "text": "你有食材的话，之后可以放进食材箱。我会按箱子里的库存来收。"},
	]
func _is_mom_soil_task_pending() -> bool:
	return _chapter_one_active and _dialogue_completed and _has_hoe and _tilled_soil_centers.is_empty()

func _can_talk_to_mom() -> bool:
	return not _dialogue_completed or _is_mom_soil_task_pending() or (_return_to_mom_prompt_active and not _starter_kit_collected) or _watering_task_prompt_active or (_scythe_task_prompt_active and not _scythe_collected) or (_return_after_weeding_prompt_active and not _weeding_lesson_completed) or _is_crop_future_talk_pending() or _is_chest_lesson_pending()

func _should_show_mom_exclamation() -> bool:
	return not _dialogue_completed or (_return_to_mom_prompt_active and not _starter_kit_collected) or _watering_task_prompt_active or (_scythe_task_prompt_active and not _scythe_collected) or (_return_after_weeding_prompt_active and not _weeding_lesson_completed) or _is_crop_future_talk_pending() or _is_chest_lesson_pending()

func _should_show_rebas_exclamation() -> bool:
	return _chapter_one_active and _rebas != null and not _dialogue_open and not _map_open and (_shop_overlay == null or not _shop_overlay.visible) and _shop_day_key() != _rebas_seen_shop_key

func _set_mom_highlight(enabled: bool) -> void:
	_mom_is_highlighted = enabled
	if _mom_model == null:
		return
	for mesh_instance in _collect_mesh_instances(_mom_model):
		mesh_instance.material_overlay = _highlight_material if enabled else null

func _set_rebas_highlight(enabled: bool) -> void:
	_rebas_is_highlighted = enabled
	if _rebas_model == null:
		return
	for mesh_instance in _collect_mesh_instances(_rebas_model):
		mesh_instance.material_overlay = _highlight_material if enabled else null

func _try_start_mom_dialogue() -> bool:
	if not _can_talk_to_mom():
		return false
	if _dialogue_open:
		_advance_dialogue()
		return true
	if not _is_player_near_mom():
		return false
	_start_mom_dialogue()
	return true

func _start_mom_dialogue() -> void:
	_mom_talk_guide_completed = true
	_dialogue_open = true
	_dialogue_index = 0
	_dialogue_steps = _build_mom_dialogue()
	_set_mom_highlight(false)
	if _dialogue_panel != null:
		_dialogue_panel.visible = true
	if _interaction_prompt != null:
		_interaction_prompt.visible = false
	_update_inventory_bar()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_show_dialogue_step()

func _close_dialogue(completed: bool = false) -> void:
	_dialogue_open = false
	if completed:
		if not _pending_open_rebas_shop:
			_dialogue_completed = true
		_set_mom_highlight(false)
		_set_rebas_highlight(false)
		if _pending_open_rebas_shop:
			_pending_open_rebas_shop = false
			_rebas_intro_completed = true
			_open_rebas_shop()
		elif _chapter_one_active and _return_to_mom_prompt_active and not _starter_kit_collected:
			_return_to_mom_prompt_active = false
			_starter_kit_collected = true
			_grant_starter_kit()
		elif _chapter_one_active and _watering_task_prompt_active:
			_watering_task_prompt_active = false
			_watering_task_active = true
		elif _chapter_one_active and _scythe_task_prompt_active and not _scythe_collected:
			_scythe_task_prompt_active = false
			_scythe_collected = true
			_grant_scythe()
		elif _chapter_one_active and _return_after_weeding_prompt_active and not _weeding_lesson_completed:
			_return_after_weeding_prompt_active = false
			_weeding_lesson_completed = true
		elif _chapter_one_active and _is_crop_future_talk_pending():
			_crop_future_talk_completed = true
			_find_food_chests_prompt_active = true
			_food_chest_guide_completed = false
		elif _chapter_one_active and _is_chest_lesson_pending():
			_chest_lesson_completed = true
		elif _chapter_one_active and not _has_hoe:
			_grant_hoe()
	if _dialogue_panel != null:
		_dialogue_panel.visible = false
	if _interaction_prompt != null:
		_interaction_prompt.visible = false
	_clear_dialogue_options()
	_update_inventory_bar()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _advance_dialogue() -> void:
	if not _dialogue_open:
		return
	if not _is_dialogue_text_finished():
		_finish_dialogue_typewriter()
		return
	if _dialogue_index < _dialogue_steps.size():
		var step := _dialogue_steps[_dialogue_index]
		if step.has("options"):
			return
	_dialogue_index += 1
	if _dialogue_index >= _dialogue_steps.size():
		_close_dialogue(true)
		return
	_show_dialogue_step()

func _choose_dialogue_option(_option_index: int) -> void:
	if not _dialogue_open:
		return
	if not _is_dialogue_text_finished():
		_finish_dialogue_typewriter()
		return
	_dialogue_index += 1
	if _dialogue_index >= _dialogue_steps.size():
		_close_dialogue(true)
		return
	_show_dialogue_step()

func _skip_mom_dialogue() -> void:
	if not _dialogue_open:
		return
	call_deferred("_close_dialogue", true)

func _on_dialogue_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		_advance_dialogue()

func _load_portrait_texture(path: String) -> Texture2D:
	var base_texture := load(path) as Texture2D
	if base_texture == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = base_texture
	atlas.region = Rect2(430.0, 40.0, 780.0, 984.0)
	return atlas

func _show_dialogue_step() -> void:
	if _dialogue_index < 0 or _dialogue_index >= _dialogue_steps.size():
		_close_dialogue(true)
		return
	var step := _dialogue_steps[_dialogue_index]
	_dialogue_name.text = str(step["speaker"])
	_dialogue_body.text = str(step["text"])
	_typewriter_time = 0.0
	_typewriter_total = _dialogue_body.get_total_character_count()
	_dialogue_body.visible_characters = 0
	_dialogue_portrait.texture = _load_portrait_texture(str(step["portrait"]))
	_clear_dialogue_options()
	if step.has("options"):
		var options: Array = step["options"]
		for option_index in range(options.size()):
			var option_button := Button.new()
			option_button.text = str(options[option_index])
			option_button.custom_minimum_size = Vector2(300.0, 44.0)
			option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			option_button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			option_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			option_button.add_theme_font_size_override("font_size", 16)
			option_button.add_theme_color_override("font_color", Color(0.24, 0.16, 0.06))
			option_button.add_theme_stylebox_override("normal", _make_round_style(Color(0.96, 0.84, 0.55, 0.96), Color(0.55, 0.39, 0.18, 0.38), 22.0, 1))
			option_button.add_theme_stylebox_override("hover", _make_round_style(Color(1.0, 0.90, 0.66, 1.0), Color(0.55, 0.39, 0.18, 0.56), 22.0, 1))
			option_button.add_theme_stylebox_override("pressed", _make_round_style(Color(0.88, 0.72, 0.42, 1.0), Color(0.48, 0.33, 0.14, 0.62), 22.0, 1))
			option_button.pressed.connect(_choose_dialogue_option.bind(option_index))
			option_button.visible = false
			_dialogue_options.add_child(option_button)

func _update_dialogue_typewriter(delta: float) -> void:
	if _dialogue_body == null or _typewriter_total <= 0:
		return
	if _dialogue_body.visible_characters >= _typewriter_total:
		_show_dialogue_options(true)
		return
	_typewriter_time += delta * DIALOGUE_CHARS_PER_SECOND
	_dialogue_body.visible_characters = mini(int(_typewriter_time), _typewriter_total)
	if _dialogue_body.visible_characters >= _typewriter_total:
		_show_dialogue_options(true)

func _is_dialogue_text_finished() -> bool:
	return _dialogue_body == null or _typewriter_total <= 0 or _dialogue_body.visible_characters >= _typewriter_total

func _finish_dialogue_typewriter() -> void:
	if _dialogue_body == null:
		return
	_dialogue_body.visible_characters = _typewriter_total
	_show_dialogue_options(true)

func _show_dialogue_options(visible: bool) -> void:
	if _dialogue_options == null:
		return
	for child in _dialogue_options.get_children():
		if child is CanvasItem:
			child.visible = visible

func _clear_dialogue_options() -> void:
	if _dialogue_options == null:
		return
	for child in _dialogue_options.get_children():
		child.queue_free()

func _is_dialogue_open() -> bool:
	return _dialogue_open

func _is_map_open() -> bool:
	return _map_open

func _is_chapter_transitioning() -> bool:
	return _chapter_transitioning or _house_transitioning

func _fit_model_to_height(model: Node3D, target_height: float) -> void:
	var bounds := _get_model_bounds(model)
	if bounds.size.y <= 0.001:
		return
	var factor := target_height / bounds.size.y
	model.scale *= factor

func _fit_model_to_max_dimension(model: Node3D, target_size: float) -> void:
	var bounds := _get_model_bounds(model)
	var max_dimension := maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
	if max_dimension <= 0.001:
		return
	var factor := target_size / max_dimension
	model.scale *= factor

func _fit_model_to_footprint_length(model: Node3D, target_length: float) -> void:
	var bounds := _get_model_bounds(model)
	var footprint_length := maxf(bounds.size.x, bounds.size.z)
	if footprint_length <= 0.001:
		return
	var factor := target_length / footprint_length
	model.scale *= factor

func _ground_model(model: Node3D) -> void:
	var bounds := _get_model_bounds(model)
	model.position.y -= bounds.position.y * model.scale.y

func _center_model_on_origin(model: Node3D) -> void:
	var bounds := _get_model_bounds(model)
	var center := bounds.get_center()
	model.position -= Vector3(center.x * model.scale.x, center.y * model.scale.y, center.z * model.scale.z)

func _set_model_shadow(model: Node3D, mode: int) -> void:
	for mesh_instance in _collect_mesh_instances(model):
		mesh_instance.cast_shadow = mode
		_stabilize_imported_materials(mesh_instance)

func _stabilize_imported_materials(mesh_instance: MeshInstance3D) -> void:
	var mesh := mesh_instance.mesh
	if mesh == null:
		return
	for surface_index in range(mesh.get_surface_count()):
		var material := mesh.surface_get_material(surface_index)
		if material is BaseMaterial3D:
			var base_material := material as BaseMaterial3D
			base_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
			base_material.alpha_antialiasing_mode = BaseMaterial3D.ALPHA_ANTIALIASING_OFF
			base_material.no_depth_test = false
			base_material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY

func _yaw_toward(from_position: Vector3, to_position: Vector3) -> float:
	var direction := to_position - from_position
	direction.y = 0.0
	if direction.length_squared() <= 0.0001:
		return 0.0
	direction = direction.normalized()
	return atan2(direction.x, direction.z)

func _add_camper_blocker(camper: Node3D, model: Node3D) -> void:
	var bounds := _get_model_bounds(model)
	var center_local := bounds.get_center()
	var center_world := model.global_transform * center_local
	var half_extents := Vector2(
		maxf(bounds.size.x * model.scale.x * 0.5 * CAMPER_BLOCKER_SHRINK + CAMPER_BLOCKER_PADDING.x, 0.9),
		maxf(bounds.size.z * model.scale.z * 0.5 * CAMPER_BLOCKER_SHRINK + CAMPER_BLOCKER_PADDING.y, 1.45)
	)
	_solid_blockers.append({
		"shape": "box",
		"center": center_world,
		"yaw": camper.rotation.y,
		"half_extents": half_extents,
	})

func _add_circle_blocker(center: Vector3, radius: float) -> void:
	_solid_blockers.append({
		"shape": "circle",
		"center": center,
		"radius": radius,
	})

func _add_box_blocker(center: Vector3, yaw: float, half_extents: Vector2, house_interior_only: bool = false) -> void:
	_solid_blockers.append({
		"shape": "box",
		"center": center,
		"yaw": yaw,
		"half_extents": half_extents,
		"house_interior_only": house_interior_only,
	})

func _add_model_box_blocker(root: Node3D, model: Node3D, padding: Vector2, shrink: float = 1.0) -> void:
	var bounds := _get_model_bounds(model)
	var center_local := bounds.get_center()
	var center_world := model.global_transform * center_local
	var half_extents := Vector2(
		maxf(bounds.size.x * model.scale.x * 0.5 * shrink + padding.x, 0.8),
		maxf(bounds.size.z * model.scale.z * 0.5 * shrink + padding.y, 0.8)
	)
	_solid_blockers.append({
		"shape": "box",
		"center": center_world,
		"yaw": root.rotation.y,
		"half_extents": half_extents,
	})

func _add_tree_blocker(center: Vector3, radius: float, tree_index: int) -> void:
	_solid_blockers.append({
		"shape": "tree",
		"center": center,
		"radius": radius,
		"tree_index": tree_index,
	})

func _handle_solid_bump(world_position: Vector3) -> bool:
	var point := Vector2(world_position.x, world_position.z)
	for blocker in _solid_blockers:
		var shape: String = blocker["shape"]
		var center_3d: Vector3 = blocker["center"]
		var center := Vector2(center_3d.x, center_3d.z)
		if shape == "tree":
			var radius: float = blocker["radius"]
			if point.distance_squared_to(center) <= radius * radius:
				_shake_tree(int(blocker["tree_index"]), point - center)
				return true
		elif _is_point_inside_blocker(point, blocker):
			return true
	return false

func _shake_tree(tree_index: int, impact_offset: Vector2) -> void:
	if tree_index < 0 or tree_index >= _wind_trees.size():
		return
	var shake_axis := impact_offset
	if shake_axis.length_squared() <= 0.0001:
		shake_axis = Vector2.RIGHT
	else:
		shake_axis = shake_axis.normalized()
	_wind_trees[tree_index]["shake_time"] = TREE_SHAKE_DURATION
	_wind_trees[tree_index]["shake_axis"] = shake_axis
	if not _tree_seed_drop_shaken_tree_indices.has(tree_index):
		_tree_seed_drop_shaken_tree_indices.append(tree_index)
		_tree_seed_drop_shake_counter += 1
	if _tree_seed_drop_shake_counter >= _tree_seed_drop_shake_target:
		_tree_seed_drop_shake_counter = 0
		_tree_seed_drop_shake_target = _roll_tree_seed_drop_shake_target()
		_tree_seed_drop_shaken_tree_indices.clear()
		var tree := _wind_trees[tree_index]["node"] as Node3D
		if tree != null and is_instance_valid(tree):
			_create_seed_resource_drop(tree.global_position + Vector3(0.0, 0.65, 0.0), CROP_BELL_PEPPER, _roll_seed_quality())

func _shake_nearby_tree() -> bool:
	if _player == null:
		return false
	var player_point := Vector2(_player.global_position.x, _player.global_position.z)
	var closest_index := -1
	var closest_offset := Vector2.ZERO
	var closest_distance_sq := TREE_CLICK_SHAKE_RADIUS * TREE_CLICK_SHAKE_RADIUS
	for index in range(_wind_trees.size()):
		var tree := _wind_trees[index]["node"] as Node3D
		if tree == null:
			continue
		var tree_point := Vector2(tree.global_position.x, tree.global_position.z)
		var offset := player_point - tree_point
		var distance_sq := offset.length_squared()
		if distance_sq <= closest_distance_sq:
			closest_distance_sq = distance_sq
			closest_index = index
			closest_offset = offset
	if closest_index == -1:
		return false
	_shake_tree(closest_index, closest_offset)
	return true

func _is_blocked_by_solid(world_position: Vector3) -> bool:
	var point := Vector2(world_position.x, world_position.z)
	for blocker in _solid_blockers:
		if _is_point_inside_blocker(point, blocker):
			return true
	return false

func _is_point_inside_blocker(point: Vector2, blocker: Dictionary) -> bool:
	if bool(blocker.get("house_interior_only", false)) and not _inside_house:
		return false
	var shape: String = blocker["shape"]
	var center_3d: Vector3 = blocker["center"]
	var center := Vector2(center_3d.x, center_3d.z)
	if shape == "box":
		var yaw: float = blocker["yaw"]
		var half_extents: Vector2 = blocker["half_extents"]
		var local := (point - center).rotated(-yaw)
		return absf(local.x) <= half_extents.x and absf(local.y) <= half_extents.y
	elif shape == "circle" or shape == "tree":
		var radius: float = blocker["radius"]
		return point.distance_squared_to(center) <= radius * radius
	return false

func _is_point_inside_house_interior_floor(point: Vector2) -> bool:
	var center := Vector2(HOUSE_INTERIOR_CENTER.x, HOUSE_INTERIOR_CENTER.z)
	var half := HOUSE_INTERIOR_SIZE * 0.5 + Vector2(0.35, 0.35)
	var local := point - center
	return absf(local.x) <= half.x and absf(local.y) <= half.y

func _get_model_bounds(model: Node3D) -> AABB:
	var has_bounds := false
	var bounds := AABB()
	var model_to_local := model.global_transform.affine_inverse()
	for mesh_instance in _collect_mesh_instances(model):
		var mesh_bounds: AABB = mesh_instance.get_aabb()
		for corner in _aabb_corners(mesh_bounds):
			var local_point := model_to_local * (mesh_instance.global_transform * corner)
			if not has_bounds:
				bounds = AABB(local_point, Vector3.ZERO)
				has_bounds = true
			else:
				bounds = bounds.expand(local_point)
	return bounds

func _collect_mesh_instances(root: Node) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	if root is MeshInstance3D:
		meshes.append(root)
	for child in root.get_children():
		meshes.append_array(_collect_mesh_instances(child))
	return meshes

func _aabb_corners(bounds: AABB) -> Array[Vector3]:
	var p := bounds.position
	var s := bounds.size
	return [
		p,
		p + Vector3(s.x, 0.0, 0.0),
		p + Vector3(0.0, s.y, 0.0),
		p + Vector3(0.0, 0.0, s.z),
		p + Vector3(s.x, s.y, 0.0),
		p + Vector3(s.x, 0.0, s.z),
		p + Vector3(0.0, s.y, s.z),
		p + s,
	]

func _create_camera() -> void:
	_camera_pivot = Node3D.new()
	_camera_pivot.name = "CameraPivot"
	_mark_generated(_camera_pivot)
	add_child(_camera_pivot)

	_camera = Camera3D.new()
	_camera.name = "Camera"
	_camera.fov = 48.0
	_camera.near = 0.04
	_camera.current = true
	_camera_pivot.add_child(_camera)
	_apply_camera()

func _update_camera_input(delta: float) -> void:
	var zoom_speed := 7.5
	if Input.is_key_pressed(KEY_Q):
		_zoom = clampf(_zoom + zoom_speed * delta, 9.0, 26.0)
	if Input.is_key_pressed(KEY_E):
		_zoom = clampf(_zoom - zoom_speed * delta, 9.0, 26.0)
	_apply_camera()

func get_camera_yaw() -> float:
	return _orbit.x

func _apply_camera() -> void:
	if _camera_pivot == null or _camera == null:
		return
	var follow_target := Vector3.ZERO
	if _player != null and is_instance_valid(_player):
		follow_target = _player.global_position
	var target := follow_target + Vector3(0.0, 1.15, 0.0)
	var distance := cos(_orbit.y) * _zoom
	var height := sin(_orbit.y) * _zoom + 1.1
	var eye_offset := Vector3(0.0, height, -distance).rotated(Vector3.UP, _orbit.x)
	var eye := follow_target + eye_offset + _camera_shake_offset
	target += _camera_shake_offset * 0.35
	_camera.global_position = eye
	_camera.look_at(target, Vector3.UP)

func _height_at(x: float, z: float) -> float:
	if _inside_house and _is_point_inside_house_interior_floor(Vector2(x, z)):
		return HOUSE_INTERIOR_FLOOR_Y
	var rolling := sin(x * 0.026 + z * 0.014) * 1.35
	var cross_slope := cos(x * 0.018 - z * 0.024 + 1.2) * 0.95
	var meadow := sin(x * 0.056) * 0.42 + cos(z * 0.049) * 0.38
	var small := sin((x + z) * 0.105) * 0.16
	return rolling + cross_slope + meadow + small

func _normal_at(x: float, z: float) -> Vector3:
	var sample_distance := 1.0
	var left := _height_at(x - sample_distance, z)
	var right := _height_at(x + sample_distance, z)
	var back := _height_at(x, z - sample_distance)
	var front := _height_at(x, z + sample_distance)
	return Vector3(left - right, sample_distance * 2.0, back - front).normalized()
