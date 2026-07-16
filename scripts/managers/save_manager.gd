extends Node

signal save_completed(path: String)
signal load_completed(path: String)
signal save_failed(path: String, reason: String)
signal load_failed(path: String, reason: String)

const DEFAULT_SAVE_PATH := "user://savegame.json"

func save_game(path: String = DEFAULT_SAVE_PATH) -> bool:
	var snapshot := create_snapshot()
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		save_failed.emit(path, error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify(snapshot, "\t"))
	save_completed.emit(path)
	return true

func load_game(path: String = DEFAULT_SAVE_PATH) -> bool:
	if not FileAccess.file_exists(path):
		load_failed.emit(path, "file_not_found")
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		load_failed.emit(path, error_string(FileAccess.get_open_error()))
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		load_failed.emit(path, "invalid_json")
		return false
	apply_snapshot(parsed)
	load_completed.emit(path)
	return true

func create_snapshot() -> Dictionary:
	return {
		"version": 4,
		"player": _collect_player_snapshot(),
		"inventory": _call_manager("InventoryManager", "get_inventory_snapshot", {}),
		"crops": _call_manager("CropManager", "get_crop_snapshot", {}),
		"quests": _collect_quest_snapshot(),
		"world": _call_manager("WorldManager", "get_world_snapshot", {}),
		"time": _call_manager("TimeManager", "get_time_snapshot", {}),
		"components": _collect_component_snapshots(),
	}

func apply_snapshot(snapshot: Dictionary) -> void:
	snapshot = _migrate_snapshot(snapshot)
	_apply_player_snapshot(snapshot.get("player", {}))
	_call_manager("InventoryManager", "apply_inventory_snapshot", null, [snapshot.get("inventory", {})])
	_call_manager("CropManager", "apply_crop_snapshot", null, [snapshot.get("crops", {})])
	_call_manager("WorldManager", "apply_world_snapshot", null, [snapshot.get("world", {})])
	_call_manager("TimeManager", "apply_time_snapshot", null, [snapshot.get("time", {})])
	_apply_component_snapshots(snapshot.get("components", {}))

func _migrate_snapshot(source: Dictionary) -> Dictionary:
	var snapshot := source.duplicate(true)
	var version := int(snapshot.get("version", 1))
	if version < 2:
		var world := snapshot.get("world", {}) as Dictionary
		var world_state := world.get("world_state", {}) as Dictionary
		if not world_state.has("roaming_harvest_progression_v2"):
			world_state["roaming_harvest_progression_v2"] = {
				"unlocked_crops": {"carrot": true},
				"codex_discovered_crops": {},
				"codex_harvested_crops": {},
				"local_event_state": {},
				"local_event_perks": {},
				"local_event_atlas": {},
				"scheduled_day_event": "",
				"scheduled_night_event": "",
				"schedule_day": -1,
			}
		world["world_state"] = world_state
		snapshot["world"] = world
		snapshot["version"] = 2
		version = 2
	if version < 3:
		var world_v3 := snapshot.get("world", {}) as Dictionary
		var world_state_v3 := world_v3.get("world_state", {}) as Dictionary
		var progression := world_state_v3.get("roaming_harvest_progression_v2", {}) as Dictionary
		if not progression.has("codex_discovered_cooking"):
			progression["needs_cooking_codex_inference"] = true
			progression["codex_discovered_cooking"] = {}
		if not progression.has("codex_revealed_cooking"):
			progression["codex_revealed_cooking"] = {}
		if not progression.has("codex_claimed_rewards"):
			progression["codex_claimed_rewards"] = {}
		if not progression.has("research_table_unlocked"):
			progression["research_table_unlocked"] = false
		if not progression.has("researched_special_recipes"):
			progression["researched_special_recipes"] = {}
		if not progression.has("special_recipe_first_served"):
			progression["special_recipe_first_served"] = {}
		world_state_v3["roaming_harvest_progression_v2"] = progression
		world_v3["world_state"] = world_state_v3
		snapshot["world"] = world_v3
		snapshot["version"] = 3
		version = 3
	if version < 4:
		var world_v4 := snapshot.get("world", {}) as Dictionary
		var world_state_v4 := world_v4.get("world_state", {}) as Dictionary
		var progression_v4 := world_state_v4.get("roaming_harvest_progression_v2", {}) as Dictionary
		if not progression_v4.has("business_discovery_states"):
			progression_v4["business_discovery_states"] = {}
		if not progression_v4.has("business_discovery_rumors"):
			progression_v4["business_discovery_rumors"] = {}
		world_state_v4["roaming_harvest_progression_v2"] = progression_v4
		world_v4["world_state"] = world_state_v4
		snapshot["world"] = world_v4
		snapshot["version"] = 4
	return snapshot

func _collect_player_snapshot() -> Dictionary:
	var player: Node = _get_player()
	if player == null and get_tree().current_scene != null:
		player = get_tree().current_scene.get_node_or_null("Player")
	if player is Node3D:
		var player_3d := player as Node3D
		return {
			"position": [player_3d.global_position.x, player_3d.global_position.y, player_3d.global_position.z],
			"rotation": [player_3d.global_rotation.x, player_3d.global_rotation.y, player_3d.global_rotation.z],
		}
	return {}

func _apply_player_snapshot(data: Dictionary) -> void:
	var player: Node = _get_player()
	if player is Node3D and data.has("position"):
		(player as Node3D).global_position = _array_to_vector3(data.get("position", []))

func _collect_quest_snapshot() -> Dictionary:
	var quests := {}
	for node in get_tree().get_nodes_in_group("quest_components"):
		if node.has_method("collect_save_data"):
			quests[str(node.get_instance_id())] = node.collect_save_data()
	return quests

func _collect_component_snapshots() -> Dictionary:
	var components := {}
	for node in get_tree().get_nodes_in_group("saveable"):
		if node.has_method("collect_save_data"):
			var data: Dictionary = node.collect_save_data()
			var save_id := str(data.get("save_id", node.get_instance_id()))
			components[save_id] = data
	return components

func _apply_component_snapshots(components: Dictionary) -> void:
	for node in get_tree().get_nodes_in_group("saveable"):
		if not node.has_method("apply_save_data") or not node.has_method("collect_save_data"):
			continue
		var data: Dictionary = node.collect_save_data()
		var save_id := str(data.get("save_id", node.get_instance_id()))
		if components.has(save_id):
			node.apply_save_data(components[save_id])

func _array_to_vector3(value: Array) -> Vector3:
	if value.size() < 3:
		return Vector3.ZERO
	return Vector3(float(value[0]), float(value[1]), float(value[2]))

func _get_player() -> Node:
	var game_manager := get_node_or_null("/root/GameManager")
	if game_manager == null:
		return null
	return game_manager.get("player") as Node

func _call_manager(manager_name: String, method_name: String, fallback: Variant = null, args: Array = []) -> Variant:
	var manager := get_node_or_null("/root/%s" % manager_name)
	if manager == null or not manager.has_method(method_name):
		return fallback
	return manager.callv(method_name, args)
