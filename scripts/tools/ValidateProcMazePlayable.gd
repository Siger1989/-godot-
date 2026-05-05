extends SceneTree

const SCENE_PATH := "res://scenes/tests/Test_ProcMazeMap.tscn"
const MIN_FORWARD_DELTA := 1.2
const MAX_ALLOWED_DROP := -0.2
const PHYSICS_STEPS := 120

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if not ResourceLoader.exists(SCENE_PATH):
		_fail("missing scene: %s" % SCENE_PATH)
		return

	var packed = load(SCENE_PATH) as PackedScene
	if packed == null:
		_fail("cannot load scene: %s" % SCENE_PATH)
		return

	var root = packed.instantiate() as Node3D
	if root == null:
		_fail("scene root is not Node3D.")
		return
	get_root().add_child(root)

	if root.has_method("rebuild"):
		var result: Dictionary = root.rebuild()
		if not bool(result.get("ok", false)):
			_fail("proc maze rebuild failed before playable validation.")
			return

	await process_frame
	await physics_frame

	var player = root.get_node_or_null("PlayerRoot/Player") as CharacterBody3D
	var camera_rig = root.get_node_or_null("CameraRig") as Node3D
	var camera = root.get_node_or_null("CameraRig/Camera3D") as Camera3D
	var marker = _find_marker_by_type(root, "Entrance")
	var systems = root.get_node_or_null("Systems")
	var lighting = root.get_node_or_null("Systems/LightingController")
	var tuning_panel = root.get_node_or_null("Systems/LightingTuningPanel")
	var occlusion = root.get_node_or_null("Systems/ForegroundOcclusion")

	if player == null:
		_fail("PlayerRoot/Player is missing.")
		return
	if camera_rig == null or camera == null:
		_fail("CameraRig/Camera3D is missing.")
		return
	if marker == null:
		_fail("Entrance marker is missing.")
		return
	if systems == null or lighting == null or tuning_panel == null or occlusion == null:
		_fail("runtime systems are missing.")
		return
	if not tuning_panel.has_method("open_panel") or not tuning_panel.has_method("close_panel") or not tuning_panel.has_method("is_panel_open"):
		_fail("lighting tuning panel does not expose runtime open/close methods.")
		return
	if tuning_panel.has_method("debug_get_control_count") and int(tuning_panel.call("debug_get_control_count")) < 6:
		_fail("lighting tuning panel did not build enough controls.")
		return
	tuning_panel.call("open_panel")
	await process_frame
	if not bool(tuning_panel.call("is_panel_open")):
		_fail("lighting tuning panel did not open.")
		return
	tuning_panel.call("close_panel")
	await process_frame
	if bool(tuning_panel.call("is_panel_open")):
		_fail("lighting tuning panel did not close.")
		return
	if not camera.current:
		_fail("gameplay camera is not current.")
		return
	if player.global_position.distance_to(marker.global_position) > 0.25:
		_fail("player was not placed at entrance marker. player=%s marker=%s" % [str(player.global_position), str(marker.global_position)])
		return

	var start_position = player.global_position
	Input.action_press("move_forward")
	for _step in range(PHYSICS_STEPS):
		await physics_frame
	Input.action_release("move_forward")
	await physics_frame

	var end_position = player.global_position
	if end_position.y < MAX_ALLOWED_DROP:
		_fail("player dropped below floor: y=%s" % str(end_position.y))
		return
	if end_position.x - start_position.x < MIN_FORWARD_DELTA:
		_fail("player did not move through the entrance path. start=%s end=%s" % [str(start_position), str(end_position)])
		return

	print("PROC_MAZE_PLAYABLE_VALIDATION PASS start=%s end=%s moved_x=%.3f camera_current=%s" % [
		str(start_position),
		str(end_position),
		end_position.x - start_position.x,
		str(camera.current),
	])
	quit(0)

func _find_marker_by_type(root: Node, marker_type: String) -> Node3D:
	var markers = root.get_node_or_null("LevelRoot/Markers")
	if markers == null:
		return null
	for marker in markers.get_children():
		var marker_node = marker as Node3D
		if marker_node == null:
			continue
		if String(marker_node.get("marker_type")) == marker_type:
			return marker_node
	return null

func _fail(message: String) -> void:
	push_error("PROC_MAZE_PLAYABLE_VALIDATION FAIL %s" % message)
	quit(1)
