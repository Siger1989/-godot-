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
	await _wait_frames(40)

	var player := root.find_child("Player", true, false) as Node3D
	var storage_door := root.find_child("StorageDoor", true, false)
	var storage_section := root.find_child("StorageRoom", true, false)
	if not player:
		_fail("Player was not found")
	if not storage_door:
		_fail("StorageDoor was not found")
	if not storage_section:
		_fail("StorageRoom section was not found")
	if failed:
		_finish()
		return

	var void_root := root.find_child("OutOfBoundsVoid", true, false) as Node3D
	if not void_root:
		_fail("OutOfBoundsVoid was not found")
	elif void_root.visible:
		_fail("OutOfBoundsVoid visuals should be hidden in the main game")

	_set_door(storage_door, true)
	await _wait_frames(20)

	var open_neighbor_state := _state_name(storage_section)
	print("MAIN_CLOSED_MEMORY_open_neighbor_StorageRoom=%s" % open_neighbor_state)
	if open_neighbor_state != "UNKNOWN":
		_fail("StorageRoom should remain logical UNKNOWN when only the door is opened")

	player.global_position = Vector3(-72.0, 0.0, -27.0)
	await _wait_frames(30)

	_set_door(storage_door, false)
	await _wait_frames(20)

	player.global_position = Vector3(-74.0, 0.0, 0.0)
	await _wait_frames(40)

	var state := _state_name(storage_section)
	print("MAIN_CLOSED_MEMORY_StorageRoom=%s" % state)
	if state != "VISITED":
		_fail("StorageRoom should be VISITED after returning to StartHall with door closed")

	var visible_light_meshes := _count_visible_light_meshes(storage_section)
	var visible_lights := _count_visible_lights(storage_section)
	var visible_dynamic := _count_visible_dynamic(storage_section)
	print("MAIN_CLOSED_MEMORY_light_mesh_visible=%d" % visible_light_meshes)
	print("MAIN_CLOSED_MEMORY_lights_visible=%d" % visible_lights)
	print("MAIN_CLOSED_MEMORY_dynamic_visible=%d" % visible_dynamic)

	if visible_light_meshes > 0:
		_fail("Visited closed StorageRoom should not show light meshes")
	if visible_lights > 0:
		_fail("Visited closed StorageRoom should not keep actual lights visible")
	if visible_dynamic > 0:
		_fail("Visited closed StorageRoom should not show dynamic/detail content")

	_finish()


func _set_door(door: Node, open: bool) -> void:
	var is_open := false
	var value: Variant = door.get("is_open")
	if value is bool:
		is_open = bool(value)
	if is_open == open:
		return
	if door.has_method("interact"):
		door.call("interact", null)


func _state_name(section: Node) -> String:
	if section and section.has_method("get_state_name"):
		return String(section.call("get_state_name"))
	return "MISSING"


func _count_visible_light_meshes(node: Node) -> int:
	var count := 0
	if node is MeshInstance3D and String(node.get_meta("fog_role", "")) == "light_mesh" and (node as MeshInstance3D).visible:
		count += 1
	for child in node.get_children():
		count += _count_visible_light_meshes(child)
	return count


func _count_visible_lights(node: Node) -> int:
	var count := 0
	if node is Light3D:
		var light := node as Light3D
		if light.visible and light.light_energy > 0.001:
			count += 1
	for child in node.get_children():
		count += _count_visible_lights(child)
	return count


func _count_visible_dynamic(node: Node) -> int:
	var count := 0
	if node is Node3D:
		var role := String(node.get_meta("fog_role", ""))
		if (role == "detail" or role == "dynamic") and (node as Node3D).visible:
			count += 1
	for child in node.get_children():
		count += _count_visible_dynamic(child)
	return count


func _wait_frames(count: int) -> void:
	for i in count:
		await process_frame


func _finish() -> void:
	if failed:
		push_error("MAIN_CLOSED_MEMORY_FAILED")
		quit(1)
	else:
		print("MAIN_CLOSED_MEMORY_OK")
		quit()


func _fail(message: String) -> void:
	failed = true
	push_error(message)
