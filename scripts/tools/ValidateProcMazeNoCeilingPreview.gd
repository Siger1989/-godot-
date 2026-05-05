extends SceneTree

const SCENE_PATH := "res://scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn"

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

	if not bool(root.get("preview_without_ceiling")):
		_fail("preview_without_ceiling export is not enabled.")
		return
	if not bool(root.get("preview_full_map_camera")):
		_fail("preview_full_map_camera export is not enabled.")
		return

	var result = {}
	if root.has_method("rebuild"):
		result = root.rebuild()
	if not bool(result.get("ok", false)):
		_fail("proc maze rebuild failed.")
		return

	await process_frame
	await physics_frame

	var total_rooms = int(result.get("total_rooms", 0))
	var ceilings = _get_nodes_in_group(root, "ceiling")
	var ceiling_names = _find_nodes_by_name_prefix(root, "Ceiling_")
	var panels = _get_nodes_in_group(root, "ceiling_light_panel")
	var lights = _get_nodes_in_group(root, "ceiling_light")
	var floors = _get_nodes_in_group(root, "floor_visual")
	var walls = _get_nodes_in_group(root, "proc_wall_body")
	var openings = _get_nodes_in_group(root, "proc_wall_opening")
	var frames = _get_nodes_in_group(root, "proc_door_frame")
	var player = root.get_node_or_null("PlayerRoot/Player") as CharacterBody3D
	var gameplay_camera = root.get_node_or_null("CameraRig/Camera3D") as Camera3D
	var camera = root.get_node_or_null("Camera3D") as Camera3D

	var issues: Array[String] = []
	var expected_panels = int(result.get("active_light_fixture_count", result.get("active_light_count", panels.size())))
	var expected_light_sources = int(result.get("active_light_source_count", lights.size()))
	if not ceilings.is_empty():
		issues.append("ceiling group should be empty, found %d." % ceilings.size())
	if not ceiling_names.is_empty():
		issues.append("Ceiling_* nodes should be absent, found %d." % ceiling_names.size())
	if panels.size() != expected_panels:
		issues.append("ceiling light panels mismatch: %d expected active_light_fixture_count %d." % [panels.size(), expected_panels])
	if lights.size() != expected_light_sources:
		issues.append("ceiling light sources mismatch: %d expected active_light_source_count %d." % [lights.size(), expected_light_sources])
	if expected_light_sources < expected_panels:
		issues.append("ceiling light source count must be at least panel count; sources=%d panels=%d." % [expected_light_sources, expected_panels])
	if expected_panels >= total_rooms:
		issues.append("not every space should have a ceiling light fixture; active=%d total=%d." % [expected_panels, total_rooms])
	if floors.size() != total_rooms:
		issues.append("floor visual count mismatch: %d expected %d." % [floors.size(), total_rooms])
	if walls.is_empty() and openings.is_empty():
		issues.append("walls/openings are missing.")
	if frames.size() != openings.size():
		issues.append("door-frame/opening count mismatch: frames=%d openings=%d." % [frames.size(), openings.size()])
	if player != null:
		issues.append("full-map preview should not include PlayerRoot/Player.")
	if gameplay_camera != null:
		issues.append("full-map preview should not include CameraRig/Camera3D.")
	if camera == null or not camera.current:
		issues.append("full-map preview Camera3D is missing or not current.")
	elif camera.projection != Camera3D.PROJECTION_ORTHOGONAL:
		issues.append("full-map preview Camera3D must use orthogonal projection.")
	elif camera.size < 85.0:
		issues.append("full-map preview Camera3D size is too small: %s." % str(camera.size))
	elif not bool(camera.get_meta("preview_camera", false)):
		issues.append("full-map preview Camera3D is missing preview metadata.")

	if not issues.is_empty():
		for issue in issues:
			push_error(issue)
		_fail("validation issues found.")
		return

	print("PROC_MAZE_NO_CEILING_PREVIEW_VALIDATION PASS rooms=%d floors=%d walls=%d openings=%d frames=%d lights=%d ceilings=%d camera_size=%.2f player=%s" % [
		total_rooms,
		floors.size(),
		walls.size(),
		openings.size(),
		frames.size(),
		lights.size(),
		ceilings.size(),
		camera.size,
		str(player != null),
	])
	quit(0)

func _get_nodes_in_group(root: Node, group_name: String) -> Array:
	var result = []
	_collect_nodes_in_group(root, group_name, result)
	return result

func _collect_nodes_in_group(node: Node, group_name: String, result: Array) -> void:
	if node.is_in_group(group_name):
		result.append(node)
	for child in node.get_children():
		_collect_nodes_in_group(child, group_name, result)

func _find_nodes_by_name_prefix(root: Node, prefix: String) -> Array:
	var result = []
	_collect_nodes_by_name_prefix(root, prefix, result)
	return result

func _collect_nodes_by_name_prefix(node: Node, prefix: String, result: Array) -> void:
	if node.name.begins_with(prefix):
		result.append(node)
	for child in node.get_children():
		_collect_nodes_by_name_prefix(child, prefix, result)

func _fail(message: String) -> void:
	push_error("PROC_MAZE_NO_CEILING_PREVIEW_VALIDATION FAIL %s" % message)
	quit(1)
