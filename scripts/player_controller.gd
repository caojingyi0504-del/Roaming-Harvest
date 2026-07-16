extends CharacterBody3D

@export var walk_speed: float = 5.2
@export var run_speed: float = 8.0
@export var turn_speed: float = 12.0
@export var ground_offset: float = 0.04
@export var field_limit: float = 72.0
@export var model_forward_offset: float = 0.0

@onready var visual_root: Node3D = $VisualRoot

var current_outfit_id := "default_traveler"

func _ready() -> void:
	_disable_real_shadows(self)

func apply_outfit(outfit_id: String, model_path: String) -> bool:
	if visual_root == null or model_path == "" or not ResourceLoader.exists(model_path, "PackedScene"):
		return false
	var scene := ResourceLoader.load(model_path) as PackedScene
	if scene == null:
		return false
	var next_model := scene.instantiate() as Node3D
	if next_model == null:
		return false
	next_model.name = "Model"
	visual_root.add_child(next_model)
	_disable_real_shadows(next_model)
	for child in visual_root.get_children():
		if child == next_model:
			continue
		visual_root.remove_child(child)
		child.queue_free()
	current_outfit_id = outfit_id
	return true

func _physics_process(delta: float) -> void:
	if get_parent().has_method("_is_camper_driving") and get_parent()._is_camper_driving():
		velocity = Vector3.ZERO
		return
	if get_parent().has_method("_is_chapter_transitioning") and get_parent()._is_chapter_transitioning():
		velocity = Vector3.ZERO
		return
	if get_parent().has_method("_is_dialogue_open") and get_parent()._is_dialogue_open():
		velocity = Vector3.ZERO
		return
	if get_parent().has_method("_is_map_open") and get_parent()._is_map_open():
		velocity = Vector3.ZERO
		return
	if get_parent().has_method("_is_kitchen_equipment_placement_active") and get_parent()._is_kitchen_equipment_placement_active():
		velocity = Vector3.ZERO
		return

	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_dir.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_dir.y += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_dir.y -= 1.0

	var move_dir := Vector3.ZERO
	if input_dir.length_squared() > 0.0:
		input_dir = input_dir.normalized()
		var forward := Vector3.FORWARD
		var right := Vector3.RIGHT
		var camera := get_viewport().get_camera_3d()
		if camera != null:
			forward = -camera.global_transform.basis.z
			right = camera.global_transform.basis.x
			forward.y = 0.0
			right.y = 0.0
			forward = forward.normalized()
			right = right.normalized()
		elif get_parent().has_method("get_camera_yaw"):
			var camera_yaw: float = get_parent().get_camera_yaw()
			forward = Vector3(sin(camera_yaw), 0.0, cos(camera_yaw))
			right = Vector3(cos(camera_yaw), 0.0, -sin(camera_yaw))
		move_dir = (right * input_dir.x + forward * input_dir.y).normalized()

	var speed := run_speed if Input.is_key_pressed(KEY_SHIFT) else walk_speed
	var next_position := global_position + move_dir * speed * delta
	next_position = _clamp_to_field(next_position)

	if _is_position_blocked(next_position):
		var slide_x := _clamp_to_field(Vector3(global_position.x + move_dir.x * speed * delta, global_position.y, global_position.z))
		var slide_z := _clamp_to_field(Vector3(global_position.x, global_position.y, global_position.z + move_dir.z * speed * delta))
		if not _is_position_blocked(slide_x):
			next_position = slide_x
		elif not _is_position_blocked(slide_z):
			next_position = slide_z
		else:
			if get_parent().has_method("_handle_solid_bump"):
				get_parent()._handle_solid_bump(next_position)
			next_position = global_position

	if get_parent().has_method("_height_at"):
		next_position.y = get_parent()._height_at(next_position.x, next_position.z) + ground_offset

	global_position = next_position

	if move_dir.length_squared() > 0.0:
		var target_yaw := atan2(move_dir.x, move_dir.z)
		visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_yaw + model_forward_offset, minf(turn_speed * delta, 1.0))

func _clamp_to_field(position: Vector3) -> Vector3:
	position.x = clampf(position.x, -field_limit, field_limit)
	position.z = clampf(position.z, -field_limit, field_limit)
	return position

func _is_position_blocked(position: Vector3) -> bool:
	if get_parent().has_method("_is_inside_pond") and get_parent()._is_inside_pond(position.x, position.z, 0.65):
		return true
	if get_parent().has_method("_is_blocked_by_solid") and get_parent()._is_blocked_by_solid(position):
		return true
	return false

func _disable_real_shadows(node: Node) -> void:
	if node is GeometryInstance3D:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		_disable_real_shadows(child)
