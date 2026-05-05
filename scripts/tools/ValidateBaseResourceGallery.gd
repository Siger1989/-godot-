extends SceneTree

const SCENE_PATH := "res://scenes/debug/BaseResourceGallery.tscn"
const REQUIRED_DEBUG_NODES := [
	"UV_Debug_Row/Wall_Visible_PosZ",
	"UV_Debug_Row/Wall_Visible_NegZ",
	"UV_Debug_Row/Wall_Visible_PosX",
	"UV_Debug_Row/Wall_Visible_NegX",
	"UV_Debug_Row/WallJoint_Box",
	"UV_Debug_Row/WallOpening_Local_Z",
	"UV_Debug_Row/WallOpening_Rotated_X",
	"UV_Debug_Row/DoorFrame_Z",
	"UV_Debug_Row/DoorFrame_X",
	"UV_Debug_Row/Floor_Panel",
	"UV_Debug_Row/Ceiling_Panel",
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		_fail("Failed to load %s." % SCENE_PATH)
		return
	var scene := packed.instantiate() as Node3D
	if scene == null:
		_fail("Failed to instantiate %s." % SCENE_PATH)
		return
	root.add_child(scene)
	current_scene = scene
	await process_frame

	for node_path in REQUIRED_DEBUG_NODES:
		var node := scene.get_node_or_null(node_path)
		if node == null:
			_fail("Missing gallery node: %s." % node_path)
			return
		if not _has_mesh(node):
			_fail("Gallery node has no mesh: %s." % node_path)
			return
		if node_path.begins_with("UV_Debug_Row/") and not _uses_debug_material(node):
			_fail("Debug gallery node is not using the UV debug material: %s." % node_path)
			return
		var mesh_error := _validate_mesh_tree(node)
		if not mesh_error.is_empty():
			_fail("%s: %s" % [node_path, mesh_error])
			return

	print("BASE_RESOURCE_GALLERY_VALIDATION PASS")
	quit(0)

func _has_mesh(node: Node) -> bool:
	var mesh_instance := node as MeshInstance3D
	if mesh_instance != null and mesh_instance.mesh != null:
		return true
	for child in node.get_children():
		if _has_mesh(child):
			return true
	return false

func _uses_debug_material(node: Node) -> bool:
	var mesh_instance := node as MeshInstance3D
	if mesh_instance != null:
		if mesh_instance.material_override == load("res://materials/debug/uv_direction_debug.tres"):
			return true
		var mesh := mesh_instance.mesh
		if mesh != null:
			for surface_index in range(mesh.get_surface_count()):
				if mesh.surface_get_material(surface_index) == load("res://materials/debug/uv_direction_debug.tres"):
					return true
	for child in node.get_children():
		if _uses_debug_material(child):
			return true
	return false

func _validate_mesh_tree(node: Node) -> String:
	var mesh_instance := node as MeshInstance3D
	if mesh_instance != null and mesh_instance.mesh != null:
		var mesh_error := _validate_mesh(mesh_instance)
		if not mesh_error.is_empty():
			return "%s %s" % [mesh_instance.get_path(), mesh_error]
	for child in node.get_children():
		var child_error := _validate_mesh_tree(child)
		if not child_error.is_empty():
			return child_error
	return ""

func _validate_mesh(mesh_instance: MeshInstance3D) -> String:
	var mesh := mesh_instance.mesh
	for surface_index in range(mesh.get_surface_count()):
		var arrays := mesh.surface_get_arrays(surface_index)
		var vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
		var normals := arrays[Mesh.ARRAY_NORMAL] as PackedVector3Array
		var uvs := arrays[Mesh.ARRAY_TEX_UV] as PackedVector2Array
		if vertices.size() == 0:
			return "surface %d has no vertices." % surface_index
		if normals.size() != vertices.size():
			return "surface %d normals are missing or mismatched." % surface_index
		if uvs.size() != vertices.size():
			return "surface %d UVs are missing or mismatched." % surface_index
		if vertices.size() % 3 != 0:
			return "surface %d vertex count is not triangles." % surface_index

		for i in range(0, vertices.size(), 3):
			var error := _validate_triangle(vertices, normals, uvs, i)
			if not error.is_empty():
				return "surface %d triangle %d %s" % [surface_index, i / 3, error]
	return ""

func _validate_triangle(vertices: PackedVector3Array, normals: PackedVector3Array, uvs: PackedVector2Array, index: int) -> String:
	var a := vertices[index]
	var b := vertices[index + 1]
	var c := vertices[index + 2]
	var normal := (normals[index] + normals[index + 1] + normals[index + 2]).normalized()
	if normal.length_squared() <= 0.000001:
		return "has invalid normal."

	var geometric_normal := (b - a).cross(c - a)
	if geometric_normal.length_squared() <= 0.000001:
		return "is degenerate."

	if geometric_normal.normalized().dot(normal) >= -0.65:
		return "has reversed winding for Godot clockwise front-face culling."

	if absf(normal.y) < 0.25:
		var u_direction := Vector3.UP.cross(normal).normalized()
		if u_direction.length_squared() <= 0.000001:
			return "has invalid vertical U direction."
		var uv_error := _validate_vertical_uv_axis(a, b, c, uvs[index], uvs[index + 1], uvs[index + 2], u_direction)
		if not uv_error.is_empty():
			return uv_error

	return ""

func _validate_vertical_uv_axis(a: Vector3, b: Vector3, c: Vector3, uv_a: Vector2, uv_b: Vector2, uv_c: Vector2, u_direction: Vector3) -> String:
	var points: Array[Vector3] = [a, b, c]
	var uv_points: Array[Vector2] = [uv_a, uv_b, uv_c]
	var checked_u := false
	var checked_v := false
	for i in range(points.size()):
		for j in range(i + 1, points.size()):
			var delta: Vector3 = points[j] - points[i]
			var delta_uv: Vector2 = uv_points[j] - uv_points[i]
			var delta_u_world: float = delta.dot(u_direction)
			if absf(delta_u_world) > 0.01 and absf(delta_uv.x) > 0.00001:
				checked_u = true
				if delta_u_world * delta_uv.x < -0.000001:
					return "has reversed vertical U direction."
			if absf(delta.y) > 0.01 and absf(delta_uv.y) > 0.00001:
				checked_v = true
				if delta.y * delta_uv.y < -0.000001:
					return "has reversed vertical V direction."
	if not checked_u:
		return "does not expose a usable vertical U edge."
	if not checked_v:
		return "does not expose a usable vertical V edge."
	return ""

func _fail(message: String) -> void:
	push_error("BASE_RESOURCE_GALLERY_VALIDATION FAIL: %s" % message)
	quit(1)
