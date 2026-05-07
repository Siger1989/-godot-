extends RefCounted

const MIN_TOTAL_NODES := 30
const MAX_TOTAL_NODES := 48
const MIN_MAIN_PATH := 15
const MAX_MAIN_PATH := 22
const MIN_BRANCHES := 6
const MAX_BRANCHES := 12
const MIN_LOOPS := 3
const MAX_LOOPS := 6
const MIN_DEAD_ENDS := 4
const MAX_DEAD_ENDS := 8
const MIN_LONG_CORRIDORS := 3
const MAX_LONG_CORRIDORS := 5
const MIN_L_TURNS := 2
const MAX_L_TURNS := 7
const MIN_L_ROOMS := 2
const MAX_L_ROOMS := 6
const MIN_INTERNAL_LARGE := 2
const MAX_INTERNAL_LARGE := 6
const MIN_HUBS := 2
const MAX_HUBS := 3
const MIN_SPECIALS := 2
const MAX_SPECIALS := 3
const MAX_PLAIN_RECT_RATIO := 0.35
const MAX_CORRIDOR_TO_ROOM_WIDTH_RATIO := 0.75
const LONG_CORRIDOR_MIN_ASPECT := 2.5
const ROOM_MAX_ASPECT := 1.75
const MIN_MACRO_CYCLE_LENGTH := 10
const MAX_MACRO_CYCLE_LENGTH := 34
const MIN_MACRO_SPLIT_MERGE_ROUTE_NODES := 9
const MIN_MACRO_ROUTE_A_CORRIDOR_SPACES := 4
const MIN_MACRO_ROUTE_B_EXPANDED_SPACES := 6
const MIN_MACRO_ROUTE_B_COMPOUND_SPACES := 2
const MIN_SMALL_LOOPS := 2
const MAX_SMALL_LOOPS := 4
const MIN_FEATURE_ANCHORS := 4
const MAX_FEATURE_ANCHORS := 7
const MAX_PILLAR_HALLS := 1
const MAX_BOX_HEAP_HALLS := 1
const MIN_DARK_ZONES := 4
const FEATURE_TEMPLATES := [
	"pillar_hall",
	"low_wall_maze_hall",
	"box_heap_hall",
	"dark_doorway_room",
	"split_hall",
	"side_chamber_hall",
	"red_alarm_hall",
]
const DARK_ZONE_TEMPLATES := [
	"Dark_Corridor_End",
	"Dark_Doorway_Interior",
	"Dark_Alcove",
	"Dark_Turn_Corner",
	"Dark_BackRoom",
	"NoLight_Room",
]
const REQUIRED_DARK_ZONE_TEMPLATES := [
	"Dark_Doorway_Interior",
	"Dark_Corridor_End",
	"Dark_Turn_Corner",
	"Dark_BackRoom",
	"NoLight_Room",
]

func validate(graph: Dictionary, registry) -> Dictionary:
	var issues: Array[String] = []
	var nodes: Array = graph.get("nodes", [])
	var edges: Array = graph.get("edges", [])
	var main_path: PackedStringArray = graph.get("main_path", PackedStringArray())
	var node_map = _build_node_map(nodes, issues)
	var adjacency = _build_adjacency(nodes, edges, issues)

	_validate_registry(registry, issues)
	_validate_node_metadata(nodes, registry, issues)
	_validate_counts(graph, node_map, adjacency, main_path, edges, issues)
	_validate_space_width_rules(graph, node_map, adjacency, registry, issues)
	_validate_footprints(node_map, issues)
	_validate_edges(node_map, edges, registry, issues)
	_validate_reachability(node_map, adjacency, issues)
	_validate_areas(graph, node_map, edges, issues)
	_validate_distances(node_map, adjacency, issues)
	_validate_main_path_shape(node_map, main_path, issues)
	_validate_monotony(node_map, adjacency, main_path, issues)
	_validate_macro_loop(graph, node_map, adjacency, issues)
	_validate_small_loops(graph, node_map, adjacency, issues)
	_validate_feature_anchors(node_map, adjacency, issues)
	_validate_dark_zones(node_map, issues)

	var metrics = _calculate_metrics(graph, node_map, adjacency, edges, main_path)
	return {
		"ok": issues.is_empty(),
		"issues": issues,
		"metrics": metrics,
	}

func _validate_registry(registry, issues: Array[String]) -> void:
	if registry == null:
		issues.append("ModuleRegistry is null.")
		return
	if registry.has_method("get_module_ids") and registry.get_module_ids().is_empty():
		issues.append("ModuleRegistry is empty.")
	if registry.has_method("errors") and not registry.errors.is_empty():
		for error in registry.errors:
			issues.append("ModuleRegistry error: %s" % error)

func _validate_node_metadata(nodes: Array, registry, issues: Array[String]) -> void:
	for node in nodes:
		var node_id = String(node.get("id", ""))
		var module_id = String(node.get("module_id", ""))
		if node_id.is_empty():
			issues.append("Node has empty id.")
		if not registry.has_module(module_id):
			issues.append("Node `%s` uses unknown module `%s`." % [node_id, module_id])
			continue
		var module = registry.get_module(module_id)
		var rotation = int(node.get("rotation", 0))
		var allowed: Array = module.get("allowed_rotations", [])
		var rotation_allowed = false
		for allowed_rotation in allowed:
			if int(allowed_rotation) == rotation:
				rotation_allowed = true
				break
		if not rotation_allowed:
			issues.append("Node `%s` rotation `%s` not allowed for module `%s`." % [node_id, str(rotation), module_id])
		if rotation not in [0, 90, 180, 270]:
			issues.append("Node `%s` has non-grid rotation `%s`." % [node_id, str(rotation)])
		if bool(node.get("is_main_path", false)) and not bool(module.get("can_be_main_path", false)):
			issues.append("Node `%s` is main path but module `%s` disallows main path." % [node_id, module_id])
		if bool(node.get("is_hub", false)) and not bool(module.get("can_be_hub", false)):
			issues.append("Node `%s` is hub but module `%s` disallows hub." % [node_id, module_id])
		if bool(node.get("is_dead_end", false)) and not bool(module.get("can_be_dead_end", false)):
			issues.append("Node `%s` is dead-end but module `%s` disallows dead-end." % [node_id, module_id])
		if bool(node.get("is_special", false)) and not bool(module.get("can_be_special", false)):
			issues.append("Node `%s` is special but module `%s` disallows special." % [node_id, module_id])
		if _occupied_cells(node).is_empty():
			issues.append("Node `%s` has empty occupied cell set." % node_id)

func _validate_counts(graph: Dictionary, node_map: Dictionary, adjacency: Dictionary, main_path: PackedStringArray, edges: Array, issues: Array[String]) -> void:
	var total_nodes = node_map.size()
	if total_nodes < MIN_TOTAL_NODES or total_nodes > MAX_TOTAL_NODES:
		issues.append("Total nodes out of range: %d." % total_nodes)
	if main_path.size() < MIN_MAIN_PATH or main_path.size() > MAX_MAIN_PATH:
		issues.append("Main path length out of range: %d." % main_path.size())

	var metrics = _calculate_metrics(graph, node_map, adjacency, edges, main_path)
	_check_range("branch count", int(metrics["branch_count"]), MIN_BRANCHES, MAX_BRANCHES, issues)
	_check_range("loop count", int(metrics["loop_count"]), MIN_LOOPS, MAX_LOOPS, issues)
	_check_range("dead-end count", int(metrics["dead_end_count"]), MIN_DEAD_ENDS, MAX_DEAD_ENDS, issues)
	_check_range("long corridor count", int(metrics["long_corridor_count"]), MIN_LONG_CORRIDORS, MAX_LONG_CORRIDORS, issues)
	_check_range("L-turn space count", int(metrics["l_turn_count"]), MIN_L_TURNS, MAX_L_TURNS, issues)
	_check_range("L-room count", int(metrics["l_room_count"]), MIN_L_ROOMS, MAX_L_ROOMS, issues)
	_check_range("internal large room count", int(metrics["internal_large_count"]), MIN_INTERNAL_LARGE, MAX_INTERNAL_LARGE, issues)
	_check_range("hub room count", int(metrics["hub_count"]), MIN_HUBS, MAX_HUBS, issues)
	_check_range("special room count", int(metrics["special_count"]), MIN_SPECIALS, MAX_SPECIALS, issues)
	_check_range("feature anchor count", int(metrics["feature_anchor_count"]), MIN_FEATURE_ANCHORS, MAX_FEATURE_ANCHORS, issues)
	if int(metrics["dark_zone_count"]) < MIN_DARK_ZONES:
		issues.append("Dark zone count too low: %d minimum=%d." % [int(metrics["dark_zone_count"]), MIN_DARK_ZONES])

	var plain_ratio = float(metrics["plain_rect_count"]) / maxf(1.0, float(total_nodes))
	if plain_ratio > MAX_PLAIN_RECT_RATIO:
		issues.append("Ordinary rectangular rooms exceed 35%%: count=%d total=%d ratio=%.2f." % [int(metrics["plain_rect_count"]), total_nodes, plain_ratio])

func _validate_space_width_rules(graph: Dictionary, node_map: Dictionary, adjacency: Dictionary, registry, issues: Array[String]) -> void:
	var cell_size = _graph_cell_size(graph, registry)
	var tier_counts = {}
	var tier_min_width = {}
	var required_corridor_modules = {
		"corridor_narrow_straight": false,
		"corridor_long_straight": false,
		"corridor_l_turn": false,
		"corridor_t_junction": false,
		"corridor_offset": false,
	}

	for node_id in node_map.keys():
		var node: Dictionary = node_map[node_id]
		var module_id = String(node.get("module_id", ""))
		var module = registry.get_module(module_id) if registry != null and registry.has_method("get_module") else {}
		var tier = String(module.get("width_tier", ""))
		var module_type = String(module.get("type", node.get("type", "")))
		var width_cells = _nominal_width_cells(node, module)
		var length_cells = _nominal_length_cells(node, module)
		var width_m = float(width_cells) * cell_size
		var length_m = float(length_cells) * cell_size
		var aspect = maxf(width_m, length_m) / maxf(0.001, minf(width_m, length_m))

		if tier.is_empty():
			issues.append("Node `%s` module `%s` is missing width_tier metadata." % [String(node_id), module_id])
		else:
			tier_counts[tier] = int(tier_counts.get(tier, 0)) + 1
			tier_min_width[tier] = minf(float(tier_min_width.get(tier, width_m)), width_m)

		if required_corridor_modules.has(module_id):
			required_corridor_modules[module_id] = true

		var degree = (adjacency.get(node_id, []) as Array).size()
		var max_degree = int(module.get("max_graph_degree", 99))
		if module_type == "corridor" and degree > max_degree:
			issues.append("Corridor `%s` has too many side doors/connectors: degree=%d max=%d." % [String(node_id), degree, max_degree])

		if module_type == "corridor":
			if tier not in ["narrow_corridor", "normal_corridor"]:
				issues.append("Corridor `%s` uses non-corridor width tier `%s`." % [String(node_id), tier])
			if _space_kind(node) == "long_corridor" and aspect < LONG_CORRIDOR_MIN_ASPECT:
				issues.append("Long corridor `%s` is not directional enough: aspect=%.2f required=%.2f." % [String(node_id), aspect, LONG_CORRIDOR_MIN_ASPECT])
		elif module_type == "room":
			if tier != "normal_room":
				issues.append("Normal room `%s` uses invalid width tier `%s`." % [String(node_id), tier])
			if aspect > ROOM_MAX_ASPECT:
				issues.append("Room `%s` is too corridor-like: aspect=%.2f max=%.2f." % [String(node_id), aspect, ROOM_MAX_ASPECT])
		elif module_type in ["large_room", "hub", "special"]:
			if tier not in ["large_room", "hub_room"]:
				issues.append("Large/hub/special space `%s` uses invalid width tier `%s`." % [String(node_id), tier])

	for required_module in required_corridor_modules.keys():
		if not bool(required_corridor_modules[required_module]):
			issues.append("Required corridor module is missing from graph: `%s`." % required_module)

	for required_tier in ["narrow_corridor", "normal_corridor", "normal_room"]:
		if not tier_counts.has(required_tier):
			issues.append("Required width tier is missing from graph: `%s`." % required_tier)
	if not tier_counts.has("large_room") and not tier_counts.has("hub_room"):
		issues.append("Required large/hub width tier is missing from graph.")

	if tier_min_width.has("narrow_corridor") and tier_min_width.has("normal_corridor"):
		if float(tier_min_width["narrow_corridor"]) >= float(tier_min_width["normal_corridor"]):
			issues.append("Width tiers are not ordered: narrow_corridor >= normal_corridor.")
	if tier_min_width.has("normal_corridor") and tier_min_width.has("normal_room"):
		var corridor_width = float(tier_min_width["normal_corridor"])
		var room_width = float(tier_min_width["normal_room"])
		if corridor_width >= room_width * MAX_CORRIDOR_TO_ROOM_WIDTH_RATIO:
			issues.append("Corridor width is too close to room width: corridor=%.2fm room=%.2fm." % [corridor_width, room_width])
	if tier_min_width.has("normal_room"):
		var large_width = INF
		if tier_min_width.has("large_room"):
			large_width = minf(large_width, float(tier_min_width["large_room"]))
		if tier_min_width.has("hub_room"):
			large_width = minf(large_width, float(tier_min_width["hub_room"]))
		if large_width < INF and float(tier_min_width["normal_room"]) >= large_width:
			issues.append("Width tiers are not ordered: normal_room >= large_room/hub_room.")

func _validate_footprints(node_map: Dictionary, issues: Array[String]) -> void:
	var occupied = {}
	for node_id in node_map.keys():
		for cell in _occupied_cells(node_map[node_id]):
			var key = _cell_key(cell)
			if occupied.has(key):
				issues.append("Footprint overlap at cell %s between `%s` and `%s`." % [key, occupied[key], node_id])
			else:
				occupied[key] = node_id

func _validate_edges(node_map: Dictionary, edges: Array, registry, issues: Array[String]) -> void:
	for edge in edges:
		var a = String(edge.get("a", ""))
		var b = String(edge.get("b", ""))
		if not node_map.has(a) or not node_map.has(b):
			issues.append("Edge `%s` references missing node." % String(edge.get("id", "")))
			continue
		var shared = get_shared_edge(node_map[a], node_map[b])
		if shared.is_empty():
			issues.append("Door edge `%s` does not connect adjacent occupied cells." % String(edge.get("id", "")))
			continue
		var offset_a = int(shared["offset_a"])
		var offset_b = int(shared["offset_b"])
		var side_a = String(shared["side_a"])
		var side_b = String(shared["side_b"])
		var module_a = String(node_map[a].get("module_id", ""))
		var module_b = String(node_map[b].get("module_id", ""))
		if not registry.module_supports_side(module_a, side_a, offset_a):
			issues.append("Door edge `%s` hits unsupported connector `%s:%s:%d`." % [String(edge.get("id", "")), a, side_a, offset_a])
		if not registry.module_supports_side(module_b, side_b, offset_b):
			issues.append("Door edge `%s` hits unsupported connector `%s:%s:%d`." % [String(edge.get("id", "")), b, side_b, offset_b])

func _validate_reachability(node_map: Dictionary, adjacency: Dictionary, issues: Array[String]) -> void:
	var start = _find_flagged_node(node_map, "is_entrance")
	var exit = _find_flagged_node(node_map, "is_exit")
	if start.is_empty() or exit.is_empty():
		issues.append("Entrance or exit node is missing.")
		return
	var distances = _bfs(adjacency, start)
	if not distances.has(exit):
		issues.append("Exit is not reachable from entrance.")
	if distances.size() != node_map.size():
		issues.append("Map graph is not fully connected. Reachable=%d total=%d." % [distances.size(), node_map.size()])

func _validate_areas(graph: Dictionary, node_map: Dictionary, edges: Array, issues: Array[String]) -> void:
	var areas: PackedStringArray = graph.get("areas", PackedStringArray())
	var declared_loop_nodes = _declared_loop_nodes(graph)
	for area_id in areas:
		var area_nodes = {}
		var area_edges = 0
		var declared_loop_node_count = 0
		var has_l_path = false
		var has_recognizable = false
		var has_anchor_room = false
		for node_id in node_map.keys():
			var node: Dictionary = node_map[node_id]
			if String(node.get("area_id", "")) != area_id:
				continue
			area_nodes[node_id] = true
			if declared_loop_nodes.has(String(node_id)):
				declared_loop_node_count += 1
			var kind = _space_kind(node)
			has_l_path = has_l_path or kind == "l_turn" or kind == "l_room"
			has_recognizable = has_recognizable or _is_recognizable_space(node)
			has_anchor_room = has_anchor_room or _is_anchor_room(node)
		for edge in edges:
			var a = String(edge.get("a", ""))
			var b = String(edge.get("b", ""))
			if area_nodes.has(a) and area_nodes.has(b):
				area_edges += 1
		var local_loops = area_edges - area_nodes.size() + 1
		if local_loops < 1 and declared_loop_node_count < 2:
			issues.append("Area `%s` has no local or declared loop participation." % area_id)
		if not has_l_path:
			issues.append("Area `%s` has no L-shaped path/room." % area_id)
		if not has_recognizable:
			issues.append("Area `%s` has no recognizable space structure." % area_id)
		if not has_anchor_room:
			issues.append("Area `%s` has no anchor room; needs large, hub, L-room, wide room, side chamber, or special space." % area_id)

func _validate_distances(node_map: Dictionary, adjacency: Dictionary, issues: Array[String]) -> void:
	var start = _find_flagged_node(node_map, "is_entrance")
	var exit = _find_flagged_node(node_map, "is_exit")
	if start.is_empty():
		return
	var distances = _bfs(adjacency, start)
	if distances.has(exit) and int(distances[exit]) < 9:
		issues.append("Exit is too close to entrance: %d edges." % int(distances[exit]))
	for node_id in node_map.keys():
		var node: Dictionary = node_map[node_id]
		if bool(node.get("is_special", false)) and distances.has(node_id) and int(distances[node_id]) < 6:
			issues.append("Special room `%s` is too close to entrance: %d edges." % [node_id, int(distances[node_id])])

func _validate_main_path_shape(node_map: Dictionary, main_path: PackedStringArray, issues: Array[String]) -> void:
	var turns = 0
	var previous_direction = Vector2i.ZERO
	for i in range(main_path.size() - 1):
		if not node_map.has(main_path[i]) or not node_map.has(main_path[i + 1]):
			continue
		var center_a = _node_center_grid(node_map[main_path[i]])
		var center_b = _node_center_grid(node_map[main_path[i + 1]])
		var delta = center_b - center_a
		var direction = Vector2i(signi(delta.x), signi(delta.y))
		if previous_direction != Vector2i.ZERO and direction != previous_direction:
			turns += 1
		previous_direction = direction
	if turns < 6:
		issues.append("Main path is too straight. Turns=%d." % turns)

func _validate_monotony(node_map: Dictionary, adjacency: Dictionary, main_path: PackedStringArray, issues: Array[String]) -> void:
	var consecutive_plain = 0
	var consecutive_short_connector = 0
	var consecutive_long = 0
	var same_signature_chain = 0
	var previous_signature = ""
	var previous_door_signature = ""
	var straight_door_chain = 1
	var previous_direction = Vector2i.ZERO

	for i in range(main_path.size()):
		if not node_map.has(main_path[i]):
			continue
		var node: Dictionary = node_map[main_path[i]]
		if _is_ordinary_rect_room(node):
			consecutive_plain += 1
		else:
			consecutive_plain = 0
		if consecutive_plain >= 3:
			issues.append("Three adjacent main-path nodes are ordinary rectangular rooms near `%s`." % String(node.get("id", "")))
			break

		if _is_short_connector_space(node, adjacency):
			consecutive_short_connector += 1
		else:
			consecutive_short_connector = 0
		if consecutive_short_connector >= 3:
			issues.append("Three adjacent main-path nodes are short connector spaces near `%s`." % String(node.get("id", "")))
			break

		if _space_kind(node) == "long_corridor":
			consecutive_long += 1
		else:
			consecutive_long = 0
		if consecutive_long > 2:
			issues.append("More than two long corridors are adjacent near `%s`." % String(node.get("id", "")))
			break

		var signature = String(node.get("room_signature", node.get("module_id", "")))
		var door_signature = _door_signature(String(node.get("id", "")), node_map, adjacency)
		if signature == previous_signature and door_signature == previous_door_signature:
			same_signature_chain += 1
		else:
			same_signature_chain = 1
		if same_signature_chain >= 3:
			issues.append("Three adjacent nodes repeat the same room signature and door positions near `%s`." % String(node.get("id", "")))
			break
		previous_signature = signature
		previous_door_signature = door_signature

		if i < main_path.size() - 1 and node_map.has(main_path[i + 1]):
			var center_a = _node_center_grid(node)
			var center_b = _node_center_grid(node_map[main_path[i + 1]])
			var direction = Vector2i(signi(center_b.x - center_a.x), signi(center_b.y - center_a.y))
			if direction == previous_direction and not _breaks_line_of_sight(node):
				straight_door_chain += 1
			else:
				straight_door_chain = 1
			if straight_door_chain > 3:
				issues.append("Main path can show too many continuous doorframes near `%s`." % String(node.get("id", "")))
				break
			previous_direction = direction

	_validate_declared_route_patterns("main path", main_path, node_map, adjacency, issues)

func _validate_declared_route_patterns(label: String, route: PackedStringArray, node_map: Dictionary, adjacency: Dictionary, issues: Array[String]) -> void:
	var consecutive_plain = 0
	var consecutive_short_connector = 0
	for raw_node_id in route:
		var node_id = String(raw_node_id)
		if not node_map.has(node_id):
			continue
		var node: Dictionary = node_map[node_id]
		if _is_ordinary_rect_room(node):
			consecutive_plain += 1
		else:
			consecutive_plain = 0
		if consecutive_plain >= 3:
			issues.append("%s has three ordinary rectangular rooms in a row near `%s`." % [label, node_id])
			return
		if _is_short_connector_space(node, adjacency):
			consecutive_short_connector += 1
		else:
			consecutive_short_connector = 0
		if consecutive_short_connector >= 3:
			issues.append("%s has three short connector spaces in a row near `%s`." % [label, node_id])
			return

func _validate_macro_loop(graph: Dictionary, node_map: Dictionary, adjacency: Dictionary, issues: Array[String]) -> void:
	var macro_value = graph.get("macro_loop", {})
	if typeof(macro_value) != TYPE_DICTIONARY or (macro_value as Dictionary).is_empty():
		issues.append("Macro loop metadata is missing.")
		return

	var macro_loop: Dictionary = macro_value
	var split = String(macro_loop.get("split_node", ""))
	var merge = String(macro_loop.get("merge_node", ""))
	var route_a = _to_string_route(macro_loop.get("route_a", PackedStringArray()))
	var route_b = _to_string_route(macro_loop.get("route_b", PackedStringArray()))

	if split.is_empty() or merge.is_empty():
		issues.append("Macro loop split or merge node is empty.")
		return
	if not node_map.has(split):
		issues.append("Macro loop split node `%s` is missing." % split)
	if not node_map.has(merge):
		issues.append("Macro loop merge node `%s` is missing." % merge)
	if split == merge:
		issues.append("Macro loop split and merge cannot be the same node.")

	var route_a_ok = _validate_open_route(route_a, split, merge, "macro loop route A", node_map, adjacency, issues)
	var route_b_ok = _validate_open_route(route_b, split, merge, "macro loop route B", node_map, adjacency, issues)
	if not route_a_ok or not route_b_ok:
		return
	_validate_declared_route_patterns("macro loop route A", route_a, node_map, adjacency, issues)
	_validate_declared_route_patterns("macro loop route B", route_b, node_map, adjacency, issues)

	if not _routes_have_disjoint_interiors(route_a, route_b):
		issues.append("Macro loop route A and route B share internal nodes.")
	if not _routes_have_no_internal_cross_edges(route_a, route_b, adjacency):
		issues.append("Macro loop routes have a near split/merge cross-connection that weakens the two-route experience.")

	var split_degree = (adjacency.get(split, []) as Array).size()
	var merge_degree = (adjacency.get(merge, []) as Array).size()
	if split_degree != 3:
		issues.append("Macro loop split `%s` must read as one inbound plus two route exits: degree=%d." % [split, split_degree])
	if merge_degree != 3:
		issues.append("Macro loop merge `%s` must read as two route entries plus one outbound: degree=%d." % [merge, merge_degree])

	var cycle_length = route_a.size() + route_b.size() - 2
	if cycle_length < MIN_MACRO_CYCLE_LENGTH or cycle_length > MAX_MACRO_CYCLE_LENGTH:
		issues.append("Macro loop simple cycle length out of range: %d." % cycle_length)
	if route_a.size() < MIN_MACRO_SPLIT_MERGE_ROUTE_NODES or route_b.size() < MIN_MACRO_SPLIT_MERGE_ROUTE_NODES:
		issues.append("Macro loop split-to-merge route is too short: route_a=%d route_b=%d." % [route_a.size(), route_b.size()])

	var signature_a = _route_space_signature(route_a, node_map)
	var signature_b = _route_space_signature(route_b, node_map)
	if signature_a == signature_b:
		issues.append("Macro loop routes repeat the same space-type signature.")
	if not _route_has_kind(route_a, node_map, ["long_corridor", "narrow_corridor", "l_turn", "offset_corridor", "junction"]):
		issues.append("Macro loop route A lacks corridor-pressure spaces.")
	if not _route_has_kind(route_b, node_map, ["normal_room", "l_room", "recognizable_room", "large_internal", "hub", "special"]):
		issues.append("Macro loop route B lacks expanded room spaces.")
	var corridor_pressure_count = _route_kind_count(route_a, node_map, ["long_corridor", "narrow_corridor", "l_turn", "offset_corridor", "junction"])
	if corridor_pressure_count < MIN_MACRO_ROUTE_A_CORRIDOR_SPACES:
		issues.append("Macro loop route A is not corridor-heavy enough: corridor_pressure=%d." % corridor_pressure_count)
	var route_b_expanded_count = _route_kind_count(route_b, node_map, ["normal_room", "l_room", "recognizable_room", "large_internal", "hub", "special"])
	if route_b_expanded_count < MIN_MACRO_ROUTE_B_EXPANDED_SPACES:
		issues.append("Macro loop route B is not expanded-room-heavy enough: expanded=%d." % route_b_expanded_count)
	var route_b_compound_count = _route_kind_count(route_b, node_map, ["large_internal", "hub", "special"])
	if route_b_compound_count < MIN_MACRO_ROUTE_B_COMPOUND_SPACES:
		issues.append("Macro loop route B needs at least %d compound large/hub/special spaces: found=%d." % [MIN_MACRO_ROUTE_B_COMPOUND_SPACES, route_b_compound_count])

	_validate_macro_loop_chokepoints(split, merge, route_a, route_b, adjacency, issues)
	_validate_main_path_alternative(split, merge, route_a, route_b, node_map, adjacency, issues)

func _validate_small_loops(graph: Dictionary, node_map: Dictionary, adjacency: Dictionary, issues: Array[String]) -> void:
	var loops_value = graph.get("small_loops", [])
	var small_loops: Array = loops_value if typeof(loops_value) == TYPE_ARRAY else []
	_check_range("small loop count", small_loops.size(), MIN_SMALL_LOOPS, MAX_SMALL_LOOPS, issues)
	for loop_index in range(small_loops.size()):
		var loop_value = small_loops[loop_index]
		if typeof(loop_value) != TYPE_DICTIONARY:
			issues.append("Small loop %d metadata is not a dictionary." % loop_index)
			continue
		var loop: Dictionary = loop_value
		var route = _to_string_route(loop.get("route", PackedStringArray()))
		var label = "small loop `%s`" % String(loop.get("id", str(loop_index)))
		_validate_closed_route(route, label, node_map, adjacency, issues)
		_validate_declared_route_patterns(label, route, node_map, adjacency, issues)

func _validate_feature_anchors(node_map: Dictionary, adjacency: Dictionary, issues: Array[String]) -> void:
	var template_counts := {}
	var active_count := 0
	for node_id in node_map.keys():
		var node: Dictionary = node_map[node_id]
		var feature := String(node.get("feature_template", ""))
		if feature.is_empty():
			continue
		active_count += 1
		template_counts[feature] = int(template_counts.get(feature, 0)) + 1
		if not FEATURE_TEMPLATES.has(feature):
			issues.append("Feature anchor `%s` uses unknown template `%s`." % [String(node_id), feature])
		if not _is_feature_anchor_space(node):
			issues.append("Feature anchor `%s` must be a large, hub, or special space; kind=%s." % [String(node_id), _space_kind(node)])
		if not String(node.get("room_signature", "")).contains(feature):
			issues.append("Feature anchor `%s` room_signature must include `%s`." % [String(node_id), feature])
		if not _feature_signature_has_required_fields(String(node.get("room_signature", ""))):
			issues.append("Feature anchor `%s` room_signature is missing feature_room_type/main_feature/door_layout/light_profile/prop_group/gameplay_role." % String(node_id))
		if not _is_priority_anchor_location(String(node_id), node, node_map, adjacency):
			issues.append("Feature anchor `%s` is not at a split, merge, transition, dead-end, special, or long-corridor endpoint." % String(node_id))
	if int(template_counts.get("pillar_hall", 0)) > MAX_PILLAR_HALLS:
		issues.append("pillar_hall appears too many times: %d max=%d." % [int(template_counts.get("pillar_hall", 0)), MAX_PILLAR_HALLS])
	if int(template_counts.get("box_heap_hall", 0)) > MAX_BOX_HEAP_HALLS:
		issues.append("box_heap_hall appears too many times: %d max=%d." % [int(template_counts.get("box_heap_hall", 0)), MAX_BOX_HEAP_HALLS])
	if active_count >= MIN_FEATURE_ANCHORS and template_counts.keys().size() < 3:
		issues.append("Feature anchors need at least 3 distinct templates; found=%d." % template_counts.keys().size())

func _validate_dark_zones(node_map: Dictionary, issues: Array[String]) -> void:
	var dark_zone_count := 0
	var has_corridor_end := false
	var template_counts := {}
	for node_id in node_map.keys():
		var node: Dictionary = node_map[node_id]
		var dark_zone := String(node.get("dark_zone", ""))
		if dark_zone.is_empty():
			continue
		dark_zone_count += 1
		template_counts[dark_zone] = int(template_counts.get(dark_zone, 0)) + 1
		if not DARK_ZONE_TEMPLATES.has(dark_zone):
			issues.append("Dark zone `%s` uses unknown template `%s`." % [String(node_id), dark_zone])
		if dark_zone == "Dark_Corridor_End":
			has_corridor_end = true
			if not bool(node.get("is_long_corridor", false)):
				issues.append("Dark_Corridor_End `%s` should be on a long corridor endpoint." % String(node_id))
	if dark_zone_count >= MIN_DARK_ZONES and not has_corridor_end:
		issues.append("Dark zones need at least one Dark_Corridor_End.")
	for required_template in REQUIRED_DARK_ZONE_TEMPLATES:
		if int(template_counts.get(required_template, 0)) < 1:
			issues.append("Dark zone template `%s` is missing from this layout." % required_template)

func _feature_signature_has_required_fields(signature: String) -> bool:
	for field_name in ["feature_room_type=", "main_feature=", "door_layout=", "light_profile=", "prop_group=", "gameplay_role="]:
		if not signature.contains(field_name):
			return false
	return true

func _is_feature_anchor_space(node: Dictionary) -> bool:
	return _space_kind(node) in ["large_internal", "hub", "special"]

func _is_priority_anchor_location(node_id: String, node: Dictionary, node_map: Dictionary, adjacency: Dictionary) -> bool:
	if bool(node.get("is_hub", false)) or bool(node.get("is_special", false)) or bool(node.get("is_dead_end", false)):
		return true
	var degree := (adjacency.get(node_id, []) as Array).size()
	if degree >= 3:
		return true
	if _has_area_transition_neighbor(node_id, node, node_map, adjacency):
		return true
	if _has_long_corridor_neighbor(node_id, node_map, adjacency):
		return true
	return false

func _has_area_transition_neighbor(node_id: String, node: Dictionary, node_map: Dictionary, adjacency: Dictionary) -> bool:
	var area_id := String(node.get("area_id", ""))
	for next_id in adjacency.get(node_id, []):
		if node_map.has(String(next_id)) and String((node_map[String(next_id)] as Dictionary).get("area_id", "")) != area_id:
			return true
	return false

func _has_long_corridor_neighbor(node_id: String, node_map: Dictionary, adjacency: Dictionary) -> bool:
	for next_id in adjacency.get(node_id, []):
		if node_map.has(String(next_id)) and _space_kind(node_map[String(next_id)]) == "long_corridor":
			return true
	return false

func _validate_open_route(
	route: PackedStringArray,
	start: String,
	end: String,
	label: String,
	node_map: Dictionary,
	adjacency: Dictionary,
	issues: Array[String]
) -> bool:
	var ok = true
	if route.size() < 3:
		issues.append("%s is too short: %d nodes." % [label, route.size()])
		return false
	if String(route[0]) != start:
		issues.append("%s does not start at split node `%s`." % [label, start])
		ok = false
	if String(route[route.size() - 1]) != end:
		issues.append("%s does not end at merge node `%s`." % [label, end])
		ok = false
	if not _validate_route_unique(route, label, false, issues):
		ok = false
	if not _validate_route_nodes_and_edges(route, label, node_map, adjacency, issues):
		ok = false
	return ok

func _validate_closed_route(
	route: PackedStringArray,
	label: String,
	node_map: Dictionary,
	adjacency: Dictionary,
	issues: Array[String]
) -> bool:
	var ok = true
	if route.size() < 4:
		issues.append("%s is too short: %d nodes." % [label, route.size()])
		return false
	if String(route[0]) != String(route[route.size() - 1]):
		issues.append("%s is not closed." % label)
		ok = false
	if not _validate_route_unique(route, label, true, issues):
		ok = false
	if not _validate_route_nodes_and_edges(route, label, node_map, adjacency, issues):
		ok = false
	return ok

func _validate_route_unique(route: PackedStringArray, label: String, allow_closed: bool, issues: Array[String]) -> bool:
	var seen = {}
	for i in range(route.size()):
		var node_id = String(route[i])
		if allow_closed and i == route.size() - 1 and node_id == String(route[0]):
			continue
		if seen.has(node_id):
			issues.append("%s repeats node `%s`." % [label, node_id])
			return false
		seen[node_id] = true
	return true

func _validate_route_nodes_and_edges(
	route: PackedStringArray,
	label: String,
	node_map: Dictionary,
	adjacency: Dictionary,
	issues: Array[String]
) -> bool:
	var ok = true
	for node_id in route:
		if not node_map.has(String(node_id)):
			issues.append("%s references missing node `%s`." % [label, String(node_id)])
			ok = false
	for i in range(route.size() - 1):
		var a = String(route[i])
		var b = String(route[i + 1])
		if not _edge_exists(adjacency, a, b):
			issues.append("%s has missing edge `%s` -> `%s`." % [label, a, b])
			ok = false
	return ok

func _validate_macro_loop_chokepoints(
	split: String,
	merge: String,
	route_a: PackedStringArray,
	route_b: PackedStringArray,
	adjacency: Dictionary,
	issues: Array[String]
) -> void:
	var internal_nodes = {}
	_collect_route_internal_nodes(route_a, internal_nodes)
	_collect_route_internal_nodes(route_b, internal_nodes)
	for node_id in internal_nodes.keys():
		if not _path_exists_with_ignored(adjacency, split, merge, {String(node_id): true}):
			issues.append("Macro loop can be blocked by one internal node `%s`." % String(node_id))

func _validate_main_path_alternative(
	split: String,
	merge: String,
	route_a: PackedStringArray,
	route_b: PackedStringArray,
	node_map: Dictionary,
	adjacency: Dictionary,
	issues: Array[String]
) -> void:
	var start = _find_flagged_node(node_map, "is_entrance")
	var exit = _find_flagged_node(node_map, "is_exit")
	if start.is_empty() or exit.is_empty():
		return
	if route_a.size() > 2 and not _path_exists_with_ignored(adjacency, start, exit, {String(route_a[1]): true}):
		issues.append("Main route has no alternative when macro route A is blocked after `%s`." % split)
	if route_b.size() > 2 and not _path_exists_with_ignored(adjacency, start, exit, {String(route_b[1]): true}):
		issues.append("Main route has no alternative when macro route B is blocked after `%s`." % split)
	if not _path_exists_with_ignored(adjacency, split, merge, {}):
		issues.append("Macro loop split `%s` cannot reach merge `%s`." % [split, merge])

func _calculate_metrics(graph: Dictionary, node_map: Dictionary, adjacency: Dictionary, edges: Array, main_path: PackedStringArray) -> Dictionary:
	var component_count = _connected_component_count(node_map, adjacency)
	var loop_count = edges.size() - node_map.size() + component_count
	var dead_end_count = 0
	var long_corridor_count = 0
	var l_turn_count = 0
	var l_room_count = 0
	var internal_large_count = 0
	var hub_count = 0
	var special_count = 0
	var plain_rect_count = 0
	var recognizable_room_count = 0
	var narrow_corridor_count = 0
	var normal_corridor_count = 0
	var normal_room_count = 0
	var large_width_count = 0
	var hub_width_count = 0
	var feature_anchor_count = 0
	var dark_zone_count = 0
	var macro_loop_count = 0
	var macro_route_a_length = 0
	var macro_route_b_length = 0
	var macro_cycle_length = _macro_cycle_length_from_graph(graph, node_map, adjacency)
	if macro_cycle_length > 0:
		macro_loop_count = 1
	var macro_value = graph.get("macro_loop", {})
	if typeof(macro_value) == TYPE_DICTIONARY:
		var macro_loop: Dictionary = macro_value
		macro_route_a_length = _to_string_route(macro_loop.get("route_a", PackedStringArray())).size()
		macro_route_b_length = _to_string_route(macro_loop.get("route_b", PackedStringArray())).size()
	var small_loop_count = _small_loop_count(graph)
	for node_id in node_map.keys():
		var node: Dictionary = node_map[node_id]
		var degree = (adjacency.get(node_id, []) as Array).size()
		var kind = _space_kind(node)
		var tier = String(node.get("width_tier", ""))
		if tier.is_empty():
			tier = _node_width_tier(node)
		if degree == 1 and not bool(node.get("is_entrance", false)) and not bool(node.get("is_exit", false)):
			dead_end_count += 1
		if kind == "long_corridor":
			long_corridor_count += 1
		if kind == "l_turn":
			l_turn_count += 1
		if kind == "l_room":
			l_room_count += 1
		if kind == "large_internal":
			internal_large_count += 1
		if kind == "hub":
			hub_count += 1
		if _is_ordinary_rect_room(node):
			plain_rect_count += 1
		if bool(node.get("is_special", false)):
			special_count += 1
		if _is_recognizable_space(node):
			recognizable_room_count += 1
		if tier == "narrow_corridor":
			narrow_corridor_count += 1
		if tier == "normal_corridor":
			normal_corridor_count += 1
		if tier == "normal_room":
			normal_room_count += 1
		if tier == "large_room":
			large_width_count += 1
		if tier == "hub_room":
			hub_width_count += 1
		if not String(node.get("feature_template", "")).is_empty():
			feature_anchor_count += 1
		if not String(node.get("dark_zone", "")).is_empty():
			dark_zone_count += 1

	return {
		"total_nodes": node_map.size(),
		"main_path_length": main_path.size(),
		"branch_count": int(graph.get("branch_count", 0)),
		"loop_count": loop_count,
		"dead_end_count": dead_end_count,
		"long_corridor_count": long_corridor_count,
		"l_turn_count": l_turn_count,
		"l_room_count": l_room_count,
		"internal_large_count": internal_large_count,
		"hub_count": hub_count,
		"large_room_count": internal_large_count + hub_count,
		"special_count": special_count,
		"plain_rect_count": plain_rect_count,
		"recognizable_room_count": recognizable_room_count,
		"narrow_corridor_count": narrow_corridor_count,
		"normal_corridor_count": normal_corridor_count,
		"normal_room_count": normal_room_count,
		"large_width_count": large_width_count,
		"hub_width_count": hub_width_count,
		"feature_anchor_count": feature_anchor_count,
		"dark_zone_count": dark_zone_count,
		"macro_loop_count": macro_loop_count,
		"macro_route_a_length": macro_route_a_length,
		"macro_route_b_length": macro_route_b_length,
		"macro_cycle_length": macro_cycle_length,
		"largest_simple_cycle_length": macro_cycle_length,
		"small_loop_count": small_loop_count,
	}

func get_shared_edge(a_node: Dictionary, b_node: Dictionary) -> Dictionary:
	var a_rect = _rect(a_node)
	var b_rect = _rect(b_node)
	var b_lookup = {}
	for b_cell in _occupied_cells(b_node):
		b_lookup[_cell_key(b_cell)] = b_cell
	for a_cell in _occupied_cells(a_node):
		var candidates = [
			{"cell": Vector2i(a_cell.x + 1, a_cell.y), "side_a": "east", "side_b": "west", "axis": "z", "line": a_cell.x + 1, "unit": a_cell.y},
			{"cell": Vector2i(a_cell.x - 1, a_cell.y), "side_a": "west", "side_b": "east", "axis": "z", "line": a_cell.x, "unit": a_cell.y},
			{"cell": Vector2i(a_cell.x, a_cell.y + 1), "side_a": "north", "side_b": "south", "axis": "x", "line": a_cell.y + 1, "unit": a_cell.x},
			{"cell": Vector2i(a_cell.x, a_cell.y - 1), "side_a": "south", "side_b": "north", "axis": "x", "line": a_cell.y, "unit": a_cell.x},
		]
		for candidate in candidates:
			var other_cell: Vector2i = candidate["cell"]
			if not b_lookup.has(_cell_key(other_cell)):
				continue
			return {
				"axis": String(candidate["axis"]),
				"line": int(candidate["line"]),
				"unit": int(candidate["unit"]),
				"side_a": String(candidate["side_a"]),
				"side_b": String(candidate["side_b"]),
				"offset_a": _side_offset(a_cell, String(candidate["side_a"]), a_rect),
				"offset_b": _side_offset(other_cell, String(candidate["side_b"]), b_rect),
			}
	return {}

func _build_node_map(nodes: Array, issues: Array[String]) -> Dictionary:
	var node_map = {}
	for node in nodes:
		var node_id = String(node.get("id", ""))
		if node_map.has(node_id):
			issues.append("Duplicate graph node id: %s." % node_id)
		node_map[node_id] = node
	return node_map

func _build_adjacency(nodes: Array, edges: Array, issues: Array[String]) -> Dictionary:
	var adjacency = {}
	for node in nodes:
		adjacency[String(node.get("id", ""))] = []
	for edge in edges:
		var a = String(edge.get("a", ""))
		var b = String(edge.get("b", ""))
		if not adjacency.has(a) or not adjacency.has(b):
			continue
		adjacency[a].append(b)
		adjacency[b].append(a)
	return adjacency

func _to_string_route(value) -> PackedStringArray:
	if typeof(value) == TYPE_PACKED_STRING_ARRAY:
		return value
	var route = PackedStringArray()
	if typeof(value) == TYPE_ARRAY:
		for item in value:
			route.append(String(item))
	return route

func _declared_loop_nodes(graph: Dictionary) -> Dictionary:
	var result = {}
	var macro_value = graph.get("macro_loop", {})
	if typeof(macro_value) == TYPE_DICTIONARY:
		var macro_loop: Dictionary = macro_value
		for node_id in _to_string_route(macro_loop.get("route_a", PackedStringArray())):
			result[String(node_id)] = true
		for node_id in _to_string_route(macro_loop.get("route_b", PackedStringArray())):
			result[String(node_id)] = true
	var loops_value = graph.get("small_loops", [])
	if typeof(loops_value) == TYPE_ARRAY:
		for loop_value in loops_value:
			if typeof(loop_value) != TYPE_DICTIONARY:
				continue
			var loop: Dictionary = loop_value
			for node_id in _to_string_route(loop.get("route", PackedStringArray())):
				result[String(node_id)] = true
	return result

func _edge_exists(adjacency: Dictionary, a: String, b: String) -> bool:
	for next_id in adjacency.get(a, []):
		if String(next_id) == b:
			return true
	return false

func _routes_have_disjoint_interiors(route_a: PackedStringArray, route_b: PackedStringArray) -> bool:
	var route_a_nodes = {}
	for i in range(1, route_a.size() - 1):
		route_a_nodes[String(route_a[i])] = true
	for i in range(1, route_b.size() - 1):
		if route_a_nodes.has(String(route_b[i])):
			return false
	return true

func _routes_have_no_internal_cross_edges(route_a: PackedStringArray, route_b: PackedStringArray, adjacency: Dictionary) -> bool:
	var route_b_nodes = {}
	for i in range(1, route_b.size() - 1):
		route_b_nodes[String(route_b[i])] = true
	for i in range(1, route_a.size() - 1):
		var node_id = String(route_a[i])
		for next_node in adjacency.get(node_id, []):
			if route_b_nodes.has(String(next_node)):
				return false
	return true

func _route_space_signature(route: PackedStringArray, node_map: Dictionary) -> String:
	var parts: Array[String] = []
	for i in range(1, route.size() - 1):
		var node_id = String(route[i])
		if node_map.has(node_id):
			parts.append(_space_kind(node_map[node_id]))
	return "|".join(parts)

func _route_has_kind(route: PackedStringArray, node_map: Dictionary, kinds: Array) -> bool:
	for i in range(1, route.size() - 1):
		var node_id = String(route[i])
		if node_map.has(node_id) and kinds.has(_space_kind(node_map[node_id])):
			return true
	return false

func _route_kind_count(route: PackedStringArray, node_map: Dictionary, kinds: Array) -> int:
	var count = 0
	for i in range(1, route.size() - 1):
		var node_id = String(route[i])
		if node_map.has(node_id) and kinds.has(_space_kind(node_map[node_id])):
			count += 1
	return count

func _collect_route_internal_nodes(route: PackedStringArray, target: Dictionary) -> void:
	for i in range(1, route.size() - 1):
		target[String(route[i])] = true

func _path_exists_with_ignored(adjacency: Dictionary, start: String, target: String, ignored: Dictionary) -> bool:
	if ignored.has(start) or ignored.has(target):
		return false
	var distances = _bfs_with_ignored(adjacency, start, ignored)
	return distances.has(target)

func _bfs_with_ignored(adjacency: Dictionary, start: String, ignored: Dictionary) -> Dictionary:
	var distances = {start: 0}
	var queue: Array[String] = [start]
	while not queue.is_empty():
		var current = queue.pop_front()
		for next_node in adjacency.get(current, []):
			var next_id = String(next_node)
			if ignored.has(next_id) or distances.has(next_id):
				continue
			distances[next_id] = int(distances[current]) + 1
			queue.append(next_id)
	return distances

func _route_has_edges(route: PackedStringArray, adjacency: Dictionary) -> bool:
	if route.size() < 2:
		return false
	for i in range(route.size() - 1):
		if not _edge_exists(adjacency, String(route[i]), String(route[i + 1])):
			return false
	return true

func _macro_cycle_length_from_graph(graph: Dictionary, node_map: Dictionary, adjacency: Dictionary) -> int:
	var macro_value = graph.get("macro_loop", {})
	if typeof(macro_value) != TYPE_DICTIONARY:
		return 0
	var macro_loop: Dictionary = macro_value
	if macro_loop.is_empty():
		return 0
	var route_a = _to_string_route(macro_loop.get("route_a", PackedStringArray()))
	var route_b = _to_string_route(macro_loop.get("route_b", PackedStringArray()))
	if route_a.size() < 3 or route_b.size() < 3:
		return 0
	if String(route_a[0]) != String(route_b[0]) or String(route_a[route_a.size() - 1]) != String(route_b[route_b.size() - 1]):
		return 0
	if not node_map.has(String(route_a[0])) or not node_map.has(String(route_a[route_a.size() - 1])):
		return 0
	if not _route_has_edges(route_a, adjacency) or not _route_has_edges(route_b, adjacency):
		return 0
	if not _routes_have_disjoint_interiors(route_a, route_b):
		return 0
	return route_a.size() + route_b.size() - 2

func _small_loop_count(graph: Dictionary) -> int:
	var loops_value = graph.get("small_loops", [])
	if typeof(loops_value) != TYPE_ARRAY:
		return 0
	return (loops_value as Array).size()

func _bfs(adjacency: Dictionary, start: String) -> Dictionary:
	var distances = {start: 0}
	var queue: Array[String] = [start]
	while not queue.is_empty():
		var current = queue.pop_front()
		for next_node in adjacency.get(current, []):
			if not distances.has(next_node):
				distances[String(next_node)] = int(distances[current]) + 1
				queue.append(String(next_node))
	return distances

func _connected_component_count(node_map: Dictionary, adjacency: Dictionary) -> int:
	var visited = {}
	var count = 0
	for node_id in node_map.keys():
		if visited.has(node_id):
			continue
		count += 1
		var queue: Array[String] = [String(node_id)]
		visited[node_id] = true
		while not queue.is_empty():
			var current = queue.pop_front()
			for next_node in adjacency.get(current, []):
				if not visited.has(next_node):
					visited[next_node] = true
					queue.append(String(next_node))
	return count

func _find_flagged_node(node_map: Dictionary, flag: String) -> String:
	for node_id in node_map.keys():
		if bool((node_map[node_id] as Dictionary).get(flag, false)):
			return String(node_id)
	return ""

func _occupied_cells(node: Dictionary) -> Array[Vector2i]:
	var rect = _rect(node)
	var shape_cells: Array = node.get("shape_cells", [])
	var cells: Array[Vector2i] = []
	if shape_cells.is_empty():
		for gx in range(rect.position.x, rect.position.x + rect.size.x):
			for gz in range(rect.position.y, rect.position.y + rect.size.y):
				cells.append(Vector2i(gx, gz))
		return cells
	for raw_cell in shape_cells:
		var rel = _to_vector2i(raw_cell)
		if rel.x < 0 or rel.y < 0 or rel.x >= rect.size.x or rel.y >= rect.size.y:
			continue
		cells.append(Vector2i(rect.position.x + rel.x, rect.position.y + rel.y))
	return cells

func _to_vector2i(value) -> Vector2i:
	var value_type = typeof(value)
	if value_type == TYPE_VECTOR2I:
		return value
	if value_type == TYPE_VECTOR2:
		return Vector2i(int(value.x), int(value.y))
	if value_type == TYPE_ARRAY and value.size() >= 2:
		return Vector2i(int(value[0]), int(value[1]))
	if value_type == TYPE_DICTIONARY:
		return Vector2i(int(value.get("x", 0)), int(value.get("z", value.get("y", 0))))
	return Vector2i.ZERO

func _side_offset(cell: Vector2i, side: String, rect: Rect2i) -> int:
	if side == "east" or side == "west":
		return cell.y - rect.position.y
	return cell.x - rect.position.x

func _door_signature(node_id: String, node_map: Dictionary, adjacency: Dictionary) -> String:
	var parts: Array[String] = []
	for next_id in adjacency.get(node_id, []):
		if not node_map.has(next_id):
			continue
		var shared = get_shared_edge(node_map[node_id], node_map[String(next_id)])
		if shared.is_empty():
			continue
		parts.append("%s:%d" % [String(shared["side_a"]), int(shared["offset_a"])])
	parts.sort()
	return ",".join(parts)

func _breaks_line_of_sight(node: Dictionary) -> bool:
	var kind = _space_kind(node)
	return kind in ["l_turn", "l_room", "large_internal", "hub", "junction", "offset_corridor", "special"]

func _is_ordinary_rect_room(node: Dictionary) -> bool:
	var kind = _space_kind(node)
	return kind == "normal_room" or kind == "plain_rect"

func _is_short_connector_space(node: Dictionary, adjacency: Dictionary) -> bool:
	var kind = _space_kind(node)
	if kind in ["narrow_corridor", "l_turn", "junction", "offset_corridor"]:
		return true
	if kind == "normal_room":
		var node_id = String(node.get("id", ""))
		var degree = (adjacency.get(node_id, []) as Array).size()
		return degree == 2 and String(node.get("room_signature", "")).contains("connector")
	return false

func _is_anchor_room(node: Dictionary) -> bool:
	var kind = _space_kind(node)
	return kind in ["l_room", "recognizable_room", "large_internal", "hub", "special"]

func _is_recognizable_space(node: Dictionary) -> bool:
	var kind = _space_kind(node)
	return kind in ["l_turn", "l_room", "recognizable_room", "large_internal", "hub", "junction", "offset_corridor", "special"]

func _space_kind(node: Dictionary) -> String:
	return String(node.get("space_kind", "plain_rect"))

func _node_width_tier(node: Dictionary) -> String:
	var kind = _space_kind(node)
	if kind in ["narrow_corridor", "l_turn", "junction", "offset_corridor"]:
		return "narrow_corridor"
	if kind == "long_corridor":
		return "normal_corridor"
	if kind in ["normal_room", "l_room", "recognizable_room"]:
		return "normal_room"
	if kind == "hub":
		return "hub_room"
	if kind in ["large_internal", "special"]:
		return "large_room"
	return ""

func _nominal_width_cells(node: Dictionary, module: Dictionary) -> int:
	if module.has("nominal_width_cells"):
		return maxi(1, int(module.get("nominal_width_cells", 1)))
	var span = _occupied_span(node)
	return maxi(1, mini(span.x, span.y))

func _nominal_length_cells(node: Dictionary, module: Dictionary) -> int:
	if module.has("nominal_length_cells"):
		return maxi(1, int(module.get("nominal_length_cells", 1)))
	var span = _occupied_span(node)
	return maxi(1, maxi(span.x, span.y))

func _occupied_span(node: Dictionary) -> Vector2i:
	var cells = _occupied_cells(node)
	if cells.is_empty():
		var rect = _rect(node)
		return rect.size
	var min_x = cells[0].x
	var min_z = cells[0].y
	var max_x = cells[0].x
	var max_z = cells[0].y
	for cell in cells:
		min_x = mini(min_x, cell.x)
		min_z = mini(min_z, cell.y)
		max_x = maxi(max_x, cell.x)
		max_z = maxi(max_z, cell.y)
	return Vector2i(max_x - min_x + 1, max_z - min_z + 1)

func _graph_cell_size(graph: Dictionary, registry) -> float:
	if graph.has("cell_size"):
		return float(graph.get("cell_size", 2.5))
	if registry != null:
		return float(registry.get("cell_size"))
	return 2.5

func _node_center_grid(node: Dictionary) -> Vector2:
	var cells = _occupied_cells(node)
	if cells.is_empty():
		var rect = _rect(node)
		return Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + rect.size.y * 0.5)
	var sum = Vector2.ZERO
	for cell in cells:
		sum += Vector2(cell.x + 0.5, cell.y + 0.5)
	return sum / float(cells.size())

func _cell_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]

func _rect(node: Dictionary) -> Rect2i:
	var footprint: Dictionary = node.get("footprint", {})
	return Rect2i(
		int(footprint.get("x", 0)),
		int(footprint.get("z", 0)),
		int(footprint.get("w", 1)),
		int(footprint.get("h", 1))
	)

func _check_range(label: String, value: int, min_value: int, max_value: int, issues: Array[String]) -> void:
	if value < min_value or value > max_value:
		issues.append("%s out of range: %d." % [label, value])
