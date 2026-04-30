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
	_expect_visible_light("initial_corridor_lamp", "Corridor")

	var player := root.find_child("VisibilityBlendPlayer", true, false) as Node3D
	var door := root.find_child("BlendDoor_Corridor_RoomB", true, false)
	if player:
		player.global_position = Vector3(2.6, 0.0, 0.0)
	await _wait_frames(70)
	_expect_state("corridor_keeps_room_a_memory", {
		"RoomA": "VISITED",
		"Corridor": "VISIBLE"
	})
	_expect_visible_light("corridor_still_sees_room_a_lamp", "RoomA")

	if player:
		player.global_position = Vector3(-5.5, 0.0, 0.0)
	await _wait_frames(70)
	_expect_state("return_keeps_corridor_memory", {
		"RoomA": "VISIBLE",
		"Corridor": "VISITED"
	})
	_expect_visible_light("return_still_sees_corridor_lamp", "Corridor")

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
	_expect_active_light_without_lamp_view("open_door_light_reaches_visible_floor", "RoomB")

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


func _expect_visible_light(label: String, section_id: String) -> void:
	var section := root.find_child(section_id, true, false)
	if not section:
		_fail("%s expected section %s to exist" % [label, section_id])
		return
	var visible_light_meshes := _count_visible_light_meshes(section)
	var active_lights := _count_active_lights(section)
	print("VISIBILITY_BLEND_%s %s light_mesh=%d active_lights=%d" % [
		label,
		section_id,
		visible_light_meshes,
		active_lights
	])
	if visible_light_meshes <= 0:
		_fail("%s expected at least one visible lamp panel in %s" % [label, section_id])
	if active_lights <= 0:
		_fail("%s expected at least one active light in %s" % [label, section_id])


func _expect_active_light_without_lamp_view(label: String, section_id: String) -> void:
	var section := root.find_child(section_id, true, false)
	if not section:
		_fail("%s expected section %s to exist" % [label, section_id])
		return
	var active_lights := _count_active_lights(section)
	print("VISIBILITY_BLEND_%s %s active_lights=%d" % [
		label,
		section_id,
		active_lights
	])
	if active_lights <= 0:
		_fail("%s expected %s light to stay active when it reaches visible floor" % [label, section_id])


func _count_visible_light_meshes(node: Node) -> int:
	var count := 0
	if node is MeshInstance3D:
		var mesh := node as MeshInstance3D
		if String(mesh.get_meta("visibility_role", "")) == "light_mesh" and mesh.visible:
			count += 1
	for child in node.get_children():
		count += _count_visible_light_meshes(child)
	return count


func _count_active_lights(node: Node) -> int:
	var count := 0
	if node is Light3D:
		var light := node as Light3D
		if light.visible and light.light_energy > 0.001:
			count += 1
	for child in node.get_children():
		count += _count_active_lights(child)
	return count


func _wait_frames(count: int) -> void:
	for i in count:
		await process_frame


func _fail(message: String) -> void:
	failed = true
	push_error(message)
