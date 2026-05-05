extends SceneTree

const SCENE_PATH := "res://scenes/modules/PlayerModule.tscn"
const EXPECTED_MOVEMENT_ANIMATION := "mixamo_com"
const EXPECTED_IDLE_ANIMATION := "idle_generated"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_release_test_actions()

	var scene_resource := load(SCENE_PATH) as PackedScene
	if scene_resource == null:
		_fail("Failed to load %s" % SCENE_PATH)
		return

	var player := scene_resource.instantiate() as CharacterBody3D
	root.add_child(player)
	await process_frame
	await physics_frame

	var animation_player := player.get_node_or_null("ModelRoot/zhujiao/AnimationPlayer") as AnimationPlayer
	if animation_player == null:
		_fail("AnimationPlayer not found at ModelRoot/zhujiao/AnimationPlayer.")
		return
	if not animation_player.has_animation(EXPECTED_MOVEMENT_ANIMATION):
		_fail("Expected animation %s was not found." % EXPECTED_MOVEMENT_ANIMATION)
		return
	if not animation_player.has_animation(EXPECTED_IDLE_ANIMATION):
		_fail("Expected idle animation %s was not generated." % EXPECTED_IDLE_ANIMATION)
		return
	var animation := animation_player.get_animation(EXPECTED_MOVEMENT_ANIMATION)
	if animation == null:
		_fail("Expected animation resource was null.")
		return
	if _has_enabled_position_track(animation):
		_fail("Root-motion POSITION track is still enabled; this can detach the mesh from the collision body.")
		return
	var idle_animation := animation_player.get_animation(EXPECTED_IDLE_ANIMATION)
	if idle_animation == null:
		_fail("Expected idle animation resource was null.")
		return
	if _has_enabled_position_track(idle_animation):
		_fail("Generated idle animation contains an enabled POSITION track.")
		return

	var skeleton := _find_skeleton(player)
	var hips_bone_index := -1
	var initial_hips_position := Vector3.ZERO
	if skeleton != null:
		hips_bone_index = _find_bone_containing(skeleton, "Hips")
		if hips_bone_index >= 0:
			initial_hips_position = skeleton.get_bone_global_pose(hips_bone_index).origin
		var idle_feet_ok := await _validate_idle_feet_balance(animation_player, skeleton)
		if not idle_feet_ok:
			return

	Input.action_press(&"move_forward", 1.0)
	await _wait_physics_frames(90)
	if not _is_playing_expected(animation_player, EXPECTED_MOVEMENT_ANIMATION):
		_fail("Forward movement did not play %s." % EXPECTED_MOVEMENT_ANIMATION)
		return
	if skeleton != null and hips_bone_index >= 0:
		var current_hips_position := skeleton.get_bone_global_pose(hips_bone_index).origin
		if current_hips_position.distance_to(initial_hips_position) > 5.0:
			_fail("Hips bone drifted away from its rest position; root motion is still affecting the visual mesh.")
			return

	Input.action_press(&"sprint", 1.0)
	await _wait_physics_frames(3)
	if not _is_playing_expected(animation_player, EXPECTED_MOVEMENT_ANIMATION):
		_fail("Sprint movement did not play %s." % EXPECTED_MOVEMENT_ANIMATION)
		return

	Input.action_release(&"move_forward")
	Input.action_release(&"sprint")
	Input.action_press(&"move_back", 1.0)
	await _wait_physics_frames(3)
	if not _is_playing_expected(animation_player, EXPECTED_MOVEMENT_ANIMATION):
		_fail("Backpedal movement did not play %s." % EXPECTED_MOVEMENT_ANIMATION)
		return

	Input.action_release(&"move_back")
	await _wait_physics_frames(3)
	if not _is_playing_expected(animation_player, EXPECTED_IDLE_ANIMATION):
		_fail("Idle animation did not play after movement input was released.")
		return

	print("PLAYER_ANIMATION_VALIDATION PASS movement=%s idle=%s" % [EXPECTED_MOVEMENT_ANIMATION, EXPECTED_IDLE_ANIMATION])
	_release_test_actions()
	quit(0)

func _wait_physics_frames(frame_count: int) -> void:
	for _frame_index in range(frame_count):
		await physics_frame

func _is_playing_expected(animation_player: AnimationPlayer, animation_name: String) -> bool:
	return animation_player.is_playing() and animation_player.current_animation == animation_name

func _has_enabled_position_track(animation: Animation) -> bool:
	for track_index in range(animation.get_track_count()):
		if animation.track_get_type(track_index) == Animation.TYPE_POSITION_3D and animation.track_is_enabled(track_index):
			return true
	return false

func _find_skeleton(node: Node) -> Skeleton3D:
	var skeleton := node as Skeleton3D
	if skeleton != null:
		return skeleton
	for child in node.get_children():
		var result := _find_skeleton(child)
		if result != null:
			return result
	return null

func _find_bone_containing(skeleton: Skeleton3D, text: String) -> int:
	for bone_index in range(skeleton.get_bone_count()):
		if skeleton.get_bone_name(bone_index).contains(text):
			return bone_index
	return -1

func _validate_idle_feet_balance(animation_player: AnimationPlayer, skeleton: Skeleton3D) -> bool:
	var left_foot := _find_bone_containing(skeleton, "LeftFoot")
	var right_foot := _find_bone_containing(skeleton, "RightFoot")
	var left_toe := _find_bone_containing(skeleton, "LeftToeBase")
	var right_toe := _find_bone_containing(skeleton, "RightToeBase")
	if left_foot < 0 or right_foot < 0 or left_toe < 0 or right_toe < 0:
		return true

	animation_player.play(EXPECTED_IDLE_ANIMATION)
	animation_player.seek(0.0, true)
	await process_frame

	var foot_delta := absf(
		skeleton.get_bone_global_pose(left_foot).origin.y
		- skeleton.get_bone_global_pose(right_foot).origin.y
	)
	var toe_delta := absf(
		skeleton.get_bone_global_pose(left_toe).origin.y
		- skeleton.get_bone_global_pose(right_toe).origin.y
	)
	if foot_delta > 2.0 or toe_delta > 2.0:
		_fail("Generated idle lower body is not planted: foot_delta=%.2f toe_delta=%.2f" % [foot_delta, toe_delta])
		return false
	return true

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
	push_error("PLAYER_ANIMATION_VALIDATION FAIL: %s" % message)
	quit(1)
