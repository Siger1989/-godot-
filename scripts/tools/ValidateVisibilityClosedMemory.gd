extends SceneTree

var failed := false


func _initialize() -> void:
	var packed_scene: PackedScene = load("res://scenes/levels/Visibility_Blend_Test.tscn")
	var scene := packed_scene.instantiate()
	root.add_child(scene)
	_run.call_deferred()


func _run() -> void:
	await _wait_frames(90)

	var player := root.find_child("VisibilityBlendPlayer", true, false) as Node3D
	var door := root.find_child("BlendDoor_Corridor_RoomB", true, false)
	if door and door.has_method("force_open"):
		door.call("force_open", true)
	if player:
		player.global_position = Vector3(10.6, 0.0, 0.0)
	await _wait_frames(90)

	if door and door.has_method("force_open"):
		door.call("force_open", false)
	if player:
		player.global_position = Vector3(5.4, 0.0, 0.0)
	await _wait_frames(120)

	var scene := root.find_child("Visibility_Blend_Test", true, false)
	var room_b_debug := {}
	if scene and scene.has_method("get_section_debug"):
		room_b_debug = scene.call("get_section_debug", "RoomB")
	var room_b_state := String(room_b_debug.get("state", "MISSING"))
	print("VISIBILITY_CLOSED_MEMORY RoomB=%s light_target=%.3f floor=%.3f lamp=%.3f" % [
		room_b_state,
		float(room_b_debug.get("light_target", -1.0)),
		float(room_b_debug.get("floor_light_target", -1.0)),
		float(room_b_debug.get("lamp_light_target", -1.0))
	])
	if room_b_state != "VISITED":
		_fail("RoomB should be VISITED after the door is closed from the corridor")

	var room_b := root.find_child("RoomB", true, false)
	if room_b:
		_assert_room_b_lights_hidden(room_b)
	else:
		_fail("RoomB section missing")

	if failed:
		push_error("VISIBILITY_CLOSED_MEMORY_FAILED")
		quit(1)
	else:
		print("VISIBILITY_CLOSED_MEMORY_OK")
		quit()


func _assert_room_b_lights_hidden(node: Node) -> void:
	for child in node.get_children():
		if child is Light3D and child.visible:
			_fail("RoomB light should not be visible in memory state: %s" % child.name)
		if child is MeshInstance3D and String(child.get_meta("visibility_role", "")) == "light_mesh" and child.visible:
			_fail("RoomB light mesh should not be visible in memory state: %s" % child.name)
		_assert_room_b_lights_hidden(child)


func _wait_frames(count: int) -> void:
	for i in count:
		await process_frame


func _fail(message: String) -> void:
	failed = true
	push_error(message)
