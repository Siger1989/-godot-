extends SceneTree

const EXPERIMENT_SCENE_PATH := "res://scenes/mvp/experiments/FourRoomMVP_contact_ao_experiment.tscn"
const CONTACT_SHADER_PATH := "res://materials/shaders/contact_ao_surface.gdshader"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load(EXPERIMENT_SCENE_PATH) as PackedScene
	if packed == null:
		_fail("Failed to load %s." % EXPERIMENT_SCENE_PATH)
		return

	var scene := packed.instantiate() as Node3D
	if scene == null:
		_fail("Failed to instantiate %s." % EXPERIMENT_SCENE_PATH)
		return

	scene.set("build_on_ready", false)
	root.add_child(scene)
	current_scene = scene
	await process_frame

	if scene.get_node_or_null("LevelRoot/Experiment_ContactAO") == null:
		_fail("Experiment marker is missing.")
		return

	var expected_shader := load(CONTACT_SHADER_PATH) as Shader
	if expected_shader == null:
		_fail("Contact AO shader is missing.")
		return

	var counts := {
		"wall": 0,
		"floor": 0,
		"door_frame": 0,
		"ceiling": 0,
	}

	var geometry_root := scene.get_node_or_null("LevelRoot/Geometry")
	if geometry_root == null:
		_fail("Experiment scene is missing LevelRoot/Geometry.")
		return

	for mesh_instance in _collect_mesh_instances(geometry_root):
		var mesh := mesh_instance as MeshInstance3D
		var owner := mesh.get_parent()
		var owner_name := String(owner.name) if owner != null else String(mesh.name)

		if mesh.is_in_group("floor_visual"):
			if not _uses_contact_shader(mesh, expected_shader, "floor"):
				return
			if not _has_uv_scale(mesh, Vector2(12.0, 12.0), "floor"):
				return
			counts["floor"] += 1
		elif mesh.is_in_group("door_frame"):
			if not _uses_contact_shader(mesh, expected_shader, "door frame"):
				return
			if not _has_uv_scale(mesh, Vector2(1.2, 2.0), "door frame"):
				return
			counts["door_frame"] += 1
		elif mesh.is_in_group("ceiling") or owner_name.begins_with("Ceiling_"):
			if not _uses_contact_shader(mesh, expected_shader, "ceiling"):
				return
			counts["ceiling"] += 1
		elif owner_name.begins_with("Wall") or String(mesh.name).begins_with("Wall"):
			if not _uses_contact_shader(mesh, expected_shader, "wall"):
				return
			if not _has_uv_scale(mesh, Vector2(4.475, 3.77), "wall"):
				return
			counts["wall"] += 1

	if int(counts["floor"]) != 4:
		_fail("Expected 4 floor AO materials, found %d." % int(counts["floor"]))
		return
	if int(counts["door_frame"]) != 4:
		_fail("Expected 4 door-frame AO materials, found %d." % int(counts["door_frame"]))
		return
	if int(counts["ceiling"]) != 4:
		_fail("Expected 4 ceiling AO materials, found %d." % int(counts["ceiling"]))
		return
	if int(counts["wall"]) < 20:
		_fail("Expected at least 20 wall AO materials, found %d." % int(counts["wall"]))
		return
	if not _validate_foreground_cutout_preserves_contact_material(scene):
		return

	print("CONTACT_AO_EXPERIMENT_VALIDATION PASS wall=%d floor=%d door_frame=%d ceiling=%d" % [
		int(counts["wall"]),
		int(counts["floor"]),
		int(counts["door_frame"]),
		int(counts["ceiling"]),
	])
	quit(0)

func _uses_contact_shader(mesh: MeshInstance3D, expected_shader: Shader, label: String) -> bool:
	var material := mesh.material_override as ShaderMaterial
	if material == null:
		_fail("%s mesh does not use a ShaderMaterial: %s." % [label, mesh.get_path()])
		return false
	if material.shader != expected_shader:
		_fail("%s mesh uses the wrong shader: %s." % [label, mesh.get_path()])
		return false
	return true

func _has_uv_scale(mesh: MeshInstance3D, expected: Vector2, label: String) -> bool:
	var material := mesh.material_override as ShaderMaterial
	if material == null:
		_fail("%s mesh does not use a ShaderMaterial while checking UV scale: %s." % [label, mesh.get_path()])
		return false
	var value: Variant = material.get_shader_parameter("uv_scale")
	if typeof(value) != TYPE_VECTOR2:
		_fail("%s mesh UV scale is not Vector2: %s." % [label, mesh.get_path()])
		return false
	var actual := value as Vector2
	if actual.distance_to(expected) > 0.001:
		_fail("%s mesh UV scale mismatch at %s, expected %s, got %s." % [label, mesh.get_path(), expected, actual])
		return false
	return true

func _validate_foreground_cutout_preserves_contact_material(scene: Node3D) -> bool:
	var occlusion := scene.get_node_or_null("Systems/ForegroundOcclusion")
	var camera_rig := scene.get_node_or_null("CameraRig") as Node3D
	var camera := scene.get_node_or_null("CameraRig/Camera3D") as Camera3D
	var player := scene.get_node_or_null("PlayerRoot/Player") as Node3D
	var wall_mesh := scene.get_node_or_null("LevelRoot/Geometry/Wall_West_A/Mesh") as MeshInstance3D
	if occlusion == null or camera_rig == null or camera == null or player == null or wall_mesh == null:
		_fail("Required foreground cutout validation nodes are missing.")
		return false

	var source_material := wall_mesh.material_override as ShaderMaterial
	if source_material == null:
		_fail("Contact AO wall material is missing before foreground cutout validation.")
		return false
	var expected_texture: Variant = source_material.get_shader_parameter("albedo_texture")
	var expected_uv_scale: Variant = source_material.get_shader_parameter("uv_scale")

	camera_rig.set_process(false)
	player.global_position = Vector3.ZERO
	camera_rig.global_position = Vector3(-4.2, 1.0, 0.0)
	camera.look_at(player.global_position + Vector3.UP, Vector3.UP)
	occlusion.call("refresh", 0.0)

	var cutout_material := wall_mesh.material_override as ShaderMaterial
	if cutout_material == null:
		_fail("Contact AO wall did not receive foreground cutout ShaderMaterial.")
		return false
	var use_texture: Variant = cutout_material.get_shader_parameter("use_albedo_texture")
	var cutout_texture: Variant = cutout_material.get_shader_parameter("albedo_texture")
	if use_texture != true or cutout_texture != expected_texture:
		_fail("Foreground cutout did not preserve contact-AO wall texture.")
		return false
	var cutout_uv_scale: Variant = cutout_material.get_shader_parameter("uv_scale")
	if typeof(expected_uv_scale) != TYPE_VECTOR2 or typeof(cutout_uv_scale) != TYPE_VECTOR2:
		_fail("Foreground cutout or contact-AO wall UV scale is not Vector2.")
		return false
	if (cutout_uv_scale as Vector2).distance_to(expected_uv_scale as Vector2) > 0.001:
		_fail("Foreground cutout did not preserve contact-AO wall UV scale; expected %s got %s." % [expected_uv_scale, cutout_uv_scale])
		return false
	return true

func _collect_mesh_instances(root_node: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	if root_node is MeshInstance3D:
		result.append(root_node as MeshInstance3D)
	for child in root_node.get_children():
		result.append_array(_collect_mesh_instances(child))
	return result

func _fail(message: String) -> void:
	push_error("CONTACT_AO_EXPERIMENT_VALIDATION FAIL: %s" % message)
	quit(1)
