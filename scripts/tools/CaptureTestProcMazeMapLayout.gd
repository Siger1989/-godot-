extends SceneTree

const ModuleRegistry = preload("res://scripts/proc_maze/ModuleRegistry.gd")
const MapGraphGenerator = preload("res://scripts/proc_maze/MapGraphGenerator.gd")
const OUTPUT_PATH := "res://artifacts/screenshots/test_proc_maze_layout.png"
const IMAGE_SIZE := Vector2i(1800, 1200)
const MARGIN := 70

func _init() -> void:
	var registry = ModuleRegistry.new()
	if not registry.load_from_path("res://data/proc_maze/module_registry.json"):
		for error in registry.errors:
			push_error(error)
		quit(1)
		return
	var graph = MapGraphGenerator.new(registry).generate_fixed(2026050401)
	var node_map = _build_node_map(graph.get("nodes", []))
	var bounds = _bounds(node_map)
	var image = Image.create(IMAGE_SIZE.x, IMAGE_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.055, 0.055, 0.05, 1.0))

	_draw_grid(image, bounds)
	for node_id in node_map.keys():
		_draw_node(image, node_map[node_id], bounds)
	for edge in graph.get("edges", []):
		_draw_edge(image, edge, node_map, bounds)
	_draw_loop_overlays(image, graph, node_map, bounds)

	var error = image.save_png(OUTPUT_PATH)
	if error != OK:
		push_error("TEST_PROC_MAZE_LAYOUT_SCREENSHOT FAIL save=%s" % str(error))
		quit(1)
		return
	print("TEST_PROC_MAZE_LAYOUT_SCREENSHOT PASS path=%s" % OUTPUT_PATH)
	quit(0)

func _draw_grid(image: Image, bounds: Rect2i) -> void:
	var color = Color(0.16, 0.16, 0.15, 1.0)
	for gx in range(bounds.position.x, bounds.position.x + bounds.size.x + 1):
		var p0 = _cell_to_px(Vector2(gx, bounds.position.y), bounds)
		var p1 = _cell_to_px(Vector2(gx, bounds.position.y + bounds.size.y), bounds)
		_draw_line(image, p0, p1, color)
	for gz in range(bounds.position.y, bounds.position.y + bounds.size.y + 1):
		var p0z = _cell_to_px(Vector2(bounds.position.x, gz), bounds)
		var p1z = _cell_to_px(Vector2(bounds.position.x + bounds.size.x, gz), bounds)
		_draw_line(image, p0z, p1z, color)

func _draw_node(image: Image, node: Dictionary, bounds: Rect2i) -> void:
	var color = _node_color(node)
	for cell in _occupied_cells(node):
		var top_left = _cell_to_px(Vector2(cell.x, cell.y + 1), bounds)
		var bottom_right = _cell_to_px(Vector2(cell.x + 1, cell.y), bounds)
		_fill_rect(image, Rect2i(top_left, bottom_right - top_left), color)
		_draw_rect_outline(image, Rect2i(top_left, bottom_right - top_left), Color(0.04, 0.035, 0.025, 1.0))

func _draw_edge(image: Image, edge: Dictionary, node_map: Dictionary, bounds: Rect2i) -> void:
	var a = _node_center(node_map[String(edge.get("a", ""))])
	var b = _node_center(node_map[String(edge.get("b", ""))])
	var color = Color(0.2, 0.85, 0.25, 1.0)
	if String(edge.get("kind", "")) == "macro_loop_b":
		color = Color(1.0, 0.52, 0.08, 1.0)
	elif String(edge.get("kind", "")) == "main":
		color = Color(0.18, 0.9, 0.35, 1.0)
	if bool(edge.get("closes_loop", false)):
		color = Color(0.2, 0.55, 1.0, 1.0)
	elif String(edge.get("kind", "")).contains("dead"):
		color = Color(1.0, 0.28, 0.18, 1.0)
	elif String(edge.get("kind", "")).contains("special"):
		color = Color(1.0, 0.38, 0.9, 1.0)
	_draw_thick_line(image, _cell_to_px(a, bounds), _cell_to_px(b, bounds), color, 5)

func _draw_loop_overlays(image: Image, graph: Dictionary, node_map: Dictionary, bounds: Rect2i) -> void:
	var macro_loop: Dictionary = graph.get("macro_loop", {})
	if not macro_loop.is_empty():
		_draw_route(image, _to_string_route(macro_loop.get("route_a", PackedStringArray())), node_map, bounds, Color(0.02, 1.0, 0.74, 1.0), 8)
		_draw_route(image, _to_string_route(macro_loop.get("route_b", PackedStringArray())), node_map, bounds, Color(1.0, 0.52, 0.08, 1.0), 8)
		_draw_node_dot(image, String(macro_loop.get("split_node", "")), node_map, bounds, Color(1.0, 0.24, 0.06, 1.0), 13)
		_draw_node_dot(image, String(macro_loop.get("merge_node", "")), node_map, bounds, Color(0.72, 0.35, 1.0, 1.0), 13)
	var small_loops: Array = graph.get("small_loops", [])
	for loop_value in small_loops:
		if typeof(loop_value) != TYPE_DICTIONARY:
			continue
		var loop: Dictionary = loop_value
		_draw_route(image, _to_string_route(loop.get("route", PackedStringArray())), node_map, bounds, Color(0.22, 0.58, 1.0, 1.0), 4)

func _draw_route(image: Image, route: PackedStringArray, node_map: Dictionary, bounds: Rect2i, color: Color, radius: int) -> void:
	if route.size() < 2:
		return
	for i in range(route.size() - 1):
		var a_id = String(route[i])
		var b_id = String(route[i + 1])
		if not node_map.has(a_id) or not node_map.has(b_id):
			continue
		_draw_thick_line(image, _cell_to_px(_node_center(node_map[a_id]), bounds), _cell_to_px(_node_center(node_map[b_id]), bounds), color, radius)

func _draw_node_dot(image: Image, node_id: String, node_map: Dictionary, bounds: Rect2i, color: Color, radius: int) -> void:
	if not node_map.has(node_id):
		return
	var center = _cell_to_px(_node_center(node_map[node_id]), bounds)
	for oy in range(-radius, radius + 1):
		for ox in range(-radius, radius + 1):
			if ox * ox + oy * oy <= radius * radius:
				var x = center.x + ox
				var y = center.y + oy
				if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
					image.set_pixel(x, y, color)

func _node_color(node: Dictionary) -> Color:
	if bool(node.get("is_entrance", false)):
		return Color(0.25, 0.9, 0.35, 1.0)
	if bool(node.get("is_exit", false)):
		return Color(0.25, 0.55, 1.0, 1.0)
	if bool(node.get("is_special", false)):
		return Color(0.78, 0.32, 0.7, 1.0)
	if bool(node.get("is_hub", false)):
		return Color(0.9, 0.72, 0.25, 1.0)
	if bool(node.get("is_dead_end", false)):
		return Color(0.9, 0.28, 0.18, 1.0)
	if bool(node.get("is_long_corridor", false)):
		return Color(0.55, 0.55, 0.42, 1.0)
	if bool(node.get("is_main_path", false)):
		return Color(0.72, 0.66, 0.42, 1.0)
	return Color(0.38, 0.55, 0.72, 1.0)

func _cell_to_px(cell: Vector2, bounds: Rect2i) -> Vector2i:
	var scale = _scale(bounds)
	var x = MARGIN + (cell.x - bounds.position.x) * scale
	var y = IMAGE_SIZE.y - MARGIN - (cell.y - bounds.position.y) * scale
	return Vector2i(roundi(x), roundi(y))

func _scale(bounds: Rect2i) -> float:
	return minf(float(IMAGE_SIZE.x - MARGIN * 2) / float(bounds.size.x), float(IMAGE_SIZE.y - MARGIN * 2) / float(bounds.size.y))

func _fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
	var x0: int = clampi(mini(rect.position.x, rect.end.x), 0, image.get_width() - 1)
	var x1: int = clampi(maxi(rect.position.x, rect.end.x), 0, image.get_width() - 1)
	var y0: int = clampi(mini(rect.position.y, rect.end.y), 0, image.get_height() - 1)
	var y1: int = clampi(maxi(rect.position.y, rect.end.y), 0, image.get_height() - 1)
	for y in range(y0, y1):
		for x in range(x0, x1):
			image.set_pixel(x, y, color)

func _draw_rect_outline(image: Image, rect: Rect2i, color: Color) -> void:
	var p0 = rect.position
	var p1 = Vector2i(rect.end.x, rect.position.y)
	var p2 = rect.end
	var p3 = Vector2i(rect.position.x, rect.end.y)
	_draw_line(image, p0, p1, color)
	_draw_line(image, p1, p2, color)
	_draw_line(image, p2, p3, color)
	_draw_line(image, p3, p0, color)

func _draw_thick_line(image: Image, a: Vector2i, b: Vector2i, color: Color, radius: int) -> void:
	for oy in range(-radius, radius + 1):
		for ox in range(-radius, radius + 1):
			if ox * ox + oy * oy <= radius * radius:
				_draw_line(image, a + Vector2i(ox, oy), b + Vector2i(ox, oy), color)

func _draw_line(image: Image, a: Vector2i, b: Vector2i, color: Color) -> void:
	var x0 = a.x
	var y0 = a.y
	var x1 = b.x
	var y1 = b.y
	var dx = abs(x1 - x0)
	var sx = 1 if x0 < x1 else -1
	var dy = -abs(y1 - y0)
	var sy = 1 if y0 < y1 else -1
	var err = dx + dy
	while true:
		if x0 >= 0 and x0 < image.get_width() and y0 >= 0 and y0 < image.get_height():
			image.set_pixel(x0, y0, color)
		if x0 == x1 and y0 == y1:
			break
		var e2 = 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy

func _build_node_map(nodes: Array) -> Dictionary:
	var node_map = {}
	for node in nodes:
		node_map[String(node.get("id", ""))] = node
	return node_map

func _to_string_route(value) -> PackedStringArray:
	if typeof(value) == TYPE_PACKED_STRING_ARRAY:
		return value
	var route = PackedStringArray()
	if typeof(value) == TYPE_ARRAY:
		for item in value:
			route.append(String(item))
	return route

func _bounds(node_map: Dictionary) -> Rect2i:
	var initialized = false
	var min_x = 0
	var min_z = 0
	var max_x = 0
	var max_z = 0
	for node_id in node_map.keys():
		for cell in _occupied_cells(node_map[node_id]):
			if not initialized:
				min_x = cell.x
				min_z = cell.y
				max_x = cell.x + 1
				max_z = cell.y + 1
				initialized = true
			else:
				min_x = mini(min_x, cell.x)
				min_z = mini(min_z, cell.y)
				max_x = maxi(max_x, cell.x + 1)
				max_z = maxi(max_z, cell.y + 1)
	return Rect2i(min_x, min_z, max_x - min_x, max_z - min_z)

func _rect(node: Dictionary) -> Rect2i:
	var footprint: Dictionary = node.get("footprint", {})
	return Rect2i(int(footprint.get("x", 0)), int(footprint.get("z", 0)), int(footprint.get("w", 1)), int(footprint.get("h", 1)))

func _node_center(node: Dictionary) -> Vector2:
	var cells = _occupied_cells(node)
	if cells.is_empty():
		var rect = _rect(node)
		return Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + rect.size.y * 0.5)
	var sum = Vector2.ZERO
	for cell in cells:
		sum += Vector2(cell.x + 0.5, cell.y + 0.5)
	return sum / float(cells.size())

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
