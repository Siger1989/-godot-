extends SceneTree

const SCENE_PATH := "res://scenes/mvp/FourRoomMVP.tscn"
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

	root.add_child(scene)
	current_scene = scene
	root.size = Vector2i(1280, 720)

	var camera := Camera3D.new()
	camera.name = "DoorFrameInspectionCamera"
	camera.fov = 58.0
	scene.add_child(camera)
	camera.global_position = Vector3(1.05, 1.45, -2.15)
	camera.look_at(Vector3(3.0, 1.12, 0.0), Vector3.UP)
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
	var screenshot_path := "%s/four_room_doorframe_%s.png" % [SCREENSHOT_DIR, timestamp]
	var image := root.get_texture().get_image()
	var save_result := image.save_png(screenshot_path)
	if save_result != OK:
		_fail("Failed to save screenshot to %s, code=%d." % [screenshot_path, save_result])
		return

	print("FOUR_ROOM_DOORFRAME_SCREENSHOT PASS path=%s" % screenshot_path)
	quit(0)

func _fail(message: String) -> void:
	push_error("FOUR_ROOM_DOORFRAME_SCREENSHOT FAIL %s" % message)
	quit(1)
