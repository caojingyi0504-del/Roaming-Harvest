extends Node

signal world_changed(world_id: StringName)
signal spawn_registered(spawn_id: StringName, node: Node3D)
signal portal_transition_requested(portal: Node, body: Node3D)

var current_world_id: StringName = &"default"
var spawns: Dictionary = {}
var world_state: Dictionary = {}

func set_current_world(world_id: StringName) -> void:
	if current_world_id == world_id:
		return
	current_world_id = world_id
	world_changed.emit(current_world_id)

func register_spawn(spawn_id: StringName, node: Node3D) -> void:
	if spawn_id == StringName() or node == null:
		return
	spawns[String(spawn_id)] = node
	spawn_registered.emit(spawn_id, node)

func get_spawn_position(spawn_id: StringName, fallback := Vector3.ZERO) -> Vector3:
	var node: Variant = spawns.get(String(spawn_id))
	if node is Node3D:
		return (node as Node3D).global_position
	return fallback

func request_portal_transition(portal: Node, body: Node3D) -> void:
	portal_transition_requested.emit(portal, body)
	var target_scene := portal.get("target_scene") as PackedScene
	var target_position := Vector3.ZERO
	var target_position_value: Variant = portal.get("target_position")
	if target_position_value is Vector3:
		target_position = target_position_value
	if target_scene != null:
		get_tree().change_scene_to_packed(target_scene)
	elif body != null and target_position != Vector3.ZERO:
		body.global_position = target_position

func get_world_snapshot() -> Dictionary:
	return {
		"current_world_id": String(current_world_id),
		"world_state": world_state.duplicate(true),
	}

func apply_world_snapshot(snapshot: Dictionary) -> void:
	current_world_id = StringName(str(snapshot.get("current_world_id", String(current_world_id))))
	world_state = snapshot.get("world_state", {}).duplicate(true)
