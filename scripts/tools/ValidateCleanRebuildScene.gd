extends SceneTree

const SCENE_PATH := "res://scenes/mvp/FourRoomMVP.tscn"
const EXPECTED_GEOMETRY_COUNTS := {
	"floor_visual": 4,
	"wall_opening": 5,
	"door_frame": 5,
	"ceiling": 4,
	"ceiling_light_panel": 4,
}
const EXPECTED_ROOM_SIZE := Vector3(6.0, 2.55, 6.0)
const EXPECTED_ROOM_CENTERS := {
	"Room_A": Vector3(0.0, 0.0, 0.0),
	"Room_B": Vector3(6.0, 0.0, 0.0),
	"Room_C": Vector3(6.0, 0.0, 6.0),
	"Room_D": Vector3(0.0, 0.0, 6.0),
}
const EXPECTED_PORTAL_CENTERS := {
	"P_AB": Vector3(3.0, 0.0, 0.0),
	"P_BC": Vector3(6.0, 0.0, 3.0),
	"P_CD": Vector3(3.0, 0.0, 6.0),
	"P_DA": Vector3(0.0, 0.0, 3.0),
}
const EXPECTED_PORTAL_AXES := {
	"P_AB": "z",
	"P_BC": "x",
	"P_CD": "z",
	"P_DA": "x",
}
const EXPECTED_DOOR_WIDTH := 1.15
const EXPECTED_DOOR_FRAME_TRIM_WIDTH := 0.10
const EXPECTED_DOOR_FRAME_SIDE_CLEARANCE := 0.0
const EXPECTED_DOOR_FRAME_DEPTH := 0.16
const EXPECTED_DOOR_FRAME_OUTER_WIDTH := EXPECTED_DOOR_WIDTH - EXPECTED_DOOR_FRAME_SIDE_CLEARANCE
const EXPECTED_DOOR_FRAME_INNER_WIDTH := EXPECTED_DOOR_FRAME_OUTER_WIDTH - EXPECTED_DOOR_FRAME_TRIM_WIDTH * 2.0
const EXPECTED_WALL_SPAN_LENGTH := 5.64
const EXPECTED_Z_AXIS_FRAME_YAW := -PI * 0.5

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene_resource := load(SCENE_PATH) as PackedScene
	if scene_resource == null:
		_fail("Failed to load %s." % SCENE_PATH)
		return

	var scene := scene_resource.instantiate() as Node3D
	scene.set("build_on_ready", false)
	root.add_child(scene)
	current_scene = scene
	await process_frame

	if not _validate_scene(scene, "baked"):
		return

	var builder := scene.get_node_or_null("Systems/SceneBuilder")
	if builder == null or not builder.has_method("build"):
		_fail("SceneBuilder is missing.")
		return
	builder.call("build")
	await process_frame

	if not _validate_scene(scene, "runtime"):
		return

	print("CLEAN_REBUILD_SCENE_VALIDATION PASS")
	quit(0)

func _validate_scene(scene: Node3D, label: String) -> bool:
	if scene.get_node_or_null("LevelRoot/Rooms") != null:
		_fail("%s scene still contains legacy LevelRoot/Rooms." % label)
		return false

	var geometry_root := scene.get_node_or_null("LevelRoot/Geometry") as Node3D
	var areas_root := scene.get_node_or_null("LevelRoot/Areas") as Node3D
	if geometry_root == null or areas_root == null:
		_fail("%s scene must contain LevelRoot/Geometry and LevelRoot/Areas." % label)
		return false

	if geometry_root.get_node_or_null("Floor_WalkableCollision") == null:
		_fail("%s scene is missing the rebuilt continuous floor collision." % label)
		return false

	if _count_room_area_nodes(areas_root) != 4:
		_fail("%s scene must contain exactly 4 room area metadata nodes under LevelRoot/Areas." % label)
		return false
	if not _validate_uniform_room_areas(areas_root, label):
		return false

	for node in areas_root.get_children():
		if _has_geometry_descendant(node):
			_fail("%s area metadata node contains geometry: %s." % [label, node.get_path()])
			return false

	for group_name in EXPECTED_GEOMETRY_COUNTS.keys():
		var expected_count := int(EXPECTED_GEOMETRY_COUNTS[group_name])
		var count := _count_group_under_root(scene, geometry_root, StringName(group_name))
		if count != expected_count:
			_fail("%s scene expected %d %s nodes under Geometry, found %d." % [label, expected_count, group_name, count])
			return false

	if _count_wall_bodies(geometry_root) != 21:
		_fail("%s scene should have exactly 21 rebuilt wall/opening/joint bodies under Geometry; found %d." % [label, _count_wall_bodies(geometry_root)])
		return false

	for old_node_path in [
		"Wall_A_NorthWestReturn",
		"WallJoint_A_NorthWest",
	]:
		if geometry_root.get_node_or_null(old_node_path) != null:
			_fail("%s scene still contains old asymmetric Room_D geometry: %s." % [label, old_node_path])
			return false

	if not _validate_uniform_floor_visuals(geometry_root, label):
		return false
	if not _validate_uniform_portals(scene, label):
		return false

	return true

func _count_room_area_nodes(areas_root: Node) -> int:
	var count := 0
	for node in areas_root.get_children():
		if node.get("room_id") != null and node.get("area_id") != null:
			count += 1
	return count

func _validate_uniform_room_areas(areas_root: Node3D, label: String) -> bool:
	for room_id in EXPECTED_ROOM_CENTERS.keys():
		var found := false
		for node in areas_root.get_children():
			if String(node.get("room_id")) != room_id:
				continue
			found = true
			var area := node as Node3D
			if area == null:
				_fail("%s room area %s is not Node3D." % [label, room_id])
				return false
			if area.global_position.distance_to(EXPECTED_ROOM_CENTERS[room_id]) > 0.01:
				_fail("%s room area %s center is not on the uniform 2x2 grid: %s." % [label, room_id, area.global_position])
				return false
			var bounds := node.get("bounds_size") as Vector3
			if bounds.distance_to(EXPECTED_ROOM_SIZE) > 0.01:
				_fail("%s room area %s is not 6x6: %s." % [label, room_id, bounds])
				return false
		if not found:
			_fail("%s missing room area metadata for %s." % [label, room_id])
			return false
	return true

func _validate_uniform_floor_visuals(geometry_root: Node3D, label: String) -> bool:
	for room_id in EXPECTED_ROOM_CENTERS.keys():
		var floor := geometry_root.get_node_or_null("Floor_%s" % room_id) as MeshInstance3D
		if floor == null:
			_fail("%s missing floor visual for %s." % [label, room_id])
			return false
		if floor.global_position.distance_to(EXPECTED_ROOM_CENTERS[room_id] + Vector3(0.0, 0.0, 0.0)) > 0.11:
			_fail("%s floor visual %s center is not on the uniform grid: %s." % [label, floor.name, floor.global_position])
			return false
		var aabb := floor.mesh.get_aabb()
		if absf(aabb.size.x - 6.0) > 0.01 or absf(aabb.size.z - 6.0) > 0.01:
			_fail("%s floor visual %s is not 6x6: %s." % [label, floor.name, aabb])
			return false
	return true

func _validate_uniform_portals(scene: Node3D, label: String) -> bool:
	var portals_root := scene.get_node_or_null("LevelRoot/Portals") as Node3D
	var geometry_root := scene.get_node_or_null("LevelRoot/Geometry") as Node3D
	if portals_root == null or geometry_root == null:
		_fail("%s scene is missing portal or geometry root." % label)
		return false
	for portal_id in EXPECTED_PORTAL_CENTERS.keys():
		var expected_center: Vector3 = EXPECTED_PORTAL_CENTERS[portal_id]
		var portal := portals_root.get_node_or_null(portal_id) as Node3D
		var opening := geometry_root.get_node_or_null("WallOpening_%s" % portal_id)
		var frame := geometry_root.get_node_or_null("DoorFrame_%s" % portal_id) as MeshInstance3D
		if portal == null or opening == null or frame == null:
			_fail("%s missing portal/opening/frame for %s." % [label, portal_id])
			return false
		if portal.global_position.distance_to(expected_center) > 0.01:
			_fail("%s portal %s is not on the uniform grid: %s." % [label, portal_id, portal.global_position])
			return false
		if (opening as Node3D).global_position.distance_to(expected_center) > 0.01:
			_fail("%s opening %s is not on the uniform grid: %s." % [label, portal_id, (opening as Node3D).global_position])
			return false
		if frame.global_position.distance_to(expected_center) > 0.01:
			_fail("%s door frame %s is not on the uniform grid: %s." % [label, portal_id, frame.global_position])
			return false
		if absf(float(portal.get("opening_width")) - EXPECTED_DOOR_WIDTH) > 0.01:
			_fail("%s portal %s width is not uniform: %.3f." % [label, portal_id, float(portal.get("opening_width"))])
			return false
		if absf(float(opening.get("opening_width")) - EXPECTED_DOOR_WIDTH) > 0.01:
			_fail("%s wall opening %s width is not uniform: %.3f." % [label, portal_id, float(opening.get("opening_width"))])
			return false
		var expected_axis: String = String(EXPECTED_PORTAL_AXES[portal_id])
		if String(opening.get("span_axis")) != expected_axis:
			_fail("%s wall opening %s axis is not uniform: %s." % [label, portal_id, String(opening.get("span_axis"))])
			return false
		var opening_node := opening as Node3D
		if opening_node.scale.distance_to(Vector3.ONE) > 0.001:
			_fail("%s wall opening %s uses node scaling instead of canonical mesh rotation: %s." % [label, portal_id, opening_node.scale])
			return false
		var expected_yaw := 0.0
		if _angle_distance(opening_node.rotation.y, expected_yaw) > 0.001:
			_fail("%s wall opening %s must keep zero node rotation for axis %s: %.4f." % [label, portal_id, expected_axis, opening_node.rotation.y])
			return false
		var opening_mesh := opening_node.get_node_or_null("Mesh") as MeshInstance3D
		if opening_mesh == null or opening_mesh.mesh == null:
			_fail("%s wall opening %s is missing its generated Mesh child." % [label, portal_id])
			return false
		var opening_aabb := opening_mesh.mesh.get_aabb()
		var expected_local_size := Vector2(EXPECTED_WALL_SPAN_LENGTH, 0.2) if expected_axis == "x" else Vector2(0.2, EXPECTED_WALL_SPAN_LENGTH)
		if absf(opening_aabb.size.x - expected_local_size.x) > 0.01 or absf(opening_aabb.size.z - expected_local_size.y) > 0.01:
			_fail("%s wall opening %s mesh is not canonical local U-wall size: %s." % [label, portal_id, opening_aabb])
			return false
		if absf(float(frame.get("opening_width")) - EXPECTED_DOOR_FRAME_INNER_WIDTH) > 0.01:
			_fail("%s door frame %s width is not uniform: %.3f." % [label, portal_id, float(frame.get("opening_width"))])
			return false
		if String(frame.get("span_axis")) != expected_axis:
			_fail("%s door frame %s axis is not uniform: %s." % [label, portal_id, String(frame.get("span_axis"))])
			return false
		if frame.scale.distance_to(Vector3.ONE) > 0.001:
			_fail("%s door frame %s uses node scaling instead of canonical mesh rotation: %s." % [label, portal_id, frame.scale])
			return false
		if _angle_distance(frame.rotation.y, expected_yaw) > 0.001:
			_fail("%s door frame %s yaw is not canonical for axis %s: %.4f." % [label, portal_id, expected_axis, frame.rotation.y])
			return false
		if frame.mesh == null:
			_fail("%s door frame %s is missing its generated mesh." % [label, portal_id])
			return false
		var frame_aabb := frame.mesh.get_aabb()
		var expected_outer_width := EXPECTED_DOOR_FRAME_OUTER_WIDTH
		var expected_frame_local_size := Vector2(expected_outer_width, EXPECTED_DOOR_FRAME_DEPTH) if expected_axis == "x" else Vector2(EXPECTED_DOOR_FRAME_DEPTH, expected_outer_width)
		if absf(frame_aabb.size.x - expected_frame_local_size.x) > 0.01 or absf(frame_aabb.size.z - expected_frame_local_size.y) > 0.01:
			_fail("%s door frame %s mesh is not canonical U-shape size: %s." % [label, portal_id, frame_aabb])
			return false
	return true

func _angle_distance(a: float, b: float) -> float:
	return absf(wrapf(a - b, -PI, PI))

func _has_geometry_descendant(node: Node) -> bool:
	for child in node.get_children():
		if child is MeshInstance3D or child is CollisionShape3D:
			return true
		if _has_geometry_descendant(child):
			return true
	return false

func _count_group_under_root(scene: Node, root_node: Node, group_name: StringName) -> int:
	var count := 0
	for node in scene.get_tree().get_nodes_in_group(group_name):
		if root_node.is_ancestor_of(node):
			count += 1
	return count

func _count_wall_bodies(root_node: Node) -> int:
	var count := 0
	for child in root_node.get_children():
		var child_name := String(child.name)
		if child_name.begins_with("Wall") and child is StaticBody3D:
			count += 1
	return count

func _fail(message: String) -> void:
	push_error("CLEAN_REBUILD_SCENE_VALIDATION FAIL: %s" % message)
	quit(1)
