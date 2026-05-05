extends SceneTree

const SCENE_PATH := "res://scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn"
const OUTPUT_PATH := "res://artifacts/screenshots/proc_maze_exit_overview_marked_20260505.png"
const MAIN_EXIT_DOOR_FRAME_PATH := "LevelRoot/Geometry/Walls/DoorFrame_E_N16_N17"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if not ResourceLoader.exists(SCENE_PATH):
		_fail("missing scene: %s" % SCENE_PATH)
		return
	var packed := load(SCENE_PATH) as PackedScene
	var root := packed.instantiate() as Node3D
	if root == null:
		_fail("scene root is not Node3D")
		return
	get_root().add_child(root)
	current_scene = root

	if root.has_method("rebuild"):
		var result: Dictionary = root.call("rebuild")
		if not bool(result.get("ok", false)):
			_fail("proc maze rebuild failed before capture")
			return

	await process_frame
	await physics_frame
	await process_frame

	var camera := _find_current_camera(root)
	var exit_marker := _find_marker_by_type(root, "Exit")
	var exit_door := root.get_node_or_null(MAIN_EXIT_DOOR_FRAME_PATH) as Node3D
	if camera == null:
		_fail("current preview camera is missing")
		return
	if exit_marker == null:
		_fail("Exit marker is missing")
		return
	if exit_door == null:
		_fail("main exit door frame is missing: %s" % MAIN_EXIT_DOOR_FRAME_PATH)
		return

	var image := get_root().get_texture().get_image()
	var image_size := Vector2(float(image.get_width()), float(image.get_height()))
	var viewport_size := get_root().get_visible_rect().size
	var scale := Vector2(image_size.x / viewport_size.x, image_size.y / viewport_size.y)
	var door_px := _screen_to_image(camera.unproject_position(exit_door.global_position + Vector3(0.0, 1.1, 0.0)), scale)
	var marker_px := _screen_to_image(camera.unproject_position(exit_marker.global_position + Vector3(0.0, 1.1, 0.0)), scale)

	_draw_line(image, door_px, marker_px, Color(1.0, 0.14, 0.06, 1.0), 4)
	_draw_circle(image, marker_px, 66, Color(1.0, 0.62, 0.05, 1.0), 5)
	_draw_circle(image, door_px, 42, Color(1.0, 0.04, 0.02, 1.0), 7)
	_draw_cross(image, door_px, 16, Color(1.0, 0.04, 0.02, 1.0), 5)

	var error := image.save_png(OUTPUT_PATH)
	if error != OK:
		_fail("save failed: %s" % str(error))
		return
	print("PROC_MAZE_EXIT_OVERVIEW_CAPTURE PASS path=%s exit_marker=%s marker_pos=%s door=%s door_pos=%s" % [
		OUTPUT_PATH,
		exit_marker.name,
		str(exit_marker.global_position),
		exit_door.name,
		str(exit_door.global_position),
	])
	quit(0)

func _find_current_camera(root: Node) -> Camera3D:
	for node in _all_nodes(root):
		var camera := node as Camera3D
		if camera != null and camera.current:
			return camera
	return null

func _find_marker_by_type(root: Node, marker_type: String) -> Node3D:
	for node in _all_nodes(root):
		var marker := node as Node3D
		if marker == null:
			continue
		if str(marker.get("marker_type")) == marker_type:
			return marker
	return null

func _all_nodes(root: Node) -> Array:
	var result := [root]
	for child in root.get_children():
		result.append_array(_all_nodes(child))
	return result

func _screen_to_image(screen_position: Vector2, scale: Vector2) -> Vector2i:
	return Vector2i(roundi(screen_position.x * scale.x), roundi(screen_position.y * scale.y))

func _draw_circle(image: Image, center: Vector2i, radius: int, color: Color, thickness: int) -> void:
	var outer := radius
	var inner := maxi(0, radius - thickness)
	for y in range(center.y - outer, center.y + outer + 1):
		for x in range(center.x - outer, center.x + outer + 1):
			if x < 0 or x >= image.get_width() or y < 0 or y >= image.get_height():
				continue
			var dx := x - center.x
			var dy := y - center.y
			var distance_sq := dx * dx + dy * dy
			if distance_sq <= outer * outer and distance_sq >= inner * inner:
				image.set_pixel(x, y, color)

func _draw_cross(image: Image, center: Vector2i, radius: int, color: Color, thickness: int) -> void:
	_draw_line(image, center + Vector2i(-radius, 0), center + Vector2i(radius, 0), color, thickness)
	_draw_line(image, center + Vector2i(0, -radius), center + Vector2i(0, radius), color, thickness)

func _draw_line(image: Image, a: Vector2i, b: Vector2i, color: Color, thickness: int) -> void:
	var radius := maxi(1, thickness / 2)
	for oy in range(-radius, radius + 1):
		for ox in range(-radius, radius + 1):
			if ox * ox + oy * oy <= radius * radius:
				_draw_single_line(image, a + Vector2i(ox, oy), b + Vector2i(ox, oy), color)

func _draw_single_line(image: Image, a: Vector2i, b: Vector2i, color: Color) -> void:
	var x0 := a.x
	var y0 := a.y
	var x1 := b.x
	var y1 := b.y
	var dx := absi(x1 - x0)
	var sx := 1 if x0 < x1 else -1
	var dy := -absi(y1 - y0)
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	while true:
		if x0 >= 0 and x0 < image.get_width() and y0 >= 0 and y0 < image.get_height():
			image.set_pixel(x0, y0, color)
		if x0 == x1 and y0 == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy

func _fail(message: String) -> void:
	push_error("PROC_MAZE_EXIT_OVERVIEW_CAPTURE FAIL %s" % message)
	quit(1)
