extends SceneTree

const PLAYER_SCENE_PATH := "res://scenes/modules/PlayerModule.tscn"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_release_test_actions()

	var packed := load(PLAYER_SCENE_PATH) as PackedScene
	if packed == null:
		_fail("missing player scene")
		return

	var scene := Node3D.new()
	scene.name = "PlayerCrouchPoseValidationRoot"
	root.add_child(scene)

	var player_root := Node3D.new()
	player_root.name = "PlayerRoot"
	scene.add_child(player_root)

	var camera_rig := Node3D.new()
	camera_rig.name = "CameraRig"
	scene.add_child(camera_rig)
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera_rig.add_child(camera)

	var player := packed.instantiate() as CharacterBody3D
	if player == null:
		_fail("player scene did not instantiate as CharacterBody3D")
		return
	player.name = "Player"
	player_root.add_child(player)

	await process_frame
	await physics_frame

	for method_name in [
		"debug_get_crouch_visual_amount",
		"debug_get_visual_root_scale",
		"debug_get_visual_root_rotation_x",
		"debug_get_crouch_bone_pose_summary",
		"debug_get_collision_height",
		"debug_get_collision_center_y",
	]:
		if not player.has_method(method_name):
			_fail("player is missing crouch pose debug method: %s" % method_name)
			return

	var standing_scale := player.call("debug_get_visual_root_scale") as Vector3
	var standing_rotation_x := float(player.call("debug_get_visual_root_rotation_x"))
	var standing_bone_pose := player.call("debug_get_crouch_bone_pose_summary") as Dictionary
	var standing_collision_height := float(player.call("debug_get_collision_height"))
	var standing_collision_y := float(player.call("debug_get_collision_center_y"))
	if standing_scale.y <= 0.0 or standing_collision_height <= 0.0:
		_fail("standing crouch baseline is invalid")
		return
	if not bool(standing_bone_pose.get("has_skeleton", false)) or int(standing_bone_pose.get("bone_count", 0)) < 6:
		_fail("standing crouch baseline has no usable skeleton pose summary")
		return

	Input.action_press(&"crouch", 1.0)
	await _wait_physics_frames(32)

	if not bool(player.call("debug_is_crouching")):
		_fail("C key did not put the player in crouch state")
		return
	var crouch_amount := float(player.call("debug_get_crouch_visual_amount"))
	var crouch_scale := player.call("debug_get_visual_root_scale") as Vector3
	var crouch_rotation_x := float(player.call("debug_get_visual_root_rotation_x"))
	var crouch_bone_pose := player.call("debug_get_crouch_bone_pose_summary") as Dictionary
	var crouch_collision_height := float(player.call("debug_get_collision_height"))
	var crouch_collision_y := float(player.call("debug_get_collision_center_y"))

	if crouch_amount < 0.90:
		_fail("crouch visual blend did not reach crouched pose: %.3f" % crouch_amount)
		return
	if crouch_scale.distance_to(standing_scale) > 0.005:
		_fail("crouch must not compress/scale ModelRoot: stand=%s crouch=%s" % [str(standing_scale), str(crouch_scale)])
		return
	if absf(crouch_rotation_x - standing_rotation_x) > deg_to_rad(0.5):
		_fail("crouch must not lean the whole ModelRoot: stand=%.4f crouch=%.4f" % [standing_rotation_x, crouch_rotation_x])
		return
	var standing_hips := standing_bone_pose.get("hips_position", Vector3.ZERO) as Vector3
	var crouch_hips := crouch_bone_pose.get("hips_position", Vector3.ZERO) as Vector3
	if crouch_hips.y > standing_hips.y - 20.0:
		_fail("crouch did not lower the hips bone enough: stand=%.3f crouch=%.3f" % [standing_hips.y, crouch_hips.y])
		return
	if _pose_rotation_delta(standing_bone_pose, crouch_bone_pose, "spine2") < deg_to_rad(4.0):
		_fail("crouch did not change spine bones into a crouch pose")
		return
	if _pose_rotation_delta(standing_bone_pose, crouch_bone_pose, "left_leg") < deg_to_rad(12.0):
		_fail("crouch did not bend the left leg bone")
		return
	if _pose_rotation_delta(standing_bone_pose, crouch_bone_pose, "right_leg") < deg_to_rad(12.0):
		_fail("crouch did not bend the right leg bone")
		return
	if crouch_collision_height >= standing_collision_height * 0.82:
		_fail("crouch collision did not shrink: stand=%.3f crouch=%.3f" % [standing_collision_height, crouch_collision_height])
		return
	if crouch_collision_y >= standing_collision_y:
		_fail("crouch collision center did not lower: stand=%.3f crouch=%.3f" % [standing_collision_y, crouch_collision_y])
		return

	Input.action_release(&"crouch")
	await _wait_physics_frames(32)

	var restored_amount := float(player.call("debug_get_crouch_visual_amount"))
	var restored_scale := player.call("debug_get_visual_root_scale") as Vector3
	var restored_bone_pose := player.call("debug_get_crouch_bone_pose_summary") as Dictionary
	var restored_collision_height := float(player.call("debug_get_collision_height"))
	if restored_amount > 0.10:
		_fail("crouch visual blend did not restore after releasing C: %.3f" % restored_amount)
		return
	if restored_scale.distance_to(standing_scale) > 0.01:
		_fail("visual scale did not restore after crouch: stand=%s restored=%s" % [str(standing_scale), str(restored_scale)])
		return
	if absf(restored_collision_height - standing_collision_height) > 0.03:
		_fail("collision height did not restore after crouch: stand=%.3f restored=%.3f" % [standing_collision_height, restored_collision_height])
		return
	var restored_hips := restored_bone_pose.get("hips_position", Vector3.ZERO) as Vector3
	if restored_hips.distance_to(standing_hips) > 4.0:
		_fail("hips bone did not restore after crouch: stand=%s restored=%s" % [str(standing_hips), str(restored_hips)])
		return

	print("PLAYER_CROUCH_POSE_VALIDATION PASS crouch_amount=%.3f scale=%s hips_y=%.3f collision=%.3f" % [crouch_amount, str(crouch_scale), crouch_hips.y, crouch_collision_height])
	_release_test_actions()
	quit(0)

func _pose_rotation_delta(standing_pose: Dictionary, crouch_pose: Dictionary, key: String) -> float:
	var standing_key := "%s_rotation" % key
	var crouch_key := "%s_rotation" % key
	if not standing_pose.has(standing_key) or not crouch_pose.has(crouch_key):
		return 0.0
	var standing_rotation := standing_pose[standing_key] as Quaternion
	var crouch_rotation := crouch_pose[crouch_key] as Quaternion
	return standing_rotation.angle_to(crouch_rotation)

func _wait_physics_frames(frame_count: int) -> void:
	for _frame_index in range(frame_count):
		await physics_frame
	await process_frame

func _release_test_actions() -> void:
	_release_action_if_present(&"move_forward")
	_release_action_if_present(&"move_back")
	_release_action_if_present(&"move_left")
	_release_action_if_present(&"move_right")
	_release_action_if_present(&"sprint")
	_release_action_if_present(&"crouch")

func _release_action_if_present(action_name: StringName) -> void:
	if InputMap.has_action(action_name):
		Input.action_release(action_name)

func _fail(message: String) -> void:
	_release_test_actions()
	push_error("PLAYER_CROUCH_POSE_VALIDATION FAIL %s" % message)
	quit(1)
