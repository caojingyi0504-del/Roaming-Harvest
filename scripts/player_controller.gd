extends CharacterBody3D

@export var walk_speed: float = 5.2
@export var run_speed: float = 8.0
@export var turn_speed: float = 12.0
@export var ground_offset: float = 0.04
@export var field_limit: float = 72.0
@export var model_forward_offset: float = 0.0

@onready var visual_root: Node3D = $VisualRoot

func _ready() -> void:
	_disable_real_shadows(self)

func _physics_process(delta: float) -> void:
	if get_parent().has_method("_is_dialogue_open") and get_parent()._is_dialogue_open():
		velocity = Vector3.ZERO
		return
	if get_parent().has_method("_is_map_open") and get_parent()._is_map_open():
		velocity = Vector3.ZERO
		return

	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_A):
		input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		input_dir.x += 1.0
	if Input.is_key_pressed(KEY_W):
		input_dir.y += 1.0
	if Input.is_key_pressed(KEY_S):
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
	next_position.x = clampf(next_position.x, -field_limit, field_limit)
	next_position.z = clampf(next_position.z, -field_limit, field_limit)

	if get_parent().has_method("_is_inside_pond") and get_parent()._is_inside_pond(next_position.x, next_position.z, 0.65):
		next_position.x = global_position.x
		next_position.z = global_position.z

	if get_parent().has_method("_is_blocked_by_solid") and get_parent()._is_blocked_by_solid(next_position):
		if get_parent().has_method("_handle_solid_bump"):
			get_parent()._handle_solid_bump(next_position)
		next_position.x = global_position.x
		next_position.z = global_position.z

	if get_parent().has_method("_height_at"):
		next_position.y = get_parent()._height_at(next_position.x, next_position.z) + ground_offset

	global_position = next_position

	if move_dir.length_squared() > 0.0:
		var target_yaw := atan2(move_dir.x, move_dir.z)
		visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_yaw + model_forward_offset, minf(turn_speed * delta, 1.0))

func _disable_real_shadows(node: Node) -> void:
	if node is GeometryInstance3D:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		_disable_real_shadows(child)
