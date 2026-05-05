extends RefCounted

const EPSILON := 0.000001

static func build_box_mesh(
	size: Vector3,
	material: Material,
	uv_world_size := 6.0,
	include_top := true,
	include_bottom := true,
	vertical_uv_v_offset := 0.0,
	use_vertical_world_uv := false,
	vertical_uv_world_origin := Vector3.ZERO,
	vertical_uv_height := 0.0
) -> ArrayMesh:
	var half := size * 0.5
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var safe_uv_world_size: float = maxf(uv_world_size, EPSILON)
	var safe_vertical_uv_height: float = maxf(vertical_uv_height, EPSILON)

	_append_box_quad(vertices, normals, uvs,
		Vector3(-half.x, -half.y, half.z),
		Vector3(half.x, -half.y, half.z),
		Vector3(half.x, half.y, half.z),
		Vector3(-half.x, half.y, half.z),
		Vector3.BACK, 0, 1, 1.0, -1.0 if use_vertical_world_uv else 1.0, safe_uv_world_size,
		vertical_uv_world_origin.x if use_vertical_world_uv else 0.0,
		(safe_vertical_uv_height - vertical_uv_world_origin.y) if use_vertical_world_uv else vertical_uv_v_offset,
		safe_vertical_uv_height if use_vertical_world_uv else safe_uv_world_size)
	_append_box_quad(vertices, normals, uvs,
		Vector3(half.x, -half.y, -half.z),
		Vector3(-half.x, -half.y, -half.z),
		Vector3(-half.x, half.y, -half.z),
		Vector3(half.x, half.y, -half.z),
		Vector3.FORWARD, 0, 1, -1.0, -1.0 if use_vertical_world_uv else 1.0, safe_uv_world_size,
		-vertical_uv_world_origin.x if use_vertical_world_uv else 0.0,
		(safe_vertical_uv_height - vertical_uv_world_origin.y) if use_vertical_world_uv else vertical_uv_v_offset,
		safe_vertical_uv_height if use_vertical_world_uv else safe_uv_world_size)
	_append_box_quad(vertices, normals, uvs,
		Vector3(half.x, -half.y, half.z),
		Vector3(half.x, -half.y, -half.z),
		Vector3(half.x, half.y, -half.z),
		Vector3(half.x, half.y, half.z),
		Vector3.RIGHT, 2, 1, -1.0, -1.0 if use_vertical_world_uv else 1.0, safe_uv_world_size,
		-vertical_uv_world_origin.z if use_vertical_world_uv else 0.0,
		(safe_vertical_uv_height - vertical_uv_world_origin.y) if use_vertical_world_uv else vertical_uv_v_offset,
		safe_vertical_uv_height if use_vertical_world_uv else safe_uv_world_size)
	_append_box_quad(vertices, normals, uvs,
		Vector3(-half.x, -half.y, -half.z),
		Vector3(-half.x, -half.y, half.z),
		Vector3(-half.x, half.y, half.z),
		Vector3(-half.x, half.y, -half.z),
		Vector3.LEFT, 2, 1, 1.0, -1.0 if use_vertical_world_uv else 1.0, safe_uv_world_size,
		vertical_uv_world_origin.z if use_vertical_world_uv else 0.0,
		(safe_vertical_uv_height - vertical_uv_world_origin.y) if use_vertical_world_uv else vertical_uv_v_offset,
		safe_vertical_uv_height if use_vertical_world_uv else safe_uv_world_size)
	if include_top:
		_append_box_quad(vertices, normals, uvs,
			Vector3(-half.x, half.y, half.z),
			Vector3(half.x, half.y, half.z),
			Vector3(half.x, half.y, -half.z),
			Vector3(-half.x, half.y, -half.z),
			Vector3.UP, 0, 2, 1.0, -1.0, safe_uv_world_size)
	if include_bottom:
		_append_box_quad(vertices, normals, uvs,
			Vector3(-half.x, -half.y, -half.z),
			Vector3(half.x, -half.y, -half.z),
			Vector3(half.x, -half.y, half.z),
			Vector3(-half.x, -half.y, half.z),
			Vector3.DOWN, 0, 2, 1.0, 1.0, safe_uv_world_size)

	return build_array_mesh(vertices, normals, uvs, material)

static func build_array_mesh(
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	uvs: PackedVector2Array,
	material: Material
) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_TANGENT] = build_tangents(vertices, normals, uvs)

	var array_mesh := ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	if material != null:
		array_mesh.surface_set_material(0, material)
	return array_mesh

static func append_oriented_triangle(
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	uvs: PackedVector2Array,
	a: Vector3,
	b: Vector3,
	c: Vector3,
	normal: Vector3,
	uv_a: Vector2,
	uv_b: Vector2,
	uv_c: Vector2
) -> void:
	var normalized_normal := normal.normalized()
	var geometric_normal := (b - a).cross(c - a)
	if geometric_normal.length_squared() <= EPSILON or normalized_normal.length_squared() <= EPSILON:
		_append_raw_triangle(vertices, normals, uvs, a, b, c, normal, uv_a, uv_b, uv_c)
		return

	# Godot treats clockwise vertex order as the visible front side for ArrayMesh
	# triangles. If the geometric normal points with the supplied outward normal,
	# reverse the order so the outward side is the rendered front face while the
	# explicit normal/UV data remains outward-facing.
	if geometric_normal.dot(normalized_normal) > 0.0:
		_append_raw_triangle(vertices, normals, uvs, a, c, b, normal, uv_a, uv_c, uv_b)
	else:
		_append_raw_triangle(vertices, normals, uvs, a, b, c, normal, uv_a, uv_b, uv_c)

static func build_tangents(
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	uvs: PackedVector2Array
) -> PackedFloat32Array:
	var tangents := PackedFloat32Array()
	if vertices.size() != normals.size() or vertices.size() != uvs.size():
		return tangents

	for i in range(0, vertices.size(), 3):
		if i + 2 >= vertices.size():
			break

		var p0 := vertices[i]
		var p1 := vertices[i + 1]
		var p2 := vertices[i + 2]
		var uv0 := uvs[i]
		var uv1 := uvs[i + 1]
		var uv2 := uvs[i + 2]

		var edge1 := p1 - p0
		var edge2 := p2 - p0
		var delta_uv1 := uv1 - uv0
		var delta_uv2 := uv2 - uv0
		var denominator := delta_uv1.x * delta_uv2.y - delta_uv2.x * delta_uv1.y

		var tangent := Vector3.ZERO
		var bitangent := Vector3.ZERO
		if absf(denominator) > EPSILON:
			var factor := 1.0 / denominator
			tangent = (edge1 * delta_uv2.y - edge2 * delta_uv1.y) * factor
			bitangent = (edge2 * delta_uv1.x - edge1 * delta_uv2.x) * factor

		for vertex_index in [i, i + 1, i + 2]:
			var normal := normals[vertex_index].normalized()
			if absf(normal.y) < 0.25:
				var wall_tangent := Vector3.UP.cross(normal).normalized()
				if wall_tangent.length_squared() <= EPSILON:
					wall_tangent = _fallback_tangent(normal)
				tangents.append(wall_tangent.x)
				tangents.append(wall_tangent.y)
				tangents.append(wall_tangent.z)
				tangents.append(1.0)
				continue

			var final_tangent := tangent - normal * normal.dot(tangent)
			if final_tangent.length_squared() <= EPSILON:
				final_tangent = _fallback_tangent(normal)
			else:
				final_tangent = final_tangent.normalized()

			var sign := 1.0
			if bitangent.length_squared() > EPSILON and normal.cross(final_tangent).dot(bitangent) < 0.0:
				sign = -1.0

			tangents.append(final_tangent.x)
			tangents.append(final_tangent.y)
			tangents.append(final_tangent.z)
			tangents.append(sign)

	return tangents

static func _append_box_quad(
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	uvs: PackedVector2Array,
	a: Vector3,
	b: Vector3,
	c: Vector3,
	d: Vector3,
	normal: Vector3,
	axis_u: int,
	axis_v: int,
	sign_u: float,
	sign_v: float,
	uv_world_size: float,
	u_offset := 0.0,
	v_offset := 0.0,
	v_world_size := -1.0
) -> void:
	var safe_v_world_size := uv_world_size if v_world_size <= 0.0 else v_world_size
	var uv_a := _box_point_uv(a, axis_u, axis_v, sign_u, sign_v, uv_world_size, u_offset, v_offset, safe_v_world_size)
	var uv_b := _box_point_uv(b, axis_u, axis_v, sign_u, sign_v, uv_world_size, u_offset, v_offset, safe_v_world_size)
	var uv_c := _box_point_uv(c, axis_u, axis_v, sign_u, sign_v, uv_world_size, u_offset, v_offset, safe_v_world_size)
	var uv_d := _box_point_uv(d, axis_u, axis_v, sign_u, sign_v, uv_world_size, u_offset, v_offset, safe_v_world_size)
	append_oriented_triangle(vertices, normals, uvs, a, b, c, normal, uv_a, uv_b, uv_c)
	append_oriented_triangle(vertices, normals, uvs, a, c, d, normal, uv_a, uv_c, uv_d)

static func _append_raw_triangle(
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	uvs: PackedVector2Array,
	a: Vector3,
	b: Vector3,
	c: Vector3,
	normal: Vector3,
	uv_a: Vector2,
	uv_b: Vector2,
	uv_c: Vector2
) -> void:
	vertices.append_array(PackedVector3Array([a, b, c]))
	normals.append_array(PackedVector3Array([normal, normal, normal]))
	uvs.append_array(PackedVector2Array([uv_a, uv_b, uv_c]))

static func _box_point_uv(
	point: Vector3,
	axis_u: int,
	axis_v: int,
	sign_u: float,
	sign_v: float,
	uv_world_size: float,
	u_offset := 0.0,
	v_offset := 0.0,
	v_world_size := -1.0
) -> Vector2:
	var safe_v_world_size := uv_world_size if v_world_size <= 0.0 else v_world_size
	return Vector2(
		(_axis_value(point, axis_u) * sign_u + u_offset) / uv_world_size,
		(_axis_value(point, axis_v) * sign_v + v_offset) / safe_v_world_size
	)

static func _axis_value(point: Vector3, axis: int) -> float:
	if axis == 0:
		return point.x
	if axis == 1:
		return point.y
	return point.z

static func _fallback_tangent(normal: Vector3) -> Vector3:
	var reference := Vector3.UP
	if absf(normal.normalized().dot(reference)) > 0.85:
		reference = Vector3.RIGHT
	var tangent := reference.cross(normal).normalized()
	if tangent.length_squared() <= EPSILON:
		return Vector3.RIGHT
	return tangent
