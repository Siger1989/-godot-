extends SceneTree

const SCENE_PATH := "res://scenes/mvp/FourRoomMVP.tscn"

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
	await process_frame

	var builder := scene.get_node_or_null("Systems/SceneBuilder")
	if builder == null or not builder.has_method("build"):
		_fail("SceneBuilder is missing.")
		return
	builder.call("build")
	scene.set("build_on_ready", true)
	await process_frame

	_assign_owned_generated_nodes(scene)

	var repacked := PackedScene.new()
	var pack_result := repacked.pack(scene)
	if pack_result != OK:
		_fail("PackedScene.pack failed with code %d." % pack_result)
		return
	var save_result := ResourceSaver.save(repacked, SCENE_PATH)
	if save_result != OK:
		_fail("ResourceSaver.save failed with code %d." % save_result)
		return

	print("BAKE_FOUR_ROOM_SCENE PASS path=%s" % SCENE_PATH)
	quit(0)

func _assign_owned_generated_nodes(scene: Node) -> void:
	for target_path in [
		"LevelRoot/Geometry",
		"LevelRoot/Areas",
		"LevelRoot/Portals",
		"LevelRoot/Markers",
		"LevelRoot/Lights",
	]:
		var target := scene.get_node_or_null(target_path)
		if target != null:
			_assign_owner_recursive(target, scene)

func _assign_owner_recursive(node: Node, owner_root: Node) -> void:
	node.owner = owner_root
	if not node.scene_file_path.is_empty():
		return
	for child in node.get_children():
		_assign_owner_recursive(child, owner_root)

func _fail(message: String) -> void:
	push_error("BAKE_FOUR_ROOM_SCENE FAIL: %s" % message)
	quit(1)
