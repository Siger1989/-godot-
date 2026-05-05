extends SceneTree

const SCENE_PATH := "res://scenes/mvp/FourRoomMVP.tscn"
const WALL_MATERIAL_PATH := "res://materials/backrooms_wall.tres"
const FLOOR_MATERIAL_PATH := "res://materials/backrooms_floor.tres"
const DOOR_FRAME_MATERIAL_PATH := "res://materials/backrooms_door_frame.tres"
const CEILING_MATERIAL_PATH := "res://materials/backrooms_ceiling.tres"
const GEOMETRY_ROOT_PATH := "LevelRoot/Geometry"
const WALL_UV_WORLD_SIZE := 6.0
const WALL_HEIGHT := 2.55
const ContactShadowMaterial = preload("res://scripts/visual/ContactShadowMaterial.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene_resource := load(SCENE_PATH) as PackedScene
	if scene_resource == null:
		_fail("Failed to load %s." % SCENE_PATH)
		return

	var scene := scene_resource.instantiate() as Node3D
	scene.set("build_on_ready", false)
	root.add_child(scene)
	current_scene = scene
	await process_frame

	var wall_material := load(WALL_MATERIAL_PATH) as Material
	var floor_material := load(FLOOR_MATERIAL_PATH) as Material
	var door_frame_material := load(DOOR_FRAME_MATERIAL_PATH) as Material
	var ceiling_material := load(CEILING_MATERIAL_PATH) as Material
	if wall_material == null or floor_material == null or door_frame_material == null or ceiling_material == null:
		_fail("Expected render-rule materials failed to load.")
		return

	_validate_scene(scene, wall_material, floor_material, door_frame_material, ceiling_material, "baked")

	var builder := scene.get_node_or_null("Systems/SceneBuilder")
	if builder == null or not builder.has_method("build"):
		_fail("SceneBuilder is missing.")
		return
	builder.call("build")
	await process_frame

	_validate_scene(scene, wall_material, floor_material, door_frame_material, ceiling_material, "runtime")

	print("GENERATED_MESH_RULES_VALIDATION PASS")
	quit(0)

func _validate_scene(
	scene: Node,
	wall_material: Material,
	floor_material: Material,
	door_frame_material: Material,
	ceiling_material: Material,
	pass_name: String
) -> void:
	var regular_wall_count := 0
	var ceiling_count := 0
	var geometry_root := scene.get_node_or_null(GEOMETRY_ROOT_PATH)
	if geometry_root == null:
		_fail("%s scene is missing %s." % [pass_name, GEOMETRY_ROOT_PATH])
		return
	for mesh in _collect_mesh_instances(geometry_root):
		var mesh_instance := mesh as MeshInstance3D
		var parent := mesh_instance.get_parent()
		var parent_name := String(parent.name) if parent != null else ""
		if parent_name.begins_with("Wall") and not parent_name.begins_with("WallOpening"):
			_validate_generated_mesh(mesh_instance, wall_material, "%s regular wall" % pass_name, true)
			_validate_wall_foot_uv_origin(mesh_instance, "%s regular wall" % pass_name)
			_validate_random_wall_grime(mesh_instance, "%s regular wall" % pass_name)
			_validate_no_horizontal_wall_render_caps(mesh_instance, "%s regular wall" % pass_name)
			regular_wall_count += 1
		elif parent_name.begins_with("Ceiling") and not mesh_instance.is_in_group("ceiling_light_panel"):
			_validate_generated_mesh(mesh_instance, ceiling_material, "%s ceiling" % pass_name)
			ceiling_count += 1

	var wall_opening_count := 0
	for node in scene.get_tree().get_nodes_in_group("wall_opening"):
		var mesh := node.get_node_or_null("Mesh") as MeshInstance3D
		if mesh == null:
			_fail("%s wall opening has no Mesh child: %s." % [pass_name, node.get_path()])
			return
		_validate_generated_mesh(mesh, wall_material, "%s wall opening" % pass_name, true)
		_validate_wall_foot_uv_origin(mesh, "%s wall opening" % pass_name)
		_validate_random_wall_grime(mesh, "%s wall opening" % pass_name)
		wall_opening_count += 1

	var door_frame_count := 0
	for node in scene.get_tree().get_nodes_in_group("door_frame"):
		var mesh := node as MeshInstance3D
		if mesh == null:
			continue
		_validate_generated_mesh(mesh, door_frame_material, "%s door frame" % pass_name)
		door_frame_count += 1

	var floor_count := 0
	for node in scene.get_tree().get_nodes_in_group("floor_visual"):
		var mesh := node as MeshInstance3D
		if mesh == null:
			_fail("%s floor_visual group contains a non-mesh node: %s." % [pass_name, node.get_path()])
			return
		_validate_generated_mesh(mesh, floor_material, "%s floor visual" % pass_name)
		floor_count += 1

	if wall_opening_count != 5:
		_fail("%s expected 5 wall openings; found %d." % [pass_name, wall_opening_count])
		return
	if regular_wall_count < 16:
		_fail("%s expected generated ordinary wall/joint meshes; found only %d." % [pass_name, regular_wall_count])
		return
	if ceiling_count != 4:
		_fail("%s expected 4 generated ceiling meshes; found %d." % [pass_name, ceiling_count])
		return
	if door_frame_count != 5:
		_fail("%s expected 5 door frames; found %d." % [pass_name, door_frame_count])
		return
	if floor_count != 4:
		_fail("%s expected 4 floor visual panels; found %d." % [pass_name, floor_count])
		return

func _validate_generated_mesh(mesh: MeshInstance3D, expected_material: Material, label: String, wall_bottom_origin := false) -> void:
	if expected_material == null:
		_fail("%s expected material failed to load." % label)
		return
	if mesh.material_override != expected_material and not ContactShadowMaterial.is_contact_material(mesh.material_override):
		_fail("%s should use material_override %s: %s." % [label, expected_material.resource_path, mesh.get_path()])
		return

	var array_mesh := mesh.mesh as ArrayMesh
	if array_mesh == null or array_mesh.get_surface_count() <= 0:
		_fail("%s mesh should be a non-empty ArrayMesh: %s." % [label, mesh.get_path()])
		return

	var arrays := array_mesh.surface_get_arrays(0)
	var vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	var normals := arrays[Mesh.ARRAY_NORMAL] as PackedVector3Array
	var uvs := arrays[Mesh.ARRAY_TEX_UV] as PackedVector2Array
	var tangents := arrays[Mesh.ARRAY_TANGENT] as PackedFloat32Array
	if vertices.is_empty():
		_fail("%s mesh has no vertices: %s." % [label, mesh.get_path()])
		return
	if normals.size() != vertices.size():
		_fail("%s mesh normal count does not match vertices: %s." % [label, mesh.get_path()])
		return
	if uvs.size() != vertices.size():
		_fail("%s mesh UV count does not match vertices: %s." % [label, mesh.get_path()])
		return
	if tangents.size() != vertices.size() * 4:
		_fail("%s mesh tangent count does not match vertices: %s." % [label, mesh.get_path()])
		return
	_validate_vertical_uv_direction(vertices, normals, uvs, label, mesh.get_path(), wall_bottom_origin)
	for index in range(0, tangents.size(), 4):
		var tangent := Vector3(tangents[index], tangents[index + 1], tangents[index + 2])
		if tangent.length_squared() <= 0.5:
			_fail("%s mesh has an invalid tangent at index %d: %s." % [label, index / 4, mesh.get_path()])
			return
		var vertex_index := int(index / 4)
		var normal := normals[vertex_index].normalized()
		if absf(normal.y) < 0.25:
			var expected_tangent := Vector3.UP.cross(normal).normalized()
			if tangent.normalized().dot(expected_tangent) < 0.95 or tangents[index + 3] < 0.0:
				_fail("%s vertical wall tangent is not using the shared wall basis at index %d: %s." % [label, vertex_index, mesh.get_path()])
				return
	_validate_vertical_uv_u_axis(vertices, normals, uvs, label, mesh.get_path())

func _validate_vertical_uv_direction(
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	uvs: PackedVector2Array,
	label: String,
	mesh_path: NodePath,
	wall_bottom_origin := false
) -> void:
	for index in range(0, vertices.size(), 3):
		if index + 2 >= vertices.size():
			break
		var normal := (normals[index] + normals[index + 1] + normals[index + 2]).normalized()
		if absf(normal.y) >= 0.25:
			continue

		var min_y_index := index
		var max_y_index := index
		for vertex_index in [index + 1, index + 2]:
			if vertices[vertex_index].y < vertices[min_y_index].y:
				min_y_index = vertex_index
			if vertices[vertex_index].y > vertices[max_y_index].y:
				max_y_index = vertex_index

		if vertices[max_y_index].y - vertices[min_y_index].y < 0.01:
			continue
		if wall_bottom_origin:
			if uvs[max_y_index].y >= uvs[min_y_index].y - 0.0001:
				_fail("%s vertical UV V should decrease with height so texture bottom stays at wall foot at triangle %d: %s." % [label, int(index / 3), mesh_path])
				return
		elif uvs[max_y_index].y <= uvs[min_y_index].y + 0.0001:
			_fail("%s vertical UV V should increase with height at triangle %d: %s." % [label, int(index / 3), mesh_path])
			return

func _validate_vertical_uv_u_axis(
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	uvs: PackedVector2Array,
	label: String,
	mesh_path: NodePath
) -> void:
	for index in range(0, vertices.size(), 3):
		if index + 2 >= vertices.size():
			break
		var normal := (normals[index] + normals[index + 1] + normals[index + 2]).normalized()
		if absf(normal.y) >= 0.25:
			continue
		var u_direction := Vector3.UP.cross(normal).normalized()
		if u_direction.length_squared() <= 0.000001:
			continue

		var min_u_index := index
		var max_u_index := index
		for vertex_index in [index + 1, index + 2]:
			if vertices[vertex_index].dot(u_direction) < vertices[min_u_index].dot(u_direction):
				min_u_index = vertex_index
			if vertices[vertex_index].dot(u_direction) > vertices[max_u_index].dot(u_direction):
				max_u_index = vertex_index

		if vertices[max_u_index].dot(u_direction) - vertices[min_u_index].dot(u_direction) < 0.01:
			continue
		if uvs[max_u_index].x <= uvs[min_u_index].x + 0.0001:
			_fail("%s vertical UV U should increase to the viewer-right side at triangle %d: %s." % [label, int(index / 3), mesh_path])
			return

func _validate_wall_foot_uv_origin(mesh: MeshInstance3D, label: String) -> void:
	var array_mesh := mesh.mesh as ArrayMesh
	if array_mesh == null or array_mesh.get_surface_count() <= 0:
		return
	var arrays := array_mesh.surface_get_arrays(0)
	var vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	var normals := arrays[Mesh.ARRAY_NORMAL] as PackedVector3Array
	var uvs := arrays[Mesh.ARRAY_TEX_UV] as PackedVector2Array
	var checked := 0
	for index in range(vertices.size()):
		if absf(normals[index].normalized().y) >= 0.25:
			continue
		var expected_v := (WALL_HEIGHT - mesh.to_global(vertices[index]).y) / WALL_HEIGHT
		if absf(uvs[index].y - expected_v) > 0.001:
			_fail("%s vertical UV V should map full wall height with texture bottom at wall foot at vertex %d: %s." % [label, index, mesh.get_path()])
			return
		checked += 1
	if checked <= 0:
		_fail("%s expected vertical wall UV vertices: %s." % [label, mesh.get_path()])
		return

func _validate_random_wall_grime(mesh: MeshInstance3D, label: String) -> void:
	var material := mesh.material_override as ShaderMaterial
	if material == null or not ContactShadowMaterial.is_contact_material(material):
		_fail("%s should use a contact-shadow ShaderMaterial for runtime grime: %s." % [label, mesh.get_path()])
		return
	if not bool(material.get_shader_parameter("use_random_grime")):
		_fail("%s should enable runtime random wall grime: %s." % [label, mesh.get_path()])
		return
	if material.get_shader_parameter("random_grime_texture") == null:
		_fail("%s should bind the runtime grime atlas texture: %s." % [label, mesh.get_path()])
		return

func _validate_no_horizontal_wall_render_caps(mesh: MeshInstance3D, label: String) -> void:
	var array_mesh := mesh.mesh as ArrayMesh
	if array_mesh == null or array_mesh.get_surface_count() <= 0:
		return
	var arrays := array_mesh.surface_get_arrays(0)
	var normals := arrays[Mesh.ARRAY_NORMAL] as PackedVector3Array
	for index in range(normals.size()):
		if absf(normals[index].normalized().y) > 0.95:
			_fail("%s should not render horizontal cap faces that fight floor/ceiling: %s." % [label, mesh.get_path()])
			return

func _collect_mesh_instances(root_node: Node) -> Array[MeshInstance3D]:
	var output: Array[MeshInstance3D] = []
	_collect_mesh_instances_recursive(root_node, output)
	return output

func _collect_mesh_instances_recursive(node: Node, output: Array[MeshInstance3D]) -> void:
	var mesh_instance := node as MeshInstance3D
	if mesh_instance != null:
		output.append(mesh_instance)
	for child in node.get_children():
		_collect_mesh_instances_recursive(child, output)

func _fail(message: String) -> void:
	push_error("GENERATED_MESH_RULES_VALIDATION FAIL: %s" % message)
	quit(1)
