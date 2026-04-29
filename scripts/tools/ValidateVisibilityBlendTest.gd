extends SceneTree

var failed := false


func _initialize() -> void:
	var packed_scene: PackedScene = load("res://scenes/levels/Visibility_Blend_Test.tscn")
	var scene := packed_scene.instantiate()
	root.add_child(scene)
	_run.call_deferred()


func _run() -> void:
	await _wait_frames(90)
	_expect_state("initial", {
		"RoomA": "VISIBLE",
		"RoomB": "UNKNOWN"
	})

	var player := root.find_child("VisibilityBlendPlayer", true, false) as Node3D
	var door := root.find_child("BlendDoor_Corridor_RoomB", true, false)
	if door and door.has_method("force_open"):
		door.call("force_open", true)
	if player:
		player.global_position = Vector3(6.4, 0.0, 0.0)
	await _wait_frames(55)

	var room_b := _weights("RoomB")
	var visibility := _visibility_debug()
	print("VISIBILITY_BLEND_open_near_door RoomB=%s rays=%d visible=%.3f memory=%.3f" % [
		String(room_b.get("state", "MISSING")),
		int(visibility.get("ray_count", 0)),
		float(room_b.get("visible", 0.0)),
		float(room_b.get("memory", 0.0))
	])
	if String(room_b.get("state", "")) != "UNKNOWN":
		_fail("RoomB should stay logical UNKNOWN; current visibility must come from physical rays")
	if int(visibility.get("ray_count", 0)) < 180:
		_fail("Physical visibility ray polygon is not being generated")
	if float(room_b.get("visible", 0.0)) >= 0.35:
		_fail("RoomB became globally visible instead of physically visible")

	if player:
		player.global_position = Vector3(10.6, 0.0, 0.0)
	await _wait_frames(70)
	_expect_state("enter_room_b", {
		"RoomA": "VISITED",
		"RoomB": "VISIBLE"
	})
	var room_a := _weights("RoomA")
	print("VISIBILITY_BLEND_room_a_memory visible=%.3f memory=%.3f" % [
		float(room_a.get("visible", 0.0)),
		float(room_a.get("memory", 0.0))
	])
	if float(room_a.get("memory", 0.0)) < 0.35:
		_fail("RoomA did not fade toward visited memory")

	if failed:
		push_error("VISIBILITY_BLEND_FAILED")
	else:
		print("VISIBILITY_BLEND_OK")
	quit()


func _expect_state(label: String, expected: Dictionary) -> void:
	var parts: Array[String] = []
	for section_id in expected.keys():
		var weights := _weights(String(section_id))
		var actual := String(weights.get("state", "MISSING"))
		var wanted := String(expected[section_id])
		parts.append("%s=%s" % [section_id, actual])
		if actual != wanted:
			_fail("%s expected %s=%s but got %s" % [label, section_id, wanted, actual])
	print("VISIBILITY_BLEND_%s %s" % [label, ", ".join(parts)])


func _weights(section_id: String) -> Dictionary:
	var scene := root.find_child("Visibility_Blend_Test", true, false)
	if scene and scene.has_method("get_section_debug"):
		return scene.call("get_section_debug", section_id)
	return {}


func _visibility_debug() -> Dictionary:
	var scene := root.find_child("Visibility_Blend_Test", true, false)
	if scene and scene.has_method("get_visibility_debug"):
		return scene.call("get_visibility_debug")
	return {}


func _wait_frames(count: int) -> void:
	for i in count:
		await process_frame


func _fail(message: String) -> void:
	failed = true
	push_error(message)
