extends SceneTree

var failed := false


func _initialize() -> void:
	var packed_scene: PackedScene = load("res://scenes/levels/FogOfWar_RoomPrototype.tscn")
	var scene: Node = packed_scene.instantiate()
	root.add_child(scene)
	_run.call_deferred()


func _run() -> void:
	for i in 16:
		await process_frame

	_expect("initial", {
		"RoomA": "VISIBLE",
		"Corridor": "UNKNOWN",
		"RoomB": "UNKNOWN",
		"RoomC": "UNKNOWN"
	})

	var door_a: Node = root.find_child("Door_A_Corridor", true, false)
	if door_a and door_a.has_method("toggle"):
		door_a.call("toggle")
	for i in 10:
		await process_frame
	_expect("open_a_door", {
		"RoomA": "VISIBLE",
		"Corridor": "UNKNOWN",
		"RoomB": "UNKNOWN",
		"RoomC": "UNKNOWN"
	})

	var player := root.find_child("RoomPrototypePlayer", true, false) as Node3D
	player.global_position = Vector3(5.0, 0.0, 0.0)
	for i in 10:
		await process_frame
	_expect("enter_corridor", {
		"RoomA": "VISITED",
		"Corridor": "VISIBLE",
		"RoomB": "UNKNOWN",
		"RoomC": "UNKNOWN"
	})

	var door_b: Node = root.find_child("Door_Corridor_B", true, false)
	if door_b and door_b.has_method("toggle"):
		door_b.call("toggle")
	for i in 10:
		await process_frame
	_expect("open_b_door", {
		"RoomA": "VISITED",
		"Corridor": "VISIBLE",
		"RoomB": "UNKNOWN",
		"RoomC": "UNKNOWN"
	})

	player.global_position = Vector3(18.0, 0.0, 0.0)
	for i in 10:
		await process_frame
	_expect("enter_room_b", {
		"RoomA": "VISITED",
		"Corridor": "VISITED",
		"RoomB": "VISIBLE",
		"RoomC": "UNKNOWN"
	})

	if failed:
		push_error("ROOM_PROTOTYPE_FAILED")
	else:
		print("ROOM_PROTOTYPE_OK")
	quit()


func _expect(label: String, expected: Dictionary) -> void:
	var parts: Array[String] = []
	for room_id in expected.keys():
		var section: Node = root.find_child(String(room_id), true, false)
		var actual := "MISSING"
		if section and section.has_method("get_state_name"):
			actual = String(section.call("get_state_name"))
		var wanted := String(expected[room_id])
		parts.append("%s=%s" % [room_id, actual])
		if actual != wanted:
			failed = true
			push_error("%s expected %s=%s but got %s" % [label, room_id, wanted, actual])
	print("ROOM_PROTOTYPE_%s %s" % [label, ", ".join(parts)])
