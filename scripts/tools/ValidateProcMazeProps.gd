extends SceneTree

const SCENE_PATH := "res://scenes/tests/Test_ProcMazeMap.tscn"
const MIN_TOTAL_PROPS := 18
const MAX_TOTAL_PROPS := 48
const MIN_FLOOR_PROPS := 8
const MIN_WALL_PROPS := 8
const MIN_HIDEABLE_PROPS := 1
const MAX_HIDEABLE_PROPS := 3
const BLOCKING_PORTAL_CLEARANCE := 0.95
const MARKER_CLEARANCE := 0.85

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
			_fail("proc maze rebuild failed before prop validation")
			return
	await process_frame
	await physics_frame

	var props_root := root.get_node_or_null("LevelRoot/Props") as Node3D
	if props_root == null:
		_fail("LevelRoot/Props is missing")
		return

	var props := _nodes_in_group(root, "proc_maze_prop")
	var total_count := props.size()
	var floor_count := 0
	var wall_count := 0
	var hideable_count := 0
	var owner_modules := {}
	var portal_positions := _node_positions_in_group(root, "proc_portal")
	var marker_positions := _marker_positions(root)

	for node in props:
		var prop := node as Node3D
		if prop == null:
			_fail("prop group contains non-Node3D")
			return
		var prop_id := String(prop.get_meta("proc_maze_prop_id", ""))
		var owner_module_id := String(prop.get_meta("owner_module_id", ""))
		var placement_surface := String(prop.get_meta("placement_surface", ""))
		var placement_group := String(prop.get_meta("placement_group", ""))
		var space_kind := String(prop.get_meta("space_kind", ""))
		if prop_id.is_empty() or owner_module_id.is_empty() or placement_group.is_empty():
			_fail("prop metadata is incomplete: %s" % prop.name)
			return
		owner_modules[owner_module_id] = true
		if placement_surface == "wall":
			wall_count += 1
			if prop.global_position.y < 0.9:
				_fail("wall prop is too low: %s y=%.2f" % [prop.name, prop.global_position.y])
				return
		elif placement_surface == "floor":
			floor_count += 1
			if prop.global_position.y < -0.04 or prop.global_position.y > 0.25:
				_fail("floor prop is not on the floor: %s y=%.2f" % [prop.name, prop.global_position.y])
				return
		else:
			_fail("prop has unknown placement surface: %s" % prop.name)
			return
		if prop_id == "HideLocker_A":
			hideable_count += 1
		if bool(prop.get_meta("blocks_path", false)):
			if space_kind in ["narrow_corridor", "long_corridor", "l_turn", "junction", "offset_corridor"]:
				_fail("blocking prop was placed in a corridor space: %s kind=%s" % [prop.name, space_kind])
				return
			if _is_near_positions(prop.global_position, portal_positions, BLOCKING_PORTAL_CLEARANCE):
				_fail("blocking prop is too close to a doorway: %s at %s" % [prop.name, str(prop.global_position)])
				return
			if _is_near_positions(prop.global_position, marker_positions, MARKER_CLEARANCE):
				_fail("blocking prop is too close to entrance/exit/special marker: %s" % prop.name)
				return

	if total_count < MIN_TOTAL_PROPS or total_count > MAX_TOTAL_PROPS:
		_fail("unexpected proc prop count: %d" % total_count)
		return
	if floor_count < MIN_FLOOR_PROPS:
		_fail("too few floor props: %d" % floor_count)
		return
	if wall_count < MIN_WALL_PROPS:
		_fail("too few wall props: %d" % wall_count)
		return
	if hideable_count < MIN_HIDEABLE_PROPS or hideable_count > MAX_HIDEABLE_PROPS:
		_fail("unexpected hideable count: %d" % hideable_count)
		return
	if owner_modules.size() >= 34:
		_fail("props are too evenly spread across nearly every space: modules=%d" % owner_modules.size())
		return

	print("PROC_MAZE_PROPS_VALIDATION PASS total=%d floor=%d wall=%d hideable=%d modules=%d" % [
		total_count,
		floor_count,
		wall_count,
		hideable_count,
		owner_modules.size(),
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

func _node_positions_in_group(root: Node, group_name: String) -> Array[Vector3]:
	var result: Array[Vector3] = []
	for node in _nodes_in_group(root, group_name):
		var node3d := node as Node3D
		if node3d != null:
			result.append(node3d.global_position)
	return result

func _marker_positions(root: Node) -> Array[Vector3]:
	var result: Array[Vector3] = []
	var markers := root.get_node_or_null("LevelRoot/Markers")
	if markers == null:
		return result
	for child in markers.get_children():
		var marker := child as Node3D
		if marker != null:
			result.append(marker.global_position)
	return result

func _is_near_positions(position: Vector3, points: Array[Vector3], distance: float) -> bool:
	for point in points:
		if Vector2(position.x, position.z).distance_to(Vector2(point.x, point.z)) < distance:
			return true
	return false

func _fail(message: String) -> void:
	push_error("PROC_MAZE_PROPS_VALIDATION FAIL %s" % message)
	quit(1)
