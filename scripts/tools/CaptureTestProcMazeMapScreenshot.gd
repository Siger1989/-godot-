extends SceneTree

const SCENE_PATH := "res://scenes/tests/Test_ProcMazeMap.tscn"
const OUTPUT_PATH := "res://artifacts/screenshots/test_proc_maze_map.png"

func _init() -> void:
	if not ResourceLoader.exists(SCENE_PATH):
		push_error("TEST_PROC_MAZE_SCREENSHOT FAIL missing scene: %s" % SCENE_PATH)
		quit(1)
		return
	var packed = load(SCENE_PATH) as PackedScene
	var root = packed.instantiate() as Node3D
	get_root().add_child(root)
	await process_frame
	if OS.get_environment("CAPTURE_MODE") == "prop_focus":
		_focus_camera_on_prop(root)
	elif OS.get_environment("CAPTURE_MODE") == "guidance_focus":
		_focus_camera_on_guidance_arrow(root)
	elif OS.get_environment("CAPTURE_MODE") == "guidance_far":
		_focus_camera_on_guidance_arrow(root, false)
	elif OS.get_environment("CAPTURE_MODE") == "guidance_near_exit":
		_focus_camera_on_guidance_arrow(root, true)
	elif OS.get_environment("CAPTURE_MODE") == "monster_key":
		_focus_camera_on_red_monster_key(root)
	await process_frame
	await process_frame
	var image = get_root().get_texture().get_image()
	var output_path := OS.get_environment("CAPTURE_OUTPUT")
	if output_path.is_empty():
		output_path = OUTPUT_PATH
	var error = image.save_png(output_path)
	if error != OK:
		push_error("TEST_PROC_MAZE_SCREENSHOT FAIL save=%s" % str(error))
		quit(1)
		return
	print("TEST_PROC_MAZE_SCREENSHOT PASS path=%s" % output_path)
	quit(0)

func _focus_camera_on_prop(root: Node3D) -> void:
	var target := _find_preferred_prop(root)
	if target == null:
		return
	for camera in _find_cameras(root):
		camera.current = false
	var camera := Camera3D.new()
	camera.name = "PropFocusCamera"
	camera.current = true
	camera.fov = 48.0
	root.add_child(camera)
	var focus := target.global_position + Vector3(0.0, 0.8, 0.0)
	var front := target.global_transform.basis.z
	front.y = 0.0
	if front.length_squared() <= 0.001:
		front = Vector3.FORWARD
	else:
		front = front.normalized()
	var right := target.global_transform.basis.x
	right.y = 0.0
	if right.length_squared() <= 0.001:
		right = Vector3.RIGHT
	else:
		right = right.normalized()
	camera.look_at_from_position(focus + front * 2.45 + right * 0.55 + Vector3.UP * 0.95, focus, Vector3.UP)

func _focus_camera_on_guidance_arrow(root: Node3D, prefer_near_exit := false) -> void:
	var target := _find_guidance_arrow_by_distance(root, prefer_near_exit)
	if target == null:
		target = _find_preferred_guidance_arrow(root)
	if target == null:
		return
	for camera in _find_cameras(root):
		camera.current = false
	var camera := Camera3D.new()
	camera.name = "GuidanceFocusCamera"
	camera.current = true
	camera.fov = 42.0
	root.add_child(camera)
	var normal := target.global_transform.basis.z
	normal.y = 0.0
	if normal.length_squared() <= 0.001:
		normal = Vector3.FORWARD
	else:
		normal = normal.normalized()
	var focus := target.global_position
	camera.look_at_from_position(focus + normal * 1.65 + Vector3.UP * 0.08, focus, Vector3.UP)

func _focus_camera_on_red_monster_key(root: Node3D) -> void:
	var target := _find_red_monster(root)
	if target == null:
		return
	for camera in _find_cameras(root):
		camera.current = false
	var camera := Camera3D.new()
	camera.name = "RedMonsterFocusCamera"
	camera.current = true
	camera.fov = 38.0
	root.add_child(camera)
	var forward := -target.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() <= 0.001:
		forward = Vector3.FORWARD
	else:
		forward = forward.normalized()
	var focus := target.global_transform * Vector3(0.0, 1.18, -0.18)
	camera.look_at_from_position(focus + forward * 1.55 + Vector3.UP * 0.06, focus, Vector3.UP)

func _find_preferred_prop(root: Node) -> Node3D:
	var fallback: Node3D = null
	for node in _all_nodes(root):
		var node3d := node as Node3D
		if node3d == null or not node3d.is_in_group("proc_maze_prop"):
			continue
		if String(node3d.get_meta("proc_maze_prop_id", "")) == "HideLocker_A":
			return node3d
		if fallback == null and String(node3d.get_meta("placement_surface", "")) == "floor":
			fallback = node3d
	return fallback

func _find_preferred_guidance_arrow(root: Node) -> Node3D:
	var fallback: Node3D = null
	for node in _all_nodes(root):
		var node3d := node as Node3D
		if node3d == null or not node3d.is_in_group("proc_guidance_graffiti"):
			continue
		if String(node3d.get_meta("owner_module_id", "")) == "N00":
			return node3d
		if fallback == null:
			fallback = node3d
	return fallback

func _find_guidance_arrow_by_distance(root: Node, nearest_to_exit: bool) -> Node3D:
	var selected: Node3D = null
	var selected_distance := INF if nearest_to_exit else -INF
	for node in _all_nodes(root):
		var node3d := node as Node3D
		if node3d == null or not node3d.is_in_group("proc_guidance_graffiti"):
			continue
		var distance := float(node3d.get_meta("path_distance_to_exit", 0))
		if selected == null:
			selected = node3d
			selected_distance = distance
			continue
		if nearest_to_exit and distance < selected_distance:
			selected = node3d
			selected_distance = distance
		elif not nearest_to_exit and distance > selected_distance:
			selected = node3d
			selected_distance = distance
	return selected

func _find_red_monster(root: Node) -> Node3D:
	for node in _all_nodes(root):
		var node3d := node as Node3D
		if node3d != null and node3d.is_in_group("red_monster"):
			return node3d
	return null

func _find_cameras(root: Node) -> Array[Camera3D]:
	var result: Array[Camera3D] = []
	for node in _all_nodes(root):
		var camera := node as Camera3D
		if camera != null:
			result.append(camera)
	return result

func _all_nodes(root: Node) -> Array:
	var result := [root]
	for child in root.get_children():
		result.append_array(_all_nodes(child))
	return result
