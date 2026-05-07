extends RefCounted

const GENERATOR_VERSION := "proc_maze_fixed_layout_v0.16_red_alarm_escape_branch"

var _registry

func _init(registry = null) -> void:
	_registry = registry

func generate_fixed(seed: int) -> Dictionary:
	var main_path = PackedStringArray([
		"N00", "N01", "N02", "N03", "N04", "N05", "N06", "N07", "N08", "N09",
		"B28", "B29", "N10", "N11", "N12", "N13", "N14", "N15", "N16", "N17",
	])

	var nodes: Array[Dictionary] = [
		_node("N00", "normal_room", 0, 0, 0, "area_0", true, false, false, false, false, true, false, [], "normal_room_start_open"),
		_node("N01", "corridor_long_straight", 3, 0, 0, "area_0", true, false, false, true, false, false, false, [], "normal_corridor_long_release_to_squeeze"),
		_node("N02", "corridor_l_turn", 9, 0, 0, "area_0", true, false, false, false, false, false, false, _cells([[0, 0], [1, 0], [1, 1]]), "narrow_l_turn_west_to_north"),
		_node("N03", "normal_room", 9, 2, 0, "area_0", true, false, false, false, false, false, false, [], "normal_room_after_corridor"),
		_node("N04", "corridor_narrow_straight", 10, 5, 0, "area_0", true, false, false, false, false, false, false, [], "narrow_vertical_choke_area0"),
		_node("N05", "hub_room_4_doors", 9, 9, 0, "area_0", true, true, false, false, false, false, false, [], _feature_signature("pillar_hall", "irregular_pillars", "macro_split_3_way", "warm_local", "none", "macro_split_a"), "pillar_hall"),
		_node("N06", "hub_room_4_doors", 13, 9, 0, "area_1", true, true, false, false, false, false, false, [], "hub_four_doors_area1"),
		_node("N07", "corridor_long_straight", 17, 10, 0, "area_1", true, false, false, true, false, false, false, [], "normal_corridor_long_main_pressure"),
		_node("N08", "corridor_l_turn", 23, 10, 0, "area_1", true, false, false, false, false, false, false, _cells([[0, 0], [1, 0], [1, 1]]), "narrow_l_turn_long_exit"),
		_node("N09", "room_l_shape", 23, 12, 0, "area_2", true, false, false, false, false, false, false, _cells([[0, 0], [1, 0], [2, 0], [0, 1], [0, 2]]), "upper_l_room_turn_pressure"),
		_node("N10", "corridor_narrow_straight", 23, 15, 0, "area_2", true, false, false, false, false, false, false, [], "upper_narrow_corridor_choke"),
		_node("N11", "room_l_shape", 21, 19, 0, "area_2", true, false, false, false, false, false, false, _cells([[2, 0], [1, 0], [1, 1], [1, 2], [0, 2]]), "upper_l_room_pre_merge"),
		_node("N12", "hub_room_4_doors", 17, 20, 0, "area_2", true, true, false, false, false, false, false, [], "hub_merge_area2_warm_local", "", "", true),
		_node("N13", "corridor_long_straight", 11, 21, 0, "area_3", true, false, false, true, false, false, false, [], "normal_corridor_long_area3_bridge"),
		_node("N14", "room_l_shape", 8, 20, 0, "area_3", true, false, false, false, false, false, false, _cells([[0, 0], [1, 0], [2, 0], [2, 1], [2, 2]]), "normal_l_room_turn_anchor"),
		_node("N15", "large_room_split_ew", 4, 19, 0, "area_3", true, false, false, false, false, false, false, [], "large_split_transition_room"),
		_node("N16", "corridor_long_straight", -2, 20, 0, "area_3", true, false, false, true, false, false, false, [], "dark_corridor_end_exit_run", "", "Dark_Corridor_End"),
		_node("N17", "room_wide", -6, 18, 0, "area_3", true, false, false, false, false, false, true, [], "wide_exit_room"),
		_node("B18", "large_room_offset_inner_door", 2, 3, 0, "area_0", false, false, false, false, false, false, false, [], "area0_compound_branch_offset_anchor"),
		_node("B20", "room_wide", 6, 5, 0, "area_0", false, false, false, false, false, false, false, _cells([[0, 0], [1, 0], [2, 0], [0, 1], [1, 1], [2, 1], [3, 1], [0, 2], [1, 2], [2, 2], [3, 2]]), "area0_notched_wide_room_branch_to_split"),
		_node("B22", "corridor_narrow_straight", 12, 1, 0, "area_0", false, false, false, false, false, false, false, [], "narrow_dead_approach"),
		_node("B23", "room_wide", 11, -2, 0, "area_0", false, false, true, false, false, false, false, [], "no_light_room_wide_dead_end_area0", "", "NoLight_Room"),
		_node("B24", "large_room_with_side_chamber", 12, 13, 0, "area_1", false, false, false, false, false, false, false, [], "large_side_chamber_route_b_room", "", "", true),
		_node("B25", "special_2x2", 16, 13, 0, "area_1", false, false, false, false, true, false, false, [], _feature_signature("low_wall_maze_hall", "half_height_wall_baffles", "macro_route_b_large_room", "warm_local", "low_wall_cluster", "route_b_cover_and_memory"), "low_wall_maze_hall"),
		_node("B26", "normal_room", 20, 15, 0, "area_1", false, false, false, false, false, false, false, [], "lower_route_room_connector_replaced_patch"),
		_node("B27", "room_l_shape", 18, 18, 0, "area_2", false, false, false, false, false, false, false, _cells([[2, 0], [1, 0], [1, 1], [0, 1]]), "lower_route_l_room_turn"),
		_node("B37", "room_l_shape", 20, 18, 0, "area_2", false, false, false, false, false, false, false, _cells([[1, 0], [2, 0], [1, 1], [0, 1]]), "lower_route_l_room_merge_antechamber"),
		_node("B28", "special_2x2", 26, 12, 0, "area_2", false, false, false, false, true, false, false, [], _feature_signature("dark_doorway_room", "lit_room_to_dark_interior", "macro_route_a_dark_door", "warm_threshold_to_unlit", "none", "unknown_dark_anchor"), "dark_doorway_room"),
		_node("B29", "corridor_offset", 24, 16, 0, "area_2", false, false, false, false, false, false, false, _cells([[2, 0], [1, 0], [1, 1], [0, 1]]), "dark_doorway_interior_special_loop_area2", "", "Dark_Doorway_Interior"),
		_node("B30", "special_2x2", 6, 23, 0, "area_3", false, false, true, false, true, false, false, [], _feature_signature("box_heap_hall", "irregular_box_heap", "dead_end_anchor", "warm_local", "asymmetric_box_heap", "deep_branch_memory"), "box_heap_hall"),
		_node("B31", "normal_room", 9, 13, 0, "area_0", false, false, false, false, false, false, false, [], "lower_route_room_after_split"),
		_node("B32", "room_wide", 24, 18, 0, "area_2", false, false, true, false, false, false, false, [], "dark_backroom_wide_dead_end_area2_offset", "", "Dark_BackRoom"),
		_node("B33", "room_wide", 13, 23, 0, "area_3", false, false, true, false, false, false, false, [], "dark_backroom_wide_dead_end_after_merge", "", "Dark_BackRoom"),
		_node("B34", "normal_room", -6, 21, 0, "area_3", false, false, false, false, false, false, false, [], "normal_loop_step_area3"),
		_node("B35", "corridor_t_junction", 3, 22, 0, "area_3", false, false, false, false, false, false, false, _cells([[0, 1], [1, 1], [2, 1], [1, 2]]), "dark_turn_corner_area3_return", "", "Dark_Turn_Corner"),
		_node("B36", "corridor_long_straight", -3, 22, 0, "area_3", false, false, false, true, false, false, false, [], "normal_corridor_area3_mid"),
		_node("B38", "corridor_narrow_straight", 21, 19, 0, "area_2", false, false, false, false, false, false, false, _cells([[0, 1]]), "macro_b_single_cell_merge_choke"),
		_node("W40", "corridor_l_turn", -2, 1, 0, "area_outer_west", false, false, false, false, false, false, false, _cells([[1, 0], [0, 0], [0, 1]]), "outer_macro_west_l_turn_from_start"),
		_node("W41", "large_room_with_side_chamber", -4, 3, 0, "area_outer_west", false, true, false, false, false, false, false, [], _feature_signature("side_chamber_hall", "small_side_chamber", "outer_route_side_room", "warm_local", "sparse_side_room", "outer_route_secondary_explore"), "side_chamber_hall"),
		_node("W42", "corridor_t_junction", -5, 7, 0, "area_outer_west", false, false, false, false, false, false, false, _cells([[1, 0], [0, 0], [0, 1], [1, 1], [2, 1]]), "outer_macro_west_t_junction_bend"),
		_node("W43", "room_l_shape", -8, 7, 0, "area_outer_west", false, false, false, false, false, false, false, _cells([[2, 0], [1, 0], [0, 0], [0, 1], [0, 2]]), "outer_macro_west_l_room_01"),
		_node("W47", "large_room_offset_inner_door", -11, 10, 0, "area_outer_west", false, true, false, false, false, false, false, [], _feature_signature("red_alarm_hall", "localized_red_emergency_light", "outer_dark_alcove_offset_door", "dark_with_red_side_spill", "none", "outer_route_abnormal_anchor"), "red_alarm_hall", "Dark_Alcove"),
		_node("W44", "corridor_offset", -7, 13, 0, "area_outer_west", false, false, false, false, false, false, false, _cells([[0, 0], [1, 0], [1, 1], [2, 1]]), "outer_macro_west_offset_corridor_01"),
		_node("W48", "room_wide", -2, 8, 0, "area_outer_west", false, false, false, false, false, false, false, _cells([[0, 0], [1, 0], [2, 0], [2, 1], [2, 2], [1, 2], [0, 2]]), "outer_macro_west_escape_branch_notched_room"),
		_node("W49", "room_wide", -5, 11, 0, "area_outer_west", false, false, false, false, false, false, false, _cells([[3, 0], [3, 1], [2, 1], [1, 1], [0, 1], [0, 2]]), "outer_macro_west_escape_branch_broken_wide_corridor"),
		_node("W45", "corridor_offset", -8, 15, 0, "area_outer_west", false, false, false, false, false, false, false, _cells([[2, 0], [1, 0], [1, 1], [0, 1]]), "outer_macro_west_offset_corridor_02"),
		_node("W46", "large_room_split_ns", -10, 17, 0, "area_outer_west", false, false, false, false, false, false, false, [], _feature_signature("split_hall", "offset_full_height_partition", "outer_route_return_split", "warm_local", "none", "outer_route_return_anchor"), "split_hall"),
	]

	var edges: Array[Dictionary] = []
	for i in range(main_path.size() - 1):
		edges.append(_edge(main_path[i], main_path[i + 1], "main", false))
	edges.append_array([
		_edge("N00", "B18", "branch_loop", false),
		_edge("B18", "B20", "branch_loop", false),
		_edge("B20", "N04", "branch_loop", true),
		_edge("N03", "B22", "branch_dead", false),
		_edge("B22", "B23", "branch_dead", false),
		_edge("N05", "B31", "macro_loop_b", false),
		_edge("B31", "B24", "macro_loop_b", false),
		_edge("B24", "B25", "macro_loop_b", false),
		_edge("B25", "B26", "macro_loop_b", false),
		_edge("B26", "B27", "macro_loop_b", false),
		_edge("B27", "B37", "macro_loop_b", false),
		_edge("B37", "B38", "macro_loop_b", false),
		_edge("B38", "N12", "macro_loop_b", true),
		_edge("N11", "B32", "branch_dead", false),
		_edge("N13", "B33", "branch_dead", false),
		_edge("B35", "B30", "special_dead", false),
		_edge("N17", "B34", "branch_loop", false),
		_edge("B34", "B36", "branch_loop", false),
		_edge("B36", "B35", "branch_loop", false),
		_edge("B35", "N15", "branch_loop", true),
		_edge("N00", "W40", "macro_loop_outer", false),
		_edge("W40", "W41", "macro_loop_outer", false),
		_edge("W41", "W42", "macro_loop_outer", false),
		_edge("W42", "W43", "macro_loop_outer", false),
		_edge("W43", "W47", "macro_loop_outer", false),
		_edge("W47", "W44", "macro_loop_outer", false),
		_edge("W42", "W48", "branch_loop", false),
		_edge("W48", "W49", "branch_loop", false),
		_edge("W49", "W44", "branch_loop", true),
		_edge("W44", "W45", "macro_loop_outer", false),
		_edge("W45", "W46", "macro_loop_outer", false),
		_edge("W46", "N17", "macro_loop_outer", true),
	])

	return {
		"seed": seed,
		"generator_version": GENERATOR_VERSION,
		"mode": "fixed_layout_macro_loop_test",
		"cell_size": _cell_size(),
		"nodes": nodes,
		"edges": edges,
		"main_path": main_path,
		"macro_loop": _macro_loop(),
		"small_loops": _small_loops(),
		"areas": PackedStringArray(["area_0", "area_1", "area_2", "area_3", "area_outer_west"]),
		"branch_count": 12,
	}

func _node(
	node_id: String,
	module_id: String,
	x: int,
	z: int,
	rotation: int,
	area_id: String,
	is_main_path: bool,
	is_hub: bool,
	is_dead_end: bool,
	is_long_corridor: bool,
	is_special: bool,
	is_entrance: bool,
	is_exit: bool,
	shape_cells: Array = [],
	room_signature := "",
	feature_template := "",
	dark_zone := "",
	red_alarm_extra := false
) -> Dictionary:
	var footprint = Vector2i(1, 1)
	var module = {}
	if _registry != null and _registry.has_method("get_footprint_size"):
		footprint = _registry.get_footprint_size(module_id)
	if _registry != null and _registry.has_method("get_module"):
		module = _registry.get_module(module_id)
	var kind = String(module.get("space_kind", module.get("type", "room")))
	var signature = room_signature
	var feature = feature_template.strip_edges()
	if signature.is_empty():
		signature = "%s_default" % module_id
	if not feature.is_empty() and not signature.contains(feature):
		signature = "%s_%s" % [feature, signature]
	return {
		"id": node_id,
		"module_id": module_id,
		"scene_path": String(module.get("scene_path", "")),
		"type": String(module.get("type", "room")),
		"space_kind": kind,
		"width_tier": String(module.get("width_tier", "")),
		"room_signature": signature,
		"feature_template": feature,
		"dark_zone": dark_zone.strip_edges(),
		"red_alarm_extra": red_alarm_extra,
		"shape_cells": shape_cells,
		"footprint": {"x": x, "z": z, "w": footprint.x, "h": footprint.y},
		"rotation": rotation,
		"area_id": area_id,
		"is_main_path": is_main_path,
		"is_hub": is_hub,
		"is_dead_end": is_dead_end,
		"is_long_corridor": is_long_corridor,
		"is_special": is_special,
		"is_entrance": is_entrance,
		"is_exit": is_exit,
	}

func _cells(values: Array) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for value in values:
		result.append(Vector2i(int(value[0]), int(value[1])))
	return result

func _edge(a: String, b: String, kind: String, closes_loop: bool) -> Dictionary:
	return {
		"id": "E_%s_%s" % [a, b],
		"a": a,
		"b": b,
		"kind": kind,
		"closes_loop": closes_loop,
	}

func _macro_loop() -> Dictionary:
	return {
		"id": "MacroLoop_OuterWest_N00_to_N17",
		"split_node": "N00",
		"merge_node": "N17",
		"route_a_name": "outer_west_feature_route",
		"route_b_name": "inner_main_feature_route",
		"route_a": PackedStringArray(["N00", "W40", "W41", "W42", "W43", "W47", "W44", "W45", "W46", "N17"]),
		"route_b": PackedStringArray(["N00", "N01", "N02", "N03", "N04", "N05", "N06", "N07", "N08", "N09", "B28", "B29", "N10", "N11", "N12", "N13", "N14", "N15", "N16", "N17"]),
	}

func _small_loops() -> Array[Dictionary]:
	return [
		{
			"id": "SmallLoop_Area0_OffsetReturn",
			"route": PackedStringArray(["N00", "B18", "B20", "N04", "N03", "N02", "N01", "N00"]),
		},
		{
			"id": "SmallLoop_Area3_Return",
			"route": PackedStringArray(["N15", "N16", "N17", "B34", "B36", "B35", "N15"]),
		},
		{
			"id": "SmallLoop_OuterWest_RedAlarmBypass",
			"route": PackedStringArray(["W42", "W43", "W47", "W44", "W49", "W48", "W42"]),
		},
	]

func _feature_signature(feature_room_type: String, main_feature: String, door_layout: String, light_profile: String, prop_group: String, gameplay_role: String) -> String:
	return "feature_room_type=%s|main_feature=%s|door_layout=%s|light_profile=%s|prop_group=%s|gameplay_role=%s" % [
		feature_room_type,
		main_feature,
		door_layout,
		light_profile,
		prop_group,
		gameplay_role,
	]

func _cell_size() -> float:
	if _registry != null:
		return float(_registry.get("cell_size"))
	return 2.5
