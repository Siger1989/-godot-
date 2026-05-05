extends SceneTree

const SCENE_PATH := "res://scenes/mvp/FourRoomMVP.tscn"
const GEOMETRY_ROOT_PATH := "LevelRoot/Geometry"
const AREAS_ROOT_PATH := "LevelRoot/Areas"
const FLOOR_BODY_PATH := "LevelRoot/Geometry/Floor_WalkableCollision"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene_resource := load(SCENE_PATH) as PackedScene
	if scene_resource == null:
		_fail("Failed to load %s." % SCENE_PATH)
		return

	var scene := scene_resource.instantiate() as Node3D
	root.add_child(scene)
	await process_frame
	await physics_frame
	await process_frame

	var floor_body := scene.get_node_or_null(FLOOR_BODY_PATH) as StaticBody3D
	var floor_collision := scene.get_node_or_null("%s/Collision" % FLOOR_BODY_PATH) as CollisionShape3D
	if floor_body == null or floor_collision == null:
		_fail("Continuous Floor_WalkableCollision body or CollisionShape3D is missing.")
		return

	var player := scene.get_node_or_null("PlayerRoot/Player") as CharacterBody3D
	if player != null:
		player.set_physics_process(false)
		player.global_position = Vector3(30.0, 2.0, 30.0)
		player.velocity = Vector3.ZERO

	var monster := scene.get_node_or_null("MonsterRoot/Monster") as CharacterBody3D
	if monster == null:
		_fail("Monster is missing.")
		return
	monster.set_physics_process(false)
	monster.global_position = Vector3(30.0, 2.0, 32.0)
	monster.velocity = Vector3.ZERO
	await physics_frame

	var ray_exclude: Array[RID] = []
	if player != null:
		ray_exclude.append(player.get_rid())
	ray_exclude.append(monster.get_rid())

	for old_collision_path in [
		"%s/Floor_SouthStrip/Collision" % GEOMETRY_ROOT_PATH,
		"%s/Floor_NorthStrip/Collision" % GEOMETRY_ROOT_PATH,
	]:
		if scene.get_node_or_null(old_collision_path) != null:
			_fail("Floor visual strip still has its own collision: %s." % old_collision_path)
			return
	for old_visual_path in [
		"%s/Floor_SouthStrip" % GEOMETRY_ROOT_PATH,
		"%s/Floor_NorthStrip" % GEOMETRY_ROOT_PATH,
	]:
		if scene.get_node_or_null(old_visual_path) != null:
			_fail("Old floor strip visual should be replaced by regular per-room floor panels: %s." % old_visual_path)
			return
	if not _validate_floor_visuals(scene):
		return

	var checked_points := 0
	var failed_point := Vector3.ZERO
	for point in _get_room_sample_points(scene):
		checked_points += 1
		var hit_collider: Variant = _get_floor_ray_collider(scene, point, ray_exclude)
		if hit_collider != floor_body:
			failed_point = point
			var hit_name := "<none>"
			var hit_node := hit_collider as Node
			if hit_node != null:
				hit_name = hit_node.get_path()
			_fail("Floor ray missed the continuous walkable collision at %s after %d checks; hit=%s." % [failed_point, checked_points, hit_name])
			return

	monster.set_physics_process(true)
	monster.global_position = Vector3(-1.8, 0.05, 8.2)
	monster.velocity = Vector3.ZERO
	await physics_frame
	for _frame_index in range(45):
		await physics_frame
		if monster.global_position.y < -0.2:
			_fail("Monster dropped below the floor near the Room_D edge: y=%.3f." % monster.global_position.y)
			return

	print("FLOOR_COVERAGE_VALIDATION PASS samples=%d monster_y=%.3f" % [checked_points, monster.global_position.y])
	quit(0)

func _validate_floor_visuals(scene: Node3D) -> bool:
	var expected := {
		"Floor_Room_A": {"center": Vector3(0.0, 0.0, 0.0), "size": Vector2(6.0, 6.0)},
		"Floor_Room_B": {"center": Vector3(6.0, 0.0, 0.0), "size": Vector2(6.0, 6.0)},
		"Floor_Room_C": {"center": Vector3(6.0, 0.0, 6.0), "size": Vector2(6.0, 6.0)},
		"Floor_Room_D": {"center": Vector3(0.0, 0.0, 6.0), "size": Vector2(6.0, 6.0)},
	}
	for floor_name in expected.keys():
		var floor := scene.get_node_or_null("%s/%s" % [GEOMETRY_ROOT_PATH, floor_name]) as MeshInstance3D
		if floor == null:
			_fail("Expected per-room floor visual is missing: %s." % floor_name)
			return false
		if not floor.is_in_group("floor_visual"):
			_fail("Per-room floor visual is missing floor_visual group: %s." % floor.get_path())
			return false
		if _has_collision_descendant(floor):
			_fail("Per-room floor visual must not own collision: %s." % floor.get_path())
			return false
		var floor_info: Dictionary = expected[floor_name]
		var expected_center: Vector3 = floor_info["center"]
		var expected_size: Vector2 = floor_info["size"]
		var position_delta := Vector2(floor.global_position.x - expected_center.x, floor.global_position.z - expected_center.z).length()
		if position_delta > 0.01:
			_fail("Per-room floor visual has unexpected center: %s pos=%s." % [floor.get_path(), floor.global_position])
			return false
		var aabb := floor.mesh.get_aabb()
		if absf(aabb.size.x - expected_size.x) > 0.01 or absf(aabb.size.z - expected_size.y) > 0.01:
			_fail("Per-room floor visual has unexpected rectangular size: %s aabb=%s." % [floor.get_path(), aabb])
			return false
	return true

func _has_collision_descendant(node: Node) -> bool:
	for child in node.get_children():
		if child is CollisionShape3D:
			return true
		if _has_collision_descendant(child):
			return true
	return false

func _get_room_sample_points(scene: Node3D) -> Array[Vector3]:
	var points: Array[Vector3] = []
	var areas_root := scene.get_node_or_null(AREAS_ROOT_PATH) as Node3D
	if areas_root == null:
		return points

	for room in areas_root.get_children():
		var room_node := room as Node3D
		if room_node == null:
			continue
		var room_id_variant: Variant = room.get("room_id")
		var bounds_variant: Variant = room.get("bounds_size")
		if room_id_variant == null or not (bounds_variant is Vector3):
			continue
		var bounds: Vector3 = bounds_variant
		if bounds == Vector3.ZERO:
			continue
		var center := room_node.global_position
		var half_x := bounds.x * 0.5 - 0.18
		var half_z := bounds.z * 0.5 - 0.18
		for x_step in [-1.0, -0.5, 0.0, 0.5, 1.0]:
			for z_step in [-1.0, -0.5, 0.0, 0.5, 1.0]:
				points.append(Vector3(center.x + half_x * x_step, 0.0, center.z + half_z * z_step))

	for x in [-2.85, -1.5, 0.0, 1.5, 3.0, 4.5, 6.0, 7.5, 8.85]:
		points.append(Vector3(x, 0.0, 3.0))
	for z in [-2.85, -1.5, 0.0, 1.5, 3.0, 4.5, 6.0, 7.5, 8.85]:
		points.append(Vector3(3.0, 0.0, z))

	return points

func _get_floor_ray_collider(scene: Node3D, point: Vector3, exclude: Array[RID]) -> Variant:
	var world := scene.get_world_3d()
	if world == null:
		return null
	var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 1.2, point + Vector3.DOWN * 1.2)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.exclude = exclude
	var hit := world.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return null
	return hit.get("collider")

func _fail(message: String) -> void:
	push_error("FLOOR_COVERAGE_VALIDATION FAIL: %s" % message)
	quit(1)
