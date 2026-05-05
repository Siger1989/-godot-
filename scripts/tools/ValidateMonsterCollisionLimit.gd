extends SceneTree

const SCENE_PATH := "res://scenes/mvp/FourRoomMVP.tscn"

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

	var monster := scene.get_node_or_null("MonsterRoot/Monster") as CharacterBody3D
	var collision := scene.get_node_or_null("MonsterRoot/Monster/CollisionShape3D") as CollisionShape3D
	if monster == null or collision == null:
		_fail("Monster or monster CollisionShape3D is missing.")
		return
	var box := collision.shape as BoxShape3D
	if box == null:
		_fail("Monster collision shape is not a BoxShape3D.")
		return

	if monster.scale.x <= 0.0 or monster.scale.y <= 0.0 or monster.scale.z <= 0.0:
		_fail("Monster root scale is invalid: %s." % monster.scale)
		return
	if monster.safe_margin < 0.049:
		_fail("Monster safe_margin is too small: %.3f." % monster.safe_margin)
		return

	var visual_aabb := _collect_visual_aabb_in_monster_local(monster)
	var collision_aabb := _box_collision_aabb_in_monster_local(monster, collision, box)
	if not _aabb_contains(collision_aabb, visual_aabb, 0.035):
		_fail("Monster visual AABB is outside collision. visual=%s collision=%s." % [visual_aabb, collision_aabb])
		return

	monster.set_physics_process(false)
	monster.global_position = Vector3(0.0, 0.05, 7.2)
	monster.rotation = Vector3.ZERO
	monster.velocity = Vector3.ZERO
	await physics_frame

	for _frame_index in range(90):
		monster.velocity = Vector3(0.0, 0.0, 3.0)
		monster.move_and_slide()
		await physics_frame

	var north_inner_face_z := 8.9
	var root_scale := monster.transform.basis.get_scale()
	var collision_front_z := collision_aabb.end.z * root_scale.z
	var visual_front_offset_z := visual_aabb.end.z * root_scale.z
	var max_center_z := north_inner_face_z - collision_front_z + 0.12
	if monster.global_position.z > max_center_z:
		_fail("Monster body crossed north-wall limit: z=%.3f max=%.3f." % [monster.global_position.z, max_center_z])
		return

	var visual_front_z := monster.global_position.z + visual_front_offset_z
	if visual_front_z > north_inner_face_z + 0.05:
		_fail("Monster visual crossed north-wall limit: front_z=%.3f." % visual_front_z)
		return

	print(
		"MONSTER_COLLISION_LIMIT_VALIDATION PASS scale=%s safe_margin=%.3f collision=%s visual=%s final_z=%.3f"
		% [monster.scale, monster.safe_margin, collision_aabb, visual_aabb, monster.global_position.z]
	)
	quit(0)

func _collect_visual_aabb_in_monster_local(monster: Node3D) -> AABB:
	var mesh_instances: Array[MeshInstance3D] = []
	_collect_mesh_instances(monster, mesh_instances)
	var has_aabb := false
	var combined := AABB()
	for mesh_instance in mesh_instances:
		var mesh_aabb := mesh_instance.get_aabb()
		var local_aabb := _aabb_to_target_local(mesh_instance, mesh_aabb, monster)
		if has_aabb:
			combined = combined.merge(local_aabb)
		else:
			combined = local_aabb
			has_aabb = true
	return combined

func _collect_mesh_instances(node: Node, output: Array[MeshInstance3D]) -> void:
	var mesh_instance := node as MeshInstance3D
	if mesh_instance != null:
		output.append(mesh_instance)
	for child in node.get_children():
		_collect_mesh_instances(child, output)

func _box_collision_aabb_in_monster_local(monster: Node3D, collision: CollisionShape3D, box: BoxShape3D) -> AABB:
	var half_size := box.size * 0.5
	var local_box := AABB(-half_size, box.size)
	return _aabb_to_target_local(collision, local_box, monster)

func _aabb_to_target_local(source: Node3D, local_aabb: AABB, target: Node3D) -> AABB:
	var corners := [
		local_aabb.position,
		local_aabb.position + Vector3(local_aabb.size.x, 0.0, 0.0),
		local_aabb.position + Vector3(0.0, local_aabb.size.y, 0.0),
		local_aabb.position + Vector3(0.0, 0.0, local_aabb.size.z),
		local_aabb.position + Vector3(local_aabb.size.x, local_aabb.size.y, 0.0),
		local_aabb.position + Vector3(local_aabb.size.x, 0.0, local_aabb.size.z),
		local_aabb.position + Vector3(0.0, local_aabb.size.y, local_aabb.size.z),
		local_aabb.position + local_aabb.size,
	]
	var target_inverse := target.global_transform.affine_inverse()
	var converted := AABB(target_inverse * (source.global_transform * corners[0]), Vector3.ZERO)
	for corner_index in range(1, corners.size()):
		converted = converted.expand(target_inverse * (source.global_transform * corners[corner_index]))
	return converted

func _aabb_contains(outer: AABB, inner: AABB, tolerance: float) -> bool:
	return (
		inner.position.x >= outer.position.x - tolerance
		and inner.position.y >= outer.position.y - tolerance
		and inner.position.z >= outer.position.z - tolerance
		and inner.end.x <= outer.end.x + tolerance
		and inner.end.y <= outer.end.y + tolerance
		and inner.end.z <= outer.end.z + tolerance
	)

func _is_near_vec3(a: Vector3, b: Vector3, tolerance: float) -> bool:
	return (
		absf(a.x - b.x) <= tolerance
		and absf(a.y - b.y) <= tolerance
		and absf(a.z - b.z) <= tolerance
	)

func _fail(message: String) -> void:
	push_error("MONSTER_COLLISION_LIMIT_VALIDATION FAIL: %s" % message)
	quit(1)
