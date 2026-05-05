extends SceneTree

const SCENE_PATH := "res://scenes/tests/Test_ProcMazeMap.tscn"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		_fail("missing scene: %s" % SCENE_PATH)
		return
	var root := packed.instantiate() as Node3D
	if root == null:
		_fail("scene root is not Node3D")
		return
	get_root().add_child(root)
	if root.has_method("rebuild"):
		var result: Dictionary = root.rebuild()
		if not bool(result.get("ok", false)):
			_fail("proc maze rebuild failed before keyed exit validation")
			return
	await process_frame
	await physics_frame

	var keyed_openings := _nodes_in_group(root, "proc_keyed_exit_opening")
	var keyed_frames := _nodes_in_group(root, "proc_keyed_exit_frame")
	var keyed_doors := _nodes_in_group(root, "proc_keyed_exit_door")
	var keys := _nodes_in_group(root, "escape_key_pickup")
	if keyed_openings.size() != 1:
		_fail("expected one keyed outer wall opening, found %d" % keyed_openings.size())
		return
	if keyed_frames.size() != 1:
		_fail("expected one keyed outer door frame, found %d" % keyed_frames.size())
		return
	if keyed_doors.size() != 1:
		_fail("expected one keyed outer door, found %d" % keyed_doors.size())
		return
	if keys.size() != 1:
		_fail("expected one random escape key, found %d" % keys.size())
		return

	var opening := keyed_openings[0] as Node3D
	var frame := keyed_frames[0] as Node3D
	var door := keyed_doors[0] as Node3D
	var key := keys[0] as Node3D
	if opening == null or frame == null or door == null or key == null:
		_fail("keyed exit nodes have invalid types")
		return
	if not _is_zero_rotation(opening.rotation):
		_fail("keyed wall opening should not rotate the wall node: %s" % opening.rotation)
		return
	if not _is_zero_rotation(frame.rotation):
		_fail("keyed door frame should not rotate the frame node: %s" % frame.rotation)
		return
	if opening.position.distance_to(frame.position) > 0.001 or opening.position.distance_to(door.position) > 0.16:
		_fail("keyed opening, frame, and door are not aligned")
		return
	if not bool(door.get("requires_escape_key")) or not bool(door.get_meta("requires_escape_key", false)):
		_fail("keyed outer door does not require the escape key")
		return
	if bool(key.get_meta("collected", false)):
		_fail("escape key starts collected")
		return
	var key_surface := String(key.get_meta("placement_surface", ""))

	var player := root.get_node_or_null("PlayerRoot/Player") as Node3D
	if player == null:
		_fail("playable player is missing")
		return
	if player.has_method("debug_set_escape_key"):
		player.call("debug_set_escape_key", false)
	var locked_opened := bool(door.call("interact_from", player, Vector3.FORWARD))
	if locked_opened:
		_fail("keyed outer door opened before the player had the key")
		return
	if int(door.get_meta("locked_attempt_count", 0)) < 1:
		_fail("keyed outer door did not record a locked attempt")
		return
	player.call("collect_escape_key", key)
	await process_frame
	if player.has_method("has_escape_key") and not bool(player.call("has_escape_key")):
		_fail("player did not receive the escape key")
		return
	var unlocked_opened := bool(door.call("interact_from", player, Vector3.FORWARD))
	if not unlocked_opened or not bool(door.call("is_open")):
		_fail("keyed outer door did not open after collecting the key")
		return

	print("PROC_MAZE_KEYED_EXIT_VALIDATION PASS opening=%s door=%s key_surface=%s" % [
		opening.name,
		door.name,
		key_surface,
	])
	quit(0)

func _nodes_in_group(root: Node, group_name: String) -> Array:
	var result := []
	_collect_nodes_in_group(root, group_name, result)
	return result

func _collect_nodes_in_group(node: Node, group_name: String, result: Array) -> void:
	if node.is_in_group(group_name):
		result.append(node)
	for child in node.get_children():
		_collect_nodes_in_group(child, group_name, result)

func _is_zero_rotation(value: Vector3) -> bool:
	return absf(value.x) <= 0.001 and absf(value.y) <= 0.001 and absf(value.z) <= 0.001

func _fail(message: String) -> void:
	push_error("PROC_MAZE_KEYED_EXIT_VALIDATION FAIL %s" % message)
	quit(1)
