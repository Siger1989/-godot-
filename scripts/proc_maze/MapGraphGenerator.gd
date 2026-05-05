extends RefCounted

const GENERATOR_VERSION := "proc_maze_fixed_layout_v0.10_door_reveal_clearance"

var _registry

func _init(registry = null) -> void:
	_registry = registry

func generate_fixed(seed: int) -> Dictionary:
	var main_path = PackedStringArray()
	for i in range(18):
		main_path.append("N%02d" % i)

	var nodes: Array[Dictionary] = [
		_node("N00", "normal_room", 0, 0, 0, "area_0", true, false, false, false, false, true, false, [], "normal_room_start_open"),
		_node("N01", "corridor_long_straight", 3, 0, 0, "area_0", true, false, false, true, false, false, false, [], "normal_corridor_long_release_to_squeeze"),
		_node("N02", "corridor_l_turn", 9, 0, 0, "area_0", true, false, false, false, false, false, false, _cells([[0, 0], [1, 0], [1, 1]]), "narrow_l_turn_west_to_north"),
		_node("N03", "normal_room", 9, 2, 0, "area_0", true, false, false, false, false, false, false, [], "normal_room_after_corridor"),
		_node("N04", "corridor_narrow_straight", 10, 5, 0, "area_0", true, false, false, false, false, false, false, [], "narrow_vertical_choke_area0"),
		_node("N05", "hub_room_partitioned", 9, 9, 0, "area_0", true, true, false, false, false, false, false, [], "macro_split_partitioned_hub_a"),
		_node("N06", "hub_room_4_doors", 13, 9, 0, "area_1", true, true, false, false, false, false, false, [], "hub_four_doors_area1"),
		_node("N07", "corridor_long_straight", 17, 10, 0, "area_1", true, false, false, true, false, false, false, [], "normal_corridor_long_main_pressure"),
		_node("N08", "corridor_l_turn", 23, 10, 0, "area_1", true, false, false, false, false, false, false, _cells([[0, 0], [1, 0], [1, 1]]), "narrow_l_turn_long_exit"),
		_node("N09", "room_l_shape", 23, 12, 0, "area_2", true, false, false, false, false, false, false, _cells([[0, 0], [1, 0], [2, 0], [0, 1], [0, 2]]), "upper_l_room_turn_pressure"),
		_node("N10", "corridor_narrow_straight", 23, 15, 0, "area_2", true, false, false, false, false, false, false, [], "upper_narrow_corridor_choke"),
		_node("N11", "corridor_offset", 21, 19, 0, "area_2", true, false, false, false, false, false, false, _cells([[2, 0], [1, 0], [1, 1], [0, 1]]), "upper_offset_pre_merge"),
		_node("N12", "hub_room_partitioned", 17, 20, 0, "area_2", true, true, false, false, false, false, false, [], "macro_merge_partitioned_hub_b"),
		_node("N13", "corridor_long_straight", 11, 21, 0, "area_3", true, false, false, true, false, false, false, [], "normal_corridor_long_area3_bridge"),
		_node("N14", "room_l_shape", 8, 20, 0, "area_3", true, false, false, false, false, false, false, _cells([[0, 0], [1, 0], [2, 0], [2, 1], [2, 2]]), "normal_l_room_turn_anchor"),
		_node("N15", "large_room_split_ew", 4, 19, 0, "area_3", true, false, false, false, false, false, false, [], "large_split_ew_anchor"),
		_node("N16", "corridor_long_straight", -2, 20, 0, "area_3", true, false, false, true, false, false, false, [], "normal_corridor_long_exit_run"),
		_node("N17", "room_wide", -6, 18, 0, "area_3", true, false, false, false, false, false, true, [], "wide_exit_room"),
		_node("B18", "large_room_offset_inner_door", 2, 3, 0, "area_0", false, false, false, false, false, false, false, [], "area0_compound_branch_offset_anchor"),
		_node("B20", "room_wide", 6, 5, 0, "area_0", false, false, false, false, false, false, false, _cells([[0, 0], [1, 0], [2, 0], [0, 1], [1, 1], [2, 1], [3, 1], [0, 2], [1, 2], [2, 2], [3, 2]]), "area0_notched_wide_room_branch_to_split"),
		_node("B22", "corridor_narrow_straight", 12, 1, 0, "area_0", false, false, false, false, false, false, false, [], "narrow_dead_approach"),
		_node("B23", "room_wide", 11, -2, 0, "area_0", false, false, true, false, false, false, false, [], "wide_dead_end_area0"),
		_node("B24", "large_room_with_side_chamber", 12, 13, 0, "area_1", false, false, false, false, false, false, false, [], "lower_route_large_side_chamber"),
		_node("B25", "large_room_split_ew", 16, 13, 0, "area_1", false, false, false, false, false, false, false, [], "lower_route_large_split_ew"),
		_node("B26", "normal_room", 20, 15, 0, "area_1", false, false, false, false, false, false, false, [], "lower_route_room_connector_replaced_patch"),
		_node("B27", "room_l_shape", 18, 18, 0, "area_2", false, false, false, false, false, false, false, _cells([[2, 0], [1, 0], [1, 1], [0, 1]]), "lower_route_l_room_turn"),
		_node("B37", "room_l_shape", 20, 18, 0, "area_2", false, false, false, false, false, false, false, _cells([[1, 0], [2, 0], [1, 1], [0, 1]]), "lower_route_l_room_merge_antechamber"),
		_node("B28", "special_2x2", 26, 12, 0, "area_2", false, false, false, false, true, false, false, [], "special_reserve_area2"),
		_node("B29", "corridor_offset", 24, 16, 0, "area_2", false, false, false, false, false, false, false, _cells([[2, 0], [1, 0], [1, 1], [0, 1]]), "offset_corridor_special_loop_area2"),
		_node("B30", "special_2x2", 6, 23, 0, "area_3", false, false, true, false, true, false, false, [], "special_dead_anchor_area3"),
		_node("B31", "normal_room", 9, 13, 0, "area_0", false, false, false, false, false, false, false, [], "lower_route_room_after_split"),
		_node("B32", "room_wide", 24, 18, 0, "area_2", false, false, true, false, false, false, false, [], "wide_dead_end_area2_offset"),
		_node("B33", "room_wide", 13, 23, 0, "area_3", false, false, true, false, false, false, false, [], "wide_dead_end_after_merge"),
		_node("B34", "normal_room", -6, 21, 0, "area_3", false, false, false, false, false, false, false, [], "normal_loop_step_area3"),
		_node("B35", "corridor_t_junction", 3, 22, 0, "area_3", false, false, false, false, false, false, false, _cells([[0, 1], [1, 1], [2, 1], [1, 2]]), "narrow_t_junction_area3_return"),
		_node("B36", "corridor_long_straight", -3, 22, 0, "area_3", false, false, false, true, false, false, false, [], "normal_corridor_area3_mid"),
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
		_edge("B37", "N12", "macro_loop_b", true),
		_edge("N09", "B28", "special_loop", false),
		_edge("B28", "B29", "special_loop", false),
		_edge("B29", "N10", "special_loop", true),
		_edge("N11", "B32", "branch_dead", false),
		_edge("N13", "B33", "branch_dead", false),
		_edge("B35", "B30", "special_dead", false),
		_edge("N17", "B34", "branch_loop", false),
		_edge("B34", "B36", "branch_loop", false),
		_edge("B36", "B35", "branch_loop", false),
		_edge("B35", "N15", "branch_loop", true),
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
		"areas": PackedStringArray(["area_0", "area_1", "area_2", "area_3"]),
		"branch_count": 8,
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
	room_signature := ""
) -> Dictionary:
	var footprint = Vector2i(1, 1)
	var module = {}
	if _registry != null and _registry.has_method("get_footprint_size"):
		footprint = _registry.get_footprint_size(module_id)
	if _registry != null and _registry.has_method("get_module"):
		module = _registry.get_module(module_id)
	var kind = String(module.get("space_kind", module.get("type", "room")))
	var signature = room_signature
	if signature.is_empty():
		signature = "%s_default" % module_id
	return {
		"id": node_id,
		"module_id": module_id,
		"scene_path": String(module.get("scene_path", "")),
		"type": String(module.get("type", "room")),
		"space_kind": kind,
		"width_tier": String(module.get("width_tier", "")),
		"room_signature": signature,
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
		"id": "MacroLoop_SplitA_N05_MergeB_N12",
		"split_node": "N05",
		"merge_node": "N12",
		"route_a_name": "upper_corridor_spine",
		"route_b_name": "lower_compound_room_arc",
		"route_a": PackedStringArray(["N05", "N06", "N07", "N08", "N09", "N10", "N11", "N12"]),
		"route_b": PackedStringArray(["N05", "B31", "B24", "B25", "B26", "B27", "B37", "N12"]),
	}

func _small_loops() -> Array[Dictionary]:
	return [
		{
			"id": "SmallLoop_Area2_Special",
			"route": PackedStringArray(["N09", "B28", "B29", "N10", "N09"]),
		},
		{
			"id": "SmallLoop_Area3_Return",
			"route": PackedStringArray(["N15", "N16", "N17", "B34", "B36", "B35", "N15"]),
		},
	]

func _cell_size() -> float:
	if _registry != null:
		return float(_registry.get("cell_size"))
	return 2.5
