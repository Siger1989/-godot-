extends SceneTree

const SCENE_PATH := "res://scenes/mvp/FourRoomMVP.tscn"
const MIN_WEST_WALL_X := -2.85

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_release_test_actions()

	var scene_resource := load(SCENE_PATH) as PackedScene
	if scene_resource == null:
		_fail("Failed to load %s" % SCENE_PATH)
		return

	var scene := scene_resource.instantiate() as Node3D
	root.add_child(scene)
	await process_frame
	await physics_frame

	var player := scene.get_node_or_null("PlayerRoot/Player") as CharacterBody3D
	var camera_rig := scene.get_node_or_null("CameraRig") as Node3D
	if player == null or camera_rig == null:
		_fail("Player or CameraRig was missing.")
		return

	camera_rig.set_process(false)
	camera_rig.global_transform = Transform3D(Basis(), Vector3.ZERO)
	player.global_position = Vector3(-2.35, 0.05, 0.0)
	player.velocity = Vector3.ZERO
	await physics_frame

	Input.action_press(&"move_left", 1.0)
	await _wait_physics_frames(180)
	Input.action_release(&"move_left")

	if player.global_position.x < MIN_WEST_WALL_X:
		_fail("Player body crossed west wall limit: x=%.3f" % player.global_position.x)
		return

	print("PLAYER_ANIMATION_COLLISION_VALIDATION PASS player_x=%.3f" % player.global_position.x)
	_release_test_actions()
	quit(0)

func _wait_physics_frames(frame_count: int) -> void:
	for _frame_index in range(frame_count):
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
	push_error("PLAYER_ANIMATION_COLLISION_VALIDATION FAIL: %s" % message)
	quit(1)
