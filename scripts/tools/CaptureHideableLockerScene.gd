extends SceneTree

const SHOWCASE_SCENE_PATH := "res://scenes/tests/Test_HideableLockerShowcase.tscn"
const LOCKER_SCENE_PATH := "res://assets/backrooms/props/furniture/HideLocker_A.tscn"
const PLAYER_SCENE_PATH := "res://scenes/modules/PlayerModule.tscn"
const FOUR_ROOM_SCENE_PATH := "res://scenes/mvp/FourRoomMVP.tscn"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var mode := OS.get_environment("CAPTURE_MODE")
	if mode.is_empty():
		mode = "showcase"
	var output_path := OS.get_environment("CAPTURE_OUTPUT_PATH")
	if output_path.is_empty():
		output_path = "res://artifacts/screenshots/hideable_locker_%s.png" % mode

	root.size = Vector2i(1280, 720)
	if mode == "slit_view":
		if not await _build_slit_view_scene():
			return
	elif mode == "mvp_room_c":
		if not await _load_mvp_room_c_scene(false):
			return
	elif mode == "mvp_prompt":
		if not await _load_mvp_room_c_scene(true):
			return
	else:
		if not _load_showcase_scene():
			return

	for _i in range(24):
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
	print("HIDEABLE_LOCKER_CAPTURE PASS path=%s mode=%s" % [output_path, mode])
	quit(0)

func _load_showcase_scene() -> bool:
	var packed := load(SHOWCASE_SCENE_PATH) as PackedScene
	if packed == null:
		_fail("Missing showcase scene.")
		return false
	var scene := packed.instantiate() as Node3D
	if scene == null:
		_fail("Failed to instantiate showcase scene.")
		return false
	root.add_child(scene)
	current_scene = scene
	return true

func _load_mvp_room_c_scene(show_player_prompt: bool) -> bool:
	var packed := load(FOUR_ROOM_SCENE_PATH) as PackedScene
	if packed == null:
		_fail("Missing FourRoomMVP scene.")
		return false
	var scene := packed.instantiate() as Node3D
	if scene == null:
		_fail("Failed to instantiate FourRoomMVP scene.")
		return false
	scene.set("build_on_ready", false)
	root.add_child(scene)
	current_scene = scene
	await process_frame

	var locker := scene.get_node_or_null("LevelRoot/Props/RoomC_HideLocker_A") as Node3D
	if locker == null:
		_fail("MVP scene missing RoomC_HideLocker_A.")
		return false

	var camera_position := Vector3(5.82, 1.42, 7.48)
	var camera_target := locker.global_position + Vector3(0.0, 1.0, 0.0)
	if show_player_prompt:
		var player := scene.get_node_or_null("PlayerRoot/Player") as Node3D
		if player == null:
			_fail("MVP scene missing player for prompt capture.")
			return false
		player.global_position = locker.global_position + (locker.global_transform.basis * Vector3(0.0, 0.0, 1.0)).normalized() * 1.02
		var to_locker := locker.global_position - player.global_position
		to_locker.y = 0.0
		if to_locker.length_squared() > 0.0001:
			var facing := to_locker.normalized()
			player.set("_facing_direction", facing)
			player.set("_has_facing_direction", true)
			player.call("_update_interaction_button")
		camera_position = player.global_position + Vector3(-0.70, 1.30, 0.72)
		camera_target = locker.global_position + Vector3(0.0, 0.95, 0.0)

	var camera := Camera3D.new()
	camera.name = "HideLockerMvpCaptureCamera"
	camera.fov = 50.0
	camera.current = true
	scene.add_child(camera)
	camera.look_at_from_position(camera_position, camera_target, Vector3.UP)

	var light := OmniLight3D.new()
	light.name = "HideLockerMvpCaptureFill"
	light.light_color = Color(1.0, 0.86, 0.62)
	light.light_energy = 1.2
	light.omni_range = 4.0
	light.position = Vector3(6.1, 2.2, 7.1)
	scene.add_child(light)
	return true

func _build_slit_view_scene() -> bool:
	var packed_locker := load(LOCKER_SCENE_PATH) as PackedScene
	var packed_player := load(PLAYER_SCENE_PATH) as PackedScene
	if packed_locker == null or packed_player == null:
		_fail("Missing locker or player scene.")
		return false

	var scene := Node3D.new()
	scene.name = "HideableLockerSlitViewCapture"
	root.add_child(scene)
	current_scene = scene
	_create_environment(scene)

	var locker := packed_locker.instantiate() as Node3D
	locker.name = "HideLocker_A_Capture"
	scene.add_child(locker)

	var player_root := Node3D.new()
	player_root.name = "PlayerRoot"
	scene.add_child(player_root)
	var player := packed_player.instantiate() as Node3D
	player.name = "Player"
	player.position = Vector3(0.0, 0.0, 1.10)
	player_root.add_child(player)

	var camera_rig := Node3D.new()
	camera_rig.name = "CameraRig"
	camera_rig.position = Vector3(0.0, 1.45, 2.35)
	scene.add_child(camera_rig)
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.current = true
	camera.fov = 62.0
	camera_rig.add_child(camera)
	camera.look_at(Vector3(0.0, 1.15, 0.0), Vector3.UP)

	await process_frame
	await physics_frame
	player.set("_facing_direction", Vector3.FORWARD)
	player.set("_has_facing_direction", true)
	if not bool(player.call("_try_interact_with_hideable")):
		_fail("Failed to enter locker for slit-view capture.")
		return false
	await process_frame
	return true

func _create_environment(scene: Node3D) -> void:
	var world := WorldEnvironment.new()
	world.name = "WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.018, 0.017, 0.014)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(1.0, 0.90, 0.70)
	environment.ambient_light_energy = 0.22
	world.environment = environment
	scene.add_child(world)

	var floor := MeshInstance3D.new()
	floor.name = "CaptureFloor"
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(4.0, 0.04, 4.0)
	floor.mesh = floor_mesh
	floor.position = Vector3(0.0, -0.02, 0.90)
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.52, 0.48, 0.35)
	floor_material.roughness = 0.92
	floor.material_override = floor_material
	scene.add_child(floor)

	var wall := MeshInstance3D.new()
	wall.name = "CaptureWall"
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = Vector3(4.0, 2.55, 0.08)
	wall.mesh = wall_mesh
	wall.position = Vector3(0.0, 1.275, -0.365)
	var wall_material := StandardMaterial3D.new()
	wall_material.albedo_color = Color(0.64, 0.55, 0.32)
	wall_material.roughness = 0.94
	wall.material_override = wall_material
	scene.add_child(wall)

	var view_target_wall := MeshInstance3D.new()
	view_target_wall.name = "SlitViewTargetWall"
	var view_target_mesh := BoxMesh.new()
	view_target_mesh.size = Vector3(4.0, 2.55, 0.08)
	view_target_wall.mesh = view_target_mesh
	view_target_wall.position = Vector3(0.0, 1.275, 2.45)
	view_target_wall.material_override = wall_material
	scene.add_child(view_target_wall)

	var light := OmniLight3D.new()
	light.name = "CaptureWarmLight"
	light.position = Vector3(0.0, 2.25, 1.20)
	light.light_color = Color(1.0, 0.86, 0.62)
	light.light_energy = 1.6
	light.omni_range = 4.0
	scene.add_child(light)

	var front_light := OmniLight3D.new()
	front_light.name = "SlitViewTargetLight"
	front_light.position = Vector3(0.0, 1.85, 2.05)
	front_light.light_color = Color(1.0, 0.88, 0.66)
	front_light.light_energy = 2.2
	front_light.omni_range = 3.0
	scene.add_child(front_light)

func _fail(message: String) -> void:
	push_error("HIDEABLE_LOCKER_CAPTURE FAIL: %s" % message)
	quit(1)
