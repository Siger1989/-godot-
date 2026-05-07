extends SceneTree

const SCENE_PATH := "res://scenes/tests/Test_ProcMazeMap_NoCeilingPreview.tscn"
const TestProcMazeMapScript = preload("res://scripts/proc_maze/TestProcMazeMap.gd")

func _init() -> void:
	var root = _load_or_create_root()
	if root.get_script() == null:
		root.set_script(TestProcMazeMapScript)
	root.name = "Test_ProcMazeMap_NoCeilingPreview"
	root.set("enable_playable_test", false)
	root.set("preview_without_ceiling", true)
	root.set("preview_keep_ceiling_lights", true)
	root.set("preview_full_map_camera", true)
	root.set("preview_show_feature_labels", true)
	root.set("show_debug_map_markers", true)
	root.set("show_guidance_graffiti", true)
	root.set("rebuild_on_ready", false)
	root.set("feature_preview_start_module_id", "")
	if root.get_parent() == null:
		get_root().add_child(root)

	var result: Dictionary = root.rebuild()
	if not bool(result.get("ok", false)):
		push_error("TEST_PROC_MAZE_NO_CEILING_PREVIEW_BAKE FAIL")
		quit(1)
		return

	_set_owner_recursive(root, root)
	var packed = PackedScene.new()
	var pack_error = packed.pack(root)
	if pack_error != OK:
		push_error("TEST_PROC_MAZE_NO_CEILING_PREVIEW_BAKE pack failed: %s" % str(pack_error))
		quit(1)
		return
	var save_error = ResourceSaver.save(packed, SCENE_PATH)
	if save_error != OK:
		push_error("TEST_PROC_MAZE_NO_CEILING_PREVIEW_BAKE save failed: %s" % str(save_error))
		quit(1)
		return
	print("TEST_PROC_MAZE_NO_CEILING_PREVIEW_BAKE PASS path=%s seed=%s rooms=%s fixtures=%s sources=%s" % [
		SCENE_PATH,
		str(result.get("seed", "")),
		str(result.get("total_rooms", "")),
		str(result.get("active_light_count", "")),
		str(result.get("active_light_source_count", "")),
	])
	quit(0)

func _load_or_create_root() -> Node3D:
	if ResourceLoader.exists(SCENE_PATH):
		var packed = load(SCENE_PATH) as PackedScene
		if packed != null:
			var instance = packed.instantiate() as Node3D
			if instance != null:
				return instance
	var root = Node3D.new()
	root.name = "Test_ProcMazeMap_NoCeilingPreview"
	return root

func _set_owner_recursive(node: Node, owner: Node) -> void:
	for child in node.get_children():
		child.owner = owner
		if child.scene_file_path != "":
			_clear_descendant_owners(child)
			continue
		_set_owner_recursive(child, owner)

func _clear_descendant_owners(node: Node) -> void:
	for child in node.get_children():
		child.owner = null
		_clear_descendant_owners(child)
