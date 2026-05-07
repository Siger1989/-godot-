extends SceneTree

const SCENE_PATH := "res://scenes/tests/Test_ProcMazeMap.tscn"

func _init() -> void:
	if not ResourceLoader.exists(SCENE_PATH):
		push_error("TEST_PROC_MAZE_VALIDATION FAIL missing scene: %s" % SCENE_PATH)
		quit(1)
		return
	var packed = load(SCENE_PATH) as PackedScene
	if packed == null:
		push_error("TEST_PROC_MAZE_VALIDATION FAIL cannot load scene: %s" % SCENE_PATH)
		quit(1)
		return
	var root = packed.instantiate() as Node3D
	if root == null:
		push_error("TEST_PROC_MAZE_VALIDATION FAIL scene root is not Node3D.")
		quit(1)
		return
	get_root().add_child(root)
	var result = {}
	if root.has_method("rebuild"):
		result = root.rebuild()
	else:
		result = root.get_meta("proc_maze_last_result", {})
	await process_frame
	await process_frame
	if root.has_method("_print_result"):
		root._print_result(result)
	if bool(result.get("ok", false)):
		var debug_visuals := _get_nodes_in_group(root, "proc_maze_debug")
		var debug_labels := _get_nodes_in_group(root, "proc_maze_debug_label")
		var debug_routes := _get_nodes_in_group(root, "proc_maze_debug_route")
		var guidance_arrows := _get_nodes_in_group(root, "proc_guidance_graffiti")
		if not debug_visuals.is_empty() or not debug_labels.is_empty() or not debug_routes.is_empty():
			push_error("TEST_PROC_MAZE_VALIDATION FAIL formal playable scene still contains debug map markers.")
			quit(1)
			return
		if not guidance_arrows.is_empty():
			push_error("TEST_PROC_MAZE_VALIDATION FAIL formal playable scene still contains glowing guidance graffiti markers.")
			quit(1)
			return
		print("TEST_PROC_MAZE_VALIDATION PASS seed=%s rooms=%s main=%s branches=%s loops=%s macro_loops=%s macro_cycle=%s largest_cycle=%s macro_a=%s macro_b=%s small_loops=%s dead=%s long=%s l_turn=%s l_room=%s internal_large=%s hubs=%s plain_rect=%s large=%s special=%s narrow_corridor=%s normal_corridor=%s normal_room=%s large_width=%s hub_width=%s features=%s dark_zones=%s low_walls=%s red_lights=%s red_attractors=%s overlap=%s door_to_wall=%s door_reveal_blocker=%s fps=%s draw_calls=%s lights=%s light_sources=%s ambient=%s" % [
			str(result.get("seed", "")),
			str(result.get("total_rooms", "")),
			str(result.get("main_path_length", "")),
			str(result.get("branch_count", "")),
			str(result.get("loop_count", "")),
			str(result.get("macro_loop_count", "")),
			str(result.get("macro_cycle_length", "")),
			str(result.get("largest_simple_cycle_length", "")),
			str(result.get("macro_route_a_length", "")),
			str(result.get("macro_route_b_length", "")),
			str(result.get("small_loop_count", "")),
			str(result.get("dead_end_count", "")),
			str(result.get("long_corridor_count", "")),
			str(result.get("l_turn_count", "")),
			str(result.get("l_room_count", "")),
			str(result.get("internal_large_count", "")),
			str(result.get("hub_count", "")),
			str(result.get("plain_rect_count", "")),
			str(result.get("large_room_count", "")),
			str(result.get("special_count", "")),
			str(result.get("narrow_corridor_count", "")),
			str(result.get("normal_corridor_count", "")),
			str(result.get("normal_room_count", "")),
			str(result.get("large_width_count", "")),
			str(result.get("hub_width_count", "")),
			str(result.get("feature_anchor_count", "")),
			str(result.get("dark_zone_count", "")),
			str(result.get("feature_low_wall_count", "")),
			str(result.get("red_alarm_light_count", "")),
			str(result.get("red_alarm_attractor_count", "")),
			str(result.get("has_overlap", "")),
			str(result.get("has_door_to_wall", "")),
			str(result.get("has_door_reveal_blocker", "")),
			str(result.get("fps", "")),
			str(result.get("draw_calls", "")),
			str(result.get("active_light_count", "")),
			str(result.get("active_light_source_count", "")),
			str(result.get("world_ambient_energy", "")),
		])
		quit(0)
	else:
		push_error("TEST_PROC_MAZE_VALIDATION FAIL")
		for issue in result.get("issues", []):
			push_error(str(issue))
		quit(1)

func _get_nodes_in_group(root_node: Node, group_name: String) -> Array:
	var result := []
	_collect_nodes_in_group(root_node, group_name, result)
	return result

func _collect_nodes_in_group(node: Node, group_name: String, result: Array) -> void:
	if node.is_in_group(group_name):
		result.append(node)
	for child in node.get_children():
		_collect_nodes_in_group(child, group_name, result)
