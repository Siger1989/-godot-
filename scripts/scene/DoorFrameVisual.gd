@tool
extends MeshInstance3D

const DoorFrameMaterial = preload("res://materials/backrooms_door_frame.tres")
const GeneratedMeshRules = preload("res://scripts/scene/GeneratedMeshRules.gd")
const FRAME_FLOOR_OVERLAP := 0.02

@export var frame_id := ""
@export_enum("z", "x") var span_axis := "z":
	set(value):
		span_axis = value
		_apply_axis_rotation()
		_rebuild_mesh()
@export var opening_width := 1.1:
	set(value):
		opening_width = value
		_rebuild_mesh()
@export var outer_height := 2.18:
	set(value):
		outer_height = value
		_rebuild_mesh()
@export var trim_width := 0.16:
	set(value):
		trim_width = value
		_rebuild_mesh()
@export var frame_depth := 0.18:
	set(value):
		frame_depth = value
		_rebuild_mesh()
@export var visual_material: Material:
	set(value):
		visual_material = value
		_rebuild_mesh()

func _ready() -> void:
	_apply_axis_rotation()
	add_to_group("door_frame", true)
	_rebuild_mesh()

func _rebuild_mesh() -> void:
	if opening_width <= 0.0 or outer_height <= 0.0 or trim_width <= 0.0 or frame_depth <= 0.0:
		return

	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var profile := _get_u_profile()
	var triangle_indices: PackedInt32Array = Geometry2D.triangulate_polygon(profile)
	if triangle_indices.size() < 3:
		return

	var half_depth := frame_depth * 0.5
	_add_profile_face(vertices, normals, uvs, profile, triangle_indices, half_depth, _positive_depth_normal(), false)
	_add_profile_face(vertices, normals, uvs, profile, triangle_indices, -half_depth, _negative_depth_normal(), true)
	_add_profile_sides(vertices, normals, uvs, profile, half_depth)

	var material := _get_visual_material()
	material_override = material
	mesh = GeneratedMeshRules.build_array_mesh(vertices, normals, uvs, material)

func _get_visual_material() -> Material:
	if visual_material != null:
		return visual_material
	return DoorFrameMaterial

func _get_u_profile() -> PackedVector2Array:
	var outer_width := opening_width + trim_width * 2.0
	var outer_half := outer_width * 0.5
	var inner_half := opening_width * 0.5
	var inner_top: float = maxf(0.1, outer_height - trim_width)
	var visual_bottom := -FRAME_FLOOR_OVERLAP

	return PackedVector2Array([
		Vector2(-outer_half, visual_bottom),
		Vector2(-inner_half, visual_bottom),
		Vector2(-inner_half, inner_top),
		Vector2(inner_half, inner_top),
		Vector2(inner_half, visual_bottom),
		Vector2(outer_half, visual_bottom),
		Vector2(outer_half, outer_height),
		Vector2(-outer_half, outer_height),
	])

func _add_profile_face(
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	uvs: PackedVector2Array,
	profile: PackedVector2Array,
	triangle_indices: PackedInt32Array,
	depth_offset: float,
	normal: Vector3,
	reverse_order: bool
) -> void:
	for i in range(0, triangle_indices.size(), 3):
		var a := _profile_to_3d(profile[triangle_indices[i]], depth_offset)
		var b := _profile_to_3d(profile[triangle_indices[i + 1]], depth_offset)
		var c := _profile_to_3d(profile[triangle_indices[i + 2]], depth_offset)
		if reverse_order:
			_add_triangle(vertices, normals, uvs, a, c, b, normal, _vertex_to_uv(a, normal), _vertex_to_uv(c, normal), _vertex_to_uv(b, normal))
		else:
			_add_triangle(vertices, normals, uvs, a, b, c, normal, _vertex_to_uv(a, normal), _vertex_to_uv(b, normal), _vertex_to_uv(c, normal))

func _add_profile_sides(vertices: PackedVector3Array, normals: PackedVector3Array, uvs: PackedVector2Array, profile: PackedVector2Array, half_depth: float) -> void:
	var is_clockwise := _is_clockwise(profile)
	for i in range(profile.size()):
		var next_index := (i + 1) % profile.size()
		var p0 := profile[i]
		var p1 := profile[next_index]
		if _is_floor_cap_edge(p0, p1):
			continue
		var edge_normal := _edge_outward_normal(p0, p1, is_clockwise)
		var normal := _profile_normal_to_3d(edge_normal)
		_add_quad(
			vertices,
			normals,
			uvs,
			_profile_to_3d(p0, -half_depth),
			_profile_to_3d(p1, -half_depth),
			_profile_to_3d(p1, half_depth),
			_profile_to_3d(p0, half_depth),
			normal,
			_vertex_to_uv(_profile_to_3d(p0, -half_depth), normal),
			_vertex_to_uv(_profile_to_3d(p1, -half_depth), normal),
			_vertex_to_uv(_profile_to_3d(p1, half_depth), normal),
			_vertex_to_uv(_profile_to_3d(p0, half_depth), normal)
		)

func _profile_to_3d(point: Vector2, depth_offset: float) -> Vector3:
	if span_axis == "z":
		return Vector3(depth_offset, point.y, point.x)
	return Vector3(point.x, point.y, depth_offset)

func _profile_normal_to_3d(normal: Vector2) -> Vector3:
	if span_axis == "z":
		return Vector3(0.0, normal.y, normal.x)
	return Vector3(normal.x, normal.y, 0.0)

func _is_floor_cap_edge(a: Vector2, b: Vector2) -> bool:
	var visual_bottom := -FRAME_FLOOR_OVERLAP
	return absf(a.y - visual_bottom) <= 0.0001 and absf(b.y - visual_bottom) <= 0.0001

func _vertex_to_uv(vertex: Vector3, normal: Vector3) -> Vector2:
	var outer_width := opening_width + trim_width * 2.0
	var normalized_normal := normal.normalized()
	if absf(normalized_normal.y) < 0.25:
		var u_direction := Vector3.UP.cross(normalized_normal).normalized()
		if u_direction.length_squared() <= 0.000001:
			u_direction = Vector3.RIGHT
		return Vector2(vertex.dot(u_direction) / maxf(outer_width, 0.01) + 0.5, vertex.y / maxf(outer_height, 0.01))
	return Vector2(vertex.x / maxf(outer_width, 0.01) + 0.5, vertex.z / maxf(frame_depth, 0.01) + 0.5)

func _positive_depth_normal() -> Vector3:
	if span_axis == "z":
		return Vector3.RIGHT
	return Vector3.BACK

func _negative_depth_normal() -> Vector3:
	if span_axis == "z":
		return Vector3.LEFT
	return Vector3.FORWARD

func _apply_axis_rotation() -> void:
	rotation = Vector3.ZERO

func _is_clockwise(points: PackedVector2Array) -> bool:
	var signed_area := 0.0
	for i in range(points.size()):
		var next_index := (i + 1) % points.size()
		signed_area += points[i].x * points[next_index].y - points[next_index].x * points[i].y
	return signed_area < 0.0

func _edge_outward_normal(a: Vector2, b: Vector2, is_clockwise: bool) -> Vector2:
	var edge := b - a
	if edge.length_squared() <= 0.000001:
		return Vector2.UP
	if is_clockwise:
		return Vector2(-edge.y, edge.x).normalized()
	return Vector2(edge.y, -edge.x).normalized()

func _add_triangle(vertices: PackedVector3Array, normals: PackedVector3Array, uvs: PackedVector2Array, a: Vector3, b: Vector3, c: Vector3, normal: Vector3, uv_a: Vector2, uv_b: Vector2, uv_c: Vector2) -> void:
	GeneratedMeshRules.append_oriented_triangle(vertices, normals, uvs, a, b, c, normal, uv_a, uv_b, uv_c)

func _add_quad(vertices: PackedVector3Array, normals: PackedVector3Array, uvs: PackedVector2Array, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3, uv_a: Vector2, uv_b: Vector2, uv_c: Vector2, uv_d: Vector2) -> void:
	_add_triangle(vertices, normals, uvs, a, b, c, normal, uv_a, uv_b, uv_c)
	_add_triangle(vertices, normals, uvs, a, c, d, normal, uv_a, uv_c, uv_d)
