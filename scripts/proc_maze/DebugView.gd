extends RefCounted

const CELL_SIZE := 2.5

func build(scene_root: Node3D, graph: Dictionary, scene_validation: Dictionary) -> void:
	var level_root = scene_root.get_node_or_null("LevelRoot") as Node3D
	if level_root == null:
		return
	var existing = level_root.get_node_or_null("DebugView")
	if existing != null:
		existing.free()
	var debug_root = Node3D.new()
	debug_root.name = "DebugView"
	debug_root.add_to_group("proc_maze_debug", true)
	level_root.add_child(debug_root)

	var node_map = _build_node_map(graph.get("nodes", []))
	var macro_loop: Dictionary = graph.get("macro_loop", {})
	for node_id in node_map.keys():
		_add_node_label(debug_root, node_map[node_id], macro_loop)
	for edge in graph.get("edges", []):
		_add_edge_marker(debug_root, edge, node_map)
	_add_macro_route_markers(debug_root, macro_loop, node_map)
	_add_small_loop_markers(debug_root, graph.get("small_loops", []), node_map)
	_add_issue_labels(debug_root, scene_validation.get("issues", []), node_map)

func _add_node_label(parent: Node3D, node: Dictionary, macro_loop: Dictionary) -> void:
	var label = Label3D.new()
	label.name = "Label_%s" % String(node.get("id", ""))
	label.text = "%s\n%s" % [String(node.get("id", "")), _node_role_text(node, macro_loop)]
	label.font_size = 34
	label.modulate = _node_color(node, macro_loop)
	label.add_to_group("proc_maze_debug_label", true)
	parent.add_child(label)
	label.position = _node_center_world(node) + Vector3(0.0, 2.85, 0.0)

func _add_edge_marker(parent: Node3D, edge: Dictionary, node_map: Dictionary) -> void:
	var a_id = String(edge.get("a", ""))
	var b_id = String(edge.get("b", ""))
	if not node_map.has(a_id) or not node_map.has(b_id):
		return
	var shared = _get_shared_edge(node_map[a_id], node_map[b_id])
	if shared.is_empty():
		return
	var marker = MeshInstance3D.new()
	marker.name = "Connector_%s" % String(edge.get("id", ""))
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.35, 0.08, 0.35)
	marker.mesh = mesh
	marker.material_override = _debug_material(_edge_color(edge))
	marker.add_to_group("proc_maze_debug_connector", true)
	parent.add_child(marker)
	marker.position = _shared_boundary_world_center(shared) + Vector3(0.0, 0.08, 0.0)

func _add_macro_route_markers(parent: Node3D, macro_loop: Dictionary, node_map: Dictionary) -> void:
	if macro_loop.is_empty():
		return
	var route_a = _to_string_route(macro_loop.get("route_a", PackedStringArray()))
	var route_b = _to_string_route(macro_loop.get("route_b", PackedStringArray()))
	_add_route_markers(parent, route_a, "MacroRouteA", Color(0.05, 1.0, 0.78), node_map, 0.22)
	_add_route_markers(parent, route_b, "MacroRouteB", Color(1.0, 0.52, 0.08), node_map, 0.30)
	_add_route_name_label(parent, route_a, "MACRO A", Color(0.05, 1.0, 0.78), node_map, 3.55)
	_add_route_name_label(parent, route_b, "MACRO B", Color(1.0, 0.52, 0.08), node_map, 3.75)

func _add_small_loop_markers(parent: Node3D, small_loops: Array, node_map: Dictionary) -> void:
	for i in range(small_loops.size()):
		var loop_value = small_loops[i]
		if typeof(loop_value) != TYPE_DICTIONARY:
			continue
		var loop: Dictionary = loop_value
		var route = _to_string_route(loop.get("route", PackedStringArray()))
		_add_route_markers(parent, route, "SmallLoop_%d" % i, Color(0.22, 0.58, 1.0), node_map, 0.38)
		_add_route_name_label(parent, route, "SMALL LOOP", Color(0.22, 0.58, 1.0), node_map, 3.25)

func _add_route_markers(
	parent: Node3D,
	route: PackedStringArray,
	prefix: String,
	color: Color,
	node_map: Dictionary,
	y_offset: float
) -> void:
	if route.size() < 2:
		return
	for i in range(route.size() - 1):
		_add_route_edge_marker(parent, String(route[i]), String(route[i + 1]), "%s_%02d" % [prefix, i], color, node_map, y_offset)

func _add_route_edge_marker(
	parent: Node3D,
	a_id: String,
	b_id: String,
	marker_name: String,
	color: Color,
	node_map: Dictionary,
	y_offset: float
) -> void:
	if not node_map.has(a_id) or not node_map.has(b_id):
		return
	var shared = _get_shared_edge(node_map[a_id], node_map[b_id])
	if shared.is_empty():
		return
	var marker = MeshInstance3D.new()
	marker.name = marker_name
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.72, 0.1, 0.72)
	marker.mesh = mesh
	marker.material_override = _debug_material(color)
	marker.add_to_group("proc_maze_debug_route", true)
	parent.add_child(marker)
	marker.position = _shared_boundary_world_center(shared) + Vector3(0.0, y_offset, 0.0)

func _add_route_name_label(
	parent: Node3D,
	route: PackedStringArray,
	text: String,
	color: Color,
	node_map: Dictionary,
	y_offset: float
) -> void:
	if route.size() < 2:
		return
	var sum = Vector3.ZERO
	var count = 0
	for node_id in route:
		if node_map.has(String(node_id)):
			sum += _node_center_world(node_map[String(node_id)])
			count += 1
	if count == 0:
		return
	var label = Label3D.new()
	label.name = "Label_%s" % text.replace(" ", "_")
	label.text = text
	label.font_size = 28
	label.modulate = color
	label.add_to_group("proc_maze_debug_label", true)
	parent.add_child(label)
	label.position = (sum / float(count)) + Vector3(0.0, y_offset, 0.0)

func _add_issue_labels(parent: Node3D, issues: Array, node_map: Dictionary) -> void:
	if issues.is_empty():
		return
	var label = Label3D.new()
	label.name = "IssueSummary"
	label.text = "Issues: %d" % issues.size()
	label.font_size = 42
	label.modulate = Color(1.0, 0.2, 0.15)
	parent.add_child(label)
	label.position = _graph_center(node_map) + Vector3(0.0, 5.0, 0.0)

func _node_role_text(node: Dictionary, macro_loop: Dictionary) -> String:
	var node_id = String(node.get("id", ""))
	if node_id == String(macro_loop.get("split_node", "")):
		return "SPLIT"
	if node_id == String(macro_loop.get("merge_node", "")):
		return "MERGE"
	if _route_contains_internal(_to_string_route(macro_loop.get("route_a", PackedStringArray())), node_id):
		return "MACRO A"
	if _route_contains_internal(_to_string_route(macro_loop.get("route_b", PackedStringArray())), node_id):
		return "MACRO B"
	if bool(node.get("is_entrance", false)):
		return "START"
	if bool(node.get("is_exit", false)):
		return "EXIT"
	if bool(node.get("is_special", false)):
		return "SPECIAL"
	if bool(node.get("is_hub", false)):
		return "HUB"
	if bool(node.get("is_dead_end", false)):
		return "DEAD"
	if bool(node.get("is_long_corridor", false)):
		return "LONG"
	if bool(node.get("is_main_path", false)):
		return "MAIN"
	return "BRANCH"

func _node_color(node: Dictionary, macro_loop: Dictionary) -> Color:
	var node_id = String(node.get("id", ""))
	if node_id == String(macro_loop.get("split_node", "")):
		return Color(1.0, 0.35, 0.08)
	if node_id == String(macro_loop.get("merge_node", "")):
		return Color(0.75, 0.42, 1.0)
	if _route_contains_internal(_to_string_route(macro_loop.get("route_a", PackedStringArray())), node_id):
		return Color(0.05, 1.0, 0.78)
	if _route_contains_internal(_to_string_route(macro_loop.get("route_b", PackedStringArray())), node_id):
		return Color(1.0, 0.52, 0.08)
	if bool(node.get("is_entrance", false)):
		return Color(0.3, 1.0, 0.4)
	if bool(node.get("is_exit", false)):
		return Color(0.35, 0.7, 1.0)
	if bool(node.get("is_special", false)):
		return Color(1.0, 0.5, 0.9)
	if bool(node.get("is_hub", false)):
		return Color(1.0, 0.82, 0.25)
	if bool(node.get("is_dead_end", false)):
		return Color(1.0, 0.35, 0.25)
	if bool(node.get("is_main_path", false)):
		return Color(0.95, 0.95, 0.85)
	return Color(0.6, 0.85, 1.0)

func _edge_color(edge: Dictionary) -> Color:
	var kind = String(edge.get("kind", ""))
	if kind == "macro_loop_b":
		return Color(1.0, 0.52, 0.08)
	if kind == "main":
		return Color(0.2, 0.9, 0.35)
	if bool(edge.get("closes_loop", false)):
		return Color(0.2, 0.55, 1.0)
	if kind.contains("dead"):
		return Color(1.0, 0.35, 0.2)
	if kind.contains("special"):
		return Color(1.0, 0.4, 0.9)
	return Color(1.0, 0.85, 0.25)

func _debug_material(color: Color) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material

func _to_string_route(value) -> PackedStringArray:
	if typeof(value) == TYPE_PACKED_STRING_ARRAY:
		return value
	var route = PackedStringArray()
	if typeof(value) == TYPE_ARRAY:
		for item in value:
			route.append(String(item))
	return route

func _route_contains_internal(route: PackedStringArray, node_id: String) -> bool:
	for i in range(1, route.size() - 1):
		if String(route[i]) == node_id:
			return true
	return false

func _build_node_map(nodes: Array) -> Dictionary:
	var node_map = {}
	for node in nodes:
		node_map[String(node.get("id", ""))] = node
	return node_map

func _rect(node: Dictionary) -> Rect2i:
	var footprint: Dictionary = node.get("footprint", {})
	return Rect2i(
		int(footprint.get("x", 0)),
		int(footprint.get("z", 0)),
		int(footprint.get("w", 1)),
		int(footprint.get("h", 1))
	)

func _rect_center_world(rect: Rect2i) -> Vector3:
	return Vector3((rect.position.x + rect.size.x * 0.5) * CELL_SIZE, 0.0, (rect.position.y + rect.size.y * 0.5) * CELL_SIZE)

func _get_shared_edge(a_node: Dictionary, b_node: Dictionary) -> Dictionary:
	var b_lookup = {}
	for b_cell in _occupied_cells(b_node):
		b_lookup[_cell_key(b_cell)] = true
	for a_cell in _occupied_cells(a_node):
		var candidates = [
			{"cell": Vector2i(a_cell.x + 1, a_cell.y), "axis": "z", "line": a_cell.x + 1, "unit": a_cell.y},
			{"cell": Vector2i(a_cell.x - 1, a_cell.y), "axis": "z", "line": a_cell.x, "unit": a_cell.y},
			{"cell": Vector2i(a_cell.x, a_cell.y + 1), "axis": "x", "line": a_cell.y + 1, "unit": a_cell.x},
			{"cell": Vector2i(a_cell.x, a_cell.y - 1), "axis": "x", "line": a_cell.y, "unit": a_cell.x},
		]
		for candidate in candidates:
			var other_cell: Vector2i = candidate["cell"]
			if b_lookup.has(_cell_key(other_cell)):
				return {"axis": String(candidate["axis"]), "line": int(candidate["line"]), "unit": int(candidate["unit"])}
	return {}

func _shared_boundary_world_center(shared: Dictionary) -> Vector3:
	if String(shared["axis"]) == "z":
		return Vector3(int(shared["line"]) * CELL_SIZE, 0.0, (int(shared["unit"]) + 0.5) * CELL_SIZE)
	return Vector3((int(shared["unit"]) + 0.5) * CELL_SIZE, 0.0, int(shared["line"]) * CELL_SIZE)

func _graph_center(node_map: Dictionary) -> Vector3:
	if node_map.is_empty():
		return Vector3.ZERO
	var sum = Vector3.ZERO
	for node_id in node_map.keys():
		sum += _node_center_world(node_map[node_id])
	return sum / float(node_map.size())

func _node_center_world(node: Dictionary) -> Vector3:
	var cells = _occupied_cells(node)
	if cells.is_empty():
		return _rect_center_world(_rect(node))
	var sum = Vector2.ZERO
	for cell in cells:
		sum += Vector2((cell.x + 0.5) * CELL_SIZE, (cell.y + 0.5) * CELL_SIZE)
	sum /= float(cells.size())
	return Vector3(sum.x, 0.0, sum.y)

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

func _cell_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]
