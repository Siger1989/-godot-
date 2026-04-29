extends Node3D
class_name PlayerModelVisual

@export_file("*.glb", "*.gltf", "*.tscn") var model_path := "res://assets/models/player.glb"
@export var target_height := 1.58
@export var ground_y := 0.0
@export var yaw_degrees := 180.0
@export var extra_offset := Vector3.ZERO
@export var source_bounds_position := Vector3(-0.869526, -1.001178, -0.242241)
@export var source_bounds_size := Vector3(1.691613, 1.891471, 0.547781)
@export var use_source_bounds := true
@export var use_source_locomotion := true
@export var idle_pose_time := 0.05
@export var walk_animation_speed := 0.86
@export var run_animation_speed := 1.48
@export_range(0.0, 1.0, 0.01) var walk_forearm_idle_blend := 0.08
@export_range(0.0, 1.0, 0.01) var run_forearm_idle_blend := 0.24

const ADJUSTMENT_CONFIG := "res://assets/models/player_model_adjustment.cfg"

var model_instance: Node3D
var motion_speed := 0.0
var sprinting := false

var _animation_player: AnimationPlayer
var _skeleton: Skeleton3D
var _source_animation_name := ""
var _animation_state := ""
var _forearm_bones: Array[int] = []
var _idle_bone_rotations: Dictionary = {}


func _ready() -> void:
	_load_adjustment_config()
	if _is_headless():
		return
	var packed := ResourceLoader.load(model_path) as PackedScene
	if not packed:
		push_warning("Player model could not be loaded: %s" % model_path)
		return

	model_instance = packed.instantiate() as Node3D
	if not model_instance:
		push_warning("Player model is not a Node3D scene: %s" % model_path)
		return

	model_instance.name = "ImportedPlayerModel"
	add_child(model_instance)
	_fit_model_to_player()
	_setup_source_animation()


func apply_adjustment(height: float, yaw: float, offset: Vector3) -> void:
	target_height = height
	yaw_degrees = yaw
	extra_offset = offset
	if model_instance:
		_fit_model_to_player()


func reset_adjustment() -> void:
	apply_adjustment(1.58, 180.0, Vector3.ZERO)


func save_adjustment_config() -> void:
	var config := ConfigFile.new()
	config.set_value("player_model", "target_height", target_height)
	config.set_value("player_model", "yaw_degrees", yaw_degrees)
	config.set_value("player_model", "extra_offset", extra_offset)
	var err := config.save(ADJUSTMENT_CONFIG)
	if err != OK:
		push_warning("Could not save player model adjustment: %s" % ADJUSTMENT_CONFIG)


func get_adjustment() -> Dictionary:
	return {
		"target_height": target_height,
		"yaw_degrees": yaw_degrees,
		"extra_offset": extra_offset,
	}


func get_current_height() -> float:
	return target_height


func set_motion_state(speed: float, is_sprinting: bool) -> void:
	motion_speed = speed
	sprinting = is_sprinting


func get_animation_status() -> Dictionary:
	return {
		"has_animation_player": _animation_player != null,
		"source_animation": _source_animation_name,
		"state": _animation_state,
	}


func _process(_delta: float) -> void:
	_update_source_animation_state()
	if not _forearm_bones.is_empty():
		call_deferred("_apply_forearm_run_adjustment")


func _load_adjustment_config() -> void:
	if not FileAccess.file_exists(ADJUSTMENT_CONFIG):
		return
	var config := ConfigFile.new()
	if config.load(ADJUSTMENT_CONFIG) != OK:
		return
	target_height = float(config.get_value("player_model", "target_height", target_height))
	yaw_degrees = float(config.get_value("player_model", "yaw_degrees", yaw_degrees))
	extra_offset = config.get_value("player_model", "extra_offset", extra_offset)


func _is_headless() -> bool:
	return DisplayServer.get_name() == "headless"


func _setup_source_animation() -> void:
	_animation_player = _find_animation_player(model_instance)
	_skeleton = _find_skeleton(model_instance)
	if not _animation_player:
		return
	var animations := _animation_player.get_animation_list()
	for animation_name in animations:
		if animation_name != "RESET":
			_source_animation_name = animation_name
			break
	if _source_animation_name.is_empty():
		return
	_animation_player.play(_source_animation_name)
	_animation_player.seek(idle_pose_time, true)
	_animation_player.speed_scale = 0.0
	_animation_state = "idle"
	_cache_forearm_bones()


func _update_source_animation_state() -> void:
	if not use_source_locomotion:
		return
	if not _animation_player or _source_animation_name.is_empty():
		return

	var moving := motion_speed > 0.12
	var next_state := "run" if moving and sprinting else "walk" if moving else "idle"
	if _animation_player.current_animation != _source_animation_name:
		_animation_player.play(_source_animation_name)

	if next_state == "idle":
		_animation_player.speed_scale = 0.0
		if _animation_state != "idle":
			_animation_player.seek(idle_pose_time, true)
	else:
		_animation_player.speed_scale = run_animation_speed if next_state == "run" else walk_animation_speed
		if _animation_state == "idle":
			_animation_player.seek(idle_pose_time, true)

	_animation_state = next_state


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found:
			return found
	return null


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found:
			return found
	return null


func _cache_forearm_bones() -> void:
	if not _skeleton:
		return
	_forearm_bones.clear()
	_idle_bone_rotations.clear()
	for bone_name in ["LeftForeArm", "RightForeArm"]:
		var bone_index := _skeleton.find_bone(bone_name)
		if bone_index >= 0:
			_forearm_bones.append(bone_index)
			_idle_bone_rotations[bone_index] = _skeleton.get_bone_pose_rotation(bone_index)


func _apply_forearm_run_adjustment() -> void:
	if not _skeleton or _forearm_bones.is_empty():
		return
	var blend := 0.0
	if _animation_state == "run":
		blend = run_forearm_idle_blend
	elif _animation_state == "walk":
		blend = walk_forearm_idle_blend
	if blend <= 0.0:
		return
	for bone_index in _forearm_bones:
		if not _idle_bone_rotations.has(bone_index):
			continue
		var current := _skeleton.get_bone_pose_rotation(bone_index)
		var idle_rotation := _idle_bone_rotations[bone_index] as Quaternion
		_skeleton.set_bone_pose_rotation(bone_index, current.slerp(idle_rotation, blend))


func _fit_model_to_player() -> void:
	model_instance.position = Vector3.ZERO
	model_instance.rotation = Vector3(0.0, deg_to_rad(yaw_degrees), 0.0)
	model_instance.scale = Vector3.ONE

	var bounds := _get_source_bounds()
	if bounds.size.y <= 0.001:
		return

	var scale_factor := target_height / bounds.size.y
	model_instance.scale = Vector3.ONE * scale_factor

	var scaled_bounds := _calculate_transformed_bounds(bounds, scale_factor, deg_to_rad(yaw_degrees))
	var center := scaled_bounds.position + scaled_bounds.size * 0.5
	model_instance.position += Vector3(-center.x, ground_y - scaled_bounds.position.y, -center.z) + extra_offset


func _get_source_bounds() -> AABB:
	if use_source_bounds and source_bounds_size.y > 0.001:
		return AABB(source_bounds_position, source_bounds_size)
	return _calculate_model_bounds()


func _calculate_transformed_bounds(bounds: AABB, scale_factor: float, yaw: float) -> AABB:
	var basis := Basis(Vector3.UP, yaw).scaled(Vector3.ONE * scale_factor)
	var has_bounds := false
	var combined := AABB()
	for corner in _aabb_corners(bounds):
		var point := basis * corner
		if not has_bounds:
			combined = AABB(point, Vector3.ZERO)
			has_bounds = true
		else:
			combined = combined.expand(point)
	return combined


func _calculate_model_bounds() -> AABB:
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(model_instance, meshes)

	var has_bounds := false
	var combined := AABB()
	for mesh_instance in meshes:
		if not mesh_instance.mesh:
			continue
		var mesh_bounds := mesh_instance.mesh.get_aabb()
		for corner in _aabb_corners(mesh_bounds):
			var local_point := global_transform.affine_inverse() * (mesh_instance.global_transform * corner)
			if not has_bounds:
				combined = AABB(local_point, Vector3.ZERO)
				has_bounds = true
			else:
				combined = combined.expand(local_point)
	return combined


func _collect_meshes(node: Node, meshes: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		meshes.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect_meshes(child, meshes)


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
