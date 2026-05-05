extends SceneTree

const SCENE_PATH := "res://scenes/mvp/experiments/FourRoomMVP_contact_ao_experiment.tscn"
const SCREENSHOT_DIR := "res://artifacts/screenshots"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		_fail("Failed to load %s." % SCENE_PATH)
		return

	var scene := packed.instantiate() as Node3D
	if scene == null:
		_fail("Failed to instantiate %s." % SCENE_PATH)
		return

	scene.set("build_on_ready", false)
	root.add_child(scene)
	current_scene = scene
	root.size = Vector2i(1280, 720)

	await process_frame
	await physics_frame
	await process_frame

	var camera_rig := scene.get_node_or_null("CameraRig") as Node3D
	var camera := scene.get_node_or_null("CameraRig/Camera3D") as Camera3D
	var player := scene.get_node_or_null("PlayerRoot/Player") as Node3D
	var occlusion := scene.get_node_or_null("Systems/ForegroundOcclusion")
	if camera_rig == null or camera == null or player == null or occlusion == null:
		_fail("Required foreground cutout screenshot nodes are missing.")
		return

	camera_rig.set_process(false)
	camera.current = true
	player.global_position = Vector3.ZERO
	camera_rig.global_position = Vector3(-4.2, 1.35, 0.0)
	camera.look_at(player.global_position + Vector3.UP, Vector3.UP)
	occlusion.call("refresh", 0.0)

	for i in range(12):
		await process_frame

	var dir := DirAccess.open("res://")
	if dir == null:
		_fail("Failed to open project root.")
		return
	if not dir.dir_exists("artifacts"):
		dir.make_dir("artifacts")
	if not dir.dir_exists("artifacts/screenshots"):
		dir.make_dir_recursive("artifacts/screenshots")

	var timestamp := Time.get_datetime_string_from_system(false, true).replace(":", "").replace("-", "").replace("T", "_")
	var screenshot_path := "%s/foreground_cutout_texture_%s.png" % [SCREENSHOT_DIR, timestamp]
	var image := root.get_texture().get_image()
	var save_result := image.save_png(screenshot_path)
	if save_result != OK:
		_fail("Failed to save screenshot to %s, code=%d." % [screenshot_path, save_result])
		return

	print("FOREGROUND_CUTOUT_SCREENSHOT PASS path=%s" % screenshot_path)
	quit(0)

func _fail(message: String) -> void:
	push_error("FOREGROUND_CUTOUT_SCREENSHOT FAIL %s" % message)
	quit(1)
