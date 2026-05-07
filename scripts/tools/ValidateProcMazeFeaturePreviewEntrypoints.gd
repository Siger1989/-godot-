extends SceneTree

const NO_CEILING_SCENE := "res://scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn"
const FEATURE_ROOM_SCENE := "res://scenes/tests/Test_ProcMazeMap_FeatureRoomPreview.tscn"
const TARGET_MODULE_ID := "N05"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var no_ceiling := await _load_scene(NO_CEILING_SCENE)
	if no_ceiling == null:
		return
	var labels := no_ceiling.get_node_or_null("FeaturePreviewLabels")
	if labels == null:
		_fail("no-ceiling preview is missing FeaturePreviewLabels")
		return
	for label_name in ["FeatureLabel_N05", "FeatureLabel_B28", "FeatureLabel_B30"]:
		if labels.get_node_or_null(label_name) == null:
			_fail("no-ceiling preview is missing %s" % label_name)
			return
	no_ceiling.queue_free()
	await process_frame

	var feature_room := await _load_scene(FEATURE_ROOM_SCENE)
	if feature_room == null:
		return
	for _index in range(8):
		await process_frame
		await physics_frame
	var player := feature_room.get_node_or_null("PlayerRoot/Player") as Node3D
	var target_module := _find_module_by_id(feature_room, TARGET_MODULE_ID)
	if player == null:
		_fail("feature-room preview did not create player")
		return
	if target_module == null:
		_fail("feature-room preview did not build target module %s" % TARGET_MODULE_ID)
		return
	var player_distance := _flat_distance(player.global_position, target_module.global_position)
	if player_distance > 1.2:
		_fail("feature-room preview did not start near %s: distance=%.3f" % [TARGET_MODULE_ID, player_distance])
		return
	print("PROC_MAZE_FEATURE_PREVIEW_ENTRYPOINTS PASS labels=true start_module=%s distance=%.3f" % [TARGET_MODULE_ID, player_distance])
	quit(0)

func _load_scene(scene_path: String) -> Node3D:
	var packed := load(scene_path) as PackedScene
	if packed == null:
		_fail("missing scene: %s" % scene_path)
		return null
	var scene := packed.instantiate() as Node3D
	if scene == null:
		_fail("scene root is not Node3D: %s" % scene_path)
		return null
	root.add_child(scene)
	await process_frame
	return scene

func _find_module_by_id(scene: Node, module_id: String) -> Node3D:
	var modules_root := scene.get_node_or_null("LevelRoot/Geometry/Modules") as Node3D
	if modules_root == null:
		return null
	for child in modules_root.get_children():
		var module := child as Node3D
		if module != null and String(module.get_meta("id", "")) == module_id:
			return module
	return null

func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))

func _fail(message: String) -> void:
	push_error("PROC_MAZE_FEATURE_PREVIEW_ENTRYPOINTS FAIL %s" % message)
	quit(1)
