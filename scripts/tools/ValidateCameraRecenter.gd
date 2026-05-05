extends SceneTree

const SCENE_PATH := "res://scenes/mvp/FourRoomMVP.tscn"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_release_test_actions()

	var scene_resource := load(SCENE_PATH) as PackedScene
	if scene_resource == null:
		_fail("Failed to load %s." % SCENE_PATH)
		return

	var scene := scene_resource.instantiate() as Node3D
	root.add_child(scene)
	await process_frame
	await physics_frame
	await process_frame

	var camera_rig := scene.get_node_or_null("CameraRig") as Node3D
	var player := scene.get_node_or_null("PlayerRoot/Player") as CharacterBody3D
	if camera_rig == null or player == null:
		_fail("CameraRig or player was missing.")
		return

	_release_test_actions()
	player.velocity = Vector3.ZERO
	await _wait_frames(6)

	var initial_yaw := float(camera_rig.get("_yaw"))
	camera_rig.call("_rotate_view", Vector2(-900.0, 0.0), 0.003)
	var dragged_yaw := float(camera_rig.get("_yaw"))
	var free_orbit_delta := _abs_angle_delta(initial_yaw, dragged_yaw)
	if free_orbit_delta <= deg_to_rad(120.0):
		_fail("Manual camera yaw still appears clamped near the old 180-degree front range.")
		return

	await _wait_frames(90)
	var stationary_yaw := float(camera_rig.get("_yaw"))
	var stationary_delta := _abs_angle_delta(dragged_yaw, stationary_yaw)
	if stationary_delta > 0.03:
		_fail("Free camera yaw changed while the player was stationary.")
		return

	Input.action_press(&"move_forward", 1.0)
	await _wait_frames(90)
	var moving_yaw := float(camera_rig.get("_yaw"))
	var moving_delta := _abs_angle_delta(stationary_yaw, moving_yaw)
	if moving_delta > 0.05:
		_fail("Free camera yaw recentered after player movement started.")
		return

	camera_rig.call("_rotate_view", Vector2(0.0, -900.0), 0.003)
	var min_pitch := float(camera_rig.get("_pitch"))
	if min_pitch < deg_to_rad(-5.0) - 0.01 or min_pitch > deg_to_rad(-5.0) + 0.01:
		_fail("Camera pitch did not clamp to the configured low angle.")
		return

	camera_rig.call("_rotate_view", Vector2(0.0, 900.0), 0.003)
	var max_pitch := float(camera_rig.get("_pitch"))
	if max_pitch < deg_to_rad(12.0) - 0.01 or max_pitch > deg_to_rad(12.0) + 0.01:
		_fail("Camera pitch did not clamp to the configured high angle.")
		return

	_release_test_actions()
	print(
		"CAMERA_FREE_ORBIT_VALIDATION PASS yaw_delta=%.3f stationary_delta=%.3f moving_delta=%.3f pitch=%.3f..%.3f"
		% [free_orbit_delta, stationary_delta, moving_delta, min_pitch, max_pitch]
	)
	quit(0)

func _abs_angle_delta(from_angle: float, to_angle: float) -> float:
	return absf(wrapf(to_angle - from_angle, -PI, PI))

func _wait_frames(frame_count: int) -> void:
	for _frame_index in range(frame_count):
		await process_frame
		await physics_frame

func _release_test_actions() -> void:
	_release_action_if_present(&"move_forward")
	_release_action_if_present(&"move_back")
	_release_action_if_present(&"move_left")
	_release_action_if_present(&"move_right")
	_release_action_if_present(&"sprint")

func _release_action_if_present(action_name: StringName) -> void:
	if InputMap.has_action(action_name):
		Input.action_release(action_name)

func _fail(message: String) -> void:
	_release_test_actions()
	push_error("CAMERA_FREE_ORBIT_VALIDATION FAIL: %s" % message)
	quit(1)
