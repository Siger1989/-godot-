@tool
extends "res://scripts/scene/WallModule.gd"

const WallMaterial = preload("res://materials/backrooms_wall.tres")
const GeneratedMeshRules = preload("res://scripts/scene/GeneratedMeshRules.gd")
const WALL_UV_WORLD_SIZE := 6.0
const VISUAL_VERTICAL_OVERLAP := 0.08

@export var opening_id := ""
@export_enum("z", "x") var span_axis := "z":
	set(value):
		span_axis = value
		_apply_axis_rotation()
		_rebuild_when_ready()
@export var span_length := 5.64:
	set(value):
		span_length = value
		_rebuild_when_ready()
@export var opening_width := 1.1:
	set(value):
		opening_width = value
		_rebuild_when_ready()
@export var opening_height := 2.16:
	set(value):
		opening_height = value
		_rebuild_when_ready()
@export var wall_height := 2.55:
	set(value):
		wall_height = value
		_rebuild_when_ready()
@export var wall_thickness := 0.2:
	set(value):
		wall_thickness = value
		_rebuild_when_ready()
@export var visual_material: Material:
	set(value):
		visual_material = value
		_rebuild_when_ready()
@export var visual_layers := 1:
	set(value):
		visual_layers = value
		var mesh_instance := get_node_or_null("Mesh") as MeshInstance3D
		if mesh_instance != null:
			mesh_instance.layers = visual_layers

func _ready() -> void:
	_apply_axis_rotation()
	is_foreground_occluder = true
	add_to_group("foreground_occluder")
	_rebuild_body()

func _rebuild_when_ready() -> void:
	if is_inside_tree():
		_rebuild_body()

func _rebuild_body() -> void:
	if span_length <= 0.0 or opening_width <= 0.0 or opening_height <= 0.0 or wall_height <= 0.0 or wall_thickness <= 0.0:
		return

	var mesh_instance := _get_or_create_mesh()
	mesh_instance.mesh = _build_visual_mesh()

	_configure_collision("Collision_Left", _side_collision_center(-1.0), _side_collision_size())
	_configure_collision("Collision_Right", _side_collision_center(1.0), _side_collision_size())
	_configure_collision("Collision_Top", _top_collision_center(), _top_collision_size())

func _get_or_create_mesh() -> MeshInstance3D:
	var mesh_instance := get_node_or_null("Mesh") as MeshInstance3D
	if mesh_instance == null:
		mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "Mesh"
		add_child(mesh_instance)
	mesh_instance.material_override = _get_visual_material()
	mesh_instance.layers = visual_layers
	_assign_scene_owner(mesh_instance)
	return mesh_instance

func _configure_collision(node_name: String, local_position: Vector3, size: Vector3) -> void:
	var collision := get_node_or_null(node_name) as CollisionShape3D
	if collision == null:
		collision = CollisionShape3D.new()
		collision.name = node_name
		add_child(collision)
	_assign_scene_owner(collision)
	var box := collision.shape as BoxShape3D
	if box == null:
		box = BoxShape3D.new()
		collision.shape = box
	box.size = size
	collision.position = local_position

func _assign_scene_owner(node: Node) -> void:
	if not Engine.is_editor_hint():
		return
	var edited_root := get_tree().edited_scene_root
	if edited_root != null:
		node.owner = edited_root

func _build_visual_mesh() -> ArrayMesh:
	var profile := _get_u_profile()
	var triangle_indices: PackedInt32Array = Geometry2D.triangulate_polygon(profile)
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var half_thickness := wall_thickness * 0.5

	if triangle_indices.size() >= 3:
		_add_profile_face(vertices, normals, uvs, profile, triangle_indices, half_thickness, _positive_depth_normal(), false)
		_add_profile_face(vertices, normals, uvs, profile, triangle_indices, -half_thickness, _negative_depth_normal(), true)
		_add_profile_sides(vertices, normals, uvs, profile, half_thickness)

	return GeneratedMeshRules.build_array_mesh(vertices, normals, uvs, _get_visual_material())

func _get_visual_material() -> Material:
	if visual_material != null:
		return visual_material
	return WallMaterial

func _get_u_profile() -> PackedVector2Array:
	var outer_half := span_length * 0.5
	var inner_half := opening_width * 0.5
	var inner_top: float = clampf(opening_height, 0.1, wall_height - 0.05)
	var visual_bottom := -VISUAL_VERTICAL_OVERLAP
	var visual_top := wall_height + VISUAL_VERTICAL_OVERLAP

	return PackedVector2Array([
		Vector2(-outer_half, visual_bottom),
		Vector2(-inner_half, visual_bottom),
		Vector2(-inner_half, inner_top),
		Vector2(inner_half, inner_top),
		Vector2(inner_half, visual_bottom),
		Vector2(outer_half, visual_bottom),
		Vector2(outer_half, visual_top),
		Vector2(-outer_half, visual_top),
	])

func _side_collision_size() -> Vector3:
	var side_length := maxf(0.05, (span_length - opening_width) * 0.5)
	if span_axis == "z":
		return Vector3(wall_thickness, wall_height, side_length)
	return Vector3(side_length, wall_height, wall_thickness)

func _side_collision_center(direction: float) -> Vector3:
	var side_length := maxf(0.05, (span_length - opening_width) * 0.5)
	var offset := direction * (opening_width * 0.5 + side_length * 0.5)
	if span_axis == "z":
		return Vector3(0.0, wall_height * 0.5, offset)
	return Vector3(offset, wall_height * 0.5, 0.0)

func _top_collision_size() -> Vector3:
	var header_height: float = maxf(0.05, wall_height - opening_height)
	if span_axis == "z":
		return Vector3(wall_thickness, header_height, opening_width)
	return Vector3(opening_width, header_height, wall_thickness)

func _top_collision_center() -> Vector3:
	var header_height: float = maxf(0.05, wall_height - opening_height)
	return Vector3(0.0, opening_height + header_height * 0.5, 0.0)

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

func _add_profile_sides(vertices: PackedVector3Array, normals: PackedVector3Array, uvs: PackedVector2Array, profile: PackedVector2Array, half_thickness: float) -> void:
	var is_clockwise := _is_clockwise(profile)
	for i in range(profile.size()):
		var next_index := (i + 1) % profile.size()
		var p0 := profile[i]
		var p1 := profile[next_index]
		if _is_floor_or_ceiling_cap_edge(p0, p1):
			continue
		var edge_normal := _edge_outward_normal(p0, p1, is_clockwise)
		var normal := _profile_normal_to_3d(edge_normal)
		_add_quad(
			vertices,
			normals,
			uvs,
			_profile_to_3d(p0, -half_thickness),
			_profile_to_3d(p1, -half_thickness),
			_profile_to_3d(p1, half_thickness),
			_profile_to_3d(p0, half_thickness),
			normal,
			_vertex_to_uv(_profile_to_3d(p0, -half_thickness), normal),
			_vertex_to_uv(_profile_to_3d(p1, -half_thickness), normal),
			_vertex_to_uv(_profile_to_3d(p1, half_thickness), normal),
			_vertex_to_uv(_profile_to_3d(p0, half_thickness), normal)
		)

func _profile_to_3d(point: Vector2, depth_offset: float) -> Vector3:
	if span_axis == "z":
		return Vector3(depth_offset, point.y, point.x)
	return Vector3(point.x, point.y, depth_offset)

func _profile_normal_to_3d(normal: Vector2) -> Vector3:
	if span_axis == "z":
		return Vector3(0.0, normal.y, normal.x)
	return Vector3(normal.x, normal.y, 0.0)

func _is_floor_or_ceiling_cap_edge(a: Vector2, b: Vector2) -> bool:
	var visual_bottom := -VISUAL_VERTICAL_OVERLAP
	var visual_top := wall_height + VISUAL_VERTICAL_OVERLAP
	if absf(a.y - visual_bottom) <= 0.0001 and absf(b.y - visual_bottom) <= 0.0001:
		return true
	if absf(a.y - visual_top) <= 0.0001 and absf(b.y - visual_top) <= 0.0001:
		return true
	return false

func _vertex_to_uv(vertex: Vector3, normal: Vector3) -> Vector2:
	var normalized_normal := normal.normalized()
	if absf(normalized_normal.y) < 0.25:
		var u_direction := Vector3.UP.cross(normalized_normal).normalized()
		if u_direction.length_squared() <= 0.000001:
			u_direction = Vector3.RIGHT
		var vertical_v := (wall_height - vertex.y) / maxf(wall_height, 0.000001)
		return Vector2(vertex.dot(u_direction) / WALL_UV_WORLD_SIZE, vertical_v)
	return Vector2(vertex.x / WALL_UV_WORLD_SIZE, vertex.z / WALL_UV_WORLD_SIZE)

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
