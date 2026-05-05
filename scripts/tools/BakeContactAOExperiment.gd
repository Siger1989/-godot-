extends SceneTree

const BASE_SCENE_PATH := "res://scenes/mvp/FourRoomMVP.tscn"
const EXPERIMENT_SCENE_PATH := "res://scenes/mvp/experiments/FourRoomMVP_contact_ao_experiment.tscn"
const CONTACT_SHADER_PATH := "res://materials/shaders/contact_ao_surface.gdshader"

const WALL_ALBEDO_PATH := "res://materials/textures/backrooms_wall_albedo.png"
const WALL_NORMAL_PATH := "res://materials/textures/backrooms_wall_normal.png"
const FLOOR_ALBEDO_PATH := "res://materials/textures/backrooms_floor_albedo.png"
const FLOOR_NORMAL_PATH := "res://materials/textures/backrooms_floor_normal.png"
const DOOR_FRAME_ALBEDO_PATH := "res://materials/textures/backrooms_door_frame_albedo.png"
const DOOR_FRAME_NORMAL_PATH := "res://materials/textures/backrooms_door_frame_normal.png"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_ensure_experiment_dir()

	var packed := load(BASE_SCENE_PATH) as PackedScene
	if packed == null:
		_fail("Failed to load %s." % BASE_SCENE_PATH)
		return

	var scene := packed.instantiate() as Node3D
	if scene == null:
		_fail("Failed to instantiate %s." % BASE_SCENE_PATH)
		return

	scene.name = "FourRoomMVP_ContactAOExperiment"
	scene.set("build_on_ready", false)
	root.add_child(scene)
	current_scene = scene
	await process_frame

	var builder := scene.get_node_or_null("Systems/SceneBuilder")
	if builder != null and builder.has_method("build"):
		builder.call("build")
		await process_frame

	var shader := load(CONTACT_SHADER_PATH) as Shader
	if shader == null:
		_fail("Failed to load contact AO shader.")
		return

	var materials := {
		"wall": _make_material(shader, 0, WALL_ALBEDO_PATH, WALL_NORMAL_PATH, Vector2(4.475, 3.77), Color(1, 1, 1, 1), 0.22, 0.88, 0.12, 0.08, 0.10, 0.00, 0.22),
		"floor": _make_material(shader, 1, FLOOR_ALBEDO_PATH, FLOOR_NORMAL_PATH, Vector2(12.0, 12.0), Color(1.18, 1.18, 1.14, 1), 0.28, 0.78, 0.08, 0.00, 0.09, 0.00, 0.16),
		"door_frame": _make_material(shader, 3, DOOR_FRAME_ALBEDO_PATH, DOOR_FRAME_NORMAL_PATH, Vector2(1.2, 2.0), Color(1, 1, 1, 1), 0.24, 0.78, 0.08, 0.06, 0.00, 0.08, 0.18),
		"ceiling": _make_material(shader, 2, "", "", Vector2.ONE, Color(0.74, 0.70, 0.52, 1), 0.0, 0.90, 0.00, 0.08, 0.08, 0.00, 0.16),
	}

	var applied := _apply_experiment_materials(scene, materials)
	_add_experiment_marker(scene)
	_assign_owned_generated_nodes(scene)

	var repacked := PackedScene.new()
	var pack_result := repacked.pack(scene)
	if pack_result != OK:
		_fail("PackedScene.pack failed with code %d." % pack_result)
		return
	var save_result := ResourceSaver.save(repacked, EXPERIMENT_SCENE_PATH)
	if save_result != OK:
		_fail("ResourceSaver.save failed with code %d." % save_result)
		return

	print("CONTACT_AO_EXPERIMENT_BAKE PASS path=%s wall=%d floor=%d door_frame=%d ceiling=%d" % [
		EXPERIMENT_SCENE_PATH,
		int(applied["wall"]),
		int(applied["floor"]),
		int(applied["door_frame"]),
		int(applied["ceiling"]),
	])
	quit(0)

func _make_material(
	shader: Shader,
	surface_mode: int,
	albedo_path: String,
	normal_path: String,
	uv_scale: Vector2,
	tint: Color,
	normal_depth: float,
	roughness: float,
	floor_strength: float,
	ceiling_strength: float,
	corner_strength: float,
	door_edge_strength: float,
	max_shadow: float
) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("surface_mode", surface_mode)
	material.set_shader_parameter("uv_scale", uv_scale)
	material.set_shader_parameter("uv_offset", Vector2.ZERO)
	material.set_shader_parameter("albedo_tint", tint)
	material.set_shader_parameter("roughness_value", roughness)
	material.set_shader_parameter("normal_depth", normal_depth)
	material.set_shader_parameter("floor_contact_strength", floor_strength)
	material.set_shader_parameter("ceiling_contact_strength", ceiling_strength)
	material.set_shader_parameter("corner_contact_strength", corner_strength)
	material.set_shader_parameter("door_edge_strength", door_edge_strength)
	material.set_shader_parameter("max_shadow", max_shadow)

	if not albedo_path.is_empty():
		material.set_shader_parameter("use_texture", true)
		material.set_shader_parameter("albedo_texture", load(albedo_path))
	else:
		material.set_shader_parameter("use_texture", false)

	if not normal_path.is_empty():
		material.set_shader_parameter("use_normal", true)
		material.set_shader_parameter("normal_texture", load(normal_path))
	else:
		material.set_shader_parameter("use_normal", false)

	return material

func _apply_experiment_materials(scene: Node, materials: Dictionary) -> Dictionary:
	var counts := {
		"wall": 0,
		"floor": 0,
		"door_frame": 0,
		"ceiling": 0,
	}
	var geometry_root := scene.get_node_or_null("LevelRoot/Geometry")
	if geometry_root == null:
		return counts

	for mesh_instance in _collect_mesh_instances(geometry_root):
		var mesh := mesh_instance as MeshInstance3D
		var owner := mesh.get_parent()
		var owner_name := String(owner.name) if owner != null else String(mesh.name)

		if mesh.is_in_group("floor_visual"):
			mesh.material_override = materials["floor"]
			counts["floor"] += 1
		elif mesh.is_in_group("door_frame"):
			_set_visual_material_if_supported(mesh, materials["door_frame"])
			mesh.material_override = materials["door_frame"]
			counts["door_frame"] += 1
		elif mesh.is_in_group("ceiling") or owner_name.begins_with("Ceiling_"):
			mesh.material_override = materials["ceiling"]
			counts["ceiling"] += 1
		elif owner_name.begins_with("Wall") or String(mesh.name).begins_with("Wall"):
			if owner != null:
				_set_visual_material_if_supported(owner, materials["wall"])
			mesh.material_override = materials["wall"]
			counts["wall"] += 1

	return counts

func _set_visual_material_if_supported(node: Object, material: Material) -> void:
	for property in node.get_property_list():
		if String(property.name) == "visual_material":
			node.set("visual_material", material)
			return

func _collect_mesh_instances(root_node: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	if root_node is MeshInstance3D:
		result.append(root_node as MeshInstance3D)
	for child in root_node.get_children():
		result.append_array(_collect_mesh_instances(child))
	return result

func _add_experiment_marker(scene: Node3D) -> void:
	var level_root := scene.get_node_or_null("LevelRoot") as Node3D
	if level_root == null:
		return
	var marker := Node3D.new()
	marker.name = "Experiment_ContactAO"
	marker.set_meta("source_scene", BASE_SCENE_PATH)
	marker.set_meta("rule", "Contact AO is an experiment copy. Do not merge until visually accepted.")
	level_root.add_child(marker)
	marker.owner = scene

func _ensure_experiment_dir() -> void:
	var dir := DirAccess.open("res://")
	if dir == null:
		return
	if not dir.dir_exists("scenes/mvp/experiments"):
		dir.make_dir_recursive("scenes/mvp/experiments")

func _assign_owned_generated_nodes(scene: Node) -> void:
	for target_path in [
		"LevelRoot/Geometry",
		"LevelRoot/Areas",
		"LevelRoot/Portals",
		"LevelRoot/Markers",
		"LevelRoot/Lights",
		"LevelRoot/Experiment_ContactAO",
	]:
		var target := scene.get_node_or_null(target_path)
		if target != null:
			_assign_owner_recursive(target, scene)

func _assign_owner_recursive(node: Node, owner_root: Node) -> void:
	node.owner = owner_root
	if not node.scene_file_path.is_empty():
		return
	for child in node.get_children():
		_assign_owner_recursive(child, owner_root)

func _fail(message: String) -> void:
	push_error("CONTACT_AO_EXPERIMENT_BAKE FAIL: %s" % message)
	quit(1)
