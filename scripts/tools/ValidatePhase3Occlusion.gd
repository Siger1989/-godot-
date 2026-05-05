extends SceneTree

const SCENE_PATH := "res://scenes/mvp/FourRoomMVP.tscn"
const GEOMETRY_ROOT_PATH := "LevelRoot/Geometry"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene_resource := load(SCENE_PATH) as PackedScene
	if scene_resource == null:
		_fail("Failed to load %s" % SCENE_PATH)
		return

	var scene := scene_resource.instantiate() as Node3D
	root.add_child(scene)
	await process_frame
	await physics_frame
	await process_frame

	var occlusion := scene.get_node_or_null("Systems/ForegroundOcclusion")
	var camera_rig := scene.get_node_or_null("CameraRig") as Node3D
	var camera := scene.get_node_or_null("CameraRig/Camera3D") as Camera3D
	var player := scene.get_node_or_null("PlayerRoot/Player") as Node3D
	var wall_mesh := scene.get_node_or_null("%s/Wall_West_A/Mesh" % GEOMETRY_ROOT_PATH) as MeshInstance3D
	var wall_collision := scene.get_node_or_null("%s/Wall_West_A/Collision" % GEOMETRY_ROOT_PATH) as CollisionShape3D
	var wall_opening_mesh := scene.get_node_or_null("%s/WallOpening_P_AB/Mesh" % GEOMETRY_ROOT_PATH) as MeshInstance3D
	var wall_opening_collision := scene.get_node_or_null("%s/WallOpening_P_AB/Collision_Top" % GEOMETRY_ROOT_PATH) as CollisionShape3D
	var door_frame := scene.get_node_or_null("%s/DoorFrame_P_AB" % GEOMETRY_ROOT_PATH) as MeshInstance3D

	if (
		occlusion == null
		or camera_rig == null
		or camera == null
		or player == null
		or wall_mesh == null
		or wall_collision == null
		or wall_opening_mesh == null
		or wall_opening_collision == null
		or door_frame == null
	):
		_fail("Required validation nodes are missing.")
		return

	camera_rig.set_process(false)
	player.global_position = Vector3.ZERO
	var original_wall_override := wall_mesh.material_override
	var original_wall_opening_override := wall_opening_mesh.material_override
	var original_door_frame_override := door_frame.material_override
	var release_delay := float(occlusion.get("cutout_release_delay"))
	var restore_delta: float = release_delay + 0.05

	camera_rig.global_position = Vector3(3.4, 2.45, 0.0)
	camera.look_at(player.global_position + Vector3.UP, Vector3.UP)
	occlusion.call("refresh", 0.0)

	var door_hidden_count := int(occlusion.call("get_hidden_mesh_count"))
	if not wall_opening_mesh.visible:
		_fail("WallOpening_P_AB mesh was fully hidden; Phase 3 should use a local cutout.")
		return
	if wall_opening_mesh.material_override as ShaderMaterial == null:
		_fail("WallOpening_P_AB did not receive the local cutout material.")
		return
	if not _cutout_preserves_standard_material(wall_opening_mesh, original_wall_opening_override, "WallOpening_P_AB"):
		return
	if not door_frame.visible:
		_fail("DoorFrame_P_AB was fully hidden; Phase 3 should use a local cutout.")
		return
	if door_frame.material_override as ShaderMaterial == null:
		_fail("DoorFrame_P_AB did not receive the local cutout material.")
		return
	if not _cutout_preserves_standard_material(door_frame, original_door_frame_override, "DoorFrame_P_AB"):
		return
	if wall_opening_collision.disabled:
		_fail("WallOpening_P_AB collision was disabled; Phase 3 cutout must keep collision active.")
		return
	if door_hidden_count < 2:
		_fail("ForegroundOcclusion did not report both wall opening and door frame meshes.")
		return

	camera_rig.global_position = player.global_position + Vector3(0.0, 0.6, -1.0)
	camera.look_at(player.global_position + Vector3.UP, Vector3.UP)
	occlusion.call("refresh", 0.0)

	if wall_opening_mesh.material_override as ShaderMaterial == null:
		_fail("WallOpening_P_AB cutout released immediately; release delay should prevent one-frame wall flash.")
		return
	if door_frame.material_override as ShaderMaterial == null:
		_fail("DoorFrame_P_AB cutout released immediately; release delay should prevent one-frame frame flash.")
		return

	occlusion.call("refresh", restore_delta)

	if not wall_opening_mesh.visible or wall_opening_mesh.material_override != original_wall_opening_override:
		_fail("WallOpening_P_AB material did not restore after Camera -> Player became clear.")
		return
	if not door_frame.visible or door_frame.material_override != original_door_frame_override:
		_fail("DoorFrame_P_AB material did not restore after Camera -> Player became clear.")
		return
	if wall_opening_collision.disabled:
		_fail("WallOpening_P_AB collision changed during restore.")
		return

	camera_rig.global_position = Vector3(-4.2, 1.0, 0.0)
	camera.look_at(player.global_position + Vector3.UP, Vector3.UP)
	occlusion.call("refresh", 0.0)

	var hidden_count := int(occlusion.call("get_hidden_mesh_count"))
	if not wall_mesh.visible:
		_fail("Wall_West_A mesh was fully hidden; Phase 3 should use a local cutout.")
		return
	if wall_mesh.material_override as ShaderMaterial == null:
		_fail("Wall_West_A did not receive the local cutout material.")
		return
	if not _cutout_preserves_standard_material(wall_mesh, original_wall_override, "Wall_West_A"):
		return
	if wall_collision.disabled:
		_fail("Wall_West_A collision was disabled; Phase 3 cutout must keep collision active.")
		return
	if hidden_count < 1:
		_fail("ForegroundOcclusion reported no hidden meshes for blocking wall.")
		return

	camera_rig.global_position = player.global_position + Vector3(0.0, 0.6, -1.0)
	camera.look_at(player.global_position + Vector3.UP, Vector3.UP)
	occlusion.call("refresh", 0.0)

	if wall_mesh.material_override as ShaderMaterial == null:
		_fail("Wall_West_A cutout released immediately; release delay should prevent one-frame wall flash.")
		return

	occlusion.call("refresh", restore_delta)

	if not wall_mesh.visible or wall_mesh.material_override != original_wall_override:
		_fail("Wall_West_A material did not restore after Camera -> Player became clear.")
		return
	if wall_collision.disabled:
		_fail("Wall_West_A collision changed during restore.")
		return

	print("PHASE3_OCCLUSION_VALIDATION PASS hidden_count=%d door_hidden_count=%d" % [hidden_count, door_hidden_count])
	quit(0)

func _cutout_preserves_standard_material(mesh: MeshInstance3D, source_material: Material, label: String) -> bool:
	var cutout := mesh.material_override as ShaderMaterial
	if cutout == null:
		_fail("%s cutout material is missing." % label)
		return false
	var standard := source_material as StandardMaterial3D
	if standard == null:
		_fail("%s source material is not StandardMaterial3D." % label)
		return false
	if standard.albedo_texture != null:
		var use_texture: Variant = cutout.get_shader_parameter("use_albedo_texture")
		var texture: Variant = cutout.get_shader_parameter("albedo_texture")
		if use_texture != true or texture != standard.albedo_texture:
			_fail("%s cutout did not preserve the wall texture." % label)
			return false
	var uv_scale: Variant = cutout.get_shader_parameter("uv_scale")
	var expected_uv := Vector2(standard.uv1_scale.x, standard.uv1_scale.y)
	if typeof(uv_scale) != TYPE_VECTOR2 or (uv_scale as Vector2).distance_to(expected_uv) > 0.001:
		_fail("%s cutout did not preserve UV scale; expected %s got %s." % [label, expected_uv, uv_scale])
		return false
	return true

func _fail(message: String) -> void:
	push_error("PHASE3_OCCLUSION_VALIDATION FAIL: %s" % message)
	quit(1)
