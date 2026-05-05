extends Node

const CutoutShader = preload("res://materials/foreground_occlusion_cutout.gdshader")

@export var enabled := true
@export_node_path("Camera3D") var camera_path: NodePath
@export_node_path("Node3D") var target_path: NodePath
@export var target_height := 1.0
@export var max_hits := 8
@export var occluder_group: StringName = &"foreground_occluder"
@export var linked_visual_group: StringName = &"door_frame"
@export var cutout_radius_u := 0.78
@export var cutout_radius_v := 1.12
@export var cutout_feather := 0.32
@export var cutout_release_delay := 0.16
@export var probe_horizontal_offset := 0.28
@export var probe_vertical_offset := 0.46
@export var bidirectional_probe := true

var _hidden_meshes: Array[MeshInstance3D] = []
var _last_hit_bodies: Array[Node] = []
var _original_material_overrides := {}
var _cutout_materials := {}
var _release_timers := {}

func _ready() -> void:
	process_priority = 100

func _process(delta: float) -> void:
	refresh(delta)

func refresh(delta: float = 0.0) -> void:
	if not enabled:
		_restore_all()
		return

	var camera := get_node_or_null(camera_path) as Camera3D
	var target := get_node_or_null(target_path) as Node3D
	if camera == null or target == null:
		_restore_all()
		return

	var current_meshes := _collect_current_occluder_meshes(camera, target)
	_apply_cutout_meshes(current_meshes, camera, target, delta)

func get_hidden_mesh_count() -> int:
	return _hidden_meshes.size()

func get_last_hit_names() -> PackedStringArray:
	var names := PackedStringArray()
	for body in _last_hit_bodies:
		if is_instance_valid(body):
			names.append(body.name)
	return names

func _collect_current_occluder_meshes(camera: Camera3D, target: Node3D) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	_last_hit_bodies.clear()

	var world := camera.get_world_3d()
	if world == null:
		return meshes

	var from := camera.global_position
	var exclude: Array[RID] = []
	var target_collision := target as CollisionObject3D
	if target_collision != null:
		exclude.append(target_collision.get_rid())

	for to in _get_target_probe_points(camera, target):
		_collect_occluder_meshes_along_line(world, from, to, exclude, meshes)
		if bidirectional_probe:
			_collect_occluder_meshes_along_line(world, to, from, exclude, meshes)
		_collect_line_hit_visual_meshes(from, to, meshes)
	return meshes

func _get_target_probe_points(camera: Camera3D, target: Node3D) -> Array[Vector3]:
	var center := target.global_position + Vector3.UP * target_height
	var points: Array[Vector3] = [center]
	var axis_u := camera.global_transform.basis.x.normalized()
	var axis_v := camera.global_transform.basis.y.normalized()
	if probe_horizontal_offset > 0.0:
		points.append(center + axis_u * probe_horizontal_offset)
		points.append(center - axis_u * probe_horizontal_offset)
	if probe_vertical_offset > 0.0:
		points.append(center + axis_v * probe_vertical_offset)
		points.append(center - axis_v * probe_vertical_offset)
	return points

func _collect_occluder_meshes_along_line(
	world: World3D,
	from: Vector3,
	to: Vector3,
	base_exclude: Array[RID],
	meshes: Array[MeshInstance3D]
) -> void:
	var exclude: Array[RID] = []
	for rid in base_exclude:
		exclude.append(rid)

	for _index in range(max_hits):
		var query := PhysicsRayQueryParameters3D.create(from, to)
		query.collide_with_areas = false
		query.collide_with_bodies = true
		query.exclude = exclude

		var hit := world.direct_space_state.intersect_ray(query)
		if hit.is_empty():
			break

		var collider := hit.get("collider") as Node
		if collider == null:
			break

		var collision_object := collider as CollisionObject3D
		if collision_object != null:
			exclude.append(collision_object.get_rid())

		if collider.is_in_group(occluder_group):
			if not _last_hit_bodies.has(collider):
				_last_hit_bodies.append(collider)
			_collect_meshes(collider, meshes)
			_collect_linked_visual_meshes(collider, meshes)

func _collect_meshes(node: Node, meshes: Array[MeshInstance3D]) -> void:
	var mesh := node as MeshInstance3D
	if mesh != null and not meshes.has(mesh):
		meshes.append(mesh)
	for child in node.get_children():
		_collect_meshes(child, meshes)

func _collect_linked_visual_meshes(occluder: Node, meshes: Array[MeshInstance3D]) -> void:
	var link_keys := _get_linked_visual_keys(occluder)
	if link_keys.is_empty():
		return

	for node in get_tree().get_nodes_in_group(linked_visual_group):
		var visual_mesh := node as MeshInstance3D
		if visual_mesh == null:
			continue
		if link_keys.has(String(visual_mesh.name)):
			_collect_meshes(visual_mesh, meshes)

func _get_linked_visual_keys(occluder: Node) -> PackedStringArray:
	var keys := PackedStringArray()
	var occluder_name := String(occluder.name)
	if occluder_name.begins_with("WallOpening_"):
		keys.append("DoorFrame_%s" % occluder_name.trim_prefix("WallOpening_"))
	return keys

func _collect_line_hit_visual_meshes(from: Vector3, to: Vector3, meshes: Array[MeshInstance3D]) -> void:
	for node in get_tree().get_nodes_in_group(linked_visual_group):
		var visual_mesh := node as MeshInstance3D
		if visual_mesh == null:
			continue
		if _line_hits_door_frame(visual_mesh, from, to):
			_collect_meshes(visual_mesh, meshes)

func _line_hits_door_frame(frame: MeshInstance3D, from: Vector3, to: Vector3) -> bool:
	var inverse_transform := frame.global_transform.affine_inverse()
	var local_from := inverse_transform * from
	var local_to := inverse_transform * to
	var span_axis := String(frame.get("span_axis"))
	var opening_width := float(frame.get("opening_width"))
	var outer_height := float(frame.get("outer_height"))
	var trim_width := float(frame.get("trim_width"))
	var frame_depth := float(frame.get("frame_depth"))
	if opening_width <= 0.0 or outer_height <= 0.0 or trim_width <= 0.0 or frame_depth <= 0.0:
		return false

	var outer_half := (opening_width + trim_width * 2.0) * 0.5
	var inner_half := opening_width * 0.5
	var inner_top: float = maxf(0.1, outer_height - trim_width)
	var half_depth := frame_depth * 0.5

	return (
		_line_hits_frame_box(local_from, local_to, span_axis, -outer_half, -inner_half, 0.0, outer_height, -half_depth, half_depth)
		or _line_hits_frame_box(local_from, local_to, span_axis, inner_half, outer_half, 0.0, outer_height, -half_depth, half_depth)
		or _line_hits_frame_box(local_from, local_to, span_axis, -outer_half, outer_half, inner_top, outer_height, -half_depth, half_depth)
	)

func _line_hits_frame_box(
	local_from: Vector3,
	local_to: Vector3,
	span_axis: String,
	min_span: float,
	max_span: float,
	min_y: float,
	max_y: float,
	min_depth: float,
	max_depth: float
) -> bool:
	var box: AABB
	if span_axis == "x":
		box = AABB(
			Vector3(min_span, min_y, min_depth),
			Vector3(max_span - min_span, max_y - min_y, max_depth - min_depth)
		)
	else:
		box = AABB(
			Vector3(min_depth, min_y, min_span),
			Vector3(max_depth - min_depth, max_y - min_y, max_span - min_span)
		)
	var intersection: Variant = box.intersects_segment(local_from, local_to)
	return intersection != null

func _apply_cutout_meshes(current_meshes: Array[MeshInstance3D], camera: Camera3D, target: Node3D, delta: float) -> void:
	var active_meshes: Array[MeshInstance3D] = []
	for mesh in current_meshes:
		if is_instance_valid(mesh):
			_release_timers[mesh] = cutout_release_delay
			_append_unique_mesh(active_meshes, mesh)

	for mesh in _hidden_meshes:
		if not is_instance_valid(mesh):
			_release_timers.erase(mesh)
			continue
		if current_meshes.has(mesh):
			continue

		var remaining := float(_release_timers.get(mesh, 0.0))
		if cutout_release_delay > 0.0:
			remaining -= maxf(delta, 0.0)

		if remaining > 0.0:
			_release_timers[mesh] = remaining
			_append_unique_mesh(active_meshes, mesh)
		else:
			_release_timers.erase(mesh)
			_restore_mesh_material(mesh)

	var center := target.global_position + Vector3.UP * target_height
	var axis_u := camera.global_transform.basis.x.normalized()
	var axis_v := camera.global_transform.basis.y.normalized()
	for mesh in active_meshes:
		if is_instance_valid(mesh):
			_apply_cutout_material(mesh, center, axis_u, axis_v)

	_hidden_meshes = active_meshes

func _append_unique_mesh(meshes: Array[MeshInstance3D], mesh: MeshInstance3D) -> void:
	if not meshes.has(mesh):
		meshes.append(mesh)

func _apply_cutout_material(mesh: MeshInstance3D, center: Vector3, axis_u: Vector3, axis_v: Vector3) -> void:
	if not _original_material_overrides.has(mesh):
		_original_material_overrides[mesh] = mesh.material_override

	var material := _cutout_materials.get(mesh) as ShaderMaterial
	if material == null:
		material = _create_cutout_material(mesh)
		_cutout_materials[mesh] = material

	mesh.visible = true
	mesh.material_override = material
	material.set_shader_parameter("cutout_center_world", center)
	material.set_shader_parameter("cutout_axis_u_world", axis_u)
	material.set_shader_parameter("cutout_axis_v_world", axis_v)
	material.set_shader_parameter("cutout_radius_u", cutout_radius_u)
	material.set_shader_parameter("cutout_radius_v", cutout_radius_v)
	material.set_shader_parameter("cutout_feather", cutout_feather)
	material.set_shader_parameter("cutout_strength", 1.0)

func _create_cutout_material(mesh: MeshInstance3D) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = CutoutShader

	var source := _get_source_material(mesh)
	var standard := source as StandardMaterial3D
	if standard != null:
		_configure_from_standard_material(material, standard)
	else:
		var shader_material := source as ShaderMaterial
		if shader_material != null:
			_configure_from_shader_material(material, shader_material)
	return material

func _configure_from_standard_material(material: ShaderMaterial, standard: StandardMaterial3D) -> void:
	material.set_shader_parameter("albedo_color", standard.albedo_color)
	material.set_shader_parameter("roughness_value", standard.roughness)
	material.set_shader_parameter("normal_strength", standard.normal_scale)
	material.set_shader_parameter("uv_scale", Vector2(standard.uv1_scale.x, standard.uv1_scale.y))
	material.set_shader_parameter("uv_offset", Vector2(standard.uv1_offset.x, standard.uv1_offset.y))
	if standard.albedo_texture != null:
		material.set_shader_parameter("albedo_texture", standard.albedo_texture)
		material.set_shader_parameter("use_albedo_texture", true)
	if standard.normal_enabled and standard.normal_texture != null:
		material.set_shader_parameter("normal_texture", standard.normal_texture)
		material.set_shader_parameter("use_normal_texture", true)

func _configure_from_shader_material(material: ShaderMaterial, shader_material: ShaderMaterial) -> void:
	var tint: Variant = shader_material.get_shader_parameter("albedo_tint")
	if tint is Color:
		material.set_shader_parameter("albedo_color", tint)
	elif typeof(tint) == TYPE_VECTOR4:
		var tint_vector := tint as Vector4
		material.set_shader_parameter("albedo_color", Color(tint_vector.x, tint_vector.y, tint_vector.z, tint_vector.w))

	var roughness: Variant = shader_material.get_shader_parameter("roughness_value")
	if typeof(roughness) == TYPE_FLOAT or typeof(roughness) == TYPE_INT:
		material.set_shader_parameter("roughness_value", float(roughness))

	var normal_depth: Variant = shader_material.get_shader_parameter("normal_depth")
	if typeof(normal_depth) == TYPE_FLOAT or typeof(normal_depth) == TYPE_INT:
		material.set_shader_parameter("normal_strength", float(normal_depth))

	var uv_scale_value: Variant = shader_material.get_shader_parameter("uv_scale")
	if typeof(uv_scale_value) == TYPE_VECTOR2:
		material.set_shader_parameter("uv_scale", uv_scale_value)

	var uv_offset_value: Variant = shader_material.get_shader_parameter("uv_offset")
	if typeof(uv_offset_value) == TYPE_VECTOR2:
		material.set_shader_parameter("uv_offset", uv_offset_value)

	var use_texture: Variant = shader_material.get_shader_parameter("use_texture")
	var albedo_texture: Variant = shader_material.get_shader_parameter("albedo_texture")
	if use_texture == true and albedo_texture is Texture2D:
		material.set_shader_parameter("albedo_texture", albedo_texture)
		material.set_shader_parameter("use_albedo_texture", true)

	var use_normal: Variant = shader_material.get_shader_parameter("use_normal")
	var normal_texture: Variant = shader_material.get_shader_parameter("normal_texture")
	if use_normal == true and normal_texture is Texture2D:
		material.set_shader_parameter("normal_texture", normal_texture)
		material.set_shader_parameter("use_normal_texture", true)

func _get_source_material(mesh: MeshInstance3D) -> Material:
	if mesh.material_override != null:
		return mesh.material_override
	if mesh.mesh != null and mesh.mesh.get_surface_count() > 0:
		return mesh.mesh.surface_get_material(0)
	return null

func _restore_mesh_material(mesh: MeshInstance3D) -> void:
	if not _original_material_overrides.has(mesh):
		return
	mesh.material_override = _original_material_overrides[mesh]
	mesh.visible = true
	_original_material_overrides.erase(mesh)
	_cutout_materials.erase(mesh)
	_release_timers.erase(mesh)

func _restore_all() -> void:
	for mesh in _hidden_meshes:
		if is_instance_valid(mesh):
			_restore_mesh_material(mesh)
	_hidden_meshes.clear()
	_last_hit_bodies.clear()
	_release_timers.clear()
