extends SceneTree

var failed := false


func _initialize() -> void:
	var packed_scene: PackedScene = load("res://scenes/main/Main.tscn")
	if not packed_scene:
		_fail("Main scene could not be loaded")
		quit(1)
		return

	var scene := packed_scene.instantiate()
	root.add_child(scene)
	_run.call_deferred()


func _run() -> void:
	await _wait_frames(20)
	_expect_node("Level0_Demo")
	_expect_node("UIRoot")
	_expect_node("Player")
	_expect_node("ObjectiveManager")
	_expect_node("RoomPrototypeFogManager")
	_expect_node("ShadowEntity")

	var objective := root.find_child("ObjectiveManager", true, false)
	if objective and objective.has_method("get_objective_text"):
		var text := String(objective.call("get_objective_text"))
		print("MAIN_SCENE_objective=%s" % text)
	else:
		_fail("ObjectiveManager is missing get_objective_text")

	if failed:
		push_error("MAIN_SCENE_FAILED")
		quit(1)
	else:
		print("MAIN_SCENE_OK")
		quit()


func _expect_node(node_name: String) -> void:
	var node := root.find_child(node_name, true, false)
	print("MAIN_SCENE_node %s=%s" % [node_name, "OK" if node else "MISSING"])
	if not node:
		_fail("%s was not found after loading Main.tscn" % node_name)


func _wait_frames(count: int) -> void:
	for i in count:
		await process_frame


func _fail(message: String) -> void:
	failed = true
	push_error(message)
