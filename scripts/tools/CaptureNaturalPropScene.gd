extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene_path := OS.get_environment("CAPTURE_SCENE_PATH")
	if scene_path.is_empty():
		scene_path = "res://scenes/mvp/FourRoomMVP.tscn"
	var output_path := OS.get_environment("CAPTURE_OUTPUT_PATH")
	if output_path.is_empty():
		output_path = "res://artifacts/screenshots/natural_props_capture.png"
	var mode := OS.get_environment("CAPTURE_MODE")
	if mode.is_empty():
		mode = "four_room"

	var packed := load(scene_path) as PackedScene
	if packed == null:
		_fail("Failed to load %s." % scene_path)
		return
	var scene := packed.instantiate() as Node3D
	if scene == null:
		_fail("Failed to instantiate %s." % scene_path)
		return
	if scene.get("build_on_ready") != null:
		scene.set("build_on_ready", false)
	root.add_child(scene)
	current_scene = scene
	root.size = Vector2i(1280, 720)
	await process_frame
	if mode != "showcase":
		_hide_capture_ceilings(scene)
	if OS.get_environment("CAPTURE_HIDE_PROPS") == "1":
		var props_root := scene.get_node_or_null("LevelRoot/Props") as Node3D
		if props_root != null:
			props_root.visible = false
	if mode == "door_p_bc_open":
		var door := scene.get_node_or_null("LevelRoot/Doors/Door_P_BC_OldOffice_A")
		if door != null and door.has_method("open_toward_direction"):
			door.call("open_toward_direction", Vector3.BACK)
			for _i in range(24):
				await physics_frame

	var camera := Camera3D.new()
	camera.name = "NaturalPropsCaptureCamera"
	camera.fov = 48.0
	scene.add_child(camera)
	match mode:
		"showcase":
			camera.fov = 54.0
			camera.global_position = Vector3(1.4, 6.15, 11.35)
			camera.look_at(Vector3(1.4, 0.85, 1.05), Vector3.UP)
		"room_b":
			camera.global_position = Vector3(3.3, 2.4, -2.9)
			camera.look_at(Vector3(7.3, 0.75, -1.0), Vector3.UP)
		"room_b_close":
			camera.global_position = Vector3(6.7, 1.35, -2.85)
			camera.look_at(Vector3(8.22, 0.46, -2.05), Vector3.UP)
		"room_c":
			camera.global_position = Vector3(3.75, 1.75, 3.15)
			camera.look_at(Vector3(7.35, 0.75, 5.35), Vector3.UP)
		"room_c_chair":
			camera.global_position = Vector3(3.75, 1.25, 6.60)
			camera.look_at(Vector3(5.05, 0.55, 7.82), Vector3.UP)
		"door_p_bc":
			camera.global_position = Vector3(6.0, 1.28, -0.30)
			camera.look_at(Vector3(6.0, 1.02, 3.0), Vector3.UP)
		"door_p_bc_open":
			camera.global_position = Vector3(5.18, 1.30, -0.45)
			camera.look_at(Vector3(6.0, 1.00, 3.0), Vector3.UP)
		"room_a":
			camera.global_position = Vector3(1.7, 1.8, 1.2)
			camera.look_at(Vector3(-1.95, 0.55, -2.22), Vector3.UP)
		_:
			camera.global_position = Vector3(3.0, 7.8, -4.8)
			camera.look_at(Vector3(3.0, 0.65, 3.0), Vector3.UP)
	camera.current = true

	for _i in range(18):
		await process_frame

	var dir := DirAccess.open("res://")
	if dir == null:
		_fail("Failed to open project root.")
		return
	dir.make_dir_recursive("artifacts/screenshots")

	var image := root.get_texture().get_image()
	var error := image.save_png(output_path)
	if error != OK:
		_fail("Failed to save %s code=%d." % [output_path, error])
		return
	print("NATURAL_PROP_CAPTURE PASS path=%s mode=%s scene=%s" % [output_path, mode, scene_path])
	quit(0)

func _fail(message: String) -> void:
	push_error("NATURAL_PROP_CAPTURE FAIL: %s" % message)
	quit(1)

func _hide_capture_ceilings(scene: Node3D) -> void:
	for node in get_nodes_in_group("ceiling"):
		if node is Node3D and scene.is_ancestor_of(node):
			(node as Node3D).visible = false
