extends SceneTree

const FOUR_ROOM_SCENE_PATH := "res://scenes/mvp/FourRoomMVP.tscn"
const DOOR_SCENE_PATH := "res://assets/backrooms/props/doors/OldOfficeDoor_A.tscn"
const DOOR_GLB_PATH := "res://assets/backrooms/props/doors/OldOfficeDoor_A.glb"
const EXPECTED_POSITION := Vector3(6.0, 0.0, 3.0)
const EXPECTED_PORTAL := "P_BC"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if not _validate_resource():
		return
	if not await _validate_four_room():
		return
	print("BACKROOMS_DOOR_VALIDATION PASS resources=1 placements=1 portal=%s" % EXPECTED_PORTAL)
	quit(0)

func _validate_resource() -> bool:
	if not ResourceLoader.exists(DOOR_GLB_PATH):
		_fail("Missing door GLB: %s." % DOOR_GLB_PATH)
		return false
	if not ResourceLoader.exists(DOOR_SCENE_PATH):
		_fail("Missing door wrapper scene: %s." % DOOR_SCENE_PATH)
		return false
	var packed := load(DOOR_SCENE_PATH) as PackedScene
	if packed == null:
		_fail("Door wrapper failed to load.")
		return false
	var instance := packed.instantiate() as Node3D
	if instance == null:
		_fail("Door wrapper failed to instantiate.")
		return false
	if not instance.has_method("is_open"):
		_fail("Door wrapper root must use DoorComponent behavior.")
		instance.free()
		return false
	if not instance.has_method("interact_from") or not instance.has_method("open_toward_direction"):
		_fail("Door wrapper must expose player interaction methods.")
		instance.free()
		return false
	if instance.get_node_or_null("HingePivot") == null:
		_fail("Door wrapper missing HingePivot child.")
		instance.free()
		return false
	if instance.get_node_or_null("HingePivot/Model") == null:
		_fail("Door wrapper missing HingePivot/Model child.")
		instance.free()
		return false
	if not (instance.get_node_or_null("HingePivot/CollisionBody/Collision") is CollisionShape3D):
		_fail("Door wrapper missing simple collision.")
		instance.free()
		return false
	if _count_mesh_instances(instance) <= 0:
		_fail("Door wrapper has no MeshInstance3D descendants.")
		instance.free()
		return false
	var mesh_aabb := _combined_mesh_aabb(instance)
	var door_top := mesh_aabb.position.y + mesh_aabb.size.y
	if door_top < 2.08:
		_fail("Door mesh is still too short for the frame; top=%.3f." % door_top)
		instance.free()
		return false
	instance.free()
	return true

func _validate_four_room() -> bool:
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

	var doors_root := scene.get_node_or_null("LevelRoot/Doors") as Node3D
	if doors_root == null:
		_fail("FourRoomMVP missing LevelRoot/Doors.")
		return false
	if doors_root.get_child_count() != 1:
		_fail("Expected exactly one selected door placement; found %d." % doors_root.get_child_count())
		return false
	var door := doors_root.get_node_or_null("Door_P_BC_OldOffice_A") as Node3D
	if door == null:
		_fail("Missing Door_P_BC_OldOffice_A placement.")
		return false
	if String(door.get_meta("portal_id", "")) != EXPECTED_PORTAL:
		_fail("Door placement has wrong portal metadata.")
		return false
	if door.global_position.distance_to(EXPECTED_POSITION) > 0.01:
		_fail("Door placement is not centered in %s: %s." % [EXPECTED_PORTAL, door.global_position])
		return false
	if absf(door.rotation.y) > 0.001:
		_fail("Door placement yaw should match x-span P_BC frame.")
		return false
	if not (door.get_node_or_null("HingePivot/CollisionBody/Collision") is CollisionShape3D):
		_fail("Placed door is missing collision.")
		return false

	var door_frame_count: int = get_nodes_in_group("door_frame").size()
	if doors_root.get_child_count() >= door_frame_count:
		_fail("Door placement should not fill every door frame.")
		return false
	if not door.is_in_group("interactive_door"):
		_fail("Placed door is not in interactive_door group.")
		return false

	var builder := scene.get_node_or_null("Systems/SceneBuilder")
	if builder != null and builder.has_method("build"):
		builder.call("build")
		await process_frame
		await physics_frame
	doors_root = scene.get_node_or_null("LevelRoot/Doors") as Node3D
	if doors_root == null:
		_fail("FourRoomMVP missing LevelRoot/Doors after runtime rebuild.")
		return false
	door = doors_root.get_node_or_null("Door_P_BC_OldOffice_A") as Node3D
	if door == null:
		_fail("Door_P_BC_OldOffice_A missing after runtime rebuild.")
		return false
	var portal := scene.get_node_or_null("LevelRoot/Portals/%s" % EXPECTED_PORTAL)
	if portal == null or not portal.has_method("is_open"):
		_fail("P_BC portal missing after runtime rebuild.")
		return false
	var door_node_path: NodePath = portal.get("door_node_path")
	if portal.get_node_or_null(door_node_path) != door:
		_fail("P_BC portal is not relinked to the selected door after runtime rebuild.")
		return false
	if bool(portal.call("is_open")):
		_fail("P_BC portal should read closed door state before interaction.")
		return false
	door.call("interact_from", scene.get_node_or_null("PlayerRoot/Player"), Vector3.BACK)
	if not bool(door.call("is_open")):
		_fail("Door did not open from player interaction.")
		return false
	if not bool(portal.call("is_open")):
		_fail("P_BC portal did not read open door state after interaction.")
		return false
	if absf(float(door.call("get_target_angle_degrees"))) < 80.0:
		_fail("Door interaction did not choose a visible open angle.")
		return false
	for _i in range(24):
		await physics_frame
	var hinge := door.get_node_or_null("HingePivot") as Node3D
	if hinge == null or absf(rad_to_deg(hinge.rotation.y)) < 65.0:
		_fail("Door hinge did not animate far enough open.")
		return false
	door.call("interact_from", scene.get_node_or_null("PlayerRoot/Player"), Vector3.BACK)
	if bool(door.call("is_open")):
		_fail("Second interaction should close the door.")
		return false
	if bool(portal.call("is_open")):
		_fail("P_BC portal should read closed state after second interaction.")
		return false
	if not _validate_interact_input_action():
		return false
	var player := scene.get_node_or_null("PlayerRoot/Player") as Node3D
	if player == null or not player.has_method("_try_interact_with_door"):
		_fail("Player is missing door interaction method.")
		return false
	player.global_position = EXPECTED_POSITION + Vector3(0.0, 0.0, -0.85)
	player.set("_facing_direction", Vector3.BACK)
	player.set("_has_facing_direction", true)
	if not bool(player.call("_try_interact_with_door")):
		_fail("Player E/interact path did not find and open the nearby door.")
		return false
	if not bool(door.call("is_open")):
		_fail("Door should be open after player interaction path.")
		return false

	root.remove_child(scene)
	scene.free()
	return true

func _count_mesh_instances(node: Node) -> int:
	var count := 1 if node is MeshInstance3D else 0
	for child in node.get_children():
		count += _count_mesh_instances(child)
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

func _fail(message: String) -> void:
	push_error("BACKROOMS_DOOR_VALIDATION FAIL: %s" % message)
	quit(1)
