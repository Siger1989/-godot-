extends RefCounted

const WallMaterial = preload("res://materials/backrooms_wall.tres")
const FloorMaterial = preload("res://materials/backrooms_floor.tres")
const CeilingMaterial = preload("res://materials/backrooms_ceiling.tres")
const DoorFrameMaterial = preload("res://materials/backrooms_door_frame.tres")
const ContactShadowMaterial = preload("res://scripts/visual/ContactShadowMaterial.gd")
const CELL_SIZE := 2.5
const WALL_HEIGHT := 2.55
const DOOR_OPENING_WIDTH := 1.15
const DOOR_FRAME_TRIM_WIDTH := 0.10
const DOOR_REVEAL_DEPTH := 1.10
const DOOR_REVEAL_WIDTH := DOOR_OPENING_WIDTH + DOOR_FRAME_TRIM_WIDTH * 2.0 + 0.80
const DOOR_REVEAL_EDGE_TOLERANCE := 0.025
const LIGHT_WALL_CLEARANCE := 0.04
const EPSILON := 0.001

func validate(scene_root: Node, graph: Dictionary, map_validation: Dictionary) -> Dictionary:
	var issues: Array[String] = []
	var metrics = {
		"has_overlap": false,
		"has_door_to_wall": false,
		"has_door_reveal_blocker": false,
		"active_light_count": 0,
		"active_light_fixture_count": 0,
		"active_light_source_count": 0,
		"fps": 0.0,
		"draw_calls": 0,
	}

	var level_root = scene_root.get_node_or_null("LevelRoot")
	if level_root == null:
		issues.append("LevelRoot is missing.")
		return {"ok": false, "issues": issues, "metrics": metrics}

	_validate_required_counts(scene_root, graph, issues)
	_validate_generated_scales(scene_root, issues)
	_validate_materials(scene_root, issues)
	_validate_wall_heights(scene_root, issues)
	_validate_door_alignment(scene_root, graph, issues, metrics)
	_validate_door_reveal_clearance(scene_root, issues, metrics)
	_validate_internal_large_rooms(scene_root, graph, issues)
	_validate_ceiling_light_placement(scene_root, graph, issues)

	metrics["has_overlap"] = _has_map_overlap(graph, issues)
	metrics["active_light_count"] = _get_nodes_in_group(scene_root, "ceiling_light_panel").size()
	metrics["active_light_fixture_count"] = _get_nodes_in_group(scene_root, "ceiling_light_panel").size()
	metrics["active_light_source_count"] = _get_nodes_in_group(scene_root, "ceiling_light").size()
	metrics["fps"] = float(Performance.get_monitor(Performance.TIME_FPS))
	metrics["draw_calls"] = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	if not bool(map_validation.get("ok", false)):
		for issue in map_validation.get("issues", []):
			issues.append("Map validation issue: %s" % issue)

	return {
		"ok": issues.is_empty(),
		"issues": issues,
		"metrics": metrics,
	}

func _validate_required_counts(scene_root: Node, graph: Dictionary, issues: Array[String]) -> void:
	var node_count = (graph.get("nodes", []) as Array).size()
	var edge_count = (graph.get("edges", []) as Array).size()
	var module_count = _get_nodes_in_group(scene_root, "proc_maze_module").size()
	var opening_count = _get_nodes_in_group(scene_root, "proc_wall_opening").size()
	var frame_count = _get_nodes_in_group(scene_root, "proc_door_frame").size()
	var portal_count = _get_nodes_in_group(scene_root, "proc_portal").size()
	if module_count != node_count:
		issues.append("Scene module count mismatch: %d expected %d." % [module_count, node_count])
	if opening_count != edge_count:
		issues.append("Scene opening count mismatch: %d expected %d." % [opening_count, edge_count])
	if frame_count != edge_count:
		issues.append("Scene door-frame count mismatch: %d expected %d." % [frame_count, edge_count])
	if portal_count != edge_count:
		issues.append("Scene portal count mismatch: %d expected %d." % [portal_count, edge_count])

func _validate_generated_scales(scene_root: Node, issues: Array[String]) -> void:
	var groups = ["proc_maze_module", "proc_wall_body", "proc_wall_opening", "proc_door_frame", "proc_portal", "floor_visual", "ceiling_light_panel", "proc_internal_wall"]
	for group_name in groups:
		for node in _get_nodes_in_group(scene_root, group_name):
			var node3d = node as Node3D
			if node3d == null:
				continue
			if node3d.scale.x <= 0.0 or node3d.scale.y <= 0.0 or node3d.scale.z <= 0.0:
				issues.append("Negative/zero scale is forbidden: %s" % _node_label(node3d))
			if not _is_vector3_close(node3d.scale, Vector3.ONE, EPSILON):
				issues.append("Generated node must keep identity scale: %s scale=%s" % [_node_label(node3d), str(node3d.scale)])

func _validate_materials(scene_root: Node, issues: Array[String]) -> void:
	for wall in _get_nodes_in_group(scene_root, "proc_wall_body"):
		var mesh = wall.get_node_or_null("Mesh") as MeshInstance3D
		if mesh == null or not _is_expected_material(mesh.material_override, WallMaterial):
			issues.append("Solid wall material mismatch: %s" % _node_label(wall))
	for opening in _get_nodes_in_group(scene_root, "proc_wall_opening"):
		var mesh = opening.get_node_or_null("Mesh") as MeshInstance3D
		if mesh == null or not _is_expected_material(mesh.material_override, WallMaterial):
			issues.append("WallOpening material mismatch: %s" % _node_label(opening))
	for frame in _get_nodes_in_group(scene_root, "proc_door_frame"):
		var mesh = frame as MeshInstance3D
		if mesh == null or not _is_expected_material(mesh.material_override, DoorFrameMaterial):
			issues.append("DoorFrame material mismatch: %s" % _node_label(frame))
	for floor in _get_nodes_in_group(scene_root, "floor_visual"):
		var mesh = floor as MeshInstance3D
		if mesh == null or mesh.material_override != FloorMaterial:
			issues.append("Floor material mismatch: %s" % _node_label(floor))
	for ceiling in _get_nodes_in_group(scene_root, "ceiling"):
		var mesh = ceiling.get_node_or_null("Mesh") as MeshInstance3D
		if mesh == null or mesh.material_override != CeilingMaterial:
			issues.append("Ceiling material mismatch: %s" % _node_label(ceiling))
	for internal_wall in _get_nodes_in_group(scene_root, "proc_internal_wall"):
		var mesh = internal_wall.get_node_or_null("Mesh") as MeshInstance3D
		if mesh == null or not _is_expected_material(mesh.material_override, WallMaterial):
			issues.append("Internal wall material mismatch: %s" % _node_label(internal_wall))

func _is_expected_material(material: Material, base_material: Material) -> bool:
	if material == base_material:
		return true
	if ContactShadowMaterial.is_contact_material(material):
		return true
	return false

func _validate_wall_heights(scene_root: Node, issues: Array[String]) -> void:
	for wall in _get_nodes_in_group(scene_root, "proc_wall_body"):
		var collision = wall.get_node_or_null("Collision") as CollisionShape3D
		var shape = collision.shape as BoxShape3D if collision != null else null
		if shape == null or absf(shape.size.y - WALL_HEIGHT) > EPSILON:
			issues.append("Solid wall height mismatch: %s" % _node_label(wall))
	for opening in _get_nodes_in_group(scene_root, "proc_wall_opening"):
		if absf(float(opening.get("wall_height")) - WALL_HEIGHT) > EPSILON:
			issues.append("WallOpening height mismatch: %s" % _node_label(opening))
	for internal_wall in _get_nodes_in_group(scene_root, "proc_internal_wall"):
		var collision = internal_wall.get_node_or_null("Collision") as CollisionShape3D
		var shape = collision.shape as BoxShape3D if collision != null else null
		if shape == null or absf(shape.size.y - WALL_HEIGHT) > EPSILON:
			issues.append("Internal wall height mismatch: %s" % _node_label(internal_wall))

func _validate_door_alignment(scene_root: Node, graph: Dictionary, issues: Array[String], metrics: Dictionary) -> void:
	var expected_edges = {}
	for edge in graph.get("edges", []):
		expected_edges[String(edge.get("id", ""))] = true
	var openings = {}
	for opening in _get_nodes_in_group(scene_root, "proc_wall_opening"):
		openings[String(opening.get_meta("edge_id", ""))] = opening
	var frames = {}
	for frame in _get_nodes_in_group(scene_root, "proc_door_frame"):
		frames[String(frame.get_meta("edge_id", ""))] = frame
	for edge_id in expected_edges.keys():
		if not openings.has(edge_id) or not frames.has(edge_id):
			issues.append("Door edge `%s` missing opening or frame." % edge_id)
			metrics["has_door_to_wall"] = true
			continue
		var opening = openings[edge_id] as Node3D
		var frame = frames[edge_id] as Node3D
		if opening == null or frame == null:
			issues.append("Door edge `%s` has invalid opening/frame node." % edge_id)
			metrics["has_door_to_wall"] = true
			continue
		if opening.position.distance_to(frame.position) > EPSILON:
			issues.append("Door edge `%s` opening/frame positions do not align." % edge_id)
		if String(opening.get("span_axis")) != String(frame.get("span_axis")):
			issues.append("Door edge `%s` opening/frame span_axis mismatch." % edge_id)

func _validate_door_reveal_clearance(scene_root: Node, issues: Array[String], metrics: Dictionary) -> void:
	var blockers: Array[Node3D] = []
	for group_name in ["proc_wall_body", "proc_internal_wall"]:
		for wall in _get_nodes_in_group(scene_root, group_name):
			var wall3d = wall as Node3D
			if wall3d != null:
				blockers.append(wall3d)

	for opening in _get_nodes_in_group(scene_root, "proc_wall_opening"):
		var opening3d = opening as Node3D
		if opening3d == null:
			continue
		var edge_id = String(opening3d.get_meta("edge_id", opening3d.name))
		for reveal_rect in _door_reveal_rects_from_opening(opening3d):
			var clear_rect = reveal_rect.grow(-DOOR_REVEAL_EDGE_TOLERANCE)
			if clear_rect.size.x <= 0.0 or clear_rect.size.y <= 0.0:
				clear_rect = reveal_rect
			for blocker in blockers:
				var blocker_rect = _body_xz_rect(blocker)
				if blocker_rect.size == Vector2.ZERO:
					continue
				if clear_rect.intersects(blocker_rect, false):
					issues.append("Door edge `%s` has an abrupt wall inside the doorway reveal: %s." % [edge_id, _node_label(blocker)])
					metrics["has_door_to_wall"] = true
					metrics["has_door_reveal_blocker"] = true
					break

func _door_reveal_rects_from_opening(opening: Node3D) -> Array[Rect2]:
	var center = _accumulated_position(opening)
	var span_axis = String(opening.get("span_axis"))
	if span_axis == "z":
		var reveal_size = Vector2(DOOR_REVEAL_DEPTH, DOOR_REVEAL_WIDTH)
		return [
			Rect2(Vector2(center.x - DOOR_REVEAL_DEPTH, center.z - DOOR_REVEAL_WIDTH * 0.5), reveal_size),
			Rect2(Vector2(center.x, center.z - DOOR_REVEAL_WIDTH * 0.5), reveal_size),
		]
	var reveal_size = Vector2(DOOR_REVEAL_WIDTH, DOOR_REVEAL_DEPTH)
	return [
		Rect2(Vector2(center.x - DOOR_REVEAL_WIDTH * 0.5, center.z - DOOR_REVEAL_DEPTH), reveal_size),
		Rect2(Vector2(center.x - DOOR_REVEAL_WIDTH * 0.5, center.z), reveal_size),
	]

func _validate_internal_large_rooms(scene_root: Node, graph: Dictionary, issues: Array[String]) -> void:
	var internal_by_owner = {}
	for internal_wall in _get_nodes_in_group(scene_root, "proc_internal_wall"):
		var owner_id = String(internal_wall.get_meta("owner_module_id", ""))
		internal_by_owner[owner_id] = int(internal_by_owner.get(owner_id, 0)) + 1
	for node in graph.get("nodes", []):
		var node_id = String(node.get("id", ""))
		var module_id = String(node.get("module_id", ""))
		var space_kind = String(node.get("space_kind", ""))
		if space_kind == "l_room" and int(internal_by_owner.get(node_id, 0)) > 0:
			issues.append("L-shaped room `%s` must use footprint boundary walls only; internal baffles create non-passable slits." % node_id)
		var requires_internal = space_kind == "large_internal" or module_id == "hub_room_partitioned"
		if requires_internal and int(internal_by_owner.get(node_id, 0)) < 1:
			issues.append("Structured room `%s` is missing internal structure." % node_id)

func _validate_ceiling_light_placement(scene_root: Node, graph: Dictionary, issues: Array[String]) -> void:
	var node_map = {}
	for node in graph.get("nodes", []):
		node_map[String(node.get("id", ""))] = node

	var panels_by_owner = {}
	for panel in _get_nodes_in_group(scene_root, "ceiling_light_panel"):
		var panel3d = panel as MeshInstance3D
		if panel3d == null:
			continue
		var owner_id = String(panel3d.get_meta("owner_module_id", panel3d.name.trim_prefix("CeilingLightPanel_")))
		panels_by_owner[owner_id] = panel3d

	var lights_by_owner = {}
	for light in _get_nodes_in_group(scene_root, "ceiling_light"):
		var light3d = light as Light3D
		if light3d == null:
			continue
		var owner_id = String(light3d.get_meta("owner_module_id", light3d.name.trim_prefix("CeilingLight_")))
		var owner_lights: Array = lights_by_owner.get(owner_id, [])
		owner_lights.append(light3d)
		lights_by_owner[owner_id] = owner_lights

	for node_id in node_map.keys():
		var node: Dictionary = node_map[node_id]
		if _node_should_be_unlit(node):
			if panels_by_owner.has(node_id) or lights_by_owner.has(node_id):
				issues.append("Narrow/complex corridor `%s` must stay unlit; found ceiling light or panel." % node_id)

	for owner_id in panels_by_owner.keys():
		if not node_map.has(owner_id):
			issues.append("Ceiling light panel has unknown owner module: %s." % owner_id)
			continue
		var panel := panels_by_owner[owner_id] as MeshInstance3D
		var node: Dictionary = node_map[owner_id]
		if not _panel_fits_owner_footprint(panel, node):
			issues.append("Ceiling light panel `%s` is outside or too close to the owner footprint." % _node_label(panel))
		if _panel_overlaps_wall(panel, scene_root):
			issues.append("Ceiling light panel `%s` overlaps a wall or internal partition in XZ." % _node_label(panel))
		if not lights_by_owner.has(owner_id):
			issues.append("Ceiling light panel `%s` has no matching OmniLight3D source." % _node_label(panel))
		else:
			var light_sources: Array = lights_by_owner[owner_id]
			if light_sources.is_empty():
				issues.append("Ceiling light panel `%s` has an empty light-source list." % _node_label(panel))
			for light_source in light_sources:
				var source3d = light_source as Light3D
				if source3d == null:
					continue
				if not _light_source_inside_panel_xz(source3d, panel):
					issues.append("Ceiling light source `%s` is not under its owner panel `%s`." % [_node_label(source3d), _node_label(panel)])

	for owner_id in lights_by_owner.keys():
		if not panels_by_owner.has(owner_id):
			for light_source in lights_by_owner[owner_id]:
				issues.append("Ceiling light `%s` has no matching visual panel." % _node_label(light_source as Node))

func _node_should_be_unlit(node: Dictionary) -> bool:
	var tier = String(node.get("width_tier", ""))
	var kind = String(node.get("space_kind", ""))
	var module_type = String(node.get("type", ""))
	if tier == "narrow_corridor":
		return true
	if kind in ["narrow_corridor", "l_turn", "junction", "offset_corridor"]:
		return true
	if module_type == "corridor" and not bool(node.get("is_long_corridor", false)):
		return true
	return false

func _panel_fits_owner_footprint(panel: MeshInstance3D, node: Dictionary) -> bool:
	var mesh := panel.mesh as BoxMesh
	if mesh == null:
		return false
	var half_x = mesh.size.x * 0.5 + LIGHT_WALL_CLEARANCE
	var half_z = mesh.size.z * 0.5 + LIGHT_WALL_CLEARANCE
	var panel_world_position = _accumulated_position(panel)
	var center = Vector2(panel_world_position.x, panel_world_position.z)
	for corner in [
		center + Vector2(-half_x, -half_z),
		center + Vector2(half_x, -half_z),
		center + Vector2(half_x, half_z),
		center + Vector2(-half_x, half_z),
	]:
		if not _world_xz_inside_occupied_cells(node, corner):
			return false
	return true

func _world_xz_inside_occupied_cells(node: Dictionary, world_xz: Vector2) -> bool:
	for cell in _occupied_cells(node):
		var rect = Rect2(Vector2(float(cell.x) * CELL_SIZE, float(cell.y) * CELL_SIZE), Vector2(CELL_SIZE, CELL_SIZE))
		if rect.has_point(world_xz):
			return true
	return false

func _panel_overlaps_wall(panel: MeshInstance3D, scene_root: Node) -> bool:
	var panel_rect = _panel_xz_rect(panel).grow(LIGHT_WALL_CLEARANCE)
	for group_name in ["proc_wall_body", "proc_internal_wall"]:
		for wall in _get_nodes_in_group(scene_root, group_name):
			var wall_rect = _body_xz_rect(wall as Node3D)
			if wall_rect.size == Vector2.ZERO:
				continue
			if panel_rect.intersects(wall_rect, true):
				return true
	return false

func _light_source_inside_panel_xz(light: Light3D, panel: MeshInstance3D) -> bool:
	var panel_rect = _panel_xz_rect(panel).grow(0.04)
	var light_position = _accumulated_position(light)
	return panel_rect.has_point(Vector2(light_position.x, light_position.z))

func _panel_xz_rect(panel: MeshInstance3D) -> Rect2:
	var mesh := panel.mesh as BoxMesh
	if mesh == null:
		return Rect2()
	var panel_world_position = _accumulated_position(panel)
	return Rect2(
		Vector2(panel_world_position.x - mesh.size.x * 0.5, panel_world_position.z - mesh.size.z * 0.5),
		Vector2(mesh.size.x, mesh.size.z)
	)

func _body_xz_rect(body: Node3D) -> Rect2:
	if body == null:
		return Rect2()
	var collision = body.get_node_or_null("Collision") as CollisionShape3D
	var shape = collision.shape as BoxShape3D if collision != null else null
	if shape == null:
		return Rect2()
	var center = _accumulated_position(body) + collision.position
	return Rect2(
		Vector2(center.x - shape.size.x * 0.5, center.z - shape.size.z * 0.5),
		Vector2(shape.size.x, shape.size.z)
	)

func _accumulated_position(node: Node3D) -> Vector3:
	var position_sum := Vector3.ZERO
	var current: Node = node
	while current is Node3D:
		position_sum += (current as Node3D).position
		current = current.get_parent()
	return position_sum

func _has_map_overlap(graph: Dictionary, issues: Array[String]) -> bool:
	var occupied = {}
	var has_overlap = false
	for node in graph.get("nodes", []):
		var node_id = String(node.get("id", ""))
		for cell in _occupied_cells(node):
			var key = _cell_key(cell)
			if occupied.has(key):
				issues.append("Scene footprint overlap at %s between `%s` and `%s`." % [key, occupied[key], node_id])
				has_overlap = true
			else:
				occupied[key] = node_id
	return has_overlap

func _rect(node: Dictionary) -> Rect2i:
	var footprint: Dictionary = node.get("footprint", {})
	return Rect2i(
		int(footprint.get("x", 0)),
		int(footprint.get("z", 0)),
		int(footprint.get("w", 1)),
		int(footprint.get("h", 1))
	)

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

func _is_vector3_close(a: Vector3, b: Vector3, epsilon: float) -> bool:
	return absf(a.x - b.x) <= epsilon and absf(a.y - b.y) <= epsilon and absf(a.z - b.z) <= epsilon

func _node_label(node: Node) -> String:
	if node == null:
		return "<null>"
	if node.is_inside_tree():
		return String(node.get_path())
	return node.name

func _get_nodes_in_group(root: Node, group_name: String) -> Array:
	var result = []
	_collect_nodes_in_group(root, group_name, result)
	return result

func _collect_nodes_in_group(node: Node, group_name: String, result: Array) -> void:
	if node.is_in_group(group_name):
		result.append(node)
	for child in node.get_children():
		_collect_nodes_in_group(child, group_name, result)
