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

	var camera := Camera3D.new()
	camera.name = "ContactAOInspectionCamera"
	camera.fov = 58.0
	scene.add_child(camera)
	camera.global_position = Vector3(1.05, 1.42, -2.15)
	camera.look_at(Vector3(3.0, 1.08, 0.0), Vector3.UP)
	camera.current = true

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
	var screenshot_path := "%s/contact_ao_experiment_%s.png" % [SCREENSHOT_DIR, timestamp]
	var image := root.get_texture().get_image()
	var save_result := image.save_png(screenshot_path)
	if save_result != OK:
		_fail("Failed to save screenshot to %s, code=%d." % [screenshot_path, save_result])
		return

	print("CONTACT_AO_EXPERIMENT_SCREENSHOT PASS path=%s" % screenshot_path)
	quit(0)

func _fail(message: String) -> void:
	push_error("CONTACT_AO_EXPERIMENT_SCREENSHOT FAIL %s" % message)
	quit(1)
