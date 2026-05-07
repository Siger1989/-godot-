extends SceneTree

const SCENE_PATH := "res://scenes/tests/Test_ProcMazeMap.tscn"
const TestProcMazeMapScript = preload("res://scripts/proc_maze/TestProcMazeMap.gd")

func _init() -> void:
	var root = _load_or_create_root()
	if root.get_script() == null:
		root.set_script(TestProcMazeMapScript)
	root.set("preview_show_feature_labels", false)
	root.set("show_debug_map_markers", false)
	root.set("show_guidance_graffiti", false)
	root.set("rebuild_on_ready", false)
	root.set("feature_preview_start_module_id", "")
	if root.get_parent() == null:
		get_root().add_child(root)
	var result: Dictionary = root.rebuild()
	if not bool(result.get("ok", false)):
		push_error("TEST_PROC_MAZE_BAKE FAIL")
		quit(1)
		return

	_set_owner_recursive(root, root)
	var packed = PackedScene.new()
	var pack_error = packed.pack(root)
	if pack_error != OK:
		push_error("TEST_PROC_MAZE_BAKE pack failed: %s" % str(pack_error))
		quit(1)
		return
	var save_error = ResourceSaver.save(packed, SCENE_PATH)
	if save_error != OK:
		push_error("TEST_PROC_MAZE_BAKE save failed: %s" % str(save_error))
		quit(1)
		return
	print("TEST_PROC_MAZE_BAKE PASS path=%s seed=%s rooms=%s" % [SCENE_PATH, str(result.get("seed", "")), str(result.get("total_rooms", ""))])
	quit(0)

func _load_or_create_root() -> Node3D:
	if ResourceLoader.exists(SCENE_PATH):
		var packed = load(SCENE_PATH) as PackedScene
		if packed != null:
			var instance = packed.instantiate() as Node3D
			if instance != null:
				return instance
	var root = Node3D.new()
	root.name = "Test_ProcMazeMap"
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
