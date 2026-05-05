extends SceneTree

const ASSET_ID := "HideLocker_A"
const GLB_PATH := "res://assets/backrooms/props/furniture/HideLocker_A.glb"
const SCENE_PATH := "res://assets/backrooms/props/furniture/HideLocker_A.tscn"
const SHOWCASE_SCENE_PATH := "res://scenes/tests/Test_HideableLockerShowcase.tscn"
const PLAYER_SCENE_PATH := "res://scenes/modules/PlayerModule.tscn"
const FOUR_ROOM_SCENE_PATH := "res://scenes/mvp/FourRoomMVP.tscn"
const FOUR_ROOM_PLACEMENT_NAME := "RoomC_HideLocker_A"
const FOUR_ROOM_PLACEMENT_POSITION := Vector3(8.58, 0.0, 7.32)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if not _validate_resource():
		return
	if not _validate_showcase_scene():
		return
	if not await _validate_interaction_flow():
		return
	if not await _validate_four_room_placement():
		return
	print("HIDEABLE_LOCKER_VALIDATION PASS asset=%s" % ASSET_ID)
	quit(0)

func _validate_resource() -> bool:
	if not ResourceLoader.exists(GLB_PATH):
		_fail("Missing GLB: %s." % GLB_PATH)
		return false
	if not ResourceLoader.exists(SCENE_PATH):
		_fail("Missing wrapper scene: %s." % SCENE_PATH)
		return false
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		_fail("Wrapper failed to load.")
		return false
	var instance := packed.instantiate() as Node3D
	if instance == null:
		_fail("Wrapper failed to instantiate.")
		return false
	if instance.name != ASSET_ID:
		_fail("Wrapper root name mismatch.")
		instance.free()
		return false
	if not instance.is_in_group("interactive_hideable"):
		_fail("Wrapper is not in interactive_hideable group.")
		instance.free()
		return false
	if not instance.has_method("interact_from") or not instance.has_method("is_occupied") or not instance.has_method("can_interact_from"):
		_fail("Wrapper is missing hideable interaction methods.")
		instance.free()
		return false
	if not (instance.get_node_or_null("CollisionBody/Collision") is CollisionShape3D):
		_fail("Hideable locker needs a simple collision body.")
		instance.free()
		return false
	for required_marker in ["HideStandPoint", "HideCameraAnchor", "ExitMarker", "InteractionPoint"]:
		if not (instance.get_node_or_null(required_marker) is Marker3D):
			_fail("Wrapper missing marker: %s." % required_marker)
			instance.free()
			return false
	if _count_mesh_instances(instance) <= 0:
		_fail("Wrapper has no MeshInstance3D descendants.")
		instance.free()
		return false
	if _count_named_meshes(instance, "view_slit") < 6:
		_fail("Locker model must include visible upper slit geometry.")
		instance.free()
		return false
	if _count_named_meshes(instance, "one_piece") < 1:
		_fail("Locker front door should be built as one integrated door panel.")
		instance.free()
		return false
	if _count_named_meshes(instance, "front_door_lower_panel") > 0:
		_fail("Locker front door still uses the old separate lower-panel mesh name.")
		instance.free()
		return false
	var aabb := _combined_mesh_aabb(instance)
	if aabb.size.y < 1.86 or aabb.size.y > 2.05:
		_fail("Locker height out of expected range: %.3f." % aabb.size.y)
		instance.free()
		return false
	if aabb.size.x < 0.70 or aabb.size.x > 0.92 or aabb.size.z < 0.50 or aabb.size.z > 0.72:
		_fail("Locker footprint out of expected range: %s." % aabb.size)
		instance.free()
		return false
	if float(instance.get("peek_yaw_limit_degrees")) > 22.0 or float(instance.get("peek_pitch_limit_degrees")) > 10.0:
		_fail("Peek view limits are too wide for slit viewing.")
		instance.free()
		return false
	instance.free()
	return true

func _validate_showcase_scene() -> bool:
	var packed := load(SHOWCASE_SCENE_PATH) as PackedScene
	if packed == null:
		_fail("Missing hideable locker showcase scene.")
		return false
	var scene := packed.instantiate() as Node3D
	if scene == null:
		_fail("Showcase failed to instantiate.")
		return false
	var props_root := scene.get_node_or_null("HideableProps")
	if props_root == null or props_root.get_child_count() != 1:
		_fail("Showcase must contain exactly one hideable locker.")
		scene.free()
		return false
	var locker := props_root.get_node_or_null("HideLocker_A_Showcase")
	if locker == null:
		_fail("Showcase missing HideLocker_A_Showcase.")
		scene.free()
		return false
	scene.free()
	return true

func _validate_interaction_flow() -> bool:
	var packed_locker := load(SCENE_PATH) as PackedScene
	var packed_player := load(PLAYER_SCENE_PATH) as PackedScene
	if packed_locker == null or packed_player == null:
		_fail("Missing player or locker scene for interaction validation.")
		return false

	var scene := Node3D.new()
	scene.name = "HideableLockerInteractionValidation"
	root.add_child(scene)
	current_scene = scene

	var locker := packed_locker.instantiate() as Node3D
	locker.name = "HideLocker_A_Test"
	scene.add_child(locker)

	var player_root := Node3D.new()
	player_root.name = "PlayerRoot"
	scene.add_child(player_root)
	var player := packed_player.instantiate() as Node3D
	player.name = "Player"
	player.position = Vector3(0.0, 0.0, 1.10)
	player_root.add_child(player)

	var camera_rig := Node3D.new()
	camera_rig.name = "CameraRig"
	camera_rig.position = Vector3(0.0, 1.45, 2.35)
	scene.add_child(camera_rig)
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.current = true
	camera.fov = 62.0
	camera_rig.add_child(camera)
	camera.look_at(Vector3(0.0, 1.1, 0.0), Vector3.UP)

	await process_frame
	await physics_frame

	if not _validate_interact_input_action():
		return false
	player.set("_facing_direction", Vector3.FORWARD)
	player.set("_has_facing_direction", true)
	await process_frame

	var prompt_button := player.get_node_or_null("InteractionPromptLayer/InteractButton") as Button
	if prompt_button == null:
		_fail("Player is missing the interaction prompt button.")
		return false
	if not prompt_button.visible:
		_fail("Hideable interaction prompt button should be visible near the locker.")
		return false
	if prompt_button.text != "E 进入":
		_fail("Hideable interaction prompt should say E enter; got `%s`." % prompt_button.text)
		return false
	if not bool(locker.call("can_interact_from", player, Vector3.FORWARD, 1.35)):
		_fail("Locker should accept a close player facing the front.")
		return false
	prompt_button.emit_signal("pressed")
	await process_frame
	if not bool(locker.call("is_occupied")):
		_fail("Interaction prompt button did not enter the locker.")
		return false
	if not _validate_peek_mask(locker):
		return false
	var locker_exit_button := locker.get_node_or_null("HideLockerExitButtonLayer/ExitHideButton") as Button
	if locker_exit_button == null:
		_fail("Hidden locker view should show a phone-friendly E exit button.")
		return false
	if locker_exit_button.text != "E 出来":
		_fail("Hidden locker exit button text is wrong: `%s`." % locker_exit_button.text)
		return false
	locker_exit_button.emit_signal("pressed")
	await process_frame
	if bool(locker.call("is_occupied")):
		_fail("Locker exit button did not leave the hiding state.")
		return false
	if locker.get_node_or_null("HideLockerExitButtonLayer") != null:
		_fail("Locker exit button layer was not removed after leaving.")
		return false
	if not bool(player.call("_try_interact_with_hideable")):
		_fail("Player interact path did not re-enter the locker after exit button validation.")
		return false
	await process_frame
	locker.call("apply_peek_mouse_motion", Vector2(0.0, 20.0))
	if float(locker.get("_peek_pitch")) >= -0.001:
		_fail("Hideable mouse vertical look should be inverted after the latest tuning.")
		return false
	locker.call("interact_from", player, Vector3.FORWARD)
	await process_frame
	if bool(locker.call("is_occupied")):
		_fail("Locker did not exit after prompt-button entry.")
		return false

	player.set("_facing_direction", Vector3.FORWARD)
	player.set("_has_facing_direction", true)
	if not bool(player.call("_try_interact_with_hideable")):
		_fail("Player interact path did not enter the locker.")
		return false
	await process_frame

	if not bool(locker.call("is_occupied")):
		_fail("Locker did not report occupied after interaction.")
		return false
	if player.visible:
		_fail("Hidden player should not remain visible outside the locker.")
		return false
	if player.has_method("is_interaction_locked") and not bool(player.call("is_interaction_locked")):
		_fail("Player movement should be locked while hiding.")
		return false
	if absf(camera.fov - 34.0) > 0.1:
		_fail("Camera FOV was not narrowed for slit viewing.")
		return false
	if locker.get_node_or_null("HideLockerPeekSlitMask") == null:
		_fail("Slit-view mask was not created.")
		return false
	var hide_anchor := locker.get_node_or_null("HideCameraAnchor") as Marker3D
	if hide_anchor == null or camera.global_position.distance_to(hide_anchor.global_position) > 0.01:
		_fail("Camera was not moved to the cabinet slit viewpoint.")
		return false

	locker.call("interact_from", player, Vector3.FORWARD)
	await process_frame
	if bool(locker.call("is_occupied")):
		_fail("Second interaction did not exit the locker.")
		return false
	if not player.visible:
		_fail("Player visibility was not restored after exiting.")
		return false
	if player.has_method("is_interaction_locked") and bool(player.call("is_interaction_locked")):
		_fail("Player movement lock was not released after exiting.")
		return false
	if absf(camera.fov - 62.0) > 0.1:
		_fail("Camera FOV was not restored after exiting.")
		return false

	root.remove_child(scene)
	scene.free()
	return true

func _validate_peek_mask(locker: Node3D) -> bool:
	var mask_root := locker.get_node_or_null("HideLockerPeekSlitMask/MaskRoot")
	if mask_root == null:
		_fail("Slit-view mask root was not created.")
		return false
	var opaque_count := 0
	var soft_count := 0
	for child in mask_root.get_children():
		var rect := child as ColorRect
		if rect == null:
			continue
		if rect.name.begins_with("OpaqueMaskRect"):
			opaque_count += 1
			if rect.color.a < 0.999:
				_fail("Opaque mask rect should be fully black and nontransparent.")
				return false
		elif rect.name.begins_with("SoftMaskEdge"):
			soft_count += 1
			if rect.color.a <= 0.0 or rect.color.a >= 1.0:
				_fail("Soft mask edge should use a partial-opacity feather.")
				return false
	if opaque_count < 9 or soft_count < 8:
		_fail("Slit-view mask should contain opaque blocks plus soft edge feathering.")
		return false
	return true

func _validate_four_room_placement() -> bool:
	var packed := load(FOUR_ROOM_SCENE_PATH) as PackedScene
	if packed == null:
		_fail("Missing FourRoomMVP scene.")
		return false
	var scene := packed.instantiate() as Node3D
	if scene == null:
		_fail("FourRoomMVP failed to instantiate.")
		return false
	scene.set("build_on_ready", false)
	root.add_child(scene)
	current_scene = scene
	await process_frame

	var props_root := scene.get_node_or_null("LevelRoot/Props") as Node3D
	if props_root == null:
		_fail("FourRoomMVP missing LevelRoot/Props.")
		return false
	var locker := props_root.get_node_or_null(FOUR_ROOM_PLACEMENT_NAME) as Node3D
	if locker == null:
		_fail("FourRoomMVP missing hideable locker placement.")
		return false
	if String(locker.get_meta("hideable_prop_id", "")) != ASSET_ID:
		_fail("FourRoomMVP locker placement has wrong hideable metadata.")
		return false
	if not locker.is_in_group("interactive_hideable"):
		_fail("FourRoomMVP locker placement is not interactive.")
		return false
	if locker.global_position.distance_to(FOUR_ROOM_PLACEMENT_POSITION) > 0.02:
		_fail("FourRoomMVP locker placement moved unexpectedly: %s." % locker.global_position)
		return false
	if String(locker.get_meta("room_id", "")) != "Room_C":
		_fail("FourRoomMVP locker placement must be marked Room_C.")
		return false
	if not (locker.get_node_or_null("CollisionBody/Collision") is CollisionShape3D):
		_fail("FourRoomMVP locker placement is missing simple collision.")
		return false
	if _xz_distance(locker.global_position, Vector3(6.0, 0.0, 3.0)) < 1.25:
		_fail("FourRoomMVP locker placement is too close to P_BC door.")
		return false
	if _xz_distance(locker.global_position, Vector3(3.0, 0.0, 6.0)) < 1.25:
		_fail("FourRoomMVP locker placement is too close to P_CD door.")
		return false
	if _xz_distance(locker.global_position, Vector3(6.0, 0.0, 6.0)) < 1.25:
		_fail("FourRoomMVP locker placement is too close to Room_C center.")
		return false
	var front := locker.global_transform.basis * Vector3(0.0, 0.0, 1.0)
	front.y = 0.0
	if front.length_squared() <= 0.0001 or front.normalized().dot(Vector3.LEFT) < 0.95:
		_fail("FourRoomMVP locker front should face inward from the east wall.")
		return false

	root.remove_child(scene)
	scene.free()
	return true

func _xz_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))

func _validate_interact_input_action() -> bool:
	if not InputMap.has_action("interact"):
		_fail("Input action `interact` is missing.")
		return false
	for event in InputMap.action_get_events("interact"):
		var key_event := event as InputEventKey
		if key_event != null and key_event.physical_keycode == KEY_E:
			return true
	_fail("Input action `interact` must be bound to E.")
	return false

func _count_mesh_instances(node: Node) -> int:
	var count := 1 if node is MeshInstance3D else 0
	for child in node.get_children():
		count += _count_mesh_instances(child)
	return count

func _count_named_meshes(node: Node, token: String) -> int:
	var count := 0
	if node is MeshInstance3D and node.name.to_lower().contains(token):
		count += 1
	for child in node.get_children():
		count += _count_named_meshes(child, token)
	return count

func _combined_mesh_aabb(node: Node3D) -> AABB:
	var state := {
		"has_aabb": false,
		"aabb": AABB(),
	}
	_accumulate_mesh_aabb(node, Transform3D.IDENTITY, state)
	return state["aabb"]

func _accumulate_mesh_aabb(node: Node, parent_transform: Transform3D, state: Dictionary) -> void:
	var current_transform := parent_transform
	var spatial := node as Node3D
	if spatial != null:
		current_transform = parent_transform * spatial.transform
	var mesh := node as MeshInstance3D
	if mesh != null:
		var mesh_aabb := _transformed_aabb(mesh, current_transform)
		if bool(state["has_aabb"]):
			state["aabb"] = (state["aabb"] as AABB).merge(mesh_aabb)
		else:
			state["aabb"] = mesh_aabb
			state["has_aabb"] = true
	for child in node.get_children():
		_accumulate_mesh_aabb(child, current_transform, state)

func _transformed_aabb(mesh: MeshInstance3D, mesh_transform: Transform3D) -> AABB:
	var local := mesh.get_aabb()
	var corners: Array[Vector3] = [
		local.position,
		local.position + Vector3(local.size.x, 0.0, 0.0),
		local.position + Vector3(0.0, local.size.y, 0.0),
		local.position + Vector3(0.0, 0.0, local.size.z),
		local.position + Vector3(local.size.x, local.size.y, 0.0),
		local.position + Vector3(local.size.x, 0.0, local.size.z),
		local.position + Vector3(0.0, local.size.y, local.size.z),
		local.position + local.size,
	]
	var first: Vector3 = mesh_transform * corners[0]
	var result := AABB(first, Vector3.ZERO)
	for i in range(1, corners.size()):
		result = result.expand(mesh_transform * corners[i])
	return result

func _fail(message: String) -> void:
	push_error("HIDEABLE_LOCKER_VALIDATION FAIL: %s" % message)
	quit(1)
