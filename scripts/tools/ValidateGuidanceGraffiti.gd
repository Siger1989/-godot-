extends SceneTree

const SCENE_PATH := "res://scenes/tests/Test_ProcMazeMap.tscn"
const MIN_ARROW_COUNT := 8
const MAX_ARROW_COUNT := 16
const MAX_PORTAL_DISTANCE := 1.45
const MIN_DOOR_SIDE_OFFSET := 1.10
const MIN_WALL_FACE_OFFSET := 0.20
const MIN_ARROW_DOT_TO_PORTAL := 0.72

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
	if root.has_method("set"):
		root.set("show_guidance_graffiti", true)
		root.set("show_debug_map_markers", false)
	if root.has_method("rebuild"):
		var result: Dictionary = root.rebuild()
		if not bool(result.get("ok", false)):
			_fail("proc maze rebuild failed before guidance validation")
			return
	await process_frame
	await physics_frame

	var arrows := _nodes_in_group(root, "proc_guidance_graffiti")
	if arrows.size() < MIN_ARROW_COUNT or arrows.size() > MAX_ARROW_COUNT:
		_fail("unexpected guidance arrow count: %d" % arrows.size())
		return

	var exit_id := _find_marker_room_id(root, "Exit")
	if exit_id.is_empty():
		_fail("exit marker is missing")
		return
	var portals := _collect_portals(root)
	var adjacency := _build_adjacency(portals)
	var distances := _shortest_distances_from(exit_id, adjacency)
	if distances.is_empty():
		_fail("could not compute exit distances")
		return

	var color_entries := []
	for node in arrows:
		var arrow := node as MeshInstance3D
		if arrow == null:
			_fail("guidance group contains non-MeshInstance3D")
			return
		if not _validate_arrow_asset(arrow):
			return
		var owner_id := String(arrow.get_meta("owner_module_id", ""))
		var next_id := String(arrow.get_meta("next_node_id", ""))
		var arrow_exit_id := String(arrow.get_meta("exit_node_id", ""))
		if owner_id.is_empty() or next_id.is_empty() or arrow_exit_id != exit_id:
			_fail("arrow metadata is incomplete: %s" % arrow.name)
			return
		if not adjacency.has(owner_id) or not (adjacency[owner_id] as Array).has(next_id):
			_fail("arrow next node is not adjacent: %s owner=%s next=%s" % [arrow.name, owner_id, next_id])
			return
		if not distances.has(owner_id) or not distances.has(next_id):
			_fail("arrow path node is disconnected from exit: %s" % arrow.name)
			return
		if int(distances[next_id]) != int(distances[owner_id]) - 1:
			_fail("arrow does not point to the next shortest-path hop: %s owner_dist=%d next_dist=%d" % [arrow.name, int(distances[owner_id]), int(distances[next_id])])
			return
		color_entries.append({
			"name": arrow.name,
			"distance": int(distances[owner_id]),
			"heat": float(arrow.get_meta("exit_heat", -1.0)),
			"color": arrow.get_meta("distance_color", Color.WHITE),
		})
		var portal := _portal_for_arrow(portals, arrow, owner_id, next_id)
		if portal == null:
			_fail("arrow target portal is missing: %s" % arrow.name)
			return
		if not _validate_arrow_points_to_portal(arrow, portal):
			return
	if not _validate_arrow_color_gradient(color_entries):
		return

	print("GUIDANCE_GRAFFITI_VALIDATION PASS arrows=%d exit=%s" % [arrows.size(), exit_id])
	quit(0)

func _validate_arrow_asset(arrow: MeshInstance3D) -> bool:
	if not (arrow.mesh is QuadMesh):
		_fail("guidance arrow must use QuadMesh decal carrier: %s" % arrow.name)
		return false
	if arrow.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
		_fail("guidance arrow casts shadows: %s" % arrow.name)
		return false
	if arrow.global_position.y < 1.05 or arrow.global_position.y > 1.75:
		_fail("guidance arrow is at an unreasonable wall height: %s y=%.2f" % [arrow.name, arrow.global_position.y])
		return false
	if _has_collision_descendant(arrow):
		_fail("guidance arrow must not add collision: %s" % arrow.name)
		return false
	var material := arrow.material_override as StandardMaterial3D
	if material == null:
		_fail("guidance arrow material is not StandardMaterial3D: %s" % arrow.name)
		return false
	if material.transparency != BaseMaterial3D.TRANSPARENCY_ALPHA:
		_fail("guidance arrow material is not alpha transparent: %s" % arrow.name)
		return false
	var texture := material.albedo_texture as Texture2D
	if texture == null:
		_fail("guidance arrow material has no albedo texture: %s" % arrow.name)
		return false
	var image := texture.get_image()
	if image == null or image.detect_alpha() == Image.ALPHA_NONE:
		_fail("guidance arrow texture has no alpha channel: %s" % arrow.name)
		return false
	var color: Color = arrow.get_meta("distance_color", Color.WHITE)
	if color.a < 0.70 or color.a > 0.90:
		_fail("guidance arrow tint alpha is outside readable range: %s alpha=%.2f" % [arrow.name, color.a])
		return false
	return true

func _validate_arrow_color_gradient(entries: Array) -> bool:
	if entries.size() < 2:
		_fail("not enough arrows to validate color gradient")
		return false
	var closest: Dictionary = entries[0]
	var farthest: Dictionary = entries[0]
	for entry in entries:
		var heat := float((entry as Dictionary).get("heat", -1.0))
		if heat < -0.001 or heat > 1.001:
			_fail("guidance arrow heat metadata is outside 0..1: %s heat=%.2f" % [String((entry as Dictionary).get("name", "")), heat])
			return false
		if int((entry as Dictionary).get("distance", 0)) < int(closest.get("distance", 0)):
			closest = entry
		if int((entry as Dictionary).get("distance", 0)) > int(farthest.get("distance", 0)):
			farthest = entry
	if int(closest.get("distance", 0)) >= int(farthest.get("distance", 0)):
		_fail("arrow distances do not span enough range for color gradient")
		return false
	var closest_color: Color = closest.get("color", Color.WHITE)
	var farthest_color: Color = farthest.get("color", Color.WHITE)
	if closest_color.r <= farthest_color.r + 0.12:
		_fail("near-exit arrow is not redder than far arrow: near=%s far=%s" % [str(closest_color), str(farthest_color)])
		return false
	if closest_color.b >= farthest_color.b - 0.12:
		_fail("far arrow is not colder/bluer than near-exit arrow: near=%s far=%s" % [str(closest_color), str(farthest_color)])
		return false
	if float(closest.get("heat", 0.0)) <= float(farthest.get("heat", 0.0)) + 0.20:
		_fail("arrow heat does not increase toward exit: near=%.2f far=%.2f" % [float(closest.get("heat", 0.0)), float(farthest.get("heat", 0.0))])
		return false
	return true

func _validate_arrow_points_to_portal(arrow: MeshInstance3D, portal: Node3D) -> bool:
	var side_offset := absf(float(arrow.get_meta("door_side_offset", 0.0)))
	if side_offset < MIN_DOOR_SIDE_OFFSET:
		_fail("guidance arrow is too close to its door frame: %s side_offset=%.2f" % [arrow.name, side_offset])
		return false
	var wall_offset := float(arrow.get_meta("wall_offset", 0.0))
	if wall_offset < MIN_WALL_FACE_OFFSET:
		_fail("guidance arrow is too close to the wall surface: %s wall_offset=%.2f" % [arrow.name, wall_offset])
		return false
	var to_portal := portal.global_position - arrow.global_position
	to_portal.y = 0.0
	if to_portal.length() > MAX_PORTAL_DISTANCE:
		_fail("guidance arrow is too far from its target door: %s distance=%.2f" % [arrow.name, to_portal.length()])
		return false
	if to_portal.length_squared() <= 0.0001:
		_fail("guidance arrow is exactly on its target portal: %s" % arrow.name)
		return false
	var arrow_direction := arrow.global_transform.basis.x
	arrow_direction.y = 0.0
	if arrow_direction.length_squared() <= 0.0001:
		_fail("guidance arrow has invalid basis: %s" % arrow.name)
		return false
	if arrow_direction.normalized().dot(to_portal.normalized()) < MIN_ARROW_DOT_TO_PORTAL:
		_fail("guidance arrow does not point toward its target door: %s" % arrow.name)
		return false
	return true

func _find_marker_room_id(root: Node, marker_type: String) -> String:
	var markers := root.get_node_or_null("LevelRoot/Markers")
	if markers == null:
		return ""
	for child in markers.get_children():
		var marker := child as Node3D
		if marker == null:
			continue
		if String(marker.get("marker_type")) == marker_type:
			return String(marker.get("room_id"))
	return ""

func _collect_portals(root: Node) -> Array[Node3D]:
	var portals: Array[Node3D] = []
	var portals_root := root.get_node_or_null("LevelRoot/Portals")
	if portals_root == null:
		return portals
	for child in portals_root.get_children():
		var portal := child as Node3D
		if portal != null:
			portals.append(portal)
	return portals

func _build_adjacency(portals: Array[Node3D]) -> Dictionary:
	var adjacency := {}
	for portal in portals:
		var area_a := String(portal.get("area_a"))
		var area_b := String(portal.get("area_b"))
		if area_a.is_empty() or area_b.is_empty():
			continue
		if not adjacency.has(area_a):
			adjacency[area_a] = []
		if not adjacency.has(area_b):
			adjacency[area_b] = []
		(adjacency[area_a] as Array).append(area_b)
		(adjacency[area_b] as Array).append(area_a)
	return adjacency

func _shortest_distances_from(start_id: String, adjacency: Dictionary) -> Dictionary:
	var distances := {start_id: 0}
	var queue := [start_id]
	var head := 0
	while head < queue.size():
		var current_id := String(queue[head])
		head += 1
		var current_distance := int(distances[current_id])
		for neighbor in adjacency.get(current_id, []):
			var neighbor_id := String(neighbor)
			if distances.has(neighbor_id):
				continue
			distances[neighbor_id] = current_distance + 1
			queue.append(neighbor_id)
	return distances

func _portal_for_arrow(portals: Array[Node3D], arrow: MeshInstance3D, owner_id: String, next_id: String) -> Node3D:
	var target_edge_id := String(arrow.get_meta("target_edge_id", ""))
	for portal in portals:
		var edge_id := String(portal.get_meta("edge_id", ""))
		var area_a := String(portal.get("area_a"))
		var area_b := String(portal.get("area_b"))
		if not target_edge_id.is_empty() and edge_id == target_edge_id:
			return portal
		if (area_a == owner_id and area_b == next_id) or (area_a == next_id and area_b == owner_id):
			return portal
	return null

func _nodes_in_group(root: Node, group_name: String) -> Array:
	var result := []
	_collect_nodes_in_group(root, group_name, result)
	return result

func _collect_nodes_in_group(node: Node, group_name: String, result: Array) -> void:
	if node.is_in_group(group_name):
		result.append(node)
	for child in node.get_children():
		_collect_nodes_in_group(child, group_name, result)

func _has_collision_descendant(node: Node) -> bool:
	if node is CollisionShape3D or node is CollisionObject3D:
		return true
	for child in node.get_children():
		if _has_collision_descendant(child):
			return true
	return false

func _fail(message: String) -> void:
	push_error("GUIDANCE_GRAFFITI_VALIDATION FAIL %s" % message)
	quit(1)
