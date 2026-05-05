extends SceneTree

const WALL_MATERIAL_PATH := "res://materials/backrooms_wall.tres"
const FLOOR_MATERIAL_PATH := "res://materials/backrooms_floor.tres"

func _init() -> void:
	var packed_scene := load("res://scenes/mvp/FourRoomMVP.tscn") as PackedScene
	var scene := packed_scene.instantiate()
	root.add_child(scene)
	var rows: Array[String] = []
	rows.append("path,type,material,mesh_class,layers,cast_shadow,gi_mode,normal_counts,tangent_by_normal,aabb")
	_collect_visuals(scene, rows, String(scene.name))
	for row in rows:
		print(row)
	quit()

func _collect_visuals(node: Node, rows: Array[String], node_path: String) -> void:
	var mesh_instance := node as MeshInstance3D
	if mesh_instance != null and _is_backrooms_visual(mesh_instance):
		rows.append(_format_mesh(mesh_instance, node_path))
	for child in node.get_children():
		_collect_visuals(child, rows, "%s/%s" % [node_path, child.name])

func _is_backrooms_visual(mesh_instance: MeshInstance3D) -> bool:
	var material := _get_material(mesh_instance)
	if material == null:
		return false
	var path := material.resource_path
	return path == WALL_MATERIAL_PATH or path == FLOOR_MATERIAL_PATH

func _format_mesh(mesh_instance: MeshInstance3D, node_path: String) -> String:
	var material := _get_material(mesh_instance)
	var mesh := mesh_instance.mesh
	var normal_counts := "{}"
	var tangent_by_normal := "{}"
	if mesh != null and mesh.get_surface_count() > 0:
		var arrays := mesh.surface_get_arrays(0)
		normal_counts = _count_normals(arrays[Mesh.ARRAY_NORMAL])
		tangent_by_normal = _count_tangent_signs_by_normal(arrays[Mesh.ARRAY_NORMAL], arrays[Mesh.ARRAY_TANGENT])
	return "%s,%s,%s,%s,%d,%d,%d,%s,%s,%s" % [
		node_path,
		_get_parent_kind(mesh_instance),
		material.resource_path,
		mesh.get_class() if mesh != null else "<none>",
		mesh_instance.layers,
		mesh_instance.cast_shadow,
		mesh_instance.gi_mode,
		normal_counts,
		tangent_by_normal,
		str(mesh_instance.get_aabb()),
	]

func _get_material(mesh_instance: MeshInstance3D) -> Material:
	if mesh_instance.material_override != null:
		return mesh_instance.material_override
	if mesh_instance.mesh != null and mesh_instance.mesh.get_surface_count() > 0:
		return mesh_instance.mesh.surface_get_material(0)
	return null

func _get_parent_kind(mesh_instance: MeshInstance3D) -> String:
	var parent := mesh_instance.get_parent()
	if parent == null:
		return "root"
	var parent_name := String(parent.name)
	if parent_name.begins_with("WallOpening_"):
		return "opening"
	if parent_name.begins_with("WallJoint_"):
		return "joint"
	if parent_name.begins_with("Wall_"):
		return "wall"
	if parent_name.begins_with("Ceiling_"):
		return "ceiling"
	if String(mesh_instance.name).begins_with("Floor_"):
		return "floor"
	return parent_name

func _count_normals(normals: PackedVector3Array) -> String:
	var counts := {}
	for normal in normals:
		var key := _normal_key(normal)
		counts[key] = int(counts.get(key, 0)) + 1
	return str(counts)

func _normal_key(normal: Vector3) -> String:
	var axis := "x"
	var value := normal.x
	if absf(normal.y) > absf(value):
		axis = "y"
		value = normal.y
	if absf(normal.z) > absf(value):
		axis = "z"
		value = normal.z
	return ("%s%s" % ["+" if value >= 0.0 else "-", axis])

func _count_tangent_signs_by_normal(normals: PackedVector3Array, tangents: PackedFloat32Array) -> String:
	var counts := {}
	var vertex_count := mini(normals.size(), tangents.size() / 4)
	for i in range(vertex_count):
		var normal_key := _normal_key(normals[i])
		var sign_key := "+" if tangents[i * 4 + 3] >= 0.0 else "-"
		var key := "%s%s" % [normal_key, sign_key]
		counts[key] = int(counts.get(key, 0)) + 1
	return str(counts)
