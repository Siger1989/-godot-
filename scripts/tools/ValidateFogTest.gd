extends SceneTree

const STATE_NAMES := ["UNKNOWN", "VISITED", "PARTIAL_VISIBLE", "VISIBLE"]

var scene: Node
var failed := false


func _initialize() -> void:
	var packed_scene: PackedScene = load("res://scenes/levels/FogOfWar_Test.tscn")
	scene = packed_scene.instantiate()
	root.add_child(scene)
	_run.call_deferred()


func _run() -> void:
	for i in 12:
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
	for i in 8:
		await process_frame
	_expect("door_a_open", {
		"RoomA": "VISIBLE",
		"Corridor": "PARTIAL_VISIBLE",
		"RoomB": "UNKNOWN",
		"RoomC": "UNKNOWN"
	})

	var player := root.find_child("FogTestPlayer", true, false) as Node3D
	player.global_position = Vector3(10.0, 0.0, 0.0)
	for i in 8:
		await process_frame

	var door_b: Node = root.find_child("Door_Corridor_B", true, false)
	if door_b and door_b.has_method("toggle"):
		door_b.call("toggle")
	for i in 8:
		await process_frame
	_expect("door_b_open_from_corridor", {
		"RoomA": "PARTIAL_VISIBLE",
		"Corridor": "VISIBLE",
		"RoomB": "PARTIAL_VISIBLE",
		"RoomC": "UNKNOWN"
	})

	player.global_position = Vector3(29.0, 0.0, 0.0)
	for i in 8:
		await process_frame
	_expect("entered_b", {
		"RoomA": "VISITED",
		"Corridor": "PARTIAL_VISIBLE",
		"RoomB": "VISIBLE",
		"RoomC": "UNKNOWN"
	})

	if failed:
		push_error("FOG_TEST_FAILED")
	else:
		print("FOG_TEST_OK")
	quit()


func _expect(label: String, expected: Dictionary) -> void:
	var parts: Array[String] = []
	for room_id in expected.keys():
		var section: Node = root.find_child(String(room_id), true, false)
		var actual_index: int = int(section.get("state")) if section else -1
		var actual: String = STATE_NAMES[actual_index] if actual_index >= 0 and actual_index < STATE_NAMES.size() else "MISSING"
		var wanted: String = String(expected[room_id])
		parts.append("%s=%s" % [room_id, actual])
		if actual != wanted:
			failed = true
			push_error("%s expected %s=%s but got %s" % [label, room_id, wanted, actual])
	print("FOG_TEST_%s %s" % [label, ", ".join(parts)])
