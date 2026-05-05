extends SceneTree

const SCENE_PATH := "res://scenes/debug/BaseResourceGallery.tscn"
const SCREENSHOT_DIR := "res://artifacts/screenshots"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		push_error("Failed to load %s." % SCENE_PATH)
		quit(1)
		return

	var scene := packed.instantiate() as Node3D
	if scene == null:
		push_error("Failed to instantiate %s." % SCENE_PATH)
		quit(1)
		return

	root.add_child(scene)
	current_scene = scene
	root.size = Vector2i(1600, 900)

	var style_row := scene.get_node_or_null("Backrooms_Material_Row") as Node3D
	if style_row != null:
		style_row.visible = false

	var camera := scene.get_node_or_null("Camera3D") as Camera3D
	if camera != null:
		camera.current = true
		camera.position = Vector3(2.5, 2.75, 8.0)
		camera.rotation_degrees = Vector3(-8.0, 0.0, 0.0)
		camera.fov = 48.0

	for i in range(8):
		await process_frame

	var dir := DirAccess.open("res://")
	if dir == null:
		push_error("Failed to open project root.")
		quit(1)
		return
	if not dir.dir_exists("artifacts"):
		dir.make_dir("artifacts")
	if not dir.dir_exists("artifacts/screenshots"):
		dir.make_dir_recursive("artifacts/screenshots")

	var timestamp := Time.get_datetime_string_from_system(false, true).replace(":", "").replace("-", "").replace("T", "_")
	var screenshot_path := "%s/base_resource_gallery_%s.png" % [SCREENSHOT_DIR, timestamp]
	var image := root.get_texture().get_image()
	var save_result := image.save_png(screenshot_path)
	if save_result != OK:
		push_error("Failed to save screenshot to %s, code=%d." % [screenshot_path, save_result])
		quit(1)
		return

	print("BASE_RESOURCE_GALLERY_SCREENSHOT PASS path=%s" % screenshot_path)
	quit(0)
