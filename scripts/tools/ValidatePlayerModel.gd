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
	await _wait_frames(30)

	var player := root.find_child("Player", true, false) as Node3D
	if not player:
		_fail("Player was not found")
		_finish()
		return

	var model_root := player.find_child("ImportedModelRoot", true, false) as Node3D
	if not model_root:
		_fail("ImportedModelRoot was not found under Player")
		_finish()
		return

	if DisplayServer.get_name() == "headless":
		if not FileAccess.file_exists("res://assets/models/player.glb"):
			_fail("assets/models/player.glb is missing")
		if not FileAccess.file_exists("res://assets/models/player.glb.import"):
			_fail("assets/models/player.glb.import is missing")
		print("PLAYER_MODEL_headless_resource_check=OK")
		print("PLAYER_MODEL_height=%.3f" % float(model_root.call("get_current_height")))
		_finish()
		return

	var imported_model := model_root.find_child("ImportedPlayerModel", true, false) as Node3D
	if not imported_model:
		_fail("ImportedPlayerModel was not instanced")
		_finish()
		return

	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(imported_model, meshes)
	if meshes.is_empty():
		_fail("ImportedPlayerModel has no MeshInstance3D nodes")
		_finish()
		return

	var old_body := player.find_child("Body", true, false) as MeshInstance3D
	if old_body and old_body.visible:
		_fail("Old placeholder Body mesh is still visible")

	print("PLAYER_MODEL_meshes=%d" % meshes.size())
	var model_height := 0.0
	if model_root.has_method("get_current_height"):
		model_height = float(model_root.call("get_current_height"))
	print("PLAYER_MODEL_height=%.3f" % model_height)
	if model_height < 1.2 or model_height > 1.9:
		_fail("Imported player model height is outside expected range: %.3f" % model_height)

	_finish()


func _finish() -> void:
	if failed:
		push_error("PLAYER_MODEL_FAILED")
		quit(1)
	else:
		print("PLAYER_MODEL_OK")
		quit()


func _collect_meshes(node: Node, meshes: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		meshes.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect_meshes(child, meshes)


func _wait_frames(count: int) -> void:
	for i in count:
		await process_frame


func _fail(message: String) -> void:
	failed = true
	push_error(message)
